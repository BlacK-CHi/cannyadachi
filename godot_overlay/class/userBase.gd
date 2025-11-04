class_name chatUser

var channelId: String
var nickname: String
var lastChatTime: float
var joinTime: float
var characterNode: CharacterBody2D
var speechBubble: Control
var hueShift: float
var colorName: String
var avatarName: String
var hiddenUser: bool = false

func _init(CID: String, NICK: String):
	channelId = CID; nickname = NICK
	
	var currentTime = Time.get_ticks_msec() / 1000.0
	lastChatTime = currentTime
	joinTime = currentTime
	
func update_chat_time():
	lastChatTime = Time.get_ticks_msec() / 1000.0

func get_idle_time() -> float:
	var currentTime = Time.get_ticks_msec() / 1000.0
	return currentTime - lastChatTime
