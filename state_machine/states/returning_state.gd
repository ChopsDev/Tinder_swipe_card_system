# Returning state - spring physics animation when card returns to center
# Features 17 spring presets for different feel profiles

extends SwipeState
class_name SwipeReturningState

enum SpringType {
	CUSTOM,
	SOFT,
	NORMAL,
	STIFF,
	BOUNCY,
	SNAPPY,
	DELAYED,
	CRITICALLY_DAMPED,
	OVERDAMPED,
	UNDERDAMPED,
	JELLY,
	RUBBER_BAND,
	TILT_EMPHASIS,
	POSITION_LOCK,
	DAMPED_SNAP,
	LONG_ELASTIC,
	SPRINGY_FAST,
	SLOW_SETTLE
}

# Spring constants (can be overridden by SwipeCard exports)
var spring_constant: float = 1000.0
var damping_coefficient: float = 35.0
var rotational_spring_constant: float = 200.0
var rotational_damping_coefficient: float = 25.0
var scale_spring_constant: float = 1800.0
var scale_damping_coefficient: float = 45.0
var enable_scale_jiggle: bool = true

var original_position: Vector2 = Vector2.ZERO
var original_rotation: float = 0.0
var original_scale: Vector2 = Vector2.ONE
var velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var scale_velocity: Vector2 = Vector2.ZERO

func apply_spring_preset(spring_type: SpringType) -> void:
	match spring_type:
		SpringType.SOFT:
			spring_constant = 300.0
			damping_coefficient = 20.0
			rotational_spring_constant = 100.0
			rotational_damping_coefficient = 15.0
		SpringType.NORMAL:
			spring_constant = 1000.0
			damping_coefficient = 35.0
			rotational_spring_constant = 200.0
			rotational_damping_coefficient = 25.0
		SpringType.STIFF:
			spring_constant = 2500.0
			damping_coefficient = 50.0
			rotational_spring_constant = 400.0
			rotational_damping_coefficient = 35.0
		SpringType.BOUNCY:
			spring_constant = 1200.0
			damping_coefficient = 10.0
			rotational_spring_constant = 250.0
			rotational_damping_coefficient = 10.0
		SpringType.SNAPPY:
			spring_constant = 3000.0
			damping_coefficient = 60.0
			rotational_spring_constant = 500.0
			rotational_damping_coefficient = 50.0
		SpringType.DELAYED:
			spring_constant = 600.0
			damping_coefficient = 15.0
			rotational_spring_constant = 150.0
			rotational_damping_coefficient = 15.0
		SpringType.CRITICALLY_DAMPED:
			spring_constant = 1500.0
			damping_coefficient = 78.0
			rotational_spring_constant = 450.0
			rotational_damping_coefficient = 42.0
		SpringType.OVERDAMPED:
			spring_constant = 900.0
			damping_coefficient = 120.0
			rotational_spring_constant = 250.0
			rotational_damping_coefficient = 70.0
		SpringType.UNDERDAMPED:
			spring_constant = 1000.0
			damping_coefficient = 12.0
			rotational_spring_constant = 220.0
			rotational_damping_coefficient = 10.0
		SpringType.JELLY:
			spring_constant = 700.0
			damping_coefficient = 8.0
			rotational_spring_constant = 180.0
			rotational_damping_coefficient = 6.0
		SpringType.RUBBER_BAND:
			spring_constant = 1400.0
			damping_coefficient = 18.0
			rotational_spring_constant = 320.0
			rotational_damping_coefficient = 16.0
		SpringType.TILT_EMPHASIS:
			spring_constant = 800.0
			damping_coefficient = 30.0
			rotational_spring_constant = 600.0
			rotational_damping_coefficient = 40.0
		SpringType.POSITION_LOCK:
			spring_constant = 3000.0
			damping_coefficient = 80.0
			rotational_spring_constant = 120.0
			rotational_damping_coefficient = 10.0
		SpringType.DAMPED_SNAP:
			spring_constant = 2600.0
			damping_coefficient = 95.0
			rotational_spring_constant = 520.0
			rotational_damping_coefficient = 60.0
		SpringType.LONG_ELASTIC:
			spring_constant = 600.0
			damping_coefficient = 6.0
			rotational_spring_constant = 150.0
			rotational_damping_coefficient = 6.0
		SpringType.SPRINGY_FAST:
			spring_constant = 2200.0
			damping_coefficient = 55.0
			rotational_spring_constant = 480.0
			rotational_damping_coefficient = 45.0
		SpringType.SLOW_SETTLE:
			spring_constant = 500.0
			damping_coefficient = 25.0
			rotational_spring_constant = 120.0
			rotational_damping_coefficient = 20.0

func enter() -> void:
	# Get rest position and settings from swipe_card
	original_position = swipe_card.get_rest_position()
	original_rotation = 0.0
	original_scale = Vector2.ONE

	# Apply spring preset from swipe_card
	var settings = swipe_card.get_swipe_settings()
	apply_spring_preset(settings.spring_type)
	enable_scale_jiggle = settings.enable_scale_jiggle

	# Calculate initial velocity from card's current offset (momentum carryover)
	var position_offset = swipe_card.position - original_position
	var rotation_offset = swipe_card.rotation_degrees - original_rotation
	var scale_offset = swipe_card.scale - original_scale

	velocity = -position_offset * 2.5
	angular_velocity = -rotation_offset * 2.0
	scale_velocity = -scale_offset * 3.0

func update(delta: float) -> void:
	# Position spring physics
	var position_diff = original_position - swipe_card.position
	var spring_force = position_diff * spring_constant
	var damping_force = -velocity * damping_coefficient
	var acceleration = spring_force + damping_force
	velocity += acceleration * delta
	swipe_card.position += velocity * delta * 0.25

	# Rotation spring physics
	var rotation_diff = original_rotation - swipe_card.rotation_degrees
	var rotational_spring_force = rotation_diff * rotational_spring_constant
	var rotational_damping_force = -angular_velocity * rotational_damping_coefficient
	var angular_acceleration = rotational_spring_force + rotational_damping_force
	angular_velocity += angular_acceleration * delta
	swipe_card.rotation_degrees += angular_velocity * delta

	# Scale spring physics (jiggle effect)
	var scale_diff = original_scale - swipe_card.scale
	var scale_settled = true

	if enable_scale_jiggle:
		var scale_spring_force = scale_diff * scale_spring_constant
		var scale_damping_force = -scale_velocity * scale_damping_coefficient
		var scale_acceleration = scale_spring_force + scale_damping_force
		scale_velocity += scale_acceleration * delta
		swipe_card.scale += scale_velocity * delta
		scale_settled = scale_velocity.length() < 0.01 and scale_diff.length() < 0.01
	else:
		swipe_card.scale = original_scale
		scale_velocity = Vector2.ZERO

	# Check if settled
	if velocity.length() < 0.1 and position_diff.length() < 0.1 and \
		abs(angular_velocity) < 0.1 and abs(rotation_diff) < 0.1 and scale_settled:
		# Snap to final position
		swipe_card.position = original_position
		swipe_card.rotation_degrees = original_rotation
		swipe_card.scale = original_scale
		velocity = Vector2.ZERO
		angular_velocity = 0.0
		scale_velocity = Vector2.ZERO

		# Reset pivot to center
		swipe_card.pivot_offset = swipe_card.size / 2

		# Emit signal and transition
		swipe_card.returned_to_center.emit()
		Transitioned.emit(self, "Idle")

func exit() -> void:
	pass
