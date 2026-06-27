extends Node2D

@export var star_count: int = 150
var stars: Array = []
var screen_size: Vector2 = Vector2(1280, 720)
var player: Node2D = null
var _camera: Camera2D = null  # Cached to avoid per-frame lookup

func _ready() -> void:
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
		
	screen_size = get_viewport_rect().size
	
	# Cache camera reference
	_camera = get_viewport().get_camera_2d()
	
	# Generate random stars
	for i in range(star_count):
		var star = {}
		star["pos"] = Vector2(randf_range(0, screen_size.x), randf_range(0, screen_size.y))
		
		# Decide layer (0 = background, 1 = midground, 2 = foreground)
		var rand_val = randf()
		if rand_val < 0.6:
			# Far stars
			star["layer"] = 0
			star["speed_mult"] = 0.08
			star["color"] = Color(0.4, 0.4, 0.4, 1.0) # Dim grey
			star["size"] = 1.0
		elif rand_val < 0.9:
			# Mid stars
			star["layer"] = 1
			star["speed_mult"] = 0.22
			star["color"] = Color(0.8, 0.8, 0.8, 1.0) # Grey-white
			star["size"] = 1.5
		else:
			# Close stars
			star["layer"] = 2
			star["speed_mult"] = 0.45
			star["color"] = Color(1.0, 1.0, 1.0, 1.0) # Bright white
			star["size"] = 2.0
			
		stars.append(star)

func _process(delta: float) -> void:
	# Get player velocity to shift stars (creating parallax)
	var velocity = Vector2(40.0, 15.0) # Default slow drift for main menu
	if is_instance_valid(player):
		velocity = player.velocity
		
	# Follow player camera visually (using cached reference)
	if is_instance_valid(_camera):
		global_position = _camera.get_screen_center_position() - screen_size / 2.0
	
	# Update star positions relative to player movement
	for star in stars:
		# Shift stars opposite to player movement velocity
		star["pos"] -= velocity * delta * star["speed_mult"]
		
		# Wrap around screen bounds
		star["pos"].x = fposmod(star["pos"].x, screen_size.x)
		star["pos"].y = fposmod(star["pos"].y, screen_size.y)
		
	queue_redraw()

func _draw() -> void:
	# Pure black base for clean vector space vibe
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color.BLACK)
	
	# Draw each star
	for star in stars:
		if star["layer"] == 2:
			# Close stars get a slight vector glow or tiny cross
			var p = star["pos"]
			var s = star["size"]
			draw_rect(Rect2(p - Vector2(s, s)/2.0, Vector2(s, s)), star["color"])
		else:
			# Other stars are simple dots/squares
			draw_rect(Rect2(star["pos"], Vector2(star["size"], star["size"])), star["color"])
