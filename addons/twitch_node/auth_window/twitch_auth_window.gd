class_name TwitchAuthWindow
extends Window

@export var twitch_auth: TwitchAuth

func _on_close_requested() -> void:
	self.queue_free()

func set_twitch_node(twitch_node: TwitchNode) -> void:
	twitch_auth.set_twitch_node(twitch_node)
