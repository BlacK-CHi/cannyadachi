# 캐릭터 객체 스크립트 ───────────────────────────────────────────────────────────
# 채팅이 입력되면 화면에 생성되는 캐릭터의 동작, 상태 전환, 물리 처리를 담당하는 메인 스크립트입니다.
# 사용자의 채팅에 반응하여 말풍선을 표시하고, 명령어 일부를 처리하며, 다양한 물리 기반 동작을 수행합니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends CharacterBody2D

# 캐릭터의 상태를 정의하는 enum입니다. (State Machine 구조)
enum State { IDLE, WALK, JUMP, FALL, DANCE, SIT, GRAB, THROWN }
@export var currentState: State = State.WALK

# 노드 참조 및 초기 설정
@onready var nameTag = $Nametag
@onready var sprite = $sprite
@onready var chatBubble: PackedScene = preload("res://character/chatBubble.tscn")
@onready var userDatabase = get_node("/root/mainWindow/UserDatabase")
var userData: chatUser

# 이동 및 상태 관련 변수
var direction = 0							# 캐릭터의 이동 방향 (-1: 왼쪽, 1: 오른쪽)
var stateTimer = 0							# 현재 상태 지속 시간
var turnChance = 0.001						# 랜덤하게 방향을 바꿀 확률
var nextStateChange = 0						# 다음 상태 변경까지의 시간

# 드래그 앤 드롭 관련 변수
var isDragged: bool = false					# 현재 드래그 중인지 여부
var animationOverride: bool = false			# 애니메이션 오버라이드 상태 (특정 애니메이션 강제 재생 시 사용)
var dragOffset: Vector2 = Vector2.ZERO		# 드래그 시 마우스와 캐릭터 위치의 오프셋
var lastPosition: Vector2 = Vector2.ZERO 	# 이전 프레임의 위치 (던지기 속도 계산용)
var throwVelocity: Vector2 = Vector2.ZERO 	# 던져졌을 때의 속도
var mouseOver: bool = false					# 마우스가 캐릭터 위에 있는지 여부

var viewportRect: Rect2						# 현재 뷰포트의 크기
var boundaryMargin: float = 50.0			# 화면 밖 판정을 위한 여유 공간
var respawnCallback: Callable				# 화면 밖으로 나갔을 때 호출할 콜백 함수

# 캐릭터 색상 팔레트 - 각 색상 이름과 Hue Shift 값을 정의합니다.
# 해당 팔레트 값은 chatUser.gd와 동일하게 정의되어야 합니다.
const COLOR_PALETTE = {
	"오리지널": 0.0,
	"블루베리": 0.05,
	"포도": 0.2,
	"복숭아": 0.3,
	"딸기": 0.45,
	"오렌지": 0.55,
	"레몬": 0.6,
	"라임":0.7,
	"녹차": 0.8,
	"민트": 0.92
}

func _ready() -> void:
	direction = [-1, 1].pick_random()		# 초기 이동 방향을 랜덤하게 설정합니다.
	viewportRect = get_viewport_rect()		# 현재 뷰포트 크기를 저장합니다.
	
	get_viewport().size_changed.connect(_on_viewport_size_changed)

# 사용자 데이터를 설정하고 캐릭터를 초기화합니다.
func _setup(user: chatUser) -> void:
	userData = user
	nameTag.text = userData.nickname		# 이름표에 사용자 닉네임을 표시합니다.
	
	# 사용자가 설정한 색상이 있으면 해당 색상을, 없으면 랜덤 색상을 적용합니다.
	if userData.colorName and userData.colorName != "":
		set_color_by_name(userData.colorName)
	else:
		var color_keys = COLOR_PALETTE.keys()
		var random_color = color_keys[randi() % color_keys.size()]
		set_color_by_name(random_color)


