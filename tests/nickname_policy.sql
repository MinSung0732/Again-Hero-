-- Generated fixture accounts only; every insert/update is rolled back.
begin;
create temp table nickname_results(checks integer);
do $test$
declare a uuid:=gen_random_uuid(); b uuid:=gen_random_uuid(); linked uuid:=gen_random_uuid();
 sa uuid:=gen_random_uuid(); sb uuid:=gen_random_uuid(); sl uuid:=gen_random_uuid();
 guest uuid:=gen_random_uuid(); op uuid:=gen_random_uuid(); nonce uuid:=gen_random_uuid();
 result jsonb; payload jsonb; checks integer:=0; value text; name_a text; name_b text; old_name text;
begin
 insert into auth.users(id,raw_app_meta_data) values(a,'{"provider":"google"}'),(b,'{"provider":"google"}'),(linked,'{"provider":"google"}');
 insert into auth.sessions(id,user_id,aal) values(sa,a,'aal1'),(sb,b,'aal1'),(sl,linked,'aal1');
 perform set_config('request.jwt.claim.sub',a::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',a,'role','authenticated','session_id',sa)::text,true);
 if private.nickname_policy()->>'minimum'<>'2' or private.nickname_policy()->>'maximum'<>'6' then raise exception 'policy drift'; end if; checks:=checks+1;
 foreach value in array array['가','1234567','a b','ㄱㄴ','이름!',E'이름\n',''] loop
  result:=public.check_player_nickname(value);
  if result->>'error'<>'invalid' then raise exception 'invalid check accepted % %',value,result; end if;
  result:=public.register_player_profile(value,'male');
  if result->>'error'<>'invalid' then raise exception 'invalid register accepted % %',value,result; end if;
  checks:=checks+2;
 end loop;
 for i in 1..32 loop
  value:=private.random_player_nickname();
  if not private.nickname_valid(value) then raise exception 'invalid generated nickname'; end if; checks:=checks+1;
 end loop;
 name_a:=private.random_player_nickname(); name_b:=private.random_player_nickname();
 result:=public.check_player_nickname(name_a);
 if result->>'available'<>'true' then raise exception 'fresh check unavailable'; end if; checks:=checks+1;
 result:=public.register_player_profile(name_a,'male');
 if result #>> '{profile,nickname}'<>name_a then raise exception 'register failed %',result; end if; checks:=checks+1;
 result:=public.rename_player_nickname(name_b,op);
 if result->>'error'<>'locked' then raise exception 'ordinary account rename allowed %',result; end if; checks:=checks+1;
 perform set_config('request.jwt.claim.sub',b::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',b,'role','authenticated','session_id',sb)::text,true);
 result:=public.check_player_nickname(name_a);
 if result->>'available'<>'false' then raise exception 'duplicate check missing'; end if; checks:=checks+1;
 result:=public.register_player_profile(name_a,'female');
 if result->>'error'<>'duplicate' then raise exception 'final unique guard missing'; end if; checks:=checks+1;
 result:=public.register_player_profile(name_b,'female');
 if result #>> '{profile,nickname}'<>name_b then raise exception 'second account failed'; end if; checks:=checks+1;
 -- Import a guest whose locally generated name collides with an account.
 perform set_config('request.jwt.claim.sub',linked::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',linked,'role','authenticated','session_id',sl)::text,true);
 payload:=jsonb_build_object('stage_progress.cfg',jsonb_build_object('guest_identity',jsonb_build_object('id',guest),
  'player_profile',jsonb_build_object('value',jsonb_build_object('nickname',name_a,'gender','female','required',false,'completed',true)),
  'guest_tutorial',jsonb_build_object('status','completed','claimed',true),'meta',jsonb_build_object('gold',1234)));
 result:=public.link_guest_save(guest,payload);
 if result->>'ok'<>'true' or result #>> '{payload,stage_progress.cfg,meta,gold}'<>'1234' then raise exception 'guest import failed %',result; end if; checks:=checks+1;
 result:=public.read_player_profile(); old_name:=result #>> '{profile,nickname}';
 if old_name=name_a or not private.nickname_valid(old_name) or result #>> '{profile,nickname_changes_remaining}'<>'1' or result #>> '{profile,completed}'<>'true' then raise exception 'guest unique name/allowance %',result; end if; checks:=checks+1;
 result:=public.rename_player_nickname(name_b,op);
 if result->>'error'<>'duplicate' or (select nickname_changes_remaining from public.player_profiles where user_id=linked)<>1 then raise exception 'duplicate spent rename'; end if; checks:=checks+1;
 value:=private.random_player_nickname();
 result:=public.rename_player_nickname(value,op);
 if result #>> '{profile,nickname}'<>value or result #>> '{profile,nickname_changes_remaining}'<>'0' then raise exception 'rename failed %',result; end if; checks:=checks+1;
 result:=public.rename_player_nickname(value,op);
 if result #>> '{profile,nickname}'<>value then raise exception 'lost ack replay failed'; end if; checks:=checks+1;
 result:=public.rename_player_nickname(old_name,op);
 if result->>'error'<>'operation_reused' then raise exception 'operation reuse accepted'; end if; checks:=checks+1;
 result:=public.rename_player_nickname(old_name,gen_random_uuid());
 if result->>'error'<>'locked' then raise exception 'second rename accepted'; end if; checks:=checks+1;
 result:=public.link_guest_save(guest,payload);
 if result->>'replayed'<>'true' or (select nickname_changes_remaining from public.player_profiles where user_id=linked)<>0 then raise exception 'link retry regranted rename'; end if; checks:=checks+1;
 -- Cross-device fence also applies to availability/rename.
 perform public.cloud_sync('claim',nonce);
 perform set_config('request.headers','{}',true);
 result:=public.check_player_nickname(old_name);
 if result->>'session_replaced'<>'true' then raise exception 'check bypassed device fence'; end if; checks:=checks+1;
 result:=public.rename_player_nickname(value,op);
 if result->>'session_replaced'<>'true' then raise exception 'rename bypassed device fence'; end if; checks:=checks+1;
 if has_function_privilege('anon','public.check_player_nickname(text)','EXECUTE') or has_function_privilege('anon','public.rename_player_nickname(text,uuid)','EXECUTE') then raise exception 'anonymous name API exposed'; end if; checks:=checks+1;
 if has_table_privilege('authenticated','public.player_profiles','UPDATE') then raise exception 'direct rename bypass'; end if; checks:=checks+1;
 insert into nickname_results values(checks);
end $test$;
select checks as nickname_server_checks_passed from nickname_results;
rollback;
