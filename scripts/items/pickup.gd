extends StaticBody3D

var pickup_id:=""
var display_name:="Oggetto"
var item_kind:="resources"
var event_name:="pickup"
var amount:=1

func configure(id:String,label:String,kind:String,event:String,qty:=1)->void:
	pickup_id=id; display_name=label; item_kind=kind; event_name=event; amount=qty

func _ready()->void:
	var collider:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=Vector3(.7,.55,.7); collider.shape=shape; collider.position.y=.28; add_child(collider)
	var mesh_node:=MeshInstance3D.new(); var mesh:=BoxMesh.new(); mesh.size=Vector3(.7,.55,.7); mesh_node.mesh=mesh; mesh_node.position.y=.28; var mat:=StandardMaterial3D.new(); mat.albedo_color=Color("f5bf42") if item_kind!="document" else Color("d8eefc"); mat.emission_enabled=true; mat.emission=mat.albedo_color*.35; mesh_node.material_override=mat; add_child(mesh_node)
	var light:=OmniLight3D.new(); light.light_color=mat.albedo_color; light.omni_range=3; light.light_energy=.45; light.position.y=.8; add_child(light)

func interact(player:Node)->void:
	if MissionManager.collected_ids.has(pickup_id): queue_free(); return
	if event_name!="bonus" and not MissionManager.expects_event(event_name):
		MissionManager.notification.emit("Questo oggetto servirà in una missione successiva")
		return
	MissionManager.collected_ids.append(pickup_id); player.add_item(item_kind,amount)
	if event_name!="bonus": MissionManager.register_event(event_name,1)
	MissionManager.notification.emit("Raccolto: %s"%display_name); queue_free()
	if pickup_id=="pistol": player.weapon_system.unlock(1)
	elif pickup_id=="rifle": player.weapon_system.unlock(2)
