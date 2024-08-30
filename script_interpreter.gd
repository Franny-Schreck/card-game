# Card Interpreter by Alexander Ripar:
# https://github.com/AlexanderRipar/gd-card-lisp

class_name ScriptInterpreter
extends Node


@export var script_prefix: String

var custom_operators: Dictionary

var custom_data: Dictionary


class ScriptNode:
	var package_name: String = ""

	var token: String
	
	var arg_count: int

	var filename: String

	var line_number: int
	
	var line_offset: int

	func init_helper(arg_count_: int, token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		self.token = token_
		self.arg_count = arg_count_
		self.filename = filename_
		self.line_number = line_number_
		self.line_offset = line_offset_
		return self

	static func create(_token: String, _filename: String, _line_number: int, _line_offset: int) -> ScriptNode:
		assert(false, "Called abstract function ScriptNode.create")
		return null

	func evaluate(_args: Array[ScriptTree], _env: ScriptEnvironment) -> int:
		assert(false, "Called abstract function ScriptNode.evaluate")
		return 0


class ScriptNodeSet extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeSet.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		assert(args[0].node is ScriptNodeVariable, "First argument of 'set' operator must be a variable")
		return args[0].node.set_value(env, args[1].evaluate(env))


class ScriptNodeGetAndSet extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeGetAndSet.new().init_helper(3, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		assert(args[0].node.arg_count == 2 and args[0].subtrees.size() == 0)
		assert(args[1].node is ScriptNodeVariable, "First argument of 'set' operator must be a variable")
		return args[1].node.set_value(env, args[0].node.evaluate([args[1], args[2]], env))


class ScriptNodeVariable extends ScriptNode:
	var is_local: bool

	var variable_name: String

	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		assert(token_[0] == '%' || token_[0] == '$', "Unexpected variable name '" + token_ + "'. Should start with '$' or '%'")
		var node = ScriptNodeVariable.new().init_helper(0, token_, filename_, line_number_, line_offset_)
		node.is_local = token_.begins_with('%')
		node.variable_name = token_.substr(1)
		return node

	func set_value(env, value: int) -> int:
		if is_local:
			env.target_vars[variable_name] = value
		else:
			env.global_vars[variable_name] = value
		return value
		

	func evaluate(_args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		if is_local:
			return env.target_vars[variable_name]
		else:
			return env.global_vars[variable_name]


class ScriptNodeConstant extends ScriptNode:
	var value: int

	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		var node = ScriptNodeConstant.new().init_helper(0, token_, filename_, line_number_, line_offset_)
		if token_ == "true":
			node.value = 1
		elif token_ == "false" or token_ == "pass":
			node.value = 0
		else:
			node.value = int(token_)
		return node

	func evaluate(_args: Array[ScriptTree], _env: ScriptEnvironment) -> int:
		return value


class ScriptNodeIf extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeIf.new().init_helper(3, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		if args[0].evaluate(env) != 0:
			return args[1].evaluate(env)
		else:
			return args[2].evaluate(env)


class ScriptNodeCompEqual extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompEqual.new().init_helper(2, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) == args[1].evaluate(env) else 0


class ScriptNodeCompNotEqual extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompNotEqual.new().init_helper(2, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) != args[1].evaluate(env) else 0


class ScriptNodeCompLessThan extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompLessThan.new().init_helper(2, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) < args[1].evaluate(env) else 0


class ScriptNodeCompLessThanOrEqual extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompLessThanOrEqual.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) <= args[1].evaluate(env) else 0


class ScriptNodeCompGreaterThan extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompGreaterThan.new().init_helper(2, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) > args[1].evaluate(env) else 0


class ScriptNodeCompGreaterThanOrEqual extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeCompGreaterThanOrEqual.new().init_helper(2, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) >= args[1].evaluate(env) else 0


class ScriptNodeNot extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeAnd.new().init_helper(1, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return 1 if args[0].evaluate(env) == 0 else 0


class ScriptNodeAnd extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeAnd.new().init_helper(-1, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		for arg in args:
			if arg.evaluate(env) == 0:
				return 0
		return 1


class ScriptNodeOr extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeOr.new().init_helper(-1, token_, filename_, line_number_, line_offset_)
		
	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		for arg in args:
			if arg.evaluate(env) == 1:
				return 1
		return 0


class ScriptNodeAdd extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeAdd.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return args[0].evaluate(env) + args[1].evaluate(env)


class ScriptNodeSub extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeSub.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return args[0].evaluate(env) - args[1].evaluate(env)


class ScriptNodeMul extends ScriptNode:
	static func create(token_: String, filename_: String, line_number_: int, line_offset_: int) -> ScriptNode:
		return ScriptNodeMul.new().init_helper(2, token_, filename_, line_number_, line_offset_)

	func evaluate(args: Array[ScriptTree], env: ScriptEnvironment) -> int:
		return args[0].evaluate(env) * args[1].evaluate(env)


class ScriptEnvironment:
	var has_target: bool

	var target_vars: Dictionary

	var global_vars: Dictionary

	var package_data: Dictionary

	static func create(has_target_: bool, target_vars_: Dictionary, global_vars_: Dictionary, package_data_) -> ScriptEnvironment:
		var env = ScriptEnvironment.new()
		env.has_target = has_target_
		env.target_vars = target_vars_
		env.global_vars = global_vars_
		env.package_data = package_data_
		return env

	func duplicate() -> ScriptEnvironment:
		return ScriptEnvironment.create(has_target, target_vars.duplicate(), global_vars.duplicate(), package_data)


class ScriptBlock:
	var script_name: String
	
	var display_name: String
	
	var description: String
	
	var image_path: String

	var tags: Array[String]
	
	var needs_target: bool

	var condition: ScriptTree
	
	var effects: Array[ScriptTree]

	func is_applicable(env: ScriptEnvironment) -> bool:
		return env.has_target == needs_target and condition.evaluate(env) != 0

	func apply(env: ScriptEnvironment) -> ScriptEnvironment:
		var new_env = env.duplicate()

		for effect in effects:
			effect.evaluate(new_env)

		return new_env


class ScriptTree:
	var node: ScriptNode
	
	var subtrees: Array[ScriptTree]
	
	func evaluate(env: ScriptEnvironment) -> int:
		return node.evaluate(subtrees, env)


class ScriptLocation:
	var filename: String
	
	var line_number: int
	
	var character_number: int
	
	func _to_string() -> String:
		return filename + ":" + str(line_number) + ":" + str(character_number)


class ParseState:
	const DEFAULT_OPERATORS: Dictionary = {
		"setf": ScriptNodeGetAndSet,
		"set": ScriptNodeSet,
		"pass": ScriptNodeConstant,
		"true": ScriptNodeConstant,
		"false": ScriptNodeConstant,
		"if": ScriptNodeIf,
		"==": ScriptNodeCompEqual,
		"!=": ScriptNodeCompNotEqual,
		"<": ScriptNodeCompLessThan,
		"<=": ScriptNodeCompLessThanOrEqual,
		">": ScriptNodeCompGreaterThan,
		">=": ScriptNodeCompGreaterThanOrEqual,
		"not": ScriptNodeNot,
		"and": ScriptNodeAnd,
		"or": ScriptNodeOr,
		"+": ScriptNodeAdd,
		"-": ScriptNodeSub,
		"*": ScriptNodeMul,
	}
	
	var operators: Dictionary

	var text: String
	
	var index: int
	
	var line_number: int

	var line_start: int

	var curr: String

	var filename: String

	var has_curr: bool
	
	var error: String

	static func create(script_name_: String, custom_operators: Dictionary) -> ParseState:
		var file = FileAccess.open("res://" + script_name_, FileAccess.READ)

		if file == null:
			print("Could not open script file ", script_name_, " ", FileAccess.get_open_error())
			return null

		var state = ParseState.new()
		state.operators = DEFAULT_OPERATORS.duplicate()
		state.operators.merge(custom_operators)
		state.text = file.get_as_text()
		state.index = 0
		state.line_number = 0
		state.line_start = 0
		state.curr = ""
		state.filename = script_name_
		state.has_curr = false

		return state


	func is_whitespace(character: String) -> bool:
		return character == ' ' or character == '\t' or character == '\n' or character == '\r'


	func skip_whitespace() -> void:
		while index < text.length() and is_whitespace(text[index]):
			if text[index] == '\n':
				line_number += 1
				line_start = index + 1

			index += 1


	func has_token() -> bool:
		return has_curr


	func next_token() -> bool:
		skip_whitespace()

		if index == text.length():
			error = "Reached end of file"
			has_curr = false
			return false

		while text[index] == '#':
			while index < text.length() and text[index] != '\n':
				index += 1

			skip_whitespace()

			if index == text.length():
				error = "Reached end of file"
				has_curr = false
				return false

		if text[index] == '(' or text[index] == ')':
			curr = text[index]
			index += 1
		elif text[index] == '"':
			index += 1

			var begin = index

			while index < text.length() and text[index] != '"':
				if text[index] == '\r' or text[index] == '\n':
					error = "string missing closing delimiter '\"'"
					has_curr = false
					return false
				index += 1

			if index == text.length():
				error = "string missing closing delimiter '\"'"
				has_curr = false
				return false

			curr = text.substr(begin, index - begin)

			index += 1
		else:
			var begin = index

			while index < text.length() and not is_whitespace(text[index]) and text[index] != '(' and text[index] != ')':
				index += 1

			curr = text.substr(begin, index - begin)

		has_curr = true
		return true


	func location() -> ScriptLocation:
		var loc: ScriptLocation = ScriptLocation.new()
		loc.filename = filename
		loc.line_number = line_number + 1
		loc.character_number = index - line_start
		return loc


func define_package(package_name: String, operators: Dictionary, data: Variant) -> void:
	custom_operators.merge(operators)
	
	custom_data[package_name] = data


func parse_script_node(state: ParseState) -> ScriptNode:
	var operator: GDScript = state.operators.get(state.curr)

	var node: ScriptNode

	if operator != null:
		node = operator.create(state.curr, state.filename, state.line_number, state.index - state.line_start)
	elif state.curr.is_valid_int():
		node = ScriptNodeConstant.create(state.curr, state.filename, state.line_number, state.index - state.line_start)
	elif state.curr.begins_with('$') or state.curr.begins_with('%'):
		node = ScriptNodeVariable.create(state.curr, state.filename, state.line_number, state.index - state.line_start)
	else:
		print(state.location(), ": Unexpected token '", state.curr, "'")
		return null

	state.next_token()

	return node


func parse_script_tree(state: ParseState) -> ScriptTree:
	var tree: ScriptTree = ScriptTree.new()

	if state.curr == ")":
		print(state.location(), ": Mismatched closing parenthesis")
		return null
	elif state.curr == "(":
		if not state.next_token():
			print(state.location(), ": End of script after opening parenthesis")
			return null

		tree.node = parse_script_node(state)
		
		if tree.node == null:
			return null
			
		if not state.has_token():
			print(state.location(), ": End of script after operator")
			return null
			
		var args: Array[ScriptTree] = []
			
		while state.curr != ")":
			var arg = parse_script_tree(state)

			if arg == null:
				return null
				
			args.append(arg)

			if not state.has_token():
				print(state.location(), ": End of script with unclosed parentheses")
				return null

		state.next_token()

		if tree.node.arg_count != -1 and args.size() != tree.node.arg_count:
			print(state.location(), ": Operator '", tree.node.token, "' expects ", tree.node.arg_count, " operands but got ", args.size())
			return null
			
		tree.subtrees = args

		return tree
	else:
		tree.node = parse_script_node(state)

		if tree.node == null:
			return null

		return tree


func package_data() -> Dictionary:
	return custom_data

func parse_single_token_property(property_name: String, state: ParseState) -> bool:
	if not state.next_token():
		print(state.location(), ": Expected '", property_name, "' script property but got ", state.error)
		return false
	elif state.curr != property_name:
		print(state.location(), ": Expected '", property_name, "' script property but got '", state.curr, "'")
		return false
	
	if not state.next_token():
		print(state.location(), ": Expected script name after '", property_name, "' script property but got ", state.error)
		return false
		
	return true

func parse_script(script_name: String) -> ScriptBlock:
	var state: ParseState = ParseState.create(script_prefix + script_name, custom_operators)

	if state == null:
		return null

	var script = ScriptBlock.new()

	if not parse_single_token_property("NAME", state):
		return null

	script.script_name = state.curr
	
	if not parse_single_token_property("DISPLAYNAME", state):
		return null
		
	script.display_name = state.curr

	if not parse_single_token_property("DESCRIPTION", state):
		return null
		
	script.description = state.curr

	if not parse_single_token_property("IMAGE-PATH", state):
		return null
		
	script.image_path = state.curr

	if not state.next_token():
		print(state.location(), ": Expected 'TARGET' or 'TAGS' script property but got ", state.error)
		return null
	
	var has_tags: bool = state.curr == "TAGS"
	
	if has_tags:
		while state.next_token() != null:
			if state.curr == "TARGET":
				break
			script.tags.append(state.curr)

	if state.curr != "TARGET":
		print(state.location(), ": Expected ", "" if has_tags else "'TAGS' or ", "'TARGET' script property but got '", state.curr, "'")
		return null

	if not state.next_token():
		print(state.location(), ": Expected 'global' or 'district' after 'TARGET' script property but got ", state.error)
		return null
	elif state.curr == "global":
		script.needs_target = false
	elif state.curr == "district":
		script.needs_target = true
	else:
		print(state.location(), ": Unknown value '", state.curr, "' for 'TARGET' script property")
		return null

	if not state.next_token():
		print(state.location(), ": Expected 'CONDITION' script property but got ", state.error)
		return null
	elif state.curr != "CONDITION":
		print(state.location(), ": Expected 'CONDITION' script property but got '", state.curr, "'")
		return null
	elif not state.next_token():
		print(state.location(), ": Expected expression after 'CONDITION' script property")
		return null

	script.condition = parse_script_tree(state)

	if script.condition == null:
		return null

	if not state.has_token():
		print(state.location(), ": Expected 'EFFECT' script property but got ", state.error)
		return null
	elif state.curr != "EFFECT":
		print(state.location(), ": Expected 'EFFECT' script property but got '", state.curr, "'")
		return null
	elif not state.next_token():
		print(state.location(), ": Expected expressions after 'CONDITION' script property")
		return null

	while state.has_token():
		var effect = parse_script_tree(state)

		if effect == null:
			return null

		script.effects.append(effect)

	return script
