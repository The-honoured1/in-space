extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 240.0
var damage: int = 1
var lifetime: float = 3.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _draw() -> void:
	# Draw enemy bullet: a hollow diamond or dotted square
	var pts = PackedVector2Array([
		Vector2(-5, 0), Vector2(0, -5), Vector2(5, 0), Vector2(0, 5), Vector2(-5, 0)
	])
	draw_colored_polygon(pts, Color.BLACK)
	draw_polyline(pts, Color.WHITE, 1.5, true)

func _on_area_entered(area: Area2D) -> void:
	# If player has a ShieldArea
	if area.name == "ShieldArea":
		var player_node = area.get_parent()
		if player_node and player_node.has_method("take_damage"):
			player_node.take_damage(damage)
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
