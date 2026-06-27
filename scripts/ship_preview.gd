extends Control

# ship_preview.gd - Renders scaled, slowly rotating vector outline of a spaceship.

@export var ship_type: int = 0 # 0=Fighter, 1=Interceptor, 2=Dreadnought

var elapsed_time: float = 0.0

func _process(delta: float) -> void:
	elapsed_time += delta
	queue_redraw()

func _draw() -> void:
	var sz = size
	var center = sz / 2.0
	
	# Scale drawing size up
	var scale_mult = 2.6
	
	# Slowly rotate back and forth (or full loop) for presentation charm
	var rot = sin(elapsed_time * 1.5) * 0.35
	
	# Center the transform
	draw_set_transform(center, rot, Vector2(scale_mult, scale_mult))
	
	var points = PackedVector2Array()
	var outline_points = PackedVector2Array()
	
	var time_ms = Time.get_ticks_msec()
	var pulse = (sin(time_ms * 0.01) + 1.0) / 2.0
	var glow_color = Color(1.0, 1.0, 1.0, 0.5 + 0.5 * pulse)
	var fast_pulse = (sin(time_ms * 0.02) + 1.0) / 2.0
	
	match ship_type:
		0: # FIGHTER
			points = PackedVector2Array([
				Vector2(0, -18), Vector2(12, 12), Vector2(4, 6), Vector2(-4, 6), Vector2(-12, 12)
			])
			outline_points = PackedVector2Array([
				Vector2(0, -18), Vector2(12, 12), Vector2(4, 6), Vector2(-4, 6), Vector2(-12, 12), Vector2(0, -18)
			])
			draw_colored_polygon(points, Color.BLACK)
			draw_polyline(outline_points, Color.WHITE, 2.0, true)
			draw_polyline(PackedVector2Array([Vector2(0, -10), Vector2(3, -2), Vector2(-3, -2), Vector2(0, -10)]), Color(0.7, 0.7, 0.7), 1.0, true)
			draw_line(Vector2(0, -5), Vector2(8, 8), Color(0.5, 0.5, 0.5), 1.0)
			draw_line(Vector2(0, -5), Vector2(-8, 8), Color(0.5, 0.5, 0.5), 1.0)
			draw_circle(Vector2(0, 6), 2.0 + 1.5 * pulse, glow_color)

		1: # INTERCEPTOR
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
			draw_line(Vector2(0, -14), Vector2(14, -4), Color(0.6, 0.6, 0.6), 1.0)
			draw_line(Vector2(0, -14), Vector2(-14, -4), Color(0.6, 0.6, 0.6), 1.0)
			draw_line(Vector2(0, -14), Vector2(0, 8), Color(0.5, 0.5, 0.5), 1.0)
			draw_circle(Vector2(4, 7), 1.5 + 1.0 * fast_pulse, glow_color)
			draw_circle(Vector2(-4, 7), 1.5 + 1.0 * fast_pulse, glow_color)

		2: # DREADNOUGHT
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
			draw_line(Vector2(-5, -12), Vector2(5, -12), Color(0.5, 0.5, 0.5), 1.5)
			draw_line(Vector2(-10, 0), Vector2(10, 0), Color(0.5, 0.5, 0.5), 1.5)
			draw_polyline(PackedVector2Array([Vector2(-4, -12), Vector2(0, -4), Vector2(4, -12)]), Color(0.7, 0.7, 0.7), 1.0)
			draw_circle(Vector2(0, 8), 2.5 + 1.0 * pulse, glow_color)
			draw_circle(Vector2(-8, 12), 1.5 + 1.0 * pulse, glow_color)
			draw_circle(Vector2(8, 12), 1.5 + 1.0 * pulse, glow_color)

		3: # GHOST
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
			draw_polyline(PackedVector2Array([Vector2(-8, 4), Vector2(0, -12), Vector2(8, 4)]), Color(0.4, 0.4, 0.4), 1.0)
			draw_circle(Vector2(0, 2), 1.0 + 2.0 * fast_pulse, Color(0.8, 0.8, 1.0, 0.5 + 0.5 * fast_pulse))

		4: # TITAN
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
			draw_rect(Rect2(-6, -10, 12, 16), Color(0.3, 0.3, 0.3), false, 1.5)
			draw_line(Vector2(-14, 0), Vector2(-6, 0), Color(0.5, 0.5, 0.5), 1.0)
			draw_line(Vector2(14, 0), Vector2(6, 0), Color(0.5, 0.5, 0.5), 1.0)
			draw_rect(Rect2(-16, 16, 6, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(-6, 8, 4, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(2, 8, 4, 2 + 2*pulse), glow_color, true)
			draw_rect(Rect2(10, 16, 6, 2 + 2*pulse), glow_color, true)
