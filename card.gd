class_name Card
extends Node2D

class GPS:
	var scale: Vector2
	var global_position: Vector2
	var rotation: float

const DEFAULT_CARD_USES = 3

var _card_script: Dictionary

var _suppress_discard: bool

var _is_sticky: bool

var _is_autoplay_start: bool

var _is_autoplay_end: bool

var _name: String

var _age: int

var _play_count: int

var _total_play_count: int

var _hover_outline: Panel

var _click_outline: Panel

var _disable_outline: Panel

var _base_play_cost: int

var _extra_play_cost: int

var _play_cost_label: Label

var _is_disabled: bool

var _tags: Array[String]

var _old_global_position: Vector2

var _old_scale: Vector2

var _old_rotation: float = -INF

var _tween_duration: float

var _tween: Tween

signal input(card: Card, input: InputEvent)

signal mouse(card: Card, is_entered: bool)


static func create_from_script(card_script: Dictionary) -> Card:
	var scene = load("res://card.tscn")
	var card: Card = scene.instantiate()
	await card._load_from_script(card_script)
	return card


func replace_script(card_script: Dictionary) -> void:
	_load_from_script(card_script)


func animate_to(to_global_position: Vector2, to_scale: Vector2, to_rotation: float, to_visibility: bool, duration: float) -> void:
	if not has_transform_checkpoint():
		_old_global_position = to_global_position
		_old_scale = to_scale
		_old_rotation = to_rotation

	if _tween != null and _tween.is_running():
		duration = max(duration, _tween_duration - _tween.get_total_elapsed_time())
		_tween.kill()
		_tween = null

	_tween_duration = duration

	visible = to_visibility

	_tween = create_tween().set_parallel().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "global_position", to_global_position, duration).from(_old_global_position)
	_tween.tween_property(self, "scale", to_scale, duration).from(_old_scale)
	_tween.tween_property(self, "rotation", to_rotation, duration).from(_old_rotation)

	global_position = _old_global_position
	scale = _old_scale
	rotation = _old_rotation

	_old_rotation = -INF


func has_transform_checkpoint() -> bool:
	return _old_rotation != -INF


func checkpoint_transform_if_missing() -> Card:
	return self if has_transform_checkpoint() else checkpoint_transform()


func checkpoint_transform() -> Card:
	_old_global_position = global_position
	_old_scale = scale
	_old_rotation = rotation
	return self


func is_playable(env: ScriptInterpreter.ScriptEnvironment) -> bool:
		if get_play_cost() > env.global_vars["gp"]:
			return false

		env.self_object = self

		if env.has_local != (_card_script["TARGET"] == "local"):
			return false

		var conditions: Array[ScriptInterpreter.ScriptNode] = _card_script["CONDITION"]

		for condition in conditions:
			if not await condition.evaluate([], env):
				return false

		return true


func play(env: ScriptInterpreter.ScriptEnvironment) -> ScriptInterpreter.ScriptEnvironment:
	env.self_object = self

	var new_env = env.duplicate()

	var effects: Array[ScriptInterpreter.ScriptNode] = _card_script["EFFECT"]

	for effect in effects:
		await effect.evaluate([], new_env)

	return new_env


func on_turn_start(env: ScriptInterpreter.ScriptEnvironment) -> ScriptInterpreter.ScriptEnvironment:
	env.self_object = self

	if not _card_script.has("ON-TURN-START"):
		return env

	for action: ScriptInterpreter.ScriptNode in _card_script["ON-TURN-START"]:
		await action.evaluate([], env)

	return env


func on_turn_end(env: ScriptInterpreter.ScriptEnvironment) -> ScriptInterpreter.ScriptEnvironment:
	env.self_object = self

	if not _card_script.has("ON-TURN-END"):
		return env

	for action: ScriptInterpreter.ScriptNode in _card_script["ON-TURN-END"]:
		await action.evaluate([], env)

	return env


func discard_on_play() -> bool:
	return not _suppress_discard


func get_tags() -> Array[String]:
	return _tags


func is_sticky() -> bool:
	return _is_sticky


func is_autoplay_start() -> bool:
	return _is_autoplay_start


func is_autoplay_end() -> bool:
	return _is_autoplay_end


func get_play_cost() -> int:
	return _base_play_cost + _extra_play_cost


func get_play_count() -> int:
	return _play_count


func get_card_name() -> String:
	return _name


func increment_play_count() -> bool:
	_play_count += 1
	return _play_count != _total_play_count


func shop_cost(env: ScriptInterpreter.ScriptEnvironment) -> int:
	var cost_func: ScriptInterpreter.ScriptNode = _card_script["SHOP-COST"]
	return await cost_func.evaluate([], env)


func set_extra_play_cost(extra_play_cost: int) -> void:
	_extra_play_cost = extra_play_cost
	_play_cost_label.text = str(_base_play_cost + extra_play_cost)


func increment_age() -> void:
	_age += 1


func get_age() -> int:
	return _age


func set_clicked(state: bool) -> void:
	_click_outline.visible = state


func set_hovered(state: bool) -> void:
	_hover_outline.visible = state


func set_disabled(state: bool) -> void:
	_is_disabled = state
	_disable_outline.visible = state


func is_disabled() -> bool:
	return _is_disabled


func get_card_container() -> CardContainer2D:
	var parent: Node = get_parent()
	if parent == null:
		return null
	
	var grandparent = parent.get_parent()
	return grandparent if grandparent != null and grandparent is CardContainer2D else null


func reset_graphics() -> void:
	set_clicked(false)
	set_hovered(false)
	set_disabled(false)
	z_index = 0


func _load_from_script(card_script: Dictionary) -> void:
	if card_script.has("TAGS"):
		_tags.assign(card_script["TAGS"])

	_card_script = card_script
	_name = card_script["NAME"]
	_total_play_count = int(card_script.get("USES")) if card_script.has("USES") else DEFAULT_CARD_USES
	_suppress_discard = _tags.has("keep-on-play")
	_is_sticky = _tags.has("sticky")

	get_node("scale_container/display_name_container/display_name").text = card_script["DISPLAYNAME"]
	get_node("scale_container/description_container/description").text = card_script["DESCRIPTION"]
	get_node("scale_container/artwork").texture = load("res://assets/card images/" + card_script["IMAGE"] + ".png")

	_hover_outline = get_node("scale_container/hover_outline")
	_click_outline = get_node("scale_container/click_outline")
	_disable_outline = get_node("scale_container/disable_outline")
	_play_cost_label = get_node("scale_container/play_cost_container/play_cost_label")

	var play_cost_func: ScriptInterpreter.ScriptNode = card_script["PLAY-COST"]
	_base_play_cost = await play_cost_func.evaluate([], null)
	_play_cost_label.text = str(_base_play_cost)


func _on_collider_gui_input(event: InputEvent) -> void:
	input.emit(self, event)


func _on_collider_mouse_entered() -> void:
	mouse.emit(self, true)


func _on_collider_mouse_exited() -> void:
	mouse.emit(self, false)
