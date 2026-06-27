extends Control

# crt_overlay.gd - Programmatic scanline overlay to simulate a retro CRT monitor screen.
# Pure vector drawing. Ensures mouse events are ignored to not block gameplay.

@export var scanline_gap: int = 3
@export var scanline_color: Color = Color(0, 0, 0, 0.12)
@export var frame_color: Color = Color(1, 1, 1, 0.05)

func _ready() -> void:
	# Ignore all mouse/touch inputs
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Make sure it fills screen and anchors are set
	anchors_preset = Control.PRESET_FULL_RECT
	
	resized.connect(queue_redraw)

func _draw() -> void:
	var sz = size
	
	# 1. Draw horizontal CRT scanlines
	for y in range(0, int(sz.y), scanline_gap):
		draw_line(Vector2(0, y), Vector2(sz.x, y), scanline_color, 1.0)
		
	# 2. Draw subtle sci-fi border grid overlay
	# Thin inner frame offset by 6px
	var margin = 6.0
	var rect = Rect2(margin, margin, sz.x - margin*2, sz.y - margin*2)
	draw_rect(rect, frame_color, false, 1.0)
	
	# Add tiny corner markings
	var mark_size = 12.0
	# Top-left corner tick
	draw_line(Vector2(margin + 2, margin + 2), Vector2(margin + 2 + mark_size, margin + 2), Color.WHITE, 1.0)
	draw_line(Vector2(margin + 2, margin + 2), Vector2(margin + 2, margin + 2 + mark_size), Color.WHITE, 1.0)
	
	# Top-right corner tick
	draw_line(Vector2(sz.x - margin - 2, margin + 2), Vector2(sz.x - margin - 2 - mark_size, margin + 2), Color.WHITE, 1.0)
	draw_line(Vector2(sz.x - margin - 2, margin + 2), Vector2(sz.x - margin - 2, margin + 2 + mark_size), Color.WHITE, 1.0)
	
	# Bottom-left corner tick
	draw_line(Vector2(margin + 2, sz.y - margin - 2), Vector2(margin + 2 + mark_size, sz.y - margin - 2), Color.WHITE, 1.0)
	draw_line(Vector2(margin + 2, sz.y - margin - 2), Vector2(margin + 2, sz.y - margin - 2 - mark_size), Color.WHITE, 1.0)
	
	# Bottom-right corner tick
	draw_line(Vector2(sz.x - margin - 2, sz.y - margin - 2), Vector2(sz.x - margin - 2 - mark_size, sz.y - margin - 2), Color.WHITE, 1.0)
	draw_line(Vector2(sz.x - margin - 2, sz.y - margin - 2), Vector2(sz.x - margin - 2, sz.y - margin - 2 - mark_size), Color.WHITE, 1.0)
