# Idle state - card rests at its target position
# Smoothly lerps to position if not already there

extends SwipeState
class_name SwipeIdleState

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	if not swipe_card:
		return
	# Smoothly lerp to target position
	var target_pos = swipe_card.get_rest_position()
	swipe_card.position = swipe_card.position.lerp(target_pos, 0.5)
