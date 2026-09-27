class_name TerritoryDefinition
extends RefCounted

var id: String
var name_de: String
var region_id: String
var neighbors: PackedStringArray
var card_symbol: String

func _init(p_id: String, p_name_de: String, p_region_id: String, p_neighbors: PackedStringArray, p_card_symbol: String) -> void:
	id = p_id
	name_de = p_name_de
	region_id = p_region_id
	neighbors = p_neighbors
	card_symbol = p_card_symbol
