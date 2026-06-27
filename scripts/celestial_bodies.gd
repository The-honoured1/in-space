extends Node2D

class_name CelestialBodies

# Signals for encounters
signal planet_entered(planet_index: int, planet_name: String)
signal planet_exited(planet_index: int, planet_name: String)
signal moon_entered(planet_index: int, moon_index: int)
signal moon_exited(planet_index: int, moon_index: int)
signal blackhole_entered()
signal blackhole_exited()

# Gravity constants
@export var gravity_enabled: bool = true
@export var sun_gravity_strength: float = 300.0
@export var black_hole_gravity_strength: float = 800.0

# Sun parameters
var sun_radius: int = 120
var sun_color: Color = Color(1.0, 0.7, 0.1)

# Planets parameters (Orbit radius, planet size, color, speed, current angle, name)
var planets = [
	{
		"name": "Aquarius",
		"radius": 1000.0,
		"size": 45.0,
		"color": Color(0.1, 0.7, 1.0),
		"speed": 0.05,
		"angle": 0.0,
		"moons": [
			{
				"name": "Ariel",
				"radius": 120.0,
				"size": 14.0,
				"color": Color(0.8, 0.8, 0.85),
				"speed": 0.35,
				"angle": 1.0
			}
		]
	},
	{
		"name": "Ares",
		"radius": 2000.0,
		"size": 65.0,
		"color": Color(1.0, 0.35, 0.1),
		"speed": 0.03,
		"angle": PI * 0.5,
		"moons": [
			{
				"name": "Phobos",
				"radius": 150.0,
				"size": 16.0,
				"color": Color(0.7, 0.7, 0.7),
				"speed": 0.25,
				"angle": 0.0
			}
		]
	}
]

# Black Hole parameters
var black_hole = {
	"name": "Gargantua",
	"pos": Vector2(3000.0, -2200.0),
	"radius": 80.0,
	"color": Color(0.0, 0.0, 0.0, 1.0)
}

# Tracking overlap states to trigger signals only once on entry/exit
var inside_planets: Dictionary = {}
var inside_moons: Dictionary = {}
var inside_blackhole: bool = false

# Timer to throttle blackhole pull sound effects
var bh_sound_timer: float = 0.0

func _ready() -> void:
	# Initialize inside tracking
	for i in range(planets.size()):
		inside_planets[i] = false
		inside_moons[i] = {}
		for j in range(planets[i]["moons"].size()):
			inside_moons[i][j] = false

func _process(delta: float) -> void:
	# Update planet and moon angles for orbital motion
	for planet in planets:
		planet["angle"] += planet["speed"] * delta
		for moon in planet["moons"]:
			moon["angle"] += moon["speed"] * delta
			
	# Update timers
	if bh_sound_timer > 0.0:
		bh_sound_timer -= delta

	# Check player proximity to emit signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_check_proximities(player)

	# Trigger redraw to animate custom glowing graphics and indicators
	queue_redraw()

