## This node handles formatting requests and rate limiting for the Twitch API.
## Don't call any functions of this node directly, use the interface of the TwitchNode node.
class_name TwitchAPI
extends Node

# enum APIOperation { GET_USER_INFO, SUBSCRIBE_TO_EVENT, POST_CHAT_MESSAGE, GET_CHANNEL_INFO, MODIFY_CHANNEL_INFO, CREATE_POLL, SEND_SHOUTOUT, BAN_USER, GET_VIPS, ADD_VIP, GET_SUBS, CREATE_PREDICTION, END_PREDICTION, START_RAID, CANCEL_RAID, WARN_USER }
enum EventType { CHANNEL_CHAT_MESSAGE, CHANNEL_UPDATE, CHANNEL_FOLLOW, CHANNEL_SUB, CHANNEL_SUB_END, CHANNEL_SUB_GIFT, CHANNEL_SUB_MESSAGE, CHANNEL_VIP_ADD, CHANNEL_VIP_REMOVE, CHANNEL_INCOMING_RAID, CHANNEL_OUTGOING_RAID, CHANNEL_POLL_BEGIN, CHANNEL_POLL_PROGRESS, CHANNEL_POLL_END, CHANNEL_PREDICTION_BEGIN, CHANNEL_PREDICTION_PROGRESS, CHANNEL_PREDICTION_LOCK, CHANNEL_PREDICTION_END, CHANNEL_POINTS_AUTOMATIC_REWARD_REDEMPTION_ADD, CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD, CHANNEL_CHEER, HYPE_TRAIN_BEGIN, HYPE_TRAIN_PROGRESS, HYPE_TRAIN_END, STREAM_ONLINE, STREAM_OFFLINE, AD_BREAK_BEGIN }

const base_uri := "https://api.twitch.tv/helix/"
const websocket_uri: String = "wss://eventsub.wss.twitch.tv/ws"
const auth_uri = "https://id.twitch.tv/oauth2/authorize"
const token_uri = "https://id.twitch.tv/oauth2/token"
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
	},
	EventType.AD_BREAK_BEGIN : {
		"type": "channel.ad_break.begin",
		"scope": "channel:read:ads",
		"version": 1,
		"condition": ["broadcaster_user_id"]
	},
}

signal websocket_connected()

var twitch_node: TwitchNode
var test := false
var rate_limit: int
var rate_limit_remaining: int
## Key: username, value: user id
var user_list: Dictionary
var invalid_users: Array
var connections: Array[Dictionary]
var poll_id: String
var prediction_info: Dictionary
## Requests queued due to rate limit
var request_queue: Array[TwitchAPIRequest]
var request_pool: Array[TwitchAPIRequest]
var session_id: String = ""
var socket := WebSocketPeer.new()

var credentials: Dictionary
var store_credentials: bool

var token_refresh_running: Dictionary

var key: CryptoKey
var crypto: Crypto

func _enter_tree():
	rate_limit = twitch_node.rate_limit
	rate_limit_remaining = twitch_node.rate_limit
	crypto = Crypto.new()
	_init_credentials()
	for user_id in credentials.get("tokens", []):
		var user_credentials = credentials["tokens"][user_id]
		user_credentials["state"] = TwitchNode.TokenState.CHECKING
		if user_credentials.get("auth_type", 0) == TwitchNode.AuthType.AUTH_CODE:
			_refresh_token_cycle(user_id)

func _ready() -> void:
	_validation_loop()
	_rate_limit_loop()
	_request_cleanup_loop()

func connect_to_channel(channel: String, username: String = "") -> void:
	var usernames: Array[String] = [channel, username]
	if !await _check_user_ids(usernames):
		printerr("Can't connect to channel due to missing channel id")
		return
	var channel_id = user_list[channel]
	var user_id = user_list[username]
	var token_info: Dictionary = credentials.get("tokens", {}).get(user_id, {})
	if token_info.is_empty():
		printerr("Can't connect to channel due to missing token for user %s" % username)
		return
	var token_state: TwitchNode.TokenState = token_info.get("state", TwitchNode.TokenState.EMPTY)
	while token_state == TwitchNode.TokenState.CHECKING \
			|| token_state == TwitchNode.TokenState.REFRESHING:
		await twitch_node.token_validated
		token_state = token_info.get("state", TwitchNode.TokenState.EMPTY)
	if token_state != TwitchNode.TokenState.VALID:
		printerr("Can't connect to channel due to invalid token for user %s" % username)
		return
	if session_id == "":
		_connect_twitch_websocket()
		await websocket_connected
	var scopes := _get_token_scopes(user_id)
	for event in events:
		var event_info: Dictionary = events[event]
		var scope: String = event_info["scope"]
		if scope == "" || scopes.has(scope):
			if (scope.begins_with("channel") || scope.begins_with("bits")) && channel_id != user_id:
				continue
			_execute_request(TwitchAPIRequest.APIOperation.SUBSCRIBE_TO_EVENT, user_id, _get_event_sub_body(event, channel_id, user_id), {})
	connections.append({"channel_id": channel_id, "user_id": user_id})

