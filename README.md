# Portal MGMP Informatika (PWA)

Aplikasi Portal MGMP Informatika Kota Bandar Lampung: presensi (wajah + lokasi), pertemuan,
ketidakhadiran, galeri/data konten, kartu anggota, dan rekap. Database: Supabase. Hosting: Vercel (via GitHub).

## Struktur
```
.
├── public/                  <- seluruh file situs (di-deploy apa adanya)
│   ├── index.html
│   ├── pwa.js
│   ├── sw.js                <- naikkan VERSION setiap index.html berubah
│   ├── manifest.webmanifest
│   └── icons/
├── supabase/                <- SQL migrasi (jalankan di Supabase SQL Editor)
├── vercel.json              <- output directory + header keamanan/cache
├── package.json
├── .gitignore
└── PANDUAN.md
```
Tidak ada proses build. Vercel langsung menyajikan folder `public/`.

## Jalankan lokal
```bash
npm run dev      # membuka http://localhost:3000
```
Kamera dan lokasi hanya berfungsi di `localhost` atau HTTPS.

## Deploy
Lihat `PANDUAN.md`.

## Buat Akun
Halaman login mendukung pendaftaran mandiri (tombol *Buat Akun*) dengan persetujuan admin. Jalankan `supabase/migrasi-pendaftaran-akun.sql` lebih dulu; lihat `PANDUAN.md` bagian 9.
