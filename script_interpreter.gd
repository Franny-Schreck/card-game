# Card Interpreter by Alexander Ripar:
# https://github.com/AlexanderRipar/gd-card-lisp

class_name ScriptInterpreter
extends Node


var custom_operators: Dictionary


class ScriptNode:
	var arg_count: int

	func init_helper(arg_count_: int) -> ScriptNode:
		self.arg_count = arg_count_
		return self

	static func create(_token: String) -> ScriptNode:
		assert(false, "Called abstract function ScriptNode.create")
		return null

	func evaluate(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		assert(args.size() == self.arg_count or self.arg_count == -1, "Expected " + str(self.arg_count) + " arguments but got " + str(args.size()))
		return evaluate_impl(args, env)

	func evaluate_impl(_args: Array[ScriptNode], _env: ScriptEnvironment) -> Variant:
		assert(false, "Called abstract function ScriptNode.evaluate_impl")
		return null
		
	func evaluate_self(_env: ScriptEnvironment) -> Variant:
		return self


class _ScriptNodeExternal extends ScriptNode:
	var function: Callable

	static func create_external(function_: Callable, arg_count_: int) -> _ScriptNodeExternal:
		var node = _ScriptNodeExternal.new().init_helper(arg_count_)
		node.function = function_
		return node
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		return function.call(args, env)


class _ScriptNodeTree extends ScriptNode:
	var subtrees: Array[ScriptNode]

	static func create_tree(subtrees_: Array[ScriptNode]) -> _ScriptNodeTree:
		var node = _ScriptNodeTree.new().init_helper(0)
		node.subtrees = subtrees_
		return node
		
	func evaluate_impl(_args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		if subtrees.size() == 0:
			return null
		else:
			return subtrees[0].evaluate_self(env).evaluate(subtrees.slice(1), env)

	func evaluate_self(env: ScriptEnvironment) -> Variant:
		return evaluate_impl([], env)


class _ScriptNodeSelf extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeSelf.new().init_helper(0)

	func evaluate_impl(_args: Array[ScriptNode], env: ScriptEnvironment) -> Object:
		return env.self_object


class _ScriptNodeIf extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeIf.new().init_helper(3)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		if args[0].evaluate([], env) != 0:
			return args[1].evaluate([], env)
		else:
			return args[2].evaluate([], env)


class _ScriptNodeList extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeList.new().init_helper(3)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		var result = []
		for arg in args:
			result.push_back(arg.evaluate([], env))
		return result


class _ScriptNodeSet extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeSet.new().init_helper(2)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		var variable_ref = args[0].evaluate_self(env)
		return variable_ref.set_value(env, args[1].evaluate([], env))


class _ScriptNodeGetAndSet extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeGetAndSet.new().init_helper(3)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		var operator = args[0].evaluate_self(env)
		var variable_ref = args[1].evaluate_self(env)
		var new_value = operator.evaluate(ScriptInterpreter._args_array([variable_ref, args[2]]), env)
		variable_ref.set_value(env, new_value)
		return new_value


class _ScriptNodeVariable extends ScriptNode:
	var is_local: bool

	var variable_name: String

	static func create(token: String) -> ScriptNode:
		assert(token[0] == '%' || token[0] == '$', "Unexpected variable name '" + token + "'. Should start with '$' or '%'")
		var node = _ScriptNodeVariable.new().init_helper(0)
		node.is_local = token.begins_with('%')
		node.variable_name = token.substr(1)
		return node

	func set_value(env: ScriptEnvironment, value: Variant) -> Variant:
		if is_local:
			assert(env.has_local and env.local_vars.has(variable_name))
			env.local_vars[variable_name] = value
		else:
			assert(env.global_vars.has(variable_name))
			env.global_vars[variable_name] = value
		return value

	func evaluate_impl(_args: Array[ScriptNode], env: ScriptEnvironment) -> int:
		if is_local:
			return env.local_vars[variable_name]
		else:
			return env.global_vars[variable_name]


class _ScriptNodeConstant extends ScriptNode:
	var value: Variant

	static func create(token: String) -> ScriptNode:
		var node = _ScriptNodeConstant.new().init_helper(0)
		if token[0] == '"':
			node.value = token.substr(1, token.length() - 2)
		elif token == "true":
			node.value = true
		elif token == "false":
			node.value = false
		elif token.contains('.'):
			node.value = float(token)
		else:
			node.value = int(token)
		return node

	func evaluate_impl(_args: Array[ScriptNode], _env: ScriptEnvironment) -> Variant:
		return value


class _ScriptNodeCompEqual extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompEqual.new().init_helper(2)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) == args[1].evaluate([], env)


class _ScriptNodeCompNotEqual extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompNotEqual.new().init_helper(2)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) != args[1].evaluate([], env)


class _ScriptNodeCompLessThan extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompLessThan.new().init_helper(2)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) < args[1].evaluate([], env)


class _ScriptNodeCompLessThanOrEqual extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompLessThanOrEqual.new().init_helper(2)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) >= args[1].evaluate([], env)


