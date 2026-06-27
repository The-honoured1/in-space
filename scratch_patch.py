import os

with open('c:/Users/USER/in-space/scenes/ship_select.tscn', 'r') as f:
    content = f.read()

# Replace HBox with ScrollContainer + HBox
scroll_part = """[node name="ScrollContainer" type="ScrollContainer" parent="VBox"]
layout_mode = 2
size_flags_vertical = 3
horizontal_scroll_mode = 2
vertical_scroll_mode = 0

[node name="HBox" type="HBoxContainer" parent="VBox/ScrollContainer"]
layout_mode = 2
size_flags_horizontal = 3
size_flags_vertical = 3
theme_override_constants/separation = 24
alignment = 1"""

content = content.replace("""[node name="HBox" type="HBoxContainer" parent="VBox"]
layout_mode = 2
theme_override_constants/separation = 24
alignment = 1""", scroll_part)

# Update parents inside HBox
content = content.replace('parent="VBox/HBox"', 'parent="VBox/ScrollContainer/HBox"')

# Now append the new cards before the CrtOverlay
ghost_titan_cards = """[node name="GhostCard" type="PanelContainer" parent="VBox/ScrollContainer/HBox"]
custom_minimum_size = Vector2(280, 440)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="VBox/ScrollContainer/HBox/GhostCard"]
layout_mode = 2
theme_override_constants/separation = 16
alignment = 1

[node name="Name" type="Label" parent="VBox/ScrollContainer/HBox/GhostCard/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "GHOST"
horizontal_alignment = 1

[node name="PreviewContainer" type="Control" parent="VBox/ScrollContainer/HBox/GhostCard/VBox"]
custom_minimum_size = Vector2(120, 120)
layout_mode = 2
size_flags_horizontal = 4

[node name="GhostPreview" type="Control" parent="VBox/ScrollContainer/HBox/GhostCard/VBox/PreviewContainer"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -60.0
offset_top = -60.0
offset_right = 60.0
offset_bottom = 60.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("3_preview_script")
ship_type = 3

[node name="Stats" type="Label" parent="VBox/ScrollContainer/HBox/GhostCard/VBox"]
custom_minimum_size = Vector2(240, 100)
layout_mode = 2
size_flags_horizontal = 4
theme_override_colors/font_color = Color(0.85, 0.85, 0.85, 1)
theme_override_font_sizes/font_size = 11
text = "HP: [o o]
SHIELD: [x]
SPEED: 360
WEAPON: Sharp Laser

Extremely fast, high damage, but almost zero defenses."
horizontal_alignment = 1
autowrap_mode = 2

[node name="SelectBtn" type="Button" parent="VBox/ScrollContainer/HBox/GhostCard/VBox"]
custom_minimum_size = Vector2(160, 36)
layout_mode = 2
size_flags_horizontal = 4
text = "LAUNCH GHOST"

[node name="TitanCard" type="PanelContainer" parent="VBox/ScrollContainer/HBox"]
custom_minimum_size = Vector2(280, 440)
layout_mode = 2

[node name="VBox" type="VBoxContainer" parent="VBox/ScrollContainer/HBox/TitanCard"]
layout_mode = 2
theme_override_constants/separation = 16
alignment = 1

[node name="Name" type="Label" parent="VBox/ScrollContainer/HBox/TitanCard/VBox"]
layout_mode = 2
theme_override_font_sizes/font_size = 20
text = "TITAN"
horizontal_alignment = 1

[node name="PreviewContainer" type="Control" parent="VBox/ScrollContainer/HBox/TitanCard/VBox"]
custom_minimum_size = Vector2(120, 120)
layout_mode = 2
size_flags_horizontal = 4

[node name="TitanPreview" type="Control" parent="VBox/ScrollContainer/HBox/TitanCard/VBox/PreviewContainer"]
layout_mode = 1
anchors_preset = 8
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -60.0
offset_top = -60.0
offset_right = 60.0
offset_bottom = 60.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("3_preview_script")
ship_type = 4

[node name="Stats" type="Label" parent="VBox/ScrollContainer/HBox/TitanCard/VBox"]
custom_minimum_size = Vector2(240, 100)
layout_mode = 2
size_flags_horizontal = 4
theme_override_colors/font_color = Color(0.85, 0.85, 0.85, 1)
theme_override_font_sizes/font_size = 11
text = "HP: [o o o o o o o o o o]
SHIELD: [x x x x x x x]
SPEED: 140
WEAPON: Quad Cannon

An absolute unit. Takes hits like a sponge."
horizontal_alignment = 1
autowrap_mode = 2

[node name="SelectBtn" type="Button" parent="VBox/ScrollContainer/HBox/TitanCard/VBox"]
custom_minimum_size = Vector2(160, 36)
layout_mode = 2
size_flags_horizontal = 4
text = "LAUNCH TITAN"

"""

content = content.replace('[node name="CrtOverlay" type="Control" parent="."]', ghost_titan_cards + '[node name="CrtOverlay" type="Control" parent="."]')

with open('c:/Users/USER/in-space/scenes/ship_select.tscn', 'w') as f:
    f.write(content)
