from sqlalchemy.orm import sessionmaker
from database import engine 
from models import RekamMedisDB

# Membuat sesi ke database
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

def reset_data():
    try:
        # Menghapus semua data dari tabel rekam_medis
        num_rows_deleted = db.query(RekamMedisDB).delete()
        db.commit()
        print(f"Berhasil! Sebanyak {num_rows_deleted} data telah dihapus dari database.")
    except Exception as e:
        db.rollback()
        print(f"Terjadi kesalahan saat menghapus data: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    reset_data()