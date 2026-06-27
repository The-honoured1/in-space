extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal shield_changed(current_shield: int, max_shield: int)

# --- Celestial Shield Boost ---
var celestial_shield_active: bool = false
var celestial_shield_timer: float = 0.0
const CELESTIAL_SHIELD_DURATION: float = 8.0

@export var bullet_scene: PackedScene

# Base Stats
var max_hp: int = 5
var current_hp: int = 5

var base_max_shield: int = 3
var max_shield: int = 3
var current_shield: int = 3
var shield_regen_cooldown: float = 4.0 # Seconds before shield begins to regen after hit
var shield_regen_tick_rate: float = 1.5 # Seconds per 1 shield point regen
var time_since_last_hit: float = 0.0
var shield_regen_timer: float = 0.0

# Movement
var base_speed: float = 240.0
var accel: float = 12.0
var friction: float = 8.0
var input_dir: Vector2 = Vector2.ZERO

# Touch Controls Joystick input (set by joystick UI)
var touch_joy_vector: Vector2 = Vector2.ZERO

# Combat / Firing
var fire_cooldown: float = 0.5 # Seconds
var fire_timer: float = 0.0
var base_damage: float = 1.0
var base_pierce: int = 0
var base_bullet_count: int = 1

# Magnet range for XP gems
var base_pickup_range: float = 75.0

# Invincibility frame on hit
var invincibility_time: float = 0.5
var invincibility_timer: float = 0.0

# Visuals
var is_shield_visible: bool = true
var target_rotation: float = 0.0

# Enemy cache — refreshed every 0.3s to avoid get_nodes_in_group spam
var _enemy_cache: Array = []
var _enemy_cache_timer: float = 0.0
const ENEMY_CACHE_INTERVAL: float = 0.3

# Precomputed shield circle points (only regenerated when shield radius changes)
var _shield_circle_pts: PackedVector2Array = PackedVector2Array()
var _shield_pulse_last: float = -1.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var thruster_particles: CPUParticles2D = $ThrusterParticles
@onready var shield_area: Area2D = $ShieldArea

