extends Area2D
class_name RectObstacle

@export var size: Vector2 = Vector2(1, 3)

func _ready() -> void:
	add_to_group("rect_obstacle")
	add_to_group("obstacle")
	var shape = RectangleShape2D.new()
	shape.size = size * 32  # 转像素
	$CollisionShape2D.shape = shape
	# 白盒灰色矩形
	var pixel_size = size * 32
	var img = Image.create(int(pixel_size.x), int(pixel_size.y), false, Image.FORMAT_RGBA8)
	img.fill(Color(0.5, 0.5, 0.5, 1))
	$Sprite2D.texture = ImageTexture.create_from_image(img)
