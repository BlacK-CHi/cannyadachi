extends Node2D

var clientId: String
var clientSecret: String
var authCode: String
var stateCode: String

var accessToken: String
var refreshToken: String
var socketEndpoint: String
var sessionKey: String
var redirectUrl: String = "https://localhost:8080"

const auth: String = "https://chzzk.naver.com/account-interlock"
const token: String = "https://openapi.chzzk.naver.com/auth/v1/token"
const revoke: String = "https://openapi.chzzk.naver.com/auth/v1/token/revoke"
const session: String = "https://openapi.chzzk.naver.com/open/v1/sessions/auth"
const eventSub: String = "https://openapi.chzzk.naver.com/open/v1/sessions/events"
@onready var headers = ["User-Agent: Mozilla/5.0","Content-Type: application/json", "Authorization: Bearer CLIENT_SECRET"]
@onready var proxyStatus = $"UI/settingUI_L/OptionPanel/인증 설정/ProxyStatus"

@onready var proxyClient: ProxyWSClient = $ProxyClient
@onready var chzzkHandler: ChzzkEventHandler = $ChzzkHandler
@onready var userManager: ChatUserManager = $ChatUserManager
@onready var characterContainer: Node2D = $CharacterContainer
@onready var errorPopup = $UI/ErrorContainer

var completeCallback: Callable
var autoConnecting
var showSpawnArea = false

func _ready() -> void:
	updateGroundPosition()
	get_viewport().size_changed.connect(_on_viewport_resized)
	
func getAuthUrl(CLIENT_ID: String, STATE: String) -> String:
	var AuthUrl: String = str(auth) + "?response_type=code" + "&clientId=" + CLIENT_ID + "&redirectUri=" + redirectUrl + "&state=" + STATE
	return AuthUrl

