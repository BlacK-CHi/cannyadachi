# 사용자 설정 싱글톤 (전역설정) ────────────────────────────────────────────────────
# 사용자 설정을 조작할 때 (tabCharacter.gd, tabUserList.gd) 해당 값의 변경을 확인하고,
# 변경된 값을 setting.cfg 파일에 저장하는 코드입니다.
# 따로 객체로 사용되는 건 아니고, 프로젝트의 전역 변수로 사용됩니다 (Singletone)
# ──────────────────────────────────────────────────────────────────────────── #

extends Node

# %APPDATA%\Godot\app_userdata\<프로그램 이름>\userConfig.cfg
const SAVE_PATH = "user://settings.cfg"

# 설정값 ────────────────────────────────────────────────────────────────────── #
var afkPollingTime: float = 300.0:					# 잠수유저 확인 주기
	set(value):
		if afkPollingTime != value:					# 만약 현재 값과 새로 주어진 값이 다른 경우
			afkPollingTime = value					# 새로 주어진 값을 저장하고
			save_settings()							# 그걸 설정 파일에 기록하는 패턴입니다.

var afkDetectTime: float = 600.0:					# 잠수유저 감지 시간
	set(value):
		if afkDetectTime != value:
			afkDetectTime = value
			save_settings()

var bubbleDuration: float = 3.0:					# 말풍선 지속 시간
	set(value):
		if bubbleDuration != value:
			bubbleDuration = value
			save_settings()

var maxChatStack: float = 3.0:						# 말풍선 최대 개수
	set(value):
		if maxChatStack != value:
			maxChatStack = value
			save_settings()

var jumpSpeed: float = 400.0:						# 점프력
	set(value):
		if jumpSpeed != value:
			jumpSpeed = value
			save_settings()

var moveSpeed: float = 100.0:						# 이동 속도
	set(value):
		if moveSpeed != value:
			moveSpeed = value
			save_settings()

var gravity: float = 980.0:							# 중력
	set(value):
		if gravity != value:
			gravity = value
			save_settings()

var stateMin: float = 2.0:							# 상태전환 최소값
	set(value):
		if stateMin != value:
			stateMin = value
			save_settings()

var stateMax: float = 5.0:							# 상태전환 최대값
	set(value):
		if stateMax != value:
			stateMax = value
			save_settings()

var spawnWidth: float = 1280.0:						# 캐릭터 스폰지역 폭
	set(value):
		if spawnWidth != value:
			spawnWidth = value
			save_settings()

var spawnHeight: float = 200.0:						# 캐릭터 스폰지역 높이
	set(value):
		if spawnHeight != value:
			spawnHeight = value
			save_settings()

var spawnOffsetX: float = 0.0:						# 캐릭터 스폰지역 X축 오프셋
	set(value):
		if spawnOffsetX != value:
			spawnOffsetX = value
			save_settings()

var spawnOffsetY: float = 0.0:						# 캐릭터 스폰지역 Y축 오프셋
	set(value):
		if spawnOffsetY != value:
			spawnOffsetY = value
			save_settings()

var autoRefreshTime: float = 30.0:					# 사용자 정보 자동 새로고침 간격
	set(value):
		if autoRefreshTime != value:
			autoRefreshTime = value
			save_settings()
			
var avatarZoom: float = 1.0:
	set(value):
		if avatarZoom != value:
			avatarZoom = value
			save_settings()
			
# ──────────────────────────────────────────────────────────────────────────── #	
func _ready():
	load_settings()

func save_settings():				# 설정 저장하기
	var config = ConfigFile.new()
	
	# 설정 저장 - 캐릭터 관련 설정은 cannyan 키 아래에 저장하고,
	# 스폰 위치 관련은 spawn 아래에, 재설정 시간은 manager 하위에 저장합니다.
	config.set_value("cannyan", "afkPollingTime", afkPollingTime)
	config.set_value("cannyan", "afkDetectTime", afkDetectTime)
	config.set_value("cannyan", "bubbleDuration", bubbleDuration)
	config.set_value("cannyan", "maxChatStack", maxChatStack)
	config.set_value("cannyan", "jumpSpeed", jumpSpeed)
	config.set_value("cannyan", "moveSpeed", moveSpeed)
	config.set_value("cannyan", "gravity", gravity)
	config.set_value("cannyan", "stateMin", stateMin)
	config.set_value("cannyan", "stateMax", stateMax)
	config.set_value("spawn", "spawnWidth", spawnWidth)
	config.set_value("spawn", "spawnHeight", spawnHeight)
	config.set_value("spawn", "spawnOffsetX", spawnOffsetX)
	config.set_value("spawn", "spawnOffsetY", spawnOffsetY)
	config.set_value("manager", "autoRefreshTime", autoRefreshTime)
	config.set_value("avatar", "avatarZoom", avatarZoom)
	
	var err = config.save(SAVE_PATH)
	if err != OK:
		print("[CONFIG] 설정 파일 저장에 실패했습니다: " + str(err))

func load_settings():				# 설정 불러오기
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	
	if err != OK: 	# 설정 파일이 손상되거나 없는 경우 기본값을 사용합니다.
		print("[CONFIG] 설정 파일이 없거나 손상되었습니다. 기본 설정을 사용합니다.")
		return
	
	afkPollingTime = config.get_value("cannyan", "afkPollingTime", 300.0)
	afkDetectTime = config.get_value("cannyan", "afkDetectTime", 600.0)
	bubbleDuration = config.get_value("cannyan", "bubbleDuration", 3.0)
	maxChatStack = config.get_value("cannyan", "maxChatStack", 4.0)
	jumpSpeed = config.get_value("cannyan", "jumpSpeed", 300.0)
	moveSpeed = config.get_value("cannyan", "moveSpeed", 100.0)
	gravity = config.get_value("cannyan", "gravity", 980.0)
	stateMin = config.get_value("cannyan", "stateMin", 2.0)
	stateMax = config.get_value("cannyan", "stateMax", 5.0)
	spawnWidth = config.get_value("spawn", "spawnWidth", 1280.0)
	spawnHeight = config.get_value("spawn", "spawnHeight", 200.0)
	spawnOffsetX = config.get_value("spawn", "spawnOffsetX", 0.0)
	spawnOffsetY = config.get_value("spawn", "spawnOffsetY", 0.0)
	autoRefreshTime = config.get_value("manager", "autoRefreshTime", 30.0)
	avatarZoom = config.get_value("avatar", "avatarZoom", 1.0)
