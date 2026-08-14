extends Node3D

signal exit_to_menu
var player:CharacterBody3D
var hud:CanvasLayer
var rng:=RandomNumberGenerator.new()
var world_size:=260.0
var terrain_textures:Dictionary={}

func start_world(save_data:Dictionary)->void:
	rng.seed=88421
	_load_environment_textures()
	_build_environment(); _build_island(); _build_landmarks()
	player=preload("res://scripts/player/player_controller.gd").new(); player.name="Player"; player.add_to_group("player"); add_child(player); player.global_position=Vector3(0,3,112)
	_build_gameplay()
	hud=preload("res://scripts/ui/hud.gd").new(); add_child(hud); hud.setup(player); hud.pause_requested.connect(_return_to_menu)
	if not save_data.is_empty():
		var p:Array=save_data.get("player_position",[])
		if p.size()==3: player.global_position=Vector3(float(p[0]),float(p[1]),float(p[2]))
		player.health=float(save_data.get("health",100)); player.inventory=save_data.get("inventory",player.inventory); player.weapon_slot=int(save_data.get("weapon_slot",0)); player.weapon_system.unlocked=save_data.get("unlocked_weapons",[true,false,false]); player.weapon_system.select(player.weapon_slot)
	MissionManager._emit_current(); SaveManager.save_game(player)

func _process(_delta:float)->void:
	if is_instance_valid(player) and player.global_position.y < -8: player.die()

func _return_to_menu()->void:
	get_tree().paused=false; SaveManager.save_game(player); exit_to_menu.emit()

func _build_environment()->void:
	var env_node:=WorldEnvironment.new(); var env:=Environment.new(); env.background_mode=Environment.BG_SKY
	var sky:=Sky.new(); var sky_mat:=ProceduralSkyMaterial.new(); sky_mat.sky_top_color=Color("16365c"); sky_mat.sky_horizon_color=Color("7eb4cf"); sky_mat.ground_horizon_color=Color("d3b36d"); sky_mat.sun_angle_max=18; sky.sky_material=sky_mat; env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_SKY; env.ambient_light_energy=0.7; env.tonemap_mode=Environment.TONE_MAPPER_FILMIC; env.fog_enabled=true; env.fog_light_color=Color("8eb3c0"); env.fog_density=.0025; env_node.environment=env; add_child(env_node)
	var sun:=DirectionalLight3D.new(); sun.rotation_degrees=Vector3(-52,-28,0); sun.light_color=Color("fff0c0"); sun.light_energy=1.35; sun.shadow_enabled=true; sun.directional_shadow_max_distance=95; add_child(sun)

func _build_island()->void:
	# Ocean
	var water:=MeshInstance3D.new(); var water_mesh:=PlaneMesh.new(); water_mesh.size=Vector2(620,620); water.mesh=water_mesh; water.position.y=-1.6; var water_mat:=StandardMaterial3D.new(); water_mat.albedo_color=Color(0.02,0.24,0.38,.88); water_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; water_mat.metallic=.25; water_mat.roughness=.18; water.material_override=water_mat; add_child(water)
	# Layered island gives a large traversable silhouette without heavy terrain assets.
	_add_box("BeachIsland",Vector3(230,2,230),Vector3(0,-1,0),Color("b89b62"),true)
	_add_box("InnerIsland",Vector3(190,1,185),Vector3(0,-.5,0),Color("42683b"),true)
	_add_box("Highlands",Vector3(110,.5,95),Vector3(-20,-.25,5),Color("526845"),true)
	# paths
	for z in range(100,-111,-12): _add_box("Path",Vector3(7,.08,11),Vector3(sin(float(z)*.05)*10,.05,z),Color("8f7753"),false)
	# cliffs and mountains
	for i in 42:
		var angle:=TAU*float(i)/42.0; var radius:=rng.randf_range(86,106); var pos:=Vector3(cos(angle)*radius,rng.randf_range(4,9),sin(angle)*radius); _add_rock(pos,Vector3(rng.randf_range(5,12),rng.randf_range(7,20),rng.randf_range(5,12)))
	for i in 75:
		var pos:=Vector3(rng.randf_range(-82,82),0,rng.randf_range(-78,82))
		if pos.length()<105 and abs(pos.x)>8: _add_tree(pos,rng.randf_range(.75,1.35))

