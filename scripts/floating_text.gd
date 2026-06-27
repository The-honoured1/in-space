extends Node2D

var text: String = ""
var velocity: Vector2 = Vector2.ZERO
var gravity: float = 80.0
var color: Color = Color.WHITE

const SPACE_THEME = preload("res://black_and_white.tres")

@onready var label: Label = Label.new()

func _ready() -> void:
	# Configure label
	label.text = text
	label.theme = SPACE_THEME
	label.theme_type_variation = "Label"
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(label)
	
	# Initial jump velocity
	velocity = Vector2(randf_range(-40.0, 40.0), randf_range(-80.0, -100.0))
	
	# Scale animation
	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta: float) -> void:
	# Physics movement
	velocity.y += gravity * delta
	position += velocity * delta
	
	# Fade out
	modulate.a -= delta * 1.5
	if modulate.a <= 0.0:
		queue_free()
