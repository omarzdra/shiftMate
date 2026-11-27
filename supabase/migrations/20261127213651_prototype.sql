-- Apply only to a separate ShiftMate development project. No production writes.
create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references auth.users(id),
  name text not null check (length(trim(name)) between 1 and 120),
  min_rest_hours numeric not null default 11 check (min_rest_hours between 0 and 48),
  created_at timestamptz not null default now()
);
create table public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  user_id uuid not null unique references auth.users(id),
  name text not null check (length(trim(name)) between 1 and 120),
  role text not null check (role in ('employer','employee')),
  position text not null default 'StreĹľba' check (length(trim(position)) between 1 and 80),
  hourly_rate numeric(10,2) not null default 0 check (hourly_rate between 0 and 10000),
  max_weekly_hours numeric not null default 40 check (max_weekly_hours between 1 and 168),
  created_at timestamptz not null default now(),
  unique(business_id,id)
);
create index members_business_idx on public.business_members(business_id);
create table public.invitations (
  token uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  email text not null check (email = lower(trim(email)) and email like '%@%'),
  position text not null check (length(trim(position)) between 1 and 80),
  hourly_rate numeric(10,2) not null check (hourly_rate between 0 and 10000),
  max_weekly_hours numeric not null check (max_weekly_hours between 1 and 168),
  expires_at timestamptz not null default now() + interval '7 days',
  created_at timestamptz not null default now(),
  unique(business_id,email)
);
create table public.availabilities (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  member_id uuid not null,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  available boolean not null default true,
  preference numeric not null default 0 check (preference between 0 and 10),
  created_at timestamptz not null default now(),
  foreign key (business_id,member_id) references public.business_members(business_id,id),
  check (ends_at > starts_at and ends_at <= starts_at + interval '24 hours')
);
create index availability_member_time_idx on public.availabilities(member_id,starts_at);
create index availability_business_idx on public.availabilities(business_id);
create table public.shifts (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  member_id uuid,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  position text not null check (length(trim(position)) between 1 and 80),
  updated_at timestamptz not null default clock_timestamp(),
  created_at timestamptz not null default now(),
  foreign key (business_id,member_id) references public.business_members(business_id,id),
  unique(business_id,id),
  check (ends_at > starts_at and ends_at <= starts_at + interval '24 hours')
);
create index shifts_business_time_idx on public.shifts(business_id,starts_at);
create index shifts_member_time_idx on public.shifts(member_id,starts_at);
create table public.work_logs (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id),
  member_id uuid not null,
  shift_id uuid not null unique,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  break_minutes integer not null default 0 check (break_minutes >= 0),
  note text not null default '' check (length(note) <= 2000),
  status text not null default 'pending' check (status in ('pending','approved','rejected')),
  rejection_reason text not null default '' check (length(rejection_reason) <= 2000),
  hourly_rate numeric(10,2) not null default 0 check (hourly_rate >= 0),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  foreign key (business_id,member_id) references public.business_members(business_id,id),
  foreign key (business_id,shift_id) references public.shifts(business_id,id),
  check (ends_at > starts_at and ends_at <= starts_at + interval '24 hours'),
  check (break_minutes * 60 < extract(epoch from ends_at-starts_at)),
  check (status <> 'rejected' or length(trim(rejection_reason)) > 0)
);
create index logs_business_status_idx on public.work_logs(business_id,status);
create index logs_member_time_idx on public.work_logs(member_id,starts_at);
create index logs_reviewer_idx on public.work_logs(reviewed_by);

-- Ownership lookup reads businesses, whose policy has no membership dependency.
create function private.owns(bid uuid) returns boolean language sql stable security invoker set search_path = '' as $$
  select exists(select 1 from public.businesses where id=bid and owner_id=(select auth.uid()));
$$;
create function private.member_of(bid uuid) returns boolean language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists(select 1 from public.business_members where business_id=bid and user_id=(select auth.uid()));
$$;
revoke all on function private.owns(uuid), private.member_of(uuid) from public,anon;
grant execute on function private.owns(uuid), private.member_of(uuid) to authenticated;

alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.invitations enable row level security;
alter table public.availabilities enable row level security;
alter table public.shifts enable row level security;
alter table public.work_logs enable row level security;

