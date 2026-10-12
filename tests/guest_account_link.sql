-- Run inside BEGIN/ROLLBACK after loading the migration. Create an old fixture
-- auth user before loading it, so backfill is exercised. No real users touched.
-- Setup:
-- create temp table guest_link_old_fixture(id uuid);
-- insert into guest_link_old_fixture values(gen_random_uuid());
-- insert into auth.users(id,raw_app_meta_data) select id,'{"provider":"google"}'::jsonb from guest_link_old_fixture;
-- Load supabase/migrations/*_guest_account_link.sql here.
create temp table guest_link_result(checks integer);
do $test$
declare
 old_id uuid; fresh_id uuid:=gen_random_uuid(); second_id uuid:=gen_random_uuid(); normal_id uuid:=gen_random_uuid(); bad_id uuid:=gen_random_uuid();
 sid uuid:=gen_random_uuid(); gid uuid:=gen_random_uuid(); next_gid uuid:=gen_random_uuid();
 data jsonb; result jsonb; nickname text:='게스'||substr(replace(gen_random_uuid()::text,'-',''),1,4); checks integer:=0;
begin
 select id into old_id from guest_link_old_fixture;
 insert into auth.users(id,raw_app_meta_data) values(fresh_id,'{"provider":"google"}'),(second_id,'{"provider":"kakao"}'),(normal_id,'{"provider":"google"}'),(bad_id,'{"provider":"google"}');
 insert into auth.sessions(id,user_id,aal) values(sid,old_id,'aal1');
 perform set_config('request.jwt.claim.sub',old_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',old_id,'role','authenticated','session_id',sid)::text,true);
 data:=jsonb_build_object('stage_progress.cfg',jsonb_build_object(
  'guest_identity',jsonb_build_object('id',gid),'meta',jsonb_build_object('gold',700,'research_points',17),
  'progress',jsonb_build_object('current_stage_id','stage_1','highest_unlocked_stage',5),
  'player_profile',jsonb_build_object('value',jsonb_build_object('nickname',nickname,'gender','female','required',true,'completed',true)),
  'guest_tutorial',jsonb_build_object('status','skipped','claimed',true)),
  'monster_collection.cfg',jsonb_build_object('monsters',jsonb_build_object('slime_unlocked',true,'slime_shards',5)));
 result:=public.link_guest_save(gid,data);
 if result->>'error'<>'already_registered' then raise exception 'zero/default existing account allowed: %',result; end if; checks:=checks+1;
 delete from auth.sessions where id=sid; insert into auth.sessions(id,user_id,aal) values(sid,fresh_id,'aal1');
 perform set_config('request.jwt.claim.sub',fresh_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',fresh_id,'role','authenticated','session_id',sid)::text,true);
 result:=public.link_guest_save(gid,data);
 if result->>'ok'<>'true' or result #>> '{payload,stage_progress.cfg,meta,gold}'<>'700' then raise exception 'fresh import failed: %',result; end if; checks:=checks+1;
 if result #>> '{payload,monster_collection.cfg,monsters,slime_shards}'<>'5' then raise exception 'collection lost'; end if; checks:=checks+1;
 if exists(select 1 from public.account_tutorials where user_id=fresh_id and (not reward_claimed or reward_gold<>1000 or status<>'skipped')) then raise exception 'tutorial ledger lost'; end if; checks:=checks+1;
 result:=public.link_guest_save(gid,jsonb_set(data,'{stage_progress.cfg,meta,gold}','999'::jsonb));
 if result->>'replayed'<>'true' or result #>> '{payload,stage_progress.cfg,meta,gold}'<>'700' then raise exception 'retry rewrites save'; end if; checks:=checks+1;
 result:=public.account_tutorial('skip',1);
 if result->>'granted'<>'0' or result #>> '{payload,stage_progress.cfg,meta,gold}'<>'700' then raise exception 'duplicate tutorial reward: %',result; end if; checks:=checks+1;
 result:=public.link_guest_save(next_gid,jsonb_set(data,'{stage_progress.cfg,guest_identity,id}',to_jsonb(next_gid::text)));
 if result->>'error'<>'already_registered' then raise exception 'existing overwritten'; end if; checks:=checks+1;
 delete from auth.sessions where id=sid; insert into auth.sessions(id,user_id,aal) values(sid,second_id,'aal1');
 perform set_config('request.jwt.claim.sub',second_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',second_id,'role','authenticated','session_id',sid)::text,true);
 result:=public.link_guest_save(gid,data);
 if result->>'error'<>'guest_already_linked' or exists(select 1 from public.account_save_snapshots where user_id=second_id) then raise exception 'guest duplicated across owners'; end if; checks:=checks+1;
 result:=public.link_guest_save(next_gid,jsonb_set(data,'{stage_progress.cfg,guest_identity,id}',to_jsonb(next_gid::text)));
 if result->>'ok'<>'true' or exists(select 1 from public.player_profiles where user_id=second_id) then raise exception 'nickname collision must preserve stats and require setup: %',result; end if; checks:=checks+1;
 delete from auth.sessions where id=sid; insert into auth.sessions(id,user_id,aal) values(sid,normal_id,'aal1');
 perform set_config('request.jwt.claim.sub',normal_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',normal_id,'role','authenticated','session_id',sid)::text,true);
 perform public.read_game_save();
 result:=public.link_guest_save(gen_random_uuid(),data);
 if result->>'error'<>'already_registered' then raise exception 'normal login registration not protected'; end if; checks:=checks+1;
 delete from auth.sessions where id=sid; insert into auth.sessions(id,user_id,aal) values(sid,bad_id,'aal1');
 perform set_config('request.jwt.claim.sub',bad_id::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',bad_id,'role','authenticated','session_id',sid)::text,true);
 result:=public.link_guest_save(gen_random_uuid(),data);
 if result->>'error'<>'invalid_save' or exists(select 1 from account_private.registrations where user_id=bad_id) then raise exception 'bad payload registered'; end if; checks:=checks+1;
 delete from auth.sessions where id=sid;
 result:=public.link_guest_save(gen_random_uuid(),data);
 if result->>'error'<>'inactive' then raise exception 'dead session accepted'; end if; checks:=checks+1;
 if has_function_privilege('anon','public.link_guest_save(uuid,jsonb)','EXECUTE') or has_table_privilege('authenticated','account_private.registrations','SELECT,INSERT,UPDATE,DELETE') then raise exception 'private boundary exposed'; end if; checks:=checks+1;
 insert into guest_link_result values(checks);
end $test$;
select checks as server_checks_passed from guest_link_result;
