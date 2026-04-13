extends CharacterBody2D
class_name Fish

# === 物理参数 ===
@export var max_scale: float = 1.8
@export var inflate_rate: float = 0.8
@export var deflate_rate: float = 1.4
@export var launch_vel: float = 900.0
@export var friction: float = 0.992
@export var rot_speed: float = 6.0
@export var invinc_time: float = 0.5
@export var max_hp: int = 100
@export var damage_base: float = 10.0
@export var damage_scale_factor: float = 40.0
@export var wave_amp_launch: float = 25.0
@export var bounce_coef: float = 0.55   # 边界反弹系数

# === 状态 ===
var state: String = "idle"
var fish_scale: float = 1.0
var rotation_angle: float = -PI / 2
var inflate: float = 0.0
var hp: int = 100
var invinc_timer: float = 0.0
var launch_scale: float = 1.0
var launch_time: float = 0.0
var wave_amp: float = 0.0
var wave_offset: float = 0.0
var _was_charging: bool = false

# === 引用 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

# 椭圆尺寸基准
const BASE_HALF_W: int = 28   # 身体最宽处
const BASE_HALF_H: int = 16   # 身体最窄处
const HEAD_FRAC: float = 0.38  # 头占身体的比例

func _ready() -> void:
	add_to_group("fish")
	add_to_group("game")
	_add_body_entered_handler()
	_create_fish_texture()
	_create_collision_shape()

func _add_body_entered_handler() -> void:
	# rect_obstacle 是 Area2D，fish 进入时触发 body_entered
	var area_check = Area2D.new()
	area_check.name = "RectHitArea"
	area_check.collision_layer = 0
	area_check.collision_mask = 2  # 检测 rect_obstacle (layer 2)
	area_check.body_entered.connect(_on_rect_hit_body_entered)
	add_child(area_check)

func _on_rect_hit_body_entered(body: Node2D) -> void:
	if body.is_in_group("rect_obstacle"):
		var push_dir = (position - body.position).normalized()
		if push_dir.length() < 0.1:
			push_dir = Vector2.RIGHT
		velocity += push_dir * 180

func _create_fish_texture() -> void:
	# 鱼身：椭圆 + 眼睛 + 尾鳍
	var img_w = BASE_HALF_W * 2 + 20  # 76px
	var img_h = BASE_HALF_H * 2        # 32px
	var img = Image.create(img_w, img_h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # 透明底

	# 身体（椭圆，往右偏一点让出尾鳍空间）
	_draw_ellipse(img, 38, 16, 26, 14, Color(0.2, 0.8, 1.0, 1.0))
	# 头（圆形，偏右，棕色）
	_draw_circle(img, 58, 16, 10, Color(0.6, 0.35, 0.2, 1.0))
	# 眼睛（小白点）
	_draw_circle(img, 62, 13, 3, Color(1, 1, 1, 1))
	# 尾鳍（三角形，左侧）
	_draw_triangle(img, 8, 16, 22, 4, 22, 28, Color(0.15, 0.65, 0.9, 1.0))

	sprite.texture = ImageTexture.create_from_image(img)

func _draw_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, col: Color) -> void:
	for x in range(cx - rx - 1, cx + rx + 1):
		for y in range(cy - ry - 1, cy + ry + 1):
			var dx = float(x - cx) / float(rx) if rx > 0 else 0.0
			var dy = float(y - cy) / float(ry) if ry > 0 else 0.0
			if dx*dx + dy*dy <= 1.0:
				img.set_pixel(x, y, col)

func _draw_circle(img: Image, cx: int, cy: int, r: int, col: Color) -> void:
	for x in range(cx - r - 1, cx + r + 1):
		for y in range(cy - r - 1, cy + r + 1):
			var dist = sqrt(float((x-cx)*(x-cx) + (y-cy)*(y-cy)))
			if dist <= r:
				img.set_pixel(x, y, col)

func _draw_triangle(img: Image, x1:int, y1:int, x2:int, y2:int, x3:int, y3:int, col: Color) -> void:
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

func _create_collision_shape() -> void:
	var shape = EllipseShape2D.new()
	shape.radius = Vector2(BASE_HALF_W, BASE_HALF_H)
	collision.shape = shape

