class_name PlaceReinforcementCommand
extends RefCounted

static func create(player_id: String, state_revision: int, territory_id: String, amount: int) -> CommandEnvelope:
	return CommandEnvelope.create(player_id, state_revision, "place_reinforcement", {"territory_id": territory_id, "amount": amount})
