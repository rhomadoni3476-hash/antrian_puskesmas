from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
from models import RekamMedisDB  # Pastikan import ini sesuai dengan struktur folder Anda
from database import Base, engine 

# Buat session ke database
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def isi_data():
    data_dummy = [
        RekamMedisDB(id_pasien="P001", nama="Budi Santoso", keluhan="Demam tinggi", diagnosa="Flu", status="Selesai"),
        RekamMedisDB(id_pasien="P002", nama="Siti Aminah", keluhan="Batuk pilek", diagnosa="ISPA", status="Proses"),
        RekamMedisDB(id_pasien="P003", nama="Andi Wijaya", keluhan="Sakit kepala", diagnosa="Migrain", status="Menunggu"),
    ]
    
    db.add_all(data_dummy)
    db.commit()
    print("Data dummy berhasil dimasukkan ke database!")

if __name__ == "__main__":
    isi_data()