func _physics_process(delta: float) -> void:
	if isDragged:
		# 드래그 중일 때: 마우스 위치를 따라 이동하고, 던지기 속도를 계산합니다.
		var mouse_pos = get_global_mouse_position()
		var target_pos = mouse_pos - dragOffset
	
		throwVelocity = (target_pos - lastPosition) / delta
		lastPosition = target_pos
		global_position = target_pos
		velocity = Vector2.ZERO
	
	else:
		if not is_on_floor():							# 공중에 떠 있는 경우, 중력을 적용합니다.
			velocity.y += userConfig.gravity * delta
		else:											# 착지한 경우 수직속도를 0으로 초기화합니다.
			if velocity.y > 0: 
				velocity.y = 0
			# 던져진 상태에서 착지하면 IDLE 상태로 전환합니다.
			if currentState == State.THROWN:
				currentState = State.IDLE
				velocity.x = 0
				_reset_state_timer()
		
		if currentState != State.THROWN:				# 던져진 상태가 아니면 자동 상태 전환을 처리합니다.
			stateTransition(delta)
		
		if currentState != State.THROWN:				# 던져진 후, 던지기 속도가 남아있으면 서서히 감속합니다.
			if throwVelocity.length() > 1:
				velocity = throwVelocity * 0.3
				throwVelocity = throwVelocity.lerp(Vector2.ZERO, 5.0 * delta)
			else:
				throwVelocity = Vector2.ZERO
			
			# StateMachine 상태에 따른 처리
			match currentState:
				State.WALK: handle_walk()
				State.SIT: velocity.x = 0		# 앉아 있거나 가만히 있는 경우 수평 속도를 0으로 설정합니다. (부동상태)
				State.IDLE: velocity.x = 0
				
				State.JUMP, State.FALL: velocity.x = direction * userConfig.moveSpeed * 0.3
	
	spriteChange()			# 현재 상태에 맞는 애니메이션을 재생합니다.
	move_and_slide()		# Godot의 물리 엔진을 사용하여 이동을 처리합니다.
	updateBoundary()		# 화면 경계를 벗어나지 않도록 처리합니다.

# 전역 입력 이벤트를 처리합니다 (마우스 버튼 입력).
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		# 마우스 왼쪽 버튼을 놓으면 드래그를 종료합니다.
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if currentState == State.GRAB:
				end_drag()
		# 마우스 오른쪽 버튼을 누르면 컨텍스트 메뉴를 표시합니다.
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if mouseOver:
				show_context_menu()
				get_tree().root.set_input_as_handled()

# 캐릭터 영역 내 마우스 클릭 이벤트를 처리합니다.
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int):
	if event is InputEventMouseButton:
		# 캐릭터를 클릭하면 드래그를 시작합니다.
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			start_drag()
			get_tree().root.set_input_as_handled()

# 리스폰 콜백 함수를 설정합니다.
func _respawn_callback(callback: Callable) -> void:
	respawnCallback = callback

# ──────────────────────────────────────────────────────────────────────────────────────────────── #

# 캐릭터의 상태를 자동으로 전환합니다.
func stateTransition(delta: float) -> void:
	if !is_on_floor():		# 공중에서 상승 중이면 JUMP, 하강 중이면 FALL 상태로 전환합니다.
		if velocity.y < 0: currentState = State.JUMP
		else: currentState = State.FALL
		return

	if currentState == State.JUMP or currentState == State.FALL:	# 착지 시 IDLE 상태로 전환합니다.
		currentState = State.IDLE
		_reset_state_timer()
		return
	
	# SIT, GRAB, THROWN 상태에서는 자동 전환을 차단합니다.
	if currentState == State.SIT or currentState == State.GRAB or currentState == State.THROWN:
		return
	
	# 일정 시간이 지나면 상태를 전환합니다.
	stateTimer += delta
	if stateTimer >= nextStateChange:
		match currentState:
			State.IDLE:								# IDLE -> WALK : 랜덤 방향으로 이동
				currentState = State.WALK
				direction = [-1, 1].pick_random()
			State.WALK:
				currentState = State.IDLE			# WALK -> IDLE : 해당 위치에서 대기
		_reset_state_timer()						# 어느 방향으로든 전환이 끝나면 다음 전환 시점을 계산합니다.

# WALK 상태일 때의 이동을 처리합니다.
func handle_walk() -> void:
	if not _is_in_viewportBound():					# 화면 경계에 도달하면 방향을 반대로 바꿉니다.
		direction *= -1
	if is_on_wall():								# 벽에 부딪히면 방향을 반대로 바꿉니다.
		direction *= -1
	elif randf() < turnChance:						# 랜덤하게 방향을 바꿉니다.
		direction = [-1, 1].pick_random()
	
	velocity.x = direction * userConfig.moveSpeed