func _physics_process(delta: float) -> void:
	_process_invincible(delta)
	_sync_circle_obstacle_shapes()  # 实时同步圆形碰撞

	var just_released = _was_charging and not Input.is_action_pressed("ui_accept")
	_was_charging = Input.is_action_pressed("ui_accept")

	match state:
		"idle":
			if Input.is_action_pressed("ui_accept"):
				_start_charging()
			_apply_friction()

		"charging":
			fish_scale = min(fish_scale + inflate_rate * delta, max_scale)
			rotation_angle += rot_speed * delta
			_update_sprite_transform()
			
			if just_released and fish_scale > 1.16:
				_launch()
			elif not Input.is_action_pressed("ui_accept"):
				_start_deflating()

		"flying":
			_apply_friction()
			var prev_vel = velocity
			move_and_slide()

			# 检测墙壁反弹（move_and_slide 反弹不够强）
			var bounds = _get_level_bounds()
			var r = _get_fish_radius()
			if position.x - r < bounds.left:
				position.x = bounds.left + r
				velocity.x = abs(prev_vel.x) * bounce_coef
			if position.x + r > bounds.right:
				position.x = bounds.right - r
				velocity.x = -abs(prev_vel.x) * bounce_coef
			if position.y - r < bounds.top:
				position.y = bounds.top + r
				velocity.y = abs(prev_vel.y) * bounce_coef
			if position.y + r > bounds.bottom:
				position.y = bounds.bottom - r
				velocity.y = -abs(prev_vel.y) * bounce_coef

			var speed = velocity.length()
			if speed > 10:
				var target_rot = velocity.angle()
				var diff = target_rot - rotation_angle
				while diff > PI: diff -= TAU
				while diff < -PI: diff += TAU
				rotation_angle += diff * 5 * delta
				_update_sprite_transform()

			if wave_amp > 0:
				wave_offset += delta * 30
				var wave = sin(wave_offset) * wave_amp
				var dir = velocity.normalized()
				if dir.length() > 0.1:
					var perp = Vector2(-dir.y, dir.x)
					position += perp * wave * delta
				wave_amp *= 0.97
				if wave_amp < 0.5: wave_amp = 0

			if launch_scale > 1.01 and launch_time < 2.0:
				launch_time += delta
				var progress = min(launch_time / 2.0, 1.0)
				if not Input.is_action_pressed("ui_accept"):
					fish_scale = launch_scale * (1 - progress) + 1.0 * progress
					_update_sprite_transform()
				else:
					launch_scale = 1.0
					launch_time = 2.0

			if Input.is_action_pressed("ui_accept"):
				_start_charging()

			if speed < 5:
				velocity = Vector2.ZERO
				state = "idle"

func _get_level_bounds() -> Dictionary:
	# 从 level_loader 读取边界（由 level_loader 设置）
	return {
		"left": 20.0, "right": 4076.0,
		"top": 20.0, "bottom": 2028.0
	}

func _get_fish_radius() -> float:
	var base_r = mini(BASE_HALF_W, BASE_HALF_H)
	return base_r * fish_scale

func _sync_circle_obstacle_shapes() -> void:
	# 调用障碍物的同步方法，同时更新碰撞+精灵
	var obstacles = get_tree().get_nodes_in_group("circle_obstacle")
	for obs in obstacles:
		obs.sync_to_fish(fish_scale)

func _update_sprite_transform() -> void:
	sprite.rotation = rotation_angle
	var sf = 1.0 + (fish_scale - 1.0) * 0.6
	sprite.scale = Vector2(sf, fish_scale)
	collision.scale = Vector2(fish_scale, fish_scale)

func _start_charging() -> void:
	if state != "charging":
		state = "charging"
		launch_scale = fish_scale
		launch_time = 0.0

func _start_deflating() -> void:
	state = "flying"
	fish_scale = max(fish_scale - deflate_rate * get_physics_process_delta_time(), 1.0)
	_update_sprite_transform()

func _launch() -> void:
	var power = (fish_scale - 1.0) / (max_scale - 1.0)
	if power < 0.1: power = 0.1
	var dir = rotation_angle + PI
	velocity = Vector2(cos(dir), sin(dir)) * launch_vel * power
	launch_scale = fish_scale
	launch_time = 0.0
	fish_scale = 1.0
	inflate = 0.0
	wave_amp = power * wave_amp_launch
	state = "flying"
	_update_sprite_transform()

func _apply_friction() -> void:
	velocity *= friction
	if velocity.length() < 5:
		velocity = Vector2.ZERO

func _process_invincible(delta: float) -> void:
	if invinc_timer > 0:
		invinc_timer -= delta
		var vis = int(invinc_timer * 10) % 2 == 0
		sprite.modulate = Color(1, 1, 1, 1.0 if vis else 0.5)
	else:
		sprite.modulate = Color.WHITE

func take_damage(amount: float) -> void:
	if is_invincible():
		return
	hp -= int(amount)
	invinc_timer = invinc_time
	if hp <= 0:
		hp = 0
		_on_dead()

func is_invincible() -> bool:
	return fish_scale >= max_scale * 0.95 or invinc_timer > 0

func _on_dead() -> void:
	state = "idle"
	velocity = Vector2.ZERO
	get_tree().call_group("game", "on_game_over")
