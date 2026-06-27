extends PanelContainer

signal selected(upgrade_id: String)

var upgrade_id: String = ""

@onready var name_label: Label = $MarginContainer/VBox/NameLabel
@onready var desc_label: Label = $MarginContainer/VBox/DescLabel
@onready var level_label: Label = $MarginContainer/VBox/LevelLabel
@onready var select_button: Button = $SelectButton
@onready var icon_draw: Control = $MarginContainer/VBox/IconDraw

func setup(id: String) -> void:
	upgrade_id = id
	var data = GameManager.upgrades[id]
	
	name_label.text = data["name"]
	desc_label.text = data["desc"]
	
	var current_lvl = data["level"]
	var max_lvl = data["max_level"]
	
	if current_lvl == 0:
		level_label.text = "NEW UPGRADE"
	else:
		level_label.text = "LEVEL %d / %d" % [current_lvl + 1, max_lvl]
		
	# Redraw the icon
	icon_draw.queue_redraw()

func _ready() -> void:
	select_button.pressed.connect(_on_pressed)
	icon_draw.draw.connect(_on_icon_draw)
	
	# Connect focus/hover signals for desktop feedback
	select_button.mouse_entered.connect(_on_hover_entered)
	select_button.mouse_exited.connect(_on_hover_exited)
	select_button.focus_entered.connect(_on_hover_entered)
	select_button.focus_exited.connect(_on_hover_exited)

