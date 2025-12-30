# State machine for managing swipe card states
# Handles transitions between Idle, Held, Returning, and Swiped states

extends Node
class_name SwipeStateMachine

## The starting state (set from inspector)
@export var initial_state: SwipeState

## Reference to the main SwipeCard (passed to all states)
var swipe_card: Control

var current_state: SwipeState
var states: Dictionary = {}
var _initialized: bool = false

func _ready() -> void:
	# Gather all child SwipeState nodes
	for child in get_children():
		if child is SwipeState:
			states[child.name.to_lower()] = child

## Initialize the state machine with the swipe card reference
## Called by SwipeCard after it sets the swipe_card reference
func initialize() -> void:
	if _initialized:
		return
	_initialized = true

	# Set swipe_card reference on all states
	for state in states.values():
		state.swipe_card = swipe_card

	# Set initial state
	if initial_state:
		current_state = initial_state
		_connect_state_signals(current_state)
		initial_state.enter()

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

## Request a transition to a new state by name
func request_transition(new_state_name: String) -> void:
	if current_state and new_state_name.to_lower() == current_state.name.to_lower():
		return
	_on_child_transition(current_state, new_state_name)

## Handle state transitions
func _on_child_transition(state: SwipeState, new_state_name: String) -> void:
	if state != current_state:
		return

	var new_state = states.get(new_state_name.to_lower())
	if not new_state:
		push_warning("SwipeStateMachine: No state found with name: " + new_state_name)
		return

	if current_state:
		_disconnect_state_signals(current_state)
		current_state.exit()

	_connect_state_signals(new_state)
	new_state.enter()
	current_state = new_state

func _connect_state_signals(state: SwipeState) -> void:
	if not state.Transitioned.is_connected(_on_child_transition):
		state.Transitioned.connect(_on_child_transition)

func _disconnect_state_signals(state: SwipeState) -> void:
	if state.Transitioned.is_connected(_on_child_transition):
		state.Transitioned.disconnect(_on_child_transition)

## Get the current state name (for debugging)
func get_current_state_name() -> String:
	return current_state.name if current_state else ""
