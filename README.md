# Swipe Card System for Godot 4.x

A drop-in Tinder-style swipe card for your Godot project. Handles all the annoying physics stuff so you don't have to.

## What it does

Swipe detection in 4 directions, spring physics for that satisfying snap-back, haptic feedback for mobile, and a bunch of tweakable settings. Works as a self-contained addon - no autoloads needed.

## Setup

1. Drop the `addons/swipe_card_system` folder into your project
2. Enable the plugin if you want (Project Settings > Plugins)
3. Instance `SwipeCard.tscn` wherever you need it

## Basic usage

```gdscript
@onready var card: SwipeCard = $SwipeCard

func _ready():
    card.swiped.connect(_on_swiped)
    card.swiping.connect(_on_swiping)

func _on_swiped(direction: String):
    # direction is "up", "down", "left", or "right"
    print("Swiped: ", direction)

func _on_swiping(direction: String, progress: float):
    # progress goes from 0.0 to 1.0 as they drag
    print("Swiping ", direction, " at ", progress * 100, "%")
```

## Signals

- `swipe_started` - drag began
- `swiping(direction, progress)` - fires while dragging
- `hold_threshold_reached(direction)` - held past the threshold
- `swiped(direction)` - swipe completed
- `swipe_canceled` - let go before threshold
- `returned_to_center` - card snapped back
- `card_off_screen` - card flew away

## Settings (in the Inspector)

**Swipe behavior**
- `swipe_threshold` - pixels needed to trigger (default 120)
- `allow_down_swipe` - toggle downward swipes
- `fly_off_on_swipe` - fly away vs snap back

**Rotation/grab**
- `grab_threshold` - where "bottom half" starts (0-1)
- `max_rotation` - max tilt in degrees
- `rotation_sensitivity` - how much drag affects tilt

**Drag feel**
- `horizontal_follow_strength` / `vertical_follow_strength` - how closely it follows your finger (0-1)
- `drag_resistance` - makes it feel heavier

**Stretch**
- `enable_stretch` - squash and stretch effect
- `stretch_amount` - intensity (0.1 = 10%)

**Spring presets** (`spring_type` 0-17)

There's a bunch of these: SOFT, NORMAL, STIFF, BOUNCY, SNAPPY, JELLY, RUBBER_BAND, etc. Just try them out and see what feels right for your game.

**Other**
- `enable_haptics` - vibration on mobile
- `juicy_mode` - toggle between polished feel and basic prototype mode

## Card structure

Add your content to the `CardContent` node:

```
SwipeCard
├── Button
├── CardContent  ← your stuff goes here
│   └── (images, labels, whatever)
└── StateMachine
```

## Methods

```gdscript
card.reset_position()
card.set_rest_position(Vector2(100, 200))
card.get_current_state()  # returns "Idle", "Held", "Returning", or "Swiped"
```

## Demo

Check out `addons/swipe_card_system/examples/demo/demo.tscn` to see it working.

## License

MIT - do whatever you want with it.

