## This node handles formatting requests and rate limiting for the Twitch API.
## Don't call any functions of this node directly, use the interface of the TwitchNode node.
class_name TwitchAPI
extends Node

# enum APIOperation { GET_USER_INFO, SUBSCRIBE_TO_EVENT, POST_CHAT_MESSAGE, GET_CHANNEL_INFO, MODIFY_CHANNEL_INFO, CREATE_POLL, SEND_SHOUTOUT, BAN_USER, GET_VIPS, ADD_VIP, GET_SUBS, CREATE_PREDICTION, END_PREDICTION, START_RAID, CANCEL_RAID, WARN_USER }
enum EventType { CHANNEL_CHAT_MESSAGE, CHANNEL_UPDATE, CHANNEL_FOLLOW, CHANNEL_SUB, CHANNEL_SUB_END, CHANNEL_SUB_GIFT, CHANNEL_SUB_MESSAGE, CHANNEL_VIP_ADD, CHANNEL_VIP_REMOVE, CHANNEL_INCOMING_RAID, CHANNEL_OUTGOING_RAID, CHANNEL_POLL_BEGIN, CHANNEL_POLL_PROGRESS, CHANNEL_POLL_END, CHANNEL_PREDICTION_BEGIN, CHANNEL_PREDICTION_PROGRESS, CHANNEL_PREDICTION_LOCK, CHANNEL_PREDICTION_END, CHANNEL_POINTS_AUTOMATIC_REWARD_REDEMPTION_ADD, CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD, CHANNEL_CHEER, HYPE_TRAIN_BEGIN, HYPE_TRAIN_PROGRESS, HYPE_TRAIN_END, STREAM_ONLINE, STREAM_OFFLINE }

