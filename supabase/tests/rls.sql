-- Run as postgres against a disposable local Supabase DB after migrations.
-- All fixture data rolls back. Never run against production.
begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('10000000-0000-0000-0000-000000000001','owner-a@example.test',now()),
 ('10000000-0000-0000-0000-000000000002','owner-b@example.test',now()),
 ('10000000-0000-0000-0000-000000000003','employee@example.test',now()),
 ('10000000-0000-0000-0000-000000000004','intruder@example.test',now());

set local role authenticated;
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
select public.create_business('Test A','Delodajalec A');
select public.invite_employee('employee@example.test','Strežba',10,40);
select set_config('test.invite',(select token::text from public.invitations limit 1),true);
select set_config('test.business_a',(select id::text from public.businesses limit 1),true);

-- An invitation cannot be claimed by another email.
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000004',true);
do $$ begin
  begin
    perform public.join_business(current_setting('test.invite')::uuid,'Vsiljivec');
    raise exception 'FAIL: wrong email accepted invitation';
  exception when raise_exception then
    if sqlerrm like 'FAIL:%' then raise; end if;
  end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
select public.join_business(current_setting('test.invite')::uuid,'Delavec');
select set_config('test.employee',(select id::text from public.business_members where user_id=auth.uid()),true);
insert into public.availabilities(business_id,member_id,starts_at,ends_at,available)
values(current_setting('test.business_a')::uuid,current_setting('test.employee')::uuid,'2026-11-23 00:00Z','2026-11-24 00:00Z',true);

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
select public.create_business('Test B','Delodajalec B');
do $$ begin
  if exists(select 1 from public.businesses where id=current_setting('test.business_a')::uuid) then raise exception 'FAIL: company isolation'; end if;
  if exists(select 1 from public.business_members where id=current_setting('test.employee')::uuid) then raise exception 'FAIL: employee leaked'; end if;
  if exists(select 1 from public.availabilities where business_id=current_setting('test.business_a')::uuid) then raise exception 'FAIL: availability leaked'; end if;
  begin
    insert into public.shifts(business_id,starts_at,ends_at,position) values(current_setting('test.business_a')::uuid,'2026-11-23 08:00Z','2026-11-23 16:00Z','Strežba');
    raise exception 'FAIL: cross company shift write';
  exception when insufficient_privilege or raise_exception then
    if sqlerrm like 'FAIL:%' then raise; end if;
  end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
insert into public.shifts(business_id,member_id,starts_at,ends_at,position)
values(current_setting('test.business_a')::uuid,current_setting('test.employee')::uuid,'2026-11-23 08:00Z','2026-11-23 16:00Z','Strežba');
select set_config('test.shift',(select id::text from public.shifts limit 1),true);
do $$ begin
  begin
    insert into public.shifts(business_id,member_id,starts_at,ends_at,position) values(current_setting('test.business_a')::uuid,current_setting('test.employee')::uuid,'2026-11-23 12:00Z','2026-11-23 20:00Z','Strežba');
    raise exception 'FAIL: overlapping assignment accepted';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
insert into public.work_logs(business_id,member_id,shift_id,starts_at,ends_at,break_minutes,hourly_rate)
values(current_setting('test.business_a')::uuid,current_setting('test.employee')::uuid,current_setting('test.shift')::uuid,'2026-11-23 08:00Z','2026-11-23 16:00Z',30,999);
select set_config('test.log',(select id::text from public.work_logs limit 1),true);
do $$ begin
  if (select hourly_rate from public.work_logs limit 1) <> 10 then raise exception 'FAIL: forged wage'; end if;
  begin
    perform public.review_work_log(current_setting('test.log')::uuid,true,'');
    raise exception 'FAIL: employee approved own hours';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
  begin
    update public.work_logs set status='approved' where id=current_setting('test.log')::uuid;
    raise exception 'FAIL: employee directly updated approval';
  exception when insufficient_privilege then null; end;
  begin
    update public.business_members set role='employer' where id=current_setting('test.employee')::uuid;
    raise exception 'FAIL: employee promoted self';
  exception when insufficient_privilege then null; end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000002',true);
do $$ begin
  if exists(select 1 from public.work_logs where id=current_setting('test.log')::uuid) then raise exception 'FAIL: work log leaked'; end if;
  begin
    perform public.review_work_log(current_setting('test.log')::uuid,true,'');
    raise exception 'FAIL: foreign employer approved hours';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
end $$;

select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
select public.review_work_log(current_setting('test.log')::uuid,true,'');
do $$ begin
  if (select status from public.work_logs where id=current_setting('test.log')::uuid)<>'approved' then raise exception 'FAIL: employer approval'; end if;
end $$;

-- Atomic confirmation: a later conflict rolls back the earlier assignment.
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000003',true);
insert into public.availabilities(business_id,member_id,starts_at,ends_at,available)
values(current_setting('test.business_a')::uuid,current_setting('test.employee')::uuid,'2026-11-24 00:00Z','2026-11-25 00:00Z',true);
select set_config('request.jwt.claim.sub','10000000-0000-0000-0000-000000000001',true);
insert into public.shifts(id,business_id,starts_at,ends_at,position) values
 ('20000000-0000-0000-0000-000000000001',current_setting('test.business_a')::uuid,'2026-11-24 08:00Z','2026-11-24 16:00Z','Strežba'),
 ('20000000-0000-0000-0000-000000000002',current_setting('test.business_a')::uuid,'2026-11-24 09:00Z','2026-11-24 17:00Z','Strežba');
do $$ declare proposal jsonb; begin
  select jsonb_agg(jsonb_build_object('id',id,'member_id',current_setting('test.employee'),'updated_at',updated_at) order by id) into proposal from public.shifts where member_id is null;
  begin
    perform public.confirm_schedule(proposal);
    raise exception 'FAIL: conflicting proposal accepted';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
  if exists(select 1 from public.shifts where id='20000000-0000-0000-0000-000000000001' and member_id is not null) then raise exception 'FAIL: partial proposal saved'; end if;
  begin
    perform public.confirm_schedule(jsonb_build_array(jsonb_build_object('id','20000000-0000-0000-0000-000000000001','member_id',current_setting('test.employee'),'updated_at','2000-01-01T00:00:00Z')));
    raise exception 'FAIL: stale proposal accepted';
  exception when raise_exception then if sqlerrm like 'FAIL:%' then raise; end if; end;
end $$;
rollback;