create policy profiles_self on public.profiles for select to authenticated using (id=(select auth.uid()));
create policy business_read on public.businesses for select to authenticated using (owner_id=(select auth.uid()) or private.member_of(id));
create policy members_read on public.business_members for select to authenticated using (user_id=(select auth.uid()) or private.owns(business_id));
create policy members_edit on public.business_members for update to authenticated using (private.owns(business_id) and role='employee') with check (private.owns(business_id) and role='employee');
create policy invites_read on public.invitations for select to authenticated using (private.owns(business_id));
create policy availability_read on public.availabilities for select to authenticated using (private.owns(business_id) or member_id in (select id from public.business_members where user_id=(select auth.uid())));
create policy availability_insert on public.availabilities for insert to authenticated with check (member_id in (select id from public.business_members where user_id=(select auth.uid()) and role='employee' and business_id=availabilities.business_id));
create policy availability_update on public.availabilities for update to authenticated using (member_id in (select id from public.business_members where user_id=(select auth.uid()) and role='employee')) with check (member_id in (select id from public.business_members where user_id=(select auth.uid()) and role='employee' and business_id=availabilities.business_id));
create policy availability_delete on public.availabilities for delete to authenticated using (member_id in (select id from public.business_members where user_id=(select auth.uid()) and role='employee'));
create policy shifts_read on public.shifts for select to authenticated using (private.owns(business_id) or member_id in (select id from public.business_members where user_id=(select auth.uid())));
create policy shifts_insert on public.shifts for insert to authenticated with check (private.owns(business_id));
create policy shifts_update on public.shifts for update to authenticated using (private.owns(business_id)) with check (private.owns(business_id));
create policy shifts_delete on public.shifts for delete to authenticated using (private.owns(business_id));
create policy logs_read on public.work_logs for select to authenticated using (private.owns(business_id) or member_id in (select id from public.business_members where user_id=(select auth.uid())));
create policy logs_insert on public.work_logs for insert to authenticated with check (status='pending' and member_id in (select id from public.business_members where user_id=(select auth.uid()) and role='employee' and business_id=work_logs.business_id));
-- No direct UPDATE privilege/policy on work_logs: only checked review RPC.
revoke all on public.profiles,public.businesses,public.business_members,public.invitations,public.availabilities,public.shifts,public.work_logs from anon,authenticated;
grant select on public.profiles,public.businesses,public.business_members,public.invitations,public.availabilities,public.shifts,public.work_logs to authenticated;
grant update(name,position,hourly_rate,max_weekly_hours) on public.business_members to authenticated;
grant insert,update,delete on public.availabilities,public.shifts to authenticated;
grant insert on public.work_logs to authenticated;

-- Internal mutations live in an unexposed schema. Public RPCs are invokers.
create function private.create_business(business_name text, full_name text) returns uuid language plpgsql security definer set search_path = '' as $$
declare bid uuid;
begin
  if auth.uid() is null or exists(select 1 from public.business_members where user_id=auth.uid()) then raise exception 'Uporabnik Ĺľe ima podjetje ali ni prijavljen'; end if;
  insert into public.profiles(id) values(auth.uid()) on conflict do nothing;
  insert into public.businesses(owner_id,name) values(auth.uid(),trim(business_name)) returning id into bid;
  insert into public.business_members(business_id,user_id,name,role) values(bid,auth.uid(),trim(full_name),'employer');
  return bid;
end; $$;
create function public.create_business(business_name text,full_name text) returns uuid language sql security invoker set search_path = '' as $$ select private.create_business(business_name,full_name); $$;

create function private.invite_employee(invite_email text,job_position text,rate numeric,max_hours numeric) returns uuid language plpgsql security definer set search_path = '' as $$
declare bid uuid; result uuid;
begin
  select id into bid from public.businesses where owner_id=auth.uid();
  if bid is null then raise exception 'Samo delodajalec lahko povabi zaposlenega'; end if;
  insert into public.invitations(business_id,email,position,hourly_rate,max_weekly_hours) values(bid,lower(trim(invite_email)),trim(job_position),rate,max_hours)
  on conflict(business_id,email) do update set token=gen_random_uuid(),position=excluded.position,hourly_rate=excluded.hourly_rate,max_weekly_hours=excluded.max_weekly_hours,expires_at=now()+interval '7 days'
  returning token into result;
  return result;
