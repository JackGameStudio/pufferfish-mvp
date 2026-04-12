extends CharacterBody2D
class_name Fish

# === 物理参数（对应原版 index.html） ===
@export var max_scale: float = 1.8       # 最大膨胀倍率
@export var inflate_rate: float = 0.8     # 膨胀速度（1秒满）
@export var deflate_rate: float = 1.4     # 收缩速度（0.5秒回）
@export var launch_vel: float = 900.0     # 弹射初速（px/s）
@export var friction: float = 0.992       # 摩擦（每帧乘）
@export var rot_speed: float = 6.0        # 旋转速度（rad/s）
@export var invinc_time: float = 0.5       # 无敌帧时长
@export var max_hp: int = 100
@export var damage_base: float = 10.0
@export var damage_scale_factor: float = 40.0
@export var wave_amp_launch: float = 25.0 # 弹射时波浪振幅

# === 状态 ===
var state: String = "idle"  # idle | charging | flying
var fish_scale: float = 1.0
var rotation_angle: float = -PI / 2  # 默认朝上
var inflate: float = 0.0  # 0~1 充气程度
var hp: int = max_hp
var invinc_timer: float = 0.0
var launch_scale: float = 1.0  # 弹射时的scale，用于渐进缩小
var launch_time: float = 0.0
var wave_amp: float = 0.0
var wave_offset: float = 0.0
var _was_charging: bool = false

# === 引用 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    add_to_group("fish")
    add_to_group("game")
    # 白盒：用 Godot 内置形状，先用默认图标
    if not sprite.texture:
        # 创建一个简单的圆形纹理作为白盒
        var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
        img.fill(Color(0.2, 0.8, 1.0, 1.0))  # 蓝色圆形
        for x in range(64):
            for y in range(64):
                var dist = Vector2(x-32, y-32).length()
                if dist > 30:
                    img.set_pixel(x, y, Color(0,0,0,0))
        var tex = ImageTexture.create_from_image(img)
        sprite.texture = tex

func _physics_process(delta: float) -> void:
    _process_invincible(delta)

    # 松手检测（charging → flying）
    var just_released = _was_charging and not Input.is_action_pressed("ui_accept")
    _was_charging = Input.is_action_pressed("ui_accept")

    match state:
        "idle":
            if Input.is_action_pressed("ui_accept"):
                _start_charging()
            _apply_friction()

        "charging":
            # 按住：膨胀 + 旋转
            fish_scale = min(fish_scale + inflate_rate * delta, max_scale)
            rotation_angle += rot_speed * delta
            _update_sprite_transform()
            
            if just_released and fish_scale > 1.16:  # 约20%充气才弹射
                _launch()
            elif not Input.is_action_pressed("ui_accept"):
                _start_deflating()

        "flying":
            # 飞行：摩擦减速
            _apply_friction()
            move_and_slide()

            # 速度朝向下：旋转对齐速度方向
            var speed = velocity.length()
            if speed > 10:
                var target_rot = velocity.angle()
                var diff = target_rot - rotation_angle
                while diff > PI: diff -= TAU
                while diff < -PI: diff += TAU
                rotation_angle += diff * 5 * delta
                _update_sprite_transform()

            # 波浪抖动
            if wave_amp > 0:
                wave_offset += delta * 30
                var wave = sin(wave_offset) * wave_amp
                var dir = velocity.normalized()
                if dir.length() > 0.1:
                    var perp = Vector2(-dir.y, dir.x)
                    position += perp * wave * delta
                wave_amp *= 0.97
                if wave_amp < 0.5: wave_amp = 0

            # 渐进缩小（2秒完成）
            if launch_scale > 1.01 and launch_time < 2.0:
                launch_time += delta
                var progress = min(launch_time / 2.0, 1.0)
                if not Input.is_action_pressed("ui_accept"):
                    fish_scale = launch_scale * (1 - progress) + 1.0 * progress
                    _update_sprite_transform()
                else:
                    launch_scale = 1.0
                    launch_time = 2.0

            # charging优先：飞行中按住也触发charging
            if Input.is_action_pressed("ui_accept"):
                _start_charging()

            # 停止判定
            if speed < 5:
                velocity = Vector2.ZERO
                state = "idle"

func _update_sprite_transform() -> void:
    sprite.rotation = rotation_angle
    # 膨胀时稍微增加厚度（scale Y）
    var scale_factor = 1.0 + (fish_scale - 1.0) * 0.6
    sprite.scale = Vector2(scale_factor, fish_scale)
    # 碰撞形状也要同步
    collision.scale = Vector2(fish_scale, fish_scale)

func _start_charging() -> void:
    if state != "charging":
        state = "charging"
        launch_scale = fish_scale
        launch_time = 0.0

func _start_deflating() -> void:
    state = "flying"
    fish_scale = max(fish_scale - deflate_rate * delta, 1.0)
    _update_sprite_transform()

func _launch() -> void:
    var power = (fish_scale - 1.0) / (max_scale - 1.0)  # 0~1
    if power < 0.1: power = 0.1
    
    var dir = rotation_angle + PI  # 弹弓：当前朝向的反方向
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
        # 闪烁效果
        var visible = int(invinc_timer * 10) % 2 == 0
        sprite.modulate = Color(1, 1, 1, 1 if visible else 0.5)
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
    # scale >= 95% 膨胀时无敌
    return fish_scale >= max_scale * 0.95 or invinc_timer > 0

func _on_dead() -> void:
    state = "idle"
    velocity = Vector2.ZERO
    get_tree().call_group("game", "on_game_over")

# === 碰撞处理 ===
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("circle_obstacle"):
        # 被圆形障碍推开+扣血
        var push_dir = (position - body.position).normalized()
        if push_dir.length() < 0.1:
            push_dir = Vector2.RIGHT
        velocity += push_dir * 200
        
        var dmg = damage_base + (fish_scale - 1.0) * damage_scale_factor
        take_damage(dmg)

func _on_area_entered(area: Area2D) -> void:
    if area.is_in_group("circle_obstacle"):
        # 圆形障碍区域
        var push_dir = (position - area.position).normalized()
        if push_dir.length() < 0.1:
            push_dir = Vector2.RIGHT
        velocity += push_dir * 200
        
        var dmg = damage_base + (fish_scale - 1.0) * damage_scale_factor
        take_damage(dmg)
    elif area.is_in_group("end_zone"):
        # 到达终点
        get_tree().call_group("game", "on_win")
