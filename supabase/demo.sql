-- DEMONSTRATION PROJECT ONLY. First create and confirm these five Auth users.
-- Choose passwords in the Auth dashboard; no passwords belong in this file.
-- Explicit opt-in: SET shiftmate.allow_demo = 'yes'; then execute this file.
begin;
do $$
declare owner_uuid uuid; employee_uuid uuid; bid uuid; mid uuid; token uuid; person integer; day integer; day_start timestamptz; job text;
begin
  if current_setting('shiftmate.allow_demo',true) is distinct from 'yes' then raise exception 'Demo seed requires explicit opt-in on a separate development project'; end if;
  select id into owner_uuid from auth.users where email='owner@shiftmate.example.test' and email_confirmed_at is not null;
  if owner_uuid is null or (select count(*) from auth.users where email in ('ana@shiftmate.example.test','bor@shiftmate.example.test','cilka@shiftmate.example.test','denis@shiftmate.example.test') and email_confirmed_at is not null)<>4 then raise exception 'Create and confirm all five demo Auth accounts first'; end if;
  if exists(select 1 from public.business_members where user_id in (select id from auth.users where email like '%@shiftmate.example.test')) then raise exception 'Demo accounts already have memberships; no existing data was changed'; end if;
  perform set_config('request.jwt.claim.sub',owner_uuid::text,true);
  bid := public.create_business('Kavarna Jutro · DEMO','Omar Demo');
  for person in 1..4 loop
    select id into employee_uuid from auth.users where email=(array['ana@shiftmate.example.test','bor@shiftmate.example.test','cilka@shiftmate.example.test','denis@shiftmate.example.test'])[person];
    job := case when person=4 then 'Kuhinja' else 'Strežba' end;
    perform set_config('request.jwt.claim.sub',owner_uuid::text,true);
    token := public.invite_employee((array['ana@shiftmate.example.test','bor@shiftmate.example.test','cilka@shiftmate.example.test','denis@shiftmate.example.test'])[person],job,10+person,40);
    perform set_config('request.jwt.claim.sub',employee_uuid::text,true);
    perform public.join_business(token,(array['Ana Demo','Bor Demo','Cilka Demo','Denis Demo'])[person]);
    select id into mid from public.business_members where user_id=employee_uuid;
    for day in -1..6 loop
      day_start := (date_trunc('day',now() at time zone 'UTC') at time zone 'UTC')+day*interval '1 day';
      insert into public.availabilities(business_id,member_id,starts_at,ends_at,available) values(bid,mid,day_start,day_start+interval '24 hours',true);
    end loop;
  end loop;
  perform set_config('request.jwt.claim.sub',owner_uuid::text,true);
  for day in 1..5 loop
    day_start := (date_trunc('day',now() at time zone 'UTC') at time zone 'UTC')+day*interval '1 day'+interval '8 hours';
    insert into public.shifts(business_id,starts_at,ends_at,position) values(bid,day_start,day_start+interval '8 hours','Strežba'),(bid,day_start,day_start+interval '8 hours','Kuhinja');
  end loop;
  select id into mid from public.business_members where user_id=(select id from auth.users where email='ana@shiftmate.example.test');
  day_start := (date_trunc('day',now() at time zone 'UTC') at time zone 'UTC')-interval '1 day'+interval '8 hours';
  insert into public.shifts(business_id,member_id,starts_at,ends_at,position) values(bid,mid,day_start,day_start+interval '8 hours','Strežba');
end $$;
commit;