end; $$;
create function public.invite_employee(invite_email text,job_position text,rate numeric,max_hours numeric) returns uuid language sql security invoker set search_path = '' as $$ select private.invite_employee(invite_email,job_position,rate,max_hours); $$;

create function private.join_business(invite_token uuid,full_name text) returns void language plpgsql security definer set search_path = '' as $$
declare invitation public.invitations; verified_email text;
begin
  if auth.uid() is null then raise exception 'Prijava je obvezna'; end if;
  select lower(email) into verified_email from auth.users where id=auth.uid() and email_confirmed_at is not null;
  select * into invitation from public.invitations where token=invite_token and email=verified_email and expires_at>now() for update;
  if invitation.token is null then raise exception 'Vabilo ni veljavno ali e-poĹˇtni naslov ni potrjen'; end if;
  perform 1 from public.businesses where id=invitation.business_id for update;
  insert into public.profiles(id) values(auth.uid()) on conflict do nothing;
  insert into public.business_members(business_id,user_id,name,role,position,hourly_rate,max_weekly_hours) values(invitation.business_id,auth.uid(),trim(full_name),'employee',invitation.position,invitation.hourly_rate,invitation.max_weekly_hours);
  delete from public.invitations where token=invite_token;
end; $$;
create function public.join_business(invite_token uuid,full_name text) returns void language sql security invoker set search_path = '' as $$ select private.join_business(invite_token,full_name); $$;

-- Serialize company scheduling writes, availability changes, and member changes.
create function private.lock_business() returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if auth.uid() is null then raise exception 'Prijava je obvezna'; end if;
  if TG_OP='UPDATE' and new.business_id<>old.business_id then raise exception 'Podjetja ni mogoÄŤe spreminjati'; end if;
  if TG_OP='DELETE' then
    perform 1 from public.businesses where id=old.business_id for update;
    return old;
  end if;
  perform 1 from public.businesses where id=new.business_id for update;
  return new;
end; $$;
create trigger availability_lock before insert or update or delete on public.availabilities for each row execute function private.lock_business();
create trigger members_lock before update on public.business_members for each row execute function private.lock_business();
create trigger shifts_lock before insert or update or delete on public.shifts for each row execute function private.lock_business();

create function private.validate_shift() returns trigger language plpgsql security definer set search_path = '' as $$
declare employee public.business_members; rest numeric; week timestamptz; total numeric;
begin
  if auth.uid() is null or not exists(select 1 from public.businesses where id=new.business_id and owner_id=auth.uid()) then raise exception 'Dostop zavrnjen'; end if;
  if TG_OP='UPDATE' and exists(select 1 from public.work_logs where shift_id=old.id) and (new.member_id is distinct from old.member_id or new.starts_at<>old.starts_at or new.ends_at<>old.ends_at or new.position<>old.position) then raise exception 'Izmena z evidenco je zaklenjena'; end if;
  new.updated_at := clock_timestamp();
  if new.member_id is null then return new; end if;
  select * into employee from public.business_members where id=new.member_id and business_id=new.business_id and role='employee';
  if employee.id is null or employee.position<>new.position then raise exception 'Neustrezna delovna pozicija'; end if;
  if not exists(select 1 from public.availabilities where member_id=employee.id and available and starts_at<=new.starts_at and ends_at>=new.ends_at)
    or exists(select 1 from public.availabilities where member_id=employee.id and not available and starts_at<new.ends_at and ends_at>new.starts_at) then raise exception 'Ni razpoloĹľljivosti za celotno izmeno'; end if;
  select min_rest_hours into rest from public.businesses where id=new.business_id;
  if exists(select 1 from public.shifts where member_id=employee.id and id<>new.id and starts_at<new.ends_at+rest*interval '1 hour' and ends_at>new.starts_at-rest*interval '1 hour') then raise exception 'Prekrivanje izmen ali premalo poÄŤitka'; end if;
  week := date_trunc('week',new.starts_at at time zone 'UTC') at time zone 'UTC';
  while week<new.ends_at loop
    select coalesce(sum(extract(epoch from least(ends_at,week+interval '7 days')-greatest(starts_at,week))/3600),0) into total from public.shifts where member_id=employee.id and id<>new.id and starts_at<week+interval '7 days' and ends_at>week;
    total := total+extract(epoch from least(new.ends_at,week+interval '7 days')-greatest(new.starts_at,week))/3600;
    if total>employee.max_weekly_hours then raise exception 'PreseĹľene tedenske ure'; end if;
    week := week+interval '7 days';
  end loop;
  return new;
