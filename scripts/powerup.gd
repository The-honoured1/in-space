extends Area2D

# Shield boost power-up pickup node
# Spawned by PowerupManager, collected when player overlaps

signal collected(type_name: String)

var _type_name: String = "shield_boost"
var _lifetime: float = 30.0  # seconds before despawn
var _life_timer: float = 0.0
var _spin: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_type(type_name: String) -> void:
	_type_name = type_name

func _process(delta: float) -> void:
	_spin += delta * 2.0
	_life_timer += delta
	
	# Fade out as lifetime expires
	if _life_timer > _lifetime * 0.7:
		var fade = 1.0 - (_life_timer - _lifetime * 0.7) / (_lifetime * 0.3)
		modulate.a = clamp(fade, 0.0, 1.0)
	
	if _life_timer >= _lifetime:
		queue_free()
		return
	
	queue_redraw()

func _draw() -> void:
	var time_ms = Time.get_ticks_msec()
	var pulse = (sin(time_ms * 0.008) + 1.0) / 2.0
	
	# Outer glow ring
	var outer_r = 18.0 + 3.0 * pulse
	draw_arc(Vector2.ZERO, outer_r, 0, TAU, 32, Color(0.0, 1.0, 1.0, 0.25 + 0.15 * pulse), 8.0)
	
	# Mid ring
	draw_arc(Vector2.ZERO, 14.0, 0, TAU, 32, Color(0.0, 1.0, 1.0, 0.7), 1.5)
	
	# Shield hexagon body (rotates slowly)
	var pts = PackedVector2Array()
	for i in range(7):
		var angle = _spin + i * TAU / 6
		pts.append(Vector2(cos(angle), sin(angle)) * 12.0)
	draw_polyline(pts, Color(0.2, 1.0, 1.0, 0.95), 2.0, true)
	
	# Inner shield cross
	draw_line(Vector2(0, -7), Vector2(0, 7), Color(0.5, 1.0, 1.0, 0.8), 1.5)
	draw_line(Vector2(-5, -2), Vector2(5, -2), Color(0.5, 1.0, 1.0, 0.8), 1.5)
	
	# Center dot
	draw_circle(Vector2.ZERO, 2.5 + 1.0 * pulse, Color(0.0, 1.0, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		# Call player's collect_powerup method
		if body.has_method("collect_powerup"):
			body.collect_powerup(_type_name)
		emit_signal("collected", _type_name)
		queue_free()
