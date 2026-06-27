extends Control

@onready var play_button: Button = $PanelContainer/Button
@onready var info_button: Button = $PanelContainer/Button2
@onready var settings_button: Button = $PanelContainer/Button3
@onready var title_container: VBoxContainer = $TitleContainer

var info_panel: PanelContainer
var settings_panel: PanelContainer

var selector_left: Label
var selector_right: Label
var active_button: Button = null

func _ready() -> void:
	play_button.pressed.connect(_on_play_pressed)
	info_button.pressed.connect(_on_info_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	
	# Connect hover/focus signals for retro selectors
	for btn in [play_button, info_button, settings_button]:
		btn.mouse_entered.connect(_on_btn_hovered.bind(btn))
		btn.focus_entered.connect(_on_btn_hovered.bind(btn))
		btn.mouse_exited.connect(_on_btn_unhovered.bind(btn))
		btn.focus_exited.connect(_on_btn_unhovered.bind(btn))
	
	_create_info_panel()
	_create_settings_panel()
	_create_selectors()

func _create_selectors() -> void:
	selector_left = Label.new()
	selector_left.text = ">"
	selector_left.hide()
	add_child(selector_left)
	
	selector_right = Label.new()
	selector_right.text = "<"
	selector_right.hide()
	add_child(selector_right)

func _on_btn_hovered(btn: Button) -> void:
	active_button = btn
	selector_left.show()
	selector_right.show()
	SoundManager.play_sfx("hover")

func _on_btn_unhovered(btn: Button) -> void:
	if active_button == btn:
		active_button = null
		selector_left.hide()
		selector_right.hide()

func _process(delta: float) -> void:
	# Float the title container gently
	if is_instance_valid(title_container):
		title_container.position.y = 80.0 + sin(Time.get_ticks_msec() * 0.0035) * 8.0
		
	if active_button and active_button.visible:
		var bounce = sin(Time.get_ticks_msec() * 0.015) * 5.0
		
		# Position selectors to bounce horizontally
		var left_x = active_button.global_position.x - 24.0 + bounce
		var right_x = active_button.global_position.x + active_button.size.x + 8.0 - bounce
		var y = active_button.global_position.y + active_button.size.y / 2.0 - selector_left.size.y / 2.0
		
		selector_left.global_position = Vector2(left_x, y)
		selector_right.global_position = Vector2(right_x, y)
	else:
		if selector_left and selector_left.visible:
			selector_left.hide()
			selector_right.hide()

func _on_play_pressed() -> void:
	SoundManager.play_sfx("click")
	# Load ship selection scene
	get_tree().change_scene_to_file("res://scenes/ship_select.tscn")

func _on_info_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_toggle_panel(info_panel, settings_panel)

func _on_settings_pressed() -> void:
	SoundManager.play_sfx("click")
	_animate_toggle_panel(settings_panel, info_panel)

func _animate_toggle_panel(target_panel: PanelContainer, other_panel: PanelContainer) -> void:
	if other_panel.visible:
		other_panel.hide()
		other_panel.scale = Vector2.ZERO
		
	if not target_panel.visible:
		target_panel.show()
		target_panel.reset_size()
		target_panel.pivot_offset = target_panel.size / 2.0
		target_panel.scale = Vector2.ZERO
		
		var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(target_panel, "scale", Vector2.ONE, 0.3)
	else:
		target_panel.pivot_offset = target_panel.size / 2.0
		var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.tween_property(target_panel, "scale", Vector2.ZERO, 0.2)
		tween.tween_callback(target_panel.hide)

func _create_info_panel() -> void:
	info_panel = PanelContainer.new()
	info_panel.name = "InfoPanel"
	info_panel.theme = load("res://black_and_white.tres")
	info_panel.hide()
	add_child(info_panel)
	
	# Position in center of screen
	info_panel.anchors_preset = Control.PRESET_CENTER
	info_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	info_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "=== LOG ENTRY ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var text = Label.new()
	text.text = (
		"MISSION: Survive 2 hours until dawn.\n\n" +
		"CONTROLS (MOBILE):\n" +
		"- Touch & drag left side of screen to steer ship.\n" +
		"- Auto-aim and auto-fire is active.\n\n" +
		"CONTROLS (DESKTOP):\n" +
		"- WASD or Arrow Keys to move.\n" +
		"- Auto-aims & auto-fires nearest enemy.\n\n" +
		"LEVEL UP:\n" +
		"- Collect energy cores from destroyed enemies.\n" +
		"- Choose upgrades to enhance weapons & speed."
	)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(text)
	
	var close = Button.new()
	close.text = "CLOSE"
	close.pressed.connect(_on_info_pressed)
	vbox.add_child(close)

func _create_settings_panel() -> void:
	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel"
	settings_panel.theme = load("res://black_and_white.tres")
	settings_panel.hide()
	add_child(settings_panel)
	
	settings_panel.anchors_preset = Control.PRESET_CENTER
	settings_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	settings_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	settings_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var title = Label.new()
	title.text = "=== SHIP SETTINGS ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add a toggle for screen shake or sound
	var shake_toggle = CheckButton.new()
	shake_toggle.text = "SCREEN SHAKE"
	shake_toggle.button_pressed = true
	shake_toggle.toggled.connect(func(toggled_on):
		# We can write a global setting to check for screen shake
		if ProjectSettings.has_setting("user/screen_shake"):
			ProjectSettings.set_setting("user/screen_shake", toggled_on)
		else:
			# Just assign to a metadata/global var or ignore since it's simple
			pass
	)
	vbox.add_child(shake_toggle)
	
	var close = Button.new()
	close.text = "CLOSE"
	close.pressed.connect(_on_settings_pressed)
	vbox.add_child(close)
