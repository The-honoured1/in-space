extends Node

@export var enemy_scene: PackedScene

# Spawn rates
var base_spawn_interval: float = 1.6
var current_spawn_interval: float = 1.6
var spawn_timer: float = 0.0

var player: Node2D = null

# Track enemy count via signals instead of get_nodes_in_group() every tick
var _active_enemy_count: int = 0
const MAX_ENEMIES_ON_SCREEN: int = 120

func _ready() -> void:
	add_to_group("spawner")
	var players = get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		player = players[0]
	# Initialize count from existing enemies (e.g. after scene reload)
	_active_enemy_count = get_tree().get_nodes_in_group("enemies").size()

func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
		
	if not is_instance_valid(player) or player.visible == false:
		return
		
	# Difficulty scaling based on time elapsed
	var time_elapsed = GameManager.REAL_GAME_DURATION_SECS - GameManager.time_left
	
	# Spawning interval decreases (speed increases) as time goes on
	current_spawn_interval = max(base_spawn_interval - (time_elapsed / 120.0), 0.35)
	
	spawn_timer += delta
	if spawn_timer >= current_spawn_interval:
		# Use counter instead of get_nodes_in_group() scan
		if _active_enemy_count < MAX_ENEMIES_ON_SCREEN:
			var spawn_count = 1
			if time_elapsed > 180.0:
				spawn_count = 3
			elif time_elapsed > 60.0:
				spawn_count = 2
			for i in range(spawn_count):
				spawn_enemy_randomly(time_elapsed)
		spawn_timer = 0.0

func spawn_enemy_randomly(time_elapsed: float) -> void:
	if not enemy_scene:
		return
		
	# Select spawn position outside of viewport (750 to 900 pixels away)
	var angle = randf_range(0.0, 2.0 * PI)
	var dist = randf_range(750.0, 900.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	
	# Determine enemy type distribution based on time_elapsed
	var rand_val = randf()
	
	# 0 = Swarmer, 1 = Speeder, 2 = Shooter, 3 = Tank, 4 = Dasher
	if time_elapsed < 45.0:
		# Only Swarmers
		enemy.enemy_type = 0 # Swarmer
	elif time_elapsed < 110.0:
		# 75% Swarmer, 25% Speeder
		if rand_val < 0.25:
			enemy.enemy_type = 1 # Speeder
		else:
			enemy.enemy_type = 0
	elif time_elapsed < 200.0:
		# 40% Swarmer, 25% Speeder, 20% Shooter, 15% Tank
		if rand_val < 0.15:
			enemy.enemy_type = 3 # Tank
		elif rand_val < 0.35:
			enemy.enemy_type = 2 # Shooter
		elif rand_val < 0.60:
			enemy.enemy_type = 1 # Speeder
		else:
			enemy.enemy_type = 0
		
		# Scaled health slightly
		enemy.max_hp += 1.0
	else:
		# Late game: 20% Swarmer, 20% Speeder, 25% Shooter, 20% Tank, 15% Dasher
		if rand_val < 0.15:
			enemy.enemy_type = 4 # Dasher
		elif rand_val < 0.35:
			enemy.enemy_type = 3 # Tank
		elif rand_val < 0.60:
			enemy.enemy_type = 2 # Shooter
		elif rand_val < 0.80:
			enemy.enemy_type = 1 # Speeder
		else:
			enemy.enemy_type = 0
			
		# Late game speed / health boost
		enemy.max_hp += 2.0
		enemy.speed += 20.0
		
	_active_enemy_count += 1
	get_parent().add_child(enemy)
