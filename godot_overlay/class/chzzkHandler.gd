# ──────────────────────────────────────────────── #
#                     				Godot 치지직 이벤트 핸들러
#                           			Written by 블랙치이
# ──────────────────────────────────────────────── #
# 이 클래스는 치지직(Chzzk) 소켓 이벤트를 처리하고, 각 이벤트에 대한 시그널을 발생시킵니다.
# 채팅, 치즈후원, 정기구독 이벤트, 시스템 메시지를 관리하고 사용할 수 있는 형태로 제공합니다.
# 사용 전 우선 웹소켓 연결 및 이벤트 구독이 필요합니다. (ProxyClient.gd 참고)
# ──────────────────────────────────────────────── #

extends Node
class_name ChzzkEventHandler

# 시그널 정의 
signal on_system_message(message_type: String, data: Dictionary)		#시스템 메시지 수신
signal on_chat_received(chat_data: Dictionary)							#채팅 메시지 수신
signal on_donation_received(donation_data: Dictionary)					#치즈 후원 메시지 수신
signal on_subscription_received(subscription_data: Dictionary)			#정기구독 메시지 수신

var event_stats: Dictionary = {} # 이벤트 통계 (디버깅용)
var session_key: String = ""



# 소켓 이벤트를 처리하는 함수 ──────────────────────────────────────────
# event_type: 소켓에서 발생하는 이벤트 종류 (SYSTEM, CHAT, DONATION, SUBSCPIPTION)
func handle_socket_event(event_type: String, event_data: Dictionary) -> void:
	if not event_stats.has(event_type):
		event_stats[event_type] = 0
	event_stats[event_type] += 1
	
	# 이벤트 타입에 따라 그에 맞는 처리 함수를 호출합니다.
	# 알 수 없는 이벤트 타입에 대해서는 경고 메시지를 출력합니다.

	# - SYSTEM: 시스템 메시지 처리 (_handle_system_message)
	# - CHAT: 채팅 메시지 처리 (_handle_chat)
	# - DONATION: 치즈 후원 메시지 처리 (_handle_donation)
	# - SUBSCRIPTION: 정기구독 메시지 처리 (_handle_subscription)
	match event_type:
		"SYSTEM":
			_handle_system_message(event_data)
		"CHAT":
			_handle_chat(event_data)
		"DONATION":
			_handle_donation(event_data)
		"SUBSCRIPTION":
			_handle_subscription(event_data)
		_:
			print("[WARNING] 알 수 없는 이벤트 타입: ", event_type)


# 시스템 메시지 처리 함수 ──────────────────────────────────────────
# message_type: 시스템 메시지의 종류 (connected, subscribed, unsubscribed, revoked)
func _handle_system_message(data: Dictionary) -> void:
	var message_type = data.get("type", "") # 프록시로부터 받은 데이터에서 데이터 타입 및 내용을 추출합니다.
	var message_data = data.get("data", {})
	
	print("[SYSTEM] 시스템 메시지: ", message_type)
	
	# 각 시스템 메시지 타입에 따른 처리
	# - connected: 세션 연결 완료
	# - subscribed: 이벤트 구독 완료
	# - unsubscribed: 이벤트 구독 취소
	# - revoked: 이벤트 권한 취소
	match message_type:
		"connected":
			session_key = message_data.get("sessionKey", "")
			print("세션 연결 완료. SessionKey: ", session_key)
		"subscribed":
			var event_type = message_data.get("eventType", "")
			print("%s 이벤트 구독 완료됨" % event_type)
		"unsubscribed":
			var event_type = message_data.get("eventType", "")
			print("%s 이벤트 구독 취소됨" % event_type)
		"revoked":
			var event_type = message_data.get("eventType", "")
			print("%s 이벤트 권한 취소됨" % event_type)

	on_system_message.emit(message_type, message_data)

# 채팅 메시지 처리 함수 ──────────────────────────────────────────
func _handle_chat(data: Dictionary) -> void:
	var profile = data.get("profile", {})
	var emojis = data.get("emojis", {})
	
	# 채팅 데이터를 딕셔너리 형태로 재구성합니다.
	var chat_data = {
		"channel_id": data.get("channelId", ""),				# 채널 ID (수신자, 스트리머)
		"sender_channel_id": data.get("senderChannelId", ""),	# 발송자 채널 ID (채팅 작성자)
		"nickname": profile.get("nickname", ""),				# 발송자 닉네임
		"user_role": profile.get("userRoleCode", ""),			# 발송자 역할 (USER, MODERATOR, STREAMER)
		"message": data.get("content", ""),						# 채팅 메시지 내용
		"badges": profile.get("badges", []),					# 발송자 뱃지 목록
		"verified": profile.get("verifiedMark", false),			# 발송자 인증 여부
		"emojis": emojis,										# 채팅에 포함된 이모지 정보
		"message_time": data.get("messageTime", 0)				# 채팅 메시지 타임스탬프
	}
	on_chat_received.emit(chat_data)

# 치즈 후원 메시지 처리 함수 ──────────────────────────────────────────
func _handle_donation(data: Dictionary) -> void:
	print("[DONATION] 후원 수신")
	
	var emojis = data.get("emojis", {})

	# 후원 데이터를 딕셔너리 형태로 재구성합니다.
	var donation_data = {
		"channel_id": data.get("channelId", ""),					# 채널 ID (수신자, 스트리머)	
		"donator_channel_id": data.get("donatorChannelId", ""),		# 후원자 채널 ID
		"donator_nickname": data.get("donatorNickname", ""),		# 후원자 닉네임
		"donation_type": data.get("donationType", ""), 				# CHAT(채팅후원), VIDEO(영상도네)
		"pay_amount": data.get("payAmount", "0"),  					# 후원 액수 (원 단위)
		"donation_text": data.get("donationText", ""),				# 후원 메시지
		"emojis": emojis
	}
	
	print("후원자: %s, 금액: %s원, 메시지: %s" % [
		donation_data["donator_nickname"],
		donation_data["pay_amount"],
		donation_data["donation_text"]
	])
	on_donation_received.emit(donation_data)

# 정기구독 메시지 처리 함수 ──────────────────────────────────────────
func _handle_subscription(data: Dictionary) -> void:
	print("[SUBSCRIPTION] 구독 수신")
	
	var tier_no = data.get("tierNo", 0)			# 정기구독 티어 
	var month = data.get("month", 0)			# 구독 기간 (개월)
	
	# 구독 데이터를 딕셔너리 형태로 재구성합니다.
	var subscription_data = {
		"channel_id": data.get("channelId", ""),						# 채널 ID (수신자, 스트리머)
		"subscriber_channel_id": data.get("subscriberChannelId", ""),	# 구독자 채널 ID
		"subscriber_nickname": data.get("subscriberNickname", ""),		# 구독자 닉네임
		"tier_number": tier_no,											# 정기구독 티어
		"tier_name": data.get("tierName", ""),							# 티어 이름
		"month": month													# 구독 기간 (개월)
	}
	
	print("구독자: %s, 티어: %d, 기간: %d개월" % [
		subscription_data["subscriber_nickname"],
		subscription_data["tier_number"],
		subscription_data["month"]
	])
	on_subscription_received.emit(subscription_data)

func get_session_key() -> String:
	"""현재 세션 키 반환"""
	return session_key

# 디버그용 함수 (이벤트 통계조회 및 초기화) ──────────────────────────────────────────
func get_event_statistics() -> Dictionary:
	"""이벤트 통계 반환"""
	return event_stats.duplicate()

func reset_statistics() -> void:
	"""이벤트 통계 초기화"""
	event_stats.clear()
