class_name TwitchAPIRequest
extends HTTPRequest

enum APIOperation { GET_USER_INFO, GET_GAMES, SUBSCRIBE_TO_EVENT, POST_CHAT_MESSAGE, GET_CHANNEL_INFO, MODIFY_CHANNEL_INFO, GET_STREAMS, CREATE_POLL, SEND_SHOUTOUT, BAN_USER, GET_VIPS, ADD_VIP, REMOVE_VIP, GET_SUBS, GET_FOLLOWERS, GET_MODERATORS, CREATE_PREDICTION, END_PREDICTION, START_RAID, CANCEL_RAID, WARN_USER, GET_CUSTOM_REWARDS, CREATE_CUSTOM_REWARD, UPDATE_CUSTOM_REWARD, UPDATE_REDEMPTION_STATUS, SEND_CHAT_ANNOUNCEMENT, START_COMMERCIAL, GET_AD_SCHEDULE, SNOOZE_NEXT_AD }
enum ErrorCode { OK, INVALID_TOKEN, HTTP_ERROR, REQUEST_ERROR }

signal twitch_api_request_completed(request: TwitchAPIRequest, result: Result)

const base_uri := "https://api.twitch.tv/helix/"
const test_base_uri := "http://127.0.0.1:8080/"
const api_operations: Dictionary = {
	APIOperation.GET_USER_INFO: {
		"endpoint": "users",
		"scope": "",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.GET_GAMES: {
		"endpoint": "games",
		"scope": "",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.SUBSCRIBE_TO_EVENT: {
		"endpoint": "eventsub/subscriptions",
		"scope": "",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.POST_CHAT_MESSAGE: {
		"endpoint": "chat/messages",
		"scope": "user:write:chat",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.GET_CHANNEL_INFO: {
		"endpoint": "channels",
		"scope": "",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.MODIFY_CHANNEL_INFO: {
		"endpoint": "channels",
		"scope": "channel:manage:broadcast",
		"method": HTTPClient.METHOD_PATCH
	},
	APIOperation.GET_STREAMS: {
		"endpoint": "streams",
		"scope": "",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.CREATE_POLL: {
		"endpoint": "polls",
		"scope": "channel:manage:polls",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.SEND_SHOUTOUT: {
		"endpoint": "chat/shoutouts",
		"scope": "moderator:manage:shoutouts",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.BAN_USER: {
		"endpoint": "moderation/bans",
		"scope": "moderator:manage:banned_users",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.GET_VIPS: {
		"endpoint": "channels/vips",
		"scope": "channel:read:vips",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.ADD_VIP: {
		"endpoint": "channels/vips",
		"scope": "channel:manage:vips",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.REMOVE_VIP: {
		"endpoint": "channels/vips",
		"scope": "channel:manage:vips",
		"method": HTTPClient.METHOD_DELETE
	},
	APIOperation.GET_SUBS: {
		"endpoint": "subscriptions",
		"scope": "channel:read:subscriptions",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.GET_FOLLOWERS: {
		"endpoint": "channels/followers",
		"scope": "moderator:read:followers",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.GET_MODERATORS: {
		"endpoint": "moderation/moderators",
		"scope": "moderation:read",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.CREATE_PREDICTION: {
		"endpoint": "predictions",
		"scope": "channel:manage:predictions",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.END_PREDICTION: {
		"endpoint": "predictions",
		"scope": "channel:manage:predictions",
		"method": HTTPClient.METHOD_PATCH
	},
	APIOperation.START_RAID: {
		"endpoint": "raids",
		"scope": "channel:manage:raids",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.CANCEL_RAID: {
		"endpoint": "raids",
		"scope": "channel:manage:raids",
		"method": HTTPClient.METHOD_DELETE
	},
	APIOperation.WARN_USER: {
		"endpoint": "moderation/warnings",
		"scope": "moderator:manage:warnings",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.GET_CUSTOM_REWARDS: {
		"endpoint": "channel_points/custom_rewards",
		"scope": "channel:read:redemptions",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.CREATE_CUSTOM_REWARD: {
		"endpoint": "channel_points/custom_rewards",
		"scope": "channel:manage:redemptions",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.UPDATE_CUSTOM_REWARD: {
		"endpoint": "channel_points/custom_rewards",
		"scope": "channel:manage:redemptions",
		"method": HTTPClient.METHOD_PATCH
	},
	APIOperation.UPDATE_REDEMPTION_STATUS: {
		"endpoint": "channel_points/custom_rewards/redemptions",
		"scope": "channel:manage:redemptions",
		"method": HTTPClient.METHOD_PATCH
	},
	APIOperation.SEND_CHAT_ANNOUNCEMENT: {
		"endpoint": "chat/announcements",
		"scope": "moderator:manage:announcements",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.START_COMMERCIAL: {
		"endpoint": "channels/commercial",
		"scope": "channel:edit:commercial",
		"method": HTTPClient.METHOD_POST
	},
	APIOperation.GET_AD_SCHEDULE: {
		"endpoint": "channels/ads",
		"scope": "channel:read:ads",
		"method": HTTPClient.METHOD_GET
	},
	APIOperation.SNOOZE_NEXT_AD: {
		"endpoint": "channels/ads/schedule/snooze",
		"scope": "channel:manage:ads",
		"method": HTTPClient.METHOD_POST
	},
}

# var account: String
var user_id: String
var api_operation: APIOperation
var query_parameters: Dictionary
var request_body: Dictionary

var result: ErrorCode
var response_code: int
var response_headers: PackedStringArray
var response_body: Dictionary

var twitch_api: TwitchAPI

func _ready() -> void:
	self.use_threads = true

func set_request_data(_twitch_api: TwitchAPI, _user_id: String, _api_operation: APIOperation, _body: Dictionary = {}, _query_parameters: Dictionary = {}) -> void:
	twitch_api = _twitch_api
	api_operation = _api_operation
	query_parameters = _query_parameters
	request_body = _body
	user_id = _user_id
	# TODO: check if user has scope?

func execute_request() -> void:
	if user_id != "":
		var user_credentials: Dictionary = twitch_api.credentials.get("tokens",{}).get(user_id, {})
		if user_credentials.is_empty():
			printerr("Can't execute %s request: no access token for user id %s" % [APIOperation.keys()[api_operation], user_id])
			return
		while user_credentials["state"] == TwitchNode.TokenState.CHECKING \
				|| user_credentials["state"] == TwitchNode.TokenState.REFRESHING:
			await twitch_api.twitch_node.token_validated
		if user_credentials["state"] != TwitchNode.TokenState.VALID:
			twitch_api_request_completed.emit(self, ErrorCode.INVALID_TOKEN)
			printerr("Can't execute %s request: invalid access token for user id %s: %s" % [APIOperation.keys()[api_operation], user_id, user_credentials["state"]])
			return

	var operation_info = api_operations[api_operation]

	var url = base_uri + operation_info["endpoint"]
	if twitch_api.test && api_operation == APIOperation.SUBSCRIBE_TO_EVENT:
		url = test_base_uri + operation_info["endpoint"]
	if !query_parameters.is_empty():
		if APIOperation.GET_USER_INFO:
			url += "?"
			for username in query_parameters["login"]:
				url += "login=" + username + "&"
			url.trim_suffic("&")
		else:
			url += "?" + HTTPClient.new().query_string_from_dict(query_parameters)
	var body_str := JSON.stringify(request_body)
	if operation_info["method"] == HTTPClient.METHOD_GET:
		body_str = ""
	request(url, _get_request_headers(), operation_info["method"], body_str)
	var response: Array = await request_completed
	response_code = response[1]
	response_headers = response[2]
	if response[0] != 0:
		result = ErrorCode.REQUEST_ERROR
		printerr("Request error: %s" % response[0])
	elif response[1] > 299 || response[1] < 200:
		result = ErrorCode.HTTP_ERROR
		printerr("Http error: %s" % response[1])
	else:
		result = ErrorCode.OK
		if !response[3].is_empty():
			response_body = JSON.parse_string(response[3].get_string_from_utf8())
	twitch_api_request_completed.emit(self, result)

func _get_request_headers() -> PackedStringArray:
	var headers := [
		"Client-Id: %s" % twitch_api.get_client_id(),
		"Content-Type: application/json"
	]
	if user_id != "":
		headers.append("Authorization: Bearer %s" % twitch_api.crypto.decrypt(twitch_api.key, twitch_api.credentials["tokens"][user_id]["access_token"]).get_string_from_utf8())
	return headers
