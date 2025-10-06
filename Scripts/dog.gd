extends RigidBody2D

# This signal is emitted when the ball is successfully launched.
# It was being used in the original code but not declared.
signal released
signal mouse_hovered
signal mouse_unhovered

const DOG_BARK_1 = preload("res://Assets/Audio/SFX/dog-bark-179915.mp3")

#-----------------------------------------------------------------------------
# Component References (Nodes accessed from the scene tree)
#-----------------------------------------------------------------------------
@onready var particles: GPUParticles2D = $GPUParticles2D
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx: AudioStreamPlayer2D = $SFX
@onready var sounds: AudioStreamPlayer2D = $Sounds
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D
@onready var bark_timer: Timer = $BarkTimer

#-----------------------------------------------------------------------------
# Exports (Configurable in the Godot Inspector)
#-----------------------------------------------------------------------------
@export_group("Shooting")
## The Line2D node used to visualize the aim direction and power.
@export var trajectory_line: Line2D
## The minimum drag distance required to register a shot.
@export var min_power: float = 30.0
## The maximum drag distance that contributes to the shot's power.
@export var max_power: float = 150.0
## A multiplier applied to the drag vector to determine the final impulse.
@export var impulse_multiplier: float = 6.0

@export_group("Input")
## If false, all player input for this ball is ignored.
@export var input_enabled: bool = true

#-----------------------------------------------------------------------------
# State Variables
#-----------------------------------------------------------------------------
var is_dragging := false
var drag_start_position := Vector2.ZERO

#=============================================================================
# Godot Engine Callbacks
#=============================================================================

func _ready() -> void:
	# Ensure particles are not emitting when the game starts.
	particles.emitting = false
	randomize()
	schedule_next_bark()

func _physics_process(_delta: float) -> void:
	# Toggle the particle emitter based on whether the body is moving.
	if linear_velocity == Vector2.ZERO:
		particles.emitting = false
	else:
		particles.emitting = false
		particles.emitting = true
	
func _process(delta: float) -> void:
	pass

func schedule_next_bark():
	# Random interval between 5 and 15 seconds
	bark_timer.wait_time = randf_range(5.0, 10.0)
	bark_timer.start()

func _toggle_input(torf: bool):
	input_enabled = torf

func _input(event: InputEvent) -> void:
	# Guard clause: Ignore all input if not enabled for this turn.
	if not input_enabled:
		return

	# --- Handle Mouse Button Input ---
	if event is InputEventMouseButton:
		# We only care about the left mouse button.
		if event.button_index == MOUSE_BUTTON_LEFT:
			
			# --- MOUSE BUTTON PRESSED ---
			if event.pressed:
				# Check if the click is inside the ball's collision shape.
				var mouse_distance_from_center = (get_global_mouse_position() - global_position).length()
				var ball_radius = get_node("CollisionShape2D").shape.radius
				
				if mouse_distance_from_center <= ball_radius:
					# Start the dragging process.
					is_dragging = true
					drag_start_position = get_global_mouse_position()
			
			# --- MOUSE BUTTON RELEASED ---
			else:
				# Only process the shot if a drag was in progress.
				if is_dragging:
					var drag_end_position = get_global_mouse_position()
					var drag_vector = global_position - drag_end_position
					var drag_length = drag_vector.length()

					# Only shoot if the drag distance exceeds the minimum power threshold.
					if drag_length >= min_power:
						# Calculate the power, clamped between the min and max values.
						var clamped_length = min(drag_length, max_power)
						var clamped_vector = drag_vector.normalized() * clamped_length
						var final_impulse = clamped_vector * impulse_multiplier
						
						# Apply the force and notify listeners that a shot was fired.
						apply_central_impulse(final_impulse)
						emit_signal("released")

				# Reset dragging state and clear the trajectory line after the shot.
				is_dragging = false
				trajectory_line.clear_points()

	# --- Handle Mouse Motion Input ---
	elif event is InputEventMouseMotion and is_dragging:
		var mouse_pos = get_global_mouse_position()
		var drag_vector = global_position - mouse_pos
		var drag_length = drag_vector.length()

		# Clear previous points before drawing the new line.
		trajectory_line.clear_points()

		# Only draw the line if the drag is long enough to be a valid shot.
		if drag_length >= min_power:
			var clamped_length = min(drag_length, max_power)
			var clamped_vector = drag_vector.normalized() * clamped_length

			# The line starts at the ball's center (local Vector2.ZERO).
			trajectory_line.add_point(Vector2.ZERO)
			
			# The line ends in the direction of the shot.
			# Convert the global end position to the Line2D's local coordinate space.
			var local_end_point = to_local(global_position + clamped_vector)
			trajectory_line.add_point(local_end_point)
		
		_update_drag_preview()
		
#=============================================================================
# Public Methods
#=============================================================================

func _update_drag_preview():
	if not trajectory_line:
		return

	var mouse_pos = get_global_mouse_position()
	var drag_vector = global_position - mouse_pos
	var drag_length = drag_vector.length()

	trajectory_line.clear_points()

	if drag_length >= min_power:
		var clamped_length = min(drag_length, max_power)
		var clamped_vector = drag_vector.normalized() * clamped_length

		# Draw the line
		trajectory_line.add_point(Vector2.ZERO)
		trajectory_line.add_point(to_local(global_position + clamped_vector))

		# Compute power ratio 0.0–1.0
		var ratio = (clamped_length - min_power) / (max_power - min_power)
		ratio = clamp(ratio, 0.0, 1.0)

		# Lerp from green (weak) to red (strong)
		var start_color = Color(0.2, 1.0, 0.2)  # green
		var end_color   = Color(1.0, 0.2, 0.2)  # red
		trajectory_line.default_color = start_color.lerp(end_color, ratio)
		# If you want per-point colors, use:
		# trajectory_line.set_point_color(0, start_color)
		# trajectory_line.set_point_color(1, end_color)




## Triggers a visual "flash" effect to indicate damage has been taken.
func died() -> void:
	animated_sprite_2d.play("Died")

func alive() -> void:
	animated_sprite_2d.play("Idle")


func _on_area_2d_body_entered(body: Node2D) -> void:
	randomize()
	var p = randf_range(1, 2)
	if body.get_collision_layer() & (1 << 0) != 0:
		sfx.pitch_scale = p
		sfx.play()

	# Check if body is on layer 3 (bit 2)
	elif body.get_collision_layer() & (1 << 2) != 0:
		sounds.pitch_scale = p
		sounds.stream = DOG_BARK_1  # or whichever sound
		sounds.play()


func _on_bark_timer_timeout() -> void:
	randomize()
	var p = randf_range(1, 1.4)
	sounds.pitch_scale = p
	sounds.play()
	schedule_next_bark()
