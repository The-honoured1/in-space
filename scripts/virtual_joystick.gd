extends Control

var player: Node2D = null

# Joystick parameters
var max_drag_radius: float = 65.0
var center_pos: Vector2 = Vector2.ZERO
var knob_pos: Vector2 = Vector2.ZERO
var is_active: bool = false
var touch_id: int = -1

# Floating area: left half of screen
func _ready() -> void:
	# Keep control transparent when not active
	modulate.a = 0.0
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _input(event: InputEvent) -> void:
	# Ignore if game is paused/menu
	if GameManager.current_state != GameManager.State.PLAYING:
		if is_active:
			_reset_joystick()
		return
		
	if not is_instance_valid(player):
		return
		
	# Touch start
	if event is InputEventScreenTouch:
		if event.pressed:
			# Only trigger if touching the left side of the screen
			# Viewport dimensions can be queried dynamically
			var screen_width = get_viewport_rect().size.x
			if event.position.x < screen_width * 0.5 and not is_active:
				is_active = true
				touch_id = event.index
				center_pos = event.position
				knob_pos = event.position
				# Fade in joystick
				modulate.a = 0.6
				queue_redraw()
		else:
			# Touch release
			if event.index == touch_id:
				_reset_joystick()
				
	# Dragging
	elif event is InputEventScreenDrag:
		if event.index == touch_id and is_active:
			var drag_vec = event.position - center_pos
			if drag_vec.length() > max_drag_radius:
				drag_vec = drag_vec.normalized() * max_drag_radius
				
			knob_pos = center_pos + drag_vec
			
			# Send normalized movement vector to player
			var input_vec = drag_vec / max_drag_radius
			if player:
				player.touch_joy_vector = input_vec
				
			queue_redraw()

func _reset_joystick() -> void:
	is_active = false
	touch_id = -1
	center_pos = Vector2.ZERO
	knob_pos = Vector2.ZERO
	# Fade out joystick
	modulate.a = 0.0
	if player:
		player.touch_joy_vector = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not is_active:
		return
		
	# Convert screen coordinates to this Control's local draw coordinates
	# Controls draw in local space starting from (0,0), global_position is offset
	var local_center = center_pos - global_position
	var local_knob = knob_pos - global_position
	
	# Draw outer boundary circle (white outline, black semi-transparent center)
	draw_circle(local_center, max_drag_radius, Color(0, 0, 0, 0.4))
	
	# Draw outer ring outline
	var outer_ring = PackedVector2Array()
	var segments = 32
	for i in range(segments + 1):
		var angle = i * 2.0 * PI / segments
		outer_ring.append(local_center + Vector2(cos(angle), sin(angle)) * max_drag_radius)
	draw_polyline(outer_ring, Color.WHITE, 2.0, true)
	
	# Draw knob (solid black circle with white outline)
	var knob_radius = 20.0
	draw_circle(local_knob, knob_radius, Color.BLACK)
	
	var knob_ring = PackedVector2Array()
	for i in range(segments + 1):
		var angle = i * 2.0 * PI / segments
		knob_ring.append(local_knob + Vector2(cos(angle), sin(angle)) * knob_radius)
	draw_polyline(knob_ring, Color.WHITE, 2.0, true)