# Checks distance to all celestial bodies and fires events
func _check_proximities(player: CharacterBody2D) -> void:
	var player_pos = player.global_position
	
	# 1. Planets Proximity
	for i in range(planets.size()):
		var planet = planets[i]
		var planet_pos = Vector2(planet["radius"], 0).rotated(planet["angle"])
		var dist = player_pos.distance_to(planet_pos)
		var encounter_range = planet["size"] * 3.5 # Proximity alert/benefit zone
		
		if dist < encounter_range:
			if not inside_planets[i]:
				inside_planets[i] = true
				emit_signal("planet_entered", i, planet["name"])
		else:
			if inside_planets[i]:
				inside_planets[i] = false
				emit_signal("planet_exited", i, planet["name"])
				
		# Moons under this planet
		for j in range(planet["moons"].size()):
			var moon = planet["moons"][j]
			var moon_pos = planet_pos + Vector2(moon["radius"], 0).rotated(moon["angle"])
			var moon_dist = player_pos.distance_to(moon_pos)
			var moon_range = moon["size"] * 3.0
			
			if moon_dist < moon_range:
				if not inside_moons[i][j]:
					inside_moons[i][j] = true
					emit_signal("moon_entered", i, j)
			else:
				if inside_moons[i][j]:
					inside_moons[i][j] = false
					emit_signal("moon_exited", i, j)

	# 2. Black Hole Proximity
	var bh_dist = player_pos.distance_to(black_hole["pos"])
	var bh_range = 450.0 # Larger pull zone
	if bh_dist < bh_range:
		if not inside_blackhole:
			inside_blackhole = true
			emit_signal("blackhole_entered")
			
		# Play soft rumble cue at intervals when inside gravity pull
		if bh_sound_timer <= 0.0:
			SoundManager.play_sfx("blackhole_pull", 0.05)
			bh_sound_timer = 1.6 # Duration of cue interval
	else:
		if inside_blackhole:
			inside_blackhole = false
			emit_signal("blackhole_exited")

# Get gravity acceleration vector to apply to the ship
func get_gravity_acceleration(ship_global_pos: Vector2) -> Vector2:
	if not gravity_enabled:
		return Vector2.ZERO
		
	var total_gravity = Vector2.ZERO
	
	# Sun gravity (at origin)
	var to_sun = -ship_global_pos
	var dist_sun = to_sun.length()
	if dist_sun > 120.0: # Outside core
		# Smooth dropoff to avoid infinite spike at center
		var force_mag = sun_gravity_strength * 12000.0 / (dist_sun * dist_sun)
		force_mag = min(force_mag, 500.0) # Cap maximum pull
		total_gravity += to_sun.normalized() * force_mag
		
	# Black hole gravity (Gargantua)
	var to_bh = black_hole["pos"] - ship_global_pos
	var dist_bh = to_bh.length()
	if dist_bh < 500.0: # Pull range
		# High gravity attraction
		var force_mag = black_hole_gravity_strength * 18000.0 / (dist_bh * dist_bh)
		# Cap pull to allow escape at outer edges but highly lethal close-in
		force_mag = min(force_mag, 900.0)
		total_gravity += to_bh.normalized() * force_mag
		
	return total_gravity

