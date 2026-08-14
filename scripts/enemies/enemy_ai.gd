extends CharacterBody3D

var enemy_id:=""
var health:=100.0
var damage:=12.0
var speed:=3.2
var detection_range:=22.0
var attack_range:=1.8
var player:Node3D
var spawn_position:=Vector3.ZERO
var patrol_target:=Vector3.ZERO
var attack_ready:=true
var is_boss:=false

func configure(id:String,target:Node3D,boss:=false)->void:
	enemy_id=id; player=target; is_boss=boss; health=260.0 if boss else 100.0; damage=24.0 if boss else 12.0; speed=3.6 if boss else 3.0

func _ready()->void:
	spawn_position=global_position; patrol_target=spawn_position+Vector3(randf_range(-6,6),0,randf_range(-6,6))
	var collider:=CollisionShape3D.new(); var shape:=CapsuleShape3D.new(); shape.radius=.48 if not is_boss else .75; shape.height=1.8 if not is_boss else 2.8; collider.shape=shape; collider.position.y=shape.height*.5; add_child(collider)
	var mesh_node:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.radius=shape.radius; mesh.height=shape.height; mesh_node.mesh=mesh; mesh_node.position.y=shape.height*.5; var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("8d2638") if not is_boss else Color("30152d"); mat.metallic=.15; mat.roughness=.65; mesh_node.material_override=mat; add_child(mesh_node)

func _physics_process(delta:float)->void:
	if not is_instance_valid(player): return
	if not is_on_floor(): velocity.y-=18*delta
	var distance:=global_position.distance_to(player.global_position)
	var target:=patrol_target
	if distance<detection_range and _can_see_player(): target=player.global_position
	var direction:=(target-global_position); direction.y=0
	if distance<attack_range:
		velocity.x=0; velocity.z=0; _attack()
	elif direction.length()>.8:
		direction=direction.normalized(); velocity.x=direction.x*speed; velocity.z=direction.z*speed; look_at(global_position+direction,Vector3.UP)
	else: patrol_target=spawn_position+Vector3(randf_range(-8,8),0,randf_range(-8,8))
	move_and_slide()

func _can_see_player()->bool:
	var query:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.2,player.global_position+Vector3.UP); query.exclude=[self]
	var hit:=get_world_3d().direct_space_state.intersect_ray(query); return hit and hit.collider==player

func _attack()->void:
	if not attack_ready:return
	attack_ready=false
	if player.has_method("take_damage"): player.take_damage(damage)
	await get_tree().create_timer(1.1).timeout; attack_ready=true

func take_damage(amount:float)->void:
	if is_boss and not MissionManager.expects_event("boss_killed"):
		MissionManager.notification.emit("Il Custode è protetto: scopri prima la verità dell'isola")
		return
	health-=amount
	if health<=0:
		MissionManager.defeated_ids.append(enemy_id); MissionManager.register_event("boss_killed" if is_boss else "enemy_killed")
		if randf()<.4 and is_instance_valid(player): player.add_item("ammo",1)
		queue_free()
