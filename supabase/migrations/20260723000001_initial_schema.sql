-- =====================================================
-- Migration 001: Initial schema
-- Blog/Forum database — tables, triggers, RLS & storage
-- =====================================================

-- 1. EXTENSIONS
create extension if not exists "uuid-ossp";

-- 2. TABLES
create table if not exists public.profiles (
  id          uuid primary key references auth.users(id) on delete cascade,
  email       text not null,
  full_name   text not null default 'User',
  avatar_url  text,
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);

create table if not exists public.posts (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null check (char_length(title) between 1 and 200),
  content    text not null check (char_length(content) between 1 and 10000),
  images     text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_created_at_idx on public.posts (created_at desc);
create index if not exists posts_user_id_idx    on public.posts (user_id);

create table if not exists public.comments (
  id         uuid primary key default uuid_generate_v4(),
  post_id    uuid not null references public.posts(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  content    text not null check (char_length(content) between 1 and 2000),
  images     text[] not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists comments_post_id_idx on public.comments (post_id);

-- 3. TRIGGERS

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, email, full_name)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'full_name', 'User')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Auto-update updated_at
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.tg_set_updated_at();

drop trigger if exists posts_set_updated_at on public.posts;
create trigger posts_set_updated_at
  before update on public.posts
  for each row execute function public.tg_set_updated_at();

drop trigger if exists comments_set_updated_at on public.comments;
create trigger comments_set_updated_at
  before update on public.comments
  for each row execute function public.tg_set_updated_at();

-- 4. ROW-LEVEL SECURITY

alter table public.profiles enable row level security;
alter table public.posts    enable row level security;
alter table public.comments enable row level security;

-- PROFILES
drop policy if exists "profiles_read_all"   on public.profiles;
drop policy if exists "profiles_insert_own" on public.profiles;
drop policy if exists "profiles_update_own" on public.profiles;

create policy "profiles_read_all"
  on public.profiles for select
  using (true);

create policy "profiles_insert_own"
  on public.profiles for insert
  with check (auth.uid() = id);

create policy "profiles_update_own"
  on public.profiles for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- POSTS
drop policy if exists "posts_read_all"   on public.posts;
drop policy if exists "posts_insert_own" on public.posts;
drop policy if exists "posts_update_own" on public.posts;
drop policy if exists "posts_delete_own" on public.posts;

create policy "posts_read_all"
  on public.posts for select
  using (true);

create policy "posts_insert_own"
  on public.posts for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "posts_update_own"
  on public.posts for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "posts_delete_own"
  on public.posts for delete
  to authenticated
  using (auth.uid() = user_id);

-- COMMENTS
drop policy if exists "comments_read_all"    on public.comments;
drop policy if exists "comments_insert_auth" on public.comments;
drop policy if exists "comments_update_own"  on public.comments;
drop policy if exists "comments_delete_own"  on public.comments;

create policy "comments_read_all"
  on public.comments for select
  using (true);

create policy "comments_insert_auth"
  on public.comments for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "comments_update_own"
  on public.comments for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "comments_delete_own"
  on public.comments for delete
  to authenticated
  using (auth.uid() = user_id);

-- 5. STORAGE

insert into storage.buckets (id, name, public)
values ('blog-media', 'blog-media', true)
on conflict (id) do nothing;

drop policy if exists "blog_media_read"   on storage.objects;
drop policy if exists "blog_media_insert" on storage.objects;
drop policy if exists "blog_media_update" on storage.objects;
drop policy if exists "blog_media_delete" on storage.objects;

create policy "blog_media_read"
  on storage.objects for select
  using (bucket_id = 'blog-media');

create policy "blog_media_insert"
  on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'blog-media'
    and (storage.foldername(name))[1] in ('avatars','posts','comments')
  );

create policy "blog_media_update"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'blog-media' and owner = auth.uid())
  with check (bucket_id = 'blog-media' and owner = auth.uid());

create policy "blog_media_delete"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'blog-media' and owner = auth.uid());
