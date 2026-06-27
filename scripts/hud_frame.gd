extends Control

var player: Node2D = null
var is_danger: bool = false
var flash_timer: float = 0.0

# Preload font once — never call load() inside _draw()
const THEME_FONT = preload("res://Metamorphosis-DOWyW.ttf")

# Decorational lines length
var bracket_length: float = 24.0
var thickness: float = 2.0

# Track previous danger state to only redraw on change
var _prev_danger: bool = false
var _prev_flash_int: int = -1

func _ready() -> void:
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	resized.connect(queue_redraw)

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		modulate.a = 0.0
		return
		
	modulate.a = 1.0
	
	var new_danger = is_instance_valid(player) and player.current_hp <= 1
	
	if new_danger:
		flash_timer += delta * 6.0
	else:
		flash_timer += delta * 1.5
	
	var new_flash_int = int(flash_timer) % 2

	# Only queue_redraw when something visually meaningful changes
	if new_danger != _prev_danger or (new_danger and new_flash_int != _prev_flash_int):
		is_danger = new_danger
		_prev_danger = new_danger
		_prev_flash_int = new_flash_int
		queue_redraw()
	elif not new_danger and _prev_danger != new_danger:
		is_danger = new_danger
		_prev_danger = new_danger
		queue_redraw()

func _draw() -> void:
	var sz = size
	var offset = 12.0
	
	var col = Color(0.0, 0.8, 1.0, 0.8) # Neon cyan
	if is_danger:
		var flash = int(flash_timer) % 2
		col = Color(1.0, 0.15, 0.15, 1.0) if flash == 0 else Color(1.0, 0.55, 0.0, 0.6)
		
	# Top-Left Bracket
	draw_line(Vector2(offset, offset), Vector2(offset + bracket_length, offset), col, thickness)
	draw_line(Vector2(offset, offset), Vector2(offset, offset + bracket_length), col, thickness)
	
	# Top-Right Bracket
	draw_line(Vector2(sz.x - offset, offset), Vector2(sz.x - offset - bracket_length, offset), col, thickness)
	draw_line(Vector2(sz.x - offset, offset), Vector2(sz.x - offset, offset + bracket_length), col, thickness)
	
	# Bottom-Left Bracket
	draw_line(Vector2(offset, sz.y - offset), Vector2(offset + bracket_length, sz.y - offset), col, thickness)
	draw_line(Vector2(offset, sz.y - offset), Vector2(offset, sz.y - offset - bracket_length), col, thickness)
	
	# Bottom-Right Bracket
	draw_line(Vector2(sz.x - offset, sz.y - offset), Vector2(sz.x - offset - bracket_length, sz.y - offset), col, thickness)
	draw_line(Vector2(sz.x - offset, sz.y - offset), Vector2(sz.x - offset, sz.y - offset - bracket_length), col, thickness)
	
	# Technical telemetry dividers (Top lines)
	draw_line(Vector2(offset, 42), Vector2(offset + 220, 42), Color(0.0, 0.8, 1.0, 0.35), 1.0)
	draw_line(Vector2(sz.x - offset - 220, 42), Vector2(sz.x - offset, 42), Color(0.0, 0.8, 1.0, 0.35), 1.0)
	
	# Top-Left Cockpit Decals
	draw_string(THEME_FONT, Vector2(offset + 8, 56), "AUTO-AIM: ACTIVE", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.0, 0.8, 1.0, 0.55))
	draw_string(THEME_FONT, Vector2(offset + 8, 70), "SYS_WEAPONS: ARMED", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.0, 0.8, 1.0, 0.55))
	
	# Top-Right Cockpit Decals
	draw_string(THEME_FONT, Vector2(sz.x - offset - 200, 56), "THRUSTERS: NOMINAL", HORIZONTAL_ALIGNMENT_RIGHT, 200, 10, Color(0.0, 0.8, 1.0, 0.55))
	draw_string(THEME_FONT, Vector2(sz.x - offset - 200, 70), "SHIELD_MOD: STABLE", HORIZONTAL_ALIGNMENT_RIGHT, 200, 10, Color(0.0, 0.8, 1.0, 0.55))
	
	# Draw decorative telemetry text (font preloaded at class level — never call load() in _draw)
	var status_text = "SYS_STATUS: NOMINAL"
	var status_col = Color(0.0, 0.8, 1.0, 0.85)
	if is_danger:
		status_text = "WARNING: HULL INTEGRITY CRITICAL"
		status_col = col
		
	draw_string(THEME_FONT, Vector2(offset + 8, sz.y - offset - 8), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, status_col)
	
	var elapsed_time = GameManager.REAL_GAME_DURATION_SECS - GameManager.time_left
	var telemetry = "SECTOR: ECLIPSE-4 | T+%ds" % int(elapsed_time)
	draw_string(THEME_FONT, Vector2(sz.x - offset - 180, sz.y - offset - 8), telemetry, HORIZONTAL_ALIGNMENT_RIGHT, 180, 10, Color(0.0, 0.8, 1.0, 0.55))