func _build_landmarks()->void:
	_add_landmark("RIFUGIO",Vector3(8,.2,82),Color("d18a3c"),Vector3(10,.4,8))
	_add_landmark("VILLAGGIO ABBANDONATO",Vector3(48,.2,24),Color("6d4c38"),Vector3(22,.4,18))
	for x in [-7,0,7]: _add_box("House",Vector3(5,4,6),Vector3(48+x,2,24+rng.randf_range(-6,6)),Color("76533b"),true)
	_add_landmark("GROTTA",Vector3(-66,.2,-12),Color("2a3138"),Vector3(16,.4,14))
	_add_landmark("CAMPO OSTILE",Vector3(55,.2,-38),Color("7f3135"),Vector3(22,.4,18))
	_add_landmark("ROVINE",Vector3(-30,.2,-67),Color("77766c"),Vector3(25,.4,18))
	for i in 6: _add_box("Column",Vector3(1.5,8,1.5),Vector3(-40+i*4,4,-67+rng.randf_range(-4,4)),Color("8e8a78"),true)
	_add_landmark("TORRE DEL SEGNALE",Vector3(5,.2,-92),Color("29384f"),Vector3(12,.4,12))
	_add_box("Tower",Vector3(8,26,8),Vector3(5,13,-92),Color("23344e"),true)
	for y in [6,13,20,27]: _add_box("TowerRing",Vector3(12,.7,12),Vector3(5,y,-92),Color("d5a72d"),true)

func _build_gameplay()->void:
	# Mission zones in story order.
	_add_zone("shelter",Vector3(8,2,82)); _add_zone("safe_zone",Vector3(8,2,76)); _add_zone("forest",Vector3(-28,2,47)); _add_zone("village",Vector3(48,2,24)); _add_zone("enemy_camp",Vector3(55,2,-30)); _add_zone("cave",Vector3(-58,2,-12)); _add_zone("cave_exit",Vector3(-72,2,-24)); _add_zone("hostile_camp",Vector3(55,2,-38)); _add_zone("radio",Vector3(20,2,-57)); _add_zone("ruins",Vector3(-30,2,-67)); _add_zone("tower",Vector3(5,2,-82)); _add_zone("signal",Vector3(14,2,-92),Vector3(8,4,8))
	# Tutorial and quest items.
	_add_pickup("tutorial_supply","Provviste del naufragio","resources","pickup",Vector3(3,2,105))
	_add_pickup("club","Mazza improvvisata","resources","weapon",Vector3(-2,2,98))
	_add_pickup("pistol","Pistola di servizio","ammo","weapon",Vector3(12,2,72)); _add_pickup("res1","Legno","resources","resource",Vector3(5,2,69)); _add_pickup("res2","Metallo","resources","resource",Vector3(13,2,69))
	_add_pickup("village_diary","Diario del villaggio","document","document",Vector3(48,3,20))
	for i in 3: _add_pickup("supply%d"%i,"Cassa rifornimenti","supplies","supply",Vector3(50+i*5,2,-28-i*2))
	_add_pickup("rifle","Fucile da caccia","ammo","bonus",Vector3(-70,2,-20))
	for i in 3: _add_pickup("component%d"%i,"Componente radio","components","component",Vector3(-5+i*14,2,-53+rng.randf_range(-5,5)))
	_add_pickup("truth","Documento classificato","document","truth_document",Vector3(-30,3,-70))
	# Enemies distributed across progression zones.
	var positions:=[Vector3(-5,2,91),Vector3(-25,2,44),Vector3(-34,2,41),Vector3(-19,2,38),Vector3(52,2,-25),Vector3(59,2,-30),Vector3(-62,2,-15),Vector3(-69,2,-18),Vector3(48,2,-39),Vector3(55,2,-43),Vector3(61,2,-38),Vector3(51,2,-47),Vector3(66,2,-45)]
	for i in positions.size(): _add_enemy("enemy_%d"%i,positions[i],false)
	_add_enemy("tower_boss",Vector3(5,2,-84),true)

func _add_box(node_name:String,size:Vector3,pos:Vector3,color:Color,collision:bool)->Node3D:
	var node:=StaticBody3D.new() if collision else Node3D.new(); node.name=node_name; node.position=pos; add_child(node)
	var visual:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=size; visual.mesh=mesh; visual.material_override=_environment_material(node_name,color,size); node.add_child(visual)
	if collision: var col:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; col.shape=shape; node.add_child(col)
	return node

