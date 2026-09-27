class_name RandomSource
extends RefCounted

var _rng := RandomNumberGenerator.new()
var _controlled_rolls: Array[int] = []

func _init(seed_value: int = 0) -> void:
	if seed_value == 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value

func next_int(min_value: int, max_value: int) -> int:
	return _rng.randi_range(min_value, max_value)

func roll_d6() -> int:
	if not _controlled_rolls.is_empty():
		return clampi(_controlled_rolls.pop_front(), 1, 6)
	return next_int(1, 6)

func set_controlled_rolls(values: Array[int]) -> void:
	_controlled_rolls = values.duplicate()

func shuffle(values: Array) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := next_int(0, index)
		var value = values[index]
		values[index] = values[swap_index]
		values[swap_index] = value
