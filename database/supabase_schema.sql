-- MindFlow Supabase Database Schema
-- Execute this SQL in your Supabase SQL Editor to initialize all tables, relationships, and security policies (RLS).

-- ── 0. RESET SCHEMAS (WARNING: Deletes existing data in these tables to perform a clean install) ──
drop table if exists public.insights cascade;
drop table if exists public.ai_conversations cascade;
drop table if exists public.mindo_conversations cascade;
drop table if exists public.user_achievements cascade;
drop table if exists public.achievements cascade;
drop table if exists public.user_missions cascade;
drop table if exists public.missions cascade;
drop table if exists public.mood_entries cascade;
drop table if exists public.profiles cascade;

drop trigger if exists on_auth_user_created on auth.users;
drop function if exists public.handle_new_user;

-- ── 1. PROFILES TABLE ───────────────────────────────────
create table public.profiles (
  id uuid references auth.users on delete cascade primary key,
  email text not null,
  name text,
  avatar_url text,
  total_xp integer default 0,
  current_streak integer default 0,
  longest_streak integer default 0,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  last_check_in timestamp with time zone,
  notifications_enabled boolean default true,
  reminder_time text,
  biometric_enabled boolean default false,
  is_onboarding_done boolean default false
);

alter table public.profiles enable row level security;

create policy "Users can view their own profile" on public.profiles
  for select using (auth.uid() = id);

create policy "Users can update their own profile" on public.profiles
  for update using (auth.uid() = id);

-- ── 2. MOOD ENTRIES TABLE ───────────────────────────────
create table public.mood_entries (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  overall_mood integer not null check (overall_mood >= 1 and overall_mood <= 10),
  emotions jsonb not null, -- Stores list of {type: String, intensity: Int}
  note text,
  triggers text[] default '{}'::text[],
  physical_symptoms text[] default '{}'::text[],
  social_context text[] default '{}'::text[],
  voice_note_url text,
  xp_earned integer default 10
);

alter table public.mood_entries enable row level security;

create policy "Users can view their own mood entries" on public.mood_entries
  for select using (auth.uid() = user_id);

create policy "Users can insert their own mood entries" on public.mood_entries
  for insert with check (auth.uid() = user_id);

create policy "Users can delete their own mood entries" on public.mood_entries
  for delete using (auth.uid() = user_id);

-- ── 3. MISSIONS TABLE ───────────────────────────────────
create table public.missions (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  emoji text not null,
  xp_reward integer not null,
  category text not null,
  target_count integer default 1
);

insert into public.missions (title, description, emoji, xp_reward, category, target_count) values
  ('Beber 2L de água', 'Mantenha seu corpo hidratado para ajudar na clareza mental.', '💧', 20, 'health', 1),
  ('Caminhar 15 minutos', 'Uma caminhada leve ajuda a clarear a mente e reduzir o cortisol.', '🚶', 30, 'body', 1),
  ('Escrever 3 pensamentos', 'Coloque no papel tudo o que está tirando seu foco.', '✍️', 25, 'mind', 1),
  ('5 sessões de respiração', 'Pratique a respiração consciente guiada com o Mindo.', '🧘', 100, 'mindfulness', 5),
  ('Dormir antes das 23h por 5 dias', 'Regule seu ciclo circadiano para melhorar a estabilidade emocional.', '😴', 150, 'routine', 5);

-- ── 4. USER MISSIONS (PROGRESS) ─────────────────────────
create table public.user_missions (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  mission_id uuid references public.missions(id) on delete cascade not null,
  status text not null check (status in ('available', 'inProgress', 'completed', 'failed')),
  current_count integer default 0,
  completed_at timestamp with time zone,
  expires_at timestamp with time zone not null,
  is_claimed boolean default false
);

alter table public.user_missions enable row level security;

create policy "Users can view their own mission progress" on public.user_missions
  for select using (auth.uid() = user_id);

create policy "Users can update their own mission progress" on public.user_missions
  for update using (auth.uid() = user_id);

-- ── 5. ACHIEVEMENTS TABLE ───────────────────────────────
create table public.achievements (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  description text not null,
  emoji text not null,
  category text not null,
  xp_reward integer not null,
  rarity text not null check (rarity in ('common', 'rare', 'epic', 'legendary'))
);

insert into public.achievements (title, description, emoji, category, xp_reward, rarity) values
  ('Primeiro Passo', 'Registrou seu humor pela primeira vez.', '🌱', 'general', 50, 'common'),
  ('Sem Parar', 'Mantenha um streak emocional de 7 dias.', '🔥', 'streak', 100, 'common'),
  ('Conversador Nato', 'Enviou mais de 50 mensagens para o Mindo.', '💬', 'social', 150, 'rare'),
  ('Explorador Mental', 'Identificou 10 gatilhos emocionais diferentes.', '🗺️', 'analysis', 200, 'epic'),
  ('Monge Zen', 'Completou 30 missões de mindfulness.', '🧘', 'mindfulness', 500, 'legendary');

-- ── 6. USER ACHIEVEMENTS ────────────────────────────────
create table public.user_achievements (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  achievement_id uuid references public.achievements(id) on delete cascade not null,
  unlocked_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.user_achievements enable row level security;

create policy "Users can view their own unlocked achievements" on public.user_achievements
  for select using (auth.uid() = user_id);

-- ── 7. MINDO CONVERSATIONS (SESSÕES) ───────────────────────────────────────
-- Cada linha representa uma sessão de conversa do usuário com o Mindo.
-- Completamente isolada por user_id.
create table public.mindo_conversations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null default 'Nova Conversa',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  message_count integer default 0,
  last_message text
);

alter table public.mindo_conversations enable row level security;

create policy "Users can view their own conversations" on public.mindo_conversations
  for select using (auth.uid() = user_id);

create policy "Users can insert their own conversations" on public.mindo_conversations
  for insert with check (auth.uid() = user_id);

create policy "Users can update their own conversations" on public.mindo_conversations
  for update using (auth.uid() = user_id);

create policy "Users can delete their own conversations" on public.mindo_conversations
  for delete using (auth.uid() = user_id);

-- ── 8. AI CONVERSATIONS (MENSAGENS) ─────────────────────────────────────────
-- Cada linha é uma mensagem dentro de uma sessão (conversation_id).
create table public.ai_conversations (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  conversation_id uuid references public.mindo_conversations(id) on delete cascade not null,
  content text not null,
  role text not null check (role in ('user', 'assistant', 'system')),
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.ai_conversations enable row level security;

create policy "Users can view their own AI chat history" on public.ai_conversations
  for select using (auth.uid() = user_id);

create policy "Users can insert their own AI messages" on public.ai_conversations
  for insert with check (auth.uid() = user_id);

create policy "Users can delete their own AI messages" on public.ai_conversations
  for delete using (auth.uid() = user_id);

-- ── 8. INSIGHTS TABLE ───────────────────────────────────
create table public.insights (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references public.profiles(id) on delete cascade not null,
  title text not null,
  content text not null,
  type text not null,
  emoji text not null,
  is_read boolean default false,
  metadata jsonb default '{}'::jsonb,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table public.insights enable row level security;

create policy "Users can view their own insights" on public.insights
  for select using (auth.uid() = user_id);

create policy "Users can update their own insights" on public.insights
  for update using (auth.uid() = user_id);

-- ── AUTOMATIC PROFILE CREATION TRIGGER ──────────────────
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, name, avatar_url, total_xp, current_streak, longest_streak, is_onboarding_done)
  values (
    new.id,
    new.email,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.raw_user_meta_data->>'avatar_url',
    0, 0, 0, false
  );
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();
