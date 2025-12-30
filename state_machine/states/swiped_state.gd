# Swiped state - handles card flying off-screen after successful swipe
# Card accelerates in swipe direction with optional spin

extends SwipeState
class_name SwipeSwipedState

var target_position: Vector2 = Vector2.ZERO
var velocity: Vector2 = Vector2.ZERO
var current_speed: float = 0.0
var swipe_direction: Vector2 = Vector2.ZERO

# Active values (set based on juicy_mode)
var active_initial_speed: float
var active_acceleration: float
var active_max_speed: float
var active_spin_speed: float

func enter() -> void:
	var settings = swipe_card.get_swipe_settings()

	# Set active values based on juicy_mode
	if settings.juicy_mode:
		active_initial_speed = settings.initial_flyoff_speed
		active_acceleration = settings.flyoff_acceleration
		active_max_speed = settings.max_flyoff_speed
		active_spin_speed = settings.spin_speed
	else:
		# Static feel
		active_initial_speed = settings.initial_flyoff_speed
		active_acceleration = 500.0
		active_max_speed = settings.max_flyoff_speed
		active_spin_speed = 0.0

	# Get fly-off direction from swipe_card
	swipe_direction = swipe_card.get_flyoff_direction()

	# Start with high speed for immediate response
	current_speed = active_initial_speed
	velocity = swipe_direction * current_speed

func update(delta: float) -> void:
	# Accelerate for satisfying "whoosh" effect
	current_speed = min(current_speed + active_acceleration * delta, active_max_speed)
	velocity = swipe_direction * current_speed

	# Move card
	swipe_card.position += velocity * delta

	# Add spin
	var spin_direction = sign(swipe_card.rotation_degrees) if swipe_card.rotation_degrees != 0 else 1
	swipe_card.rotation_degrees += spin_direction * active_spin_speed * delta

	# Check if off-screen
	var viewport_size = get_viewport().get_visible_rect().size
	var card_pos = swipe_card.global_position

	if card_pos.x < -swipe_card.size.x or card_pos.x > viewport_size.x + swipe_card.size.x or \
	   card_pos.y < -swipe_card.size.y or card_pos.y > viewport_size.y + swipe_card.size.y:
		# Card is off-screen
		swipe_card.card_off_screen.emit()

func exit() -> void:
	pass
