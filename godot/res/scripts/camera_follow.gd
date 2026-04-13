extends Camera2D

@export var target_path: NodePath
@export var lerp_speed: float = 0.08

var shake_timer: float = 0.0
var shake_amount: float = 5.0

func _ready() -> void:
	if target_path:
		var target = get_node(target_path)
		if target:
			position = target.position

func _physics_process(delta: float) -> void:
	if target_path:
		var target = get_node(target_path)
		if target:
			position = position.lerp(target.position, lerp_speed)
	
	if shake_timer > 0:
		shake_timer -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
	else:
		offset = Vector2.ZERO

func shake(duration: float = 0.2, amount: float = 5.0) -> void:
	shake_timer = duration
	shake_amount = amount
