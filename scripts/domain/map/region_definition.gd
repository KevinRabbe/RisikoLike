class_name RegionDefinition
extends RefCounted

var id: String
var name_de: String
var bonus: int
var expected_territory_count: int

func _init(p_id: String, p_name_de: String, p_bonus: int, p_expected_territory_count: int) -> void:
	id = p_id
	name_de = p_name_de
	bonus = p_bonus
	expected_territory_count = p_expected_territory_count
