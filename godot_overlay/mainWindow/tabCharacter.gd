# 캐릭터 설정 탭 ────────────────────────────────────────────────────────────────
# 캐릭터 설정 탭의 라벨을 업데이트하고, 변경된 값을 userConfig에 전달해주는 스크립트입니다.
# 값에 따라 값 변경 시 userConfig에 전달하거나/전달하지 않고 다른 함수를 시작하는 기능도 맡습니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends Control

@onready var userManager: ChatUserManager = $"../../../../ChatUserManager"

func _ready() -> void:
	ui_load_settings()				# 최초 시작 시 UI에 설정값을 불러옵니다.

func _process(delta: float) -> void:
	# 설정값 변경 시 해당 설정값 표시 라벨을 업데이트합니다.
	$AFKPollingTime.text = str($AFKPolling.value) + "초"
	$AFKDetectTime.text = str($AFKDetection.value) + "초"
	$BubbleTime.text = str($BubbleDuration.value) + "초"
	$BubbleCount.text = str(int($BubbleStack.value)) + "개"
	$jumpSpeedLabel.text = str($JumpPower.value) + "px/delta"
	$MoveSpeedLabel.text = str($MoveSpeed.value) + "px/delta"
	$GravityLabel.text = str($Gravity.value) + "px/delta"
	
	# 잠수 감지 설정이 활성화된 경우에는 슬라이더를 수정할 수 있게 하고, 비활성화된 경우 잠급니다.
	if $AFKToggle.button_pressed:
		$AFKPolling.editable = true
		$AFKDetection.editable = true
	else:
		$AFKPolling.editable = false
		$AFKDetection.editable = false

# userConfig에 저장되어 있는 설정값을 UI에 불러옵니다.
func ui_load_settings() -> void:
	$AFKPolling.value = userConfig.afkPollingTime
	$AFKDetection.value = userConfig.afkDetectTime
	$BubbleDuration.value = userConfig.bubbleDuration
	$BubbleStack.value = userConfig.maxChatStack
	$JumpPower.value = userConfig.jumpSpeed
	$MoveSpeed.value = userConfig.moveSpeed
	$Gravity.value = userConfig.gravity
	$spawnWidth.text = str(userConfig.spawnWidth)
	$spawnHeight.text = str(userConfig.spawnHeight)
	$spawnOffsetX.text = str(userConfig.spawnOffsetX)
	$spawnOffsetY.text = str(userConfig.spawnOffsetY)
	$stateMin.text = str(userConfig.stateMin)
	$stateMax.text = str(userConfig.stateMax)

# 현재 설정값들을 모두 초기값으로 되돌리고, userConfig에도 해당 값을 전달한 후 UI에 반영합니다.
func reset_default_value() -> void:
	userConfig.afkPollingTime = 300.0
	userConfig.afkDetectTime = 600.0
	userConfig.bubbleDuration = 3.0
	userConfig.maxChatStack = 3.0
	userConfig.jumpSpeed = 400.0
	userConfig.moveSpeed = 100.0
	userConfig.gravity = 980.0
	userConfig.spawnWidth = 1280.0
	userConfig.spawnHeight = 200.0
	userConfig.spawnOffsetX = 0.0
	userConfig.spawnOffsetY = 0.0
	userConfig.stateMin = 2.0
	userConfig.stateMax = 5.0
	ui_load_settings()
	userManager.update_pollingRate(userConfig.afkPollingTime)


# 이 아래쪽 시그널들은 설정값을 변경할 경우 userConfig로 새로운 설정값을 전달하는 시그널입니다.
func _on_afk_polling_value_changed(value: float) -> void:
	userConfig.afkPollingTime = value
	userManager.update_pollingRate(value)

func _on_afk_detection_value_changed(value: float) -> void:
	userConfig.afkDetectTime = value

func _on_bubble_duration_value_changed(value: float) -> void:
	userConfig.bubbleDuration = value

func _on_bubble_stack_value_changed(value: float) -> void:
	userConfig.maxChatStack = value

func _on_jump_power_value_changed(value: float) -> void:
	userConfig.jumpSpeed = value

func _on_move_speed_value_changed(value: float) -> void:
	userConfig.moveSpeed = value

func _on_gravity_value_changed(value: float) -> void:
	userConfig.gravity = value

func _on_spawn_width_text_changed(new_text: String) -> void:
	userConfig.spawnWidth = float(new_text)

func _on_spawn_height_text_changed(new_text: String) -> void:
	userConfig.spawnHeight = float(new_text)

func _on_spawn_offset_x_text_changed(new_text: String) -> void:
	userConfig.spawnOffsetX = float(new_text)

func _on_spawn_offset_y_text_changed(new_text: String) -> void:
	userConfig.spawnOffsetY = float(new_text)

func _on_state_min_text_changed(new_text: String) -> void:
	userConfig.stateMin = float(new_text)

func _on_state_max_text_changed(new_text: String) -> void:
	userConfig.stateMax = float(new_text)

func _on_cleanup_toggled(toggled_on: bool) -> void:	
	userManager.set_auto_cleanup(toggled_on)