func _load_environment_textures()->void:
	terrain_textures={
		"sand":load("res://assets/textures/environment/sand_albedo.jpg"),
		"ground":load("res://assets/textures/environment/forest_ground_albedo.jpg"),
		"rock":load("res://assets/textures/environment/rock_albedo.jpg"),
		"wood":load("res://assets/textures/environment/wood_albedo.jpg")
	}

func _environment_material(node_name:String,color:Color,size:Vector3)->StandardMaterial3D:
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=color
	mat.roughness=.86
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var texture_key:=""
	if node_name in ["BeachIsland","Path"]: texture_key="sand"
	elif node_name in ["InnerIsland","Highlands"]: texture_key="ground"
	elif node_name in ["Cliff","Column","ROVINE","GROTTA"]: texture_key="rock"
	elif node_name in ["House","RIFUGIO","VILLAGGIO ABBANDONATO"]: texture_key="wood"
	if texture_key!="":
		mat.albedo_texture=terrain_textures.get(texture_key)
		mat.albedo_color=Color.WHITE
		mat.uv1_scale=Vector3(maxf(1.0,size.x/5.0),maxf(1.0,size.z/5.0),maxf(1.0,size.y/4.0))
	return mat

func _add_tree(pos:Vector3,scale_value:float)->void:
	var tree:=Node3D.new(); tree.position=pos; tree.scale=Vector3.ONE*scale_value; add_child(tree)
	var trunk:=MeshInstance3D.new(); var tm:=CylinderMesh.new(); tm.top_radius=.18; tm.bottom_radius=.32; tm.height=4; trunk.mesh=tm; trunk.position.y=2; var brown:=StandardMaterial3D.new(); brown.albedo_color=Color("543c29"); trunk.material_override=brown; tree.add_child(trunk)
	for y in [3.5,4.5,5.4]: var leaves:=MeshInstance3D.new(); var lm:=SphereMesh.new(); lm.radius=1.6; lm.height=2.2; leaves.mesh=lm; leaves.position=Vector3(rng.randf_range(-.35,.35),y,rng.randf_range(-.35,.35)); var green:=StandardMaterial3D.new(); green.albedo_color=Color("1d5132"); green.roughness=1; leaves.material_override=green; tree.add_child(leaves)

func _add_rock(pos:Vector3,size:Vector3)->void:
	var rock:=_add_box("Cliff",size,pos,Color("4c5558"),true); rock.rotation_degrees.y=rng.randf_range(0,180)

func _add_landmark(label_text:String,pos:Vector3,color:Color,size:Vector3)->void:
	_add_box(label_text,size,pos,color,true); var label:=Label3D.new(); label.text=label_text; label.position=pos+Vector3(0,size.y*.65+2,0); label.font_size=44; label.outline_size=8; label.modulate=Color("f5bf42"); add_child(label)

func _add_zone(event:String,pos:Vector3,size:=Vector3(8,3,8))->void:
	var ground_pos:=Vector3(pos.x,0,pos.z)
	var zone:=preload("res://scripts/world/mission_zone.gd").new(); zone.position=ground_pos; add_child(zone); zone.configure(event,size)
	var marker:=MeshInstance3D.new(); var mesh:=CylinderMesh.new(); mesh.top_radius=2.5; mesh.bottom_radius=2.5; mesh.height=.08; marker.mesh=mesh; marker.position=ground_pos+Vector3(0,.12,0); var mat:=StandardMaterial3D.new(); mat.albedo_color=Color(0.15,0.5,1,.42); mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; mat.emission_enabled=true; mat.emission=Color("2e75df")*.35; marker.material_override=mat; add_child(marker)

func _add_pickup(id:String,label:String,kind:String,event:String,pos:Vector3)->void:
	if MissionManager.collected_ids.has(id):return
	var item:=preload("res://scripts/items/pickup.gd").new(); item.position=Vector3(pos.x,.1,pos.z); item.configure(id,label,kind,event); add_child(item)

func _add_enemy(id:String,pos:Vector3,boss:bool)->void:
	if MissionManager.defeated_ids.has(id):return
	var enemy:=preload("res://scripts/enemies/enemy_ai.gd").new(); enemy.position=pos; enemy.configure(id,player,boss); add_child(enemy)