# 드래그를 시작합니다.
func start_drag() -> void:
	isDragged = true
	currentState = State.GRAB
	
	dragOffset = get_global_mouse_position() - global_position
	lastPosition = global_position
	throwVelocity = Vector2.ZERO

# 드래그를 종료합니다.
func end_drag() -> void:
	isDragged = false

	if throwVelocity.length() > 1:			# 빠르게 놓으면 던지기 상태로 전환
		currentState = State.THROWN
		velocity = throwVelocity * 0.5
		throwVelocity = Vector2.ZERO
	else:									# 천천히 놓으면 자유낙하 (일반적인 낙하)
		currentState = State.FALL
		throwVelocity = Vector2.ZERO

# 캐릭터가 화면 안에 있는지 확인합니다.
func _is_in_viewportBound() -> bool:
	var margin = 20.0
	return (global_position.x > margin and 
			global_position.x < viewportRect.size.x - margin)

# ──────────────────────────────────────────────────────────────────────────────────────────────── #

# 채팅 말풍선을 표시합니다.
func show_chatbubble(CHAT: String):
	# 느낌표(!)로 시작하는 메시지는 명령어로 처리합니다.
	if CHAT.to_lower().begins_with("!"):
		handle_command(CHAT)
		
	else:
		# 말풍선 인스턴스를 생성하고 화면에 추가합니다.
		var bubble = chatBubble.instantiate()
		$ChatContainer.add_child(bubble)
		bubble.get_node("MarginContainer/PanelContainer").set_text(CHAT)
		
		# 말풍선을 페이드인 효과로 표시합니다.
		bubble.modulate.a = 0.0
		var tween = create_tween()
		tween.tween_property(bubble, "modulate:a", 1.0, 0.2)
		
		# 최대 개수를 초과하면 가장 오래된 말풍선을 제거합니다.
		if $ChatContainer.get_child_count() > userConfig.maxChatStack:
			var oldest = $ChatContainer.get_child(0)
			remove_chatBubble(oldest)
		
		# 말풍선 지속 시간이 초과된 경우 말풍선을 제거합니다.
		await get_tree().create_timer(userConfig.bubbleDuration).timeout
		if is_instance_valid(bubble):
			remove_chatBubble(bubble)

# 말풍선을 페이드아웃 효과로 제거합니다.
func remove_chatBubble(bubble: Node):
	if not is_instance_valid(bubble): return
	
	var tween = create_tween()
	tween.tween_property(bubble, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): 
		if is_instance_valid(bubble):
			bubble.queue_free()
		tween.kill())

# 채팅 명령어를 처리합니다.
func handle_command(CMD: String):
	var parts = CMD.to_lower().strip_edges().split(" ")
	var command = parts[0]
	
	match command:
		"!jump", "!점프":			# 캐릭터 점프 - 앉아있거나 공중에 있는 경우 적용되지 않음
			if currentState == State.SIT: return
			if is_on_floor():
				velocity.y = -userConfig.jumpSpeed
				currentState = State.JUMP
		"!sit", "!앉아":				# 캐릭터 앉히기 - 지면에 있는 경우에만 실행되고, 대부분의 상태전환을 무시합니다.
			if is_on_floor(): currentState = State.SIT
		"!stand", "!일어나":			# 캐릭터 일으키기 - 앉은 상태에서 일어나는 애니메이션을 재생합니다.
			if currentState == State.SIT and is_on_floor():
				animationOverride = true	# 다른 애니메이션이 재생되지 않도록 잠금
				$sprite.play("stand")
				await $sprite.animation_finished
				currentState = State.IDLE
				animationOverride = false 
				_reset_state_timer()
		"!color", "!색바꾸기":		# 색상 바꾸기 - 색상 이름이 주어지면 해당 색상으로 변경합니다.
			if parts.size() > 1:
				set_color_by_name(parts[1])
			else:
				pass
				# TODO: 지정되지 않은 색상이나 명령어만 입력한 경우 챗봇으로 메시지 출력
		_:
			pass
			# TODO: 지정되지 않은 명령어인 경우 챗봇으로 오류 메시지 출력

# ──────────────────────────────────────────────────────────────────────────────────────────────── #