end; $$;
create trigger shifts_validate before insert or update on public.shifts for each row execute function private.validate_shift();

create function private.confirm_schedule(assignments jsonb) returns void language plpgsql security definer set search_path = '' as $$
declare bid uuid; item jsonb; current_shift public.shifts;
begin
  select id into bid from public.businesses where owner_id=auth.uid() for update;
  if bid is null then raise exception 'Dostop zavrnjen'; end if;
  if jsonb_typeof(assignments)<>'array' or jsonb_array_length(assignments)>500 then raise exception 'Neveljaven predlog'; end if;
  for item in select value from jsonb_array_elements(assignments) loop
    select * into current_shift from public.shifts where id=(item->>'id')::uuid and business_id=bid for update;
    if current_shift.id is null or current_shift.member_id is not null or current_shift.updated_at is distinct from (item->>'updated_at')::timestamptz then raise exception 'Predlog je zastarel. Ponovno pridobi podatke.'; end if;
    update public.shifts set member_id=(item->>'member_id')::uuid where id=current_shift.id;
  end loop;
end; $$;
create function public.confirm_schedule(assignments jsonb) returns void language sql security invoker set search_path = '' as $$ select private.confirm_schedule(assignments); $$;

create function private.validate_log() returns trigger language plpgsql security definer set search_path = '' as $$
declare shift public.shifts; employee public.business_members;
begin
  if auth.uid() is null then raise exception 'Prijava je obvezna'; end if;
  perform 1 from public.businesses where id=new.business_id for update;
  select * into employee from public.business_members where id=new.member_id and business_id=new.business_id and user_id=auth.uid() and role='employee';
  select * into shift from public.shifts where id=new.shift_id and business_id=new.business_id and member_id=new.member_id for update;
  if employee.id is null or shift.id is null or new.status<>'pending' or new.ends_at>now() then raise exception 'Neveljavna oddaja evidence'; end if;
  if exists(select 1 from public.work_logs where member_id=new.member_id and starts_at<new.ends_at and ends_at>new.starts_at) then raise exception 'Prekrivanje evidenc'; end if;
  new.hourly_rate := employee.hourly_rate;
  new.rejection_reason := '';
  new.reviewed_by := null;
  new.reviewed_at := null;
  return new;
end; $$;
create trigger log_validate before insert on public.work_logs for each row execute function private.validate_log();

create function private.review_work_log(log_id uuid,approve boolean,reason text) returns void language plpgsql security definer set search_path = '' as $$
declare entry public.work_logs;
begin
  select l.* into entry from public.work_logs l join public.businesses b on b.id=l.business_id where l.id=log_id and b.owner_id=auth.uid() for update of l;
  if entry.id is null or entry.status<>'pending' or exists(select 1 from public.business_members where id=entry.member_id and user_id=auth.uid()) then raise exception 'Potrditev ni dovoljena'; end if;
  if not approve and length(trim(reason))=0 then raise exception 'Vnesi razlog zavrnitve'; end if;
  update public.work_logs set status=case when approve then 'approved' else 'rejected' end,rejection_reason=case when approve then '' else trim(reason) end,reviewed_by=auth.uid(),reviewed_at=now() where id=log_id;
end; $$;
create function public.review_work_log(log_id uuid,approve boolean,reason text) returns void language sql security invoker set search_path = '' as $$ select private.review_work_log(log_id,approve,reason); $$;

revoke all on all functions in schema private from public,anon,authenticated;
grant execute on function private.owns(uuid),private.member_of(uuid),private.create_business(text,text),private.invite_employee(text,text,numeric,numeric),private.join_business(uuid,text),private.confirm_schedule(jsonb),private.review_work_log(uuid,boolean,text) to authenticated;
revoke all on function public.create_business(text,text),public.invite_employee(text,text,numeric,numeric),public.join_business(uuid,text),public.confirm_schedule(jsonb),public.review_work_log(uuid,boolean,text) from public,anon;
grant execute on function public.create_business(text,text),public.invite_employee(text,text,numeric,numeric),public.join_business(uuid,text),public.confirm_schedule(jsonb),public.review_work_log(uuid,boolean,text) to authenticated;