func _on_icon_draw() -> void:
	var center = icon_draw.size / 2.0
	var col = Color.WHITE
	
	# Draw vector shapes based on upgrade type
	match upgrade_id:
		"fire_rate":
			# Two rapid bullets side-by-side with trails
			var b1 = center - Vector2(12, 0)
			var b2 = center + Vector2(12, 0)
			
			# Bullet 1
			icon_draw.draw_line(b1 - Vector2(6, 0), b1 + Vector2(6, 0), col, 3.0)
			icon_draw.draw_line(b1 - Vector2(14, 0), b1 - Vector2(8, 0), col, 1.0)
			# Bullet 2
			icon_draw.draw_line(b2 - Vector2(6, 0), b2 + Vector2(6, 0), col, 3.0)
			icon_draw.draw_line(b2 - Vector2(14, 0), b2 - Vector2(8, 0), col, 1.0)
			
		"bullets_count":
			# Three bullets spreading out
			var start = center + Vector2(0, 12)
			icon_draw.draw_line(start, start + Vector2(-18, -26), col, 2.0)
			icon_draw.draw_line(start, start + Vector2(0, -32), col, 2.0)
			icon_draw.draw_line(start, start + Vector2(18, -26), col, 2.0)
			# Arrow heads
			icon_draw.draw_circle(start + Vector2(-18, -26), 2.5, col)
			icon_draw.draw_circle(start + Vector2(0, -32), 2.5, col)
			icon_draw.draw_circle(start + Vector2(18, -26), 2.5, col)
			
		"pierce":
			# A bullet passing through a shield wall
			var wall_y_top = center.y - 20.0
			var wall_y_bottom = center.y + 20.0
			# Vertical wall (dashed line or solid)
			icon_draw.draw_line(Vector2(center.x, wall_y_top), Vector2(center.x, wall_y_bottom), col, 2.0)
			
			# Bullet line going straight through
			icon_draw.draw_line(center - Vector2(25, 0), center + Vector2(25, 0), col, 1.5)
			# Bullet tip
			icon_draw.draw_polyline(PackedVector2Array([
				center + Vector2(20, -4), center + Vector2(26, 0), center + Vector2(20, 4)
			]), col, 1.5)
			
		"speed":
			# Engine thruster chevrons >>>
			var offset_x = 14.0
			for i in range(-1, 2):
				var cx = center.x + i * offset_x
				icon_draw.draw_polyline(PackedVector2Array([
					Vector2(cx - 8, center.y - 12),
					Vector2(cx, center.y),
					Vector2(cx - 8, center.y + 12)
				]), col, 2.0)
				
		"shield_max":
			# Thick glowing shield circle
			icon_draw.draw_circle(center, 18.0, Color.BLACK)
			# Outer outline
			var pts = PackedVector2Array()
			var segments = 20
			for i in range(segments + 1):
				var angle = i * 2.0 * PI / segments
				pts.append(center + Vector2(cos(angle), sin(angle)) * 18.0)
			icon_draw.draw_polyline(pts, col, 2.5, true)
			# Inner core dot
			icon_draw.draw_circle(center, 4.0, col)
			
		"shield_regen":
			# Shield circle with rotating curved arrows
			icon_draw.draw_circle(center, 18.0, Color.BLACK)
			var pts = PackedVector2Array()
			var segments = 16
			for i in range(segments + 1):
				var angle = i * 2.0 * PI / segments
				pts.append(center + Vector2(cos(angle), sin(angle)) * 18.0)
			icon_draw.draw_polyline(pts, col, 1.5, true)
			
			# Plus sign in the middle representing regen
			icon_draw.draw_line(center - Vector2(6, 0), center + Vector2(6, 0), col, 2.0)
			icon_draw.draw_line(center - Vector2(0, 6), center + Vector2(0, 6), col, 2.0)
			
		"magnet":
			# U-shaped magnet
			var mag_col = col
			# Left prong
			icon_draw.draw_line(center + Vector2(-10, -14), center + Vector2(-10, 4), mag_col, 4.0)
			# Right prong
			icon_draw.draw_line(center + Vector2(10, -14), center + Vector2(10, 4), mag_col, 4.0)
			# Bottom bend
			var pts = PackedVector2Array()
			for i in range(11):
				var angle = i * PI / 10
				pts.append(center + Vector2(cos(angle) * -10.0, sin(angle) * 10.0 + 4.0))
			icon_draw.draw_polyline(pts, mag_col, 4.0)
			# Magnetic field lines at top prongs
			icon_draw.draw_line(center + Vector2(-10, -20), center + Vector2(-10, -24), col, 1.0)
			icon_draw.draw_line(center + Vector2(10, -20), center + Vector2(10, -24), col, 1.0)
			
		"damage":
			# Spikey starburst representing high damage
			var pts = PackedVector2Array()
			var num_spikes = 12
			for i in range(num_spikes * 2):
				var is_even = (i % 2 == 0)
				var r = 22.0 if is_even else 8.0
				var angle = i * PI / num_spikes
				pts.append(center + Vector2(cos(angle), sin(angle)) * r)
			pts.append(pts[0]) # close loop
			icon_draw.draw_polyline(pts, col, 1.5, true)
			icon_draw.draw_circle(center, 4.0, col)
			
		"shield_nova":
			# Circle with explosive spokes
			icon_draw.draw_circle(center, 12.0, Color.BLACK)
			var pts = PackedVector2Array()
			var segments = 16
			for i in range(segments + 1):
				var angle = i * 2.0 * PI / segments
				pts.append(center + Vector2(cos(angle), sin(angle)) * 12.0)
			icon_draw.draw_polyline(pts, col, 2.0, true)
			
			# Radials (spokes)
			for i in range(8):
				var angle = i * PI / 4.0
				var dir = Vector2(cos(angle), sin(angle))
				icon_draw.draw_line(center + dir * 15.0, center + dir * 25.0, col, 1.5)


func _on_pressed() -> void:
	# Trigger selection
	emit_signal("selected", upgrade_id)
	GameManager.apply_upgrade(upgrade_id)

func _on_hover_entered() -> void:
	# Hover feedback: slightly scale up and add white modulate boost
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)
	modulate = Color(1.2, 1.2, 1.2, 1.0) # glow effect

func _on_hover_exited() -> void:
	# Normal state
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	modulate = Color.WHITE
