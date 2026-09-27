class_name CardState
extends RefCounted

enum Symbol { INFANTRY, CAVALRY, ARTILLERY, JOKER }

var card_id: String
var territory_id: String = ""
var symbol: int = Symbol.JOKER

func _init(p_card_id: String = "", p_territory_id: String = "", p_symbol: int = Symbol.JOKER) -> void:
	card_id = p_card_id
	territory_id = p_territory_id
	symbol = p_symbol

func is_joker() -> bool:
	return symbol == Symbol.JOKER
