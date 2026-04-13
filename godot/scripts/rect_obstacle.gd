extends Area2D
class_name RectObstacle

@export var size: Vector2 = Vector2(30, 80)

func _ready() -> void:
	add_to_group("rect_obstacle")
	add_to_group("obstacle")
	body_entered.connect(_on_body_entered)
	_create_shape()
	_create_sprite()

func _create_shape() -> void:
	# 防御：确保 shape 在 _physics_frame 前就创建好
	var shape = RectangleShape2D.new()
	shape.size = size
	$CollisionShape2D.shape = shape

func _create_sprite() -> void:
	var img = Image.create(maxi(1, int(size.x)), maxi(1, int(size.y)), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.55, 0.55, 0.55, 1.0))
	# 加边框线
	for i in range(int(size.x)):
		img.set_pixel(i, 0, Color(0.3, 0.3, 0.3, 1))
		img.set_pixel(i, int(size.y)-1, Color(0.3, 0.3, 0.3, 1))
	for j in range(int(size.y)):
		img.set_pixel(0, j, Color(0.3, 0.3, 0.3, 1))
		img.set_pixel(int(size.x)-1, j, Color(0.3, 0.3, 0.3, 1))
	$Sprite2D.texture = ImageTexture.create_from_image(img)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		var push_dir = (body.position - position).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2.RIGHT
		body.velocity += push_dir * 180
