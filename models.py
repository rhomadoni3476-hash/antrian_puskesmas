from sqlalchemy import Column, Integer, String, DateTime
from datetime import datetime
from database import Base

class RekamMedisDB(Base):
    __tablename__ = "rekam_medis"

    id = Column(Integer, primary_key=True, index=True)
    id_pasien = Column(String, index=True)
    nama = Column(String)
    keluhan = Column(String)
    diagnosa = Column(String, nullable=True)
    
    # Menambahkan kolom tanggal agar error 'AttributeError' hilang
    tanggal_pemeriksaan = Column(DateTime, default=datetime.utcnow)
    
    # Menambahkan kolom status agar sinkron dengan fungsi updateStatus di Flutter
    status = Column(String, default="Menunggu")