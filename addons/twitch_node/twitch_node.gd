@icon("./icons/glitch_purple.svg")

## Provides functions for Twitch API operations and signals for Twitch websocket events
class_name TwitchNode
extends Node

enum ErrorCode { UNAUTHORIZED, INVALID_TOKEN, UNAVAILABLE, UNKNOWN_USER, BAD_INPUT }
enum TokenState { EMPTY, VALID, INVALID, CHECKING, UNKNOWN }

signal new_chat_message(channel: String, user: String, message: String, event_data: Dictionary)
signal channel_info_updated(channel: String, title: String, category: String, event_data: Dictionary)
signal new_follower(channel: String, follower: String, event_data: Dictionary)
signal new_sub(channel: String, subscriber: String, tier: int, event_data: Dictionary)
signal resub(channel: String, subscriber: String, tier: int, streak: int, duration_months: int, cumulative_months: int, message: String, event_data: Dictionary)
signal end_sub(channel: String, subscriber: String, tier: int, event_data: Dictionary)
signal gift_subs(channel: String, gifter: String, tier: int, amount: int, event_data: Dictionary)
signal vip_added(channel: String, user: String, event_data: Dictionary)
signal vip_removed(channel: String, user: String, event_data: Dictionary)
signal poll_started(channel: String, poll_title: String, poll_choices: Array[String], event_data: Dictionary)
signal poll_progress(channel: String, poll_title: String, poll_choices: Array[String], poll_votes: Array[String], event_data: String)
signal poll_ended(channel: String, poll_title: String, poll_choices: Array[String], poll_votes: Array[int], event_data: Dictionary)
signal prediction_started(channel: String, prediction_title: String, prediction_outcomes: Array[String], event_data: Dictionary)
signal prediction_progress(channel: String, prediction_title: String, event_data: String)
signal prediction_locked(channel: String, prediction_title, event_data: Dictionary)
signal prediction_resolved(channel: String, prediction_title: String, prediction_outcome: String, event_data: Dictionary)
signal prediction_canceled(channel: String, prediction_title: String, event_data: Dictionary)
signal reward_redeemed(channel: String, user: String, redemption: String, user_input: String, event_data: Dictionary)
signal incoming_raid(channel: String, raiding_channel: String, party_size: int, event_data: Dictionary)
signal outgoing_raid(channel: String, raid_target: String, event_data: Dictionary)
signal bits_cheered(channel: String, user: String, amount: int, message: String, event_data: Dictionary)
signal hype_train_started(channel: String, event_data: Dictionary)
signal hype_train_progress(channel: String, level: int, event_data: Dictionary)
signal hype_train_ended(channel: String, level: int, event_data: Dictionary)
signal stream_started(channel: String, event_data: Dictionary)
signal stream_ended(channel: String, event_data: Dictionary)

signal token_validated(account: String, token_state: TokenState)
signal error_occured(error_code, error_info: Dictionary)

## Max amount of calls that can be done in one minute
@export var rate_limit := 100

var _twitch_api: TwitchAPI
var _followers_page: String
var _subs_page: String
var _vips_page: String
var _moderators_page: String

func _ready() -> void:
	_twitch_api = TwitchAPI.new()
	_twitch_api.twitch_node = self
	add_child(_twitch_api)

## Connect to channel to trigger signals when events happen in the channel (incoming chat messages, subs, follows, ...) (see list of signals)
func connect_to_channel(channel: String) -> void:
	await _twitch_api.connect_to_channel(channel)

func send_chat_message(channel: String, username: String, message: String) -> void:
	_twitch_api.send_chat_message(channel, username, message)

func get_channel_info(channel: String) -> Dictionary:
	return await _twitch_api.get_channel_info(channel)

## Delay will not be modified if value -1 is passed. Tags will not be modified if empty array is passed
func modify_channel_info(channel: String, title: String, category: String = "", language: String = "", delay: int = -1, tags: Array[String] = []):
	return await _twitch_api.modify_channel_info(channel, title, category, language, delay, tags)

func send_shoutout(channel: String, shoutout_channel: String) -> void:
	_twitch_api.send_shoutout(channel, shoutout_channel)

func warn_user(channel: String, warned_username: String, reason: String) -> void:
	_twitch_api.warn_user(channel, warned_username, reason)

func ban_user(channel: String, banned_username: String, duration: int = -1, reason: String = "") -> void:
	_twitch_api.ban_user(channel, banned_username, duration, reason)