func _draw() -> void:
	var time_ms = Time.get_ticks_msec()
	
	# --- DRAW SUN ---
	var sun_pulse = sin(time_ms * 0.0025) * 8.0
	var core_rad = sun_radius + sun_pulse
	# Outer glowing corona rings
	draw_circle(Vector2.ZERO, core_rad + 60.0, Color(sun_color.r, sun_color.g, 0.0, 0.05))
	draw_circle(Vector2.ZERO, core_rad + 30.0, Color(sun_color.r, sun_color.g, 0.0, 0.15))
	draw_circle(Vector2.ZERO, core_rad, sun_color)
	
	# Solar flare rays (procedural)
	var ray_count = 12
	var ray_rot = time_ms * 0.0001
	for i in range(ray_count):
		var angle = ray_rot + i * (TAU / ray_count)
		var start_pt = Vector2(core_rad - 10, 0).rotated(angle)
		var end_pt = Vector2(core_rad + 40 + sin(time_ms * 0.004 + i) * 15, 0).rotated(angle)
		draw_line(start_pt, end_pt, Color(sun_color.r, sun_color.g * 0.8, 0.0, 0.4), 3.0)

	# --- DRAW PLANETS AND ORBITS ---
	for i in range(planets.size()):
		var planet = planets[i]
		
		# Draw Orbit path
		draw_arc(Vector2.ZERO, planet["radius"], 0, TAU, 180, Color(planet["color"].r, planet["color"].g, planet["color"].b, 0.07), 1.5)
		
		var planet_pos = Vector2(planet["radius"], 0).rotated(planet["angle"])
		
		# Draw Proximity Alert / slingshot circle
		var proximity_radius = planet["size"] * 3.5
		var prox_alpha = 0.08
		var prox_thickness = 1.0
		if inside_planets[i]:
			# Pulse glowing active proximity
			prox_alpha = 0.25 + 0.1 * sin(time_ms * 0.01)
			prox_thickness = 2.0
		draw_arc(planet_pos, proximity_radius, 0, TAU, 64, Color(planet["color"].r, planet["color"].g, planet["color"].b, prox_alpha), prox_thickness)
		
		# Draw moons orbit & moons
		for moon in planet["moons"]:
			draw_arc(planet_pos, moon["radius"], 0, TAU, 32, Color(1, 1, 1, 0.05), 1.0)
			var moon_pos = planet_pos + Vector2(moon["radius"], 0).rotated(moon["angle"])
			
			# Moon glow and body
			draw_circle(moon_pos, moon["size"] + 4.0, Color(moon["color"].r, moon["color"].g, moon["color"].b, 0.15))
			draw_circle(moon_pos, moon["size"], moon["color"])
		
		# Planet customized styling
		if planet["name"] == "Aquarius":
			# Ice planet glow
			draw_circle(planet_pos, planet["size"] + 12.0, Color(0.1, 0.7, 1.0, 0.15))
			draw_circle(planet_pos, planet["size"], planet["color"])
			# Draw Saturn-like ice rings
			var ring_pts = PackedVector2Array()
			for idx in range(33):
				var a = idx * TAU / 32
				var r_pt = Vector2(cos(a) * planet["size"] * 1.7, sin(a) * planet["size"] * 0.45).rotated(deg_to_rad(-18))
				ring_pts.append(planet_pos + r_pt)
			draw_polyline(ring_pts, Color(0.3, 0.8, 1.0, 0.5), 3.0, true)
		else: # Ares (banded red planet)
			# Gas/desert planet glow
			draw_circle(planet_pos, planet["size"] + 15.0, Color(1.0, 0.35, 0.1, 0.12))
			draw_circle(planet_pos, planet["size"], planet["color"])
			# Banding stripes
			var s = planet["size"]
			draw_line(planet_pos + Vector2(-s * 0.8, -s * 0.3), planet_pos + Vector2(s * 0.8, -s * 0.3), Color(0.5, 0.1, 0.0, 0.6), 4.0)
			draw_line(planet_pos + Vector2(-s * 0.95, 0.0), planet_pos + Vector2(s * 0.95, 0.0), Color(0.6, 0.15, 0.0, 0.6), 5.0)
			draw_line(planet_pos + Vector2(-s * 0.8, s * 0.3), planet_pos + Vector2(s * 0.8, s * 0.3), Color(0.5, 0.1, 0.0, 0.6), 4.0)

	# --- DRAW BLACK HOLE ---
	var bh_pos = black_hole["pos"]
	var bh_rad = black_hole["radius"]
	
	# Event horizon warnings (concentric warning arcs)
	var warn_pulse = sin(time_ms * 0.008)
	var warn_alpha = 0.1 + 0.05 * warn_pulse
	draw_circle(bh_pos, 450.0, Color(0.8, 0.1, 1.0, 0.02 if not inside_blackhole else 0.05))
	
	# Accretion disk lines swirling
	var base_angle = time_ms * 0.0008
	for r_offset in [25.0, 45.0, 65.0]:
		var current_r = bh_rad + r_offset + 5.0 * sin(time_ms * 0.002 + r_offset)
		var angle_shift = base_angle * (1.2 if r_offset == 45.0 else 0.8)
		# Draw accretion arcs (purple / violet)
		draw_arc(bh_pos, current_r, angle_shift, angle_shift + TAU * 0.8, 48, Color(0.6, 0.1, 1.0, 0.45 - r_offset * 0.004), 4.0)
		draw_arc(bh_pos, current_r + 4.0, angle_shift + 0.5, angle_shift + 0.5 + TAU * 0.5, 32, Color(1.0, 0.2, 0.9, 0.3), 1.5)
	
	# Core event horizon (solid pitch black hole)
	draw_circle(bh_pos, bh_rad, Color.BLACK)
	# Glowing edge ring
	draw_arc(bh_pos, bh_rad + 1.0, 0.0, TAU, 64, Color(0.8, 0.1, 1.0, 0.8), 2.5)

	# --- DRAW SCREEN EDGE RADAR MARKERS ---
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var cam = get_viewport().get_camera_2d()
		if cam:
			var viewport_size = get_viewport_rect().size / cam.zoom
			var cam_pos = cam.global_position
			
			# Sun Marker
			_draw_edge_marker(Vector2.ZERO, cam_pos, viewport_size, Color(1.0, 0.7, 0.1), "SUN")
			
			# Planets Markers
			for planet in planets:
				var planet_pos = Vector2(planet["radius"], 0).rotated(planet["angle"])
				_draw_edge_marker(planet_pos, cam_pos, viewport_size, planet["color"], planet["name"].to_upper())
				
			# Black Hole Marker
			_draw_edge_marker(black_hole["pos"], cam_pos, viewport_size, Color(0.8, 0.1, 1.0), "WARN: BLACK HOLE", true)