func send_chat_message(channel: String, username: String, message: String) -> void:
	if await _check_user_ids([channel, username]):
		var channel_id = user_list.get(channel, "")
		var user_id = user_list.get(username, "")
		var body :=	{ "broadcaster_id": channel_id, "sender_id": user_id, "message" : message }
		_execute_request(TwitchAPIRequest.APIOperation.POST_CHAT_MESSAGE, user_id, body)
	else:
		printerr("Can't send chat message as %s due to missing user ids" % username)

func get_channel_info(channel: String) -> Dictionary:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id
		}
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_CHANNEL_INFO, "", {}, query_parameters)
		if request.response_body.get("data",[]).size() > 0:
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
		await _execute_request(TwitchAPIRequest.APIOperation.MODIFY_CHANNEL_INFO, channel_id, body, query_parameters)
	else:
		printerr("Can't update channel info due to missing channel id")
	
func get_streams(broadcasters: Array[String], game_ids: Array[String] = [], live_only: bool = false, languages: Array[String] = ["en"]) -> Array:
	if await _check_user_ids(broadcasters):
		var user_ids: Array[String]
		for broadcaster in broadcasters:
			user_ids.append(user_list.get(broadcaster,""))
		var query_parameters := {
			"user_id": user_ids,
			"game_id": game_ids,
			"type": "live" if live_only else "all",
			"language": languages,
			"first": 100
		}
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_STREAMS, "", {}, query_parameters)
		if !request.response_body.is_empty():
			return request.response_body["data"]
		else:
			twitch_node.error_occured.emit(TwitchNode.ErrorCode.BAD_INPUT, {"message" : "Error getting streams from Twitch"})
			printerr("Error getting streams from Twitch")
			return []
	else:
		printerr("Can't get streams due to invalid broadcaster name")
		return []

func send_shoutout(channel: String, auth_username: String, shoutout_channel: String) -> void:
	if await _check_user_ids([channel, auth_username, shoutout_channel]):
		var channel_id = user_list.get(channel, "")
		var user_id = user_list.get(auth_username, "")
		var shoutout_channel_id = user_list.get(shoutout_channel, "")
		var body := {
			"from_broadcaster_id": channel_id,
			"to_broadcaster_id": shoutout_channel_id,
			"moderator_id": channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.SEND_SHOUTOUT, user_id, body)
	else:
		printerr("Can't send shoutout to %s due to missing user ids" % shoutout_channel)

func create_custom_reward(channel: String, title: String, cost: int, explanation: String, is_enabled: bool = true, is_user_input_required: bool = false, max_per_stream: int = 0, max_per_user: int = 0, global_cooldown_s: int = 0, skip_request_queue: bool = false, background_color: Color = Color.WHITE) -> String:
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
			body["background_color"] = "#%s" % background_color.to_html(false)
		if max_per_stream > 0:
			body["is_max_per_stream_enabled"] = true
			body["max_per_stream"] = max_per_stream
		if max_per_user > 0:
			body["is_max_per_user_per_stream_enabled"] = true
			body["max_per_user_per_stream"] = max_per_user
		if global_cooldown_s > 0:
			body["is_global_cooldown_enabled"] = true
			body["global_cooldown_seconds"] = global_cooldown_s
		var result := await _execute_request(TwitchAPIRequest.APIOperation.CREATE_CUSTOM_REWARD, channel_id, body, query_parameters)
		if !result.response_body.is_empty():
			return result.response_body["data"][0]["id"]
		elif result.response_code == 400:
			printerr("Reward creation failed. Maybe another reward with the same title already exists")
		else:
			printerr("Reward creation failed. Return code %s" % result.response_code)
		return ""
	else:
		printerr("Can't create reward due to missing channel id")
		return ""

func get_custom_rewards(channel: String, ids: Array[String] = [], only_manageable: bool = false) -> Array:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id,
			"id": ids,
			"only_manageable": only_manageable
		}
		var result := await _execute_request(TwitchAPIRequest.APIOperation.GET_CUSTOM_REWARDS, channel_id, {}, query_parameters)
		if !result.response_body.is_empty():
			return result.response_body["data"]
		else:
			return []
	else:
		return []

