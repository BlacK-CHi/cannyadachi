# 프록시 웹소켓 클라이언트─────────────────────────────────────────────────────── #
# 이 클래스는 Python으로 작성된 로컬 프록시 서버와 웹소켓을 통해 통신하는 클라이언트입니다.
# 프록시 서버는 치지직(Chzzk) 소켓과 연결되어 있으며, 이 클라이언트를 통해 치지직 이벤트를 수신하고 전송할 수 있습니다.
# 해당 코드를 사용하기 전 로컬 프록시 서버가 실행 중이여야 하고, proxy_url에 접속 정보를 입력해야 합니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends Node
class_name ProxyWSClient

signal connected
signal disconnected
signal message_received(message: Dictionary)
signal error_occurred(error_message: String)

var websocket: WebSocketPeer
var proxy_url: String = "ws://127.0.0.1:6543/ws" 		#로컬 프록시 서버 주소입니다. 필요에 따라 변경 가능합니다.
var isConnected: bool = false
var wsPollingRate


func _ready() -> void:
	websocket = WebSocketPeer.new()
	set_process(false)
	
	# CPU 사용량 절감을 위해 폴링레이트를 제한합니다. 사실상 사용 중에는 티가 안 나지만,
	# 만약 더 빠른 정보 받아오기를 원한다면 wait_time 값을 수정하거나 28-32행을 지우고, set_process(true)로 바꾼 후
	# poll_websocket 함수를 _process 함수로 만들어주세요.
	
	wsPollingRate = Timer.new()			# 웹소켓 폴링 타이머 
	wsPollingRate.wait_time = 0.1		# 기본적으로 약 10프레임마다 폴링을 진행합니다. (100ms의 지연시간 발생)
	wsPollingRate.timeout.connect(_poll_websocket)
	wsPollingRate.autostart = false
	add_child(wsPollingRate)
	
# 프록시 서버에 연결하는 함수 (반환값: 성공 여부 (bool)) ──────────────────────────────────────────
# 연결이 성공한 경우 true, 이미 연결되어 있거나 실패한 경우 false+오류 메시지를 반환합니다.
func connect_to_proxy() -> bool:
	if isConnected:
		push_error("이미 프록시 서버와 연결되어 있습니다.") 		# Godot 콘솔에 오류 메시지 출력 (디버거)
		return false
	
	var error = websocket.connect_to_url(proxy_url)			
	if error == OK:
		wsPollingRate.start()								# WebSocket과 제대로 연결된 경우에만 폴링을 시작합니다.
		return true
	
	elif error != OK:
		var error_msg = "연결 중 오류 발생: " + str(error)
		print(error_msg) 									# 오류 발생 시 콘솔에 오류 메시지를 출력하고
		error_occurred.emit(error_msg)						# 시그널로 해당 오류 내용을 전송합니다.
		return false
	return false

# 프록시 서버와 연결을 종료하는 함수
# 연결이 되어 있으면 소켓을 닫고, isConnected 플래그를 false로 설정합니다.
func disconnect_from_proxy() -> void:
	if websocket:
		websocket.close()
	isConnected = false

# 프록시 서버로 메시지를 전송하는 함수 (반환값: 성공 여부 (bool))
# 연결이 되어 있지 않으면 false+오류 메시지를 반환합니다.
# 연결되어 있다면 message를 JSON으로 변환 후 전송하고, 성공 시 true를 반환합니다.
func send_message(message: Dictionary) -> bool:
	if not isConnected:
		var error_msg = "프록시 서버에 연결되어 있지 않습니다."
		print(error_msg)
		error_occurred.emit(error_msg)
		return false
	
	# message 딕셔너리를 JSON 문자열로 변환합니다.
	var json_message = JSON.stringify(message)
	
	var error = websocket.send_text(json_message)
	if error != OK:
		var error_msg = "메시지 전송 중 오류 발생: " + str(error)
		print(error_msg)
		error_occurred.emit(error_msg)
		return false
	
	return true

# 프록시에게 명령어를 전송하는 함수들
# 각 함수는 프록시 서버로 특정 명령어를 포함한 메시지를 전송합니다.

# 액세스 토큰 및 소켓 URL 설정 
func set_token(access_token: String, socket_url: String) -> bool:
	var message = {
		"command": "set_token",
		"access_token": access_token,
		"socket_url": socket_url
	}
	return send_message(message)

# 치지직 소켓에 연결
func connect_to_chzzk() -> bool:
	var message = {
		"command": "connect"
	}
	return send_message(message)

# 치지직 소켓에서 연결 해제
func disconnect_from_chzzk() -> bool:
	var message = {
		"command": "disconnect"
	}
	return send_message(message)


func _poll_websocket() -> void:
	websocket.poll() 			# 웹소켓 상태를 계속 갱신합니다. (이게 없으면 접속이 불가능)
	var state = websocket.get_ready_state()
	
	# 웹소켓의 상태에 따라 연결/끊김 이벤트를 처리합니다.
	# STATE_OPEN(연결됨) 및 STATE_CLOSED(끊김) 상태를 감지하여 시그널을 발생시킵니다.
	match state:
		WebSocketPeer.STATE_OPEN:
			if not isConnected:
				isConnected = true
				print("[PROXY] 프록시 서버에 연결되었습니다.")
				connected.emit()
		
		WebSocketPeer.STATE_CLOSED:
			if isConnected:
				isConnected = false
				print("[PROXY] 프록시 서버와의 연결이 끊어졌습니다.")
				disconnected.emit()
	
	# 수신 메시지 처리
	if websocket.get_available_packet_count() > 0:
		_on_data_received()

# 수신된 데이터 처리 함수
func _on_data_received() -> void:
	var message_text = websocket.get_packet().get_string_from_utf8()
	
	var json = JSON.new()
	var error = json.parse(message_text)
	
	if error != OK:
		var error_msg = "JSON 파싱 실패: " + message_text
		print(error_msg)
		error_occurred.emit(error_msg)
		return
	
	var message = json.data
	message_received.emit(message)
