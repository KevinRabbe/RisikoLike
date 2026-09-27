class_name Ruleset
extends RefCounted

const MIN_PLAYERS := 2
const MAX_PLAYERS := 5

enum TerritoryAssignmentMode { RANDOM, MANUAL }
enum StartingArmiesMode { STANDARD, CUSTOM }
enum StartingPlayerRule { FEWEST_ARMIES_THEN_RANDOM, RANDOM }
enum CardBonusMode { PROGRESSIVE, FIXED }
enum FortificationMode { CONNECTED, ADJACENT }
enum VictoryCondition { WORLD_CONQUEST }

var territory_assignment_mode := TerritoryAssignmentMode.RANDOM
var starting_armies_mode := StartingArmiesMode.STANDARD
var starting_armies_by_player_count: Dictionary = {2: 40, 3: 35, 4: 30, 5: 25}
var starting_player_rule := StartingPlayerRule.FEWEST_ARMIES_THEN_RANDOM
var turn_timer_seconds: int = 180
var reconnect_timeout_seconds: int = 180
var territory_cards_enabled: bool = true
var card_bonus_mode := CardBonusMode.PROGRESSIVE
var progressive_card_values: Array[int] = [4, 6, 8, 10, 12, 15]
var progressive_increment_after_sequence: int = 5
var forced_trade_threshold: int = 5
var owned_territory_card_bonus: int = 2
var fixed_card_bonus: int = 4
var continent_bonus_enabled: bool = true
var fortification_mode := FortificationMode.CONNECTED
var unlimited_fortification: bool = false
var surrender_allowed: bool = true
var spectating_allowed: bool = true
var victory_condition := VictoryCondition.WORLD_CONQUEST

func duplicate_ruleset() -> Ruleset:
	var copy := Ruleset.new()
	copy.territory_assignment_mode = territory_assignment_mode
	copy.starting_armies_mode = starting_armies_mode
	copy.starting_armies_by_player_count = starting_armies_by_player_count.duplicate()
	copy.starting_player_rule = starting_player_rule
	copy.turn_timer_seconds = turn_timer_seconds
	copy.reconnect_timeout_seconds = reconnect_timeout_seconds
	copy.territory_cards_enabled = territory_cards_enabled
	copy.card_bonus_mode = card_bonus_mode
	copy.progressive_card_values = progressive_card_values.duplicate()
	copy.progressive_increment_after_sequence = progressive_increment_after_sequence
	copy.forced_trade_threshold = forced_trade_threshold
	copy.owned_territory_card_bonus = owned_territory_card_bonus
	copy.fixed_card_bonus = fixed_card_bonus
	copy.continent_bonus_enabled = continent_bonus_enabled
	copy.fortification_mode = fortification_mode
	copy.unlimited_fortification = unlimited_fortification
	copy.surrender_allowed = surrender_allowed
	copy.spectating_allowed = spectating_allowed
	copy.victory_condition = victory_condition
	return copy

func to_dict() -> Dictionary:
	return {
		"territory_assignment_mode": territory_assignment_mode,
		"starting_armies_mode": starting_armies_mode,
		"starting_armies_by_player_count": starting_armies_by_player_count.duplicate(),
		"starting_player_rule": starting_player_rule,
		"turn_timer_seconds": turn_timer_seconds,
		"reconnect_timeout_seconds": reconnect_timeout_seconds,
		"territory_cards_enabled": territory_cards_enabled,
		"card_bonus_mode": card_bonus_mode,
		"progressive_card_values": progressive_card_values.duplicate(),
		"progressive_increment_after_sequence": progressive_increment_after_sequence,
		"forced_trade_threshold": forced_trade_threshold,
		"owned_territory_card_bonus": owned_territory_card_bonus,
		"fixed_card_bonus": fixed_card_bonus,
		"continent_bonus_enabled": continent_bonus_enabled,
		"fortification_mode": fortification_mode,
		"unlimited_fortification": unlimited_fortification,
		"surrender_allowed": surrender_allowed,
		"spectating_allowed": spectating_allowed,
		"victory_condition": victory_condition,
	}
