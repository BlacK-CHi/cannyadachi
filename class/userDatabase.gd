extends Node
class_name UserDatabase

var db_path = "user://userData.json"
var userData: Dictionary = {}

func _ready():
	load_database()

func load_database() -> void:
	if ResourceLoader.exists(db_path):
		var file = FileAccess.open(db_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			var json = JSON.parse_string(json_string)  # 바로 파싱
			if json is Dictionary:
				userData = json
				print("[DB] 데이터베이스 로드 완료: %d명의 사용자" % userData.size())
			else:
				print("[DB] JSON 파싱 중 오류가 발생했습니다.")
				userData = {}
	else:
		print("[DB] 데이터베이스 파일이 없습니다. 새로운 파일을 생성합니다.")
		userData = {}

func save_database() -> void:
	var json_string = JSON.stringify(userData)
	var file = FileAccess.open(db_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("[DB] 데이터베이스에 성공적으로 저장되었습니다.")
	else:
		print("[DB] 데이터베이스에 저장하지 못했습니다.")

func get_user_data(CID: String) -> Dictionary:
	if userData.has(CID):
		return userData[CID]
	return {}

func user_exists(CID: String) -> bool:
	return userData.has(CID)

func add_user(CID: String, nickname: String) -> void:
	if not userData.has(CID):
		userData[CID] = {
			"CID": CID,
			"NAME": nickname,
			"COLOR_HUE": -1.0,
			"COLOR_NAME": "",
			"HIDDEN": false,
			"FIRST_SEEN": Time.get_ticks_msec() / 1000.0,
			"LAST_SEEN": Time.get_ticks_msec() / 1000.0
		}
		save_database()
		print("[DB] 새로운 사용자 추가됨: %s (%s)" % [nickname, CID])
	else:
		# 이미 존재하면 닉네임만 업데이트
		update_nickname(CID, nickname)

func update_nickname(CID: String, nickname: String) -> void:
	if userData.has(CID):
		userData[CID]["NAME"] = nickname
		userData[CID]["LAST_SEEN"] = Time.get_ticks_msec() / 1000.0
		save_database()

func update_hidden_status(CID: String, is_hidden: bool) -> void:
	if userData.has(CID):
		userData[CID]["HIDDEN"] = is_hidden
		userData[CID]["LAST_SEEN"] = Time.get_ticks_msec() / 1000.0
		save_database()

func update_user_color(CID: String, hue: float, color_name: String) -> void:
	if userData.has(CID):
		userData[CID]["COLOR_HUE"] = hue
		userData[CID]["COLOR_NAME"] = color_name
		userData[CID]["LAST_SEEN"] = Time.get_ticks_msec() / 1000.0
		save_database()


func get_all_users() -> Dictionary:
	return userData

func remove_user(CID: String) -> void:
	if userData.has(CID):
		userData.erase(CID)
		save_database()
		print("[DB] 사용자 삭제됨: %s" % CID)
