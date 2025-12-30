# Base state class for the swipe card state machine
# Extend this class to create custom states

extends Node
class_name SwipeState

## Emitted when this state wants to transition to another state
signal Transitioned(state: SwipeState, new_state_name: String)

## Reference to the main SwipeCard node (set by state machine)
var swipe_card: Control

## Called when entering this state
func enter() -> void:
	pass

## Called when exiting this state
func exit() -> void:
	pass

## Called every frame while in this state
func update(_delta: float) -> void:
	pass

## Called every physics frame while in this state
func physics_update(_delta: float) -> void:
	pass
