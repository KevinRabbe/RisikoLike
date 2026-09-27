class_name MapDataFactory
extends RefCounted

static func create_default() -> MapData:
	var map_data := MapData.new()
	map_data.add_region(RegionDefinition.new("NA", "Nordamerika", 5, 9))
	map_data.add_region(RegionDefinition.new("SA", "Südamerika", 2, 4))
	map_data.add_region(RegionDefinition.new("EU", "Europa", 5, 7))
	map_data.add_region(RegionDefinition.new("AF", "Afrika", 3, 6))
	map_data.add_region(RegionDefinition.new("AS", "Asien", 7, 12))
	map_data.add_region(RegionDefinition.new("OC", "Ozeanien", 2, 4))
	_add_region(map_data, "NA", [
		["NA_01", "Alaska", ["NA_02", "NA_06", "AS_11"], "infantry"],
		["NA_02", "Nordwestterritorium", ["NA_01", "NA_03", "NA_04", "NA_06"], "cavalry"],
		["NA_03", "Grönland", ["NA_02", "NA_04", "NA_05", "NA_09", "EU_01"], "artillery"],
		["NA_04", "Alberta", ["NA_02", "NA_03", "NA_05", "NA_06"], "infantry"],
		["NA_05", "Ontario", ["NA_03", "NA_04", "NA_06", "NA_07", "NA_08", "NA_09"], "cavalry"],
		["NA_06", "Westliche USA", ["NA_01", "NA_02", "NA_04", "NA_05", "NA_07"], "artillery"],
		["NA_07", "Östliche USA", ["NA_05", "NA_06", "NA_08", "NA_09"], "infantry"],
		["NA_08", "Mittelamerika", ["NA_05", "NA_07", "SA_01"], "cavalry"],
		["NA_09", "Québec", ["NA_03", "NA_05", "NA_07"], "artillery"],
	])
	_add_region(map_data, "SA", [
		["SA_01", "Kolumbien", ["NA_08", "SA_02", "SA_03"], "infantry"],
		["SA_02", "Brasilien", ["SA_01", "SA_03", "SA_04", "AF_01"], "cavalry"],
		["SA_03", "Peru", ["SA_01", "SA_02", "SA_04"], "artillery"],
		["SA_04", "Argentinien", ["SA_02", "SA_03"], "infantry"],
	])
	_add_region(map_data, "EU", [
		["EU_01", "Island", ["NA_03", "EU_02", "EU_03"], "cavalry"],
		["EU_02", "Skandinavien", ["EU_01", "EU_03", "EU_04", "EU_05"], "artillery"],
		["EU_03", "Britische Inseln", ["EU_01", "EU_02", "EU_04", "EU_06"], "infantry"],
		["EU_04", "Nordeuropa", ["EU_02", "EU_03", "EU_05", "EU_06", "EU_07"], "cavalry"],
		["EU_05", "Osteuropa", ["EU_02", "EU_04", "EU_07", "AS_01", "AS_02", "AS_03"], "artillery"],
		["EU_06", "Westeuropa", ["EU_03", "EU_04", "EU_07", "AF_01", "AF_02"], "infantry"],
		["EU_07", "Südeuropa", ["EU_04", "EU_05", "EU_06", "AF_01", "AF_02", "AS_03"], "cavalry"],
	])
	_add_region(map_data, "AF", [
		["AF_01", "Nordafrika", ["SA_02", "EU_06", "EU_07", "AF_02", "AF_03", "AF_04"], "artillery"],
		["AF_02", "Ägypten", ["EU_06", "EU_07", "AF_01", "AF_03", "AS_03"], "infantry"],
		["AF_03", "Ostafrika", ["AF_01", "AF_02", "AF_04", "AF_05", "AF_06", "AS_03"], "cavalry"],
		["AF_04", "Zentralafrika", ["AF_01", "AF_03", "AF_05"], "artillery"],
		["AF_05", "Südafrika", ["AF_03", "AF_04", "AF_06"], "infantry"],
		["AF_06", "Madagaskar", ["AF_03", "AF_05"], "cavalry"],
	])
	_add_region(map_data, "AS", [
		["AS_01", "Ural", ["EU_05", "AS_02", "AS_04", "AS_05"], "artillery"],
		["AS_02", "Sibirien", ["EU_05", "AS_01", "AS_04", "AS_06", "AS_07"], "infantry"],
		["AS_03", "Naher Osten", ["EU_05", "EU_07", "AF_02", "AF_03", "AS_04", "AS_08"], "cavalry"],
		["AS_04", "Zentralasien", ["AS_01", "AS_02", "AS_03", "AS_05", "AS_07", "AS_08"], "artillery"],
		["AS_05", "China", ["AS_01", "AS_04", "AS_07", "AS_08", "AS_09"], "infantry"],
		["AS_06", "Jakutien", ["AS_02", "AS_07", "AS_10", "AS_11"], "cavalry"],
		["AS_07", "Mongolei", ["AS_02", "AS_04", "AS_05", "AS_06", "AS_09", "AS_10"], "artillery"],
		["AS_08", "Indien", ["AS_03", "AS_04", "AS_05", "AS_09", "OC_01"], "infantry"],
		["AS_09", "Südostasien", ["AS_05", "AS_07", "AS_08", "AS_10", "OC_01"], "cavalry"],
		["AS_10", "Ostasien", ["AS_06", "AS_07", "AS_09", "AS_11"], "artillery"],
		["AS_11", "Kamtschatka", ["AS_06", "AS_10", "AS_12", "NA_01"], "infantry"],
		["AS_12", "Fernost", ["AS_11"], "cavalry"],
	])
	_add_region(map_data, "OC", [
		["OC_01", "Indonesien", ["AS_08", "AS_09", "OC_02", "OC_03"], "artillery"],
		["OC_02", "Neuguinea", ["OC_01", "OC_03", "OC_04"], "infantry"],
		["OC_03", "Westaustralien", ["OC_01", "OC_02", "OC_04"], "cavalry"],
		["OC_04", "Ostaustralien", ["OC_02", "OC_03"], "artillery"],
	])
	return map_data

static func _add_region(map_data: MapData, _region_id: String, definitions: Array) -> void:
	for definition in definitions:
		map_data.add_territory(TerritoryDefinition.new(
			str(definition[0]), str(definition[1]), str(definition[0]).left(2),
			PackedStringArray(definition[2]), str(definition[3])
		))
