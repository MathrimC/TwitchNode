class_name ChannelInfo
extends HBoxContainer

signal leave_pressed(channel_name: String, auth_username: String)

@export var channel_label: Label
var channel_name: String
var auth_username: String

func _ready() -> void:
	channel_label.text = channel_name

func on_leave_pressed() -> void:
	leave_pressed.emit(channel_name, auth_username)

