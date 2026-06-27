extends Control

# ship_select.gd - Handles ship selection UI, stats preview, and retro drawing.

var fighter_btn: Button = null
var interceptor_btn: Button = null
var dreadnought_btn: Button = null
var ghost_btn: Button = null
var titan_btn: Button = null
var back_btn: Button = null

func _init_nodes():
	fighter_btn = get_node_or_null("VBox/ScrollContainer/HBox/FighterCard/VBox/SelectBtn")
	interceptor_btn = get_node_or_null("VBox/ScrollContainer/HBox/InterceptorCard/VBox/SelectBtn")
	dreadnought_btn = get_node_or_null("VBox/ScrollContainer/HBox/DreadnoughtCard/VBox/SelectBtn")
	ghost_btn = get_node_or_null("VBox/ScrollContainer/HBox/GhostCard/VBox/SelectBtn")
	titan_btn = get_node_or_null("VBox/ScrollContainer/HBox/TitanCard/VBox/SelectBtn")
	back_btn = get_node_or_null("BackBtn")

var f_preview: Control = null
var i_preview: Control = null
var d_preview: Control = null
var g_preview: Control = null
var t_preview: Control = null

func _init_previews():
	f_preview = get_node_or_null("VBox/ScrollContainer/HBox/FighterCard/VBox/PreviewContainer/FighterPreview")
	i_preview = get_node_or_null("VBox/ScrollContainer/HBox/InterceptorCard/VBox/PreviewContainer/InterceptorPreview")
	d_preview = get_node_or_null("VBox/ScrollContainer/HBox/DreadnoughtCard/VBox/PreviewContainer/DreadnoughtPreview")
	g_preview = get_node_or_null("VBox/ScrollContainer/HBox/GhostCard/VBox/PreviewContainer/GhostPreview")
	t_preview = get_node_or_null("VBox/ScrollContainer/HBox/TitanCard/VBox/PreviewContainer/TitanPreview")

func _ready() -> void:
	_init_nodes()
	_init_previews()
	# Connect buttons safely
	if fighter_btn:
		fighter_btn.pressed.connect(_on_ship_selected.bind(GameManager.ShipType.FIGHTER))
	if interceptor_btn:
		interceptor_btn.pressed.connect(_on_ship_selected.bind(GameManager.ShipType.INTERCEPTOR))
	if dreadnought_btn:
		dreadnought_btn.pressed.connect(_on_ship_selected.bind(GameManager.ShipType.DREADNOUGHT))
	if ghost_btn:
		ghost_btn.pressed.connect(_on_ship_selected.bind(GameManager.ShipType.GHOST))
	if titan_btn:
		titan_btn.pressed.connect(_on_ship_selected.bind(GameManager.ShipType.TITAN))
	if back_btn:
		back_btn.pressed.connect(_on_back_pressed)
	
	# Connect hover SFX
	var _button_list = []
	if fighter_btn:
		_button_list.append(fighter_btn)
	if interceptor_btn:
		_button_list.append(interceptor_btn)
	if dreadnought_btn:
		_button_list.append(dreadnought_btn)
	if ghost_btn:
		_button_list.append(ghost_btn)
	if titan_btn:
		_button_list.append(titan_btn)
	if back_btn:
		_button_list.append(back_btn)
	for btn in _button_list:
		btn.mouse_entered.connect(_on_btn_hover)
		btn.focus_entered.connect(_on_btn_hover)
	# Start pre-draw animations (pulse and rotate slightly)
	_animate_previews()

func _on_btn_hover() -> void:
	SoundManager.play_sfx("hover")

func _on_ship_selected(ship_type: GameManager.ShipType) -> void:
	GameManager.selected_ship = ship_type
	SoundManager.play_sfx("levelup", 0.0)
	
	# Transition out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	)

func _on_back_pressed() -> void:
	SoundManager.play_sfx("click")
	get_tree().change_scene_to_file("res://scenes/home.tscn")

func _animate_previews() -> void:
	var t = 0.0
	# Simple animation loops for the vector drawings
	create_tween().set_loops().tween_method(func(val):
		if f_preview:
			f_preview.queue_redraw()
		if i_preview:
			i_preview.queue_redraw()
		if d_preview:
			d_preview.queue_redraw()
		if g_preview:
			g_preview.queue_redraw()
		if t_preview:
			t_preview.queue_redraw()
	, 0.0, 1.0, 0.05)
