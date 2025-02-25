class_name TokenLine
extends HBoxContainer

@export var username_label: Label
@export var status_label: Label
@export var scopes_button: MenuButton
@export var regenerate_button: Button
@export var delete_button: Button

var username: String
var twitch_node: TwitchNode

func initialize(_username: String, _twitch_node: TwitchNode):
	username = _username
	twitch_node = _twitch_node
	username_label.text = username
	var scopes_menu := scopes_button.get_popup()
	for scope: String in await _twitch_node.get_scopes():
		scopes_menu.add_check_item(scope)
	var selected_scopes := await _twitch_node.get_token_scopes(username)
	for i in scopes_menu.item_count:
		if selected_scopes.has(scopes_menu.get_item_text(i)):
			scopes_menu.set_item_checked(i, true)
		scopes_menu.set_item_disabled(i,true)
	_refresh_token_state(username, await twitch_node.get_token_state(username))
	twitch_node.token_validated.connect(_refresh_token_state)

func _refresh_token_state(account: String, state: TwitchNode.TokenState):
	if account != username:
		return
	match state:
		TwitchNode.TokenState.VALID:
			status_label.text = "Valid"
			status_label.self_modulate = Color.GREEN
		TwitchNode.TokenState.INVALID:
			status_label.text = "Invalid"
			status_label.self_modulate = Color.RED
		TwitchNode.TokenState.REFRESHING:
			status_label.text = "Refreshing"
			status_label.self_modulate = Color.ORANGE
		TwitchNode.TokenState.CHECKING:
			status_label.text = "Checking"
			status_label.self_modulate = Color.ORANGE
		_:
			status_label.text = "Unkown"
			status_label.self_modulate = Color.ORANGE


func _on_regenerate_pressed() -> void:
	pass

func _on_delete_pressed() -> void:
	twitch_node.delete_token(username)
	self.queue_free()
