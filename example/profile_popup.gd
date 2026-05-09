class_name ProfilePopup
extends PopupPanel

@export var profile_rect: TextureRect
@export var name_label: Label
@export var date_label: Label
@export var description_label: Label
var user_info: Dictionary
var profile_pic: Image

func _ready() -> void:
	profile_rect.texture = ImageTexture.create_from_image(profile_pic)
	name_label.text = user_info.display_name
	date_label.text = user_info.created_at
	description_label.text = user_info.description
