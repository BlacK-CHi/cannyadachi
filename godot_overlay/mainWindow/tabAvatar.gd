extends Control

var all_avatars = {}
@onready var avatarDatabase = $"../../../../AvatarDatabase"
@onready var avatarList = $AvatarList
@onready var errorPopup = $"../../../ErrorContainer"
var selectedAvatarName = ""

signal avatar_refresh()


func _ready() -> void:
	$SetAsDefault.disabled = true
	$DeleteAvatar.disabled = true
	
	if avatarDatabase == null:
		print("[AvatarList] 아바타 데이터베이스를 불러오는 중입니다...")
		await get_tree().process_frame
	
	await get_tree().process_frame
	load_all_avatars()
	refresh_avatar_list()
	ui_load_settings()

func _process(delta: float) -> void:
	$ZoomLevel.text = "x" + str($ZoomSlider.value)

func ui_load_settings() -> void:
	$ZoomSlider.value = userConfig.avatarZoom
	
func load_all_avatars() -> void:
	all_avatars = avatarDatabase.get_all_avatars()
	print("[AvatarList] 데이터베이스에서 %d개의 아바타를 불러왔습니다." % all_avatars.size())

func refresh_avatar_list():
	avatarList.clear()

	for avatarName in all_avatars.keys():
		var avatar = all_avatars[avatarName]
		var isDefault = avatar.get("IS_DEFAULT", false)
		var prefix = "*" if isDefault else ""
		
		var itemText = "%s - by %s%s" % [avatar.NAME, avatar.AUTHOR, prefix]
		avatarList.add_item(itemText)
		avatarList.set_item_metadata(avatarList.item_count - 1, avatarName)
	
	avatar_refresh.emit()

func _on_avatar_selected(index: int):
	var avatarName = avatarList.get_item_metadata(index)
	var avatar = avatarDatabase.get_avatar_data(avatarName)
	selectedAvatarName = avatarName
	
	if avatar.is_empty():
		return
		
	$AvatarName.text = avatar.NAME
	$AvatarAuthor.text = avatar.AUTHOR
	$AvatarDesc.text = avatar.DESC
	$SetAsDefault.button_pressed = avatar.get("IS_DEFAULT", false)
	$SetAsDefault.disabled = false
	$DeleteAvatar.disabled = false
	
func _on_default_avatar_toggled(toggled_on: bool) -> void:
	if selectedAvatarName.is_empty():
		return
	
	var current_avatar = avatarDatabase.get_avatar_data(selectedAvatarName)
	if current_avatar.get("IS_DEFAULT", false) == toggled_on:
		return
	
	avatarDatabase.set_default_avatar(selectedAvatarName, toggled_on)
	refresh_avatar_list()

func _on_new_avatar_pressed() -> void:
	$NewAvatarWindow.popup_centered()
	
func _on_load_avatar_pressed() -> void:
	$LoadAvatarDialog.popup_centered()

func _on_avatar_file_selected(path: String) -> void:
	var loadedAvatar = load(path)
	
	var metaName = loadedAvatar.get_meta("avatar_name", "Unknown Avatar")
	var metaAuthor = loadedAvatar.get_meta("author", "Anonymous")
	var metaDesc = loadedAvatar.get_meta("description", "")
	
	avatarDatabase.add_avatar(metaName, metaAuthor, metaDesc, path)
	refresh_avatar_list()
	
func _on_remove_avatar_pressed() -> void:
	if $AvatarName.text.is_empty():
		return
	
	if not avatarDatabase.avatar_removable($AvatarName.text):
		return
	
	avatarDatabase.remove_avatar($AvatarName.text)
	await get_tree().process_frame
	
	$AvatarName.text = ""
	$AvatarAuthor.text = ""
	$AvatarDesc.text = ""
	refresh_avatar_list()

func _on_zoom_value_changed(value: float) -> void:
	userConfig.avatarZoom = value
	
	var characterContainer = $"../../../../CharacterContainer"
	for character in characterContainer.get_children():
		if is_instance_valid(character) and character is CharacterBody2D:
			character.change_scale(value)
