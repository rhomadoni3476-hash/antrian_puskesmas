# Menggunakan image Python versi slim agar ringan
FROM python:3.12-slim

# Menentukan direktori kerja di dalam kontainer
WORKDIR /app

# Menyalin requirements dan menginstalnya
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Menyalin seluruh kode proyek ke dalam kontainer
COPY . .

# Mengekspos port 8000
EXPOSE 8000

# Perintah untuk menjalankan aplikasi
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]