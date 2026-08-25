-- Finora 数据库初始化脚本
-- 在 Supabase SQL Editor 中执行一次即可。

create extension if not exists "pgcrypto";

-- ============================================================
-- 用户资料
-- ============================================================
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  phone text,
  nickname text not null default '用户',
  avatar_url text,
  default_currency text not null default 'CNY',
  language text not null default 'zh_CN',
  is_admin boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 资金账户
-- ============================================================
create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  type text not null check (type in (
    'wechat','alipay','cash','bankCard','creditCard','savings','investment','wallet','other'
  )),
  balance numeric(16,2) not null default 0,
  icon text not null default 'wallet',
  color integer not null default 4282563051,
  sort_order integer not null default 0,
  archived boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- ============================================================
-- 分类（系统分类 user_id 为空，用户自定义分类绑定 user_id）
-- ============================================================
create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.profiles(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  name text not null,
  icon text not null default 'more',
  color integer not null default 4287198392,
  is_system boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 账单
-- ============================================================
create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  type text not null check (type in ('income','expense')),
  amount numeric(16,2) not null check (amount > 0),
  category_id uuid not null references public.categories(id),
  account_id uuid not null references public.accounts(id),
  happened_at timestamptz not null default now(),
  note text not null default '',
  image_url text,
  import_source text not null default 'manual'
    check (import_source in ('manual','wechat','alipay','csv')),
  external_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, external_id)
);

-- ============================================================
-- 预算
-- ============================================================
create table if not exists public.budgets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  scope text not null check (scope in ('total','category')),
  amount numeric(16,2) not null check (amount > 0),
  period text not null,
  category_id uuid references public.categories(id),
  notify_80 boolean not null default true,
  notify_100 boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists budgets_unique_per_user
  on public.budgets (user_id, scope, period, coalesce(category_id, '00000000-0000-0000-0000-000000000000'::uuid));

-- ============================================================
-- 推送 / 通知 / 订阅 / 导入批次 / 行为事件
-- ============================================================
create table if not exists public.push_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token text not null unique,
  platform text not null default 'android',
  created_at timestamptz not null default now()
);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null default '',
  type text not null default 'general',
  read boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  plan text not null default 'free',
  status text not null default 'active',
  provider text,
  provider_id text,
  started_at timestamptz,
  renews_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