func update_custom_reward(channel: String, reward_id: String, title: String = "", cost: int = 0, explanation: String = "", is_user_input_required: bool = false, is_enabled: bool = true, is_paused: bool = false, max_per_stream: int = 0, max_per_user: int = 0, global_cooldown_s: int = 0, skip_request_queue: bool = false, background_color: Color = Color.WHITE) -> void:
	var channel_id = user_list.get(channel, "")
	var rewards := await get_custom_rewards(channel, [reward_id], true)

	if !rewards.is_empty() && await _check_user_ids([channel]):
		var reward_info = rewards[0]
		var query_parameters := {
			"broadcaster_id": channel_id,
			"id": reward_id
		}
		var body := {}
		if reward_info["title"] != title:
			body["title"] = title
		if reward_info["prompt"] != explanation:
			body["prompt"] = explanation
		if reward_info["cost"] != cost:
			body["cost"] = cost
		if reward_info["background_color"] != background_color.to_html(false):
			body["background_color"] = "#%s" % background_color.to_html(false)
		if reward_info["is_enabled"] != is_enabled:
			body["is_enabled"] = is_enabled
		if reward_info["is_user_input_required"] != is_user_input_required:
			body["is_user_input_required"] = is_user_input_required
		var is_max_per_stream_enabled: bool = (max_per_stream > 0)
		if reward_info["max_per_stream_setting"]["is_enabled"] != is_max_per_stream_enabled:
			body["is_max_per_stream_enabled"] = is_max_per_stream_enabled
		if reward_info["max_per_stream_setting"]["max_per_stream"] != max_per_stream:
			body["max_per_stream"] = max_per_stream
		var is_max_per_user_enabled: bool = (max_per_user > 0)
		if reward_info["max_per_user_per_stream_setting"]["is_enabled"] != is_max_per_user_enabled:
			body["is_max_per_user_per_stream_enabled"] = is_max_per_user_enabled
		if reward_info["max_per_user_per_stream_setting"]["max_per_user_per_stream"] != max_per_user:
			body["max_per_user_per_stream"] = max_per_user
		var is_global_cooldown_enabled: bool = (global_cooldown_s > 0)
		if reward_info["global_cooldown_setting"]["is_enabled"] != is_global_cooldown_enabled:
			body["is_global_cooldown_enabled"] = is_global_cooldown_enabled
		if reward_info["global_cooldown_setting"]["global_cooldown_seconds"] != global_cooldown_s:
			body["global_cooldown_seconds"] = global_cooldown_s
		if reward_info["is_paused"] != is_paused:
			body["is_paused"] = is_paused
		if reward_info["should_redemptions_skip_request_queue"] != skip_request_queue:
			body["should_redemptions_skip_request_queue"] = skip_request_queue
		await _execute_request(TwitchAPIRequest.APIOperation.UPDATE_CUSTOM_REWARD, channel_id, body, query_parameters)
	elif rewards.is_empty():
		printerr("Reward update failed: can't find reward with id %s" % reward_id)
	else:
		printerr("Can't update reward due to missing channel id")

func enable_custom_reward(channel: String, reward_id: String, is_enabled = false) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id,
			"id": reward_id
		}
		var body := {
			"is_enabled": is_enabled,
		}
		await _execute_request(TwitchAPIRequest.APIOperation.UPDATE_CUSTOM_REWARD, channel_id, body, query_parameters)
	else:
		printerr("Can't create reward due to missing channel id")

func pause_custom_reward(channel: String, reward_id: String, is_paused = false) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list.get(channel, "")
		var query_parameters := {
			"broadcaster_id": channel_id,
			"id": reward_id
		}
		var body := {
			"is_paused": is_paused,
		}
		await _execute_request(TwitchAPIRequest.APIOperation.UPDATE_CUSTOM_REWARD, channel_id, body, query_parameters)
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
		await _execute_request(TwitchAPIRequest.APIOperation.UPDATE_REDEMPTION_STATUS, channel_id, body, query_parameters)
	else:
		printerr("Can't update redemption status due to missing channel id")
	
func warn_user(channel: String, username: String, warned_username: String, reason: String) -> void:
	if await _check_user_ids([channel, username, warned_username]):
		var channel_id = user_list.get(channel, "")
		var user_id = user_list.get(username, "")
		var warned_user_id = user_list.get(warned_username, "")
		var query_parameters := {
			"broadcaster_id" = channel_id,
			"moderator_id" = channel_id,
		}
		var body := {
			"data" = {"user_id": warned_user_id, "reason": reason}
		}
		_execute_request(TwitchAPIRequest.APIOperation.WARN_USER, user_id, body, query_parameters)
	else:
		printerr("Can't warn user %s due to missing user ids" % warned_username)

