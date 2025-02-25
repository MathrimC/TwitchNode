class_name ScopesButton
extends MenuButton

var twitch_node: TwitchNode

func initialize(_twitch_node: TwitchNode) -> void:
	twitch_node = _twitch_node
	var scopes_menu := self.get_popup()
	scopes_menu.add_check_item("none", 0)
	scopes_menu.add_check_item("all", 1)
	scopes_menu.add_check_item("channel", 2)
	scopes_menu.add_check_item("moderator", 3)
	scopes_menu.add_check_item("user", 4)
	scopes_menu.add_separator()
	for scope in twitch_node.get_scopes():
		scopes_menu.add_check_item(scope)
	_on_scope_selected(1)
	scopes_menu.hide_on_checkable_item_selection = false
	scopes_menu.index_pressed.connect(_on_scope_selected)

func get_selected_scopes() -> Array[String]:
	var scopes_menu := self.get_popup()
	var selected_scopes: Array[String]
	for i in range(6,scopes_menu.item_count):
		if scopes_menu.is_item_checked(i):
			selected_scopes.append(scopes_menu.get_item_text(i))
	selected_scopes.sort()
	return selected_scopes

func _on_scope_selected(index: int) -> void:
	var scopes_menu := self.get_popup()
	scopes_menu.toggle_item_checked(index)
	match index:
		0:
			if scopes_menu.is_item_checked(index):
				for i in range(1, scopes_menu.item_count):
					scopes_menu.set_item_checked(i, false)
		1:
			if scopes_menu.is_item_checked(index):
				scopes_menu.set_item_checked(0, false)
				for i in range(2, scopes_menu.item_count):
					scopes_menu.set_item_checked(i, true)
		2:
			scopes_menu.set_item_checked(0, false)
			scopes_menu.set_item_checked(1, false)
			_update_checked(scopes_menu.is_item_checked(index), "channel")
			_update_checked(scopes_menu.is_item_checked(index), "bits")
		3:
			scopes_menu.set_item_checked(0, false)
			scopes_menu.set_item_checked(1, false)
			_update_checked(scopes_menu.is_item_checked(index), "moderat")
		4:
			scopes_menu.set_item_checked(0, false)
			scopes_menu.set_item_checked(1, false)
			_update_checked(scopes_menu.is_item_checked(index), "user")
		_:
			scopes_menu.set_item_checked(0, false)
			scopes_menu.set_item_checked(1, false)
			if !scopes_menu.is_item_checked(index):
				var text := scopes_menu.get_item_text(index)
				if text.begins_with("channel"):
					scopes_menu.set_item_checked(2, false)
				elif text.begins_with("moderat"):
					scopes_menu.set_item_checked(3, false)
				elif text.begins_with("user"):
					scopes_menu.set_item_checked(4, false)


func _update_checked(checked: bool, filter: String):
	var scopes_menu := self.get_popup()
	for i in range(5, scopes_menu.item_count):
		if filter == "" || scopes_menu.get_item_text(i).begins_with(filter):
			scopes_menu.set_item_checked(i, checked)
