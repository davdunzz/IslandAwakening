extends CharacterBody3D

signal health_changed(value: float)
signal inventory_changed(inventory: Dictionary)
signal died

var speed:=6.0
var sprint_speed:=10.0
var health:=100.0
var stamina:=100.0
var mouse_sensitivity:=0.0022
var inventory:Dictionary={"medical":1,"resources":0,"documents":0,"components":0,"supplies":0}
var weapon_slot:=0
var respawn_position:=Vector3(0,3,22)
var camera:Camera3D
var head:Node3D
var interaction:RayCast3D
var weapon_system:Node
var moved_once:=false
var looked_once:=false

func _ready()->void:
	mouse_sensitivity=float(SaveManager.settings.sensitivity); Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	head=Node3D.new(); head.position=Vector3(0,1.55,0); add_child(head)
	camera=Camera3D.new(); camera.current=true; head.add_child(camera)
	interaction=RayCast3D.new(); interaction.target_position=Vector3(0,0,-4); interaction.collide_with_areas=true; interaction.collide_with_bodies=true; camera.add_child(interaction)
	weapon_system=preload("res://scripts/combat/weapon_system.gd").new(); add_child(weapon_system); weapon_system.setup(self); weapon_system.select(weapon_slot)
	var collider:=CollisionShape3D.new(); var shape:=CapsuleShape3D.new(); shape.radius=.42; shape.height=1.8; collider.shape=shape; collider.position.y=.9; add_child(collider)
	var body:=MeshInstance3D.new(); var mesh:=CapsuleMesh.new(); mesh.radius=.42; mesh.height=1.8; body.mesh=mesh; body.position.y=.9; body.visible=false; add_child(body)

func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x*mouse_sensitivity); head.rotation.x=clampf(head.rotation.x-event.relative.y*mouse_sensitivity,-1.45,1.45)
		if not looked_once and event.relative.length()>3: looked_once=true; MissionManager.register_event("look")
	if event.is_action_pressed("attack") and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED: weapon_system.attack()
	if event.is_action_pressed("interact"): interact()
	if event.is_action_pressed("reload"): weapon_system.reload()
	if event.is_action_pressed("slot_1"): weapon_system.select(0)
	if event.is_action_pressed("slot_2"): weapon_system.select(1)
	if event.is_action_pressed("slot_3"): weapon_system.select(2)

func _physics_process(delta:float)->void:
	if not is_on_floor(): velocity.y-=18.0*delta
	if Input.is_action_just_pressed("jump") and is_on_floor(): velocity.y=7.2; MissionManager.register_event("jump")
	var input:=Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction:=(transform.basis*Vector3(input.x,0,input.y)).normalized()
	var current_speed:=sprint_speed if Input.is_action_pressed("sprint") and stamina>0 else speed
	if Input.is_action_pressed("crouch"): current_speed*=.55; head.position.y=lerpf(head.position.y,1.05,delta*10.0)
	else: head.position.y=lerpf(head.position.y,1.55,delta*10.0)
	if direction:
		velocity.x=move_toward(velocity.x,direction.x*current_speed,25.0*delta); velocity.z=move_toward(velocity.z,direction.z*current_speed,25.0*delta)
		if not moved_once: moved_once=true; MissionManager.register_event("move")
	else: velocity.x=move_toward(velocity.x,0,18.0*delta); velocity.z=move_toward(velocity.z,0,18.0*delta)
	stamina=clampf(stamina + (-22.0 if current_speed==sprint_speed and direction else 15.0)*delta,0,100)
	move_and_slide()

func interact()->void:
	interaction.force_raycast_update()
	if interaction.is_colliding():
		var target:Node=interaction.get_collider()
		if target.has_method("interact"): target.interact(self)

func add_item(kind:String,amount:int=1)->void:
	inventory[kind]=int(inventory.get(kind,0))+amount; inventory_changed.emit(inventory)
	if kind=="ammo": weapon_system.add_ammo(amount*6)
	if kind=="medical": health=minf(100,health+25); health_changed.emit(health)

func take_damage(amount:float)->void:
	health=maxf(0,health-amount); health_changed.emit(health)
	if health<=0: die()

func die()->void:
	health=100; global_position=respawn_position; velocity=Vector3.ZERO; health_changed.emit(health); died.emit()

func recoil(amount:float)->void:
	head.rotation.x=clampf(head.rotation.x+amount,-1.45,1.45)