func ban_user(channel: String, username: String, banned_username: String, duration: int = -1, reason: String = "") -> void:
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
		_execute_request(TwitchAPIRequest.APIOperation.BAN_USER, username, body, query_parameters)
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
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_VIPS, channel_id, {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get vips due to missing channel id")
		return {}

func add_vip(channel: String, vip_username: String) -> void:
	if await _check_user_ids([channel, vip_username]):
		var channel_id = user_list[channel]
		var vip_user_id = user_list[vip_username]
		var query_parameters := {
			"user_id" : vip_user_id,
			"broadcaster_id" : channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.ADD_VIP, channel_id, {}, query_parameters)
	else:
		printerr("Can't add %s as vip due to missing user ids" % vip_username)

func remove_vip(channel: String, vip_username: String) -> void:
	if await _check_user_ids([channel, vip_username]):
		var channel_id = user_list[channel]
		var vip_user_id = user_list[vip_username]
		var query_parameters := {
			"user_id" : vip_user_id,
			"broadcaster_id" : channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.REMOVE_VIP, channel_id, {}, query_parameters)
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
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_SUBS, channel_id, {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get subs due to missing channel id")
		return {}

func get_followers(channel: String, auth_username: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get follow info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel, auth_username]):
		var channel_id = user_list[channel]
		var auth_user_id = user_list[auth_username]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["after"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_FOLLOWERS, auth_user_id, {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get followers due to missing channel id or auth user id")
		return {}

func get_moderators(channel: String, auth_username: String, page: String = "", user: String = "") -> Dictionary:
	var user_id := ""
	if user != "":
		if await _check_user_ids([user]):
			user_id = user_list[user]
		else:
			printerr("Can't get moderator info for unknown user %s" % user)
			return {}
	if await _check_user_ids([channel, auth_username]):
		var channel_id = user_list[channel]
		var auth_user_id = user_list[auth_username]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"first" : 100,
		}
		if page != "":
			query_parameters["after"] = page
		if user_id != "":
			query_parameters["user_id"] = user_id
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_MODERATORS, auth_user_id, {}, query_parameters)
		return request.response_body
	else:
		printerr("Can't get moderators due to missing channel id or auth user id")
		return {}

func create_poll(channel: String, poll_title: String, poll_choices: Array[String], poll_duration: int) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := { 
			"broadcaster_id": channel_id, 
			"title": poll_title.left(60), 
			"choices": [],
			"duration": poll_duration,
		}
		for choice: String in poll_choices:
			body["choices"].append({ "title" : choice.left(25)})
		_execute_request(TwitchAPIRequest.APIOperation.CREATE_POLL, channel_id, body)
	else:
		printerr("Can't create poll due to missing channel id")

func create_prediction(channel: String, prediction_title: String, prediction_outcomes: Array[String], prediction_duration: int) -> void:
	if prediction_outcomes.size() > 10:
		printerr("Can't create prediction with more than 10 outcomes")
		return
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var body := {
			"broadcaster_id" : channel_id,
			"title" : prediction_title.left(45),
			"outcomes": [],
			"prediction_window" : prediction_duration,
		}
		for outcome in prediction_outcomes:
			body["outcomes"].append({"title": outcome.left(25)})
		var request := await _execute_request(TwitchAPIRequest.APIOperation.CREATE_PREDICTION, channel_id, body)
		if request.response_code == 200:
			prediction_info = request.response_body["data"][0]
		else:
			printerr("Can't create prediction. Perhaps another prediction is still active")
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
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, channel_id, body)
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
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, channel_id, body)
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
		_execute_request(TwitchAPIRequest.APIOperation.END_PREDICTION, channel_id, body)
	else:
		printerr("Can't cancel prediction due to missing channel id")

func send_chat_announcement(channel: String, auth_username: String, message: String, color: String = "") -> void:
	if await _check_user_ids([channel, auth_username]):
		var channel_id = user_list[channel]
		var user_id = user_list[auth_username]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"moderator_id" : user_id,
		}
		var body := {
			"message" : message,
		}
		if color == "blue" || color == "green" || color == "orange" || color == "purple":
			body["color"] = color
		_execute_request(TwitchAPIRequest.APIOperation.SEND_CHAT_ANNOUNCEMENT, user_id, body, query_parameters)
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
		_execute_request(TwitchAPIRequest.APIOperation.START_RAID, channel_id, {}, query_parameters)
	else:
		printerr("Can't start raid due to missing channel id")

func cancel_raid(channel: String) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
		}
		_execute_request(TwitchAPIRequest.APIOperation.CANCEL_RAID, channel_id, {}, query_parameters)
	else:
		printerr("Can't start raid due to missing channel id")

func start_commercial(channel: String, length: int) -> void:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
			"length" : length
		}
		_execute_request(TwitchAPIRequest.APIOperation.START_COMMERCIAL, channel_id, {}, query_parameters)
	else:
		printerr("Can't start ads due to missing channel id")

func get_ad_schedule(channel: String) -> Dictionary:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
		}
		var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_AD_SCHEDULE, channel_id, {}, query_parameters)
		if !request.response_body.is_empty():
			return request.response_body["data"][0]
		else:
			return {}
	else:
		printerr("Can't start ads due to missing channel id")
		return {}

func snooze_next_ad(channel: String) -> Dictionary:
	if await _check_user_ids([channel]):
		var channel_id = user_list[channel]
		var query_parameters := {
			"broadcaster_id" : channel_id,
		}
		var request := await _execute_request(TwitchAPIRequest.APIOperation.SNOOZE_NEXT_AD, channel_id, {}, query_parameters)
		if !request.response_body.is_empty():
			return request.response_body["data"][0]
		else:
			return {}
	else:
		printerr("Can't snooze ads due to missing channel id")
		return {}

