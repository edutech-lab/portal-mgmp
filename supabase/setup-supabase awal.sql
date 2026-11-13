-- =====================================================================
-- SETUP DATABASE: PORTAL MGMP INFORMATIKA (TA 2026/2027)
-- Jalankan seluruh isi file ini di Supabase > SQL Editor > New query > Run
-- Aman dijalankan berulang kali (idempotent).
-- =====================================================================

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1. TABEL
-- ---------------------------------------------------------------------

-- Pengaturan aplikasi (selalu 1 baris, id = 1)
create table if not exists public.pengaturan (
  id            int primary key default 1 check (id = 1),
  nama_aplikasi text not null default 'Portal MGMP Informatika',
  mapel         text not null default 'Informatika',
  logo_url      text,
  tahun_ajaran  text not null default '2026/2027',
  updated_at    timestamptz not null default now()
);

insert into public.pengaturan (id, logo_url)
values (1, 'https://lh3.googleusercontent.com/d/1dCPVcVoQpqltJ2HBzkrKN3xoReAxTM-6')
on conflict (id) do nothing;

-- Untuk database yang SUDAH dibuat sebelumnya: ganti nama lama menjadi "Portal MGMP Informatika"
-- (hanya jika nama belum diubah manual lewat menu Pengaturan)
alter table public.pengaturan alter column nama_aplikasi set default 'Portal MGMP Informatika';
update public.pengaturan
   set nama_aplikasi = 'Portal MGMP Informatika', updated_at = now()
 where id = 1 and nama_aplikasi = 'Presensi MGMP Informatika';

-- Data anggota (kode, NIP/NIY, NUPTK disimpan sebagai TEXT)
create table if not exists public.anggota (
  id              uuid primary key default gen_random_uuid(),
  kode_anggota    text not null unique,
  nip_niy         text,
  nuptk           text,
  nama_lengkap    text not null,
  jenis_kelamin   text check (jenis_kelamin in ('Laki-laki','Perempuan')),
  tempat_lahir    text,
  tanggal_lahir   date,
  asal_sekolah    text,
  jabatan_mgmp    text default 'Anggota',
  username        text not null unique,
  password        text not null,          -- teks biasa (tanpa hash) sesuai permintaan
  foto_url        text,
  face_descriptor jsonb,                  -- vektor 128 angka hasil pengenalan wajah
  created_at      timestamptz not null default now()
);

-- Untuk database yang SUDAH dibuat sebelumnya: tambahkan kolom Asal Sekolah
alter table public.anggota add column if not exists asal_sekolah text;

-- Pertemuan
create table if not exists public.pertemuan (
  id              uuid primary key default gen_random_uuid(),
  judul           text not null default 'Pertemuan MGMP Informatika',
  tanggal         date not null,
  jam_mulai       time not null,
  jam_selesai     time not null,
  toleransi_menit int  not null default 30 check (toleransi_menit >= 0),
  dresscode       text,
  tempat          text,
  latitude        double precision not null,
  longitude       double precision not null,
  radius_meter    int  not null default 150 check (radius_meter > 0),
  tahun_ajaran    text,
  created_at      timestamptz not null default now(),
  check (jam_selesai > jam_mulai)
);

-- Presensi (sekali per anggota per pertemuan, tanpa presensi pulang)
create table if not exists public.presensi (
  id             uuid primary key default gen_random_uuid(),
  pertemuan_id   uuid not null references public.pertemuan(id) on delete cascade,
  anggota_id     uuid not null references public.anggota(id)  on delete cascade,
  waktu_presensi timestamptz not null default now(),
  latitude       double precision,
  longitude      double precision,
  jarak_meter    numeric,
  foto_selfie    text,
  skor_wajah     numeric,
  status         text not null check (status in ('Hadir','Terlambat')),
  created_at     timestamptz not null default now(),
  unique (pertemuan_id, anggota_id)
);

-- Ketidakhadiran
create table if not exists public.ketidakhadiran (
  id           uuid primary key default gen_random_uuid(),
  pertemuan_id uuid not null references public.pertemuan(id) on delete cascade,
  anggota_id   uuid not null references public.anggota(id)  on delete cascade,
  jenis        text not null default 'Izin' check (jenis in ('Sakit','Izin','Dinas','Lainnya')),
  alasan       text not null,
  status       text not null default 'Menunggu' check (status in ('Menunggu','Disetujui')),
  created_at   timestamptz not null default now(),
  unique (pertemuan_id, anggota_id)
);

