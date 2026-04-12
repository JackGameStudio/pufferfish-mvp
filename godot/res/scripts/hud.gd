extends Control

@onready var hp_bar: TextureProgressBar
@onready var hp_label: Label

var max_hp: int = 100

func _ready() -> void:
    # 创建 HP 条 UI
    var panel = PanelContainer.new()
    panel.name = "HP Panel"
    panel.position = Vector2(20, 20)
    add_child(panel)
    
    var hbox = HBoxContainer.new()
    panel.add_child(hbox)
    
    hp_label = Label.new()
    hp_label.text = "HP: 100"
    hp_label.add_theme_font_size_override("font_size", 24)
    hbox.add_child(hp_label)
    
    hp_bar = TextureProgressBar.new()
    hp_bar.name = "HP Bar"
    hp_bar.min_value = 0
    hp_bar.max_value = 100
    hp_bar.value = 100
    hp_bar.size = Vector2(200, 20)
    hp_bar.position = Vector2(80, 5)
    # 用颜色创建简单进度条
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.2, 0.8, 0.2)
    style.set_corner_radius_all(4)
    hp_bar.add_theme_stylebox_override("fill", style)
    hbox.add_child(hp_bar)
    
    # 监听鱼的血量变化
    get_tree().call_group("fish", "tree_entered").connect(_on_fish_ready)

func _on_fish_ready() -> void:
    var fish = get_tree().get_first_node_in_group("fish") as Fish
    if fish:
        fish.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(current: int, max_val: int) -> void:
    max_hp = max_val
    hp_bar.max_value = max_val
    hp_bar.value = current
    hp_label.text = "HP: " + str(current)