func get_auth_url(_scopes: Array[String], _auth_type: TwitchNode.AuthType, _redirect_uri: String, _state: String = "") -> String:
	var scopes_str: String
	for scope in _scopes:
		scopes_str += scope + " "
	scopes_str = scopes_str.trim_suffix(" ")
	var query_parameters := {
		"response_type" : "token" if _auth_type == TwitchNode.AuthType.IMPLICIT else "code",
		"client_id" : get_client_id(),
		"redirect_uri" : _redirect_uri,
		"scope" : scopes_str,
		"force_verify" : true,
	}
	if _state != "":
		query_parameters["state"] = _state
	return auth_uri + "?" + HTTPClient.new().query_string_from_dict(query_parameters)

func get_client_id() -> String:
	return crypto.decrypt(key, credentials["client_id"]).get_string_from_utf8()

func has_client_secret() -> bool:
	return !credentials.get("client_secret",[]).is_empty()

func get_token_state(username: String) -> TwitchNode.TokenState:
	if !await _check_user_ids([username]):
		printerr("Error getting token state for unkown user %s" % username)
		return TwitchNode.TokenState.EMPTY
	var user_id = user_list[username]
	return credentials.get("tokens", {}).get(user_id, {}).get("state", TwitchNode.TokenState.EMPTY)

func get_token_scopes(username: String) -> Array[String]:
	var scopes: Array[String] = []
	if !await _check_user_ids([username]):
		printerr("Error fetching token scopes: account %s not found" % username)
	return _get_token_scopes(user_list[username])

func _get_token_scopes(user_id: String) -> Array[String]:
	var scopes: Array[String] = []
	scopes.assign(credentials.get("tokens",{}).get(user_id, {}).get("scopes", []))
	return scopes

func get_scopes() -> Array[String]:
	var scopes: Array[String]
	for operation in TwitchAPIRequest.api_operations.values():
		var scope: String = operation["scope"]
		if scope != "" && !scopes.has(scope):
			scopes.append(scope)
	for event: Dictionary in events.values():
		var scope: String = event["scope"]
		if scope != "" && !scopes.has(scope):
			scopes.append(scope)
	scopes.sort()
	return scopes

func _get_event_sub_body(event_type: EventType, channel_id: String, user_id: String) -> Dictionary:
	var body := { "type": "", "version": "1", "condition": { "broadcaster_user_id": channel_id}, "transport" : {"method": "websocket", "session_id": session_id}}
	var event_info: Dictionary = events[event_type]
	body["type"] = event_info["type"]
	body["version"] = event_info["version"]
	for condition in event_info["condition"]:
		match condition:
			"broadcaster_id":
				body["condition"]["broadcaster_id"] = channel_id
			"user_id":
				body["condition"]["user_id"] = user_id
			"moderator_user_id":
				body["condition"]["moderator_user_id"] = user_id
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
		if request.response_code == 200:
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

func _get_user_info(user_id: String) -> Dictionary:
	var query_parameters: Dictionary = { "id": user_id }
	var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_USER_INFO, "", {}, query_parameters)
	if request.response_code == 200:
		var user_info: Dictionary = request.response_body.get("data",[{}])[0]
		var login: String = user_info.get("login", "")
		if login != "":
			user_list[login] = user_id
		var display_name: String = user_info.get("display_name")
		if display_name != "":
			user_list[display_name] = user_id
		return user_info
	else:
		return {}

func _get_category_id(category: String) -> String:
	var query_parameters := {
		"name" = category
	}
	var request := await _execute_request(TwitchAPIRequest.APIOperation.GET_GAMES, "", {}, query_parameters)
	for game in request.response_body["data"]:
		return game["id"]
	printerr("Category not found: %s" % category)
	return ""

func _execute_request(api_operation: TwitchAPIRequest.APIOperation, user_id: String, body: Dictionary = {}, query_parameters: Dictionary = {}) -> TwitchAPIRequest:
	var request := TwitchAPIRequest.new()
	add_child(request)
	if user_id == "":
		var tokens: Dictionary = credentials.get("tokens", {})
		if tokens.is_empty():
			printerr("Error executing request operation %s: no tokens available" % api_operation)
		user_id = tokens.keys()[0]
	request.set_request_data(self, user_id, api_operation, body, query_parameters)
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
			request_queue.pop_front().execute_request()
		await get_tree().create_timer(1).timeout

func _request_cleanup_loop() -> void:
	while true:
		while !request_pool.is_empty():
			var request = request_pool.pop_front()
			request.queue_free()
		await get_tree().create_timer(1).timeout

func _connect_twitch_websocket() -> void:
	if socket.get_ready_state() != WebSocketPeer.State.STATE_CLOSED:
		return
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
		await get_tree().create_timer(0.01).timeout

