extends Camera2D

@export var lerp_speed: float = 0.08

var shake_timer: float = 0.0
var shake_amount: float = 5.0

func _ready() -> void:
	# 初始对齐到鱼位置
	var fish = get_tree().get_first_node_in_group("fish")
	if fish:
		position = fish.position

func _physics_process(delta: float) -> void:
	var fish = get_tree().get_first_node_in_group("fish")
	if fish:
		position = position.lerp(fish.position, lerp_speed)
	
	if shake_timer > 0:
		shake_timer -= delta
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
	else:
		offset = Vector2.ZERO

func shake(duration: float = 0.2, amount: float = 5.0) -> void:
	shake_timer = duration
	shake_amount = amount
