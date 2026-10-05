-- Additive deployment. Existing accounts are not reclassified as newcomers.
create table public.account_tutorials (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','active','completed','skipped','legacy')),
  reward_claimed boolean not null default false,
  reward_gold integer not null default 0 check (reward_gold in (0,1000)),
  updated_at timestamptz not null default now()
);
alter table public.account_tutorials enable row level security;
revoke all on public.account_tutorials from public,anon,authenticated;
grant select on public.account_tutorials to authenticated;
create policy own_tutorial_read on public.account_tutorials for select to authenticated
using (user_id = (select auth.uid()));
insert into public.account_tutorials(user_id,status)
select user_id,'legacy' from public.player_profiles
union select user_id,'legacy' from public.account_save_snapshots
union select user_id,'legacy' from public.player_progress
on conflict (user_id) do nothing;

-- The private helper owns the ledger + snapshot transaction. No target UUID,
-- reward amount or arbitrary payload can be supplied by the client.
create function private.tutorial_operation(action text, expected_revision bigint default 0)
returns jsonb language plpgsql security definer set search_path='' as $$
declare
  owner_id uuid := auth.uid();
  record public.account_tutorials;
  snapshot public.account_save_snapshots;
  new_payload jsonb; stage jsonb; meta jsonb; gold bigint;
begin
  if owner_id is null then raise exception 'authentication required'; end if;
  if action is null or action not in ('read','start','complete','skip') then
    return jsonb_build_object('ok',false,'error','invalid');
  end if;
  if not exists(select 1 from public.player_profiles where user_id=owner_id and prologue_completed) then
    return jsonb_build_object('ok',false,'error','profile_required');
  end if;
  insert into public.account_tutorials(user_id) values(owner_id) on conflict(user_id) do nothing;
  select * into record from public.account_tutorials where user_id=owner_id for update;
  if action='read' then
    return jsonb_build_object('ok',true,'status',record.status,'reward_claimed',record.reward_claimed);
  end if;
  if action='start' then
    if record.status='pending' then
      update public.account_tutorials set status='active',updated_at=now() where user_id=owner_id returning * into record;
    end if;
    return jsonb_build_object('ok',true,'status',record.status,'reward_claimed',record.reward_claimed);
  end if;
  if record.status='legacy' then return jsonb_build_object('ok',false,'error','not_eligible'); end if;
  if action='complete' and record.status='pending' then return jsonb_build_object('ok',false,'error','not_started'); end if;
  select * into snapshot from public.account_save_snapshots where user_id=owner_id for update;
  if snapshot.user_id is null or expected_revision is null or snapshot.revision<>expected_revision then
    return jsonb_build_object('ok',false,'conflict',true);
  end if;
  if not record.reward_claimed then
    new_payload := snapshot.payload;
    stage := coalesce(new_payload->'stage_progress.cfg','{}'::jsonb);
    meta := coalesce(stage->'meta','{}'::jsonb);
    if jsonb_typeof(stage)<>'object' or jsonb_typeof(meta)<>'object' or
       coalesce(meta->>'gold','0') !~ '^[0-9]{1,12}$' then
      return jsonb_build_object('ok',false,'error','invalid_save');
    end if;
    gold := coalesce(meta->>'gold','0')::bigint;
    meta := jsonb_set(meta,'{gold}',to_jsonb(gold+1000),true);
    stage := jsonb_set(stage,'{meta}',meta,true);
    new_payload := jsonb_set(new_payload,'{stage_progress.cfg}',stage,true);
    update public.account_save_snapshots set payload=new_payload,revision=revision+1,updated_at=now()
    where user_id=owner_id returning * into snapshot;
    update public.account_tutorials set status=case when action='skip' then 'skipped' else 'completed' end,
      reward_claimed=true,reward_gold=1000,updated_at=now() where user_id=owner_id returning * into record;
    return jsonb_build_object('ok',true,'status',record.status,'reward_claimed',true,'granted',1000,'revision',snapshot.revision,'payload',snapshot.payload);
  end if;
  return jsonb_build_object('ok',true,'status',record.status,'reward_claimed',true,'granted',0,'revision',snapshot.revision,'payload',snapshot.payload);
end $$;
revoke all on function private.tutorial_operation(text,bigint) from public,anon;
grant execute on function private.tutorial_operation(text,bigint) to authenticated;
create function public.account_tutorial(action text,expected_revision bigint default 0)
returns jsonb language sql security invoker set search_path='' as $$
select private.tutorial_operation(action,expected_revision);
$$;
revoke all on function public.account_tutorial(text,bigint) from public,anon;
grant execute on function public.account_tutorial(text,bigint) to authenticated;
