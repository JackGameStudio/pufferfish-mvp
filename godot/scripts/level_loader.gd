extends Node2D
class_name LevelLoader

# 关卡数据（像素坐标）
const LEVEL_WIDTH: int = 4096
const LEVEL_HEIGHT: int = 2048
const WALL_T: int = 20  # 墙厚

var circle_data: Array = [
	[200, 250, 1.4], [280, 230, 1.56], [360, 220, 1.5], [440, 230, 1.63],
	[520, 260, 1.56], [580, 310, 1.5],
	[620, 380, 1.4], [680, 430, 1.56], [740, 460, 1.63], [800, 470, 1.5],
	[860, 460, 1.4], [920, 420, 1.56], [980, 370, 1.5], [1040, 310, 1.63],
	[1080, 270, 1.4], [1140, 250, 1.5], [1200, 245, 1.56],
	[250, 500, 1.56], [330, 520, 1.5], [410, 540, 1.63], [490, 550, 1.4],
	[570, 540, 1.56], [650, 520, 1.5], [730, 490, 1.63],
	[810, 470, 1.4], [890, 510, 1.56], [970, 530, 1.5],
]

var rect_data: Array = [
	[150, 400, 30, 80], [350, 350, 100, 20], [350, 420, 80, 20],
	[550, 200, 20, 100], [550, 450, 20, 100],
	[700, 300, 120, 20], [950, 280, 20, 80], [950, 420, 20, 80],
	[1100, 200, 80, 15], [1100, 350, 80, 15], [1100, 500, 80, 15],
	[1250, 150, 20, 60], [1250, 350, 20, 80], [1250, 500, 20, 60],
	[1850, 280, 150, 20], [1850, 400, 150, 20],
]

var start_pos: Vector2 = Vector2(80, 450)
var end_pos: Vector2 = Vector2(2050, 350)
var end_radius: float = 40.0

var circle_scene: PackedScene
var rect_scene: PackedScene

func _ready() -> void:
	circle_scene = preload("res://scenes/obstacles/circle_obstacle.tscn")
	rect_scene = preload("res://scenes/obstacles/rect_obstacle.tscn")
	_spawn_fish()
	_spawn_walls()
	_spawn_circle_obstacles()
	_spawn_rect_obstacles()
	_spawn_start_end()
	_setup_camera()

func _spawn_fish() -> void:
	var fish_scene = preload("res://scenes/player/fish.tscn")
	var fish = fish_scene.instantiate()
	fish.position = start_pos
	add_child(fish)

func _spawn_walls() -> void:
	# 左墙（蓝）
	_add_wall("LeftWall", Rect2(0, 0, WALL_T, LEVEL_HEIGHT), Color(0.2, 0.4, 1.0, 0.8))
	# 右墙（蓝）
	_add_wall("RightWall", Rect2(LEVEL_WIDTH - WALL_T, 0, WALL_T, LEVEL_HEIGHT), Color(0.2, 0.4, 1.0, 0.8))
	# 上墙（红）
	_add_wall("TopWall", Rect2(0, 0, LEVEL_WIDTH, WALL_T), Color(1.0, 0.2, 0.2, 0.8))
	# 下墙（红）
	_add_wall("BottomWall", Rect2(0, LEVEL_HEIGHT - WALL_T, LEVEL_WIDTH, WALL_T), Color(1.0, 0.2, 0.2, 0.8))
	# 内部边框线（半透明灰）
	_add_border_line()

func _add_wall(name: String, rect: Rect2, col: Color) -> void:
	var tex = _solid_texture(int(rect.size.x), int(rect.size.y), col)
	var spr = Sprite2D.new()
	spr.name = name
	spr.texture = tex
	spr.position = Vector2(rect.position.x + rect.size.x / 2.0, rect.position.y + rect.size.y / 2.0)
	add_child(spr)

