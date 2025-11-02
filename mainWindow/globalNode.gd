extends Node

@onready var errorPopup = get_node("/root/mainWindow/UI/ErrorContainer")
@onready var userDatabase = get_node("/root/mainWindow/UserDatabase")
@onready var avatarDatabase = get_node("/root/mainWindow/AvatarDatabase")
@onready var userManager = get_node("/root/mainWindow/ChatUserManager")
@onready var proxyClient = get_node("/root/mainWindow/ProxyClient")
@onready var chzzkHandler = get_node("/root/mainWindow/ChzzkHandler")
