class_name MapVisualValidator
extends RefCounted

static func validate(map_data: MapData, visuals: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if map_data == null:
		errors.append("map_data is null")
		return errors
	if visuals == null:
		errors.append("visual definitions are null")
		return errors
	if visuals.size() != 42:
		errors.append("expected exactly 42 visual definitions, got %d" % visuals.size())
	if map_data.regions.size() != 6:
		errors.append("expected exactly 6 regions, got %d" % map_data.regions.size())
	for territory_id: String in map_data.territories:
		var visual := visuals.get(territory_id) as TerritoryVisualDefinition
		if visual == null:
			errors.append("missing visual definition for %s" % territory_id)
			continue
		if visual.territory_id != territory_id:
			errors.append("visual territory id mismatch for %s" % territory_id)
		if visual.polygon.size() < 3:
			errors.append("territory %s polygon has fewer than 3 points" % territory_id)
		if not Rect2(Vector2.ZERO, MapVisualDefinition.MAP_SIZE).has_point(visual.label_position):
			errors.append("territory %s label position is outside map bounds" % territory_id)
		if not Rect2(Vector2.ZERO, MapVisualDefinition.MAP_SIZE).has_point(visual.marker_position):
			errors.append("territory %s marker position is outside map bounds" % territory_id)
	for visual_id: String in visuals:
		if not map_data.territories.has(visual_id):
			errors.append("visual references unknown territory %s" % visual_id)
	return errors

static func is_valid(map_data: MapData, visuals: Dictionary) -> bool:
	return validate(map_data, visuals).is_empty()
