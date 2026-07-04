from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
import json
import firebase_admin
from firebase_admin import credentials, firestore, auth

# --- Konfigurasi ---
FIREBASE_JSON_CONTENT = os.getenv("FIREBASE_JSON_CONTENT")

app = FastAPI(title="Puskesmas Digital API - Full Integrated", version="2.2.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Inisialisasi Firebase ---
def initialize_firebase():
    if not firebase_admin._apps:
        try:
            if FIREBASE_JSON_CONTENT:
                cred_dict = json.loads(FIREBASE_JSON_CONTENT)
                cred = credentials.Certificate(cred_dict)
                firebase_admin.initialize_app(cred)
            else:
                cred = credentials.Certificate('firebase.json')
                firebase_admin.initialize_app(cred)
            print("Firebase terinisialisasi dengan sukses.")
        except Exception as e:
            print(f"Gagal inisialisasi Firebase: {e}")

initialize_firebase()

# --- Auth Security (Firebase Token) ---
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=f"Token tidak valid: {str(e)}",
        )

# --- Model Data ---
class RekamMedis(BaseModel):
    nik: str
    nama_pasien: str
    keluhan: str
    status: str

class UpdateStatusRequest(BaseModel):
    status: str

# --- Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Puskesmas Digital API is Running Securely"}

# 1. Statistik SUS
@app.get("/api/sus-statistics")
def get_sus_statistics(user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        docs = db.collection("sus_results").stream()
        scores = [d.to_dict().get("final_score", 0) for d in docs]
        avg = sum(scores) / len(scores) if scores else 0
        return {
            "status": "success",
            "data": {"rata_rata_sus": round(avg, 2), "total_responden": len(scores)}
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 2. Daftar Rekam Medis
@app.get("/daftar-rekam-medis")
def get_daftar_rekam_medis(user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        docs = db.collection("rekam_medis").stream()
        return [{"id": d.id, **d.to_dict()} for d in docs]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 3. Tambah Rekam Medis
@app.post("/tambah-rekam-medis")
def tambah_rekam_medis(data: RekamMedis, user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        new_doc = db.collection("rekam_medis").add(data.dict())
        return {"status": "success", "id": new_doc[1].id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 4. Update Status
@app.put("/update-status/{id}")
def update_status(id: str, request: UpdateStatusRequest, user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        db.collection("rekam_medis").document(id).update({"status": request.status})
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal update: {str(e)}")

# 5. Hapus Rekam Medis
@app.delete("/hapus-rekam-medis/{id}")
def hapus_rekam_medis(id: str, user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        db.collection("rekam_medis").document(id).delete()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))