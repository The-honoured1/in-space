extends Node

# Programmatic 8-Bit Retro Audio Synthesizer
# Pre-synthesizes byte arrays into AudioStreamWAV resources on startup
# to provide latency-free, zero-CPU runtime sound effects.

var sfx_library: Dictionary = {}
var sample_rate: int = 22050

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Generate sound streams on startup
	sfx_library["pew"] = _generate_pew()
	sfx_library["explode"] = _generate_explode()
	sfx_library["impact"] = _generate_impact()
	sfx_library["levelup"] = _generate_levelup()
	sfx_library["click"] = _generate_click()
	sfx_library["hover"] = _generate_hover()

func play_sfx(name: String, pitch_variance: float = 0.1) -> void:
	if not sfx_library.has(name):
		return
		
	var stream = sfx_library[name]
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	
	# Add slight pitch randomizing for retro charm
	if pitch_variance > 0.0:
		player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
		
	add_child(player)
	player.play()
	
	# Auto-destroy player when finished
	player.finished.connect(player.queue_free)

# --- SOUND EFFECT GENERATORS (8-Bit PCM Unsigned 8-Bit) ---

func _create_wav_from_bytes(bytes: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.data = bytes
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	return wav

func _generate_pew() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		# Exponential frequency sweep down (800Hz to 120Hz)
		var freq = lerp(800.0, 120.0, t * t)
		phase += (freq * 2.0 * PI) / sample_rate
		
		# Square wave for retro chiptune bite
		var sample = 1.0 if sin(phase) >= 0.0 else -1.0
		# Apply exponential volume fade-out
		var volume = 1.0 - t
		
		var val = int((sample * volume * 0.4 + 1.0) * 127.5)
		bytes.append(clamped_byte(val))
		
	return _create_wav_from_bytes(bytes)

func _generate_explode() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.45
	var num_samples = int(sample_rate * duration)
	
	var seed = 12345
	for i in range(num_samples):
		var t = float(i) / num_samples
		
		# Linear congruential generator for white noise
		seed = (seed * 1103515245 + 12345) & 0x7fffffff
		var noise = (float(seed) / 0x3fffffff) - 1.0
		
		# Low-pass filter approximation: smooth out noise over time
		var volume = exp(-t * 6.0) # Sharp exponential decay
		
		var val = int((noise * volume * 0.45 + 1.0) * 127.5)
		bytes.append(clamped_byte(val))
		
	return _create_wav_from_bytes(bytes)

func _generate_impact() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.08
	var num_samples = int(sample_rate * duration)
	
	var phase = 0.0
	var seed = 54321
	for i in range(num_samples):
		var t = float(i) / num_samples
		
		# Fast pitch drop
		var freq = lerp(450.0, 150.0, t)
		phase += (freq * 2.0 * PI) / sample_rate
		
		# Mix triangle/sine wave with a touch of white noise
		var wave = sin(phase)
		seed = (seed * 1103515245 + 12345) & 0x7fffffff
		var noise = (float(seed) / 0x3fffffff) - 1.0
		
		var sample = lerp(wave, noise, 0.3)
		var volume = 1.0 - t
		
		var val = int((sample * volume * 0.35 + 1.0) * 127.5)
		bytes.append(clamped_byte(val))
		
	return _create_wav_from_bytes(bytes)

func _generate_levelup() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	
	# Pentatonic/major chord notes (C4, E4, G4, C5, E5, G5)
	# Frequencies: 261.63, 329.63, 392.00, 523.25, 659.25, 783.99
	var notes = [261.63, 329.63, 392.00, 523.25, 659.25, 783.99]
	var note_duration = duration / notes.size()
	var samples_per_note = int(sample_rate * note_duration)
	
	var phase = 0.0
	for note_idx in range(notes.size()):
		var freq = notes[note_idx]
		for i in range(samples_per_note):
			var note_t = float(i) / samples_per_note
			phase += (freq * 2.0 * PI) / sample_rate
			
			# Triangle wave (approximated by folding phase)
			var wave = abs(fmod(phase / PI, 2.0) - 1.0) * 2.0 - 1.0
			var volume = 1.0 - note_t * 0.4 # slight fade on each note
			
			var val = int((wave * volume * 0.3 + 1.0) * 127.5)
			bytes.append(clamped_byte(val))
			
	return _create_wav_from_bytes(bytes)

func _generate_click() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.05
	var num_samples = int(sample_rate * duration)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = 1200.0 - t * 400.0 # short chirp down
		phase += (freq * 2.0 * PI) / sample_rate
		
		var sample = 1.0 if sin(phase) >= 0.0 else -1.0
		var volume = exp(-t * 15.0)
		
		var val = int((sample * volume * 0.25 + 1.0) * 127.5)
		bytes.append(clamped_byte(val))
		
	return _create_wav_from_bytes(bytes)

func _generate_hover() -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var duration = 0.03
	var num_samples = int(sample_rate * duration)
	
	var phase = 0.0
	for i in range(num_samples):
		var t = float(i) / num_samples
		var freq = 680.0
		phase += (freq * 2.0 * PI) / sample_rate
		
		var sample = sin(phase)
		var volume = exp(-t * 20.0)
		
		var val = int((sample * volume * 0.2 + 1.0) * 127.5)
		bytes.append(clamped_byte(val))
		
	return _create_wav_from_bytes(bytes)

func clamped_byte(val: int) -> int:
	return clampi(val, 0, 255)
