extends Node

signal weapon_changed(name: String, ammo: int, reserve: int)
signal hit_confirmed
var owner_player: CharacterBody3D
var weapons := [
	{"name":"Mazza improvvisata","damage":34.0,"range":2.7,"mag":0,"ammo":0,"reserve":0,"cooldown":0.55},
	{"name":"Pistola","damage":28.0,"range":80.0,"mag":12,"ammo":12,"reserve":36,"cooldown":0.22},
	{"name":"Fucile","damage":58.0,"range":120.0,"mag":6,"ammo":6,"reserve":18,"cooldown":0.75}
]
var slot := 0
var unlocked := [true, false, false]
var can_fire := true

func setup(player: CharacterBody3D) -> void:
	owner_player=player; emit_status()

func select(index:int)->void:
	index=clampi(index,0,weapons.size()-1)
	if not unlocked[index]: MissionManager.notification.emit("Arma non ancora trovata"); return
	slot=index; owner_player.weapon_slot=slot; emit_status()

func unlock(index:int)->void:
	if index>=0 and index<unlocked.size(): unlocked[index]=true; select(index)

func attack()->void:
	if not can_fire: return
	var weapon:Dictionary=weapons[slot]
	if slot>0 and int(weapon.ammo)<=0: reload(); return
	if slot>0: weapon.ammo=int(weapon.ammo)-1
	can_fire=false; MissionManager.register_event("attack")
	var camera:Camera3D=owner_player.camera
	var from:=camera.global_position; var to:=from + -camera.global_basis.z*float(weapon.range)
	var query:=PhysicsRayQueryParameters3D.create(from,to); query.exclude=[owner_player]
	var hit:=owner_player.get_world_3d().direct_space_state.intersect_ray(query)
	if hit:
		var collider:Node=hit.collider
		if collider.has_method("take_damage"):
			var damage:=float(weapon.damage)* (2.0 if hit.position.y-collider.global_position.y>1.25 else 1.0)
			collider.take_damage(damage); hit_confirmed.emit()
	owner_player.recoil(0.025 if slot==1 else 0.05 if slot==2 else 0.01)
	emit_status(); await get_tree().create_timer(float(weapon.cooldown)).timeout; can_fire=true

func reload()->void:
	if slot==0:return
	var w:Dictionary=weapons[slot]; var needed:=int(w.mag)-int(w.ammo); var amount:=mini(needed,int(w.reserve)); w.ammo=int(w.ammo)+amount; w.reserve=int(w.reserve)-amount; emit_status()

func add_ammo(amount:int)->void:
	for i in range(1,weapons.size()): weapons[i].reserve=int(weapons[i].reserve)+amount
	emit_status()

func emit_status()->void:
	var w:Dictionary=weapons[slot]; weapon_changed.emit(w.name,int(w.ammo),int(w.reserve))
