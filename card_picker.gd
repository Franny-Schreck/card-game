class_name CardPicker
extends Node2D

var pickable_cards: PickableCards

var btn_confirm: Button

var is_ready: bool

signal cards_picked(cards: Array[Card])

func _ready() -> void:
	self.pickable_cards = get_node("pickable_cards")
	self.btn_confirm = get_node("btn_confirm")
	pickable_cards.set_process(false)


func _on_btn_confirm_pressed() -> void:
	hide()
	var root: Node = get_tree().root.get_child(0)
	root.get_node("hand").set_process(true)
	root.get_node("draw_pile").set_process(true)
	root.get_node("discard_pile").set_process(true)
	pickable_cards.set_process(false)

	cards_picked.emit(pickable_cards.get_picked_cards())


func _delayed_ready():
	is_ready = true


func pick_cards(cards: Array[Card], pick_count: int) -> Array[Card]:
	is_ready = false
	show()
	var root: Node = get_tree().root.get_child(0)
	root.get_node("hand").set_process(false)
	root.get_node("draw_pile").set_process(false)
	root.get_node("discard_pile").set_process(false)
	pickable_cards.set_process(true)

	pickable_cards.set_cards(cards, pick_count)

	await get_tree().create_timer(0.1).timeout

	is_ready = true

	return await cards_picked
