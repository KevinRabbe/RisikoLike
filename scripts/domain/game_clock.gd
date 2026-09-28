class_name GameClock
extends RefCounted

## Monotonic clock boundary used by the authoritative host and deterministic tests.
## Tests may pin the clock without changing production behavior.
var _override_msec: int = -1

func now_msec() -> int:
	return _override_msec if _override_msec >= 0 else Time.get_ticks_msec()

func set_now_msec(value: int) -> void:
	_override_msec = maxi(0, value)

func advance_msec(amount: int) -> void:
	set_now_msec(now_msec() + maxi(0, amount))

func clear_override() -> void:
	_override_msec = -1
