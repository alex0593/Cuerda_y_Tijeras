# PlatformService — interfaces de plataforma (doc 09.6).
# El núcleo solo usa este autoload. Desktop implementa real; Android/iOS/web hacen override.
extends Node

var platform_name := "desktop"

func _ready() -> void:
	if OS.has_feature("android"):
		platform_name = "android"
	elif OS.has_feature("ios"):
		platform_name = "ios"
	elif OS.has_feature("web"):
		platform_name = "web"

func vibrate(pattern: String = "short") -> void:
	if not SaveService.settings.get("vibration", true):
		return
	if platform_name == "android" and Engine.has_singleton("GodotVibration"):
		pass # Implementación Android real va en platform-android/
	# Desktop: sin vibración, solo feedback visual/sonoro.

func share_text(text: String) -> void:
	DisplayServer.clipboard_set(text)

func safe_area() -> Rect2:
	return Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
