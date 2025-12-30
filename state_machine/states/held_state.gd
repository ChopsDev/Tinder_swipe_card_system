# Held state - handles Tinder-style swipe behavior while card is being dragged
# Core swipe detection, rotation, stretch, and threshold detection

extends SwipeState
class_name SwipeHeldState

const SWIPE_THRESHOLD_DEFAULT = 120.0

enum HighlightState { NONE, UP, DOWN, LEFT, RIGHT }
var highlight_state: HighlightState = HighlightState.NONE

var swipe_start_position: Vector2 = Vector2.ZERO
var original_card_position: Vector2 = Vector2.ZERO
var original_card_rotation: float = 0.0
var grabbed_from_bottom: bool = false
var button_released: bool = false
var haptic_halfway_triggered: bool = false
var swipe_processing_started: bool = false

# Active values (set based on juicy_mode)
var active_max_rotation: float
var active_rotation_sensitivity: float
var active_position_follow: float
var active_vertical_follow: float
var active_drag_resistance: float
var active_vertical_drag_resistance: float
var active_swipe_threshold: float

func enter() -> void:
	# Get settings from swipe_card
	var settings = swipe_card.get_swipe_settings()

	# Set active values based on juicy_mode
	if settings.juicy_mode:
		active_max_rotation = settings.max_rotation
		active_rotation_sensitivity = settings.rotation_sensitivity
		active_position_follow = settings.horizontal_follow_strength
		active_vertical_follow = settings.vertical_follow_strength
		active_drag_resistance = settings.drag_resistance
		active_vertical_drag_resistance = settings.vertical_drag_resistance
		active_swipe_threshold = settings.swipe_threshold
	else:
		# Static, prototype feel
		active_max_rotation = 0.0
		active_rotation_sensitivity = 0.0
		active_position_follow = 0.5
		active_vertical_follow = 0.5
		active_drag_resistance = 1.0
		active_vertical_drag_resistance = 1.0
		active_swipe_threshold = settings.swipe_threshold

	# Haptic feedback on grab
	if settings.enable_haptics:
		Input.vibrate_handheld(40, 0.5)

	# Reset flags
	button_released = false
	haptic_halfway_triggered = false
	swipe_processing_started = false
	highlight_state = HighlightState.NONE

	# Store starting positions
	swipe_start_position = get_viewport().get_mouse_position()
	original_card_position = swipe_card.position
	original_card_rotation = swipe_card.rotation_degrees

	# Detect grab location and set pivot
	var local_grab_point = swipe_card.get_local_mouse_position()
	var card_size = swipe_card.size
	grabbed_from_bottom = local_grab_point.y > (card_size.y * settings.grab_threshold)

	if grabbed_from_bottom:
		swipe_card.pivot_offset = Vector2(card_size.x / 2, 0)
	else:
		swipe_card.pivot_offset = Vector2(card_size.x / 2, card_size.y * settings.pivot_y_offset)

	# Emit swipe started
	swipe_card.swipe_started.emit()

func update(delta: float) -> void:
	var settings = swipe_card.get_swipe_settings()

	# Handle button release
	if button_released and not swipe_processing_started:
		_handle_release(settings)
		return

	var current_mouse_position = get_viewport().get_mouse_position()
	var swipe_vector = current_mouse_position - swipe_start_position

	# Apply drag resistance
	var adjusted_swipe_x = swipe_vector.x / active_drag_resistance
	var adjusted_swipe_y = swipe_vector.y / active_vertical_drag_resistance

	# Calculate rotation
	var rotation_multiplier = -1 if grabbed_from_bottom else 1
	var rotation_amount = clamp(
		adjusted_swipe_x * rotation_multiplier * active_rotation_sensitivity,
		-active_max_rotation,
		active_max_rotation
	)
	swipe_card.rotation_degrees = rotation_amount

	# Move card
	swipe_card.position.x = original_card_position.x + (adjusted_swipe_x * active_position_follow)
	swipe_card.position.y = original_card_position.y + (adjusted_swipe_y * active_vertical_follow)

	# Apply directional stretch
	if settings.enable_stretch:
		_apply_stretch(swipe_vector, settings)
	else:
		swipe_card.scale = Vector2.ONE

	# Progressive haptics
	if settings.enable_haptics and not haptic_halfway_triggered:
		var swipe_progress = swipe_vector.length() / active_swipe_threshold
		if swipe_progress > 0.5:
			Input.vibrate_handheld(30, 0.3)
			haptic_halfway_triggered = true

	# Handle highlight detection
	_handle_highlight(swipe_vector, settings)

func _apply_stretch(swipe_vector: Vector2, settings: Dictionary) -> void:
	var swipe_normalized = swipe_vector.normalized() if swipe_vector.length() > 0.0 else Vector2.ZERO
	var swipe_intensity = clamp(swipe_vector.length() / active_swipe_threshold, 0.0, 1.0)

	if swipe_intensity > settings.stretch_threshold:
		var adjusted_intensity = (swipe_intensity - settings.stretch_threshold) / (1.0 - settings.stretch_threshold)
		var horizontal_influence = abs(swipe_normalized.x)
		var vertical_influence = abs(swipe_normalized.y)

		var stretch_x = 1.0 + (horizontal_influence * settings.stretch_amount * adjusted_intensity) - (vertical_influence * settings.stretch_amount * adjusted_intensity * 0.5)
		var stretch_y = 1.0 + (vertical_influence * settings.stretch_amount * adjusted_intensity) - (horizontal_influence * settings.stretch_amount * adjusted_intensity * 0.5)

		swipe_card.scale = Vector2(stretch_x, stretch_y)
	else:
		swipe_card.scale = Vector2.ONE

