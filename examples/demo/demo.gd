# Demo script showing how to use the SwipeCard component
# Displays swipe direction and progress in real-time

extends Control

@onready var swipe_card: SwipeCard = $CenterContainer/SwipeCard
@onready var direction_label: Label = $DirectionLabel
@onready var progress_label: Label = $ProgressLabel

func _ready() -> void:
	# Connect to SwipeCard signals
	swipe_card.swipe_started.connect(_on_swipe_started)
	swipe_card.swiping.connect(_on_swiping)
	swipe_card.hold_threshold_reached.connect(_on_hold_threshold_reached)
	swipe_card.swiped.connect(_on_swiped)
	swipe_card.swipe_canceled.connect(_on_swipe_canceled)
	swipe_card.returned_to_center.connect(_on_returned_to_center)
	swipe_card.card_off_screen.connect(_on_card_off_screen)

func _on_swipe_started() -> void:
	print("Swipe started")
	direction_label.text = "Direction: Dragging..."

func _on_swiping(direction: String, progress: float) -> void:
	direction_label.text = "Direction: " + direction.capitalize()
	progress_label.text = "Progress: " + str(int(progress * 100)) + "%"

func _on_hold_threshold_reached(direction: String) -> void:
	print("Hold threshold reached: ", direction)
	direction_label.text = "Direction: " + direction.capitalize() + " (READY)"
	progress_label.text = "Progress: 100%+"

func _on_swiped(direction: String) -> void:
	print("SWIPED: ", direction)
	direction_label.text = "SWIPED: " + direction.capitalize()

func _on_swipe_canceled() -> void:
	print("Swipe canceled")
	direction_label.text = "Direction: Canceled"
	progress_label.text = "Progress: 0%"

func _on_returned_to_center() -> void:
	print("Returned to center")
	direction_label.text = "Direction: None"
	progress_label.text = "Progress: 0%"

func _on_card_off_screen() -> void:
	print("Card flew off screen")
	# Respawn the card after a delay
	await get_tree().create_timer(0.5).timeout
	swipe_card.reset_position()
	direction_label.text = "Direction: None"
	progress_label.text = "Progress: 0%"