func is_vip(channel: String, username: String) -> bool:
	var response = await _twitch_api.get_vips(channel, "", username)
	return !response.is_empty() && !response["data"].is_empty()

## Gets the first 100 vips. If the channel has more than 100 vips, get_next_vips can be called to retrieve the next 100 vips
func get_vips(channel: String) -> Dictionary:
	var response = await _twitch_api.get_vips(channel)
	if !response["pagination"].is_empty():
		_vips_page = response["pagination"]["cursor"]
	else:
		_vips_page = ""
	return response

## Gets the next 100 vips. If all vips have been retrieved, it repeats from the first 100
func get_next_vips(channel: String) -> Dictionary:
	var response = await _twitch_api.get_vips(channel, _vips_page)
	if !response["pagination"].is_empty():
		_vips_page = response["pagination"]["cursor"]
	else:
		_vips_page = ""
	return response

func add_vip(channel: String, vip_username: String) -> void:
	_twitch_api.add_vip(channel, vip_username)

## Returns a dictionary with keys "tier", "plan_name", "is_gift", "gifter_name", "gifter_login", "gifter_id", "user_name", "user_login", "user_id", "broadcaster_name", "broadcaster_login", "broadcaster_id".
## If the user isn't a sub, an empty dictionary is returned
func get_sub_info(channel: String, username: String) -> Dictionary:
	var response = await _twitch_api.get_subs(channel, "", username)
	if !response.is_empty() && !response["data"].is_empty():
		return response["data"][0]
	else:
		return {}

func get_subs(channel: String) -> Dictionary:
	var response = await _twitch_api.get_subs(channel)
	if !response["pagination"].is_empty():
		_subs_page = response["pagination"]["cursor"]
	else:
		_subs_page = ""
	return response

func get_next_subs(channel: String) -> Dictionary:
	var response = await _twitch_api.get_subs(channel, _subs_page)
	if !response["pagination"].is_empty():
		_subs_page = response["pagination"]["cursor"]
	else:
		_subs_page = ""
	return response

## Returns a dictionary with keys "user_id", "user_name", "user_login" and "followed_at"
func get_follower_info(channel: String, username: String) -> Dictionary:
	var response = await _twitch_api.get_followers(channel, "", username)
	if !response.is_empty() && !response["data"].is_empty():
		return response["data"][0]
	else:
		return {}

## Return the most recent 100 followers of the channel. To retrieve the next 100, call get_next_followers
func get_followers(channel: String) -> Dictionary:
	var response = await _twitch_api.get_followers(channel)
	if !response["pagination"].is_empty():
		_followers_page = response["pagination"]["cursor"]
	else:
		_followers_page = ""
	return response

## Retrieves the next 100 followers. Returns an empty dictionary if there are no more followers
func get_next_followers(channel: String) -> Dictionary:
	if _followers_page == "":
		return {}
	var response = await _twitch_api.get_followers(channel, _followers_page)
	if !response["pagination"].is_empty():
		_followers_page = response["pagination"]["cursor"]
	else:
		_followers_page = ""
	return response

func is_moderator(channel: String, username: String) -> bool:
	var response = await _twitch_api.get_moderators(channel, "", username)
	return !response.is_empty() && !response["data"].is_empty()

## Return the first 100 moderators of the channel. To retrieve the next 100, call get_next_moderators
func get_moderators(channel: String) -> Dictionary:
	var response = await _twitch_api.get_moderators(channel)
	if !response["pagination"].is_empty():
		_moderators_page = response["pagination"]["cursor"]
	else:
		_moderators_page = ""
	return response

## Retrieves the next 100 moderators. Returns an empty dictionary if there are no more moderators
func get_next_moderators(channel: String) -> Dictionary:
	if _moderators_page == "":
		return {}
	var response = await _twitch_api.get_moderators(channel, _moderators_page)
	if !response["pagination"].is_empty():
		_moderators_page = response["pagination"]["cursor"]
	else:
		_moderators_page = ""
	return response

func create_poll(channel: String, poll_title: String, poll_choices: Array[String], poll_duration: int) -> void:
	_twitch_api.create_poll(channel, poll_title, poll_choices, poll_duration)

func create_prediction(channel: String, prediction_title: String, prediction_outcomes: Array[String], prediction_duration_s: int) -> void:
	_twitch_api.create_prediction(channel, prediction_title, prediction_outcomes, prediction_duration_s)