create table if not exists public.import_batches (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  source text not null,
  file_name text not null default '',
  total_rows integer not null default 0,
  imported_rows integer not null default 0,
  skipped_rows integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.app_events (
  id bigint generated always as identity primary key,
  user_id uuid references public.profiles(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

-- ============================================================
-- 索引
-- ============================================================
create index if not exists idx_accounts_user on public.accounts(user_id, sort_order);
create index if not exists idx_categories_type on public.categories(type, sort_order);
create index if not exists idx_transactions_user_time on public.transactions(user_id, happened_at desc);
create index if not exists idx_transactions_category on public.transactions(category_id);
create index if not exists idx_transactions_account on public.transactions(account_id);
create index if not exists idx_budgets_user_period on public.budgets(user_id, period);
create index if not exists idx_events_user_time on public.app_events(user_id, created_at desc);

-- ============================================================
-- 更新时间和新用户初始化
-- ============================================================
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_profiles_updated_at on public.profiles;
create trigger set_profiles_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();

drop trigger if exists set_accounts_updated_at on public.accounts;
create trigger set_accounts_updated_at
before update on public.accounts
for each row execute function public.set_updated_at();

drop trigger if exists set_transactions_updated_at on public.transactions;
create trigger set_transactions_updated_at
before update on public.transactions
for each row execute function public.set_updated_at();

drop trigger if exists set_budgets_updated_at on public.budgets;
create trigger set_budgets_updated_at
before update on public.budgets
for each row execute function public.set_updated_at();

create or replace function public.seed_defaults(p_user_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  insert into public.accounts (user_id, name, type, icon, color, sort_order) values
    (p_user_id, '微信支付', 'wechat', 'wechat', 4282563051, 0),
    (p_user_id, '支付宝', 'alipay', 'alipay', 4287092471, 1),
    (p_user_id, '现金', 'cash', 'cash', 4283508571, 2),
    (p_user_id, '银行卡', 'bankCard', 'bank', 4281658819, 3);

  insert into public.categories (user_id, type, name, icon, color, is_system, sort_order) values
    (p_user_id, 'expense', '餐饮', 'restaurant', 4291602565, true, 0),
    (p_user_id, 'expense', '购物', 'cart', 4292953611, true, 1),
    (p_user_id, 'expense', '交通', 'transit', 4282408184, true, 2),
    (p_user_id, 'expense', '娱乐', 'movie', 4287236858, true, 3),
    (p_user_id, 'expense', '住房', 'home', 4292694710, true, 4),
    (p_user_id, 'expense', '水电', 'bolt', 4293401124, true, 5),
    (p_user_id, 'expense', '学习', 'school', 4284929786, true, 6),
    (p_user_id, 'expense', '医疗', 'medical', 4284473241, true, 7),
    (p_user_id, 'expense', '旅行', 'flight', 4282410223, true, 8),
    (p_user_id, 'expense', '其他', 'more', 4293659320, true, 9),
    (p_user_id, 'income', '工资', 'salary', 4284473241, true, 10),
    (p_user_id, 'income', '奖金', 'gift', 4292953611, true, 11),
    (p_user_id, 'income', '投资', 'trending', 4282408184, true, 12),
    (p_user_id, 'income', '红包', 'redpacket', 4291602565, true, 13),
    (p_user_id, 'income', '兼职', 'parttime', 4287236858, true, 14),
    (p_user_id, 'income', '其他', 'more', 4293659320, true, 15);
end;
$$;

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, email, phone, nickname, avatar_url)
  values (
    new.id,
    new.email,
    new.phone,
    coalesce(new.raw_user_meta_data ->> 'nickname', '用户'),
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  perform public.seed_defaults(new.id);
  insert into public.subscriptions (user_id, plan, status) values (new.id, 'free', 'active')
  on conflict (user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

-- ============================================================
-- 行级安全策略
-- ============================================================
alter table public.profiles enable row level security;
alter table public.accounts enable row level security;
alter table public.categories enable row level security;
alter table public.transactions enable row level security;
alter table public.budgets enable row level security;
alter table public.push_tokens enable row level security;
alter table public.notifications enable row level security;
alter table public.subscriptions enable row level security;
alter table public.import_batches enable row level security;
alter table public.app_events enable row level security;

create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);
create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

create policy "accounts_select_own" on public.accounts
  for select using (auth.uid() = user_id);
create policy "accounts_insert_own" on public.accounts
  for insert with check (auth.uid() = user_id);
create policy "accounts_update_own" on public.accounts
  for update using (auth.uid() = user_id);
create policy "accounts_delete_own" on public.accounts
  for delete using (auth.uid() = user_id);

create policy "categories_select_visible" on public.categories
  for select using (user_id is null or user_id = auth.uid());
create policy "categories_insert_own" on public.categories
  for insert with check (auth.uid() = user_id and is_system = false);
create policy "categories_update_own" on public.categories
  for update using (auth.uid() = user_id and is_system = false);
create policy "categories_delete_own" on public.categories
  for delete using (auth.uid() = user_id and is_system = false);

create policy "transactions_select_own" on public.transactions
  for select using (auth.uid() = user_id);
create policy "transactions_insert_own" on public.transactions
  for insert with check (auth.uid() = user_id);
create policy "transactions_update_own" on public.transactions
  for update using (auth.uid() = user_id);
create policy "transactions_delete_own" on public.transactions
  for delete using (auth.uid() = user_id);

create policy "budgets_select_own" on public.budgets
  for select using (auth.uid() = user_id);
create policy "budgets_insert_own" on public.budgets
  for insert with check (auth.uid() = user_id);
create policy "budgets_update_own" on public.budgets
  for update using (auth.uid() = user_id);
create policy "budgets_delete_own" on public.budgets
  for delete using (auth.uid() = user_id);

create policy "tokens_select_own" on public.push_tokens
  for select using (auth.uid() = user_id);
create policy "tokens_insert_own" on public.push_tokens
  for insert with check (auth.uid() = user_id);
create policy "tokens_delete_own" on public.push_tokens
  for delete using (auth.uid() = user_id);

create policy "notifications_select_own" on public.notifications
  for select using (auth.uid() = user_id);
create policy "notifications_update_own" on public.notifications
  for update using (auth.uid() = user_id);

create policy "subscriptions_select_own" on public.subscriptions
  for select using (auth.uid() = user_id);

create policy "imports_select_own" on public.import_batches
  for select using (auth.uid() = user_id);
create policy "imports_insert_own" on public.import_batches
  for insert with check (auth.uid() = user_id);

create policy "events_select_own" on public.app_events
  for select using (auth.uid() = user_id);
create policy "events_insert_own" on public.app_events
  for insert with check (auth.uid() = user_id);

-- ============================================================
-- 存储桶：头像与账单截图
-- ============================================================
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true), ('receipts', 'receipts', true)
on conflict (id) do nothing;

create policy "avatars_public_read"
on storage.objects for select
using (bucket_id = 'avatars');

create policy "avatars_owner_write"
on storage.objects for insert
with check (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "avatars_owner_update"
on storage.objects for update
using (
  bucket_id = 'avatars'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "receipts_owner_read"
on storage.objects for select
using (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "receipts_owner_write"
on storage.objects for insert
with check (
  bucket_id = 'receipts'
  and (storage.foldername(name))[1] = auth.uid()::text
);
