extends Node

const twitch_auth_scene: PackedScene = preload("res://addons/twitch_node/auth_window/twitch_auth_window.tscn")
const months_length: Array[int] = [0,31,28,31,30,31,30,31,31,30,31,30,31]
const weekdays: Array[String] = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

@export var twitch_node: TwitchNode
@export var scroll_container: ScrollContainer
@export var info_container: Container
@export var poll_label: Label
@export var hypetrain_label: Label
@export var settings_bar: SettingsBar
var twitch_auth_window: TwitchAuthWindow
var label_queue: Array[RichTextLabel]

func _ready() -> void:
	poll_label.visible = false
	hypetrain_label.visible = false
	twitch_node.new_chat_message.connect(on_new_chat_message)
	twitch_node.new_follower.connect(on_new_follower)
	twitch_node.new_sub.connect(on_new_sub)
	twitch_node.resub.connect(on_resub)
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
	twitch_node.ad_break_started.connect(on_ad_break_started)

func on_new_chat_message(_channel: String, _user: String, _message: String, _event_data: Dictionary) -> void:
	var color_hex: String = _event_data["color"]
	_add_label("(%s) [color=%s]%s[/color]: %s" % [_channel, color_hex, _user, _message])
	if _message.begins_with("!"):
		process_command(_channel, _user, _message)

func on_new_follower(_channel: String, _follower: String, _event_data: Dictionary) -> void:
	_add_label("New follower: %s" % _follower)
	twitch_node.send_chat_message(_channel, settings_bar.get_user_account(), "Thanks for the follow %s!" % _follower)

func on_new_sub(_channel: String, _subscriber: String, _tier: int, _event_data: Dictionary) -> void:
	_add_label("New tier %s sub: %s" % [_tier, _subscriber])

func on_resub(_channel: String, _subscriber: String, _tier: int, _streak: int, _duration: int, _cumulative: int, _message: String, _event_data: Dictionary) -> void:
	_add_label("Tier %s resub by %s: %s months, %s" % [_tier, _subscriber, _cumulative, _message])

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
	twitch_node.send_shoutout(_channel, _channel, _raiding_channel)

func on_bits_cheered(_channel: String, _user: String, _amount: int, _message: String, _event_data: Dictionary) -> void:
	_add_label("%s cheered %s bits: %s" % [_user, _amount, _message])

func on_hype_train_started(_channel: String, _event_data: Dictionary) -> void:
	_add_label("A hype train has started!")
	hypetrain_label.text = "A hype train has started!"
	hypetrain_label.visible = true

func on_hype_train_progress(_channel: String, _level: int, _event_data: Dictionary) -> void:
	var progress: int = _event_data["progress"]
	var goal: int = _event_data["goal"]
	var lvl_pct: int = roundi((progress as float / goal as float) * 100.)
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

func on_ad_break_started(_channel: String, _duration: int, _event_data: Dictionary) -> void:
	var account := settings_bar.get_user_account()
	twitch_node.send_chat_message(_channel, account, "Ads are starting BigSad")
	await get_tree().create_timer(_duration).timeout
	twitch_node.send_chat_message(_channel, account, "Ads are over! DinoDance")

func process_command(_channel: String, _user: String, _message: String) -> void:
	var account := settings_bar.get_user_account()
	if _message.begins_with("!ping"):
		twitch_node.send_chat_message(_channel, settings_bar.get_user_account(), "Pong!")
	if _message.begins_with("!followage"):
		var user := _user
		var split := _message.split(" ")
		if split.size() > 1:
			user = split[1].to_lower()
		twitch_node.send_chat_message(_channel, account, await _followage(_channel, _channel, user))
	if _message.begins_with("!privilege"):
		var user := _user
		var split := _message.split(" ")
		if split.size() > 1:
			user = split[1].to_lower()
		var msg := await _followage(_channel, _channel, user)
		msg += ". " + await _subbage(_channel, user)
		msg += ". " + await _moddage(_channel, _channel, user)
		msg += ". " + await _vippage(_channel, user) + "."
		twitch_node.send_chat_message(_channel, account, msg)
	if _message.begins_with("!ads"):
		_ads(_channel, account)

func _followage(channel: String, account: String, user: String) -> String:
		var follower_info := await twitch_node.get_follower_info(channel, account, user)
		if !follower_info.is_empty():
			var followed_time_dict := Time.get_datetime_dict_from_datetime_string(str(follower_info["followed_at"]), true)
			var weekday: int = followed_time_dict["weekday"]
			var msg := "%s has been following since %02d:%02d on %s %s/%s/%s. " % [user, followed_time_dict["hour"], followed_time_dict["minute"], weekdays[weekday], followed_time_dict["day"], followed_time_dict["month"], followed_time_dict["year"]]
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
			return msg
		else:
			return "%s is not following the channel" % user

func _subbage(channel: String, user: String) -> String:
	var sub_info := await twitch_node.get_sub_info(channel, user)
	if sub_info.is_empty():
		return "They are not subbed"
	else:
		var tier: int = round(sub_info["tier"] / 1000.)
		if !sub_info["is_gift"]:
			return "They are a tier %s sub" % tier
		else:
			return "They received a tier %s gift sub from %s" % [tier, sub_info["gifter_name"]]

func _moddage(channel: String, account: String, user: String) -> String:
	if await twitch_node.is_moderator(channel, account, user):
		return "They are a mod"
	else:
		return "They are not a mod"

func _vippage(channel: String, user: String) -> String:
	if await twitch_node.is_vip(channel, user):
		return "They are a vip"
	else:
		return "They are not a vip"

func _ads(_channel: String, _account: String) -> void:
	var ad_info := await twitch_node.get_ad_schedule(_channel)
	var ads_in_s: int = ad_info["next_ad_at"] - Time.get_unix_time_from_system()
	var minutes: int = floori(ads_in_s / 60.)
	var seconds: int = ads_in_s % 60
	twitch_node.send_chat_message(_channel, _account, "Ads will play in %s minutes and %s seconds" % [minutes, seconds])

func _add_label(_text: String) -> void:
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.text = _text
	info_container.add_child(label)
	_scroll_down()
	label_queue.push_back(label)
	while label_queue.size() > 100:
		var old_label: RichTextLabel = label_queue.pop_front()
		old_label.queue_free()

func _scroll_down() -> void:
	await get_tree().process_frame
	scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value as int

func _get_elapsed_datetime(from: Dictionary, to: Dictionary) -> Dictionary:
	var elapsed: Dictionary
	var to_unit: int = to["minute"]
	var from_unit: int = from["minute"]
	var diff := _calc_diff(to_unit, from_unit, 60)
	elapsed["minute"] = diff[0]
	to_unit = to["hour"]
	from_unit = from["hour"]
	diff = _calc_diff(to_unit, from_unit + diff[1], 24)
	elapsed["hour"] = diff[0]
	to_unit = to["day"]
	from_unit = from["day"]
	diff = _calc_diff(to_unit, from_unit + diff[1], months_length[to["month"] - 1])
	elapsed["day"] = diff[0]
	to_unit = to["month"]
	from_unit = from["month"]
	diff = _calc_diff(to_unit, from_unit + diff[1], 12)
	elapsed["month"] = diff[0]
	to_unit = to["year"]
	from_unit = from["year"]
	elapsed["year"] = to_unit - from_unit - diff[1]
	return elapsed

func _calc_diff(a: int, b: int, modulus: int) -> Array[int]:
	return [fposmod(a - b, modulus) as int, 1 if a < b else 0]
