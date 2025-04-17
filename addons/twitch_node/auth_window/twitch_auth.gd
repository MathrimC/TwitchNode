class_name TwitchAuth
extends MarginContainer

enum { INACTIVE, LISTENING_FOR_TOKEN }

const auth_uri = "https://id.twitch.tv/oauth2/authorize" 
const redirect_bind_address := "127.0.0.1"
const filled_field_text := "ThisIsAFakeTokenForATextField!"

const redirect_uri: String = "https://redirectmeto.com/http://localhost"
const redirect_port: int = 7345

const help_texts := {
	TwitchNode.AuthType.IMPLICIT: "* Create an application in the Twitch Dev Console (https://dev.twitch.tv/console) and copy the Client ID. Make sure the OAuth Redirect URL is set to https://redirectmeto.com/http://localhost:7345",
	TwitchNode.AuthType.AUTH_CODE: "* Create an application in the Twitch Dev Console (https://dev.twitch.tv/console) and copy the Client ID and Client Secret. Make sure the OAuth Redirect URL is set to https://redirectmeto.com/http://localhost:7345",
}

@export var twitch_node: TwitchNode

@export var application_id_input: LineEdit
@export var application_secret_container: Container
@export var application_secret_input: LineEdit
@export var line_container: Container
@export var auth_type_dropdown: OptionButton
@export var scopes_button: MenuButton
@export var generate_token_button: Button
@export var help_label: RichTextLabel
@export var token_line_scene: PackedScene


var redirect_server := TCPServer.new()
var incoming_token_scope: Array[String]
var server_status = INACTIVE
var state_code: String
var auth_type: TwitchNode.AuthType

func _ready() -> void:
	if twitch_node == null:
		twitch_node = TwitchNode.new()
		add_child(twitch_node)
	twitch_node.token_validated.connect(on_token_validated)
	auth_type = TwitchNode.AuthType.AUTH_CODE
	auth_type_dropdown.selected = auth_type
	if auth_type == TwitchNode.AuthType.AUTH_CODE:
		application_secret_container.show()
		application_secret_input.text = filled_field_text if twitch_node.has_client_secret() else ""
	else:
		application_secret_container.hide()
	application_id_input.text = twitch_node.get_client_id()
	_create_token_lines()
	scopes_button.initialize(twitch_node)
	help_label.text = help_texts[auth_type]
	_refresh_ui()

func _create_token_lines():
	for username in await twitch_node.get_token_accounts():
		var token_line: TokenLine = token_line_scene.instantiate()
		line_container.add_child(token_line)
		token_line.initialize(username, twitch_node)

func set_twitch_node(_twitch_node: TwitchNode) -> void:
	if twitch_node != null:
		twitch_node.queue_free()
	twitch_node = _twitch_node

func on_auth_type_selected(index: int):
	match index:
		TwitchNode.AuthType.IMPLICIT:
			application_secret_container.hide()
		TwitchNode.AuthType.AUTH_CODE:
			application_secret_container.show()
	auth_type = index
	help_label.text = help_texts[auth_type]
	_refresh_ui()

func on_client_id_changed(_client_id: String) -> void:
	if _client_id.length() == 30:
		twitch_node.set_credentials(_client_id, "", true)
		application_id_input.self_modulate = Color.WHITE
	else:
		application_id_input.self_modulate = Color.DARK_RED
	_refresh_ui()

func on_client_secret_changed(_client_secret: String) -> void:
	if _client_secret.length() == 30:
		twitch_node.set_credentials("", _client_secret, true)
		application_secret_input.self_modulate = Color.WHITE
	else:
		application_secret_input.self_modulate = Color.DARK_RED
	_refresh_ui()

func on_generate_token_button_pressed() -> void:
	if generate_token_button.text == "Cancel":
		_end_auth_flow()
	else:
		_open_auth_url()

func _open_auth_url() -> void:
	redirect_server.listen(redirect_port, redirect_bind_address)
	server_status = LISTENING_FOR_TOKEN
	state_code = _generate_state_code()
	incoming_token_scope = scopes_button.get_selected_scopes()
	var url = twitch_node.get_auth_url(incoming_token_scope, auth_type, "%s:%s" % [redirect_uri, redirect_port], state_code)
	OS.shell_open(url)
	_refresh_ui()

func _process(_delta: float) -> void:
	if redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var byte_count := connection.get_available_bytes()
		var request = connection.get_utf8_string(byte_count)
		if request.begins_with("GET"):
			connection.put_data(("HTTP/1.1 %d\r\n\n" % 200).to_ascii_buffer())
			connection.put_data(_get_redirect_page().to_ascii_buffer())
		elif request.begins_with("POST"):
			var token := ""
			if auth_type == TwitchNode.AuthType.IMPLICIT:
				token = request.split("token\":\"")[1].split("\"")[0]
			else:
				token = request.split("code=",1)[1].split("&",1)[0]
			var response_code := 200
			if token != "":
				match server_status:
					LISTENING_FOR_TOKEN:
						var username := await twitch_node.add_token(token, auth_type, incoming_token_scope, "%s:%s" % [redirect_uri, redirect_port])
						if !username.is_empty():
							_refresh_token_info()
					_:
						printerr("Twitch auth process error: unknown token received")
						response_code = 500
			else:
				response_code = 400
			connection.put_data(("HTTP/1.1 %d\r\n" % response_code).to_ascii_buffer())
			_end_auth_flow()

func _refresh_token_info():
	for child in line_container.get_children():
		child.queue_free()
	_create_token_lines()

func _end_auth_flow():
	redirect_server.stop()
	server_status = INACTIVE
	_refresh_ui()

func on_token_validated(_account: String, _token_state: TwitchNode.TokenState) -> void:
	_refresh_ui()

func _refresh_ui() -> void:
	if application_id_input.text.length() == 30:
		application_id_input.self_modulate = Color.WHITE
		generate_token_button.disabled = false
	else:
		application_id_input.self_modulate = Color.RED
		generate_token_button.disabled = true
	if application_secret_input.text.length() == 30:
		application_secret_input.self_modulate = Color.WHITE
	else:
		application_secret_input.self_modulate = Color.RED
		if auth_type == TwitchNode.AuthType.AUTH_CODE:
			generate_token_button.disabled = true
	match server_status:
		INACTIVE:
			generate_token_button.text = "Generate token"
		LISTENING_FOR_TOKEN:
			generate_token_button.text = "Cancel"
			generate_token_button.disabled = false

func _get_redirect_page() -> String:
	var page := FileAccess.get_file_as_string("res://addons/twitch_node/auth_window/redirectpage.html")
	if page == "":
		printerr("error retrieving redirect page")
	return page

func _generate_state_code() -> String:
	var chars := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	var state_code: String
	for i in 64:
		state_code += chars[randi() % chars.length()]
	return state_code
