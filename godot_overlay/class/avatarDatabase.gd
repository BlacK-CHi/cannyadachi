extends Node
class_name AvatarDatabase

var db_path = "user://avatarData.json"
var avatarData: Dictionary = {}
var defaultAvatar = ""
@onready var errorPopup = $"../UI/ErrorContainer"

func _ready() -> void:
	load_database()
	
func load_database() -> void:
	if ResourceLoader.exists(db_path):
		var file = FileAccess.open(db_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.parse_string(json_string)  # 바로 파싱
			if json is Dictionary:
				avatarData = json
				print("[AvatarDB] 아바타 목록 로드 완료: %d개의 아바타" % avatarData.size())
				_update_default_avatar()
			else:
				print("[AvatarDB] JSON 파싱 중 오류가 발생했습니다.")
				avatarData = {}
	else:
		print("[AvatarDB] 아바타 데이터베이스 파일이 없습니다. 새로운 파일을 생성합니다.")
		avatarData = {}

func _update_default_avatar() -> void:
	defaultAvatar = ""
	
	for avatarName in avatarData.keys():
		if avatarData[avatarName].get("IS_DEFAULT", false):
			defaultAvatar = avatarName
			print("[AvatarDB] 기본값 아바타 설정됨: %s" % avatarName)
			break

func get_default_avatar() -> String:
	return defaultAvatar

func set_default_avatar(avatarName: String, isDefault: bool) -> void:
	for aname in avatarData.keys():
		avatarData[aname]["IS_DEFAULT"] = false
	
	if isDefault and avatarData.has(avatarName):
		avatarData[avatarName]["IS_DEFAULT"] = true
		defaultAvatar = avatarName
		print("[AvatarDB] 기본값 아바타 변경됨: %s" % avatarName)
	else:
		defaultAvatar = ""
		print("[AvatarDB] 기본값 아바타 해제됨")
	
	save_database()
	_update_default_avatar()

func add_avatar(aname: String, author: String, description: String, path: String):
	if not avatarData.has(aname):
		avatarData[aname] = {
			"NAME": aname,
			"AUTHOR": author,
			"DESC": description,
			"PATH": path,
			"IS_DEFAULT": false
		}
		save_database()
		print("[AvatarDB] 새로운 아바타 추가됨: %s " % aname)
		
func save_database() -> void:  # 함수명 통일
	var json_string = JSON.stringify(avatarData)
	var file = FileAccess.open(db_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()  # 파일 닫기 추가
		print("[AvatarDB] 데이터베이스 저장 완료 (%d개 항목)" % avatarData.size())
	else:
		push_error("[AvatarDB] 데이터베이스 저장 실패")

func avatar_removable(aname: String) -> bool:
	if not avatarData.has(aname):
		globalNode.errorPopup.pop_error("경고", "해당 아바타가 없거나 삭제할 수 없습니다.")
		return false
	
	if avatarData[aname].get("IS_DEFAULT", false):
		globalNode.errorPopup.pop_error("경고", "기본 설정된 아바타는 제거할 수 없습니다.")
		return false
	
	if avatarData.size() <= 1:
		globalNode.errorPopup.pop_error("경고", "최소 하나의 아바타가 등록되어 있어야 합니다.")
		return false
	
	return true


func remove_avatar(aname: String):
	if not avatarData.has(aname):
		push_error("[AvatarDB] 존재하지 않는 아바타: %s" % aname)
		return
	
	# 기본값 아바타는 삭제 불가
	if avatarData[aname].get("IS_DEFAULT", false):
		errorPopup.pop_error("오류", "기본 설정된 아바타는 삭제할 수 없습니다.")
		return
		
	print("[AvatarDB] 아바타 삭제됨: %s" % aname)
	avatarData.erase(aname)
	save_database()

func get_avatar_data(aname: String) -> Dictionary:
	if avatarData.has(aname):
		return avatarData[aname]
	return {}

func avatar_exists(aname: String) -> bool:
	return avatarData.has(aname)

func get_all_avatars() -> Dictionary:
	return avatarData
