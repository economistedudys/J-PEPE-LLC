-- ============================================
-- J Pepe LLC — Candidate Profiles Setup for Supabase
-- Run this entire script once in the Supabase SQL Editor
-- ============================================

-- 1. Table to store candidate profile data
create table if not exists public.candidates (
  id uuid references auth.users(id) on delete cascade primary key,
  full_name text,
  email text,
  phone text,
  category text,        -- e.g. "Call Center", "Bookkeeping", "Sales", "Healthcare", "Interpretation"
  cover_note text,
  resume_url text,
  created_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now()
);

-- 2. Enable Row Level Security (required so users only see/edit their own data)
alter table public.candidates enable row level security;

-- 3. Policy: a logged-in user can view their OWN profile
create policy "Candidates can view own profile"
  on public.candidates for select
  using (auth.uid() = id);

-- 4. Policy: a logged-in user can insert their OWN profile
create policy "Candidates can insert own profile"
  on public.candidates for insert
  with check (auth.uid() = id);

-- 5. Policy: a logged-in user can update their OWN profile
create policy "Candidates can update own profile"
  on public.candidates for update
  using (auth.uid() = id);

-- 6. Storage bucket for resumes (CVs)
insert into storage.buckets (id, name, public)
values ('resumes', 'resumes', true)
on conflict (id) do nothing;

-- 7. Policy: anyone logged in can upload their own resume
create policy "Users can upload their own resume"
  on storage.objects for insert
  with check (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- 8. Policy: anyone logged in can update/replace their own resume
create policy "Users can update their own resume"
  on storage.objects for update
  using (
    bucket_id = 'resumes'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

-- 9. Policy: resumes are publicly readable (so you, the admin, can open the link)
create policy "Resumes are publicly readable"
  on storage.objects for select
  using (bucket_id = 'resumes');
