class_name ProfilePopup
extends PopupPanel

@export var profile_rect: TextureRect
@export var name_label: Label
@export var date_label: Label
@export var stream_category_label: RichTextLabel
@export var stream_title_label: RichTextLabel
@export var stream_viewer_count_label: Label
@export var description_label: Label
@export var follower_date_label: Label
var user_info: Dictionary
var stream_info: Dictionary
var follower_info: Dictionary
var profile_pic: Image

func _ready() -> void:
	profile_rect.texture = ImageTexture.create_from_image(profile_pic)
	name_label.text = user_info.display_name
	var date_str: String = user_info.created_at
	var date: PackedStringArray = date_str.split('T')
	date_label.text = "Account created: %s %s UTC" % [date[0], date[1].trim_suffix("Z")]
	description_label.text = user_info.description
	if !stream_info.is_empty():
		stream_title_label.text = stream_info.get("title", "")
		stream_category_label.text = stream_info.get("game_name", "")
		stream_viewer_count_label.text = "%d viewers" % stream_info.get("viewer_count", 0)
		stream_title_label.show()
		stream_category_label.show()
		stream_viewer_count_label.show()
	else:
		stream_title_label.hide()
		stream_category_label.hide()
		stream_viewer_count_label.hide()
	if !follower_info.is_empty():
		var follower_date_str: String = follower_info.get("followed_at", "")
		var follower_date: PackedStringArray = follower_date_str.split('T')
		follower_date_label.text = "Following since: %s %s UTC" % [follower_date[0], follower_date[1].trim_suffix("Z")]
		follower_date_label.show()
	else:
		follower_date_label.hide()
