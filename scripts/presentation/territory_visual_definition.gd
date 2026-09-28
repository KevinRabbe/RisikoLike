class_name TerritoryVisualDefinition
extends RefCounted

var territory_id: String
var polygon: PackedVector2Array
var label_position: Vector2
var marker_position: Vector2
var connection_anchors: Array

func _init(
		p_territory_id: String,
		p_polygon: PackedVector2Array,
		p_label_position: Vector2,
		p_marker_position: Vector2,
		p_connection_anchors: Array = []
	) -> void:
	territory_id = p_territory_id
	polygon = p_polygon
	label_position = p_label_position
	marker_position = p_marker_position
	connection_anchors = p_connection_anchors
