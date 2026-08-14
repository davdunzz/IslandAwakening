extends Area3D

var event_name:=""
var one_shot:=true
var triggered:=false

func configure(event:String,size:=Vector3(7,3,7))->void:
	event_name=event; var collider:=CollisionShape3D.new(); var shape:=BoxShape3D.new(); shape.size=size; collider.shape=shape; collider.position.y=size.y*.5; add_child(collider); body_entered.connect(_entered)

func _entered(body:Node)->void:
	if triggered and one_shot:return
	if body.is_in_group("player"):
		if not MissionManager.expects_event(event_name):return
		triggered=true; MissionManager.register_event(event_name)
		if event_name=="safe_zone" or event_name=="shelter": body.respawn_position=body.global_position
