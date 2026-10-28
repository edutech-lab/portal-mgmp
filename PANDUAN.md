# Panduan: Portal MGMP Informatika (GitHub -> Vercel)

## 1. Unggah ke GitHub
1. Buat repositori baru di GitHub (mis. `portal-mgmp`), **Private** disarankan.
2. Ekstrak zip ini. Isi folder (`public/`, `vercel.json`, `package.json`, `.gitignore`, `README.md`, `PANDUAN.md`)
   harus berada di **root** repositori, bukan di dalam folder tambahan.
3. Unggah: lewat GitHub web (Add file -> Upload files, seret semua isi folder) atau lewat Git:
   ```bash
   git init
   git add .
   git commit -m "Portal MGMP v3: backup & restore, siap Vercel"
   git branch -M main
   git remote add origin https://github.com/USERNAME/portal-mgmp.git
   git push -u origin main
   ```

## 2. Impor ke Vercel
1. Vercel -> Add New -> Project -> pilih repositori GitHub tadi -> Import.
2. Pengaturan sudah dibaca otomatis dari `vercel.json`. Pastikan tampil:
   - Framework Preset: **Other**
   - Build Command: kosong
   - Install Command: kosong
   - Output Directory: **public**
3. Klik **Deploy**. Tidak ada environment variable yang diperlukan (konfigurasi Supabase ada di `public/index.html`;
   kunci yang dipakai adalah publishable/anon key, bukan secret key).
4. Setiap `git push` ke `main` otomatis men-deploy ulang.

## 3. Supabase (setelah punya alamat Vercel)
Supabase -> Authentication -> URL Configuration: isi **Site URL** dengan alamat Vercel
(mis. `https://portal-mgmp.vercel.app` atau domain sekolah) dan tambahkan di **Redirect URLs**.
Database tidak berubah pada versi ini, jadi tidak ada SQL baru yang wajib dijalankan.

## 4. Domain sekolah (opsional)
Vercel -> Project -> Settings -> Domains -> tambahkan `mgmp.smpn1-bandarlampung.sch.id`,
lalu buat record DNS (CNAME) sesuai instruksi Vercel.

## 5. Backup & Restore Database (menu Pengaturan, khusus Admin)
**Unduh backup:** Masuk sebagai Admin -> Pengaturan -> *Backup & Restore Database* -> **Unduh Backup Sekarang**.
Hasilnya satu file `backup-portal-mgmp-TANGGAL-JAM.json` berisi tabel: pengaturan, anggota, pertemuan, presensi,
ketidakhadiran, konten.

**Pulihkan:** pilih file backup -> aplikasi memeriksa file dan menampilkan jumlah data di file vs saat ini -> pilih mode:
- **Gabungkan (disarankan):** menambah data yang belum ada dan menimpa data dengan id yang sama. Tidak menghapus apa pun.
- **Ganti total:** database dibuat sama persis dengan file backup; data yang tidak ada di backup dihapus permanen.

Sebelum pemulihan dimulai, aplikasi otomatis mengunduh `pengaman-sebelum-restore-....json` berisi kondisi database saat ini.
Simpan file itu sampai Anda yakin hasilnya benar.

Catatan penting:
- File foto/logo di Supabase Storage tidak ikut di-backup; yang tersimpan hanya tautannya. Simpan salinan bucket
  `foto-anggota` dan `logo` secara terpisah bila perlu.
- File backup berisi data pribadi anggota (username, password, data wajah). Jangan di-commit ke GitHub
  (sudah dicegah `.gitignore`), jangan dibagikan, dan simpan di tempat aman.
- Restore menulis ke database memakai akun Admin, jadi mengikuti kebijakan RLS. Jika muncul pesan
  "Akses ditolak database", akun Admin belum punya izin tulis (insert/update/delete) pada tabel yang disebut;
  jalankan ulang `setup-supabase (END).sql` Anda.
- Backup bersifat manual. Biasakan mengunduh sebelum perubahan besar (awal semester, impor data, dll).

## 6. Memperbarui aplikasi
1. Ubah file di `public/`. Naikkan `VERSION` di `public/sw.js` (sekarang `mgmp-v3`, berikutnya `mgmp-v4`, dst.).
2. `git commit` lalu `git push`. Vercel otomatis deploy.
3. Pengguna membuka aplikasi dengan internet aktif; tutup lalu buka lagi bila tampilan belum berubah.

## 7. Tombol Back di HP
- Jika ada jendela (dialog, konfirmasi, menu Lainnya) terbuka, Back menutupnya.
- Jika tidak, Back kembali ke halaman/menu sebelumnya.
- Di Beranda, Back pertama menampilkan "Tekan sekali lagi untuk keluar"; Back kedua (dalam sekitar 2 detik) keluar.
- Di layar login, Back langsung keluar. Setelah Keluar (logout), riwayat dibersihkan.

## 8. Catatan lain
- Izin kamera dan lokasi wajib diizinkan untuk presensi; GPS HP harus aktif.
- Di iPhone, aplikasi terpasang menyimpan data terpisah dari Safari: login sekali lagi setelah memasang.
- Ikon masih sementara; ganti 4 file di `public/icons/` dengan logo (192, 512, maskable 512, apple-touch 180).
- Pemecahan masalah: jika Vercel menampilkan 404, pastikan Output Directory = `public` dan `index.html` ada di dalamnya.
  Jika tampilan lama masih muncul, naikkan `VERSION` di `sw.js` lalu deploy ulang.
