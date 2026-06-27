extends Control

# splash.gd - Splash Screen for "In-Space by Jiggy Games"
# Features retro boot sequence, title flash, loading simulation, and audio synthesis.

@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBox/SubtitleLabel
@onready var telemetry_label: Label = $TelemetryLabel
@onready var loading_bar: ProgressBar = $CenterContainer/VBox/LoadingBar

var elapsed_time: float = 0.0
var boot_state: int = 0
var dots: String = ""

func _ready() -> void:
	# Start with black screen, elements hidden/modulate=0
	title_label.modulate.a = 0.0
	subtitle_label.modulate.a = 0.0
	telemetry_label.text = ""
	loading_bar.value = 0
	loading_bar.modulate.a = 0.0
	
	# Play startup synth chime after 0.2s delay
	get_tree().create_timer(0.2).timeout.connect(func():
		SoundManager.play_sfx("levelup", 0.0)
	)

func _process(delta: float) -> void:
	elapsed_time += delta
	
	# Retro telemetry boot printing simulation
	if boot_state == 0:
		if elapsed_time < 0.8:
			var lines = [
				"BOOT ROM V4.7...",
				"SYSTEM STATUS CHECK: NOMINAL",
				"GRAPHICS DRIVER: GL_COMPATIBILITY",
				"LOADING VECTORS...",
				"AUDIO INITIALIZED programmatically"
			]
			var idx = int(elapsed_time * 6)
			var txt = ""
			for i in range(min(idx, lines.size())):
				txt += lines[i] + "\n"
			telemetry_label.text = txt
		else:
			boot_state = 1
			elapsed_time = 0.0
			
	# Fade in the title logo and developer name with chiptune clicks
	elif boot_state == 1:
		title_label.modulate.a = lerp(title_label.modulate.a, 1.0, 5.0 * delta)
		if elapsed_time > 0.4:
			subtitle_label.modulate.a = lerp(subtitle_label.modulate.a, 1.0, 5.0 * delta)
			
		if elapsed_time > 0.9:
			boot_state = 2
			elapsed_time = 0.0
			loading_bar.modulate.a = 1.0
			SoundManager.play_sfx("click")
			
	# Fill the retro loading bar
	elif boot_state == 2:
		loading_bar.value = lerp(loading_bar.value, 100.0, 1.5 * delta)
		
		# Telemetry scanning status
		var load_idx = int(loading_bar.value / 25)
		var load_txt = ["SYS: LOADING MODULES...", "SYS: GENERATING SFX...", "SYS: COMPILING SHADERS...", "SYS: LAUNCH READY!"]
		telemetry_label.text = "SYSTEM: COMPILING VECTOR BUFFERS...\nSTATUS: " + load_txt[clamp(load_idx, 0, 3)]
		
		if loading_bar.value >= 98.0:
			boot_state = 3
			elapsed_time = 0.0
			SoundManager.play_sfx("levelup")
			
	# Transition to Main Menu
	elif boot_state == 3:
		# Flash title a couple of times before transition
		var flash = int(elapsed_time * 12.0) % 2
		title_label.modulate.a = 1.0 if flash == 0 else 0.2
		
		if elapsed_time > 0.7:
			# Fade out and transition
			var tween = create_tween()
			tween.tween_property(self, "modulate:a", 0.0, 0.4)
			tween.tween_callback(func():
				get_tree().change_scene_to_file("res://scenes/home.tscn")
			)
			boot_state = 4 # stop processing

func _input(event: InputEvent) -> void:
	# Skip splash on touch/click
	if boot_state < 3 and (event is InputEventScreenTouch and event.pressed or event is InputEventMouseButton and event.pressed):
		boot_state = 3
		elapsed_time = 0.0
		SoundManager.play_sfx("click")
