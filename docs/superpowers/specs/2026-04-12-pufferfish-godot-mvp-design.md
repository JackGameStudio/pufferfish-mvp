# 弹弹河豚 × Godot 4 重设计文档

> 日期：2026-04-12
> 状态：已确认，待实施

---

## 1. 项目目标

将弹弹河豚 MVP 从 HTML5 Canvas 迁移至 Godot 4，保留核心弹跳玩法，同时升级架构、美术（像素风）和音效。

**MVP 定义：** 从起点弹到终点，途中躲避/消灭敌人，收集道具，消耗 HP，胜利/死亡条件完整。

**范围终点：** 完整 MVP（架构 + 像素美术 + 音效 + 粒子），但**先交付一个可玩关卡**再扩张。

---

## 2. 核心技术选型

| 模块 | 选择 | 理由 |
|------|------|------|
| 引擎 | Godot 4.6+ | 跨平台（PC/手机/Web），代码 90% 共用 |
| 渲染 | 2D + Pixel Art | 8-bit/16-bit 复古风格，资源好找 |
| 关卡编辑 | TileMap | Godot 内置，可视化拖拽，无需自研编辑器 |
| 物理 | CharacterBody2D | 完全代码控制手感，扩展性强（弹簧/黏液/传送带均适用） |
| 导出平台 | Windows + macOS + Android + iOS + HTML5 | Godot 一键导出 |

---

## 3. 项目结构

```
res://
├── project.godot
├── scenes/
│   ├── main.tscn           # 主入口，加载第一关
│   ├── levels/
│   │   └── level_01.tscn  # 第一关（完整可玩）
│   ├── player/
│   │   └── fish.tscn       # 河豚角色
│   ├── enemies/
│   │   └── patrol_enemy.tscn
│   ├── objects/
│   │   ├── spring.tscn     # 弹簧机关
│   │   ├── coin.tscn       # 收集道具
│   │   └── goal.tscn       # 终点
│   └── ui/
│       └── hud.tscn        # HP 条 + 分数
├── resources/
│   ├── tilesets/
│   │   └── level_tileset.tres  # 瓦片图集
│   ├── sprites/
│   │   ├── fish_sprites.png    # 河豚各状态精灵图
│   │   ├── enemy_sprites.png   # 敌人精灵图
│   │   └── tiles_sprites.png  # 瓦片精灵图
│   └── audio/
│       ├── bounce.wav
│       ├── collect.wav
│       └── hurt.wav
└── scripts/
    ├── fish.gd             # 玩家控制（弹跳、死亡、碰撞）
    ├── game_manager.gd     # 游戏状态、分数、HP
    ├── camera_follow.gd     # 摄像机跟随
    ├── patrol_enemy.gd      # 巡逻敌人 AI
    ├── spring.gd           # 弹簧机关
    └── level_loader.gd     # 关卡加载、重置
```

---

## 4. 核心模块设计

### 4.1 玩家角色（fish.tscn）

- **节点结构：** `CharacterBody2D` → `Sprite2D` + `CollisionShape2D` + `AnimationPlayer`
- **核心脚本：** `fish.gd`
- **状态机：** `idle` | `jumping` | `dead` | `win`
- **弹跳机制：** 点击/空格触发，`velocity = direction * speed`；弹簧机关可覆盖速度
- **HP 系统：** 初始 3 格，受攻击 -1，0 → dead

### 4.2 关卡（level_01.tscn）

- **TileMap 节点：** 使用 `TileSet` 定义瓦片类型（地面/障碍/弹簧/道具）
- **地图尺寸：** 逻辑 1200×900（与原版一致），TileMap 自动扩展
- **内容：**
  - 起点（绿色地砖）
  - 终点（旗帜/门）
  - 平台若干
  - 巡逻敌人 1-2 个
  - 弹簧机关 ×1
  - 收集道具（星星）×3
- **碰撞层：**
  - Layer 1: 地面
  - Layer 2: 敌人
  - Layer 3: 道具/机关
  - Layer 4: 终点

### 4.3 摄像机跟随（camera_follow.gd）

- `Camera2D` 节点，跟随 `fish`
- 平滑 lerp：`position = lerp(position, target, 0.1)`
- 边缘留白：摄像头略超前弹跳方向

### 4.4 敌人 AI（patrol_enemy.gd）

- 在两个 X 坐标之间巡逻
- 碰到鱼 → 鱼扣 HP + 无敌帧闪烁
- 碰到鱼头部（鱼的 y 坐标 < 敌人的 y 中心）→ 消灭敌人，敌人消失 + 得分

### 4.5 粒子特效

- **弹跳爆炸：** `CPUParticles2D` 或 `GPUParticles2D`，在 `velocity.y` 反方向爆发
- **死亡特效：** 红色粒子爆开 + 屏幕闪红
- **收集道具：** 金色星星闪光粒子

---

## 5. 验收标准（第一关）

| 检查项 | 标准 |
|--------|------|
| 游戏能启动 | 打开项目后直接进入 level_01 |
| 弹跳手感 | 点击/空格能控制方向，CharacterBody2D 物理反馈正常 |
| TileMap 正常 | 能看到像素风瓦片地面、起点、终点 |
| 摄像机跟随 | 鱼移动时摄像机平滑跟随 |
| 敌人碰撞 | 碰到敌人扣血，鱼闪红，敌人消灭 |
| 弹簧机关 | 碰到弹簧后高速弹起 |
| 收集道具 | 碰到星星 +10 分，星星消失 |
| 胜负条件 | 到达终点显示"通关"；HP=0 显示"失败"并重置 |
| 音效 | 弹跳/收集/受伤有不同音效反馈 |
| 导出测试 | Windows 导出后能独立运行 |

---

## 6. 像素美术资源（第一关）

**来源策略：** 使用免费像素素材，再按需调整

| 资源 | 建议来源 | 规格 |
|------|----------|------|
| 河豚精灵 | 自行绘制或免费素材 | 32×32 或 64×64，4 方向动画 |
| 地面瓦片 | OpenGameArt /itch.io 免费包 | 16×16 或 32×32 |
| 敌人 | 同上 | 32×32 |
| 星星道具 | 同上 | 16×16 |
| 弹簧 | 自行绘制 | 16×16，3帧动画 |

**美术风格锚点：** 16-bit SNES 风格，256 色上限，清晰轮廓线

---

## 7. 音效设计

| 事件 | 音效描述 |
|------|----------|
| 弹跳 | 短促"噗"声 |
| 收集星星 | 清脆叮咚 |
| 受伤 | 低频撞击 |
| 消灭敌人（踩头） | 轻微爆炸 |
| 过关 | 胜利 jingle（2-3秒） |
| 死亡 | 失败音效 |

**工具：** Godot 内置 `AudioStreamPlayer`，所有音效挂载在 `main.tscn`

---

## 8. 团队分工

| 角色 | 职责 |
|------|------|
| **麟虾** | 全栈实现：代码 + 关卡设计 + 资源集成 |
| **JACK** | 审批玩法、美术方向把关 |

---

## 9. 下一步

1. ✅ 本设计文档确认
2. → 制定实施计划（writing-plans skill）
3. → 搭建 Godot 项目骨架
4. → 实现鱼（fish.gd）+ 摄像机跟随
5. → 制作 TileSet + level_01
6. → 添加敌人 + 机关 + 道具
7. → 接入美术资源（像素风）
8. → 添加音效和粒子
9. → 测试 + 导出 Windows 版验收
