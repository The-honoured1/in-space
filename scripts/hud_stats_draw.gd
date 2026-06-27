extends Control

# Preload font once — never call load() inside _draw()
const THEME_FONT = preload("res://Metamorphosis-DOWyW.ttf")

var player: Node2D = null

func _ready() -> void:
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
		
	# Connect to player signals to update
	if player:
		player.health_changed.connect(func(_hp, _max): queue_redraw())
		player.shield_changed.connect(func(_sh, _max): queue_redraw())

func _draw() -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	if not is_instance_valid(player) or player.visible == false:
		return
		
	var col = Color.WHITE
	
	# Draw Health Icons (Hearts/Shield shapes)
	var hp_start = Vector2(0, 10)
	var icon_spacing = 20.0
	
	# "HP" Label
	draw_string(THEME_FONT, Vector2(0, 18), "HP:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		
	var hearts_offset_x = 35.0
	for i in range(player.max_hp):
		var pos = hp_start + Vector2(hearts_offset_x + i * icon_spacing, 0)
		var shape = PackedVector2Array([
			pos + Vector2(0, -6),
			pos + Vector2(5, -6),
			pos + Vector2(7, -3),
			pos + Vector2(7, 2),
			pos + Vector2(0, 9), # tip
			pos + Vector2(-7, 2),
			pos + Vector2(-7, -3),
			pos + Vector2(-5, -6),
			pos + Vector2(0, -6)
		])
		
		if i < player.current_hp:
			# Filled
			draw_colored_polygon(shape, col)
		else:
			# Outline
			draw_polyline(shape, col, 1.5, true)
			
	# Draw Shield Icons (Hexagonal energy units)
	var sh_start = Vector2(0, 36)
	draw_string(THEME_FONT, Vector2(0, 44), "SHD:", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
		
	var shield_offset_x = 42.0
	for i in range(player.max_shield):
		var pos = sh_start + Vector2(shield_offset_x + i * icon_spacing, 0)
		var shape = PackedVector2Array([
			pos + Vector2(-6, -4),
			pos + Vector2(6, -4),
			pos + Vector2(9, 2),
			pos + Vector2(6, 8),
			pos + Vector2(-6, 8),
			pos + Vector2(-9, 2),
			pos + Vector2(-6, -4)
		])
		
		if i < player.current_shield:
			# Filled (with a small hollow center to make it look high-tech)
			draw_colored_polygon(shape, col)
			draw_circle(pos + Vector2(0, 2), 2.5, Color.BLACK)
		else:
			# Outline
			draw_polyline(shape, col, 1.5, true)