func _reconnect_to_channels() -> void:
	for connection in connections:
		var channel_id = connection["channel_id"]
		var user_id = connection["user_id"]
		var token_info: Dictionary = credentials.get("tokens", {}).get(user_id, {})
		if token_info.is_empty():
			printerr("Can't connect to channel due to missing token for userid %s" % user_id)
			continue
		var token_state: TwitchNode.TokenState = token_info["state"]
		while token_state == TwitchNode.TokenState.CHECKING \
				|| token_state == TwitchNode.TokenState.REFRESHING:
			await twitch_node.token_validated
			token_state = token_info["state"]
		if token_state != TwitchNode.TokenState.VALID:
			printerr("Can't connect to channel due to invalid token for userid %s" % user_id)
			continue
		if session_id == "":
			_connect_twitch_websocket()
			await websocket_connected
		var scopes := _get_token_scopes(user_id)
		for event in events:
			var event_info: Dictionary = events[event]
			var scope: String = event_info["scope"]
			if scopes.has(scope):
				if (scope.begins_with("channel") || scope.begins_with("bits")) && channel_id != user_id:
					continue
				_execute_request(TwitchAPIRequest.APIOperation.SUBSCRIBE_TO_EVENT, user_id, _get_event_sub_body(event, channel_id, user_id), {})

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
				for connection in connections:
					if connection["channel_id"] == event_data["to_broadcaster_user_id"]:
						twitch_node._process_twitch_event(EventType.CHANNEL_INCOMING_RAID, event_data)
					if connection["channel_id"] == event_data["from_broadcaster_user_id"]:
						twitch_node._process_twitch_event(EventType.CHANNEL_OUTGOING_RAID, event_data)
				return
			for event_type in events.keys():
				if events[event_type].type == event_type_str:
					twitch_node._process_twitch_event(event_type, event_data)
					return
		"session_keepalive":
			pass
		"session_reconnect":
			print("Received reconnect message: %s" % JSON.stringify(message_data,"\t"))
			_reconnect_twitch_websocket(message_data["payload"]["session"]["reconnect_url"])
		_:
			printerr("Unknown Twitch message type recieved: %s" % message_data["metadata"]["message_type"])
			printerr("Full message: %s" % message_data)


func _validation_loop() -> void:
	while true:
		var tokens: Dictionary = credentials.get("tokens", {})
		for user_id in tokens:
			var validation_info := await _validate_token(tokens[user_id]["access_token"])
			var validation_user_id = validation_info.get("user_id", "")
			if validation_user_id != "":
				if validation_user_id != user_id:
					printerr("Validated token belongs to a different user: %s instead of %s" % [validation_user_id, user_id])
					tokens[validation_user_id] = tokens[user_id]
					tokens.erase(user_id)
					user_id = validation_user_id
				var scopes: Array[String]
				scopes.assign(validation_info.get("scopes", []))
				tokens[validation_user_id]["scopes"] = scopes
				tokens[validation_user_id]["state"] = TwitchNode.TokenState.VALID
			elif validation_info.get("status", 0) == 401:
				tokens[user_id]["state"] = TwitchNode.TokenState.INVALID
				var user_info := await _get_user_info(user_id)
				twitch_node.error_occured.emit(TwitchNode.ErrorCode.INVALID_TOKEN, {"username" : user_info.get("login", "")})
			else:
				printerr("Unkown response from token validation: %s" % validation_info)
				tokens[user_id]["state"] = TwitchNode.TokenState.UNKNOWN
			twitch_node.token_validated.emit(validation_info.get("login", ""), tokens[user_id]["state"])
		await get_tree().create_timer(3599).timeout

func _validate_token(encrypted_access_token: PackedByteArray) -> Dictionary:
	var header: PackedStringArray = ["Authorization: OAuth " + crypto.decrypt(key, encrypted_access_token).get_string_from_utf8()]
	var http_request := HTTPRequest.new()
	http_request.use_threads = true
	add_child(http_request)
	http_request.request(validate_uri, header, HTTPClient.METHOD_GET)
	var response: Array = await http_request.request_completed
	http_request.queue_free()
	if response.size() > 1 && (response[1] == 200 || response[1] == 401):
		var validation_info: Dictionary = JSON.parse_string(response[3].get_string_from_utf8())
		return validation_info
	else:
		printerr("Unexpected response on token validation request: %s" % [response])
		return {}