func _ready() -> void:
	# Initialize stats based on selected ship
	match GameManager.selected_ship:
		GameManager.ShipType.FIGHTER:
			max_hp = 5
			base_max_shield = 3
			base_speed = 240.0
			fire_cooldown = 0.5
			base_damage = 1.0
		GameManager.ShipType.INTERCEPTOR:
			max_hp = 4
			base_max_shield = 2
			base_speed = 310.0
			fire_cooldown = 0.4
			base_damage = 1.0
		GameManager.ShipType.DREADNOUGHT:
			max_hp = 7
			base_max_shield = 5
			base_speed = 180.0
			fire_cooldown = 0.58
			base_damage = 1.35
		GameManager.ShipType.GHOST:
			max_hp = 2
			base_max_shield = 1
			base_speed = 360.0
			fire_cooldown = 0.45
			base_damage = 1.6
		GameManager.ShipType.TITAN:
			max_hp = 10
			base_max_shield = 7
			base_speed = 140.0
			fire_cooldown = 0.8
			base_damage = 2.0
			
	max_shield = base_max_shield
	current_hp = max_hp
	current_shield = max_shield
	
	# Connect to upgrade events
	GameManager.upgrade_selected.connect(_on_upgrade_selected)
	
	# Connect to CelestialSystem signals
	var celestial = get_parent().get_node_or_null("CelestialSystem")
	if celestial:
		celestial.planet_entered.connect(_on_planet_entered)
		celestial.blackhole_entered.connect(_on_blackhole_entered)
		celestial.blackhole_exited.connect(_on_blackhole_exited)
	
	# Initial emit
	emit_signal("health_changed", current_hp, max_hp)
	emit_signal("shield_changed", current_shield, max_shield)
	
	# Force redraw
	queue_redraw()

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	# Manage Invincibility
	if invincibility_timer > 0.0:
		invincibility_timer -= delta
		visible = (int(invincibility_timer * 15) % 2 == 0)
	else:
		visible = true
		
	# Celestial Shield boost timer
	if celestial_shield_active:
		celestial_shield_timer -= delta
		if celestial_shield_timer <= 0.0:
			celestial_shield_active = false
			
	# Shield recharge logic
	time_since_last_hit += delta
	var charge_cooldown = shield_regen_cooldown / (1.0 + 0.25 * GameManager.upgrades["shield_regen"]["level"])
	
	if current_shield < max_shield and time_since_last_hit >= charge_cooldown:
		shield_regen_timer += delta
		if shield_regen_timer >= shield_regen_tick_rate:
			current_shield = min(current_shield + 1, max_shield)
			shield_regen_timer = 0.0
			emit_signal("shield_changed", current_shield, max_shield)
			
	queue_redraw()
			
	# Refresh enemy cache on interval (not every frame)
	_enemy_cache_timer += delta
	if _enemy_cache_timer >= ENEMY_CACHE_INTERVAL:
		_enemy_cache = get_tree().get_nodes_in_group("enemies")
		# Purge invalid entries
		_enemy_cache = _enemy_cache.filter(func(e): return is_instance_valid(e))
		_enemy_cache_timer = 0.0

	# Firing logic
	fire_timer += delta
	var current_cooldown = fire_cooldown / (1.0 + 0.20 * GameManager.upgrades["fire_rate"]["level"])
	
	if fire_timer >= current_cooldown:
		var target = find_closest_enemy_cached()
		if target:
			fire_at(target)
			fire_timer = 0.0

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	# Get Movement input (Arrow keys, controller, or direct WASD keys)
	var left = Input.is_physical_key_pressed(KEY_A) or Input.is_action_pressed("ui_left")
	var right = Input.is_physical_key_pressed(KEY_D) or Input.is_action_pressed("ui_right")
	var up = Input.is_physical_key_pressed(KEY_W) or Input.is_action_pressed("ui_up")
	var down = Input.is_physical_key_pressed(KEY_S) or Input.is_action_pressed("ui_down")
	
	var x = float(right) - float(left)
	var y = float(down) - float(up)
	var kb_input = Vector2(x, y)
	if kb_input.length() > 0:
		kb_input = kb_input.normalized()
			
	if kb_input.length() > 0:
		input_dir = kb_input
	else:
		input_dir = touch_joy_vector
		
	var speed_multiplier = 1.0 + 0.15 * GameManager.upgrades["speed"]["level"]
	var target_speed = base_speed * speed_multiplier
	
	if input_dir.length() > 0.1:
		# Rotate ship towards movement direction (classic feel)
		target_rotation = input_dir.angle() + PI/2
		rotation = lerp_angle(rotation, target_rotation, 10.0 * delta)
		
		# Accelerate
		velocity = velocity.lerp(input_dir.normalized() * target_speed, accel * delta)
		
		# Emit thruster particles
		thruster_particles.emitting = true
	else:
		# Apply friction
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		thruster_particles.emitting = false
	
	# --- Apply celestial gravity ---
	var celestial = get_parent().get_node_or_null("CelestialSystem")
	if celestial and celestial.has_method("get_gravity_acceleration"):
		var grav = celestial.get_gravity_acceleration(global_position)
		velocity += grav * delta
		
	move_and_slide()

