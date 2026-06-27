extends Node2D

# PowerupManager: spawns shield-boost pickups randomly throughout space.
# Integrates with player via powerup.gd collect_powerup signal chain.

const SPAWN_INTERVAL: float = 14.0
const MAX_POWERUPS: int = 5
const SPAWN_RADIUS_MIN: float = 350.0
const SPAWN_RADIUS_MAX: float = 1100.0

var _spawn_timer: float = 6.0   # Initial delay before first spawn
var _active_powerups: Array = []

@onready var powerup_scene: PackedScene = load("res://scenes/powerup.tscn")

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	# Clean up freed instances
	_active_powerups = _active_powerups.filter(func(p): return is_instance_valid(p))

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = SPAWN_INTERVAL
		if _active_powerups.size() < MAX_POWERUPS:
			_spawn_powerup()

func _spawn_powerup() -> void:
	if not powerup_scene:
		return

	var player = get_tree().get_first_node_in_group("player")
	var spawn_center = Vector2.ZERO
	if player:
		spawn_center = player.global_position

	var pu = powerup_scene.instantiate()
	get_parent().add_child(pu)

	# Spawn in a ring around the player (random angle + radius)
	var angle = randf_range(0.0, TAU)
	var radius = randf_range(SPAWN_RADIUS_MIN, SPAWN_RADIUS_MAX)
	pu.global_position = spawn_center + Vector2(cos(angle), sin(angle)) * radius

	# Only one type for now: shield_boost
	pu.set_type("shield_boost")

	_active_powerups.append(pu)
