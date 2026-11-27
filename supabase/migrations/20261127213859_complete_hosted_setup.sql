-- Cover composite tenant foreign keys used by PostgREST and referential checks.
create index availability_business_member_idx on public.availabilities(business_id,member_id);
create index shifts_business_member_idx on public.shifts(business_id,member_id);
create index logs_business_member_idx on public.work_logs(business_id,member_id);
create index logs_business_shift_idx on public.work_logs(business_id,shift_id);

-- New hosted Supabase projects may include this event-trigger function.
-- Its automatic trigger still runs as postgres; API roles need no direct call.
-- Plain PostgreSQL used by CI does not include the function.
do $$
begin
  if to_regprocedure('public.rls_auto_enable()') is not null then
    execute 'revoke execute on function public.rls_auto_enable() from public, anon, authenticated';
  end if;
end;
$$;