class _ScriptNodeCompGreaterThan extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompGreaterThan.new().init_helper(2)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) > args[1].evaluate([], env)


class _ScriptNodeCompGreaterThanOrEqual extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeCompGreaterThanOrEqual.new().init_helper(2)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return args[0].evaluate([], env) >= args[1].evaluate([], env)


class _ScriptNodeNot extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeAnd.new().init_helper(1)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		return not args[0].evaluate([], env)


class _ScriptNodeAnd extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeAnd.new().init_helper(-1)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		for arg in args:
			if not arg.evaluate([], env):
				return false
		return true


class _ScriptNodeOr extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeOr.new().init_helper(-1)
		
	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> bool:
		for arg in args:
			if arg.evaluate([], env):
				return true
		return false


class _ScriptNodeAdd extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeAdd.new().init_helper(2)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> Variant:
		var first_arg = args[0].evaluate([], env)
		if first_arg is Array:
			var result: Array = first_arg.duplicate()
			result.append_array(args[1].evaluate([], env))
			return result
		return first_arg + args[1].evaluate([], env)


class _ScriptNodeSub extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeSub.new().init_helper(2)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> int:
		return args[0].evaluate([], env) - args[1].evaluate([], env)


class _ScriptNodeMul extends ScriptNode:
	static func create(_token: String) -> ScriptNode:
		return _ScriptNodeMul.new().init_helper(2)

	func evaluate_impl(args: Array[ScriptNode], env: ScriptEnvironment) -> int:
		return args[0].evaluate([], env) * args[1].evaluate([], env)


class CustomOperator:
	var operator: String
	var function: Callable
	var arg_count: int

	static func create(operator_: String, function_: Callable, arg_count_: int) -> CustomOperator:
		var op = CustomOperator.new()
		op.operator = operator_
		op.function = function_
		op.arg_count = arg_count_
		return op


class ScriptProperty:
	var property_name: String
	var required: bool
	var multiple: bool
	var pattern: RegEx
	var is_code: bool

	static func create(property_name_: String, required_: bool = true, multiple_: bool = false, pattern_: String = "", is_code_: bool = false) -> ScriptProperty:
		var property = ScriptProperty.new()
		property.property_name = property_name_
		property.required = required_
		property.multiple = multiple_
		property.pattern = null if pattern_ == "" else RegEx.create_from_string("^" + pattern_ + "$")
		property.is_code = is_code_
		return property


class ScriptEnvironment:
	var has_local: bool
	var local_vars: Dictionary
	var global_vars: Dictionary
	var self_object: Object

	static func create(has_local_: bool, local_vars_: Dictionary, global_vars_: Dictionary, self_object_: Object = null) -> ScriptEnvironment:
		var env = ScriptEnvironment.new()

		env.has_local = has_local_
		env.local_vars = local_vars_
		env.global_vars = global_vars_
		env.self_object = self_object_

		return env


	func duplicate() -> ScriptEnvironment:
		return ScriptEnvironment.create(has_local, local_vars.duplicate(), global_vars.duplicate(), self_object)


