class_name DeckState
extends RefCounted

var cards: Dictionary = {}
var draw_pile: Array[String] = []
var discard_pile: Array[String] = []
var trade_count: int = 0

func add_card(card: CardState) -> void:
	cards[card.card_id] = card

func get_card(card_id: String) -> CardState:
	return cards.get(card_id) as CardState

func draw_card() -> CardState:
	if draw_pile.is_empty():
		return null
	var card_id: String = draw_pile.pop_back()
	return get_card(card_id)

func discard(card_id: String) -> void:
	if cards.has(card_id):
		discard_pile.append(card_id)
