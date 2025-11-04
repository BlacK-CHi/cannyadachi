extends Node

const CONFIG_PATH = "user://authData.cfg"

func save_login_data(clientId: String, clientSecret: String, autoLogin: bool) -> void:
	var config = ConfigFile.new()
	config.set_value("auth", "clientID", clientId)
	config.set_value("auth", "clientSecret", clientSecret)
	config.set_value("auth", "autoLogin", autoLogin)
	config.save(CONFIG_PATH)

func load_login_data() -> Dictionary:
	var config = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return {}
	
	return {
		"clientID": config.get_value("auth", "clientID", ""),
		"clientSecret": config.get_value("auth", "clientSecret", ""),
		"autoLogin": config.get_value("auth", "autoLogin", false)
	}

func clear_login_data() -> void:
	var file = FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	DirAccess.remove_absolute(CONFIG_PATH)
