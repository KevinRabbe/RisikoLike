class_name RulesetValidator
extends RefCounted

static func validate(ruleset: Ruleset) -> PackedStringArray:
	var errors := PackedStringArray()

	if ruleset.turn_timer_seconds != 0 and ruleset.turn_timer_seconds < 30:
		errors.append("turn_timer_seconds must be 0 or at least 30")
	if ruleset.reconnect_timeout_seconds < 30:
		errors.append("reconnect_timeout_seconds must be at least 30")
	if ruleset.forced_trade_threshold < 3:
		errors.append("forced_trade_threshold must be at least 3")
	if ruleset.owned_territory_card_bonus < 0:
		errors.append("owned_territory_card_bonus must not be negative")
	if ruleset.fixed_card_bonus < 0:
		errors.append("fixed_card_bonus must not be negative")
	for player_count in range(Ruleset.MIN_PLAYERS, Ruleset.MAX_PLAYERS + 1):
		if not ruleset.starting_armies_by_player_count.has(player_count):
			errors.append("missing starting army value for %d players" % player_count)
		elif int(ruleset.starting_armies_by_player_count[player_count]) < player_count:
			errors.append("starting armies for %d players are too low" % player_count)
	if ruleset.progressive_card_values.is_empty():
		errors.append("progressive_card_values must not be empty")
	else:
		var previous := 0
		for value in ruleset.progressive_card_values:
			if value <= previous:
				errors.append("progressive_card_values must be strictly increasing")
				break
			previous = value
	if ruleset.progressive_increment_after_sequence <= 0:
		errors.append("progressive_increment_after_sequence must be positive")

	return errors

static func is_valid(ruleset: Ruleset) -> bool:
	return validate(ruleset).is_empty()
