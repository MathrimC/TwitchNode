extends Node

const twitch_auth_scene: PackedScene = preload("res://addons/twitch_node/auth_window/twitch_auth_window.tscn")
const months_length: Array[int] = [0,31,28,31,30,31,30,31,31,30,31,30,31]
const weekdays: Array[String] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

@export var channel_name: String
@export var bot_account_name: String

@export var twitch_node: TwitchNode
@export var scroll_container: ScrollContainer
@export var info_container: Container
@export var poll_label: Label
@export var hypetrain_label: Label
var twitch_auth_window: TwitchAuthWindow

func _ready() -> void:
	poll_label.visible = false
	hypetrain_label.visible = false
	if channel_name != "":
		twitch_node.new_chat_message.connect(on_new_chat_message)
		twitch_node.new_follower.connect(on_new_follower)
		twitch_node.new_sub.connect(on_new_sub)
		twitch_node.end_sub.connect(on_end_sub)
		twitch_node.gift_subs.connect(on_gift_subs)
		twitch_node.vip_added.connect(on_vip_added)
		twitch_node.vip_removed.connect(on_vip_removed)
		twitch_node.poll_started.connect(on_poll_started)
		twitch_node.poll_progress.connect(on_poll_progress)
		twitch_node.poll_ended.connect(on_poll_ended)
		twitch_node.incoming_raid.connect(on_incoming_raid)
		twitch_node.bits_cheered.connect(on_bits_cheered)
		twitch_node.hype_train_started.connect(on_hype_train_started)
		twitch_node.hype_train_progress.connect(on_hype_train_progress)
		twitch_node.hype_train_ended.connect(on_hype_train_ended)
		twitch_node.stream_started.connect(on_stream_started)
		twitch_node.stream_ended.connect(on_stream_ended)
		_connect_to_channel()
	else:
		printerr("No channel name provided")
	if bot_account_name == "":
		printerr("No bot account provided")

func _connect_to_channel() -> void:
	if await twitch_node.has_valid_credentials():
		if twitch_node.token_validated.is_connected(on_token_validated):
			twitch_node.token_validated.disconnect(on_token_validated)
		twitch_node.connect_to_channel(channel_name)
	elif twitch_auth_window == null:
		twitch_auth_window = twitch_auth_scene.instantiate()
		twitch_auth_window.set_twitch_node(twitch_node)
		add_child(twitch_auth_window)
		twitch_node.token_validated.connect(on_token_validated)

func on_token_validated(_account: String, _token_state: TwitchNode.TokenState) -> void:
	_connect_to_channel()

func on_auth_button_pressed() -> void:
	if twitch_auth_window == null:
		twitch_auth_window = twitch_auth_scene.instantiate()
		twitch_auth_window.set_twitch_node(twitch_node)
		add_child(twitch_auth_window)
	else:
		twitch_auth_window.grab_focus.call_deferred()

func on_new_chat_message(_channel: String, _user: String, _message: String, _event_data: Dictionary) -> void:
	var color_hex: String = _event_data["color"]
	_add_label("[color=%s]%s[/color]: %s" % [color_hex, _user, _message])
	if _message.begins_with("!"):
		process_command(_user, _message)

func on_new_follower(_channel: String, _follower: String, _event_data: Dictionary) -> void:
	_add_label("New follower: %s" % _follower)
	twitch_node.send_chat_message(channel_name, bot_account_name, "Thanks for the follow %s!" % _follower)

func on_new_sub(_channel: String, _subscriber: String, _tier: int, _event_data: Dictionary) -> void:
	_add_label("New tier %s sub: %s" % [_tier, _subscriber])

func on_end_sub(_channel: String, _subscriber: String, _tier: int, _event_data: Dictionary) -> void:
	_add_label("%s's tier %s sub has ended" % [_subscriber, _tier])

func on_gift_subs(_channel: String, _gifter: String, _tier: int, _amount: int, _event_data: Dictionary) -> void:
	_add_label("%s is gifting %s tier %s subs" % [_gifter, _amount, _tier])

func on_vip_added(_channel: String, _user: String, _event_data: Dictionary) -> void:
	_add_label("%s has been made a VIP" % _user)

func on_vip_removed(_channel: String, _user: String) -> void:
	_add_label("%s's VIP status has been removed" % _user)

func on_poll_started(_channel: String, _title: String, _choices: Array[String], _event_data: Dictionary) -> void:
	var msg := "Poll started: %s, choices: " % _title
	for choice in _choices:
		msg += choice + ", "
	msg = msg.trim_suffix(", ")
	_add_label(msg)
	poll_label.text = msg
	poll_label.visible = true

func on_poll_progress(_channel: String, _title: String, _choices: Array[String], _votes: Array[int], _event_data: Dictionary) -> void:
	var msg := "Poll progress: %s, " % _title
	while !_choices.is_empty():
		var most_votes: int = _votes.max()
		var index := _votes.find(most_votes)
		msg += "%s: %s votes, " % [_choices[index], _votes[index]]
		_votes.remove_at(index)
		_choices.remove_at(index)
	msg = msg.trim_suffix(", ")
	poll_label.text = msg
	
