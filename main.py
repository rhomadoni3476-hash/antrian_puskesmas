from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
import jwt
from datetime import datetime, timedelta, timezone
import os
import json

# Firebase
import firebase_admin
from firebase_admin import credentials, firestore

# --- Konfigurasi ---
SECRET_KEY = os.getenv("SECRET_KEY", "puskesmas-digital-secret-key-yang-sangat-panjang")
ALGORITHM = "HS256"
FIREBASE_JSON_CONTENT = os.getenv("FIREBASE_JSON_CONTENT")

app = FastAPI(title="Puskesmas Digital API", version="1.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Inisialisasi Firebase (Aman untuk Cloud) ---
def get_firebase_db():
    if not firebase_admin._apps:
        try:
            if FIREBASE_JSON_CONTENT:
                # Menggunakan JSON dari Environment Variable (Railway)
                cred_dict = json.loads(FIREBASE_JSON_CONTENT)
                cred = credentials.Certificate(cred_dict)
            else:
                # Fallback ke file lokal jika sedang testing di laptop
                cred = credentials.Certificate('firebase.json')
            firebase_admin.initialize_app(cred)
        except Exception as e:
            print(f"Error Firebase: {e}")
            return None
    return firestore.client()

# --- Auth Security ---
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")

def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise HTTPException(status_code=401, detail="Token tidak valid")
        return username
    except jwt.PyJWTError:
        raise HTTPException(status_code=401, detail="Token tidak valid atau kedaluwarsa")

# --- Endpoints ---
@app.post("/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends()):
    if form_data.username != "admin" or form_data.password != "admin123":
        raise HTTPException(status_code=400, detail="Username atau password salah")
    
    expire = datetime.now(timezone.utc) + timedelta(minutes=120)
    token = jwt.encode({"sub": form_data.username, "exp": expire}, SECRET_KEY, algorithm=ALGORITHM)
    return {"access_token": token, "token_type": "bearer"}

@app.get("/api/sus-statistics")
def get_sus_statistics(current_user: str = Depends(get_current_user)):
    db = get_firebase_db()
    if not db:
        raise HTTPException(status_code=503, detail="Koneksi Firebase gagal diinisialisasi")
    
    try:
        docs = db.collection("sus_results").stream()
        scores = [d.to_dict().get("final_score", 0) for d in docs]
        avg = sum(scores) / len(scores) if scores else 0
        return {
            "rata_rata_sus": round(avg, 2),
            "total_responden": len(scores),
            "kategori": "Excellent" if avg > 80 else "Good" if avg > 68 else "Marginal/Poor"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)