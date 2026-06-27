extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 600.0
var damage: float = 1.0
var pierce_limit: int = 0
var pierces: int = 0
var lifetime: float = 2.0

func _ready() -> void:
	# Connect collision
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Rotate bullet towards its direction
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	# Draw a crisp retro vector bullet: a glowing horizontal capsule/line
	# Since it is rotated towards direction, we can draw a line from (-8, 0) to (8, 0)
	draw_line(Vector2(-6, 0), Vector2(6, 0), Color.WHITE, 3.0)
	# Inner core
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color.WHITE, 1.0)

func _on_area_entered(area: Area2D) -> void:
	# Handle hitting enemies if they are Area2D
	if area.is_in_group("enemies"):
		hit_enemy(area)

func _on_body_entered(body: Node2D) -> void:
	# Handle hitting enemies if they are CharacterBody2D
	if body.is_in_group("enemies"):
		hit_enemy(body)

func hit_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		
		# Bullet impact particle splash
		spawn_impact_particles()
		
		# Pierce check
		if pierces < pierce_limit:
			pierces += 1
		else:
			queue_free()

func spawn_impact_particles() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 8
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 45.0
	# point splash away from bullet direction
	particles.direction = -direction
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 50.0
	particles.initial_velocity_max = 120.0
	particles.scale_amount_min = 1.0
	particles.scale_amount_max = 2.0
	particles.color = Color.WHITE
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Free particles when finished
	var timer = get_tree().create_timer(0.3)
	timer.timeout.connect(particles.queue_free)
