extends Node

const GAME_VERSION := "0.1.0-dev"
const PROTOCOL_VERSION := 1
const APP_NAME := "RisikoLike"

func _ready() -> void:
	print("[%s] %s %s | protocol %d" % ["APP", APP_NAME, GAME_VERSION, PROTOCOL_VERSION])
