# 弹弹河豚 × Godot 4 MVP 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付一个完整的可玩关卡（level_01），包含弹跳玩法、敌人、机关、道具、音效和像素美术

**Architecture:** CharacterBody2D 玩家 + TileMap 关卡 + 节点树结构，代码与场景分离，Godot 一键导出全平台

**Tech Stack:** Godot 4.6+ | GDScript | TileMap | CharacterBody2D | CPUParticles2D | AudioStreamPlayer

---

## 文件结构

```
res://
├── project.godot                  # Godot 项目入口
├── scenes/
│   ├── main.tscn                  # 主场景（加载 level_01）
│   ├── levels/
│   │   └── level_01.tscn         # 第一关完整关卡
│   ├── player/
│   │   └── fish.tscn             # 河豚角色
│   ├── objects/
│   │   ├── spring.tscn           # 弹簧机关
│   │   ├── coin.tscn             # 星星道具
│   │   └── goal.tscn             # 终点门
│   ├── enemies/
│   │   └── patrol_enemy.tscn     # 巡逻敌人
│   └── ui/
│       └── hud.tscn              # HP条+分数
├── resources/
│   ├── tilesets/
│   │   └── level_tileset.tres    # 瓦片图集
│   ├── sprites/                   # 所有精灵图
│   └── audio/                     # 音效文件
└── scripts/
    ├── fish.gd                    # 玩家控制
    ├── game_manager.gd            # 游戏状态管理
    ├── camera_follow.gd           # 摄像机跟随
    ├── patrol_enemy.gd            # 敌人AI
    ├── spring.gd                  # 弹簧机关
    ├── coin.gd                   # 星星收集
    └── hud.gd                    # UI更新
```

---

## 阶段一：项目骨架

### Task 1: 创建 Godot 项目

**Files:**
- 创建: `res://project.godot`
- 创建: `res://scenes/main.tscn`
- 创建: `res://scenes/levels/level_01.tscn`

- [ ] **Step 1: 创建 project.godot**

在 `pufferfish-mvp` 目录下用 Godot 4 CLI 新建项目，或手动创建基础 `project.godot` 文件

- [ ] **Step 2: 创建 main.tscn**

- 根节点: `Node2D`
- 子节点: `Camera2D`（全屏跟随）
- 添加 `game_manager.gd` 脚本

- [ ] **Step 3: 创建 level_01.tscn**

- 根节点: `Node2D`
- 子节点: `TileMap`（空地图，待填充瓦片）
- 连接 `main.tscn` → 实例化 `level_01.tscn`

- [ ] **Step 4: 提交**

```bash
git add -A; git commit -m "feat: Godot项目骨架 - main.tscn + level_01.tscn"
```

---

### Task 2: 玩家角色 fish.tscn

**Files:**
- 创建: `res://scenes/player/fish.tscn`
- 创建: `res://scripts/fish.gd`

- [ ] **Step 1: 创建 fish.tscn 节点树**

```
CharacterBody2D (fish.gd)
├── Sprite2D (精灵图)
├── CollisionShape2D (碰撞体，圆形)
├── AnimationPlayer (动画)
└── CPUParticles2D (弹跳粒子)
```

- [ ] **Step 2: 写 fish.gd 核心逻辑**

```gdscript
extends CharacterBody2D

@export var speed: float = 300.0
@export var jump_force: float = -500.0

var hp: int = 3
var is_invincible: bool = false
var invincible_timer: float = 0.0

# 状态: idle, jumping, dead, win
var state: String = "idle"

func _physics_process(delta: float) -> void:
    # 重力
    velocity.y += 800 * delta
    # 移动
    velocity.x = speed
    move_and_slide()

    # 无敌计时
    if is_invincible:
        invincible_timer -= delta
        if invincible_timer <= 0:
            is_invincible = false
            $Sprite2D.modulate = Color.WHITE

func jump(dir: Vector2) -> void:
    velocity = dir * speed
    # 触发弹跳粒子
    $CPUParticles2D.emitting = true

func take_damage() -> void:
    if is_invincible:
        return
    hp -= 1
    is_invincible = true
    invincible_timer = 1.5
    $Sprite2D.modulate = Color.RED
    # 屏幕震动（Camera2D调用）
    get_tree().call_group("camera", "shake")
    if hp <= 0:
        state = "dead"
```

- [ ] **Step 3: 在 level_01.tscn 实例化 fish.tscn**

放置在起点位置

- [ ] **Step 4: 提交**

```bash
git add -A; git commit -m "feat: 玩家角色fish - CharacterBody2D + 弹跳 + 受伤无敌帧"
```

---

### Task 3: 摄像机跟随

**Files:**
- 创建: `res://scripts/camera_follow.gd`
- 修改: `res://scenes/main.tscn`

- [ ] **Step 1: 写 camera_follow.gd**

```gdscript
extends Camera2D

@export var target: Node2D
@export var lerp_speed: float = 0.1
@export var shake_duration: float = 0.2
@export var shake_amount: float = 5.0

var _shake_timer: float = 0.0
var _offset: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
    if target:
        position = lerp(position, target.position, lerp_speed)
    if _shake_timer > 0:
        _shake_timer -= delta
        _offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amount
    else:
        _offset = Vector2.ZERO

func shake() -> void:
    _shake_timer = shake_duration
```

- [ ] **Step 2: Camera2D 添加 `add_to_group("camera")`**

- [ ] **Step 3: 提交**

```bash
git add -A; git commit -m "feat: 摄像机跟随 + 屏幕震动"
```

---

## 阶段二：关卡编辑（麟虾引导 JACK）

### Task 4: TileSet + 第一关布局

**Files:**
- 创建: `res://resources/tilesets/level_tileset.tres`
- 创建: `res://resources/sprites/tiles_sprites.png` （像素瓦片图，JACK 负责迭代）
- 修改: `res://scenes/levels/level_01.tscn`

