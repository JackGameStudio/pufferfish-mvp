extends Area2D
class_name CircleObstacle

@export var radius: float = 1.4    # 单位：Godot单位（已 *32 = 像素）
@export var damage: float = 10.0
@export var damage_scale_factor: float = 40.0

var base_radius_px: float  # 基准像素半径
var base_sprite_size: int # 基准精灵尺寸

func _ready() -> void:
	add_to_group("circle_obstacle")
	add_to_group("obstacle")
	body_entered.connect(_on_body_entered)
	
	base_radius_px = radius * 32.0
	base_sprite_size = int(base_radius_px * 2.0)
	
	# 创建初始碰撞形状
	var shape = CircleShape2D.new()
	shape.radius = base_radius_px
	$CollisionShape2D.shape = shape
	
	# 创建初始精灵
	_create_sprite(base_sprite_size)

func _create_sprite(size: int) -> void:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.3, 0.3, 1))
	for x in range(size):
		for y in range(size):
			var dist = Vector2(x - size/2.0, y - size/2.0).length()
			if dist > base_radius_px:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	$Sprite2D.texture = ImageTexture.create_from_image(img)

# 由 fish.gd 每帧调用，传入鱼的当前 scale
func sync_to_fish(fish_scale: float) -> void:
	var new_r = base_radius_px * fish_scale
	# 更新碰撞形状
	if $CollisionShape2D.shape:
		$CollisionShape2D.shape.radius = new_r
	# 更新精灵
	var new_size = maxi(2, int(base_sprite_size * fish_scale))
	_create_sprite(new_size)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		var fish = body as Fish
		if fish == null:
			return
		var push_dir = (fish.position - position).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2.RIGHT
		fish.velocity += push_dir * 200
		var dmg = damage + (fish.fish_scale - 1.0) * damage_scale_factor
		fish.take_damage(dmg)