func randomState(length: int, charset: String = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") -> String:
	var rng = RandomNumberGenerator.new(); rng.randomize()
	
	var randomString = ""
	for i in range(length):
		var randomIndex = rng.randi_range(0, charset.length() - 1)
		randomString += charset[randomIndex]
		
	return randomString

#------------------------------------------------------------------------------ #

func getAccessToken(RESULT: int, RESP_CODE: int, header: PackedStringArray, BODY: PackedByteArray) -> void:
	if RESULT != HTTPRequest.RESULT_SUCCESS: print("[GET] HTTP Request Error: ", RESULT)
	var rawResponse = BODY.get_string_from_utf8()
	
	if RESP_CODE == 200:
		var response = JSON.parse_string(rawResponse)
		var respToken = response["content"]
		if response:
			accessToken = respToken["accessToken"]
			refreshToken = respToken["refreshToken"]
			$"UI/settingUI_L/OptionPanel/인증 설정/AccessToken".text = accessToken
			$"UI/settingUI_L/OptionPanel/인증 설정/RefreshToken".text = refreshToken
		else:
			print(str("[REST] JSON Parsing Error: ", rawResponse))
	else:
		print(str("[REST] HTTP Error %d: %s", RESP_CODE, rawResponse))

func refreshAccessToken(RESULT: int, RESP_CODE: int, header: PackedStringArray, BODY: PackedByteArray) -> void:
	if RESULT != HTTPRequest.RESULT_SUCCESS: print("[REFRESH] HTTP Request Error: ", RESULT)
	var rawResponse = BODY.get_string_from_utf8()
	
	if RESP_CODE == 200:
		var response = JSON.parse_string(rawResponse)
		var respToken = response["content"]
		if response:
			accessToken = respToken["accessToken"]
			refreshToken = respToken["refreshToken"]
			$"settingUI/OptionPanel/인증 설정/AccessToken".text = accessToken
			$"settingUI/OptionPanel/인증 설정/RefreshToken".text = refreshToken
		else:
			print(str("JSON Parsing Error: ", rawResponse))
	else:
		print(str("HTTP Error %d: %s", RESP_CODE, rawResponse))

func getSessionInfo(RESULT: int, RESP_CODE: int, header: PackedStringArray, BODY: PackedByteArray) -> void:
	if RESULT != HTTPRequest.RESULT_SUCCESS: print("[REFRESH] HTTP Request Error: ", RESULT)
	var rawResponse = BODY.get_string_from_utf8()
	
	if RESP_CODE == 200:
		var response = JSON.parse_string(rawResponse)
		if response:
			var respUrl = response["content"]
			socketEndpoint = respUrl["url"]
		
			if autoConnecting:
				print("[REST] 세션 정보를 불러왔습니다.")
				await get_tree().create_timer(0.5).timeout
				print("[PROXY] 프록시와 연결 중입니다...")
				proxyClient.connect_to_proxy()
		else:
			print(str("JSON Parsing Error: ", rawResponse))
	else:
		print(str("HTTP Error %d: %s", RESP_CODE, rawResponse))
		globalNode.errorPopup.pop_error("오류", "프록시 연결 중 오류가 발생했습니다.\n응답 코드 : %s" % RESP_CODE)
		if autoConnecting:
			$"UI/settingUI_L/OptionPanel/인증 설정/ProxyToggle".button_pressed = false
			autoConnecting = false

#------------------------------------------------------------------------------ #

func restAPIRequest(REQ_TO: String, BODY: Dictionary, METHOD: HTTPClient.Method, ON_COMPLETE: Callable) -> void:
	completeCallback = ON_COMPLETE
	var jsonPayload = JSON.stringify(BODY)
	var request = $RESTCaller
	
	var currentHeaders = [ "User-Agent: Mozilla/5.0", "Content-Type: application/json", "Authorization: Bearer " + accessToken]
	var error = request.request(REQ_TO, currentHeaders, METHOD, jsonPayload)
	
	if error != OK: print("[ERR] Token Request Failed : ", error)

func eventSubUnsub(ACTION: String, EVENT: String) -> void:
	var request = $SUBCaller
	var currentHeaders = [ "User-Agent: Mozilla/5.0", "Content-Type: application/json", "Authorization: Bearer " + accessToken]
	var subUrl: String = ""
	match ACTION:
		"sub": subUrl = eventSub + "/subscribe/" + EVENT
		"unsub": subUrl = eventSub + "/unsubscribe/" + EVENT

	subUrl = subUrl + "?sessionKey=" + sessionKey
	var error = request.request(subUrl, currentHeaders, HTTPClient.METHOD_POST)
	if error != OK: print("[PUBSUB] SUb/Unsub Request Failed : ", error)

#------------------------------------------------------------------------------ #

func _on_proxy_message(message: Dictionary) -> void:
	var msgType = message.get("type", "")
	
	match msgType:
		"token_set":
			print("[PROXY] 프록시에 인증 정보를 성공적으로 전달했습니다.")
			# 자동 연결 중이면 치지직 연결
			if autoConnecting:
				await get_tree().create_timer(0.5).timeout
				print("[PROXY] 치지직 API와 연결하는 중입니다...")
				proxyClient.connect_to_chzzk()
		
		"connection_status":
			var status = message.get("status", "")
			if status == "connected":
				print("[PROXY] 치지직 API와 성공적으로 연결되었습니다.")
				globalNode.errorPopup.pop_error("알림", "치지직 API와 정상적으로 연결되었습니다.\n즐거운 스트리밍 되세요!")

			else:
				print("프록시 연결 상태: " + status)
				proxyStatus.text = "✅ 연결됨"
		
		"session_key":
			var session_key = message.get("session_key", "")
			sessionKey = session_key
			print("[PROXY] 세션 키를 받아왔습니다.")
		
		"socket_event":
			var event = message.get("event", "")
			var data = message.get("data", {})
			chzzkHandler.handle_socket_event(event, data)
		
		"error":
			var error_msg = message.get("message", "")
			print("[PROXY] 오류: " + error_msg)
			globalNode.errorPopup.pop_error("오류", error_msg)
			if autoConnecting:
				$"../Control/ProxyToggle".button_pressed = false
				autoConnecting = false

func _on_proxy_connected() -> void:
	print("[PROXY] 프록시 서버와 연결되었습니다.")
	proxyClient.set_token(accessToken, socketEndpoint)
	
func _on_proxy_disconnected() -> void:
	print("[PROXY] 프록시와 연결을 해제합니다...")
	$"../Control/ProxyToggle".button_pressed = false
	proxyStatus.text = "❌ 연결 해제됨"
	autoConnecting = false

#------------------------------------------------------------------------------ #

func _on_system_message(message_type: String, data: Dictionary) -> void:
	match message_type:
		"connected":
			print("[SYSTEM] 세션 연결 완료!")
			if autoConnecting:
				autoConnecting = false
				print("[PROXY] 프록시 및 치지직과 연결이 수립되었습니다.")
				if sessionKey:
					await get_tree().create_timer(1.0).timeout
					eventSubUnsub("sub", "chat")
					proxyStatus.text = "✅ 연결됨"
					
		"subscribed":
			var event_type = data.get("eventType", "")
			print("[SYSTEM] 이벤트 구독 완료: %s" % event_type)
		"unsubscribed":
			var event_type = data.get("eventType", "")
			print(" [SYSTEM]이벤트 구독 취소: %s" % event_type)

func _on_chat_received(chat_data: Dictionary) -> void:
	var nickname = chat_data.get("nickname", "Unknown")
	var senderId = chat_data.get("sender_channel_id", "000000")
	var message = chat_data.get("message", "")
	print("[CHAT] %s (%s): %s" % [nickname, senderId, message])
	
	userManager.handle_chat_message(senderId, nickname, message)

func _on_cheese_received() -> void:
	pass

func _on_subscription_received() -> void:
	pass

func _on_user_joined(user: chatUser) -> void:
	print("[CHAT] %s 님 접속" % user.nickname)
	
	var cannyan = user.characterNode
	characterContainer.add_child(cannyan)
	cannyan._setup(user)
	cannyan._respawn_callback(Callable(self, "_respawn_user"))
	
	cannyan.position = _user_random_spawn()
	_user_join_animation(cannyan)
	

func _on_user_left(user: chatUser) -> void:
	print("[CHAT] %s 님 타임아웃" % user.nickname)
	
func _on_user_chat(user: chatUser, message: String) -> void:
	if user.characterNode:
		user.characterNode.show_chatbubble(message)

func _user_join_animation(cannyan: CharacterBody2D) -> void:
	cannyan.modulate.a = 0.0
	cannyan.scale = Vector2(0.3, 0.3)
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(cannyan, "modulate:a", 1.0, 0.5)
	tween.tween_property(cannyan, "scale", Vector2.ONE, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _user_random_spawn() -> Vector2:
	var spawnX = userConfig.spawnOffsetX + randf() * userConfig.spawnWidth
	var spawnY = userConfig.spawnOffsetY - randf() * userConfig.spawnHeight
	return Vector2(spawnX, spawnY)

func _respawn_user(cannyan: CharacterBody2D):
	cannyan.position = _user_random_spawn()
	cannyan.velocity = Vector2.ZERO
	cannyan.currentState = cannyan.State.FALL
	
	_user_join_animation(cannyan)
	print("[SYSTEM] %s 님이 리스폰되었습니다" % cannyan.userData.nickname)

func toggle_spawn_view(enabled: bool) -> void:
	showSpawnArea = enabled
	queue_redraw()  # 다시 그리기 요청

func _draw() -> void:
	if showSpawnArea:
		var rect = Rect2(
			Vector2(userConfig.spawnOffsetX, userConfig.spawnOffsetY),
			Vector2(userConfig.spawnWidth, userConfig.spawnHeight)  # (너비, 높이)
		)
		
		draw_rect(rect, Color.YELLOW, false, 2.0)
		draw_rect(rect, Color(1, 1, 0, 0.2), true)
#------------------------------------------------------------------------------ #

func _on_chzzkLogin_pressed() -> void:
	clientId =  $"UI/settingUI_L/OptionPanel/인증 설정/ClientID".text
	clientSecret = $"UI/settingUI_L/OptionPanel/인증 설정/ClientSecret".text
	stateCode = randomState(8)
	
	if clientId.is_empty() or clientSecret.is_empty():
		errorPopup.pop_error("오류", "Client ID/Secret을 입력해주세요.")
		return
		
	var loginUrl: String = getAuthUrl(clientId, stateCode)
	
	OS.shell_open(loginUrl)

func _on_chzzkAuth_pressed() -> void:
	var tokenCode = $"UI/settingUI_L/OptionPanel/인증 설정/AccessKey".text
	var requestBody = {
		"grantType": "authorization_code",
		"clientId": clientId,
		"clientSecret": clientSecret,
		"code": tokenCode,
		"state": stateCode,
		"redirectUri": redirectUrl
	}
	
	if tokenCode.is_empty():
		errorPopup.pop_error("오류", "액세스 키가 입력되지 않았습니다.")
		return
		
	restAPIRequest(token, requestBody, HTTPClient.METHOD_POST, Callable(self, "getAccessToken"))

func _on_proxy_toggled(toggled_on: bool) -> void:
	if toggled_on:
		await get_tree().process_frame
		await get_tree().process_frame
		
		if not _check_avatars():
			$"UI/settingUI_L/OptionPanel/인증 설정/ProxyToggle".button_pressed = false
			return
		else:
			autoConnecting = true
			print("세션 정보를 불러오는 중입니다...")
			proxyClient.proxy_url = $"UI/settingUI_L/OptionPanel/인증 설정/ProxyAddress".text
			proxyStatus.text = "📡 접속 중..."
			restAPIRequest(session, {}, HTTPClient.METHOD_GET, Callable(self, "getSessionInfo"))
		
	else:
		autoConnecting = false
		proxyStatus.text = "🔌 연결 해제됨"
		if proxyClient.is_connected:
			proxyClient.disconnect_from_chzzk()
			await get_tree().create_timer(0.3).timeout
			proxyClient.disconnect_from_proxy()

func _on_RESTCaller_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if completeCallback:
		completeCallback.call(result, response_code, headers, body)
		
func _on_spawn_visible_toggled(toggled_on: bool) -> void:
	toggle_spawn_view(toggled_on)

func _on_viewport_resized() -> void:
	updateGroundPosition()
#------------------------------------------------------------------------------ #

func updateGroundPosition() -> void:
	var viewportSize = get_viewport_rect()
	$CharacterContainer/ground/CollisionShape2D.global_position.y = viewportSize.size.y

func _check_avatars() -> bool:
	var avatarDB = globalNode.avatarDatabase
	
	if avatarDB and avatarDB.get_all_avatars().is_empty():
		globalNode.errorPopup.pop_error("오류", "등록된 아바타가 없습니다.\n연결 전 아바타를 먼저 추가해주세요.")
		return false
	if avatarDB and avatarDB.get_default_avatar().is_empty():
		globalNode.errorPopup.pop_error("오류", "기본 아바타로 설정된 아바타가 없습니다.\n기본 아바타를 설정해주세요.")
		return false
	return true
