# SwipeCard - A modular, Tinder-style swipe card component
# Drop this into any scene and connect to signals for swipe events
#
# Usage:
#   1. Add SwipeCard.tscn to your scene (or instantiate SwipeCard script on a Control)
#   2. Add your content as a child of the SwipeCard
#   3. Connect to signals: swiped, swiping, hold_threshold_reached, etc.
#
# Example:
#   $SwipeCard.swiped.connect(func(dir): print("Swiped: ", dir))

extends Control
class_name SwipeCard

# ============================================================
# SIGNALS - Connect to these to respond to swipe events
# ============================================================

## Emitted when the user starts dragging the card
signal swipe_started()

## Emitted continuously while dragging, before threshold is reached
## direction: "up", "down", "left", "right"
## progress: 0.0 to 1.0 (percentage toward threshold)
signal swiping(direction: String, progress: float)

## Emitted when the card is held past the swipe threshold
## direction: "up", "down", "left", "right"
signal hold_threshold_reached(direction: String)

## Emitted when a successful swipe is completed
## direction: "up", "down", "left", "right"
signal swiped(direction: String)

## Emitted when the swipe is canceled (released before threshold)
signal swipe_canceled()

## Emitted when the card returns to its rest position
signal returned_to_center()

## Emitted when the card flies off-screen after a swipe
signal card_off_screen()

# ============================================================
# CONFIGURATION - Tweak these in the inspector
# ============================================================

@export_group("Swipe Behavior")
## Distance in pixels required to trigger a swipe
@export var swipe_threshold: float = 120.0
## Allow swiping down (set false to only allow up/left/right)
@export var allow_down_swipe: bool = true
## Card flies off-screen after successful swipe (false = returns to center)
@export var fly_off_on_swipe: bool = true

@export_group("Grab & Rotation")
## Percentage of card height that defines "bottom half" for grab detection
@export_range(0.0, 1.0) var grab_threshold: float = 0.5
## Pivot point offset when grabbed from top (percentage of height)
@export_range(0.0, 1.0) var pivot_y_offset: float = 0.8
## Maximum rotation in degrees while dragging
@export var max_rotation: float = 45.0
## How much horizontal movement affects rotation
@export var rotation_sensitivity: float = 0.08

@export_group("Drag Feel")
## How much the card follows the cursor horizontally (0-1)
@export_range(0.0, 1.0) var horizontal_follow_strength: float = 0.6
## How much the card follows the cursor vertically (0-1)
@export_range(0.0, 1.0) var vertical_follow_strength: float = 0.7
## Resistance to horizontal dragging (higher = more resistance)
@export var drag_resistance: float = 1.0
## Resistance to vertical dragging
@export var vertical_drag_resistance: float = 0.8

@export_group("Stretch Effect")
## Enable squash and stretch when dragging
@export var enable_stretch: bool = true
## How much to stretch the card (0.1 = 10%)
@export_range(0.0, 0.3) var stretch_amount: float = 0.1
## Intensity threshold before stretch starts (0-1)
@export_range(0.0, 1.0) var stretch_threshold: float = 0.0

@export_group("Spring Physics")
## Spring preset for return animation
@export var spring_type: int = 2  # SpringType.NORMAL
## Enable scale jiggle on return
@export var enable_scale_jiggle: bool = true

@export_group("Fly-off Animation")
## Initial speed when flying off-screen
@export var initial_flyoff_speed: float = 5500.0
## Acceleration while flying
@export var flyoff_acceleration: float = 3000.0
## Maximum fly-off speed
@export var max_flyoff_speed: float = 8000.0
## Spin speed in degrees per second
@export var spin_speed: float = 180.0

@export_group("Haptics & Polish")
## Enable haptic feedback (vibration on mobile)
@export var enable_haptics: bool = true
## Juicy mode: polished animations vs static prototype feel
@export var juicy_mode: bool = true

# ============================================================
# INTERNAL STATE
# ============================================================

var _rest_position: Vector2 = Vector2.ZERO
var _flyoff_direction: Vector2 = Vector2.ZERO
var _state_machine: SwipeStateMachine

@onready var _button: Button = $Button

func _ready() -> void:
	# Store initial position as rest position
	_rest_position = position

	# Set up button styling (invisible button for input)
	if _button:
		var normal_style = _button.get_theme_stylebox("normal", "Button")
		_button.add_theme_stylebox_override("hover", normal_style)
		_button.add_theme_stylebox_override("pressed", normal_style)

		_button.button_down.connect(_on_button_down)
		_button.button_up.connect(_on_button_up)

	# Set up state machine
	_state_machine = $StateMachine as SwipeStateMachine
	if _state_machine:
		_state_machine.swipe_card = self
		_state_machine.initialize()

	# Set pivot to center
	pivot_offset = size / 2

func _on_button_down() -> void:
	if _state_machine:
		_state_machine.request_transition("Held")

func _on_button_up() -> void:
	if _state_machine and _state_machine.current_state:
		var held_state = _state_machine.current_state
		if held_state.name == "Held" and held_state.has_method("set"):
			held_state.button_released = true
	if _button:
		_button.release_focus()

# ============================================================
# PUBLIC API - Methods for external use
# ============================================================

## Get the rest position (where the card returns to)
func get_rest_position() -> Vector2:
	return _rest_position

## Set the rest position
func set_rest_position(pos: Vector2) -> void:
	_rest_position = pos

## Get current swipe settings as a dictionary (used by states)
func get_swipe_settings() -> Dictionary:
	return {
		"swipe_threshold": swipe_threshold,
		"allow_down_swipe": allow_down_swipe,
		"fly_off_on_swipe": fly_off_on_swipe,
		"grab_threshold": grab_threshold,
		"pivot_y_offset": pivot_y_offset,
		"max_rotation": max_rotation,
		"rotation_sensitivity": rotation_sensitivity,
		"horizontal_follow_strength": horizontal_follow_strength,
		"vertical_follow_strength": vertical_follow_strength,
		"drag_resistance": drag_resistance,
		"vertical_drag_resistance": vertical_drag_resistance,
		"enable_stretch": enable_stretch,
		"stretch_amount": stretch_amount,
		"stretch_threshold": stretch_threshold,
		"spring_type": spring_type,
		"enable_scale_jiggle": enable_scale_jiggle,
		"initial_flyoff_speed": initial_flyoff_speed,
		"flyoff_acceleration": flyoff_acceleration,
		"max_flyoff_speed": max_flyoff_speed,
		"spin_speed": spin_speed,
		"enable_haptics": enable_haptics,
		"juicy_mode": juicy_mode,
	}

## Set the fly-off direction (called by HeldState)
func set_flyoff_direction(direction: Vector2) -> void:
	_flyoff_direction = direction.normalized()

## Get the fly-off direction (called by SwipedState)
func get_flyoff_direction() -> Vector2:
	return _flyoff_direction

## Reset the card to its rest position immediately
func reset_position() -> void:
	position = _rest_position
	rotation_degrees = 0.0
	scale = Vector2.ONE
	pivot_offset = size / 2
	if _state_machine:
		_state_machine.request_transition("Idle")

## Get current state name (for debugging)
func get_current_state() -> String:
	if _state_machine:
		return _state_machine.get_current_state_name()
	return ""