func add_token(_token: String, auth_type: TwitchNode.AuthType, _scopes: Array[String], _redirect_uri: String) -> String:
	var user_id: String
	var encrypted_access_token := crypto.encrypt(key, _token.to_utf8_buffer())
	var encrypted_refresh_token: PackedByteArray
	var real_scopes: Array[String] = []
	var state: TwitchNode.TokenState

	match auth_type:
		TwitchNode.AuthType.AUTH_CODE:
			var result := await _request_token(_token, _redirect_uri, "")
			if result.is_empty():
				printerr("Error: token request failed when adding token")
				return ""
			else:
				encrypted_access_token = crypto.encrypt(key, result.get("access_token").to_utf8_buffer())
				encrypted_refresh_token = crypto.encrypt(key, result.get("refresh_token").to_utf8_buffer())
		TwitchNode.AuthType.IMPLICIT:
			encrypted_access_token = crypto.encrypt(key, _token.to_utf8_buffer())

	var result := await _validate_token(encrypted_access_token)
	if result.get("status", 200) == 401:
		return ""
	elif result.is_empty():
		printerr("Error: token validation failed when adding token")
		return ""
	else:
		real_scopes.assign(result["scopes"])
		user_id = result["user_id"]
	for scope in _scopes:
		assert(real_scopes.has(scope), "Add token error: scope %s passed in input not present in real token scope")
	for scope in real_scopes:
		assert(_scopes.has(scope), "Add token error: scope %s in real token scope not passed in input")
	var expires_at: int = Time.get_unix_time_from_system() + result["expires_in"]
	if !credentials.has("tokens"):
		credentials["tokens"] = {}
	credentials["tokens"][user_id] = { "auth_type" : auth_type, "access_token" : encrypted_access_token, "scopes" : real_scopes, "state" : TwitchNode.TokenState.VALID, "expires_at" : expires_at}
	if auth_type == TwitchNode.AuthType.AUTH_CODE:
		credentials["tokens"][user_id]["refresh_token"] = encrypted_refresh_token
		_refresh_token_cycle(user_id)
	if store_credentials:
		_store_credentials()
	var user_info := await _get_user_info(user_id)
	twitch_node.token_validated.emit(user_info["login"], credentials["tokens"][user_id]["state"])
	return user_info.get("login", "")

func delete_token(account: String) -> void:
	var tokens: Dictionary = credentials.get("tokens", {})
	await _check_user_ids([account])
	var user_id = user_list[account]
	tokens.erase(user_id)
	if store_credentials:
		_store_credentials()
	twitch_node.token_validated.emit(account, TwitchNode.TokenState.DELETED)

func set_credentials(client_id: String, client_secret: String, store: bool) -> void:
	if client_id != "":
		credentials["client_id"] = crypto.encrypt(key, client_id.to_utf8_buffer())
	if client_secret != "":
		credentials["client_secret"] = crypto.encrypt(key, client_secret.to_utf8_buffer())
	store_credentials = store
	if store:
		_store_credentials()

func get_token_accounts() -> Array[String]:
	var user_ids: Array[String]
	user_ids.assign(credentials.get("tokens", {}).keys())
	var usernames: Array[String]
	for user_id in user_ids:
		var user_info := await _get_user_info(user_id)
		var username: String = user_info.get("login", "")
		if username == "":
			printerr("Error getting token accounts: user id %s not found" % user_id)
		else:
			usernames.append(username)
	return usernames

func _request_token(authorization_code: String, redirect_uri: String, account: String) -> Dictionary:
	var query_parameters := {
		"client_id": crypto.decrypt(key,credentials["client_id"]).get_string_from_utf8(),
		"client_secret": crypto.decrypt(key,credentials["client_secret"]).get_string_from_utf8(),
		"code": authorization_code,
		"grant_type": "authorization_code",
		"redirect_uri": "%s" % [redirect_uri],
	}
	var request := HTTPRequest.new()
	request.use_threads = true
	add_child(request)
	var headers: PackedStringArray = ["Content-Type: application/x-www-form-urlencoded"]
	request.request("%s?%s" % [token_uri,HTTPClient.new().query_string_from_dict(query_parameters)],headers,HTTPClient.METHOD_POST, "")
	var result: Array = await request.request_completed
	request.queue_free()
	if result.size() < 4 || result[0] != 0 || result[1] < 200 || result[1] > 299:
		var error_details: String
		if !result.is_empty():
			error_details += "Result code %s" % result[0]
		if result.size() > 1:
			error_details += ", response code %s" % result[1]
		if result.size() > 3:
			error_details += ", %s" % result[3].get_string_from_utf8()
		printerr("Error requesting refresh token: %s" % [error_details])
		return {}
	var response_body: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
	if response_body.is_empty():
		printerr("Error requesting refresh token: empty response body, %s" % [result])
	return response_body