func lock_prediction(channel: String) -> void:
	_twitch_api.lock_prediction(channel)

func resolve_prediction(channel: String, outcome: String) -> void:
	_twitch_api.resolve_prediction(channel, outcome)

func cancel_prediction(channel: String) -> void:
	_twitch_api.cancel_prediction(channel)

func create_custom_reward(channel: String, title: String, cost: int, explanation: String = "", is_enabled: bool = true, is_user_input_required: bool = false, max_per_stream: int = 0, max_per_user: int = 0, global_cooldown_s: int = 0, skip_request_queue: bool = false, background_color: Color = Color.WHITE):
	_twitch_api.create_custom_reward(channel, title, cost, explanation, is_enabled, is_user_input_required, max_per_stream, max_per_user, global_cooldown_s, skip_request_queue, background_color)

## Only works for custom redemptions created by the same application
func cancel_channel_redemption(channel: String, reward_id: String, redemption_id: String):
	_twitch_api.update_redemption_status(channel, reward_id, redemption_id, "CANCELED")

## Only works for custom redemptions created by the same application
func fulfill_channel_redemption(channel: String, reward_id: String, redemption_id: String):
	_twitch_api.update_redemption_status(channel, reward_id, redemption_id, "FULFILLED")

## Color needs to be blue, green, orange or purple
func send_chat_announcement(channel: String, username: String, message: String, color: String):
	_twitch_api.send_chat_announcement(channel, username, message, color)

func start_raid(channel: String, raid_target: String) -> void:
	_twitch_api.start_raid(channel, raid_target)

func cancel_raid(channel: String) -> void:
	_twitch_api.cancel_raid(channel)

func get_channel_auth_url( _redirect_url: String) -> String:
	return _twitch_api.get_channel_auth_url(_redirect_url)

func get_useraccount_auth_url( _redirect_url: String) -> String:
	return _twitch_api.get_useraccount_auth_url(_redirect_url)

## Client_id: application client id (from Twitch Dev Console) [br]
## Channel token: access token generated when authorizing the application with your Twitch channel account [br]
## User token: access token generated when authorizing the application with a bot account that has moderator privileges on the channel [br]
## Store: whether or not the credentials should be stored in an encrypted file in the project user directory. If yes, they will be retreived automatically next time the program runs
func set_credentials(client_id: String, channel_token: String, user_token: String, store: bool) -> void:
	_twitch_api.set_credentials(client_id, channel_token, user_token, store)

## Account: "channel" or "user"
func get_token_state(account: String) -> TokenState:
	return _twitch_api.token_states[account]

func has_valid_credentials() -> bool:
	while get_token_state("channel") == TokenState.CHECKING || get_token_state("user") == TokenState.CHECKING:
		await token_validated
	return get_token_state("channel") == TokenState.VALID && get_token_state("user") == TokenState.VALID

func get_client_id() -> String:
	return _twitch_api.get_client_id()

func get_channel_authorization_url() -> String:
	return _twitch_api.get_channel_authorization_url()

func get_useraccount_authorization_url() -> String:
	return _twitch_api.get_useraccount_authorization_url()

