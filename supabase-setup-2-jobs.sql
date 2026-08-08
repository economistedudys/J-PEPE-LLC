-- ============================================
-- J Pepe LLC — Jobs, Applications & Extended Profiles
-- Run this AFTER supabase-setup.sql, in SQL Editor
-- ============================================

-- 1. Expand the candidates table with richer profile fields
alter table public.candidates add column if not exists photo_url text;
alter table public.candidates add column if not exists cover_letter text;
alter table public.candidates add column if not exists experience text;
alter table public.candidates add column if not exists education text;

-- 2. Admin users table — anyone listed here can manage jobs & view all applications
create table if not exists public.admin_users (
  email text primary key
);
insert into public.admin_users (email) values
  ('jpepe@jpepellc.com'),
  ('contact@jpepellc.com')
on conflict (email) do nothing;

alter table public.admin_users enable row level security;
create policy "Admins can read admin list"
  on public.admin_users for select
  using (auth.jwt() ->> 'email' in (select email from public.admin_users));

-- 3. Jobs table — one row per open position
create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  category text not null,          -- Call Center, Bookkeeping, Sales, Healthcare Support, Interpretation
  location text default 'Remote · Worldwide',
  employment_type text default 'Full-time',   -- Full-time, Part-time, Contract
  schedule text,                    -- e.g. "Mon-Fri, 9am-5pm EST"
  summary text,                     -- short 1-2 sentence teaser
  description text,                 -- full job description
  responsibilities text,            -- bullet list, one per line
  requirements text,                -- bullet list, one per line
  working_conditions text,          -- bullet list, one per line (remote, equipment, pay cycle, etc.)
  is_active boolean default true,
  created_at timestamp with time zone default now()
);

alter table public.jobs enable row level security;

create policy "Anyone can view active jobs"
  on public.jobs for select
  using (is_active = true or auth.jwt() ->> 'email' in (select email from public.admin_users));

create policy "Admins can insert jobs"
  on public.jobs for insert
  with check (auth.jwt() ->> 'email' in (select email from public.admin_users));

create policy "Admins can update jobs"
  on public.jobs for update
  using (auth.jwt() ->> 'email' in (select email from public.admin_users));

create policy "Admins can delete jobs"
  on public.jobs for delete
  using (auth.jwt() ->> 'email' in (select email from public.admin_users));

-- 4. Applications table — links a candidate to a job, with a status
create table if not exists public.applications (
  id uuid primary key default gen_random_uuid(),
  candidate_id uuid references public.candidates(id) on delete cascade,
  job_id uuid references public.jobs(id) on delete cascade,
  cover_note text,
  status text default 'Submitted',  -- Submitted, Under Review, Interview, Offered, Hired, Rejected
  applied_at timestamp with time zone default now(),
  updated_at timestamp with time zone default now(),
  unique (candidate_id, job_id)
);

alter table public.applications enable row level security;

create policy "Candidates can view own applications"
  on public.applications for select
  using (auth.uid() = candidate_id or auth.jwt() ->> 'email' in (select email from public.admin_users));

create policy "Candidates can insert own applications"
  on public.applications for insert
  with check (auth.uid() = candidate_id);

create policy "Admins can update application status"
  on public.applications for update
  using (auth.jwt() ->> 'email' in (select email from public.admin_users));

-- 5. Allow admins to view ALL candidate profiles (not just their own)
create policy "Admins can view all candidates"
  on public.candidates for select
  using (auth.jwt() ->> 'email' in (select email from public.admin_users));

-- 6. Storage bucket for candidate photos
insert into storage.buckets (id, name, public)
values ('photos', 'photos', true)
on conflict (id) do nothing;

create policy "Users can upload their own photo"
  on storage.objects for insert
  with check (
    bucket_id = 'photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Users can update their own photo"
  on storage.objects for update
  using (
    bucket_id = 'photos'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

create policy "Photos are publicly readable"
  on storage.objects for select
  using (bucket_id = 'photos');

-- 7. Sample job postings to start with (edit or delete these later from the admin panel)
insert into public.jobs (title, category, summary, description, responsibilities, requirements, working_conditions)
values
(
  'Bilingual Customer Service Representative',
  'Call Center',
  'Handle inbound and outbound calls for a variety of clients, in English and Spanish.',
  'As a Bilingual Customer Service Representative, you will be the first point of contact for our clients'' customers — answering questions, resolving issues, and ensuring every caller feels heard and helped.',
  'Answer inbound calls professionally and promptly
Make outbound follow-up calls as needed
Log every interaction accurately in our system
Escalate complex issues to the right department
Meet quality and response-time targets',
  'Fluent in English and Spanish (written and spoken)
Reliable internet connection and quiet workspace
Prior customer service experience preferred
Comfortable with basic computer software
Strong communication and problem-solving skills',
  'Remote, work from anywhere
Full-time, 40 hours/week
Paid training provided
Bi-weekly pay cycle
Equipment: your own computer + headset required'
),
(
  'QuickBooks Online Bookkeeper',
  'Bookkeeping',
  'Maintain accurate financial records for small business clients using QuickBooks Online.',
  'We''re looking for a detail-oriented bookkeeper to manage day-to-day financial records for our client base, using QuickBooks Online Accountant (QBOA).',
  'Perform monthly bank and credit card reconciliations
Categorize transactions accurately
Prepare basic financial reports (P&L, balance sheet)
Support catch-up and cleanup bookkeeping projects
Coordinate with clients'' CPAs at tax time',
  'Experience with QuickBooks Online required
QBOA certification a plus
Strong attention to detail and accuracy
Understanding of basic accounting principles
Reliable and organized, able to manage multiple clients',
  'Remote, work from anywhere
Full-time
Flexible scheduling within business hours
Bi-weekly pay cycle'
),
(
  'Bilingual Interpreter (Spanish/English)',
  'Interpretation',
  'Provide live phone interpretation support so every caller is served in their preferred language.',
  'As a Bilingual Interpreter, you''ll join live calls to provide real-time interpretation between English and Spanish speakers, ensuring clear and accurate communication.',
  'Join live calls to interpret in real time
Maintain neutrality and accuracy in interpretation
Handle sensitive conversations professionally
Document call summaries as needed',
  'Native or near-native fluency in English and Spanish
Prior interpretation experience preferred
Excellent listening and communication skills
Ability to remain calm and professional under pressure',
  'Remote, work from anywhere
Part-time or full-time available
Flexible scheduling, including evenings/weekends
Per-call or hourly pay depending on role'
);
