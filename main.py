from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from datetime import datetime
import os
import json
import firebase_admin
from firebase_admin import credentials, firestore, auth

# --- Konfigurasi ---
FIREBASE_JSON_CONTENT = os.getenv("FIREBASE_JSON_CONTENT")

app = FastAPI(title="Puskesmas Digital API - Secure & RBAC", version="2.2.1")

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

# --- Auth & Security ---
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    token = credentials.credentials
    try:
        decoded_token = auth.verify_id_token(token)
        return decoded_token
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=f"Token tidak valid: {str(e)}")

def verify_admin(user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    user_ref = db.collection("users").document(user_data['uid']).get()
    user_data_db = user_ref.to_dict()
    
    if not user_data_db or user_data_db.get('role') != 'admin':
        raise HTTPException(status_code=403, detail="Akses ditolak: Memerlukan hak akses Admin")
    return user_data

# --- Model Data ---
class RekamMedis(BaseModel):
    nik: str = Field(..., min_length=16, max_length=16)
    nama_pasien: str
    keluhan: str
    status: str

class UpdateStatusRequest(BaseModel):
    status: str

# --- Endpoints ---

@app.get("/")
def read_root():
    return {"message": "Puskesmas Digital API is Running Securely"}

# 1. Statistik
@app.get("/api/sus-statistics")
def get_sus_statistics(user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        docs = db.collection("sus_results").stream()
        scores = [d.to_dict().get("final_score", 0) for d in docs]
        avg = sum(scores) / len(scores) if scores else 0
        return {"status": "success", "data": {"rata_rata_sus": round(avg, 2), "total_responden": len(scores)}}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 2. Daftar Rekam Medis (Admin Only)
@app.get("/daftar-rekam-medis")
def get_daftar_rekam_medis(admin: dict = Depends(verify_admin)):
    db = firestore.client()
    try:
        docs = db.collection("rekam_medis").order_by("created_at", direction=firestore.Query.DESCENDING).stream()
        return [{"id": d.id, **d.to_dict()} for d in docs]
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 3. Tambah Rekam Medis (Pasien & Admin)
@app.post("/tambah-rekam-medis")
def tambah_rekam_medis(data: RekamMedis, user_data: dict = Depends(get_current_user)):
    db = firestore.client()
    try:
        rekam_medis_dict = data.dict()
        rekam_medis_dict['user_id'] = user_data['uid']
        rekam_medis_dict['created_at'] = datetime.now().isoformat() # Menambahkan timestamp
        
        new_doc = db.collection("rekam_medis").add(rekam_medis_dict)
        return {"status": "success", "id": new_doc[1].id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 4. Update Status (Admin Only)
@app.put("/update-status/{id}")
def update_status(id: str, request: UpdateStatusRequest, admin: dict = Depends(verify_admin)):
    db = firestore.client()
    doc_ref = db.collection("rekam_medis").document(id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan")
    try:
        doc_ref.update({"status": request.status})
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Gagal update: {str(e)}")

# 5. Hapus Rekam Medis (Admin Only)
@app.delete("/hapus-rekam-medis/{id}")
def hapus_rekam_medis(id: str, admin: dict = Depends(verify_admin)):
    db = firestore.client()
    doc_ref = db.collection("rekam_medis").document(id)
    if not doc_ref.get().exists:
        raise HTTPException(status_code=404, detail="Data tidak ditemukan")
    try:
        doc_ref.delete()
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))