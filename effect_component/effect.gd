extends Resource
class_name Effect

## The name of the effect.
@export var name : StringName
## Determines how this effect will behave when applied to an entity already being affected by the same effect.
## Duration: Adds this effect’s duration to the current.
## Stack: Applies this effect as a separate effect.
## Override: Replaces the current effect with the new effect.
@export_enum("Duration", "Stack", "Override") var stacking_mode : String = "Override"
## What happens when this effect is applied to an entity, but there is not enough slots to apply the effect.
## Replace: Makes this effect replace the oldest current effect.
## Discard: Stops this effect from being applied.
@export_enum("Replace", "Discard") var overflow_mode : String = "Discard"

## The duration of this effect.
var effect_duration : float
## The timer linked to this effect.
var timer : Timer
