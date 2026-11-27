-- Test-only Supabase Auth seam for an EMPTY disposable PostgreSQL database.
-- Never apply this file to a Supabase project, where Auth already exists.
create role anon;
create role authenticated;
create schema auth;
create table auth.users(id uuid primary key,email text,email_confirmed_at timestamptz);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid;
$$;
grant usage on schema auth to authenticated;
grant execute on function auth.uid() to authenticated;
