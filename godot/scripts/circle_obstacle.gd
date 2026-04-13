extends Area2D
class_name CircleObstacle

@export var radius: float = 1.4  # 约45px = 1.4 units at 32 PPU
@export var damage: float = 10.0
@export var damage_scale_factor: float = 40.0

func _ready() -> void:
	add_to_group("circle_obstacle")
	add_to_group("obstacle")
	var shape = CircleShape2D.new()
	shape.radius = radius
	$CollisionShape2D.shape = shape
	body_entered.connect(_on_body_entered)

	# 白盒：用圆形绘制
	var img = Image.create(int(radius*2*32), int(radius*2*32), false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 0.3, 0.3, 1))  # 红色
	for x in range(img.get_width()):
		for y in range(img.get_height()):
			var dist = Vector2(x-img.get_width()/2.0, y-img.get_height()/2.0).length()
			if dist > radius * 32:
				img.set_pixel(x, y, Color(0,0,0,0))
	var tex = ImageTexture.create_from_image(img)
	$Sprite2D.texture = tex

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		var fish = body as Fish
		if fish == null:
			return
		var dmg = damage + (fish.fish_scale - 1.0) * damage_scale_factor
		fish.take_damage(dmg)