const base_uri := "https://api.twitch.tv/helix/"
const websocket_uri: String = "wss://eventsub.wss.twitch.tv/ws"
const auth_uri = "https://id.twitch.tv/oauth2/authorize"
const validate_uri = "https://id.twitch.tv/oauth2/validate"
const test_base_uri := "http://127.0.0.1:8080/"
const test_websocket_uri := "ws://127.0.0.1:8080/ws"
const events: Dictionary = {
	EventType.CHANNEL_CHAT_MESSAGE : {
		"type": "channel.chat.message",
		"scope": "user:read:chat",
		"version": 1,
		"condition": ["broadcaster_user_id", "user_id"]
	},
	EventType.CHANNEL_UPDATE : {
		"type": "channel.update",
		"scope": "",
		"version": 2,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_FOLLOW : {
		"type": "channel.follow",
		"scope": "moderator:read:followers",
		"version": 2,
		"condition": ["broadcaster_user_id", "moderator_user_id"]
	},
	EventType.CHANNEL_SUB : {
		"type": "channel.subscribe",
		"scope": "channel:read:subscriptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_SUB_END : {
		"type": "channel.subscription.end",
		"scope": "channel:read:subscriptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_SUB_GIFT : {
		"type": "channel.subscription.gift",
		"scope": "channel:read:subscriptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_SUB_MESSAGE : {
		"type": "channel.subscription.message",
		"scope": "channel:read:subscriptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_VIP_ADD : {
		"type": "channel.vip.add",
		"scope": "channel:read:vips",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_VIP_REMOVE : {
		"type": "channel.vip.remove",
		"scope": "channel:read:vips",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_INCOMING_RAID : {
		"type": "channel.raid",
		"scope": "",
		"version": 1,
		"condition": ["to_broadcaster_user_id"],
	},
	EventType.CHANNEL_OUTGOING_RAID : {
		"type": "channel.raid",
		"scope": "",
		"version": 1,
		"condition": ["from_broadcaster_user_id"],
	},
	EventType.CHANNEL_POLL_BEGIN : {
		"type": "channel.poll.begin",
		"scope": "channel:read:polls",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_POLL_PROGRESS : {
		"type": "channel.poll.progress",
		"scope": "channel:read:polls",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_POLL_END : {
		"type": "channel.poll.end",
		"scope": "channel:read:polls",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_PREDICTION_BEGIN: {
		"type": "channel.prediction.begin",
		"scope": "channel:read:predictions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_PREDICTION_PROGRESS: {
		"type": "channel.prediction.progress",
		"scope": "channel:read:predictions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_PREDICTION_LOCK: {
		"type": "channel.prediction.lock",
		"scope": "channel:read:predictions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_PREDICTION_END: {
		"type": "channel.prediction.end",
		"scope": "channel:read:predictions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD : {
		"type": "channel.channel_points_custom_reward_redemption.add",
		"scope": "channel:read:redemptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_POINTS_AUTOMATIC_REWARD_REDEMPTION_ADD : {
		"type": "channel.channel_points_automatic_reward_redemption.add",
		"scope": "channel:read:redemptions",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.CHANNEL_CHEER : {
		"type": "channel.cheer",
		"scope": "bits:read",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.HYPE_TRAIN_BEGIN : {
		"type": "channel.hype_train.begin",
		"scope": "channel:read:hype_train",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.HYPE_TRAIN_PROGRESS : {
		"type": "channel.hype_train.progress",
		"scope": "channel:read:hype_train",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.HYPE_TRAIN_END : {
		"type": "channel.hype_train.end",
		"scope": "channel:read:hype_train",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.STREAM_ONLINE : {
		"type": "stream.online",
		"scope": "",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
	EventType.STREAM_OFFLINE : {
		"type": "stream.offline",
		"scope": "",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	}
}

signal websocket_connected()

var twitch_node: TwitchNode
var test := false
var rate_limit: int
var rate_limit_remaining: int
## Key: username, value: user id
var user_list: Dictionary
var invalid_users: Array
var channels: Array[String]
var poll_id: String
var prediction_info: Dictionary
## Requests queued due to rate limit
var request_queue: Array[TwitchAPIRequest]
var request_pool: Array[TwitchAPIRequest]
var session_id: String = ""
var socket := WebSocketPeer.new()
var encrypted_client_id: PackedByteArray
var encrypted_channel_access_token: PackedByteArray
var encrypted_user_access_token: PackedByteArray
var encrypted_tokens: Dictionary
## key: "channel" or "user", value: TwitchNode.TokenState
var token_states: Dictionary
var key: CryptoKey

@onready var crypto: Crypto = Crypto.new()

func _ready() -> void:
	rate_limit = twitch_node.rate_limit
	rate_limit_remaining = twitch_node.rate_limit
	_init_credentials()
	_validation_loop()
	_rate_limit_loop()
	_request_cleanup_loop()

func connect_to_channel(channel: String) -> void:
	if token_states["channel"] == TwitchNode.TokenState.CHECKING:
		await twitch_node.token_validated
	if token_states["user"] == TwitchNode.TokenState.CHECKING:
		await twitch_node.token_validated
	if token_states["channel"] != TwitchNode.TokenState.VALID:
		return
	if session_id == "":
		_connect_twitch_websocket()
		await websocket_connected
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		channels.append(channel_id)
		for type in EventType.size():
			_execute_request(TwitchAPIRequest.APIOperation.SUBSCRIBE_TO_EVENT, "channel", _get_event_sub_body(type, channel_id), {})
	else:
		printerr("Can't connect to channel due to missing channel id")

func send_chat_message(channel: String, username: String, message: String) -> void:
	if await _check_user_ids([channel, username]):
		var channel_id = user_list.get(channel, "")
		var user_id = user_list.get(username, "")
		var body :=	{ "broadcaster_id": channel_id, "sender_id": user_id, "message" : message }
		_execute_request(TwitchAPIRequest.APIOperation.POST_CHAT_MESSAGE, "user", body)
	else:
		printerr("Can't send chat message as %s due to missing user ids" % username)

func get_channel_info(channel: String) -> Dictionary:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id
		}
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_CHANNEL_INFO, "", {}, query_parameters)
		if request.response_body["data"].size() > 0:
			return request.response_body["data"][0]
		else:
			twitch_node.error_occured.emit(TwitchNode.ErrorCode.BAD_INPUT, {"message" : "Channel info not found for %s" % channel})
			printerr("Didn't find channel info")
			return {}
	else:
		printerr("Can't get channel info due to missing channel id")
		return {}

func modify_channel_info(channel: String, title: String, category: String = "", language: String = "", delay: int = -1, tags: Array[String] = []) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id
		}
		var body := {
		}
		if category != "":
			var category_id = await _get_category_id(category)
			if category_id == "":
				twitch_node.error_occured.emit(TwitchNode.ErrorCode.BAD_INPUT, {"message": "Can't find category %s" % category})
				return
			else:
				body["game_id"] = category_id
		if language != "":
			body["broadcaster_language"] = language
		if title != "":
			body["title"] = title
		if delay > -1:
			body["delay"] = delay
		if !tags.is_empty():
			body["tags"] = tags
		_execute_request(TwitchAPIRequest.APIOperation.MODIFY_CHANNEL_INFO, "", body, query_parameters)
	else:
		printerr("Can't update channel info due to missing channel id")

func send_shoutout(channel: String, shoutout_channel: String) -> void:
	if await _check_user_ids([channel, shoutout_channel]):
		var channel_id = user_list.get(channel, "")
		# var user_id = user_list.get(username, "")
		var shoutout_channel_id = user_list.get(shoutout_channel, "")
		var body := {
			"from_broadcaster_id": channel_id,
			"to_broadcaster_id": shoutout_channel_id,
			"moderator_id": channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.SEND_SHOUTOUT, "", body)
	else:
		printerr("Can't send shoutout to %s due to missing user ids" % shoutout_channel)

func create_custom_reward(channel: String, title: String, cost: int, explanation: String, is_enabled: bool = true, is_user_input_required: bool = false, max_per_stream: int = 0, max_per_user: int = 0, global_cooldown_s: int = 0, skip_request_queue: bool = false, background_color: Color = Color.WHITE):
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id,
		}
		var body := {
			"title": title,
			"cost": cost,
			"prompt": explanation,
			"is_enabled": is_enabled,
			"is_user_input_required": is_user_input_required,
			"should_redemption_skip_request_queue": skip_request_queue
		}
		if background_color != Color.WHITE:
			body["background_color"] = "#%s" % background_color.to_html()
		if max_per_stream > 0:
			body["is_max_per_stream_enabled"] = true
			body["max_per_stream"] = max_per_stream
		if max_per_user > 0:
			body["is_max_per_user_per_stream_enabled"] = true
			body["max_per_user_per_stream"] = max_per_user
		if global_cooldown_s > 0:
			body["is_global_cooldown_enabled"] = true
			body["global_cooldown_seconds"] = global_cooldown_s
		_execute_request(TwitchAPIRequest.APIOperation.CREATE_CUSTOM_REWARD, "", body, query_parameters)
	else:
		printerr("Can't create reward due to missing channel id")

func update_redemption_status(channel: String, reward_id: String, redemption_id: String, status: String) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel,"")
		var query_parameters := {
			"id": redemption_id,
			"broadcaster_id": channel_id,
			"reward_id": reward_id
		}
		var body := {
			"status" = status
		}
		_execute_request(TwitchAPIRequest.APIOperation.UPDATE_REDEMPTION_STATUS, "", body, query_parameters)
	else:
		printerr("Can't update redemption status due to missing channel id")
	
func warn_user(channel: String, warned_username: String, reason: String) -> void:
	if await _check_user_ids([channel, warned_username]):
		var channel_id = user_list.get(channel, "")
		# var user_id = user_list.get(bot_username, "")
		var warned_user_id = user_list.get(warned_username, "")
		var query_parameters := {
			"broadcaster_id" = channel_id,
			"moderator_id" = channel_id,
		}
		var body := {
			"data" = {"user_id": warned_user_id, "reason": reason}
		}
		_execute_request(TwitchAPIRequest.APIOperation.WARN_USER, "channel", body, query_parameters)
	else:
		printerr("Can't warn user %s due to missing user ids" % warned_username)

func ban_user(channel: String, banned_username: String, duration: int = -1, reason: String = "") -> void:
	if await _check_user_ids([channel, banned_username]):
		var channel_id = user_list.get(channel, "")
		# var user_id = user_list.get(bot_username, "")
		var banned_user_id = user_list.get(banned_username, "")
		var body := {
			"data" : {
				"user_id" : banned_user_id,
				"duration" : duration,
				"reason" : reason,
			}
		}
		var query_parameters := {
			"broadcast_id" : channel_id,
			"moderator_id" : channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.BAN_USER, "channel", body, query_parameters)
	else:
		printerr("Can't ban user %s due to missing user ids" % banned_username)

func get_vips(channel: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get vip info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["page"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_VIPS, "", {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get vips due to missing channel id")
		return {}

func add_vip(channel: String, vip_username = "", page: String = "") -> void:
	if await _check_user_ids([channel, vip_username]):
		var channel_id = user_list[channel]
		var vip_user_id = user_list[vip_username]
		var query_parameters := {
			"user_id" : vip_user_id,
			"broadcaster_id" : channel_id,
		}
		if page != "":
			query_parameters["after"] = page
		_execute_request(TwitchAPIRequest.APIOperation.ADD_VIP, "", {}, query_parameters)
	else:
		printerr("Can't add %s as vip due to missing user ids" % vip_username)

func get_subs(channel: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get sub info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["after"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_SUBS, "", {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get subs due to missing channel id")
		return {}

func get_followers(channel: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get follow info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["after"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_FOLLOWERS, "", {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get followers due to missing channel id")
		return {}

func get_moderators(channel: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get moderator info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["after"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_MODERATORS, "", {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get moderators due to missing channel id")
		return {}

func create_poll(channel: String, poll_title: String, poll_choices: Array[String], poll_duration: int) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := { 
			"broadcaster_id": channel_id, 
			"title": poll_title, 
			"choices": [],
			"duration": poll_duration,
		}
		for choice: String in poll_choices:
			body["choices"].append({ "title" : choice})
		_execute_request(TwitchAPIRequest.APIOperation.CREATE_POLL, "", body)
	else:
		printerr("Can't create poll due to missing channel id")

func create_prediction(channel: String, prediction_title: String, prediction_outcomes: Array[String], prediction_duration: int) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := {
			"broadcaster_id" : channel_id,
			"title" : prediction_title,
			"outcomes": [],
			"prediction_window" : prediction_duration,
		}
		for outcome in prediction_outcomes:
			body["outcomes"].append({"title": outcome})
		var request := await _execute_request(TwitchAPIRequest.APIOperation.CREATE_PREDICTION, "", body)
		prediction_info = request.response_body["data"]
	else:
		printerr("Can't create prediction due to missing channel id")

func lock_prediction(channel: String) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := {
			"broadcaster_id" : channel_id,
			"id" : prediction_info["id"],
			"status" : "LOCKED"
		}
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, "", body)
	else:
		printerr("Can't lock prediction due to missing channel id")

func resolve_prediction(channel: String, outcome: String) -> void:
	var outcome_id := ""
	for outcome_info in prediction_info.outcomes:
		if outcome_info["title"] == outcome:
			outcome_id = outcome_info["id"]
			break
	if outcome_id != "" && await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := {
			"broadcaster_id" : channel_id,
			"id" : prediction_info["id"],
			"status" : "RESOLVED",
			"winning_outcome_id" : outcome_id
		}
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, "", body)
	elif outcome_id == "":
		printerr("Couldn't find prediction outcome %s in prediction options" % outcome)
		twitch_node.error_occured.emit(TwitchNode.ErrorCode.BAD_INPUT, {"message": "Prediction outcome not found"})
	else:
		printerr("Can't resolve prediction due to missing channel id")

func cancel_prediction(channel: String) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := {
			"broadcaster_id" : channel_id,
			"id" : prediction_info["id"],
			"status" : "CANCELED"
		}
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, "", body)
	else:
		printerr("Can't cancel prediction due to missing channel id")

func send_chat_announcement(channel: String, user: String, message: String, color: String = "") -> void:
	if await _check_user_ids([channel, user]):
		var channel_id = user_list[channel]
		var user_id = user_list[user]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"moderator_id" : user_id,
		}
		var body := {
			"message" : message,
		}
		if color == "blue" || color == "green" || color == "orange" || color == "purple":
			body["color"] = color
		_execute_request(TwitchAPIRequest.APIOperation.SEND_CHAT_ANNOUNCEMENT, "user", body, query_parameters)
	else:
		printerr("Can't cancel prediction due to missing channel id")

func start_raid(channel: String, raid_target: String) -> void:
	if await _check_user_ids([channel, raid_target]):
		var channel_id = user_list[channel]
		var target_id = user_list[raid_target]
		var query_parameters := {
			"from_broadcaster_id" : channel_id,
			"to_broadcaster_id" : target_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.START_RAID, "", {}, query_parameters)
	else:
		printerr("Can't start raid due to missing channel id")

func cancel_raid(channel: String) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.CANCEL_RAID, "", {}, query_parameters)
	else:
		printerr("Can't start raid due to missing channel id")

static func get_channel_scope() -> String:
	var scopes: Array[String]
	for operation  in TwitchAPIRequest.api_operations.values():
		var scope: String = operation["scope"]
		if (scope.begins_with("channel") \
				|| scope.begins_with("moderator") \
				|| scope.begins_with("moderation")) \
				&& !scopes.has(scope):
			scopes.append(scope)
	for event: Dictionary in events.values():
		var scope: String = event["scope"]
		# if scope.begins_with("channel") && !scopes.has(scope):
		if scope != "" && !scopes.has(scope):
			scopes.append(scope)
	var scope_str: String = ""
	for scope in scopes:
		scope_str += scope + " "
	scope_str = scope_str.trim_suffix(" ")
	return scope_str

static func get_useraccount_scope() -> String:
	var scopes: Array[String]
	for operation  in TwitchAPIRequest.api_operations.values():
		var scope: String = operation["scope"]
		if (scope.begins_with("user") || scope.begins_with("moderator")) && !scopes.has(scope):
		# if scope.begins_with("user") && !scopes.has(scope):
			scopes.append(scope)
	var scope_str: String = ""
	for scope in scopes:
		scope_str += scope + " "
	scope_str = scope_str.trim_suffix(" ")
	return scope_str

func get_channel_auth_url(_redirect_uri: String) -> String:
	# var decrypted := crypto.decrypt(key, file.get_buffer(file.get_length()))
	var query_parameters := {
		"response_type" : "token",
		"client_id" : get_client_id(),
		"redirect_uri" : _redirect_uri,
		"scope" : get_channel_scope(),
	}
	return auth_uri + "?" + HTTPClient.new().query_string_from_dict(query_parameters)

func get_useraccount_auth_url(_redirect_uri: String) -> String:
	# var decrypted := crypto.decrypt(key, file.get_buffer(file.get_length()))
	var query_parameters := {
		"response_type" : "token",
		"client_id" : get_client_id(),
		"redirect_uri" : _redirect_uri,
		"scope" : get_useraccount_scope()
	}
	return auth_uri + "?" + HTTPClient.new().query_string_from_dict(query_parameters)

func get_client_id() -> String:
	return crypto.decrypt(key, encrypted_client_id).get_string_from_utf8()

func _get_event_sub_body(event_type: EventType, channel_id: String) -> Dictionary:
	var body := { "type": "", "version": "1", "condition": { "broadcaster_user_id": channel_id}, "transport" : {"method": "websocket", "session_id": session_id}}
	var event_info: Dictionary = events[event_type]
	body["type"] = event_info["type"]
	body["version"] = event_info["version"]
	for condition in event_info["condition"]:
		match condition:
			"broadcaster_id":
				body["condition"]["broadcaster_id"] = channel_id
			"user_id":
				body["condition"]["user_id"] = channel_id
			"moderator_user_id":
				body["condition"]["moderator_user_id"] = channel_id
			"from_broadcaster_user_id":
				body["condition"]["from_broadcaster_user_id"] = channel_id
			"to_broadcaster_user_id":
				body["condition"]["to_broadcaster_user_id"] = channel_id
	return body

func _check_user_ids(usernames: Array[String]) -> bool:
	var user_ids: Array[String]
	var missing_ids: Array[String]
	for username in usernames:
		var user_id = user_list.get(username, "")
		if user_id != "":
			user_ids.append(user_id)
		else:
			missing_ids.append(username)
	if !missing_ids.is_empty():
		var query_parameters: Dictionary = { "login": missing_ids }
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_USER_INFO, "", {}, query_parameters)
		for user_info in request.response_body["data"]:
			var login_name: String = user_info["login"]
			var display_name: String = user_info["display_name"]
			var id = user_info["id"]
			user_list[login_name] = id
			user_list[display_name] = id
		for username in query_parameters["login"]:
			if !user_list.has(username):
				twitch_node.error_occured.emit(TwitchNode.ErrorCode.UNKNOWN_USER, {"username": username})
				return false
	return true

func _get_category_id(category: String) -> String:
	var query_parameters := {
		"name" = category
	}
	var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_GAMES, "", {}, query_parameters)
	for game in request.response_body["data"]:
		return game["id"]
	printerr("Category not found: %s" % category)
	return ""

func _execute_request(api_operation: TwitchAPIRequest.APIOperation, account: String, body: Dictionary = {}, query_parameters: Dictionary = {}) -> TwitchAPIRequest:
	var request := TwitchAPIRequest.new()
	add_child(request)
	request.set_request_data(self, account, api_operation, body, query_parameters)
	if rate_limit_remaining > 0:
		rate_limit_remaining -= 1
		request.execute_request()
	else:
		request_queue.push_back(request)
	await request.twitch_api_request_completed
	match request.result:
		TwitchAPIRequest.ErrorCode.INVALID_TOKEN:
			twitch_node.error_occured.emit(TwitchNode.ErrorCode.INVALID_TOKEN, {"token type" : request.account})
		TwitchAPIRequest.ErrorCode.HTTP_ERROR:
			twitch_node.error_occured.emit(TwitchNode.ErrorCode.UNAVAILABLE, {"response code" : request.response_code})
	request_pool.append(request)
	return request

func _rate_limit_loop() -> void:
	while true:
		rate_limit_remaining = min(rate_limit_remaining + 1, rate_limit)
		while !request_queue.is_empty() && rate_limit_remaining > 0:
			rate_limit_remaining -= 1
			request_queue.pop_front().execute()
		await get_tree().create_timer(1).timeout

func _request_cleanup_loop() -> void:
	while true:
		while !request_pool.is_empty():
			var request = request_pool.pop_front()
			request.queue_free()
		await get_tree().create_timer(1).timeout

func _connect_twitch_websocket() -> void:
	var ws_url := websocket_uri
	if test:
		ws_url = test_websocket_uri
	var err = socket.connect_to_url(ws_url)
	if err != OK:
		printerr("Unable to connect Twitch websocket, error code: %s" % err)
	else:
		_socket_poll_loop()

func _reconnect_twitch_websocket(reconnect_url: String) -> void:
	socket.close()
	var err = socket.connect_to_url(reconnect_url)
	if err != OK:
		printerr("Unable to reconnect Twitch websocket")

func _socket_poll_loop() -> void:
	var loop := true
	while loop:
		socket.poll()
		var state = socket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while socket.get_available_packet_count():
				var message_data: Dictionary = JSON.parse_string(socket.get_packet().get_string_from_utf8())
				if message_data != null:
					_process_message(message_data)
				else:
					printerr("Error parsing incoming twitch websocket message")
		elif state == WebSocketPeer.STATE_CLOSED:
			loop = false
			var code := socket.get_close_code()
			print("Twitch websocket closed with code: %d. Clean: %s" % [code, code != -1])
			if code != 4001 && code != 4003:
				_connect_twitch_websocket()
				await websocket_connected
				_reconnect_to_channels()
		await get_tree().create_timer(0.1).timeout

func _reconnect_to_channels() -> void:
	for channel_id in channels:
		for type in EventType.size():
			_execute_request(TwitchAPIRequest.APIOperation.SUBSCRIBE_TO_EVENT, "channel", _get_event_sub_body(type, channel_id), {})


func _process_message(message_data: Dictionary) -> void:
	match message_data["metadata"]["message_type"]:
		"session_welcome":
			session_id = message_data["payload"]["session"]["id"]
			websocket_connected.emit()
		"notification":
			var event_data: Dictionary = message_data["payload"]["event"]
			var event_type_str: String = message_data["payload"]["subscription"]["type"]
			if event_type_str.begins_with("channel.prediction"):
				prediction_info = event_data
			if event_type_str == "channel.raid":
				if channels.has(event_data["to_broadcaster_user_id"]):
					twitch_node._process_twitch_event(EventType.CHANNEL_INCOMING_RAID, event_data)
					return
				if channels.has(event_data["from_broadcaster_user_id"]):
					twitch_node._process_twitch_event(EventType.CHANNEL_OUTGOING_RAID, event_data)
					return
			for event_type in events.keys():
				if events[event_type].type == event_type_str:
					twitch_node._process_twitch_event(event_type, event_data)
					return
		"session_keepalive":
			pass
		"session_reconnect":
			_reconnect_twitch_websocket(message_data["payload"]["session"]["reconnect_url"])
		_:
			printerr("Unknown Twitch message type recieved: %s" % message_data["metadata"]["message_type"])
			printerr("Full message: %s" % message_data)

func _validation_loop() -> void:
	while true:
		_validate_token(encrypted_channel_access_token, "channel")
		_validate_token(encrypted_user_access_token, "user")
		await get_tree().create_timer(3599).timeout

func _validate_token(encrypted_token: PackedByteArray, account: String) -> void:
	token_states[account] = TwitchNode.TokenState.CHECKING
	if encrypted_token.is_empty():
		token_states[account] = TwitchNode.TokenState.EMPTY
		twitch_node.token_validated.emit(account, TwitchNode.TokenState.EMPTY)
	var header: PackedStringArray = ["Authorization: OAuth " + crypto.decrypt(key, encrypted_token).get_string_from_utf8()]
	var http_request := HTTPRequest.new()
	add_child(http_request)
	http_request.request(validate_uri, header, HTTPClient.METHOD_GET)
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	if response[1] == 200:
		token_states[account] = TwitchNode.TokenState.VALID
		twitch_node.token_validated.emit(account, TwitchNode.TokenState.VALID)
	elif response[1] == 401:
		printerr("Token invalid")
		token_states[account] = TwitchNode.TokenState.INVALID
		twitch_node.token_validated.emit(account, TwitchNode.TokenState.INVALID)
		twitch_node.error_occured.emit(TwitchNode.ErrorCode.INVALID_TOKEN, account)
	else:
		printerr("Unexpected response on token validation request: %s" % [response])

func set_credentials(client_id: String, channel_token: String, user_token: String, store: bool) -> void:
	if client_id != "":
		encrypted_client_id = crypto.encrypt(key, client_id.to_utf8_buffer())
	if channel_token != "":
		encrypted_channel_access_token = crypto.encrypt(key, channel_token.to_utf8_buffer())
		encrypted_tokens["channel"] = encrypted_channel_access_token
		_validate_token(encrypted_channel_access_token, "channel")
	if user_token != "":
		encrypted_user_access_token = crypto.encrypt(key, user_token.to_utf8_buffer())
		encrypted_tokens["user"] = encrypted_user_access_token
		_validate_token(encrypted_user_access_token, "user")
	if store:
		_store_credentials()

func _init_credentials() -> bool:
	_init_key()
	_load_credentials()
	return !encrypted_client_id.is_empty() && !encrypted_channel_access_token.is_empty() && !encrypted_user_access_token.is_empty()

func _store_credentials() -> void:
	var encrypted_credentials: Dictionary
	# TODO: test this
	encrypted_credentials["client_id"] = encrypted_client_id
	encrypted_credentials["channel_access_token"] = encrypted_channel_access_token
	encrypted_credentials["user_access_token"] = encrypted_user_access_token
	var file = FileAccess.open("user://twitch_credentials", FileAccess.WRITE)
	file.store_buffer(var_to_bytes(encrypted_credentials))

func _load_credentials() -> bool:
	if FileAccess.file_exists("user://twitch_credentials"):
		var file := FileAccess.open("user://twitch_credentials", FileAccess.READ)
		var encrypted_credentials = bytes_to_var(file.get_buffer(file.get_length()))
		encrypted_client_id = encrypted_credentials["client_id"]
		encrypted_channel_access_token = encrypted_credentials["channel_access_token"]
		encrypted_user_access_token = encrypted_credentials["user_access_token"]
		encrypted_tokens["channel"] = encrypted_channel_access_token
		encrypted_tokens["user"] = encrypted_user_access_token
		return true
	else:
		return false

func _init_key():
	if key != null:
		return key
	key = CryptoKey.new()
	var err := key.load("user://encryption.key")
	if err != 0:
		key = crypto.generate_rsa(4096)
		key.save("user://encryption.key")
