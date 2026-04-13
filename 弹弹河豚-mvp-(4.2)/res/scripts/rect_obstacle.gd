extends Area2D
class_name RectObstacle

@export var size: Vector2 = Vector2(1, 3)  # 默认尺寸（单位）

func _ready() -> void:
    add_to_group("rect_obstacle")
    add_to_group("obstacle")
    var shape = RectangleShape2D.new()
    shape.size = size
    $CollisionShape2D.shape = shape
    
    # 白盒：用矩形绘制
    if not has_node("Sprite2D"):
        var sprite = Sprite2D.new()
        sprite.name = "Sprite2D"
        add_child(sprite)
    var pixel_size = size * 32  # 转换为像素
    var img = Image.create(int(pixel_size.x), int(pixel_size.y), false, Image.FORMAT_RGBA8)
    img.fill(Color(0.5, 0.5, 0.5, 1))  # 灰色
    var tex = ImageTexture.create_from_image(img)
    $Sprite2D.texture = tex
    $Sprite2D.position = -size / 2  # 居中
