extends Node2D

# space_grid.gd - Draws an infinite scrolling background grid to enhance movement depth.

@export var grid_size: float = 120.0
@export var grid_color: Color = Color(0.15, 0.15, 0.15, 1.0)
@export var line_width: float = 1.0

var player: Node2D = null
var screen_size: Vector2 = Vector2(1280, 720)

func _ready() -> void:
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
		
	screen_size = get_viewport_rect().size

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Follow camera viewport
	var camera = get_viewport().get_camera_2d()
	var offset = Vector2.ZERO
	
	if camera:
		offset = camera.get_screen_center_position() - screen_size / 2.0
		global_position = offset
		
	# Draw infinite grid lines based on camera scroll offset
	var start_x = fposmod(-offset.x, grid_size)
	var start_y = fposmod(-offset.y, grid_size)
	
	# Draw vertical lines
	var curr_x = start_x
	while curr_x < screen_size.x:
		draw_line(Vector2(curr_x, 0), Vector2(curr_x, screen_size.y), grid_color, line_width)
		curr_x += grid_size
		
	# Draw horizontal lines
	var curr_y = start_y
	while curr_y < screen_size.y:
		draw_line(Vector2(0, curr_y), Vector2(screen_size.x, curr_y), grid_color, line_width)
		curr_y += grid_size
