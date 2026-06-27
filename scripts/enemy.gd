extends CharacterBody2D

enum Type { SWARMER, SPEEDER, SHOOTER, TANK, DASHER }
@export var enemy_type: Type = Type.SWARMER

@export var max_hp: float = 3.0
var hp: float = 3.0

@export var speed: float = 120.0
@export var damage: int = 1
@export var xp_value: float = 1.0

# Preloaded to avoid repeated disk I/O on every hit/death
const FLOATING_TEXT_SCRIPT = preload("res://scripts/floating_text.gd")
const XP_GEM_SCENE = preload("res://scenes/xp_gem.tscn")

# Shooting parameters (for Shooter type)
@export var bullet_scene: PackedScene
var shoot_cooldown: float = 2.0
var shoot_timer: float = 0.0
var shoot_range: float = 250.0

var player: Node2D = null

# Hit flash visual
var flash_timer: float = 0.0

func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	
	# Find player
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
		
	# Select stats based on type if not customized
	match enemy_type:
		Type.SWARMER:
			max_hp = 3.0
			speed = 110.0
			damage = 1
			xp_value = 1.0
		Type.SPEEDER:
			max_hp = 1.0
			speed = 180.0
			damage = 1
			xp_value = 1.0
		Type.SHOOTER:
			max_hp = 6.0
			speed = 70.0
			damage = 1
			xp_value = 3.0
			shoot_cooldown = 2.5
		Type.TANK:
			max_hp = 18.0
			speed = 40.0
			damage = 2
			xp_value = 5.0
		Type.DASHER:
			max_hp = 2.0
			speed = 280.0
			damage = 1
			xp_value = 2.0
			
	hp = max_hp
	queue_redraw()

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	if not is_instance_valid(player) or player.visible == false:
		# If player is dead, drift away or stop
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		move_and_slide()
		return
		
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var dir = to_player.normalized()
	
	# Face the player
	rotation = dir.angle() + PI/2
	
	match enemy_type:
		Type.SWARMER, Type.SPEEDER, Type.TANK, Type.DASHER:
			# Direct chase
			velocity = dir * speed
			move_and_slide()
			
			# Check contact damage
			for i in range(get_slide_collision_count()):
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider and collider.is_in_group("player"):
					collider.take_damage(damage)
					
		Type.SHOOTER:
			# Stop when in range to shoot, otherwise move closer
			if dist > shoot_range - 40.0:
				velocity = dir * speed
				move_and_slide()
			else:
				# Drift slowly or keep distance
				velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
				move_and_slide()
				
			# Handle shooting
			shoot_timer += delta
			if shoot_timer >= shoot_cooldown:
				if dist <= shoot_range:
					shoot_at_player(dir)
					shoot_timer = 0.0

func _process(delta: float) -> void:
	if flash_timer > 0.0:
		flash_timer -= delta
	queue_redraw()

func shoot_at_player(dir: Vector2) -> void:
	if not bullet_scene:
		return
		
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + dir * 15.0
	bullet.direction = dir
	# Set simple properties if enemy bullet script supports it
	bullet.damage = 1
	bullet.speed = 280.0
	bullet.collision_mask = 2 # Hit player
	get_parent().add_child(bullet)

func take_damage(amount: float) -> void:
	hp -= amount
	flash_timer = 0.1
	queue_redraw()
	
	spawn_floating_text(str(int(amount)))
	
	if hp <= 0.0:
		die()

func spawn_floating_text(txt: String) -> void:
	# Cap total floating texts to avoid node buildup
	if get_tree().get_nodes_in_group("floating_texts").size() > 20:
		return
	var ft = Node2D.new()
	ft.set_script(FLOATING_TEXT_SCRIPT)
	ft.add_to_group("floating_texts")
	ft.text = txt
	ft.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
	get_parent().add_child(ft)

func die() -> void:
	# Decrement spawner counter (avoids group scan for the cap check)
	var spawners = get_tree().get_nodes_in_group("spawner")
	if not spawners.is_empty():
		spawners[0]._active_enemy_count = max(0, spawners[0]._active_enemy_count - 1)
	
	# Play retro synth explosion
	SoundManager.play_sfx("explode", 0.4)
	
	spawn_debris()
	spawn_xp_gem()
	queue_free()

func spawn_debris() -> void:
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 12
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 90.0
	particles.scale_amount_min = 1.5
	particles.scale_amount_max = 3.0
	particles.color = Color.WHITE
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	var timer = get_tree().create_timer(0.4)
	timer.timeout.connect(particles.queue_free)

func spawn_xp_gem() -> void:
	var gem = XP_GEM_SCENE.instantiate()
	gem.global_position = global_position
	gem.xp_value = xp_value
	get_parent().call_deferred("add_child", gem)

