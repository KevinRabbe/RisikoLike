extends Node

signal backend_error(code: String)

const API_VERSION := "v1"
var base_url := ""

func configure(url: String) -> void:
	base_url = url.trim_suffix("/")

func is_configured() -> bool:
	return not base_url.is_empty()
