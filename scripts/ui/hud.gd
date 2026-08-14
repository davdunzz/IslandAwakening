extends CanvasLayer

signal pause_requested
var health_bar:ProgressBar
var stamina_bar:ProgressBar
var mission_title:Label
var objective:Label
var weapon_label:Label
var ammo_label:Label
var notification:Label
var inventory_panel:PanelContainer
var map_panel:PanelContainer
var pause_panel:PanelContainer
var inventory_label:Label

func setup(player:Node)->void:
	_build(); player.health_changed.connect(func(v):health_bar.value=v); player.inventory_changed.connect(_inventory_changed); player.weapon_system.weapon_changed.connect(_weapon_changed); player.weapon_system.hit_confirmed.connect(func(): show_notification("COLPO A SEGNO")); MissionManager.mission_changed.connect(_mission_changed); MissionManager.notification.connect(show_notification); _mission_changed(MissionManager.current_text().title,MissionManager.current_text().objective,MissionManager.mission_index); _inventory_changed(player.inventory); player.weapon_system.emit_status()

func _build()->void:
	var root:=Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(root)
	# L'HUD rimane visibile ma non intercetta il mouse durante il gioco.
	root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var top:=PanelContainer.new(); top.position=Vector2(35,30); top.size=Vector2(560,110); top.add_theme_stylebox_override("panel",_panel_style(Color(0.02,0.05,0.09,.82))); root.add_child(top); var box:=VBoxContainer.new(); box.add_theme_constant_override("separation",5); top.add_child(box); mission_title=Label.new(); mission_title.add_theme_font_size_override("font_size",18); mission_title.add_theme_color_override("font_color",Color("f5bf42")); box.add_child(mission_title); objective=Label.new(); objective.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(objective)
	health_bar=_bar(Color("e34f64")); health_bar.position=Vector2(35,780); root.add_child(health_bar); stamina_bar=_bar(Color("f5bf42")); stamina_bar.position=Vector2(35,818); root.add_child(stamina_bar)
	weapon_label=Label.new(); weapon_label.position=Vector2(1210,790); weapon_label.size=Vector2(330,30); weapon_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; weapon_label.add_theme_font_size_override("font_size",18); root.add_child(weapon_label); ammo_label=Label.new(); ammo_label.position=Vector2(1210,820); ammo_label.size=Vector2(330,35); ammo_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT; ammo_label.add_theme_font_size_override("font_size",22); root.add_child(ammo_label)
	var cross:=Label.new(); cross.text="+"; cross.position=Vector2(790,440); cross.add_theme_font_size_override("font_size",24); root.add_child(cross)
	notification=Label.new(); notification.position=Vector2(500,160); notification.size=Vector2(600,50); notification.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; notification.add_theme_font_size_override("font_size",18); notification.add_theme_color_override("font_color",Color("f5bf42")); root.add_child(notification)
	inventory_panel=_large_panel(root,"INVENTARIO — Tab"); inventory_panel.visible=false; inventory_label=inventory_panel.get_child(0); inventory_label.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	map_panel=_large_panel(root,"MAPPA E MISSIONI — M\nSpiaggia → Rifugio → Foresta → Villaggio → Grotta → Campo → Rovine → Torre"); map_panel.visible=false
	pause_panel=_large_panel(root,"PAUSA\nESC: riprendi  •  F5: salva  •  F9: torna al menu"); pause_panel.visible=false

func _process(_delta:float)->void:
	stamina_bar.value=get_tree().get_first_node_in_group("player").stamina if get_tree().get_first_node_in_group("player") else 0
	if Input.is_action_just_pressed("inventory"): inventory_panel.visible=not inventory_panel.visible; _mouse_for_panels()
	if Input.is_action_just_pressed("map"): map_panel.visible=not map_panel.visible; _mouse_for_panels()
	if Input.is_action_just_pressed("ui_cancel"): pause_panel.visible=not pause_panel.visible; _mouse_for_panels()
	if Input.is_key_pressed(KEY_F5):
		var p=get_tree().get_first_node_in_group("player")
		if p: SaveManager.save_game(p)
	if pause_panel.visible and Input.is_key_pressed(KEY_F9): pause_requested.emit()

func _mouse_for_panels()->void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if inventory_panel.visible or map_panel.visible or pause_panel.visible else Input.MOUSE_MODE_CAPTURED
	get_tree().paused=pause_panel.visible
	process_mode=Node.PROCESS_MODE_ALWAYS

func _bar(color:Color)->ProgressBar:
	var bar:=ProgressBar.new(); bar.min_value=0;bar.max_value=100;bar.value=100;bar.size=Vector2(300,26);bar.show_percentage=false; var bg:=StyleBoxFlat.new(); bg.bg_color=Color(0,0,0,.65);bg.set_corner_radius_all(8);var fill:=StyleBoxFlat.new();fill.bg_color=color;fill.set_corner_radius_all(8);bar.add_theme_stylebox_override("background",bg);bar.add_theme_stylebox_override("fill",fill);return bar

func _panel_style(color:Color)->StyleBoxFlat:
	var s:=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(14);s.set_content_margin_all(18);s.border_color=Color("2d70d6");s.set_border_width_all(1);return s

func _large_panel(root:Control,text:String)->PanelContainer:
	var p:=PanelContainer.new();p.position=Vector2(430,250);p.size=Vector2(740,340);p.add_theme_stylebox_override("panel",_panel_style(Color(0.02,0.05,0.09,.95)));root.add_child(p);var l:=Label.new();l.text=text;l.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",21);p.add_child(l);return p

func _weapon_changed(name:String,ammo:int,reserve:int)->void:
	weapon_label.text=name;ammo_label.text="CORPO A CORPO" if ammo==0 and reserve==0 else "%02d / %02d"%[ammo,reserve]
func _inventory_changed(items:Dictionary)->void:
	if inventory_label: inventory_label.text="INVENTARIO — Tab\n\nCure: %d\nRisorse: %d\nDocumenti: %d\nComponenti radio: %d\nProvviste: %d"%[int(items.get("medical",0)),int(items.get("resources",0)),int(items.get("documents",0)),int(items.get("components",0)),int(items.get("supplies",0))]
func _mission_changed(title:String,obj:String,_index:int)->void:mission_title.text=title;objective.text=obj
func show_notification(text:String)->void:
	notification.text=text;var tween=create_tween();notification.modulate.a=1;tween.tween_interval(2.4);tween.tween_property(notification,"modulate:a",0,0.6)