func _process_twitch_event(event_type: TwitchAPI.EventType, event_data: Dictionary):
	match event_type:
		TwitchAPI.EventType.CHANNEL_CHAT_MESSAGE:
			new_chat_message.emit(event_data["broadcaster_user_name"],event_data["chatter_user_name"],event_data["message"]["text"], event_data)
		TwitchAPI.EventType.CHANNEL_UPDATE:
			channel_info_updated.emit(event_data["broadcaster_user_name"], event_data["title"], event_data["category_name"], event_data)
		TwitchAPI.EventType.CHANNEL_FOLLOW:
			new_follower.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data)
		TwitchAPI.EventType.CHANNEL_SUB:
			new_sub.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data)
		TwitchAPI.EventType.CHANNEL_SUB_MESSAGE:
			resub.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["tier"], event_data["streak_months"], event_data["duration_months"], event_data["cumulative_months"], event_data["message"]["text"], event_data)
		TwitchAPI.EventType.CHANNEL_SUB_GIFT:
			gift_subs.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["tier"], event_data["total"], event_data)
		TwitchAPI.EventType.CHANNEL_SUB_END:
			end_sub.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["tier"], event_data)
		TwitchAPI.EventType.CHANNEL_VIP_ADD:
			vip_added.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data)
		TwitchAPI.EventType.CHANNEL_VIP_REMOVE:
			vip_removed.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data)
		TwitchAPI.EventType.CHANNEL_POLL_BEGIN:
			var choices: Array[String]
			for choice: Dictionary in event_data["choices"]:
				choices.append(choice["title"])
			poll_started.emit(event_data["broadcaster_user_name"], event_data["title"], choices, event_data)
		TwitchAPI.EventType.CHANNEL_POLL_PROGRESS:
			var choices: Array[String]
			var votes: Array[int]
			for choice: Dictionary in event_data["choices"]:
				choices.append(choice["title"])
				votes.append(choice["votes"] as int)
			poll_progress.emit(event_data["broadcaster_user_name"], event_data["title"], choices, votes, event_data)
		TwitchAPI.EventType.CHANNEL_POLL_END:
			var choices: Array[String]
			var votes: Array[int]
			for choice: Dictionary in event_data["choices"]:
				choices.append(choice["title"])
				votes.append(choice["votes"] as int)
			poll_ended.emit(event_data["broadcaster_user_name"], event_data["title"], choices, votes, event_data)
		TwitchAPI.EventType.CHANNEL_POINTS_CUSTOM_REWARD_REDEMPTION_ADD:
			reward_redeemed.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["reward"]["title"], event_data["user_input"], event_data)
		TwitchAPI.EventType.CHANNEL_POINTS_AUTOMATIC_REWARD_REDEMPTION_ADD:
			reward_redeemed.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["reward"]["type"], event_data["message"]["text"], event_data)
		TwitchAPI.EventType.CHANNEL_INCOMING_RAID:
			incoming_raid.emit(event_data["to_broadcaster_user_name"], event_data["from_broadcaster_user_name"], event_data["viewers"], event_data)
		TwitchAPI.EventType.CHANNEL_OUTGOING_RAID:
			outgoing_raid.emit(event_data["from_broadcaster_user_name"], event_data["to_broadcaster_user_name"], event_data)
		TwitchAPI.EventType.CHANNEL_PREDICTION_BEGIN:
			# _prediction_info = event_data
			var outcomes: Array[String]
			for outcome in event_data["outcomes"]:
				outcomes.append(outcome["title"])
			prediction_started.emit(event_data["broadcaster_user_name"], event_data["title"], outcomes, event_data)
		TwitchAPI.EventType.CHANNEL_PREDICTION_PROGRESS:
			prediction_progress.emit(event_data["broadcaster_user_name"], event_data["title"], event_data)
		TwitchAPI.EventType.CHANNEL_PREDICTION_LOCK:
			# _prediction_info = event_data
			prediction_locked.emit(event_data["broadcaster_user_name"], event_data["title"], event_data)
		TwitchAPI.EventType.CHANNEL_PREDICTION_END:
			match event_data["status"]:
				"resolved":
					var winning_outcome := ""
					for outcome in event_data["outcomes"]:
						if event_data["winning_outcome_id"] == outcome["id"]:
							winning_outcome = outcome["title"]
							break
					prediction_resolved.emit(event_data["broadcaster_user_name"], event_data["title"], winning_outcome, event_data)
				"canceled":
					prediction_canceled.emit(event_data["broadcaster_user_name"], event_data["title"], event_data)
		TwitchAPI.EventType.CHANNEL_CHEER:
			bits_cheered.emit(event_data["broadcaster_user_name"], event_data["user_name"], event_data["bits"], event_data["message"], event_data)
		TwitchAPI.EventType.HYPE_TRAIN_BEGIN:
			hype_train_started.emit(event_data["broadcaster_user_name"], event_data)
		TwitchAPI.EventType.HYPE_TRAIN_PROGRESS:
			hype_train_progress.emit(event_data["broadcaster_user_name"], event_data["level"], event_data)
		TwitchAPI.EventType.HYPE_TRAIN_END:
			hype_train_ended.emit(event_data["broadcaster_user_name"], event_data["level"], event_data)
		TwitchAPI.EventType.STREAM_ONLINE:
			stream_started.emit(event_data["broadcaster_user_name"], event_data)
		TwitchAPI.EventType.STREAM_OFFLINE:
			stream_ended.emit(event_data["broadcaster_user_name"], event_data)
		_:
			printerr("Unkown twitch event recieved: %s" % event_type)
