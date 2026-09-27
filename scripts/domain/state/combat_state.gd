class_name CombatState
extends RefCounted

var attacker_player_id: String = ""
var attacker_territory_id: String = ""
var defender_territory_id: String = ""
var attacker_dice: Array[int] = []
var defender_dice: Array[int] = []
var attacker_losses: int = 0
var defender_losses: int = 0
var active: bool = false

func clear() -> void:
	attacker_player_id = ""
	attacker_territory_id = ""
	defender_territory_id = ""
	attacker_dice.clear()
	defender_dice.clear()
	attacker_losses = 0
	defender_losses = 0
	active = false
