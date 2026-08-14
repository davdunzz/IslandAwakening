extends Node

var menu: Control
var current_world: Node
var continue_button: Button
var overlay: ColorRect

func _ready() -> void:
	if SaveManager.has_save(): MissionManager.restore_state(SaveManager.load_game())
	build_menu()

func build_menu() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if is_instance_valid(current_world): current_world.queue_free()
	menu = Control.new(); menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(menu)
	var base := ColorRect.new(); base.color = Color("071525"); base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu.add_child(base)
	var glow := GradientTexture2D.new(); var grad := Gradient.new(); grad.colors=[Color("143f75"),Color("071525"),Color("d49b24")]; grad.offsets=[0.0,0.62,1.0]; glow.gradient=grad; glow.width=1600; glow.height=900; var background:=TextureRect.new(); background.texture=glow; background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); background.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; menu.add_child(background)
	var shade := ColorRect.new(); shade.color=Color(0,0,0,0.30); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu.add_child(shade)
	var left := VBoxContainer.new(); left.position=Vector2(95,125); left.size=Vector2(480,650); left.add_theme_constant_override("separation",14); menu.add_child(left)
	var kicker:=Label.new(); kicker.text="A FIRST-PERSON SURVIVAL STORY"; kicker.add_theme_color_override("font_color",Color("f5bf42")); kicker.add_theme_font_size_override("font_size",14); left.add_child(kicker)
	var title:=Label.new(); title.text="ISLAND\nAWAKENING"; title.add_theme_color_override("font_color",Color.WHITE); title.add_theme_font_size_override("font_size",56); left.add_child(title)
	var subtitle:=Label.new(); subtitle.text="La memoria è perduta. L'isola no."; subtitle.add_theme_color_override("font_color",Color("b9c9dc")); subtitle.add_theme_font_size_override("font_size",18); left.add_child(subtitle)
	left.add_child(_spacer(28))
	left.add_child(_menu_button("NUOVA PARTITA", func(): confirm_new_game()))
	continue_button=_menu_button("CONTINUA", func(): start_game(true)); continue_button.disabled=not SaveManager.has_save(); left.add_child(continue_button)
	left.add_child(_menu_button("MULTIGIOCATORE LAN", show_network))
	left.add_child(_menu_button("IMPOSTAZIONI", show_settings))
	left.add_child(_menu_button("LORE", show_lore))
	left.add_child(_menu_button("ESCI", func(): get_tree().quit()))
	var version:=Label.new(); version.text="VERSIONE 1.0  •  GODOT 4.7.1  •  OFFLINE READY"; version.position=Vector2(98,850); version.add_theme_color_override("font_color",Color("7890aa")); menu.add_child(version)

func _menu_button(text: String, callback: Callable) -> Button:
	var button:=Button.new(); button.text=text; button.custom_minimum_size=Vector2(360,52); button.alignment=HORIZONTAL_ALIGNMENT_LEFT; button.add_theme_font_size_override("font_size",16); button.add_theme_color_override("font_color",Color.WHITE); button.pressed.connect(callback)
	var normal:=StyleBoxFlat.new(); normal.bg_color=Color(0.04,0.09,0.15,0.82); normal.corner_radius_top_left=10; normal.corner_radius_top_right=10; normal.corner_radius_bottom_left=10; normal.corner_radius_bottom_right=10; normal.content_margin_left=20
	var hover:=normal.duplicate(); hover.bg_color=Color("205ec7"); hover.border_width_left=4; hover.border_color=Color("f5bf42")
	button.add_theme_stylebox_override("normal",normal); button.add_theme_stylebox_override("hover",hover); button.add_theme_stylebox_override("pressed",hover); return button

func _spacer(height: float) -> Control:
	var c:=Control.new(); c.custom_minimum_size=Vector2(1,height); return c

func confirm_new_game() -> void:
	if not SaveManager.has_save(): start_game(false); return
	show_dialog("NUOVA PARTITA", "Il salvataggio attuale verrà cancellato. Continuare?", func(): start_game(false))

func start_game(load_existing: bool) -> void:
	var data := SaveManager.load_game() if load_existing else {}
	if not load_existing: SaveManager.delete_save(); MissionManager.reset()
	else: MissionManager.restore_state(data)
	menu.queue_free()
	current_world=preload("res://scripts/world/world.gd").new(); current_world.name="IslandWorld"; add_child(current_world)
	current_world.exit_to_menu.connect(build_menu)
	current_world.start_world(data)

