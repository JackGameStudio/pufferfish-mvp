extends Node2D
class_name GameManager

signal game_over
signal game_win

var game_state: String = "playing"  # playing | won | lost

func _ready() -> void:
	add_to_group("game")

func on_game_over() -> void:
	if game_state != "playing":
		return
	game_state = "lost"
	game_over.emit()
	_show_message("游戏结束!\n点击重新开始")

func on_win() -> void:
	if game_state != "playing":
		return
	game_state = "won"
	game_win.emit()
	_show_message("过关!\n点击重新开始")

func _show_message(text: String) -> void:
	var label = Label.new()
	label.name = "MessageLabel"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.add_theme_font_size_override("font_size", 48)
	add_child(label)

func _input(event: InputEvent) -> void:
	if game_state != "playing" and event is InputEventMouseButton:
		if event.pressed:
			get_tree().reload_current_scene()
