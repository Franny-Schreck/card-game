class_name Hand
extends CardContainer2D

const IMPORTS = ["board"]

const ARC_ANGLE_BASE: float = 0.1

const ARC_OFFSET_BASE: float = 1100

const ARC_ANGLE_POW: float = 0.6

const ARC_OFFSET_POW: float = 0.5

const ARC_FOCUS_ANGLE_BASE: float = 0.015

const FOCUS_UP_OFFSET: float = 110

const HOVER_EXIT_DELAY: float = 0.05

const MIN_DRAG_DISTANCE = 10

const MIN_DRAG_TIME = 500

var board: Board

var clicked_card: Card

var hovered_card: Card

var _card_click_position: Vector2

var _card_click_time: int

var _extra_play_cost: int


func reset_extra_play_cost(to: int) -> void:
	_extra_play_cost = to
	for card in _cards:
		card.set_extra_play_cost(_extra_play_cost)


func _ready() -> void:
	super._ready()
	board = get_parent().get_node("board")
	content_changed.connect(_redraw)
	card_input.connect(_on_card_input)
	card_mouse.connect(_on_card_mouse)
	card_attached.connect(_on_card_attached)
	
	Root.connect_on_root_ready(self, _on_root_ready)
	
	board.new_turn.connect(_on_new_turn)
	
	board.card_played.connect(_on_card_played)


func _on_root_ready() -> void:
	for i in range(3):
		add_card(await board.card_factory.get_card_by_category("shop"))


func _input(event: InputEvent) -> void:
	if self.clicked_card == null:
		return

	if (event.is_action_released("mouse_left") and not _is_card_click(event)) or event.is_action_pressed("mouse_left"):
		clicked_card.set_clicked(false)
		board.play(clicked_card)
		clicked_card = null
		_redraw(_cards)
	elif event.is_action_pressed("mouse_right"):
		clicked_card = null
		_redraw(_cards)


func _redraw(cards: Array[Card]) -> void:

	var enlarged_card_index: int = _calc_enlarged_card_index()

	for index in range(cards.size()):
		var tf: Transform2D = _calc_card_transform(index, enlarged_card_index)
		var card: Card = cards[index]
		card.checkpoint_transform().animate_to(
			global_position + tf.get_origin(),
			tf.get_scale(),
			tf.get_rotation(),
			true,
			0.2
		)

		card.set_clicked(card == clicked_card)
		card.set_hovered(card == hovered_card and card._base_play_cost != -1 and clicked_card == null)

		card.z_index = 1

		_card_root.move_child(card, index)

	if enlarged_card_index != -1:
		var enlarged_card: Card = cards[enlarged_card_index]
		enlarged_card.z_index = 2
		_card_root.move_child(enlarged_card, -1)


func _on_card_attached(card: Card, index: int) -> void:
	var tf: Transform2D = _calc_card_transform(index, _calc_enlarged_card_index())
	card.animate_to(
		global_position + tf.get_origin(),
		tf.get_scale(),
		tf.get_rotation(),
		true,
		0.6
	)
	card.set_extra_play_cost(_extra_play_cost)


func _on_card_detached(card: Card, _index: int) -> void:
	card.set_extra_play_cost(0)


func _on_card_input(card: Card, event: InputEvent) -> void:
	if event.is_action_pressed("mouse_left") and hovered_card == card and card._base_play_cost != -1:
		clicked_card = card
		_card_click_position = event.global_position
		_card_click_time = Time.get_ticks_msec()
		_redraw(_cards)


func _on_card_mouse(card: Card, is_entered: bool) -> void:
	card.set_hovered(is_entered and clicked_card == null)

	if is_entered:
		hovered_card = card
	else:
		var last_hovered_card: Card = hovered_card
		await get_tree().create_timer(HOVER_EXIT_DELAY).timeout
		if hovered_card == last_hovered_card:
			hovered_card = null

	_redraw(_cards)


func _is_card_click(event: InputEvent) -> bool:
	return (_card_click_position - event.global_position).length() < MIN_DRAG_DISTANCE \
	   and Time.get_ticks_msec() - _card_click_time < MIN_DRAG_TIME


func _on_new_turn() -> void:
	reset_extra_play_cost(0)


func _on_card_played() -> void:
	_extra_play_cost += 1
	for card in _cards:
		card.set_extra_play_cost(_extra_play_cost)


func _calc_card_transform(index: int, enlarged_card_index: int) -> Transform2D:
	var card: Card = _cards[index]
	var is_enlarged: bool = index == enlarged_card_index
	var is_centered: bool = card == clicked_card

	# Distance from the card arc's center point
	var offset: float = ARC_OFFSET_BASE * pow(_cards.size(), ARC_OFFSET_POW)

	# Angle between cards
	var angle_delta: float = ARC_ANGLE_BASE / pow(_cards.size(), ARC_ANGLE_POW)

	# Offset applied to the card's angle to 'center' the card arc
	var angle_offset: float = ((_cards.size() - 1) * angle_delta) / 2 + (ARC_FOCUS_ANGLE_BASE / 2 if enlarged_card_index >= 0 and enlarged_card_index <= index else 0.0)

	var tf_scale: Vector2 = Vector2(1.5, 1.5) if is_enlarged else Vector2(1, 1)

	var tf_rotate: float = angle_delta * index - angle_offset if not is_centered else 0.0

	var tf_up: float = Hand.FOCUS_UP_OFFSET if is_enlarged else 0.0

	var tf_unrotate: float = -tf_rotate if is_enlarged and not is_centered else 0.0

	return Transform2D() \
		.scaled(tf_scale) \
		.rotated(tf_unrotate) \
		.translated(Vector2(0, -offset - tf_up)) \
		.rotated(tf_rotate) \
		.translated(Vector2(0, offset))


func _calc_enlarged_card_index() -> int:
	var index: int = index_of(clicked_card)
	return index if index != -1 else index_of(hovered_card)