# 현재 상태에 맞는 스프라이트 애니메이션을 재생합니다.
func spriteChange():
	if direction < 1: $sprite.flip_h = true			# 이동 방향에 맞게 스프라이트를 좌우반전합니다.
	elif direction > 0: $sprite.flip_h = false		# -1(왼쪽)인 경우 좌우반전, 1(오른쪽)인 경우 그대로
	
	if animationOverride:							# 애니메이션 오버라이드가 활성화되어 있으면 상태 변경을 무시합니다.
		return
	else:
		match currentState:
			State.IDLE: $sprite.play("idle")
			State.WALK: $sprite.play("walk")
			State.JUMP: $sprite.play("jump")
			State.FALL: $sprite.play("fall")
			State.SIT: 
				if $sprite.animation != "sit":		# 이미 앉기 애니메이션이 재생 중이 아닐 때만 재생합니다. (반복재생 방지)
					$sprite.play("sit")
			State.THROWN: $sprite.play("fall")
			State.GRAB: $sprite.play("grab")
			State.DANCE: pass

# 색상 이름으로 캐릭터의 색상을 변경합니다.
func set_color_by_name(COLOR: String):
	if COLOR_PALETTE.has(COLOR):
		var hue = COLOR_PALETTE[COLOR]
		sprite_hue_shift(hue)
		userData.hueShift = hue
		userData.colorName = COLOR
		
		if userDatabase and userData.channelId:
			userDatabase.update_user_color(userData.channelId, hue, COLOR)
	else:
		pass

# 스프라이트의 색조(Hue)를 변경합니다.
func sprite_hue_shift(HUE: float):
	if sprite.material:
		sprite.material.set_shader_parameter("hue", HUE)
	
	if userData:
		userData.hueShift = HUE		# 색상 변경 후 사용자 정보에 Hue Shift 값을 저장합니다.

# ──────────────────────────────────────────────────────────────────────────────────────────────── #

# 화면 경계를 벗어나지 않도록 위치를 제한합니다.
func updateBoundary() -> void:
	
	# 일반 상태일 때는 화면 안에 위치하도록 제한합니다.
	if currentState != State.THROWN and not isDragged:
		if global_position.x < 0:
			global_position.x = 0
			velocity.x = 0
		elif global_position.x > viewportRect.size.x:
			global_position.x = viewportRect.size.x
			velocity.x = 0
			
		if global_position.y < 0:
			global_position.y = 0
			velocity.y = 0

	# 던져진 상태일 때는 완전히 화면 밖으로 나가면 리스폰을 요청합니다.
	elif currentState == State.THROWN:
		var oobDetection = (
			global_position.x < -boundaryMargin or
			global_position.x > viewportRect.size.x + boundaryMargin or
			global_position.y < -boundaryMargin or
			global_position.y > viewportRect.size.y + boundaryMargin
		)
		
		if oobDetection: _request_respawn()

# 캐릭터 우클릭 시 컨텍스트 메뉴를 표시합니다.
func show_context_menu():
	var context_menu = get_tree().root.get_node("/root/mainWindow/UI/ContextMenu")
	if context_menu: context_menu.show_character_menu(self)

# ──────────────────────────────────────────────────────────────────────────────────────────────── #

# 상태 타이머를 초기화하고 다음 상태 변경 시간을 랜덤하게 설정합니다.
func _reset_state_timer():
	stateTimer = 0.0
	nextStateChange = randf_range(userConfig.stateMin, userConfig.stateMax)

# 캐릭터가 창 밖으로 넘어간 경우, 리스폰을 요청합니다.
func _request_respawn():
	if respawnCallback:
		respawnCallback.call(self)
	else:
		queue_free()

func _on_viewport_size_changed() -> void:
	viewportRect = get_viewport_rect()
	
	# 창 크기가 작아져서 캐릭터가 화면 밖에 있으면 안쪽으로 이동시킵니다.
	if global_position.x > viewportRect.size.x:
		global_position.x = viewportRect.size.x - 10
	if global_position.y > viewportRect.size.y:
		global_position.y = viewportRect.size.y - 10

func _on_mouse_entered() -> void:
	mouseOver = true

func _on_mouse_exited() -> void:
	mouseOver = false
