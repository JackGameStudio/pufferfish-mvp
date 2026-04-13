extends Node2D
class_name LevelLoader

# 关卡数据（原版 index.html 移植）
# 坐标单位：Godot 像素（已乘32）

const LEVEL_WIDTH: int = 4096
const LEVEL_HEIGHT: int = 2048
const WALL_THICKNESS: int = 20

# 圆形障碍 (x_px, y_px, radius_units)
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

# 矩形障碍 (x_px, y_px, w_units, h_units)
var rect_data: Array = [
	[150, 400, 0.94, 2.5], [350, 350, 3.13, 0.63], [350, 420, 2.5, 0.63],
	[550, 200, 0.63, 3.13], [550, 450, 0.63, 3.13],
	[700, 300, 3.75, 0.63], [950, 280, 0.63, 2.5], [950, 420, 0.63, 2.5],
	[1100, 200, 2.5, 0.47], [1100, 350, 2.5, 0.47], [1100, 500, 2.5, 0.47],
	[1250, 150, 0.63, 1.88], [1250, 350, 0.63, 2.5], [1250, 500, 0.63, 1.88],
	[1850, 280, 4.69, 0.63], [1850, 400, 4.69, 0.63],
]

# 起点终点（像素）
var start_pos: Vector2 = Vector2(80, 450)
var end_pos: Vector2 = Vector2(2050, 350)
var end_radius: float = 40.0

var circle_scene: PackedScene
var rect_scene: PackedScene

func _ready() -> void:
	circle_scene = preload("res://scenes/obstacles/circle_obstacle.tscn")
	rect_scene = preload("res://scenes/obstacles/rect_obstacle.tscn")
	
	_spawn_fish()
	_spawn_world_bounds()
	_spawn_circle_obstacles()
	_spawn_rect_obstacles()
	_spawn_start_end()
	_setup_camera()

func _spawn_fish() -> void:
	var fish_scene = preload("res://scenes/player/fish.tscn")
	var fish = fish_scene.instantiate()
	fish.position = start_pos
	add_child(fish)

func _spawn_world_bounds() -> void:
	var bounds = StaticBody2D.new()
	bounds.name = "WorldBounds"
	bounds.collision_layer = 4
	bounds.collision_mask = 0
	add_child(bounds)
	
	# 四面墙
	_add_wall(bounds, "Left", Vector2(-WALL_THICKNESS/2, LEVEL_HEIGHT/2), Vector2(WALL_THICKNESS, LEVEL_HEIGHT + WALL_THICKNESS*2))
	_add_wall(bounds, "Right", Vector2(LEVEL_WIDTH + WALL_THICKNESS/2, LEVEL_HEIGHT/2), Vector2(WALL_THICKNESS, LEVEL_HEIGHT + WALL_THICKNESS*2))
	_add_wall(bounds, "Top", Vector2(LEVEL_WIDTH/2, -WALL_THICKNESS/2), Vector2(LEVEL_WIDTH + WALL_THICKNESS*2, WALL_THICKNESS))
	_add_wall(bounds, "Bottom", Vector2(LEVEL_WIDTH/2, LEVEL_HEIGHT + WALL_THICKNESS/2), Vector2(LEVEL_WIDTH + WALL_THICKNESS*2, WALL_THICKNESS))

func _add_wall(parent: StaticBody2D, name: String, pos: Vector2, size: Vector2) -> void:
	var wall = CollisionShape2D.new()
	wall.name = name
	wall.position = pos
	var shape = RectangleShape2D.new()
	shape.size = size
	wall.shape = shape
	parent.add_child(wall)

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
	# 起点标记
	var start_sprite = Sprite2D.new()
	start_sprite.name = "Start"
	start_sprite.position = start_pos
	var start_img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	start_img.fill(Color(0.2, 0.8, 0.2, 0.5))
	start_sprite.texture = ImageTexture.create_from_image(start_img)
	add_child(start_sprite)
	
	# 终点区域
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
	
	# 终点视觉
	var end_sprite = Sprite2D.new()
	end_zone.add_child(end_sprite)
	var end_img = Image.create(80, 80, false, Image.FORMAT_RGBA8)
	end_img.fill(Color(1, 0.8, 0, 0.5))
	for x in range(80):
		for y in range(80):
			var dist = Vector2(x-40, y-40).length()
			if dist > 38:
				end_img.set_pixel(x, y, Color(0,0,0,0))
	end_sprite.texture = ImageTexture.create_from_image(end_img)
	
	end_zone.body_entered.connect(_on_end_zone_body_entered)

func _setup_camera() -> void:
	var camera = get_node_or_null("../Camera2D") as Camera2D
	if camera:
		var fish = get_tree().get_first_node_in_group("fish")
		if fish:
			camera.position = fish.position

func _on_end_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("fish"):
		get_tree().call_group("game", "on_win")