func _draw() -> void:
	var time_ms = Time.get_ticks_msec()
	var pulse = (sin(time_ms * 0.01) + 1.0) / 2.0
	var fast_pulse = (sin(time_ms * 0.03) + 1.0) / 2.0
	var core_color = Color(1.0, 0.3, 0.3, 0.5 + 0.5 * pulse)
	var is_flashing = flash_timer > 0.0

	if is_flashing:
		match enemy_type:
			Type.SWARMER:
				var pts = PackedVector2Array([
					Vector2(0, -8), Vector2(6, -2), Vector2(4, 8), 
					Vector2(-4, 8), Vector2(-6, -2)
				])
				draw_colored_polygon(pts, Color.WHITE)
			Type.SPEEDER:
				var pts = PackedVector2Array([
					Vector2(0, -12), Vector2(8, 8), Vector2(0, 4), Vector2(-8, 8)
				])
				draw_colored_polygon(pts, Color.WHITE)
			Type.SHOOTER:
				var pts = PackedVector2Array([
					Vector2(0, -14), Vector2(10, -6), Vector2(10, 6), 
					Vector2(0, 14), Vector2(-10, 6), Vector2(-10, -6)
				])
				draw_colored_polygon(pts, Color.WHITE)
			Type.TANK:
				var pts = PackedVector2Array([
					Vector2(-12, -12), Vector2(12, -12), Vector2(16, 0), Vector2(12, 12), Vector2(-12, 12), Vector2(-16, 0)
				])
				draw_colored_polygon(pts, Color.WHITE)
			Type.DASHER:
				var pts = PackedVector2Array([
					Vector2(0, -14), Vector2(8, 6), Vector2(0, 0), Vector2(-8, 6)
				])
				draw_colored_polygon(pts, Color.WHITE)
	else:
		match enemy_type:
			Type.SWARMER:
				var pts = PackedVector2Array([
					Vector2(0, -8), Vector2(6, -2), Vector2(4, 8), 
					Vector2(-4, 8), Vector2(-6, -2), Vector2(0, -8)
				])
				draw_colored_polygon(pts, Color.BLACK)
				draw_polyline(pts, Color.WHITE, 1.5, true)
				# Mandibles
				draw_line(Vector2(4, -5), Vector2(8, -10), Color(0.8, 0.8, 0.8), 1.0)
				draw_line(Vector2(-4, -5), Vector2(-8, -10), Color(0.8, 0.8, 0.8), 1.0)
				# Glowing insect core
				draw_circle(Vector2(0, 2), 2.0 + pulse, core_color)
				
			Type.SPEEDER:
				var pts = PackedVector2Array([
					Vector2(0, -12), Vector2(8, 8), Vector2(0, 4), Vector2(-8, 8), Vector2(0, -12)
				])
				draw_colored_polygon(pts, Color.BLACK)
				draw_polyline(pts, Color.WHITE, 1.5, true)
				# Internal aerodynamics
				draw_line(Vector2(0, -8), Vector2(0, 2), Color(0.6, 0.6, 0.6), 1.0)
				# Thruster
				draw_circle(Vector2(0, 6), 1.5 + 1.5 * fast_pulse, core_color)
				
			Type.SHOOTER:
				var pts = PackedVector2Array([
					Vector2(0, -14), Vector2(10, -6), Vector2(10, 6), 
					Vector2(0, 14), Vector2(-10, 6), Vector2(-10, -6), Vector2(0, -14)
				])
				draw_colored_polygon(pts, Color.BLACK)
				draw_polyline(pts, Color.WHITE, 1.5, true)
				# Rotating inner geometry
				var rot_angle = time_ms * 0.002
				var inner_pts = PackedVector2Array()
				for i in range(4):
					var a = rot_angle + i * PI / 2.0
					inner_pts.append(Vector2(cos(a), sin(a)) * 5.0)
				inner_pts.append(inner_pts[0])
				draw_polyline(inner_pts, Color(0.8, 0.8, 0.8), 1.0, true)
				# Core eye
				draw_circle(Vector2.ZERO, 2.0 + 1.0 * pulse, core_color)
				
			Type.TANK:
				var pts = PackedVector2Array([
					Vector2(-12, -12), Vector2(12, -12), Vector2(16, 0), Vector2(12, 12), Vector2(-12, 12), Vector2(-16, 0), Vector2(-12, -12)
				])
				draw_colored_polygon(pts, Color.BLACK)
				draw_polyline(pts, Color.WHITE, 2.0, true)
				# Heavy plating lines
				draw_line(Vector2(-12, -6), Vector2(12, -6), Color(0.5, 0.5, 0.5), 1.5)
				draw_line(Vector2(-12, 6), Vector2(12, 6), Color(0.5, 0.5, 0.5), 1.5)
				# Outer pulsing nodes
				draw_circle(Vector2(14, 0), 2.0 + pulse, core_color)
				draw_circle(Vector2(-14, 0), 2.0 + pulse, core_color)
				draw_circle(Vector2(0, 0), 4.0 + 1.0 * pulse, core_color)
				
			Type.DASHER:
				var pts = PackedVector2Array([
					Vector2(0, -14), Vector2(8, 6), Vector2(0, 0), Vector2(-8, 6), Vector2(0, -14)
				])
				draw_colored_polygon(pts, Color.BLACK)
				draw_polyline(pts, Color.WHITE, 1.5, true)
				# Layered arrow
				draw_polyline(PackedVector2Array([Vector2(0, -8), Vector2(4, 4), Vector2(0, 2), Vector2(-4, 4), Vector2(0, -8)]), Color(0.6, 0.6, 0.6), 1.0)
				# Dash core
				draw_circle(Vector2(0, 0), 1.0 + 1.5 * fast_pulse, core_color)