func on_poll_ended(_channel: String, _title: String, _choices: Array[String], _votes: Array[int], _event_data: Dictionary) -> void:
	var msg := "Poll ended: %s, results: " % _title
	while !_choices.is_empty():
		var most_votes: int = _votes.max()
		var index := _votes.find(most_votes)
		msg += "%s: %s votes, " % [_choices[index], _votes[index]]
		_votes.remove_at(index)
		_choices.remove_at(index)
	msg = msg.trim_suffix(", ")
	_add_label(msg)
	poll_label.text = msg

func on_incoming_raid(_channel: String, _raiding_channel: String, _party_size: int, _event_data: Dictionary) -> void:
	_add_label("%s is raiding with a party of %s" % [_raiding_channel, _party_size])
	twitch_node.send_shoutout(channel_name, _raiding_channel)

func on_bits_cheered(_channel: String, _user: String, _amount: int, _message: String, _event_data: Dictionary) -> void:
	_add_label("%s cheered %s bits: %s" % [_user, _amount, _message])

func on_hype_train_started(_channel: String, _event_data: Dictionary) -> void:
	_add_label("A hype train has started!")
	hypetrain_label.text = "A hype train has started!"
	hypetrain_label.visible = true

func on_hype_train_progress(_channel: String, _level: int, _event_data: Dictionary) -> void:
	var lvl_pct: int = roundi((_event_data["progress"] as float / _event_data["goal"] as float) * 100.)
	var msg := "Hype train in progress: lvl %s, %s %%" % [_level, lvl_pct]
	hypetrain_label.text = msg

func on_hype_train_ended(_channel: String, _level: int, _event_data: Dictionary) -> void:
	var msg := "The hype train ended at level %s" % _level
	_add_label(msg)
	hypetrain_label.text = msg

func on_stream_started(_channel: String, _event_data: Dictionary) -> void:
	_add_label("%s is now live" % _channel)

func on_stream_ended(_channel: String, _event_data: Dictionary) -> void:
	_add_label("%s is now offline" % _channel)

func process_command(_user: String, _message: String) -> void:
	if _message.begins_with("!ping"):
		twitch_node.send_chat_message(channel_name, bot_account_name, "Pong!")
	if _message.begins_with("!followage"):
		var user := _user
		var split := _message.split(" ")
		if split.size() > 1:
			user = split[1]
		var follower_info := await twitch_node.get_follower_info(channel_name, user)
		if !follower_info.is_empty():
			var followed_time_dict := Time.get_datetime_dict_from_datetime_string(str(follower_info["followed_at"]), true)
			var msg := "%s has been following since %02d:%02d on %s %s/%s/%s. " % [user, followed_time_dict["hour"], followed_time_dict["minute"], weekdays[followed_time_dict["weekday"] as int], followed_time_dict["day"], followed_time_dict["month"], followed_time_dict["year"]]
			var passed_time_dict := _get_elapsed_datetime(followed_time_dict, Time.get_datetime_dict_from_system())
			var years: int = passed_time_dict["year"]
			var months: int = passed_time_dict["month"]
			var days: int = passed_time_dict["day"]
			var hours: int = passed_time_dict["hour"]
			var minutes: int = passed_time_dict["minute"]
			msg += "That's "
			if years > 0:
				msg += "%s year" % years
				if years > 1:
					msg += "s"
			if months > 0:
				msg += " %s month" % months
				if months > 1:
					msg += "s"
			if days > 0:
				msg += " %s day" % days
				if days > 1:
					msg += "s"
			if hours > 0:
				msg += " %s hour" % hours
				if hours > 1:
					msg += "s"
			if minutes > 0:
				msg += " %s minute" % minutes
				if minutes > 1:
					msg += "s"
			twitch_node.send_chat_message(channel_name, bot_account_name, msg)
		else:
			twitch_node.send_chat_message(channel_name, bot_account_name, "%s is not following the channel" % user)

func _add_label(_text: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = _text
	info_container.add_child(label)
	_scroll_down()

func _scroll_down() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value as int

func _get_elapsed_datetime(from: Dictionary, to: Dictionary) -> Dictionary:
	var elapsed: Dictionary
	var diff := _calc_diff(to["minute"] as int, from["minute"] as int, 60)
	elapsed["minute"] = diff[0]
	diff = _calc_diff(to["hour"] as int, from["hour"] as int + diff[1], 24)
	elapsed["hour"] = diff[0]
	diff = _calc_diff(to["day"] as int, from["day"] as int + diff[1], months_length[to["month"] - 1])
	elapsed["day"] = diff[0]
	diff = _calc_diff(to["month"] as int, from["month"] as int + diff[1], 12)
	elapsed["month"] = diff[0]
	elapsed["year"] = to["year"] - from["year"] - diff[1]
	return elapsed

func _calc_diff(a: int, b: int, modulus: int) -> Array[int]:
	return [fposmod(a - b, modulus) as int, 1 if a < b else 0]