func show_settings() -> void:
	var panel:=_modal_panel("IMPOSTAZIONI",Vector2(660,600)); var box:VBoxContainer=panel.get_node("Box")
	var master:=_slider_row(box,"Volume generale",float(SaveManager.settings.master)); master.value_changed.connect(func(v): SaveManager.settings.master=v; SaveManager.apply_settings())
	var music:=_slider_row(box,"Volume musica",float(SaveManager.settings.music)); music.value_changed.connect(func(v): SaveManager.settings.music=v; SaveManager.apply_settings())
	var sens:=_slider_row(box,"Sensibilità mouse",float(SaveManager.settings.sensitivity)*200.0); sens.max_value=1.0; sens.step=0.01; sens.value_changed.connect(func(v): SaveManager.settings.sensitivity=maxf(v/200.0,0.0005))
	var quality:=OptionButton.new(); quality.add_item("Qualità bassa"); quality.add_item("Qualità media"); quality.add_item("Qualità alta"); quality.selected=int(SaveManager.settings.quality); quality.item_selected.connect(func(i): SaveManager.settings.quality=i); box.add_child(_field("Qualità grafica",quality))
	var fullscreen:=CheckButton.new(); fullscreen.text="Schermo intero"; fullscreen.button_pressed=bool(SaveManager.settings.fullscreen); fullscreen.toggled.connect(func(v): SaveManager.settings.fullscreen=v); box.add_child(fullscreen)
	var vsync:=CheckButton.new(); vsync.text="V-Sync"; vsync.button_pressed=bool(SaveManager.settings.vsync); vsync.toggled.connect(func(v): SaveManager.settings.vsync=v); box.add_child(vsync)
	var save:=_menu_button("SALVA IMPOSTAZIONI",func(): SaveManager.save_settings(); panel.queue_free()); box.add_child(save)

func _slider_row(parent: VBoxContainer, label_text: String, value: float) -> HSlider:
	var slider:=HSlider.new(); slider.min_value=0.0; slider.max_value=1.0; slider.step=0.01; slider.value=value; slider.custom_minimum_size=Vector2(500,34); parent.add_child(_field(label_text,slider)); return slider

func _field(label_text:String, control:Control)->VBoxContainer:
	var box:=VBoxContainer.new(); var label:=Label.new(); label.text=label_text; label.add_theme_color_override("font_color",Color("b9c9dc")); box.add_child(label); box.add_child(control); return box

func show_lore() -> void:
	var panel:=_modal_panel("LORE DELL'ISOLA",Vector2(850,690)); var box:VBoxContainer=panel.get_node("Box")
	var scroll:=ScrollContainer.new(); scroll.custom_minimum_size=Vector2(750,530); box.add_child(scroll); var lore_box:=VBoxContainer.new(); lore_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL; scroll.add_child(lore_box)
	var chapters := ["Il naufragio","Il primo rifugio","La spedizione scomparsa","Il villaggio silenzioso","Gli esperimenti","La montagna cava","I custodi","Il segnale interrotto","La verità","Il risveglio"]
	for i in chapters.size():
		var label:=Label.new(); label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; label.custom_minimum_size=Vector2(700,70)
		label.text=("CAPITOLO %d — %s\nI frammenti recuperati raccontano una spedizione bloccata sull'isola e un segnale sabotato dall'interno." % [i+1,chapters[i]]) if MissionManager.lore.has(i) else ("CAPITOLO %d — BLOCCATO\nCompleta le missioni e trova i documenti." % [i+1])
		label.add_theme_color_override("font_color",Color.WHITE if MissionManager.lore.has(i) else Color("65748a")); lore_box.add_child(label)

func show_network() -> void:
	var panel:=_modal_panel("MULTIGIOCATORE LAN",Vector2(650,500)); var box:VBoxContainer=panel.get_node("Box")
	var info:=Label.new(); info.text="Versione base: host e connessione ENet fino a 4 giocatori.\nLa campagna offline resta sempre disponibile."; info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(info)
	var address:=LineEdit.new(); address.placeholder_text="Indirizzo IP host (es. 192.168.1.20)"; address.custom_minimum_size=Vector2(500,48); box.add_child(address)
	var status:=Label.new(); status.text="Offline"; box.add_child(status); NetworkManager.status_changed.connect(func(t): status.text=t)
	box.add_child(_menu_button("CREA PARTITA",func(): NetworkManager.host_game(); status.text="Host pronto: avvia la campagna dal menu"))
	box.add_child(_menu_button("ENTRA NELLA PARTITA",func(): NetworkManager.join_game(address.text); status.text="Connessione avviata"))

func _modal_panel(title_text:String, panel_size:Vector2)->PanelContainer:
	var dim:=ColorRect.new(); dim.color=Color(0,0,0,0.68); dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); menu.add_child(dim)
	var panel:=PanelContainer.new(); panel.size=panel_size; panel.position=(get_viewport().get_visible_rect().size-panel_size)/2.0; dim.add_child(panel)
	var style:=StyleBoxFlat.new(); style.bg_color=Color("0b1726"); style.border_color=Color("2d70d6"); style.set_border_width_all(1); style.set_corner_radius_all(18); style.set_content_margin_all(34); panel.add_theme_stylebox_override("panel",style)
	var box:=VBoxContainer.new(); box.name="Box"; box.add_theme_constant_override("separation",15); panel.add_child(box)
	var header:=HBoxContainer.new(); box.add_child(header); var title:=Label.new(); title.text=title_text; title.add_theme_font_size_override("font_size",28); title.size_flags_horizontal=Control.SIZE_EXPAND_FILL; header.add_child(title); var close:=Button.new(); close.text="✕"; close.pressed.connect(dim.queue_free); header.add_child(close)
	return panel

func show_dialog(title:String,text:String,yes_callback:Callable)->void:
	var panel:=_modal_panel(title,Vector2(570,300)); var box:VBoxContainer=panel.get_node("Box"); var label:=Label.new(); label.text=text; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART; box.add_child(label); box.add_child(_menu_button("CONFERMA",func(): yes_callback.call(); panel.get_parent().queue_free()))
