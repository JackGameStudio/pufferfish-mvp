# 弹弹河豚 × Godot 4 MVP 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 移植 MVP 核心弹跳机制到 Godot 4，包含：充气膨胀、持续旋转、弹弓弹射、摩擦飞行、障碍碰撞

**Architecture:** CharacterBody2D + 自定义物理（摩擦力而非重力）+ 状态机（charging / flying / idle）

**Tech Stack:** Godot 4.6+ | GDScript | TileMap | CharacterBody2D | CPUParticles2D | AudioStreamPlayer

---

## MVP 核心机制（代码级规范）

### 物理参数（严格对应原版）

| 参数 | 原版值 | Godot 实现 |
|------|--------|------------|
| `maxScale` | 1.8 | `fish.scale` 1.0 → 1.8 |
| `inflateRate` | 0.8/s（1秒满膨胀） | `scale += 0.8 * delta` |
| `deflateRate` | 1.4/s（0.5秒缩回） | `scale -= 1.4 * delta` |
| `launchVel` | 900 px/s | `Vector2(cos/sin) * 900 * power` |
| `friction` | 0.992/帧 | `velocity *= 0.992` |
| `rotSpeed` | 6 rad/s | `rotation += 6 * delta`（charging时）|
| `launch方向` | `rotation + PI` | 与 facing 反方向弹射 |

### 状态机

```
fish.state = "idle" | "charging" | "flying"

idle:     velocity ≈ 0，等待输入
charging: 按住 → scale增大 + rotation自转，不受摩擦影响
flying:   松手 → 以 rotation+PI 方向弹射，摩擦减速，rotation对齐速度
          charging优先：飞行中按住也会触发charging状态
idle判定: speed < 5 → state = "idle"
```

### 碰撞规则

- 圆形障碍：物理推开 + 扣血 + 无敌帧（scale≥95%时无敌）
- 矩形障碍：物理推开（不掉血）
- 碰撞后速度衰减 80%

---

## 文件结构

```
res://
├── project.godot
├── scenes/
│   ├── main.tscn              # 游戏入口，加载 level_01
│   ├── levels/
│   │   └── level_01.tscn     # 第一关（TileMap + 障碍数据）
│   ├── player/
│   │   └── fish.tscn         # 河豚角色
│   ├── obstacles/
│   │   ├── circle_obstacle.tscn  # 圆形障碍（可掉血）
│   │   └── rect_obstacle.tscn    # 矩形障碍（不掉血）
│   └── ui/
│       └── hud.tscn           # HP条（屏幕空间）
├── resources/
│   ├── tilesets/
│   │   └── level_tileset.tres
│   ├── sprites/               # 像素精灵图
│   └── audio/
└── scripts/
    ├── fish.gd               # 核心：状态机 + 充气 + 弹射
    ├── game_manager.gd       # 游戏状态（win/gameover）
    ├── camera_follow.gd      # 摄像机跟随
    ├── hud.gd                # HP条更新
    └── level_loader.gd       # 关卡数据加载
```

---

## 阶段一：核心玩家角色（最重要）

### Task 1: fish.tscn 节点树

**Files:**
- 创建: `res://scenes/player/fish.tscn`
- 创建: `res://scripts/fish.gd`

- [ ] **Step 1: 创建 fish.tscn 节点树**

```
CharacterBody2D (fish.gd, 添加到组 "fish")
├── Sprite2D (像素精灵图，锚点居中)
├── CollisionShape2D (圆形，半径20px)
└── CPUParticles2D (弹跳粒子，可选后加)
```

- [ ] **Step 2: 写 fish.gd 核心逻辑（严格对标原版）**

