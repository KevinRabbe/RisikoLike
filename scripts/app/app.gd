extends Node

const GAME_VERSION := "0.1.0"
const PROTOCOL_VERSION := 1
const APP_NAME := "RisikoLike"

func _ready() -> void:
	print("[%s] %s %s | protocol %d" % ["APP", APP_NAME, GAME_VERSION, PROTOCOL_VERSION])
	var map_errors := MapValidator.validate(MapDataFactory.create_default())
	if not map_errors.is_empty():
		for error in map_errors:
			push_error("[MAP] %s" % error)
	var ruleset_errors := RulesetValidator.validate(Ruleset.new())
	if not ruleset_errors.is_empty():
		for error in ruleset_errors:
			push_error("[RULES] %s" % error)
