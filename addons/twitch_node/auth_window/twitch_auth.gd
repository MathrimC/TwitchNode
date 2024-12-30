class_name TwitchAuth
extends MarginContainer

enum { INACTIVE, LISTENING_FOR_CHANNELTOKEN, LISTENING_FOR_USERTOKEN }

const auth_uri = "https://id.twitch.tv/oauth2/authorize" 
const redirect_bind_address := "127.0.0.1"
const filled_field_text := "ThisIsAFakeTokenForATextField!"

const redirect_uri: String = "https://redirectmeto.com/http://localhost"
const redirect_port: int = 7345

@export var twitch_node: TwitchNode

@export var application_id_input: LineEdit
@export var channel_token_input: LineEdit
@export var bot_account_token_input: LineEdit

@export var channel_token_button: Button
@export var bot_account_token_button: Button

var redirect_server := TCPServer.new()
var incoming_token_type: String
var server_status = INACTIVE

func _ready() -> void:
	if twitch_node == null:
		twitch_node = TwitchNode.new()
		add_child(twitch_node)
	twitch_node.token_validated.connect(on_token_validated)
	application_id_input.text = twitch_node.get_client_id()
	_refresh_ui()

func set_twitch_node(_twitch_node: TwitchNode) -> void:
	if twitch_node != null:
		twitch_node.queue_free()
	twitch_node = _twitch_node

func on_client_id_changed(_client_id: String) -> void:
	if _client_id.length() == 30:
		twitch_node.set_credentials(_client_id, "", "", true)
		application_id_input.self_modulate = Color.WHITE
	else:
		application_id_input.self_modulate = Color.DARK_RED
	_refresh_ui()

func on_channel_token_changed(_channel_token: String) -> void:
	if _channel_token.length() == 30:
		twitch_node.set_credentials("", _channel_token, "", true)
		channel_token_input.self_modulate = Color.WHITE
		if server_status != INACTIVE:
			_end_auth_flow()
	else:
		channel_token_input.self_modulate = Color.DARK_RED

func on_bot_account_token_changed(_bot_account_token: String) -> void:
	if _bot_account_token.length() == 30:
		twitch_node.set_credentials("", "", _bot_account_token, true)
		bot_account_token_input.self_modulate = Color.WHITE
		if server_status != INACTIVE:
			_end_auth_flow()
	else:
		bot_account_token_input.self_modulate = Color.DARK_RED

func on_channel_token_button_pressed() -> void:
	if channel_token_input.text == "Cancel":
		_end_auth_flow()
	else:
		_open_channel_auth_url()

func on_bot_account_token_button_pressed() -> void:
	if bot_account_token_button.text == "Cancel":
		_end_auth_flow()
	else:
		_open_botaccount_auth_url()

func _open_channel_auth_url() -> void:
	redirect_server.listen(redirect_port, redirect_bind_address)
	server_status = LISTENING_FOR_CHANNELTOKEN
	var url = twitch_node.get_channel_auth_url("%s:%s" % [redirect_uri, redirect_port])
	OS.shell_open(url)
	_refresh_ui()

func _open_botaccount_auth_url() -> void:
	redirect_server.listen(redirect_port, redirect_bind_address)
	server_status = LISTENING_FOR_USERTOKEN
	var url = twitch_node.get_useraccount_auth_url("%s:%s" % [redirect_uri, redirect_port])
	OS.shell_open(url)
	_refresh_ui()
	
func _process(_delta: float) -> void:
	if redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var byte_count := connection.get_available_bytes()
		var request = connection.get_utf8_string(byte_count)
		if request.begins_with("GET"):
			connection.put_data(("HTTP/1.1 %d\r\n" % 200).to_ascii_buffer())
			connection.put_data(_get_redirect_page().to_ascii_buffer())
		elif request.begins_with("POST"):
			var token := request.split("token\":\"")[1].split("\"")[0]
			var response_code := 200
			if token != "":
				match server_status:
					LISTENING_FOR_CHANNELTOKEN:
						twitch_node.set_credentials("", token, "", true)
					LISTENING_FOR_USERTOKEN:
						twitch_node.set_credentials("", "", token, true)
					_:
						printerr("Twitch auth process error: unknown token received")
						response_code = 500
			else:
				response_code = 400
			connection.put_data(("HTTP/1.1 %d\r\n" % response_code).to_ascii_buffer())
			_end_auth_flow()

func _end_auth_flow():
	redirect_server.stop()
	server_status = INACTIVE
	_refresh_ui()

func on_token_validated(_account: String, _token_state: TwitchNode.TokenState) -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	if application_id_input.text.length() == 30:
		application_id_input.self_modulate = Color.WHITE
		match server_status:
			INACTIVE:
				channel_token_button.text = "Create New Token"
				channel_token_button.disabled = false
				bot_account_token_button.text = "Create New Token"
				bot_account_token_button.disabled = false
			LISTENING_FOR_CHANNELTOKEN:
				channel_token_button.text = "Cancel"
				bot_account_token_button.text = "Create New Token"
				bot_account_token_button.disabled = true
			LISTENING_FOR_USERTOKEN:
				channel_token_button.text = "Create New Token"
				channel_token_button.disabled = true
				bot_account_token_button.text = "Cancel"
	else:
		application_id_input.self_modulate = Color.RED
		channel_token_button.disabled = true
		bot_account_token_button.disabled = true
	match twitch_node.get_token_state("channel"):
		TwitchNode.TokenState.EMPTY:
			channel_token_input.text = ""
			channel_token_input.self_modulate = Color.RED
		TwitchNode.TokenState.VALID:
			channel_token_input.text = filled_field_text
			channel_token_input.self_modulate = Color.WHITE
		_:
			channel_token_input.self_modulate = Color.RED
	match twitch_node.get_token_state("user"):
		TwitchNode.TokenState.EMPTY:
			bot_account_token_input.text = ""
			bot_account_token_input.self_modulate = Color.RED
		TwitchNode.TokenState.VALID:
			bot_account_token_input.text = filled_field_text
			bot_account_token_input.self_modulate = Color.WHITE
		_:
			bot_account_token_input.self_modulate = Color.RED

func _get_redirect_page() -> String:
	var page := FileAccess.get_file_as_string("res://addons/twitch_node/auth_window/redirectpage.html")
	if page == "":
		printerr("error retrieving redirect page")
	return page
