extends Area2D

var xp_value: float = 1.0
var speed: float = 180.0
var accel: float = 600.0
var is_pulled: bool = false
var player: Node2D = null

# Rotation for visual flair — driven by rotation property, not manual redraw
var spin_speed: float = 2.5

# Cap how many gems can exist at once (global counter via group)
const MAX_GEMS: int = 80
# Despawn if too far from player (unreachable gems)
const MAX_RANGE: float = 1200.0

func _ready() -> void:
	add_to_group("xp_gems")
	
	# If already over cap, self-destruct immediately (no XP awarded — already dropped)
	if get_tree().get_nodes_in_group("xp_gems").size() > MAX_GEMS:
		queue_free()
		return
	
	# Randomize initial rotation using the node's built-in rotation property
	rotation = randf_range(0.0, PI)
	
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	# Rotate via node property — NO queue_redraw needed, Godot handles it
	rotation += spin_speed * delta

	if not is_instance_valid(player) or player.visible == false:
		return
		
	var dist = global_position.distance_to(player.global_position)
	
	# Despawn gems that are impossibly far away
	if dist > MAX_RANGE:
		queue_free()
		return
	
	if not is_pulled:
		var pull_range = player.get_pickup_range()
		if dist <= pull_range:
			is_pulled = true
	else:
		var dir = (player.global_position - global_position).normalized()
		speed = min(speed + accel * delta, 900.0) # Cap speed
		global_position += dir * speed * delta
		
		if dist <= 15.0:
			collect()

func collect() -> void:
	GameManager.gain_xp(xp_value)
	spawn_spark()
	queue_free()

func spawn_spark() -> void:
	# Simple one-shot particle instead of creating a Line2D node
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 5
	p.lifetime = 0.2
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 60.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color.WHITE
	get_parent().add_child(p)
	p.global_position = global_position
	# Auto-free: CPUParticles2D with one_shot frees itself when done if we use a timer
	get_tree().create_timer(0.25).timeout.connect(p.queue_free)

func _draw() -> void:
	# Using node rotation property means Godot transforms the draw automatically
	# Draw a static square — rotation handled by node transform
	var half_size = 3.5
	var pts = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size),
		Vector2(-half_size, -half_size)
	])
	draw_colored_polygon(pts, Color.BLACK)
	draw_polyline(pts, Color.WHITE, 1.5, true)
