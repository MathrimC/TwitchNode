class_name SettingsBar
extends HBoxContainer

const twitch_auth_scene: PackedScene = preload("res://addons/twitch_node/auth_window/twitch_auth_window.tscn")

@export var account_button: OptionButton
@export var add_channel_button: Button
@export var join_container: Container
@export var channel_input: LineEdit
@export var twitch_node: TwitchNode
@export var disconnect_button: Button
var twitch_auth_window: TwitchAuthWindow

func _ready() -> void:
	join_container.hide()
	refresh_account_dropdown()
	twitch_node.token_validated.connect(on_token_validated)
	update_add_channel_button_visibility()

func get_user_account() -> String:
	return account_button.text

func on_token_validated(_account: String, _state: TwitchNode.TokenState) -> void:
	refresh_account_dropdown()

func refresh_account_dropdown() -> void:
	var accounts: Array[String] = await twitch_node.get_token_accounts()
	var selection_backup: String = account_button.text
	var popup := account_button.get_popup()
	popup.clear()
	var index := 0
	for account in accounts:
		popup.add_item(account)
		if account == selection_backup:
			account_button.select(index)
		index += 1
	update_add_channel_button_visibility()

func update_add_channel_button_visibility() -> void:
	add_channel_button.visible = account_button.item_count > 0 && account_button.selected >= 0

func on_account_selected(_index: int) -> void:
	update_add_channel_button_visibility()

func on_add_channel_pressed() -> void:
	join_container.show()

func on_join_pressed() -> void:
	on_channel_input_submitted(channel_input.text)

func on_cancel_pressed() -> void:
	join_container.hide()
	channel_input.text = ""

func on_channel_input_submitted(_channel_name: String) -> void:
	twitch_node.connect_to_channel(_channel_name, account_button.text)
	join_container.hide()

func on_auth_button_pressed() -> void:
	if twitch_auth_window == null:
		twitch_auth_window = twitch_auth_scene.instantiate()
		twitch_auth_window.set_twitch_node(twitch_node)
		add_child(twitch_auth_window)
	else:
		twitch_auth_window.grab_focus.call_deferred()

func on_disconnect_button_pressed() -> void:
	twitch_node.disconnect_from_twitch()
