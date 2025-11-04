extends Control


func _ready() -> void:
	var auth = authInfo.load_login_data()
	
	if auth:
		$ClientID.text = auth.get("clientID", "")
		$ClientSecret.text = auth.get("clientSecret", "")
		$AutoLogin.button_pressed = auth.get("autoLogin", false)
		
		if auth.get("autoLogin", false):
			await get_tree().process_frame
			$"../../../.."._on_chzzkLogin_pressed()

		
func _on_auto_login_toggled(toggled_on: bool) -> void:
	var clientId = $ClientID.text
	var clientSecret = $ClientSecret.text
	
	if toggled_on:
		authInfo.save_login_data(clientId, clientSecret, true)
	else:
		authInfo.save_login_data("", "", false)
