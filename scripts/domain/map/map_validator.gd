class_name MapValidator
extends RefCounted

const EXPECTED_REGION_COUNTS := {
	"NA": 9,
	"SA": 4,
	"EU": 7,
	"AF": 6,
	"AS": 12,
	"OC": 4,
}
const VALID_SYMBOLS := ["infantry", "cavalry", "artillery"]

static func validate(map_data: MapData) -> PackedStringArray:
	var errors := PackedStringArray()
	if map_data == null:
		errors.append("map_data is null")
		return errors
	if map_data.territories.size() != 42:
		errors.append("expected exactly 42 territories, got %d" % map_data.territories.size())
	if map_data.regions.size() != EXPECTED_REGION_COUNTS.size():
		errors.append("expected exactly 6 regions, got %d" % map_data.regions.size())

	var symbol_counts := {"infantry": 0, "cavalry": 0, "artillery": 0}
	var region_counts := {}
	for territory_id: String in map_data.territories:
		var territory := map_data.get_territory(territory_id)
		if territory == null:
			errors.append("territory %s is null" % territory_id)
			continue
		if territory.id != territory_id:
			errors.append("territory dictionary key mismatch for %s" % territory_id)
		if not EXPECTED_REGION_COUNTS.has(territory.region_id):
			errors.append("territory %s references unknown region %s" % [territory.id, territory.region_id])
		region_counts[territory.region_id] = int(region_counts.get(territory.region_id, 0)) + 1
		if not VALID_SYMBOLS.has(territory.card_symbol):
			errors.append("territory %s has invalid card symbol %s" % [territory.id, territory.card_symbol])
		else:
			symbol_counts[territory.card_symbol] += 1
		if territory.neighbors.is_empty():
			errors.append("territory %s has no neighbors" % territory.id)
		var seen_neighbors := {}
		for neighbor_id: String in territory.neighbors:
			if seen_neighbors.has(neighbor_id):
				errors.append("territory %s lists neighbor %s twice" % [territory.id, neighbor_id])
			seen_neighbors[neighbor_id] = true
			if neighbor_id == territory.id:
				errors.append("territory %s has a self-neighbor" % territory.id)
			if not map_data.territories.has(neighbor_id):
				errors.append("territory %s references unknown neighbor %s" % [territory.id, neighbor_id])
			elif not map_data.get_territory(neighbor_id).neighbors.has(territory.id):
				errors.append("neighbor edge %s -> %s is not bidirectional" % [territory.id, neighbor_id])

	for region_id: String in EXPECTED_REGION_COUNTS:
		if not map_data.regions.has(region_id):
			errors.append("missing region %s" % region_id)
		else:
			var region := map_data.get_region(region_id)
			if region.expected_territory_count != EXPECTED_REGION_COUNTS[region_id]:
				errors.append("region %s declares %d territories, expected %d" % [region_id, region.expected_territory_count, EXPECTED_REGION_COUNTS[region_id]])
			if region.bonus < 0:
				errors.append("region %s has a negative bonus" % region_id)
			if int(region_counts.get(region_id, 0)) != EXPECTED_REGION_COUNTS[region_id]:
				errors.append("region %s has %d territories, expected %d" % [region_id, int(region_counts.get(region_id, 0)), EXPECTED_REGION_COUNTS[region_id]])
	for symbol: String in VALID_SYMBOLS:
		if int(symbol_counts[symbol]) != 14:
			errors.append("symbol %s has %d cards, expected 14" % [symbol, int(symbol_counts[symbol])])

	if not map_data.territories.is_empty() and not _is_connected(map_data, map_data.territories.keys(), ""):
		errors.append("territory graph is not connected")
	for region_id: String in EXPECTED_REGION_COUNTS:
		var ids := map_data.territory_ids_for_region(region_id)
		if not ids.is_empty() and not _is_connected(map_data, ids, region_id):
			errors.append("region %s is not internally connected" % region_id)
	return errors

static func is_valid(map_data: MapData) -> bool:
	return validate(map_data).is_empty()

static func _is_connected(map_data: MapData, ids, _region_id: String) -> bool:
	if ids.is_empty():
		return true
	var allowed := {}
	for territory_id in ids:
		allowed[territory_id] = true
	var visited := {}
	var queue: Array[String] = [str(ids[0])]
	while not queue.is_empty():
		var current: String = queue.pop_front()
		if visited.has(current):
			continue
		visited[current] = true
		var territory := map_data.get_territory(current)
		if territory == null:
			continue
		for neighbor_id: String in territory.neighbors:
			if allowed.has(neighbor_id) and not visited.has(neighbor_id):
				queue.append(neighbor_id)
	return visited.size() == allowed.size()
