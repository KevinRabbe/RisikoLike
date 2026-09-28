class_name TurnState
extends RefCounted

enum Phase { TURN_START, CARD_TRADE, REINFORCEMENT, ATTACK, FORTIFICATION, TURN_END }

var round_number: int = 1
var active_player_id: String = ""
var phase: int = Phase.TURN_START
var turn_started_at_msec: int = 0
var turn_deadline_msec: int = 0
var timer_warning_emitted: bool = false

func phase_name() -> String:
	return Phase.keys()[phase]

func can_transition_to(next_phase: int) -> bool:
	match phase:
		Phase.TURN_START:
			return next_phase == Phase.CARD_TRADE or next_phase == Phase.REINFORCEMENT
		Phase.CARD_TRADE:
			return next_phase == Phase.REINFORCEMENT
		Phase.REINFORCEMENT:
			return next_phase == Phase.ATTACK
		Phase.ATTACK:
			return next_phase == Phase.FORTIFICATION
		Phase.FORTIFICATION:
			return next_phase == Phase.TURN_END
		Phase.TURN_END:
			return next_phase == Phase.TURN_START
	return false

func transition_to(next_phase: int) -> bool:
	if not can_transition_to(next_phase):
		return false
	phase = next_phase
	return true
