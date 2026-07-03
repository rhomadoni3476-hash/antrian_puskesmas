from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from pydantic import BaseModel, Field, ConfigDict
from fastapi.middleware.cors import CORSMiddleware
import jwt
from datetime import datetime, timedelta, timezone
from typing import List, Optional
import models, database
import os

# Firebase
import firebase_admin
from firebase_admin import credentials, firestore

# --- Konfigurasi ---
SECRET_KEY = os.getenv("SECRET_KEY", "puskesmas-digital-secret-key-yang-sangat-panjang")
ALGORITHM = "HS256"

# --- Inisialisasi Firebase ---
if not firebase_admin._apps:
    try:
        cred = credentials.Certificate("serviceAccountKey.json")
        firebase_admin.initialize_app(cred)
    except Exception as e:
        print(f"Gagal inisialisasi Firebase: {e}")

db_firebase = firestore.client()

app = FastAPI(title="Puskesmas Digital API", version="1.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

models.Base.metadata.create_all(bind=database.engine)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

# --- Security Helper ---
def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Token tidak valid atau telah kedaluwarsa",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None: raise credentials_exception
        return username
    except jwt.PyJWTError:
        raise credentials_exception

# --- Schemas ---
class RekamMedisCreate(BaseModel):
    nama_pasien: str = Field(..., min_length=3)
    nik: str = Field(..., min_length=16, max_length=16)
    keluhan: str
    email_pasien: str 
    status: str = "Menunggu"

class RekamMedisSchema(RekamMedisCreate):
    id: int
    tanggal_pemeriksaan: datetime
    model_config = ConfigDict(from_attributes=True)

# Schema khusus untuk update status agar lebih aman
class StatusUpdate(BaseModel):
    status: str

# --- Login & Authentication ---
@app.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    # Sederhana: autentikasi langsung via token
    # Catatan: Tambahkan logika validasi user vs database di sini jika perlu
    expire = datetime.now(timezone.utc) + timedelta(minutes=120)
    token = jwt.encode({"sub": form_data.username, "exp": expire}, SECRET_KEY, algorithm=ALGORITHM)
    return {"access_token": token, "token_type": "bearer"}

# --- Rekam Medis Endpoints ---
@app.post("/tambah-rekam-medis", status_code=status.HTTP_201_CREATED)
def tambah_data(item: RekamMedisCreate, db: Session = Depends(database.get_db), user: str = Depends(get_current_user)):
    db_item = models.RekamMedisDB(**item.model_dump(), tanggal_pemeriksaan=datetime.now(timezone.utc))
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return {"message": "Data berhasil disimpan!", "id": db_item.id}

@app.get("/daftar-rekam-medis", response_model=List[RekamMedisSchema])
def ambil_semua_data(db: Session = Depends(database.get_db), user: str = Depends(get_current_user)):
    return db.query(models.RekamMedisDB).order_by(models.RekamMedisDB.tanggal_pemeriksaan.desc()).all()

@app.get("/rekam-medis-pasien", response_model=List[RekamMedisSchema])
def ambil_data_pasien(db: Session = Depends(database.get_db), user: str = Depends(get_current_user)):
    return db.query(models.RekamMedisDB).filter(models.RekamMedisDB.email_pasien == user).order_by(models.RekamMedisDB.tanggal_pemeriksaan.desc()).all()

# --- Endpoint Update yang Diperbarui ---
@app.put("/update-status/{id}")
def update_status(id: int, data: StatusUpdate, db: Session = Depends(database.get_db), user: str = Depends(get_current_user)):
    db_item = db.query(models.RekamMedisDB).filter(models.RekamMedisDB.id == id).first()
    if not db_item:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan")
    
    db_item.status = data.status
    db.commit()
    db.refresh(db_item)
    return {"message": "Status berhasil diupdate", "new_status": db_item.status}

# --- Firebase Endpoints ---
@app.get("/api/sus-statistics")
def get_sus_statistics(user: str = Depends(get_current_user)):
    try:
        docs = db_firebase.collection("sus_results").stream()
        scores = [d.to_dict().get("final_score", 0) for d in docs]
        avg = sum(scores) / len(scores) if scores else 0
        return {
            "rata_rata_sus": round(avg, 2),
            "total_responden": len(scores),
            "kategori": "Excellent" if avg > 80 else "Good" if avg > 68 else "Marginal/Poor"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal akses Firebase: {str(e)}")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)