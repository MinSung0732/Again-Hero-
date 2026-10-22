extends SceneTree
const PROFILE=preload("res://src/systems/player_profile.gd")
const GUEST=preload("res://src/systems/guest_progress_store.gd")
const SCOPE=preload("res://src/systems/account_save_scope.gd")
const FLOW=preload("res://src/systems/tutorial_flow.gd")
class NoNetwork extends Node:
 var calls=0
 func request_rpc(_method,_data):calls+=1;return {}
func _initialize():call_deferred("run")
func run():
 var folder="user://profile_flow_"+Crypto.new().generate_random_bytes(16).hex_encode()
 DirAccess.make_dir_recursive_absolute(folder)
 SCOPE.guest_directory=folder;SCOPE.select_guest()
 root.get_node("LocalTestMode").active=false
 root.get_node("LocalTestMode").tutorial_preview=false
 assert(GUEST.reset())
 var network=NoNetwork.new();root.add_child(network)
 var r=await PROFILE.refresh(network)
 # Since 10-17 (d8f2266d) guests start with a persisted random name and no name/prologue setup.
 assert(r.ok and not PROFILE.needs_prologue(r.profile) and PROFILE.valid_name(String(r.profile.nickname)))
 var guest_name=String(r.profile.nickname)
 assert(String((await PROFILE.refresh(network)).profile.nickname)==guest_name)
 r=await PROFILE.register(network,"리세마왕","male")
 assert(r.ok and r.profile.nickname==guest_name)
 assert(await PROFILE.complete(network))
 var flow=FLOW.new();root.add_child(flow)
 var result=await flow._rpc("read")
 assert(result.ok and result.status=="pending")
 assert((await flow._rpc("start")).status=="active")
 flow.account_owner=flow._owner();flow.status="active"
 assert(flow.active() and flow.account_owner.begins_with("guest:"))
 assert((await flow._rpc("skip")).reward_claimed)
 assert(GUEST.capture().payload["stage_progress.cfg"].meta.gold==1000)
 assert(network.calls==0)
 flow.clear_guide();flow.free();network.free()
 for file in DirAccess.get_files_at(folder):DirAccess.remove_absolute(folder.path_join(file))
 DirAccess.remove_absolute(folder)
 SCOPE.guest_directory="user://";SCOPE.select_guest()
 print("actual guest profile/tutorial dispatch: 10 checks PASS")
 quit()
