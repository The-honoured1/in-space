extends Node

signal xp_changed(current_xp: float, required_xp: float)
signal level_changed(new_level: int)
signal game_state_changed(new_state: String)
signal upgrade_selected(upgrade_id: String)
signal show_upgrade_choices(choices: Array)
signal timer_updated(time_left_seconds: float)

enum State { MENU, PLAYING, LEVEL_UP, GAME_OVER, VICTORY }
var current_state: State = State.MENU

enum ShipType { FIGHTER, INTERCEPTOR, DREADNOUGHT, GHOST, TITAN }
var selected_ship: ShipType = ShipType.FIGHTER

# Game duration parameters
const REAL_GAME_DURATION_SECS: float = 300.0 # 5 minutes actual play time
const IN_GAME_SECONDS_TOTAL: float = 7200.0  # 2 hours (120 minutes)
var time_left: float = REAL_GAME_DURATION_SECS

# Progression
var level: int = 1
var xp: float = 0.0
var xp_required: float = 10.0 # Base XP requirement
const XP_GROWTH_FACTOR: float = 1.3

# Player stats upgrades tracking
var upgrades = {
	"fire_rate": {
		"name": "Rapid Thruster-Blaster",
		"desc": "+20% Weapon Fire Rate",
		"level": 0,
		"max_level": 5,
		"weight": 1.0
	},
	"bullets_count": {
		"name": "Spread Cannon",
		"desc": "+1 Bullet per shot (Fires in spread)",
		"level": 0,
		"max_level": 3,
		"weight": 0.8
	},
	"pierce": {
		"name": "Hyper-Velo Projectile",
		"desc": "Bullets pierce through +1 enemy",
		"level": 0,
		"max_level": 3,
		"weight": 0.9
	},
	"speed": {
		"name": "Sub-Light Engine",
		"desc": "+15% Ship Flight Speed",
		"level": 0,
		"max_level": 5,
		"weight": 1.0
	},
	"shield_max": {
		"name": "Quantum Shielding",
		"desc": "+1 Max Shield Capacity",
		"level": 0,
		"max_level": 5,
		"weight": 1.0
	},
	"shield_regen": {
		"name": "Flux Charger",
		"desc": "+25% Shield Recharge Speed",
		"level": 0,
		"max_level": 4,
		"weight": 0.9
	},
	"magnet": {
		"name": "Gravity Collector",
		"desc": "+35% Scrap Pickup Range",
		"level": 0,
		"max_level": 4,
		"weight": 1.0
	},
	"damage": {
		"name": "Plasma Supercharger",
		"desc": "+25% Laser Damage",
		"level": 0,
		"max_level": 5,
		"weight": 1.0
	},
	"shield_nova": {
		"name": "Nova Discharge",
		"desc": "Shield breaking triggers a visual blast damaging nearby bugs",
		"level": 0,
		"max_level": 1,
		"weight": 0.4
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func start_game() -> void:
	level = 1
	xp = 0.0
	xp_required = 10.0
	time_left = REAL_GAME_DURATION_SECS
	current_state = State.PLAYING
	
	# Reset upgrades
	for key in upgrades:
		upgrades[key]["level"] = 0
		
	emit_signal("game_state_changed", "playing")
	emit_signal("xp_changed", xp, xp_required)
	emit_signal("level_changed", level)
	get_tree().paused = false
	
	# Start sound
	SoundManager.play_sfx("levelup", 0.0)

func _process(delta: float) -> void:
	if current_state == State.PLAYING:
		var prev_int = int(time_left)
		time_left -= delta
		# Only signal when the displayed second actually changes (not 60x/sec)
		if int(time_left) != prev_int:
			emit_signal("timer_updated", time_left)
		
		if time_left <= 0:
			trigger_victory()

func gain_xp(amount: float) -> void:
	if current_state != State.PLAYING:
		return
		
	xp += amount
	emit_signal("xp_changed", xp, xp_required)
	
	if xp >= xp_required:
		level_up()

func level_up() -> void:
	xp -= xp_required
	level += 1
	# Scale XP requirements
	xp_required = floor(xp_required * XP_GROWTH_FACTOR) + 5.0
	
	emit_signal("level_changed", level)
	emit_signal("xp_changed", xp, xp_required)
	
	current_state = State.LEVEL_UP
	get_tree().paused = true
	emit_signal("game_state_changed", "level_up")
	
	SoundManager.play_sfx("levelup", 0.0)
	
	# Select choices
	var choices = get_random_upgrades(3)
	if choices.is_empty():
		# No upgrades left, resume
		resume_game()
	else:
		emit_signal("show_upgrade_choices", choices)

func get_random_upgrades(count: int) -> Array:
	var pool = []
	for id in upgrades:
		var u = upgrades[id]
		if u["level"] < u["max_level"]:
			pool.append(id)
			
	if pool.is_empty():
		return []
		
	var choices = []
	pool.shuffle()
	
	for i in range(min(count, pool.size())):
		choices.append(pool[i])
		
	return choices

func apply_upgrade(upgrade_id: String) -> void:
	if upgrades.has(upgrade_id):
		upgrades[upgrade_id]["level"] += 1
		emit_signal("upgrade_selected", upgrade_id)
		SoundManager.play_sfx("click", 0.0)
		resume_game()

func resume_game() -> void:
	current_state = State.PLAYING
	get_tree().paused = false
	emit_signal("game_state_changed", "playing")

func trigger_game_over() -> void:
	current_state = State.GAME_OVER
	get_tree().paused = true
	emit_signal("game_state_changed", "game_over")
	SoundManager.play_sfx("explode", 0.0)

func trigger_victory() -> void:
	current_state = State.VICTORY
	get_tree().paused = true
	emit_signal("game_state_changed", "victory")
	SoundManager.play_sfx("levelup", 0.0)

# Formats the timer for the UI
# 300 real seconds countdown to 0, representing 02:00:00 (2 hours) down to 00:00:00
func get_formatted_time() -> String:
	# Calculate current ratio of time left
	var ratio = time_left / REAL_GAME_DURATION_SECS
	if ratio < 0:
		ratio = 0
	var in_game_seconds_left = ratio * IN_GAME_SECONDS_TOTAL
	
	var hours = int(in_game_seconds_left / 3600)
	var minutes = int((int(in_game_seconds_left) % 3600) / 60)
	var seconds = int(in_game_seconds_left) % 60
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]
