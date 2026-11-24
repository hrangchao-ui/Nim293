-- RETRO JUKEBOX 80s / Supabase setup
-- Run in Supabase Dashboard -> SQL Editor using project owner privileges.
-- Important: Public bucket is appropriate ONLY for audio you are permitted to share.

create table if not exists public.admin_users (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.admin_users enable row level security;
-- Never create a public insert policy for admin_users.

create or replace function public.is_jukebox_admin()
returns boolean language sql stable security definer
set search_path = ''
as $$ select exists(select 1 from public.admin_users where user_id = (select auth.uid())); $$;
revoke all on function public.is_jukebox_admin() from public;
grant execute on function public.is_jukebox_admin() to authenticated;

create table if not exists public.songs (
  id uuid primary key default gen_random_uuid(),
  name text not null check (char_length(name) between 1 and 120),
  artist text not null check (char_length(artist) between 1 and 120),
  category text not null check (category in ('เพลงสากล','เพลงซึ้งกินใจ','เพลงเพื่อชีวิต','เพลงมันวัยเก๋า')),
  type text not null check(type in ('file','url')),
  file_path text unique,
  audio_url text,
  created_at timestamptz not null default now(),
  constraint valid_source check ((type='file' and file_path is not null and audio_url is null) or (type='url' and file_path is null and audio_url is not null))
);
alter table public.songs enable row level security;

drop policy if exists "jukebox songs read" on public.songs;
create policy "jukebox songs read" on public.songs for select to anon, authenticated using (true);
drop policy if exists "jukebox songs insert admin" on public.songs;
create policy "jukebox songs insert admin" on public.songs for insert to authenticated with check ((select public.is_jukebox_admin()));
drop policy if exists "jukebox songs update admin" on public.songs;
create policy "jukebox songs update admin" on public.songs for update to authenticated using ((select public.is_jukebox_admin())) with check ((select public.is_jukebox_admin()));
drop policy if exists "jukebox songs delete admin" on public.songs;
create policy "jukebox songs delete admin" on public.songs for delete to authenticated using ((select public.is_jukebox_admin()));

-- Public listening: knowing a file URL is enough to fetch it. Only share permitted audio.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('songs','songs',true,52428800,array['audio/mpeg','audio/mp3','audio/mp4','audio/x-m4a','audio/wav','audio/x-wav','audio/ogg'])
on conflict(id) do update set public=true, file_size_limit=excluded.file_size_limit, allowed_mime_types=excluded.allowed_mime_types;

-- No anonymous write permissions. Authorized Admin can upload/read/delete objects in songs bucket.
drop policy if exists "jukebox storage admin select" on storage.objects;
create policy "jukebox storage admin select" on storage.objects for select to authenticated using (bucket_id='songs' and (select public.is_jukebox_admin()));
drop policy if exists "jukebox storage admin insert" on storage.objects;
create policy "jukebox storage admin insert" on storage.objects for insert to authenticated with check (bucket_id='songs' and (select public.is_jukebox_admin()));
drop policy if exists "jukebox storage admin update" on storage.objects;
create policy "jukebox storage admin update" on storage.objects for update to authenticated using (bucket_id='songs' and (select public.is_jukebox_admin())) with check (bucket_id='songs' and (select public.is_jukebox_admin()));
drop policy if exists "jukebox storage admin delete" on storage.objects;
create policy "jukebox storage admin delete" on storage.objects for delete to authenticated using (bucket_id='songs' and (select public.is_jukebox_admin()));

-- Optional: Supabase Realtime, polling works even if this step is skipped.
do $$ begin
  alter publication supabase_realtime add table public.songs;
exception when duplicate_object then null;
end $$;

-- IMPORTANT: Create an Admin user in Authentication -> Users first.
-- Next, run this with the real user UUID (not email), replacing UUID_HERE:
-- insert into public.admin_users(user_id) values ('UUID_HERE') on conflict do nothing;
