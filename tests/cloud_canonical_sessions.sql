-- Execute as a single BEGIN/ROLLBACK transaction. Only generated fixture IDs.
begin;
create temp table cloud_session_results(checks integer);
do $test$
declare
 uid uuid:=gen_random_uuid(); sid_a uuid:=gen_random_uuid(); sid_b uuid:=gen_random_uuid();
 nonce_a uuid:=gen_random_uuid(); nonce_b uuid:=gen_random_uuid(); op uuid:=gen_random_uuid();
 result jsonb; data jsonb:='{"stage_progress.cfg":{"meta":{"gold":100}}}'; checks integer:=0;
begin
 insert into auth.users(id,raw_app_meta_data) values(uid,'{"provider":"google"}');
 insert into auth.sessions(id,user_id,aal) values(sid_a,uid,'aal1'),(sid_b,uid,'aal1');
 perform set_config('request.jwt.claim.sub',uid::text,true);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','session_id',sid_a)::text,true);
 perform set_config('request.headers',jsonb_build_object('x-game-session',nonce_a)::text,true);
 result:=public.cloud_sync('claim',nonce_a);
 if result->>'ok'<>'true' then raise exception 'claim failed %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('read',nonce_a);
 if result->>'revision'<>'0' then raise exception 'new account revision not zero %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('save',nonce_a,op,0,data);
 if result->>'revision'<>'1' then raise exception 'initial commit %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('save',nonce_a,op,0,data);
 if result->>'revision'<>'1' or (select revision from public.account_save_snapshots where user_id=uid)<>1 then raise exception 'retry duplicated'; end if; checks:=checks+1;
 result:=public.cloud_sync('save',nonce_a,op,0,'{}');
 if result->>'error'<>'operation_reused' then raise exception 'operation reused %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('read',nonce_a,op);
 if result->>'acknowledged_revision'<>'1' or result->'payload'<>data then raise exception 'lost ack recovery %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('save',nonce_a,gen_random_uuid(),0,data);
 if result->>'conflict'<>'true' then raise exception 'CAS missing'; end if; checks:=checks+1;
 -- Tutorial ledger survives a lost response and never grants twice.
 perform public.register_player_profile('별'||substr(replace(uid::text,'-',''),1,5),'male');
 perform public.complete_player_prologue();
 result:=public.cloud_sync('tutorial',nonce_a,null,1,null,'start');
 if result->>'ok'<>'true' then raise exception 'tutorial start %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('tutorial',nonce_a,null,1,null,'complete');
 if result #>> '{payload,stage_progress.cfg,meta,gold}'<>'1100' or result->>'revision'<>'2' then raise exception 'tutorial award %',result; end if; checks:=checks+1;
 result:=public.cloud_sync('tutorial',nonce_a,null,1,null,'complete');
 if result->>'conflict'<>'true' then raise exception 'lost tutorial ack did not require canonical refresh'; end if; checks:=checks+1;
 result:=public.cloud_sync('tutorial',nonce_a,null,2,null,'complete');
 if result->>'granted'<>'0' or result #>> '{payload,stage_progress.cfg,meta,gold}'<>'1100' then raise exception 'tutorial double grant'; end if; checks:=checks+1;
 -- New device takes ownership. An in-flight/lost old claim cannot steal back.
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','session_id',sid_b)::text,true);
 perform set_config('request.headers',jsonb_build_object('x-game-session',nonce_b)::text,true);
 result:=public.cloud_sync('claim',nonce_b);
 if result->>'ok'<>'true' then raise exception 'takeover failed'; end if; checks:=checks+1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','session_id',sid_a)::text,true);
 perform set_config('request.headers',jsonb_build_object('x-game-session',nonce_a)::text,true);
 result:=public.cloud_sync('check',nonce_a);
 if result->>'session_replaced'<>'true' then raise exception 'heartbeat fence missing'; end if; checks:=checks+1;
 result:=public.cloud_sync('claim',nonce_a);
 if result->>'session_replaced'<>'true' then raise exception 'old claim regained ownership'; end if; checks:=checks+1;
 result:=public.cloud_sync('save',nonce_a,op,0,data);
 if result->>'session_replaced'<>'true' then raise exception 'receipt bypassed fence'; end if; checks:=checks+1;
 if private.cloud_device_allowed() then raise exception 'legacy write fence missing'; end if; checks:=checks+1;
 result:=public.account_tutorial('skip',1);
 if result->>'session_replaced'<>'true' then raise exception 'legacy definer reward bypass'; end if; checks:=checks+1;
 result:=public.read_player_profile();
 if result->>'session_replaced'<>'true' then raise exception 'profile definer bypass'; end if; checks:=checks+1;
 result:=public.request_account_withdrawal();
 if result->>'session_replaced'<>'true' then raise exception 'withdrawal definer bypass'; end if; checks:=checks+1;
 begin
  update public.account_save_snapshots set payload='{}' where user_id=uid;
  raise exception 'direct snapshot update bypassed lease';
 exception when insufficient_privilege then checks:=checks+1;
 end;
 begin
  update public.player_progress set research_points=999 where user_id=uid;
  raise exception 'legacy progress update bypassed lease';
 exception when insufficient_privilege then checks:=checks+1;
 end;
 -- A valid nonce on the wrong Auth session is also rejected.
 result:=public.cloud_sync('check',nonce_b);
 if result->>'session_replaced'<>'true' then raise exception 'nonce-only auth accepted'; end if; checks:=checks+1;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',uid,'role','authenticated','session_id',sid_b)::text,true);
 perform set_config('request.headers',jsonb_build_object('x-game-session',nonce_b)::text,true);
 if not private.cloud_device_allowed() then raise exception 'active device blocked'; end if; checks:=checks+1;
 delete from auth.sessions where id=sid_b;
 result:=public.cloud_sync('check',nonce_b);
 if result->>'reauthenticate'<>'true' then raise exception 'revoked auth session accepted'; end if; checks:=checks+1;
 if has_function_privilege('anon','public.cloud_sync(text,uuid,uuid,bigint,jsonb,text)','EXECUTE') then raise exception 'anon RPC exposed'; end if; checks:=checks+1;
 if has_table_privilege('authenticated','private.cloud_receipts','SELECT,INSERT,UPDATE,DELETE') then raise exception 'receipt table exposed'; end if; checks:=checks+1;
 insert into cloud_session_results values(checks);
end $test$;
select checks as server_checks_passed from cloud_session_results;
rollback;