```gdscript
extends CharacterBody2D
class_name Fish

# === 物理参数（对应原版 index.html） ===
@export var max_scale: float = 1.8       # 最大膨胀
@export var inflate_rate: float = 0.8    # 膨胀速度（1秒满）
@export var deflate_rate: float = 1.4    # 收缩速度（0.5秒回）
@export var launch_vel: float = 900.0    # 弹射初速
@export var friction: float = 0.992      # 摩擦（每帧乘）
@export var rot_speed: float = 6.0       # 旋转速度（rad/s）
@export var invinc_time: float = 0.5     # 无敌帧时长
@export var max_hp: int = 100
@export var damage_base: float = 10.0
@export var damage_scale_factor: float = 40.0

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

# === 引用 ===
@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
    add_to_group("fish")

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
            sprite.rotation = rotation_angle
            var scale_factor = 1.0 + (fish_scale - 1.0) * (1.0 / (max_scale - 1.0)) * 0.6
            sprite.scale = Vector2(scale_factor, scale_factor)

            if just_released and inflate > 0.2:
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
                sprite.rotation = rotation_angle

            # 波浪抖动
            if wave_amp > 0:
                wave_offset += delta * 30
                var wave = sin(wave_offset) * wave_amp
                var dir = velocity.normalized()
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

func _start_charging() -> void:
    state = "charging"
    launch_scale = fish_scale
    launch_time = 0.0

func _start_deflating() -> void:
    state = "flying"
    fish_scale = max(fish_scale - deflate_rate * get_process_delta_time(), 1.0)

func _launch() -> void:
    var power = inflate  # 0~1
    var dir = rotation_angle + PI  # 弹弓：当前朝向的反方向
    velocity = Vector2(cos(dir), sin(dir)) * launch_vel * power
    launch_scale = fish_scale
    launch_time = 0.0
    fish_scale = 1.0
    inflate = 0.0
    wave_amp = power * 25.0
    state = "flying"
    particles.emitting = true if particles else false

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
```

- [ ] **Step 3: 提交**

```bash
git add -A; git commit -m "feat: fish角色核心逻辑 - 充气/旋转/弹弓弹射/摩擦飞行"
```

---

### Task 2: 摄像机跟随

**Files:**
- 创建: `res://scripts/camera_follow.gd`
- 修改: `res://scenes/main.tscn`

- [ ] **Step 1: camera_follow.gd**

```gdscript
extends Camera2D

@export var target_path: NodePath
@export var lerp_speed: float = 0.08

var shake_timer: float = 0.0
var shake_amount: float = 5.0

func _process(delta: float) -> void:
    if target_path:
        var target = get_node(target_path)
        position = position.lerp(target.position, lerp_speed)
    if shake_timer > 0:
        shake_timer -= delta
        offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
    else:
        offset = Vector2.ZERO

func shake(duration: float = 0.2, amount: float = 5.0) -> void:
    shake_timer = duration
    shake_amount = amount
```

- [ ] **Step 2: main.tscn 添加 Camera2D，设置 target_path**

- [ ] **Step 3: 提交**

---

## 阶段二：障碍物 + 碰撞

### Task 3: 圆形障碍（掉血）

**Files:**
- 创建: `res://scenes/obstacles/circle_obstacle.tscn`
- 创建: `res://scripts/circle_obstacle.gd`

- [ ] **Step 1: circle_obstacle.gd**

```gdscript
extends Area2D

@export var radius: float = 45.0
@export var damage: float = 10.0
@export var damage_scale_factor: float = 40.0

func _ready() -> void:
    var shape = CircleShape2D.new()
    shape.radius = radius
    $CollisionShape2D.shape = shape
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not body.is_in_group("fish"):
        return
    var fish: Fish = body as Fish
    var dmg = damage + (fish.fish_scale - 1.0) * damage_scale_factor
    fish.take_damage(dmg)
```

### Task 4: 矩形障碍（不掉血）

**Files:**
- 创建: `res://scenes/obstacles/rect_obstacle.tscn`
- 创建: `res://scripts/rect_obstacle.gd`

- [ ] **Step 1: rect_obstacle.gd**

```gdscript
extends Area2D

# 矩形障碍：物理推开，不掉血
# 通过 StaticBody2D 实现碰撞响应
```

- [ ] **Step 2: 提交**

---

## 阶段三：关卡数据（对应原版 index.html）

**Files:**
- 创建: `res://scenes/levels/level_01.tscn`
- 创建: `res://resources/tilesets/level_tileset.tres`
- 创建: `res://scripts/level_loader.gd`

### 原版关卡数据（直接移植）