# Helper to calculate position and draw an edge pointer arrow
func _draw_edge_marker(target_pos: Vector2, cam_pos: Vector2, viewport_size: Vector2, color: Color, label: String, is_warning: bool = false) -> void:
	var to_target = target_pos - cam_pos
	var distance = to_target.length()
	
	# Half-extents of viewport with safety padding
	var padding = 50.0
	var h_width = (viewport_size.x / 2.0) - padding
	var h_height = (viewport_size.y / 2.0) - padding
	
	# If celestial body is on screen, don't draw an edge marker
	if abs(to_target.x) < h_width and abs(to_target.y) < h_height:
		return
		
	# Find screen boundary intersection point
	var dir = to_target.normalized()
	var marker_pos = cam_pos
	
	# Intersect projection logic
	var x_ratio = h_width / abs(dir.x) if dir.x != 0 else 99999.0
	var y_ratio = h_height / abs(dir.y) if dir.y != 0 else 99999.0
	var ratio = min(x_ratio, y_ratio)
	
	marker_pos += dir * ratio
	
	# Draw glowing neon pointer (triangle pointing in target direction)
	var arrow_angle = dir.angle()
	var points = PackedVector2Array([
		marker_pos + Vector2(16.0, 0.0).rotated(arrow_angle),
		marker_pos + Vector2(-8.0, -10.0).rotated(arrow_angle),
		marker_pos + Vector2(-8.0, 10.0).rotated(arrow_angle)
	])
	
	# Threat alert pulsing for Black Hole
	if is_warning:
		var pulse = (sin(Time.get_ticks_msec() * 0.015) + 1.0) / 2.0
		color = color.lerp(Color.RED, pulse)
		
	# Draw background drop shadow, neon fill, and wireframe outline
	draw_colored_polygon(points, Color(0, 0, 0, 0.7))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[0]]), color, 2.0, true)
	
	# Draw small distance text above marker
	var distance_km = int(distance / 100.0)
	var text_offset = Vector2(-25.0, -20.0) # Default position offset
	
	# Push text inwards to avoid overlapping edge
	if marker_pos.y < cam_pos.y - h_height + 20:
		text_offset.y = 25.0
	if marker_pos.x < cam_pos.x - h_width + 20:
		text_offset.x = 10.0
	elif marker_pos.x > cam_pos.x + h_width - 20:
		text_offset.x = -60.0
		
	# Subtle aesthetic label rendering
	draw_string(ThemeDB.fallback_font, marker_pos + text_offset, "%s [%dkm]" % [label, distance_km], HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(color.r, color.g, color.b, 0.85))
