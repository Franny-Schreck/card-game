class_name GameOverScreen
extends Node2D

var _title: Label

var _subtitle: Label

var _sticky: bool


func show_game_over(title: String, subtitle: String, sticky: bool) -> void:
	_title.text = title
	_subtitle.text = subtitle
	_sticky = sticky
	if sticky:
		get_node("background/buttons/continue_btn").hide()
	show()


func _ready() -> void:
	_title = get_node("background/title")
	_subtitle = get_node("background/subtitle")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_main_menu"):
		if not visible:
			show_game_over("MENU", "What do you want to do?", false)
		elif not _sticky:
			hide() 


func _on_retry_btn_pressed() -> void:
	var board: Board = get_node("/root/root/board")	
	board.reset()
	hide()


func _on_quit_btn_pressed() -> void:
	get_tree().quit()


func _on_continue_btn_pressed() -> void:
	hide()