```python
LEVEL_W = 2200, LEVEL_H = 750
startX = 80, startY = 450
endX = 2050, endY = 350, endRadius = 40

# 圆形障碍（28个）
obstacles = [
    (200,250,45), (280,230,50), (360,220,48), (440,230,52),
    (520,260,50), (580,310,48),
    (620,380,45), (680,430,50), (740,460,52), (800,470,48), (860,460,45),
    (920,420,50), (970,360,48), (1020,310,52),
    (1080,270,45), (1140,250,48), (1200,245,50),
    (250,500,50), (330,520,48), (410,540,52), (490,550,45),
    (570,540,50), (650,510,48), (730,470,52), (810,530,45),
    (890,560,50), (970,530,48), (1050,490,52)
]

# 矩形障碍（16个）
rects = [
    (150,400,30,80), (350,350,100,20), (350,420,80,20),
    (550,200,20,100), (550,450,20,100), (700,300,120,20),
    (950,280,20,80), (950,420,20,80),
    (1100,200,80,15), (1100,350,80,15), (1100,500,80,15),
    (1250,150,20,60), (1250,350,20,80), (1250,500,20,60),
    (1850,280,150,20), (1850,400,150,20)
]
```

- [ ] **Step 1: level_loader.gd 解析关卡数据，实例化障碍物节点**

- [ ] **Step 2: 在 level_01.tscn 用脚本生成所有障碍物**

- [ ] **Step 3: 添加起点/终点标记**

- [ ] **Step 4: 提交**

---

## 阶段四：UI + 游戏状态

### Task 5: HUD + 游戏管理

**Files:**
- 创建: `res://scenes/ui/hud.tscn`
- 创建: `res://scripts/hud.gd`
- 创建: `res://scripts/game_manager.gd`

- [ ] **Step 1: hud.gd — HP条（屏幕空间）**

```gdscript
extends Control

@onready var hp_bar: TextureProgressBar
@onready var hp_label: Label

func _ready() -> void:
    get_tree().call_group("fish", "health_changed").connect(_on_health_changed)

func _on_health_changed(current: int, max_hp: int) -> void:
    hp_bar.value = current * 100.0 / max_hp
    hp_label.text = str(current)
```

- [ ] **Step 2: game_manager.gd — win/gameover 状态**

- [ ] **Step 3: 提交**

---

## 阶段五：像素美术 + 音效（可迭代）

### Task 6: 像素精灵图（第一版先用占位色块）

- [ ] **JACK 主导：** 绘制/选择像素瓦片精灵图（16×16 / 32×32）
- [ ] **麟虾：** 导入 Godot，设置 `Import → Pixel` 模式
- [ ] **提交**

### Task 7: 音效（对应原版 Web Audio API）

- [ ] **用 Godot AudioStreamPlayer 替代 Web Audio API**
- 弹射音：400Hz 正弦波 0.1s
- 受伤音：150Hz 方波 0.3s
- 过关音：800Hz 正弦波 0.3s

- [ ] **提交**

---

## 阶段六：验收（逐项对标原版）

| 检查项 | 原版行为 | Godot 实现 |
|--------|----------|------------|
| 按住充气 | scale 1→1.8，旋转 | `charging` 状态 |
| 松手弹射 | 反方向 900*power | `launch()` 函数 |
| 摩擦飞行 | velocity *= 0.992 | `_apply_friction()` |
| 圆形障碍碰撞 | 推开+扣血 | `circle_obstacle.gd` |
| 矩形障碍碰撞 | 推开不掉血 | `rect_obstacle.gd` |
| 膨胀无敌 | scale≥95% 无敌 | `is_invincible()` |
| 过关判定 | 到达 endZone | `game_manager.gd` |
| 失败判定 | hp=0 | `game_manager.gd` |
| 摄像机跟随 | 平滑 lerp 0.08 | `camera_follow.gd` |

---

## JACK × 麟虾 协作模式

| 阶段 | JACK 负责 | 麟虾负责 |
|------|-----------|----------|
| 像素美术 | 绘制瓦片、角色精灵图 | 导入 Godot、设置 Pixel 模式 |
| 关卡设计 | TileMap 摆放（参考原版坐标） | 提供操作步骤指引 |
| 音效素材 | 收集/制作音效 | 接入 AudioStreamPlayer |
| 验收测试 | 实际玩游戏并反馈手感 | 调参（摩擦力、弹射速度等）|

**麟虾引导原则：** 每步 Godot 操作给出截图 + 文字描述，JACK 跟着做。