func _refresh_token_cycle(user_id: String) -> void:
	if credentials.get("tokens", {}).get(user_id, {}).get("refresh_token", "").is_empty():
		printerr("Can't run refresh cycle without refresh token for user id %s" % user_id)
		return
	token_refresh_running[user_id] = true
	while true:
		var user_credentials: Dictionary = credentials.get("tokens", {}).get(user_id, {})
		if user_credentials.is_empty():
			printerr("Stopping refresh cycle for userid %s: credentials removed" % user_id)
			token_refresh_running.erase(user_id)
			return
		var auth_type: TwitchNode.AuthType = user_credentials.get("auth_type", 0)
		if auth_type != TwitchNode.AuthType.AUTH_CODE:
			printerr("Stopping refresh cycle for userid %s: auth type changed" % user_id)
			token_refresh_running[user_id] = false
			return
		var refresh_token: PackedByteArray = user_credentials.get("refresh_token", [])
		if refresh_token.is_empty():
			printerr("Stopping refresh cycle for userid %s: no refresh token" % user_id)
		var expires_at: int = user_credentials.get("expires_at", 0)
		if expires_at == 0:
			printerr("Stopping refresh cycle for userid %s: not expire time info" % user_id)
			token_refresh_running[user_id] = false
			return
		var lifetime: int = expires_at - Time.get_unix_time_from_system()
		if lifetime > 60:
			await get_tree().create_timer(min(60, lifetime - 60)).timeout
		else:
			user_credentials["state"] = TwitchNode.TokenState.REFRESHING
			var query_parameters := {
				"client_id": crypto.decrypt(key, credentials["client_id"]).get_string_from_utf8(),
				"client_secret": crypto.decrypt(key, credentials["client_secret"]).get_string_from_utf8(),
				"grant_type": "refresh_token",
				"refresh_token": crypto.decrypt(key, refresh_token).get_string_from_utf8(),
			}
			var request := HTTPRequest.new()
			request.use_threads = true
			add_child(request)
			# print("%s?%s" % [token_uri, HTTPClient.new().query_string_from_dict(query_parameters)])
			request.request("%s?%s" % [token_uri, HTTPClient.new().query_string_from_dict(query_parameters)], [], HTTPClient.METHOD_POST, "")
			var result: Array = await request.request_completed
			request.queue_free()
			if result.size() < 4 || result[0] != 0 || result[1] < 200 || result[1] > 299:
				printerr("Error refreshing token for userid %s: %s" % [user_id, result])
				token_refresh_running[user_id] = false
				user_credentials["state"] = TwitchNode.TokenState.INVALID
				# TODO: handle failures and update state
				return
			var response_body: Dictionary = JSON.parse_string(result[3].get_string_from_utf8())
			if !response_body.is_empty():
				user_credentials["access_token"] = crypto.encrypt(key,response_body["access_token"].to_utf8_buffer())
				if response_body.get("refresh_token", "") != "":
					user_credentials["refresh_token"] = crypto.encrypt(key,response_body["refresh_token"].to_utf8_buffer())
				user_credentials["state"] = TwitchNode.TokenState.VALID
				user_credentials["expires_at"] = floori(Time.get_unix_time_from_system()) + response_body["expires_in"]
				_store_credentials()
			else:
				printerr("Error refreshing token for userid %s: %s" % [user_id, result])
				token_refresh_running[user_id] = false
				user_credentials["state"] = TwitchNode.TokenState.INVALID
			var user_info := await _get_user_info(user_id)
			twitch_node.token_validated.emit(user_info["login"], user_credentials["state"])

func _init_credentials() -> bool:
	_init_key()
	credentials["version"] = "2.0"
	credentials["client_id"] = []
	credentials["client_secret"] = []
	_load_credentials()
	return !credentials["client_id"].is_empty()

func _store_credentials() -> void:
	if !DirAccess.dir_exists_absolute("user://TwitchNode"):
		DirAccess.make_dir_absolute("user://TwitchNode")
	var file = FileAccess.open("user://TwitchNode/twitch_credentials", FileAccess.WRITE)
	file.store_buffer(var_to_bytes(credentials))

func _load_credentials() -> bool:
	if FileAccess.file_exists("user://twitch_credentials"):
		var file := FileAccess.open("user://twitch_credentials", FileAccess.READ)
		credentials = bytes_to_var(file.get_buffer(file.get_length()))
		credentials["version"] = "0.2"
		_store_credentials()
		DirAccess.remove_absolute("user://twitch_credentials")
		return true
	elif FileAccess.file_exists("user://TwitchNode/twitch_credentials"):
		var file := FileAccess.open("user://TwitchNode/twitch_credentials", FileAccess.READ)
		credentials = bytes_to_var(file.get_buffer(file.get_length()))
		if credentials["version"] != "2.0":
			credentials["version"] = "2.0"
			credentials.erase("auth_type")
			credentials.erase("channel")
			credentials.erase("user")
			credentials.erase("channel_refresh_token")
			credentials.erase("user_refresh_token")
		store_credentials = true
		return true
	else:
		return false

func _init_key() -> void:
	if key != null:
		return 
	key = CryptoKey.new()
	if !DirAccess.dir_exists_absolute("user://TwitchNode"):
		DirAccess.make_dir_absolute("user://TwitchNode")
	if FileAccess.file_exists("user://encryption.key"):
		if !DirAccess.dir_exists_absolute("user://TwitchNode"):
			DirAccess.make_dir_absolute("user://TwitchNode")
		DirAccess.copy_absolute("user://encryption.key", "user://TwitchNode/encryption.key")
		DirAccess.remove_absolute("user://encryption.key")
	var err := key.load("user://TwitchNode/encryption.key")
	if err != 0:
		key = crypto.generate_rsa(4096)
		key.save("user://TwitchNode/encryption.key")
