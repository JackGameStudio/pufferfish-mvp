extends Node2D
class_name LevelLoader

# 关卡数据（原版 index.html 直接移植）
# 坐标已转换为 Godot 单位（除以 32）

const LEVEL_WIDTH: float = 128.0   # 4096 / 32
const LEVEL_HEIGHT: float = 64.0   # 2048 / 32

# 圆形障碍数据 (x, y, radius) - 单位
var circle_obstacles: Array[Vector3] = [
	# 原版第一组
	Vector3(6.25, 7.81, 1.4), Vector3(8.75, 7.19, 1.56),
	Vector3(11.25, 6.88, 1.5), Vector3(13.75, 7.19, 1.63),
	Vector3(16.25, 8.13, 1.56), Vector3(18.13, 9.69, 1.5),
	# 第二组
	Vector3(19.38, 11.88, 1.4), Vector3(21.25, 13.44, 1.56),
	Vector3(23.13, 14.38, 1.63), Vector3(25.0, 14.69, 1.5),
	Vector3(26.88, 14.38, 1.4), Vector3(28.75, 13.13, 1.56),
	Vector3(30.63, 11.56, 1.5), Vector3(32.5, 9.69, 1.63),
	# 第三组
	Vector3(33.75, 8.44, 1.4), Vector3(35.63, 7.81, 1.5),
	Vector3(37.5, 7.66, 1.56), Vector3(7.81, 15.63, 1.56),
	Vector3(10.31, 16.25, 1.5), Vector3(12.81, 16.88, 1.63),
	Vector3(15.31, 17.19, 1.4), Vector3(17.81, 16.88, 1.56),
	Vector3(20.31, 16.25, 1.5), Vector3(22.81, 15.31, 1.63),
	Vector3(25.31, 14.69, 1.4), Vector3(27.81, 15.94, 1.56),
	Vector3(30.31, 16.56, 1.5),
]

# 矩形障碍数据 (x, y, width, height) - 单位
var rect_obstacles: Array[Vector4] = [
	# 原版坐标换算
	Vector4(4.69, 12.5, 0.94, 2.5),   # 150,400,30,80
	Vector4(10.94, 10.94, 3.13, 0.63), # 350,350,100,20
	Vector4(10.94, 13.13, 2.5, 0.63),  # 350,420,80,20
	Vector4(17.19, 6.25, 0.63, 3.13),  # 550,200,20,100
	Vector4(17.19, 14.06, 0.63, 3.13), # 550,450,20,100
	Vector4(21.88, 9.38, 3.75, 0.63),  # 700,300,120,20
	Vector4(29.69, 8.75, 0.63, 2.5),   # 950,280,20,80
	Vector4(29.69, 13.13, 0.63, 2.5),   # 950,420,20,80
	Vector4(34.38, 6.25, 2.5, 0.47),   # 1100,200,80,15
	Vector4(34.38, 10.94, 2.5, 0.47),  # 1100,350,80,15
	Vector4(34.38, 15.63, 2.5, 0.47),  # 1100,500,80,15
	Vector4(39.06, 4.69, 0.63, 1.88),  # 1250,150,20,60
	Vector4(39.06, 10.94, 0.63, 2.5),   # 1250,350,20,80
	Vector4(39.06, 15.63, 0.63, 1.88),  # 1250,500,20,60
	Vector4(57.81, 8.75, 4.69, 0.63),   # 1850,280,150,20
	Vector4(57.81, 12.5, 4.69, 0.63),    # 1850,400,150,20
]

# 起点和终点
var start_pos: Vector2 = Vector2(2.5, 14.06)   # 原版 (80, 450)
var end_pos: Vector2 = Vector2(64.06, 10.94)   # 原版 (2050, 350)
var end_radius: float = 1.25  # 原版 40px

var circle_scene: PackedScene
var rect_scene: PackedScene

func _ready() -> void:
	circle_scene = preload("res://scenes/obstacles/circle_obstacle.tscn")
	rect_scene = preload("res://scenes/obstacles/rect_obstacle.tscn")
	
	_spawn_circle_obstacles()
	_spawn_rect_obstacles()
	_spawn_start_end()

func _spawn_circle_obstacles() -> void:
	for data in circle_obstacles:
		var obstacle = circle_scene.instantiate()
		obstacle.position = Vector2(data.x, data.y)
		obstacle.radius = data.z
		add_child(obstacle)

func _spawn_rect_obstacles() -> void:
	for data in rect_obstacles:
		var obstacle = rect_scene.instantiate()
		obstacle.position = Vector2(data.x, data.y)
		obstacle.size = Vector2(data.z, data.w)
		add_child(obstacle)

func _spawn_start_end() -> void:
	# 起点标记（绿色方块）
	var start_marker = Node2D.new()
	start_marker.name = "Start"
	start_marker.position = start_pos * 32  # 转换回像素
	add_child(start_marker)
	
	var start_sprite = Sprite2D.new()
	start_marker.add_child(start_sprite)
	var start_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	start_img.fill(Color(0.2, 0.8, 0.2, 0.5))
	start_sprite.texture = ImageTexture.create_from_image(start_img)
	
	# 终点区域
	var end_zone = Area2D.new()
	end_zone.name = "EndZone"
	end_zone.add_to_group("end_zone")
	end_zone.collision_layer = 0   # Area2D 不作为碰撞体
	end_zone.collision_mask = 1    # 只检测 layer 1（鱼）
	end_zone.position = end_pos * 32
	add_child(end_zone)
	
	var end_shape = CollisionShape2D.new()
	end_shape.shape = CircleShape2D.new()
	end_shape.shape.radius = end_radius * 32
	end_zone.add_child(end_shape)
	
	# 终点视觉
	var end_sprite = Sprite2D.new()
	end_zone.add_child(end_sprite)
	var end_img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	end_img.fill(Color(1, 0.8, 0, 0.5))  # 金色
	for x in range(64):
		for y in range(64):
			var dist = Vector2(x-32, y-32).length()
			if dist > 30:
				end_img.set_pixel(x, y, Color(0,0,0,0))
	end_sprite.texture = ImageTexture.create_from_image(end_img)
	
	# 连接信号
	end_zone.body_entered.connect(_on_end_zone_body_entered)

func _on_end_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		get_tree().call_group("game", "on_win")