func _add_border_line() -> void:
	# 虚线边框（黄色虚线提示边界）
	var line_color = Color(1.0, 0.85, 0.0, 0.6)
	# 上边
	var top_line = Sprite2D.new()
	top_line.name = "BorderTop"
	var top_tex = _hatch_texture(LEVEL_WIDTH, 4, line_color)
	top_line.texture = top_tex
	top_line.position = Vector2(LEVEL_WIDTH / 2.0, WALL_T + 4)
	add_child(top_line)
	# 下边
	var bot_line = Sprite2D.new()
	bot_line.name = "BorderBottom"
	var bot_tex = _hatch_texture(LEVEL_WIDTH, 4, line_color)
	bot_line.texture = bot_tex
	bot_line.position = Vector2(LEVEL_WIDTH / 2.0, LEVEL_HEIGHT - WALL_T - 4)
	add_child(bot_line)
	# 左
	var left_line = Sprite2D.new()
	left_line.name = "BorderLeft"
	var left_tex = _hatch_texture(4, LEVEL_HEIGHT, line_color)
	left_line.texture = left_tex
	left_line.position = Vector2(WALL_T + 4, LEVEL_HEIGHT / 2.0)
	add_child(left_line)
	# 右
	var right_line = Sprite2D.new()
	right_line.name = "BorderRight"
	var right_tex = _hatch_texture(4, LEVEL_HEIGHT, line_color)
	right_line.texture = right_tex
	right_line.position = Vector2(LEVEL_WIDTH - WALL_T - 4, LEVEL_HEIGHT / 2.0)
	add_child(right_line)

func _solid_texture(w: int, h: int, col: Color) -> ImageTexture:
	var img = Image.create(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)

func _hatch_texture(w: int, h: int, col: Color) -> ImageTexture:
	var img = Image.create(maxi(1, w), maxi(1, h), false, Image.FORMAT_RGBA8)
	img.fill(Color(col.r, col.g, col.b, 0))
	for i in range(0, maxi(w, h), 8):
		for j in range(0, max(w, h)):
			if i < w and j < h:
				img.set_pixel(i, j, col)
	return ImageTexture.create_from_image(img)

func _spawn_circle_obstacles() -> void:
	for data in circle_data:
		var obstacle = circle_scene.instantiate()
		obstacle.position = Vector2(data[0], data[1])
		obstacle.radius = data[2]
		add_child(obstacle)

func _spawn_rect_obstacles() -> void:
	for data in rect_data:
		var obstacle = rect_scene.instantiate()
		obstacle.position = Vector2(data[0], data[1])
		obstacle.size = Vector2(data[2], data[3])
		add_child(obstacle)

func _spawn_start_end() -> void:
	# 起点（绿色三角）
	var start_spr = Sprite2D.new()
	start_spr.name = "StartMarker"
	start_spr.position = start_pos
	var start_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	start_img.fill(Color(0, 0, 0, 0))
	# 画三角形
	_draw_triangle_fill(start_img, 16, 4, 4, 28, 28, 28, Color(0.2, 1.0, 0.3, 1.0))
	start_spr.texture = ImageTexture.create_from_image(start_img)
	add_child(start_spr)

	# 终点（金色圆圈）
	var end_zone = Area2D.new()
	end_zone.name = "EndZone"
	end_zone.add_to_group("end_zone")
	end_zone.collision_layer = 0
	end_zone.collision_mask = 1
	end_zone.position = end_pos
	add_child(end_zone)

	var end_shape = CollisionShape2D.new()
	end_shape.shape = CircleShape2D.new()
	end_shape.shape.radius = end_radius
	end_zone.add_child(end_shape)

	var end_spr = Sprite2D.new()
	end_zone.add_child(end_spr)
	var end_img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	end_img.fill(Color(1, 0.8, 0, 0.3))
	for x in range(80):
		for y in range(80):
			var dist = Vector2(x-40, y-40).length()
			if dist > 38 or dist < 25:
				end_img.set_pixel(x, y, Color(0,0,0,0))
	end_spr.texture = ImageTexture.create_from_image(end_img)
	end_zone.body_entered.connect(_on_end_zone_body_entered)

func _draw_triangle_fill(img: Image, x1:int, y1:int, x2:int, y2:int, x3:int, y3:int, col: Color) -> void:
	var min_x = maxi(0, mini(x1, mini(x2, x3)))
	var max_x = mini(img.get_width()-1, maxi(x1, maxi(x2, x3)))
	var min_y = maxi(0, mini(y1, mini(y2, y3)))
	var max_y = mini(img.get_height()-1, maxi(y1, maxi(y2, y3)))
	for x in range(min_x, max_x+1):
		for y in range(min_y, max_y+1):
			var s = (x-x1)*(y2-y1)-(x2-x1)*(y-y1)
			var t = (x-x2)*(y3-y2)-(x3-x2)*(y-y2)
			if (x-x3)*(y1-y3)-(x1-x3)*(y-y3) >= 0 and s >= 0 and t >= 0:
				img.set_pixel(x, y, col)

func _setup_camera() -> void:
	var camera = get_node_or_null("../Camera2D") as Camera2D
	if camera:
		var fish = get_tree().get_first_node_in_group("fish")
		if fish:
			camera.position = fish.position

func _on_end_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		get_tree().call_group("game", "on_win")