func _handle_highlight(swipe_vector: Vector2, settings: Dictionary) -> void:
	var direction = swipe_vector.normalized() if swipe_vector.length() > 0.0 else Vector2.ZERO
	var swipe_progress = swipe_vector.length() / active_swipe_threshold if active_swipe_threshold > 0 else 0.0

	if swipe_vector.length() > active_swipe_threshold:
		# Above threshold - determine direction
		var up_s = direction.dot(Vector2.UP)
		var down_s = direction.dot(Vector2.DOWN)
		var left_s = direction.dot(Vector2.LEFT)
		var right_s = direction.dot(Vector2.RIGHT)

		var vert_strength = max(up_s, down_s)
		var horiz_strength = max(left_s, right_s)

		var new_state: HighlightState = HighlightState.NONE
		if vert_strength > horiz_strength * 0.75:
			new_state = HighlightState.UP if (up_s >= down_s) else HighlightState.DOWN
		else:
			new_state = HighlightState.LEFT if (left_s >= right_s) else HighlightState.RIGHT

		if new_state != highlight_state:
			highlight_state = new_state
			var dir_name = _highlight_to_string(highlight_state)

			# Haptic feedback
			if settings.enable_haptics:
				match highlight_state:
					HighlightState.UP:
						Input.vibrate_handheld(80, 0.7)
					HighlightState.DOWN:
						Input.vibrate_handheld(30, 0.4)
					HighlightState.LEFT:
						Input.vibrate_handheld(40, 0.5)
					HighlightState.RIGHT:
						Input.vibrate_handheld(35, 0.5)

			swipe_card.hold_threshold_reached.emit(dir_name)
	else:
		# Below threshold
		if swipe_progress < 0.15:
			if highlight_state != HighlightState.NONE:
				highlight_state = HighlightState.NONE
		else:
			if highlight_state != HighlightState.NONE:
				highlight_state = HighlightState.NONE

			# Emit progress
			var up_s = direction.dot(Vector2.UP)
			var down_s = direction.dot(Vector2.DOWN)
			var left_s = direction.dot(Vector2.LEFT)
			var right_s = direction.dot(Vector2.RIGHT)

			var vert_strength = max(up_s, down_s)
			var horiz_strength = max(left_s, right_s)

			var progress_direction = ""
			if vert_strength > horiz_strength * 0.75:
				progress_direction = "up" if (up_s >= down_s) else "down"
			else:
				progress_direction = "left" if (left_s >= right_s) else "right"

			swipe_card.swiping.emit(progress_direction, swipe_progress)

func _handle_release(settings: Dictionary) -> void:
	var current_mouse_position = get_viewport().get_mouse_position()
	var swipe_vector = current_mouse_position - swipe_start_position
	var swipe_direction = swipe_vector.normalized()

	# Check if downward swipe is allowed
	var is_downward_swipe = swipe_direction.y > 0 and abs(swipe_direction.y) > abs(swipe_direction.x)
	var allow_swipe = settings.allow_down_swipe or not is_downward_swipe

	if swipe_vector.length() > active_swipe_threshold and allow_swipe:
		swipe_processing_started = true

		# Determine swipe direction
		var abs_x = abs(swipe_direction.x)
		var abs_y = abs(swipe_direction.y)
		var dir_name: String

		if abs_y > abs_x:
			dir_name = "up" if swipe_direction.y < 0 else "down"
		else:
			dir_name = "left" if swipe_direction.x < 0 else "right"

		# Haptic feedback
		if settings.enable_haptics:
			_play_swipe_haptic(dir_name)

		# Emit swiped signal
		swipe_card.swiped.emit(dir_name)

		if settings.fly_off_on_swipe:
			# Set fly-off direction
			swipe_card.set_flyoff_direction(swipe_direction)
			Transitioned.emit(self, "Swiped")
		else:
			Transitioned.emit(self, "Returning")
	else:
		# Swipe rejected
		swipe_card.swipe_canceled.emit()
		Transitioned.emit(self, "Returning")

func _play_swipe_haptic(direction: String) -> void:
	match direction:
		"up":
			Input.vibrate_handheld(100, 1.0)
		"down":
			Input.vibrate_handheld(80, 0.8)
			await get_tree().create_timer(0.08).timeout
			Input.vibrate_handheld(80, 0.8)
		"left":
			Input.vibrate_handheld(60, 0.7)
			await get_tree().create_timer(0.06).timeout
			Input.vibrate_handheld(60, 0.7)
		"right":
			Input.vibrate_handheld(50, 0.8)
			await get_tree().create_timer(0.05).timeout
			Input.vibrate_handheld(50, 0.8)
			await get_tree().create_timer(0.05).timeout
			Input.vibrate_handheld(50, 0.8)

func _highlight_to_string(state: HighlightState) -> String:
	match state:
		HighlightState.UP: return "up"
		HighlightState.DOWN: return "down"
		HighlightState.LEFT: return "left"
		HighlightState.RIGHT: return "right"
		_: return "none"

func exit() -> void:
	pass
