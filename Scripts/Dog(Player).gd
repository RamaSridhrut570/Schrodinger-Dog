extends RigidBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $SFX
@onready var sounds: AudioStreamPlayer2D = $Sounds

@onready var quantum_timer: Timer = $QuantumTimer
@onready var gpu_particles: GPUParticles2D = $GPUParticles2D

enum QuantumState { ALIVE, DEAD, SUPERPOSITION }
var current_state: QuantumState = QuantumState.ALIVE

@export var ALIVE_FORCE: float = 1000.0
@export var DEAD_GRAVITY_SCALE: float = 3.0
@export var NORMAL_GRAVITY_SCALE: float = 1.0
@export var HORIZONTAL_SPEED: float = 300.0
@export var TOGGLE_COOLDOWN: float = 0.5
var can_toggle: bool = true

func _ready() -> void:
	gravity_scale = NORMAL_GRAVITY_SCALE
	quantum_timer.wait_time = TOGGLE_COOLDOWN
	quantum_timer.timeout.connect(_on_quantum_timer_timeout)
	set_quantum_state(QuantumState.ALIVE)

func _physics_process(delta: float) -> void:
	# Continuous horizontal movement
	var h = Input.get_axis("left", "right")
	linear_velocity.x = h * HORIZONTAL_SPEED

	# Continuous thrust or gravity in each state
	match current_state:
		QuantumState.ALIVE:
			apply_central_force(Vector2(0, -ALIVE_FORCE))
		QuantumState.DEAD:
			# gravity_scale is already increased, no extra force needed
			pass
		QuantumState.SUPERPOSITION:
			pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch") and can_toggle:
		collapse_superposition()

func collapse_superposition() -> void:
	var new_state = QuantumState.SUPERPOSITION
	if current_state == QuantumState.SUPERPOSITION:
		new_state =  QuantumState.ALIVE if (randf() < 0.5) else QuantumState.DEAD
	else:
		new_state = QuantumState.DEAD if (current_state == QuantumState.ALIVE) else QuantumState.ALIVE
	set_quantum_state(new_state)
	can_toggle = false
	quantum_timer.start()

func set_quantum_state(new_state: QuantumState) -> void:
	current_state = new_state
	match new_state:
		QuantumState.ALIVE:
			gravity_scale = 0.0
			gpu_particles.emitting = true
			animated_sprite.play("Idle")
			animated_sprite.modulate = Color(1, 1, 0)  # yellow
			#sfx.stream = preload("res://sfx/bark_happy.wav")
			sounds.play()
		QuantumState.DEAD:
			gravity_scale = DEAD_GRAVITY_SCALE
			gpu_particles.emitting = false
			animated_sprite.play("Died")
			animated_sprite.modulate = Color(0, 1, 1)  # cyan
			#sfx.stream = preload("res://sfx/whine_sad.wav")
			sfx.play()
		QuantumState.SUPERPOSITION:
			gravity_scale = NORMAL_GRAVITY_SCALE
			gpu_particles.emitting = false
			animated_sprite.play("Died_ex")
			animated_sprite.modulate = Color(1, 1, 1)
			# optional tiny particles/breath effect

func _on_quantum_timer_timeout() -> void:
	can_toggle = true
