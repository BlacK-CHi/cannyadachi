extends Control

@onready var userList = $UserList
@onready var onlineOnly = $OnlineOnly
@onready var userManager = $"../../../../ChatUserManager"
@onready var userDatabase = $"../../../../UserDatabase"
@onready var avatarDatabase = $"../../../../AvatarDatabase" 
@onready var colorSelector = $ColorSelect
@onready var avatarSelector = $AvatarSelect
var all_users: Dictionary = {}  # DB의 모든 사용자
var autoRefreshStatus: bool = false
var refreshTimer: Timer
var userCID

const COLOR_PALETTE = {
	"오리지널": 0.0,
	"블루베리": 0.05,
	"포도": 0.2,
	"복숭아": 0.3,
	"딸기": 0.45,
	"오렌지": 0.55,
	"레몬": 0.6,
	"라임": 0.7,
	"녹차": 0.8,
	"민트": 0.92
}

func _ready() -> void:
	colorSelector.disabled = true
	avatarSelector.disabled = true
	$Despawn.disabled = true
	$Delete.disabled = true
	$HideUser.disabled = true
	
	if userManager.userDatabase == null:
		print("[UserList] 사용자 데이터베이스를 불러오는 중입니다...")
		await get_tree().process_frame
		
	load_all_users()
	refresh_user_list()
	setup_color_selector()
	setup_avatar_selector()
	load_settings_to_ui()

func load_all_users() -> void:
	all_users = userDatabase.get_all_users()
	print("[UserList] 데이터베이스에서 %d명의 사용자를 불러왔습니다." % all_users.size())

func refresh_user_list() -> void:
	userList.clear()
	
	var online_filter = onlineOnly.button_pressed
	
	for CID in all_users.keys():
		var user = all_users[CID]
		var nickname = user["NAME"]
		var is_hidden = user["HIDDEN"]
		
		# 온라인 필터 적용
		if online_filter:
			if not userManager.is_user_online(CID):
				continue
		
		var item_index = userList.add_item(nickname)
		
		# 온라인 상태 표시
		if userManager.is_user_online(CID):
			userList.set_item_custom_fg_color(item_index, Color.GREEN)
		else:
			userList.set_item_custom_fg_color(item_index, Color.GRAY)
		
		# 숨김 상태 표시
		if is_hidden:
			userList.set_item_text(item_index, nickname + "*")
		
		# CID를 메타데이터로 저장
		userList.set_item_metadata(item_index, CID)

func setup_color_selector() -> void:
	colorSelector.clear()
	
	for color_name in COLOR_PALETTE.keys():
		colorSelector.add_item(color_name)

func setup_avatar_selector() -> void:
	avatarSelector.clear()
	
	var all_avatars = avatarDatabase.get_all_avatars()
	for avatar_name in all_avatars.keys():
		avatarSelector.add_item(avatar_name)
		avatarSelector.set_item_metadata(avatarSelector.item_count - 1, avatar_name)

func user_auto_refresh() -> void:
	refreshTimer = Timer.new()
	refreshTimer.wait_time = userConfig.autoRefreshTime
	refreshTimer.timeout.connect(_refresh_timer_timeout)
	add_child(refreshTimer)
	refreshTimer.start()

func update_refresh_rate(refreshRate: float) -> void:
	if refreshTimer:
		refreshTimer.wait_time = refreshRate

func update_color_selection(character: Dictionary) -> void:
	var current_color = character.get("COLOR_NAME", "")
	if current_color and current_color != "":
		for i in range(colorSelector.item_count):
			if colorSelector.get_item_text(i) == current_color:
				colorSelector.select(i)
				break
				
func update_avatar_selection(character: Dictionary) -> void:
	var current_avatar = character.get("AVATAR", "")
	for i in range(avatarSelector.item_count):
		var metadata = avatarSelector.get_item_metadata(i)
		if metadata == current_avatar:
			avatarSelector.select(i)
			return

# ---------------------------------------------------------------------------- #

func _on_online_filter_toggled(toggled_on: bool) -> void:
	refresh_user_list()

func show_user_details(CID: String) -> void:
	var user = all_users[CID]

	$Nickname.text = user["NAME"]
	$ChannelID.text = user["CID"]
	$IsOnline.button_pressed = userManager.is_user_online(user["CID"])
	$HideUser.button_pressed = user["HIDDEN"]
	update_color_selection(user)
	update_avatar_selection(user)

# ---------------------------------------------------------------------------- #

func _on_user_joined(user: chatUser) -> void:
	refresh_user_list()

func _on_user_left(user: chatUser) -> void:
	refresh_user_list()

func _on_user_updated(user: chatUser) -> void:
	refresh_user_list()

func _on_user_selected(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	var CID = userList.get_item_metadata(index)
	var user = all_users[CID]
	userCID = user["CID"]
	
	colorSelector.disabled = false
	avatarSelector.disabled = false
	$Despawn.disabled = false
	$Delete.disabled = false
	$HideUser.disabled = false
	
	print("선택된 사용자: %s (%s)" % [user["NAME"], CID])
	# 여기서 색상 변경, 숨김 토글 등의 UI 표시
	show_user_details(CID)

func _on_refresh_button_pressed() -> void:
	load_all_users()
	refresh_user_list()

func _on_auto_refresh_toggled(toggled_on: bool) -> void:
	autoRefreshStatus = toggled_on
	
	if toggled_on:
		if refreshTimer == null:
			user_auto_refresh()
		else: 
			refreshTimer.start()
	else:
		if refreshTimer:
			refreshTimer.stop()
		print("자동 새로고침 비활성화")
		
func _refresh_timer_timeout() -> void:
	load_all_users()
	refresh_user_list()

func _on_despawn_pressed() -> void:
	if userCID.is_empty():
		return
	userManager.remove_user(userCID)

func _on_delete_pressed() -> void:
	if userCID.is_empty():
		return
	userManager.remove_user(userCID)
	userDatabase.remove_user(userCID)
	await get_tree().process_frame
	
	load_all_users()
	refresh_user_list()
	
#------#

func _process(_delta: float) -> void:
	$RefRate.text = str($RefreshTime.value) + "초마다"
	
func load_settings_to_ui() -> void:
	$RefreshTime.value = userConfig.autoRefreshTime
	
func _on_refresh_time_value_changed(value: float) -> void:
	userConfig.autoRefreshTime = value
	update_refresh_rate(value)


func _on_hide_user_toggled(toggled_on: bool) -> void:
	if userCID.is_empty():
		return
	
	if toggled_on == true:
		userManager.remove_user(userCID)
	userDatabase.update_hidden_status(userCID, toggled_on)


func _on_color_selected(index: int) -> void:
	if userCID.is_empty(): return 

	var selectedColor = colorSelector.get_item_text(index)
	var hueValue = COLOR_PALETTE[selectedColor]
	
	if userManager.users.has(userCID):
		var user = userManager.users[userCID]
		user.characterNode.set_color_by_name(selectedColor)
	userDatabase.update_user_color(userCID, hueValue, selectedColor)

func _on_avatar_selected(index: int) -> void:
	if userCID.is_empty(): 
		return 
	
	var selected_avatar = avatarSelector.get_item_metadata(index)
	
	if userManager.users.has(userCID):
		userManager.apply_avatar(userCID, selected_avatar)
	else:
		userDatabase.update_user_avatar(userCID, selected_avatar)

func _on_avatar_refresh() -> void:
	setup_avatar_selector()
