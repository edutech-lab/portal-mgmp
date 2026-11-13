-- =====================================================================
-- Migrasi: fitur "Buat Akun" (pendaftaran mandiri anggota) - Portal MGMP
-- Jalankan SEKALI di Supabase -> SQL Editor, SEBELUM men-deploy index.html baru.
-- Aman dijalankan ulang. Tidak mengubah data yang sudah ada.
-- =====================================================================

-- 1. Kolom status akun. Semua anggota lama otomatis 'Aktif'.
alter table public.anggota
  add column if not exists status text not null default 'Aktif';

alter table public.anggota drop constraint if exists anggota_status_check;
alter table public.anggota
  add constraint anggota_status_check check (status in ('Aktif', 'Menunggu', 'Nonaktif'));

create index if not exists anggota_status_idx on public.anggota (status);

-- 2. Izinkan pengunjung (anon) MENDAFTAR, tetapi hanya sebagai 'Menunggu'.
--    Pendaftar tidak bisa mengaktifkan dirinya sendiri, memilih jabatan lain,
--    atau menyisipkan foto/data wajah lewat jalur ini.
alter table public.anggota enable row level security;

grant insert on public.anggota to anon;

drop policy if exists "Pendaftaran mandiri anggota" on public.anggota;
create policy "Pendaftaran mandiri anggota"
  on public.anggota
  for insert
  to anon
  with check (
    status = 'Menunggu'
    and jabatan_mgmp = 'Anggota'
    and tanggal_lahir is not null
    and foto_url is null
    and face_descriptor is null
  );

-- 2b. Tolak pendaftaran mandiri jika tanggal lahir sudah terdaftar (pelindung di database).
--     Hanya berlaku untuk INSERT berstatus 'Menunggu' (pendaftaran mandiri). Penambahan oleh admin,
--     impor Excel, dan data lama yang kebetulan sama tidak terpengaruh.
create index if not exists anggota_tanggal_lahir_idx on public.anggota (tanggal_lahir);

create or replace function public.tolak_pendaftaran_ganda()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.status = 'Menunggu' and new.tanggal_lahir is not null
     and exists (select 1 from public.anggota a where a.tanggal_lahir = new.tanggal_lahir) then
    raise exception 'AKUN_SUDAH_ADA' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists trg_tolak_pendaftaran_ganda on public.anggota;
create trigger trg_tolak_pendaftaran_ganda
  before insert on public.anggota
  for each row execute function public.tolak_pendaftaran_ganda();

-- 3. PERIKSA (wajib): daftar kebijakan yang berlaku pada tabel anggota.
--    Jika ada kebijakan untuk anon/public dengan cmd = 'ALL' atau 'INSERT'
--    yang kondisinya 'true' (tanpa batas), pendaftar bisa melewati persetujuan
--    dengan mengirim status = 'Aktif'. Ganti kebijakan itu agar tidak mencakup INSERT.
select policyname, roles, cmd, with_check
from pg_policies
where schemaname = 'public' and tablename = 'anggota'
order by policyname;