func _draw() -> void:
	var points = PackedVector2Array()
	var outline_points = PackedVector2Array()
	
	var time_ms = Time.get_ticks_msec()
	var pulse = (sin(time_ms * 0.01) + 1.0) / 2.0
	var glow_color = Color(1.0, 1.0, 1.0, 0.5 + 0.5 * pulse)
	var fast_pulse = (sin(time_ms * 0.02) + 1.0) / 2.0
	
	match GameManager.selected_ship:
		GameManager.ShipType.FIGHTER:
			points = PackedVector2Array([
				Vector2(0, -18), Vector2(12, 12), Vector2(4, 6), Vector2(-4, 6), Vector2(-12, 12)
			])
			outline_points = PackedVector2Array([
				Vector2(0, -18), Vector2(12, 12), Vector2(4, 6), Vector2(-4, 6), Vector2(-12, 12), Vector2(0, -18)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			# Cockpit
			draw_polyline(PackedVector2Array([Vector2(0, -10), Vector2(3, -2), Vector2(-3, -2), Vector2(0, -10)]), Color(0.7, 0.7, 0.7), 1.0, true)
			# Wing lines
			draw_line(Vector2(0, -5), Vector2(8, 8), Color(0.5, 0.5, 0.5), 1.0)
			draw_line(Vector2(0, -5), Vector2(-8, 8), Color(0.5, 0.5, 0.5), 1.0)
			# Engine Core
			draw_circle(Vector2(0, 6), 2.0 + 1.5 * pulse, glow_color)

		GameManager.ShipType.INTERCEPTOR:
			points = PackedVector2Array([
				Vector2(0, -22), Vector2(16, -4), Vector2(5, 6), Vector2(10, 14), 
				Vector2(0, 8), Vector2(-10, 14), Vector2(-5, 6), Vector2(-16, -4)
			])
			outline_points = PackedVector2Array([
				Vector2(0, -22), Vector2(16, -4), Vector2(5, 6), Vector2(10, 14), 
				Vector2(0, 8), Vector2(-10, 14), Vector2(-5, 6), Vector2(-16, -4), Vector2(0, -22)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			# Swept inner lines
			draw_line(Vector2(0, -14), Vector2(14, -4), Color(0.6, 0.6, 0.6), 1.0)
			draw_line(Vector2(0, -14), Vector2(-14, -4), Color(0.6, 0.6, 0.6), 1.0)
			draw_line(Vector2(0, -14), Vector2(0, 8), Color(0.5, 0.5, 0.5), 1.0)
			# Dual Engines
			draw_circle(Vector2(4, 7), 1.5 + 1.0 * fast_pulse, glow_color)
			draw_circle(Vector2(-4, 7), 1.5 + 1.0 * fast_pulse, glow_color)

		GameManager.ShipType.DREADNOUGHT:
			points = PackedVector2Array([
				Vector2(-5, -20), Vector2(5, -20), Vector2(14, -8), Vector2(16, 12), 
				Vector2(6, 12), Vector2(0, 8), Vector2(-6, 12), Vector2(-16, 12), Vector2(-14, -8)
			])
			outline_points = PackedVector2Array([
				Vector2(-5, -20), Vector2(5, -20), Vector2(14, -8), Vector2(16, 12), 
				Vector2(6, 12), Vector2(0, 8), Vector2(-6, 12), Vector2(-16, 12), Vector2(-14, -8), Vector2(-5, -20)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			# Heavy armor plating lines
			draw_line(Vector2(-5, -12), Vector2(5, -12), Color(0.5, 0.5, 0.5), 1.5)
			draw_line(Vector2(-10, 0), Vector2(10, 0), Color(0.5, 0.5, 0.5), 1.5)
			draw_polyline(PackedVector2Array([Vector2(-4, -12), Vector2(0, -4), Vector2(4, -12)]), Color(0.7, 0.7, 0.7), 1.0)
			# Tri-Engine
			draw_circle(Vector2(0, 8), 2.5 + 1.0 * pulse, glow_color)
			draw_circle(Vector2(-8, 12), 1.5 + 1.0 * pulse, glow_color)
			draw_circle(Vector2(8, 12), 1.5 + 1.0 * pulse, glow_color)

		GameManager.ShipType.GHOST:
			points = PackedVector2Array([
				Vector2(0, -24), Vector2(14, 8), Vector2(6, 2), 
				Vector2(0, 16), Vector2(-6, 2), Vector2(-14, 8)
			])
			outline_points = PackedVector2Array([
				Vector2(0, -24), Vector2(14, 8), Vector2(6, 2), 
				Vector2(0, 16), Vector2(-6, 2), Vector2(-14, 8), Vector2(0, -24)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			# Stealth lines
			draw_polyline(PackedVector2Array([Vector2(-8, 4), Vector2(0, -12), Vector2(8, 4)]), Color(0.4, 0.4, 0.4), 1.0)
			# Central stealth core
			draw_circle(Vector2(0, 2), 1.0 + 2.0 * fast_pulse, Color(0.8, 0.8, 1.0, 0.5 + 0.5 * fast_pulse))

		GameManager.ShipType.TITAN:
			points = PackedVector2Array([
				Vector2(-10, -16), Vector2(10, -16), Vector2(18, -4), Vector2(20, 16), 
				Vector2(8, 16), Vector2(8, 8), Vector2(-8, 8), Vector2(-8, 16), 
				Vector2(-20, 16), Vector2(-18, -4)
			])
			outline_points = PackedVector2Array([
				Vector2(-10, -16), Vector2(10, -16), Vector2(18, -4), Vector2(20, 16), 
				Vector2(8, 16), Vector2(8, 8), Vector2(-8, 8), Vector2(-8, 16), 
				Vector2(-20, 16), Vector2(-18, -4), Vector2(-10, -16)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			# Titan internal frame
			draw_rect(Rect2(-6, -10, 12, 16), Color(0.3, 0.3, 0.3), false, 1.5)
			draw_line(Vector2(-14, 0), Vector2(-6, 0), Color(0.5, 0.5, 0.5), 1.0)
			draw_line(Vector2(14, 0), Vector2(6, 0), Color(0.5, 0.5, 0.5), 1.0)
			# Quad Engine Block
			draw_rect(Rect2(-16, 16, 6, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(-6, 8, 4, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(2, 8, 4, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(10, 16, 6, 2 + 2*pulse), glow_color, true)
			
	# Draw Shield ring if shields are up
	if current_shield > 0:
		var shield_pulse = 1.0 + 0.05 * sin(Time.get_ticks_msec() * 0.005)
		if abs(shield_pulse - _shield_pulse_last) > 0.005:
			var shield_radius = 28.0 * shield_pulse
			_shield_circle_pts.clear()
			var segments = 20
			for i in range(segments + 1):
				var angle = i * 2.0 * PI / segments
				_shield_circle_pts.append(Vector2(cos(angle), sin(angle)) * shield_radius)
			_shield_pulse_last = shield_pulse
		draw_polyline(_shield_circle_pts, Color.WHITE, 1.5, true)
	
	# Draw celestial shield boost indicator (glowing cyan ring)
	if celestial_shield_active:
		var time_mss = Time.get_ticks_msec()
		var glow_alpha = 0.55 + 0.35 * sin(time_mss * 0.012)
		var glow_radius = 36.0 + 4.0 * sin(time_mss * 0.009)
		var seg = 32
		var glow_pts = PackedVector2Array()
		for k in range(seg + 1):
			var ang = k * TAU / seg
			glow_pts.append(Vector2(cos(ang), sin(ang)) * glow_radius)
		# Outer halo
		draw_polyline(glow_pts, Color(0.0, 1.0, 1.0, glow_alpha * 0.4), 8.0, true)
		# Inner ring
		draw_polyline(glow_pts, Color(0.0, 1.0, 1.0, glow_alpha), 2.0, true)
		# Countdown arc (shows remaining time)
		var fraction = celestial_shield_timer / CELESTIAL_SHIELD_DURATION
		draw_arc(Vector2.ZERO, glow_radius + 10.0, -PI / 2.0, -PI / 2.0 + fraction * TAU, 48, Color(0.0, 1.0, 1.0, 0.9), 3.0)

func find_closest_enemy_cached() -> Node2D:
	var closest: Node2D = null
	var min_dist = 99999.0
	for enemy in _enemy_cache:
		if is_instance_valid(enemy):
			var dist = global_position.distance_squared_to(enemy.global_position)
			if dist < min_dist:
				min_dist = dist
				closest = enemy
	return closest

func fire_at(enemy: Node2D) -> void:
	if not bullet_scene:
		return
		
	var target_dir = (enemy.global_position - global_position).normalized()
	
	# Play laser sound
	SoundManager.play_sfx("pew")
	
	# Stats based on upgrades
	var damage_mult = 1.0 + 0.25 * GameManager.upgrades["damage"]["level"]
	var bullet_damage = base_damage * damage_mult
	var bullet_pierce = base_pierce + GameManager.upgrades["pierce"]["level"]
	var extra_bullets = GameManager.upgrades["bullets_count"]["level"]
	
	# Spawn bullets
	# If extra bullets exist, fire in spread
	if extra_bullets == 0:
		spawn_single_bullet(target_dir, bullet_damage, bullet_pierce)
	elif extra_bullets == 1:
		# Double shot
		spawn_single_bullet(target_dir.rotated(deg_to_rad(-12)), bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir.rotated(deg_to_rad(12)), bullet_damage, bullet_pierce)
	elif extra_bullets == 2:
		# Triple shot
		spawn_single_bullet(target_dir.rotated(deg_to_rad(-20)), bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir, bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir.rotated(deg_to_rad(20)), bullet_damage, bullet_pierce)
	else:
		# Quad/Fan shot
		spawn_single_bullet(target_dir.rotated(deg_to_rad(-30)), bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir.rotated(deg_to_rad(-10)), bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir.rotated(deg_to_rad(10)), bullet_damage, bullet_pierce)
		spawn_single_bullet(target_dir.rotated(deg_to_rad(30)), bullet_damage, bullet_pierce)

func spawn_single_bullet(dir: Vector2, dmg: float, prc: int) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + dir * 15.0
	bullet.direction = dir
	bullet.damage = dmg
	bullet.pierce_limit = prc
	get_parent().add_child(bullet)

func take_damage(amount: int) -> void:
	if invincibility_timer > 0.0 or GameManager.current_state != GameManager.State.PLAYING:
		return
		
	# Damage Shield first
	if current_shield > 0:
		current_shield = max(current_shield - amount, 0)
		time_since_last_hit = 0.0
		shield_regen_timer = 0.0
		emit_signal("shield_changed", current_shield, max_shield)
		trigger_screen_shake(0.2, 5.0)
		
		# Play shield hit sound
		SoundManager.play_sfx("impact")
		
		# Nova shield breaking upgrade
		if current_shield == 0 and GameManager.upgrades["shield_nova"]["level"] > 0:
			trigger_nova_discharge()
	else:
		# Health damage
		current_hp = max(current_hp - amount, 0)
		emit_signal("health_changed", current_hp, max_hp)
		trigger_screen_shake(0.4, 10.0)
		
		# Play hull damage sound
		SoundManager.play_sfx("explode", 0.3)
		
		if current_hp <= 0:
			die()
			
	invincibility_timer = invincibility_time
	queue_redraw()

func trigger_nova_discharge() -> void:
	# Just damage enemies in a radius immediately
	var enemies = get_tree().get_nodes_in_group("enemies")
	var blast_range = 150.0
	for enemy in enemies:
		if is_instance_valid(enemy) and global_position.distance_to(enemy.global_position) < blast_range:
			enemy.take_damage(3.0) # Solid damage
			
	# Spawn a retro ring visual
	var shockwave = Line2D.new()
	shockwave.width = 3.0
	shockwave.default_color = Color.WHITE
	var segments = 32
	for i in range(segments + 1):
		var angle = i * 2.0 * PI / segments
		shockwave.add_point(Vector2(cos(angle), sin(angle)) * blast_range)
	get_parent().add_child(shockwave)
	shockwave.global_position = global_position
	
	# Animate shockwave out and disappear
	var tween = create_tween()
	tween.tween_property(shockwave, "scale", Vector2(1.2, 1.2), 0.3)
	tween.parallel().tween_property(shockwave, "modulate:a", 0.0, 0.3)
	tween.tween_callback(shockwave.queue_free)

func trigger_screen_shake(duration: float, amplitude: float) -> void:
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(duration, amplitude)

func die() -> void:
	# Hide player and trigger Game Over
	visible = false
	collision_shape.set_deferred("disabled", true)
	
	# Spawn a cool particle explosion
	var particles = CPUParticles2D.new()
	particles.emitting = true
	particles.amount = 40
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.spread = 180.0
	particles.gravity = Vector2.ZERO
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 180.0
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0
	particles.color = Color.WHITE
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	
	# Wait for explosion then trigger game over
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(func():
		GameManager.trigger_game_over()
		particles.queue_free()
	)

func _on_upgrade_selected(upgrade_id: String) -> void:
	if upgrade_id == "shield_max":
		max_shield = base_max_shield + GameManager.upgrades["shield_max"]["level"]
		current_shield = min(current_shield + 1, max_shield)
		emit_signal("shield_changed", current_shield, max_shield)
		
	# Power-up ring burst effect
	var ring = Line2D.new()
	ring.width = 1.5
	ring.default_color = Color.WHITE
	var segments = 24
	for i in range(segments + 1):
		var angle = i * 2.0 * PI / segments
		ring.add_point(Vector2(cos(angle), sin(angle)) * 24.0)
	add_child(ring)
	
	var tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(ring, "scale", Vector2(2.5, 2.5), 0.4)
	tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	tween.tween_callback(ring.queue_free)
	
	# Redraw for shield updates
	queue_redraw()

# Gets current pickup range for magnet
func get_pickup_range() -> float:
	var magnet_level = GameManager.upgrades["magnet"]["level"]
	return base_pickup_range * (1.0 + 0.35 * magnet_level)

# --- Celestial encounter callbacks ---
func _on_planet_entered(_planet_index: int, planet_name: String) -> void:
	# Planets grant a temporary shield boost
	activate_celestial_shield()
	_spawn_encounter_text("⬡ %s PROXIMITY — SHIELD BOOST!" % planet_name, Color(0.1, 1.0, 0.6))

func _on_blackhole_entered() -> void:
	trigger_screen_shake(0.5, 8.0)
	_spawn_encounter_text("⚠ BLACK HOLE GRAVITY FIELD", Color(0.9, 0.2, 1.0))

func _on_blackhole_exited() -> void:
	_spawn_encounter_text("Escaped gravity well", Color(0.6, 0.6, 1.0))

func activate_celestial_shield() -> void:
	celestial_shield_active = true
	celestial_shield_timer = CELESTIAL_SHIELD_DURATION
	SoundManager.play_sfx("shield_up", 0.05)
	queue_redraw()

func collect_powerup(type_name: String) -> void:
	if type_name == "shield_boost":
		activate_celestial_shield()
		_spawn_encounter_text("SHIELD BOOST (%ds)" % CELESTIAL_SHIELD_DURATION, Color(0.0, 1.0, 1.0))
		SoundManager.play_sfx("powerup", 0.05)

func _spawn_encounter_text(msg: String, color: Color) -> void:
	var label = Label.new()
	label.text = msg
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 11)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var parent = get_parent()
	if parent:
		parent.add_child(label)
		label.global_position = global_position + Vector2(-80, -50)
		var tween = label.create_tween()
		tween.tween_property(label, "position:y", label.position.y - 40, 1.8)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.8)
		tween.tween_callback(label.queue_free)
