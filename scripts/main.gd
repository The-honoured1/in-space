extends Node2D

@export var upgrade_card_scene: PackedScene

# UI Outlines
@onready var hud: Control = $CanvasLayer/HUD
@onready var xp_bar: ProgressBar = $CanvasLayer/HUD/XPBar
@onready var lvl_label: Label = $CanvasLayer/HUD/LvlLabel
@onready var timer_label: Label = $CanvasLayer/HUD/TimerLabel

# Overlays
@onready var level_up_overlay: Control = $CanvasLayer/LevelUpOverlay
@onready var cards_container: HBoxContainer = $CanvasLayer/LevelUpOverlay/VBoxContainer/CardsContainer

@onready var game_over_overlay: Control = $CanvasLayer/GameOverOverlay
@onready var game_over_stats: Label = $CanvasLayer/GameOverOverlay/Panel/VBox/StatsLabel

@onready var victory_overlay: Control = $CanvasLayer/VictoryOverlay
@onready var victory_stats: Label = $CanvasLayer/VictoryOverlay/Panel/VBox/StatsLabel

# Restart/Quit buttons
@onready var retry_btn: Button = $CanvasLayer/GameOverOverlay/Panel/VBox/RetryBtn
@onready var quit_btn: Button = $CanvasLayer/GameOverOverlay/Panel/VBox/QuitBtn
@onready var v_restart_btn: Button = $CanvasLayer/VictoryOverlay/Panel/VBox/RestartBtn
@onready var v_quit_btn: Button = $CanvasLayer/VictoryOverlay/Panel/VBox/QuitBtn

@onready var player: Node2D = $Player
@onready var starfield: Node2D = $Starfield

func _ready() -> void:
	# Connect GameManager signals
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.level_changed.connect(_on_level_changed)
	GameManager.game_state_changed.connect(_on_game_state_changed)
	GameManager.show_upgrade_choices.connect(_on_show_upgrade_choices)
	GameManager.timer_updated.connect(_on_timer_updated)
	
		
	# Connect UI buttons
	retry_btn.pressed.connect(_on_retry_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	v_restart_btn.pressed.connect(_on_retry_pressed)
	v_quit_btn.pressed.connect(_on_quit_pressed)
	
	# Hide overlays at start
	level_up_overlay.hide()
	game_over_overlay.hide()
	victory_overlay.hide()
	
	# Start game
	GameManager.start_game()

func _on_xp_changed(current: float, required: float) -> void:
	xp_bar.max_value = required
	xp_bar.value = current

func _on_level_changed(lvl: int) -> void:
	lvl_label.text = "LVL: %d" % lvl

func _on_timer_updated(_time_left: float) -> void:
	timer_label.text = GameManager.get_formatted_time()


func _on_game_state_changed(state: String) -> void:
	match state:
		"playing":
			level_up_overlay.hide()
			game_over_overlay.hide()
			victory_overlay.hide()
		"level_up":
			level_up_overlay.show()
		"game_over":
			var elapsed = GameManager.REAL_GAME_DURATION_SECS - GameManager.time_left
			var ratio = elapsed / GameManager.REAL_GAME_DURATION_SECS
			var in_game_seconds = ratio * GameManager.IN_GAME_SECONDS_TOTAL
			var hours = int(in_game_seconds / 3600)
			var mins = int((int(in_game_seconds) % 3600) / 60)
			var secs = int(in_game_seconds) % 60
			
			game_over_stats.text = (
				"SURVIVED: %02d hours, %02d minutes, %02d seconds\n" % [hours, mins, secs] +
				"FINAL LEVEL: %d" % GameManager.level
			)
			game_over_overlay.show()
		"victory":
			victory_stats.text = (
				"MISSION COMPLETED\n" +
				"YOU SURVIVED UNTIL DAWN!\n\n" +
				"FINAL LEVEL: %d" % GameManager.level
			)
			victory_overlay.show()

func _on_show_upgrade_choices(choices: Array) -> void:
	# Clear old cards
	for child in cards_container.get_children():
		child.queue_free()
		
	# Spawn new choices
	for i in range(choices.size()):
		var card = upgrade_card_scene.instantiate()
		cards_container.add_child(card)
		card.setup(choices[i])
		
		# Staggered popping entrance animation (runs while game is paused)
		card.scale = Vector2.ZERO
		card.process_mode = Node.PROCESS_MODE_ALWAYS
		var tween = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_interval(i * 0.15)
		tween.tween_property(card, "scale", Vector2.ONE, 0.4)
		
		# For controller navigation
		if i == 0:
			card.select_button.grab_focus()

func _on_retry_pressed() -> void:
	# Restart the scene
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	# Go back to main menu
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/home.tscn")