-- Konten pembelajaran (dibagikan anggota; admin mengelola semua, anggota hanya miliknya)
create table if not exists public.konten (
  id               uuid primary key default gen_random_uuid(),
  judul            text not null,
  jenis_konten     text not null check (jenis_konten in ('Permainan Aktif','Media Belajar','Video Pembelajaran','Bahan Ajar','E-Book','Info Grafis','Augmented Reality (AR)','Artikel','Lainnya')),
  mapel            text not null check (mapel in ('Informatika','Koding dan Kecerdasan Artifisial (KKA)')),
  kelas            smallint not null check (kelas in (7,8,9)),
  deskripsi        text not null,
  link             text not null,
  anggota_id       uuid references public.anggota(id) on delete set null,  -- null = diinput oleh admin
  nama_kontributor text,                  -- salinan nama saat input (tetap tampil bila anggota dihapus)
  asal_sekolah     text,
  created_at       timestamptz not null default now()
);

create index if not exists idx_presensi_pertemuan on public.presensi (pertemuan_id);
create index if not exists idx_presensi_anggota   on public.presensi (anggota_id);
create index if not exists idx_izin_pertemuan     on public.ketidakhadiran (pertemuan_id);
create index if not exists idx_izin_anggota       on public.ketidakhadiran (anggota_id);
create index if not exists idx_pertemuan_tanggal  on public.pertemuan (tanggal);
create index if not exists idx_konten_anggota     on public.konten (anggota_id);
create index if not exists idx_konten_created     on public.konten (created_at desc);

-- ---------------------------------------------------------------------
-- 2. ROW LEVEL SECURITY
--    Hybrid login: Admin = role "authenticated" (Supabase Auth),
--    Anggota = role "anon" (login via tabel anggota).
--    Keduanya diberi akses penuh agar tidak ada "permission denied".
-- ---------------------------------------------------------------------
alter table public.pengaturan     enable row level security;
alter table public.anggota        enable row level security;
alter table public.pertemuan      enable row level security;
alter table public.presensi       enable row level security;
alter table public.ketidakhadiran enable row level security;
alter table public.konten         enable row level security;

do $$
declare t text;
begin
  foreach t in array array['pengaturan','anggota','pertemuan','presensi','ketidakhadiran','konten'] loop
    execute format('drop policy if exists "akses_penuh_%1$s" on public.%1$s', t);
    execute format('create policy "akses_penuh_%1$s" on public.%1$s for all to anon, authenticated using (true) with check (true)', t);
  end loop;
end $$;

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to anon, authenticated;

-- ---------------------------------------------------------------------
-- 3. STORAGE (SETUP FOLDER)
--    Bucket "logo"          : logo aplikasi
--    Bucket "foto-anggota"  : subfolder foto/ (foto anggota) dan selfie/ (bukti presensi)
--    Subfolder dibuat otomatis oleh aplikasi saat file pertama diunggah.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('logo',         'logo',         true, 2097152, array['image/jpeg','image/png','image/webp','image/gif']),
  ('foto-anggota', 'foto-anggota', true, 2097152, array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = true,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "mgmp_storage_select" on storage.objects;
drop policy if exists "mgmp_storage_insert" on storage.objects;
drop policy if exists "mgmp_storage_update" on storage.objects;
drop policy if exists "mgmp_storage_delete" on storage.objects;

create policy "mgmp_storage_select" on storage.objects for select to anon, authenticated
  using (bucket_id in ('logo','foto-anggota'));
create policy "mgmp_storage_insert" on storage.objects for insert to anon, authenticated
  with check (bucket_id in ('logo','foto-anggota'));
create policy "mgmp_storage_update" on storage.objects for update to anon, authenticated
  using (bucket_id in ('logo','foto-anggota')) with check (bucket_id in ('logo','foto-anggota'));
create policy "mgmp_storage_delete" on storage.objects for delete to anon, authenticated
  using (bucket_id in ('logo','foto-anggota'));

-- Muat ulang cache skema API agar kolom baru langsung terbaca
notify pgrst, 'reload schema';

-- Selesai. Lanjut: daftarkan 1 akun Admin di Authentication > Users.