class _ParseState:
	const BUILTIN_OPERATORS: Dictionary = {
		"if" = _ScriptNodeIf,
		"self" = _ScriptNodeSelf,
		"." = _ScriptNodeList,
		"setf" = _ScriptNodeGetAndSet,
		"set" = _ScriptNodeSet,
		"==" = _ScriptNodeCompEqual,
		"!=" = _ScriptNodeCompNotEqual,
		"<" = _ScriptNodeCompLessThan,
		"<=" = _ScriptNodeCompLessThanOrEqual,
		">" = _ScriptNodeCompGreaterThan,
		">=" = _ScriptNodeCompGreaterThanOrEqual,
		"not" = _ScriptNodeNot,
		"and" = _ScriptNodeAnd,
		"or" = _ScriptNodeOr,
		"+" = _ScriptNodeAdd,
		"-" = _ScriptNodeSub,
		"*" = _ScriptNodeMul,
	}

	var debug_script_name: String

	var custom_operators: Dictionary

	var properties: Dictionary

	var text: String

	var index: int

	var line_number: int

	var line_start: int

	var curr: String

	var has_curr: bool

	var error: String


	func _is_whitespace(character: String) -> bool:
		return character == ' ' or character == '\t' or character == '\n' or character == '\r'


	func _skip_whitespace() -> void:
		while index < text.length() and _is_whitespace(text[index]):
			if text[index] == '\n':
				line_number += 1
				line_start = index + 1

			index += 1


	func _print_error(messsage: String) -> void:
		print(debug_script_name, ":", line_number, ":", (index - line_start + 1), " - ", messsage)


	func _has_token() -> bool:
		return has_curr


	func _next_token() -> bool:
		_skip_whitespace()

		if index == text.length():
			error = "Reached end of file"
			has_curr = false
			return false

		while text[index] == '#':
			while index < text.length() and text[index] != '\n':
				index += 1

			_skip_whitespace()

			if index == text.length():
				error = "Reached end of file"
				has_curr = false
				return false

		if text[index] == '(' or text[index] == ')':
			curr = text[index]
			index += 1
		elif text[index] == '"':
			var begin = index

			index += 1

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

			index += 1

			curr = text.substr(begin, index - begin)
		else:
			var begin = index

			while index < text.length() and not _is_whitespace(text[index]) and text[index] != '(' and text[index] != ')':
				index += 1

			curr = text.substr(begin, index - begin)

		has_curr = true
		return true


	static func create(debug_script_name_: String, code_: String, custom_operators_: Dictionary, script_properties_: Array[ScriptProperty]) -> _ParseState:
		var state: _ParseState = _ParseState.new()

		state.debug_script_name = debug_script_name_
		state.custom_operators = custom_operators_
		state.text = code_
		state.index = 0
		state.line_number = 1
		state.line_start = 0
		state.curr = ""
		state.has_curr = false

		for script_property in script_properties_:
			state.properties[script_property.property_name] = script_property

		if not state._next_token():
			state._print_error("Cannot parse empty script")
			return null

		return state


	func parse_script_node(is_root: bool = false) -> ScriptNode:
		var subtrees: Array[ScriptNode] = []

		var node: ScriptNode

		if curr == ")":
			_print_error("Mismatched closing parenthesis")
			return null
		elif curr == "(":
			if not _next_token():
				_print_error("End of script after opening parenthesis")
				return null

			while curr != ")":
				var subtree: ScriptNode = parse_script_node()

				if subtree == null:
					return null
					
				subtrees.append(subtree)

				if not _has_token():
					_print_error("End of script with unclosed parentheses")
					return null

			node = _ScriptNodeTree.create_tree(subtrees)
		elif curr[0] == '$' or curr[0] == '%':
			node = _ScriptNodeVariable.create(curr)
		elif curr[0] == '"' or curr == "true" or curr == "false" or curr.is_valid_int() or curr.is_valid_float():
			node = _ScriptNodeConstant.create(curr)
		else:
			var operator: GDScript = BUILTIN_OPERATORS.get(curr)

			if operator != null:
				node = operator.create(curr)
			else:
				var custom_operator: CustomOperator = custom_operators.get(curr)

				if custom_operator == null:
					_print_error("Unexpected token '" +  curr + "'")
					return null

				node = _ScriptNodeExternal.create_external(custom_operator.function, custom_operator.arg_count)

		_next_token()
		
		if is_root and _has_token():
			_print_error("Trailing text after end of script node")
			return null

		return node


	func parse_script() -> Dictionary:
		var script: Dictionary = {}

		while _has_token():
			if curr[0] != '{' or curr[-1] != '}':
				_print_error("Expected property identifer (in {} or []), but got '" + curr + "'")
				return {}
	
			var property_name: String = curr.substr(1, curr.length() - 2)
	
			var property: ScriptProperty = properties.get(property_name)

			if property == null:
				_print_error("Unknown property identifer '" + curr + "'")
				return {}

			_next_token()

			var strings: Array[String] = []

			var nodes: Array[ScriptNode] = []

			while _has_token():
				if curr[0] == '{':
					break
				elif property.is_code:
					var node = parse_script_node()
					if node == null:
						return {}
					nodes.append(node)
				elif curr[0] == '"':
					var string: String = curr.substr(1, curr.length() - 2)
					if property.pattern != null and not property.pattern.search(string):
						_print_error("Value '" + string + "' for the property '" + property_name + "' does not match the pattern '" + property.pattern.get_pattern() + "'")
						return {}
					strings.append(string)
					_next_token()
				else:
					_print_error("Expected value(s) for {" + property_name + "} property, but got " + curr)
					return {}

				if not property.multiple:
					break

			if nodes.size() == 0 and strings.size() == 0:
					_print_error("Expected value(s) for {" + property_name + "} property, but got '" + curr + "'")
					return {}

			if property.is_code:
				if property.multiple:
					script[property_name] = nodes
				else:
					script[property_name] = nodes[0]
			else:
				if property.multiple:
					script[property_name] = strings
				else:
					script[property_name] = strings[0]

		for property_name in properties.keys():
			if not script.has(property_name) and properties[property_name].required:
				_print_error("Missing required script property" + property_name)
				return {}

		return script


static func _args_array(args: Array) -> Array[ScriptNode]:
	var typed: Array[ScriptNode] = []
	typed.assign(args)
	return typed


func define_operators(custom_operators_: Array[CustomOperator]) -> void:
	for custom_operator in custom_operators_:
		if custom_operators.has(custom_operator.operator):
			print("Warning: Redefining custom operator ", custom_operator.operator)

		custom_operators[custom_operator.operator] = custom_operator


func load_script(debug_name: String, code: String, properties: Array[ScriptProperty]) -> Dictionary:
	var state = _ParseState.create(debug_name, code, custom_operators, properties)

	if state == null:
		return {}

	return state.parse_script()


func load_script_node(debug_name: String, code: String) -> ScriptNode:
	var state = _ParseState.create(debug_name, code, custom_operators, [])

	if state == null:
		return null

	var node: ScriptNode = state.parse_script_node()

	return node
