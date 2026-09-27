class_name MapData
extends RefCounted

var schema_version: int = 1
var territories: Dictionary = {}
var regions: Dictionary = {}

func add_region(region: RegionDefinition) -> void:
	regions[region.id] = region

func add_territory(territory: TerritoryDefinition) -> void:
	territories[territory.id] = territory

func get_territory(territory_id: String) -> TerritoryDefinition:
	return territories.get(territory_id) as TerritoryDefinition

func get_region(region_id: String) -> RegionDefinition:
	return regions.get(region_id) as RegionDefinition

func are_neighbors(a_id: String, b_id: String) -> bool:
	var territory := get_territory(a_id)
	return territory != null and b_id in territory.neighbors

func territory_ids_for_region(region_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	for territory: TerritoryDefinition in territories.values():
		if territory.region_id == region_id:
			result.append(territory.id)
	return result
