class_name ChatUserManager
extends Node

var users: Dictionary = {}
var cannyanScene: PackedScene = preload("res://character/character.tscn")

signal user_joined(user: chatUser)
signal user_updated(user: chatUser)
signal user_chat(user: chatUser, message: String)
signal user_left(user: chatUser)

@onready var userDatabase = $"../UserDatabase"
@export var autoCleanup: bool = true
var cleanupPoll: Timer = null

func _ready() -> void:
	if autoCleanup:		 #자동 정리 기능 활성화 시 작동
		_setup_cleanup()

func handle_chat_message(CID: String, NAME: String, CHAT: String):
	var user = get_user(CID, NAME)
	user_chat.emit(user, CHAT)

func get_user(CID: String, NAME: String):
	if users.has(CID):
		# 현재 세션에 있는 사용자
		var user = users[CID]
		
		user.lastChatTime = Time.get_ticks_msec() / 1000.0
		if user.nickname != NAME:
			user.nickname = NAME
			userDatabase.update_nickname(CID, NAME)
			user_updated.emit(user)
	
		return user
	
	else:
		# 방송 켜고 처음 로딩된 사용자
		var user = chatUser.new(CID, NAME)
		users[CID] = user
		
		if userDatabase.user_exists(CID): # 또 오셨네요?
			var savedData = userDatabase.get_user_data(CID)
			user.hiddenUser = savedData["HIDDEN"]
			if savedData.has("COLOR_HUE"): user.hueShift = savedData["COLOR_HUE"]
			if savedData.has("COLOR_NAME"): user.colorName = savedData["COLOR_NAME"]
		else: # 뉴비네요?
			userDatabase.add_user(CID, NAME)
			user.hueShift = -1.0 
			user.colorName = "" 
			
		var cannyan = cannyanScene.instantiate()
		user.characterNode = cannyan
		user_joined.emit(user)
		
		if user.hiddenUser:
			user.characterNode.visible = false
			
		return user
		
func remove_user(CID: String):
	if users.has(CID):
		var user = users[CID]
		
		if user.characterNode:
			var chatContainer = user.characterNode.get_node_or_null("ChatContainer")
			if chatContainer:
				for child in chatContainer.get_children():
					child.queue_free()
			user.characterNode.queue_free()

		users.erase(CID)
		user_left.emit(user)

func toggle_visibility(CID: String, hidden: bool):
	if users.has(CID):
		var user = users[CID]
		user.HiddenUser = hidden
		userDatabase.update_hidden_status(CID, hidden)  # DB 저장
		
		if user.characterNode:
			user.characterNode.visible = not hidden
		
		user_updated.emit(user)

func is_user_online(CID: String) -> bool:
	if users.has(CID):
		var user = users[CID]
		return user.characterNode != null and user.characterNode.visible and not user.hiddenUser
	return false

#-----------------------------------------------------------------------------#
func update_pollingRate(pollingRate: float) -> void:
	if cleanupPoll:
		cleanupPoll.wait_time = pollingRate
	
func set_auto_cleanup(enabled: bool) -> void:
	autoCleanup = enabled
	if enabled:
		_setup_cleanup()
	else:
		_stop_cleanup()

func _setup_cleanup():
	if cleanupPoll:
		cleanupPoll.queue_free()
	
	cleanupPoll = Timer.new()
	cleanupPoll.wait_time = userConfig.afkPollingTime
	cleanupPoll.timeout.connect(_idle_cleanup)
	cleanupPoll.autostart = true
	add_child(cleanupPoll)

func _stop_cleanup() -> void:
	if cleanupPoll:
		cleanupPoll.stop()
		cleanupPoll.queue_free()
		cleanupPoll = null

func _idle_cleanup():
	var currentTime = Time.get_ticks_msec() / 1000.0
	var toRemoved = []
	
	for channelId in users.keys():
		var user = users[channelId]
		var idleTime = user.get_idle_time()
		
		if idleTime > userConfig.afkDetectTime:
			toRemoved.append(channelId)
		
	for channelId in toRemoved:
		remove_user(channelId)