- [ ] **Step 1: 麟虾引导 JACK 创建像素瓦片图**

使用免费素材或 JACK 绘制 16×16 / 32×32 像素瓦片，保存为 PNG

- [ ] **Step 2: 在 Godot 中创建 TileSet → 添加瓦片**

麟虾通过截图/指引步骤引导 JACK 操作 Godot 编辑器

- [ ] **Step 3: 在 level_01.tscn 的 TileMap 上摆放瓦片**

麟虾指导 JACK 绘制：地面、障碍物、弹簧位置

- [ ] **Step 4: 提交**

---

### Task 5: 关卡内容物摆放

**Files:**
- 创建: `res://scenes/objects/spring.tscn`
- 创建: `res://scenes/objects/goal.tscn`
- 创建: `res://scenes/objects/coin.tscn`
- 修改: `res://scenes/levels/level_01.tscn`

- [ ] **Step 1: 创建弹簧机关**

节点树：`Area2D` + `CollisionShape2D` + `Sprite2D`
脚本 `spring.gd`：检测 fish 进入 → 触发高速弹射

- [ ] **Step 2: 创建终点门**

`Area2D` + `CollisionShape2D` + `Sprite2D`
检测 fish 进入 → 触发 win 状态

- [ ] **Step 3: 创建星星道具**

`Area2D` + `CollisionShape2D` + `Sprite2D` + `AnimationPlayer`
检测 fish 进入 → 收集 + 加分 + 消失

- [ ] **Step 4: 提交**

---

## 阶段三：敌人 + 交互

### Task 6: 巡逻敌人

**Files:**
- 创建: `res://scenes/enemies/patrol_enemy.tscn`
- 创建: `res://scripts/patrol_enemy.gd`
- 修改: `res://scenes/levels/level_01.tscn`

- [ ] **Step 1: 创建 patrol_enemy.tscn 节点树**

```
CharacterBody2D (patrol_enemy.gd)
├── Sprite2D
├── CollisionShape2D
└── AnimationPlayer
```

- [ ] **Step 2: 写 patrol_enemy.gd**

```gdscript
extends CharacterBody2D

@export var patrol_left: float = 0.0
@export var patrol_right: float = 200.0
@export var speed: float = 100.0

var direction: int = 1

func _physics_process(delta: float) -> void:
    velocity.x = speed * direction
    move_and_slide()

    if position.x >= patrol_right:
        direction = -1
    elif position.x <= patrol_left:
        direction = 1

    $Sprite2D.flip_h = direction < 0

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("fish"):
        # 检测是踩头还是碰身
        if body.position.y < position.y - 10:
            # 消灭敌人
            queue_free()
        else:
            # 扣血
            body.take_damage()
```

- [ ] **Step 3: 在 level_01 放置 1-2 个敌人**

- [ ] **Step 4: 提交**

---

## 阶段四：音效 + 粒子

### Task 7: 音效层

**Files:**
- 创建: `res://resources/audio/` （bounce.wav, collect.wav, hurt.wav, win.wav）
- 修改: `res://scripts/fish.gd`
- 修改: `res://scripts/coin.gd`

- [ ] **Step 1: 获取/制作音效文件]

使用 Audacity 或在线免费音效

- [ ] **Step 2: 在 main.tscn 添加 AudioStreamPlayer 节点**

- [ ] **Step 3: 在 fish.gd 的 jump() 播放弹跳音效**

```gdscript
AudioServer.play_bounce_sound()
```

- [ ] **Step 4: 提交**

---

### Task 8: 粒子特效

**Files:**
- 修改: `res://scenes/player/fish.tscn`
- 修改: `res://scripts/fish.gd`

- [ ] **Step 1: 弹跳粒子**

`CPUParticles2D` 配置：向前爆发、淡出、生命周期 0.5s

- [ ] **Step 2: 受伤屏幕闪红**

Camera2D 加 ColorRect → 受伤时闪红 → 0.3s 后消失

- [ ] **Step 3: 提交**

---

## 阶段五：验收

### Task 9: 完整验收

- [ ] **Step 1: 玩法验收**
  - [ ] 弹跳方向正确（点击/空格）
  - [ ] 摄像机跟随流畅
  - [ ] HP 条正确显示（3格）
  - [ ] 受伤后无敌帧闪烁
  - [ ] 踩头消灭敌人

- [ ] **Step 2: 关卡验收**
  - [ ] 弹簧机关能弹起鱼
  - [ ] 星星可收集，+10分
  - [ ] 到达终点触发 win
  - [ ] HP=0 触发 dead + 重置

- [ ] **Step 3: 导出验收**
  - [ ] Windows .exe 可独立运行
  - [ ] HTML5 导出可在浏览器运行

- [ ] **Step 4: 提交最终版本**

```bash
git add -A; git commit -m "feat: level_01 MVP完成 - 完整可玩版本"
git tag -a v1.0 -m "弹弹河豚 MVP v1.0 - level_01 可玩版本"
```

---

## JACK × 麟虾 协作模式说明

| 阶段 | JACK 负责 | 麟虾负责 |
|------|-----------|----------|
| 像素美术 | 绘制/选择瓦片、角色、敌人精灵图 | 导入 Godot、调整导入设置 |
| 关卡设计 | 在 Godot TileMap 中拖拽摆放 | 指引操作步骤、验证碰撞 |
| 音效素材 | 收集/制作音效文件 | 接入 AudioStreamPlayer |
| 验收测试 | 实际玩游戏并反馈 | 修复 bug、调整参数 |

**麟虾引导原则：** 每个 Godot 操作步骤给出截图指引或文字描述，JACK 跟着做，有问题随时问。
