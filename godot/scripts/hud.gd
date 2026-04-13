extends Control

var hp_bar: TextureProgressBar
var hp_label: Label
var max_hp: int = 100

func _ready() -> void:
	# 创建 HP 条 UI
	var panel = PanelContainer.new()
	panel.name = "HP Panel"
	panel.anchor_left = 0
	panel.anchor_top = 0
	panel.offset_left = 20
	panel.offset_top = 20
	panel.offset_right = 320
	panel.offset_bottom = 60
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
	hbox.add_child(hp_bar)
	
	# 用颜色创建简单进度条背景
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.3, 0.3, 0.3)
	bg_style.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.2, 0.8, 0.2)
	fill_style.set_corner_radius_all(4)
	hp_bar.add_theme_stylebox_override("fill", fill_style)
	
	# 定时器轮询鱼的血量
	var timer = Timer.new()
	timer.name = "FishHPTimer"
	timer.wait_time = 0.1
	timer.autostart = true
	timer.timeout.connect(_poll_fish_hp)
	add_child(timer)

func _poll_fish_hp() -> void:
	var fish = get_tree().get_first_node_in_group("fish") as Fish
	if fish and hp_bar:
		max_hp = fish.max_hp
		hp_bar.max_value = max_hp
		hp_bar.value = fish.hp
		hp_label.text = "HP: " + str(fish.hp)
