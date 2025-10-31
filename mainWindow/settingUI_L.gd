# 설정 UI 코드 (좌측 패널) ──────────────────────────────────────────────────────
# 이 코드에서는 단순히 설정 패널의 숨기기/보이기 기능만을 정의하고 있습니다.
# 설정 UI 값이 어떻게 전달되는지는 settingUI.gd를 참고해주세요.
# ──────────────────────────────────────────────────────────────────────────── #

extends Control

@onready var settingPanel = $OptionPanel
@export var hidePosition = Vector2(-320, 0) 			# 숨겼을 때의 위치
@export var showPosition = Vector2(0, 0)     			# 보이는 위치
@export var detectArea = 20  							# 감지 영역 너비 (px)
@export var animSpeed = 0.3 							# 애니메이션 속도
@onready var userManager: ChatUserManager = $"../../ChatUserManager"

var menuEnabled = false									# 메뉴 활성화 (표시) 여부
var mouseOnPanel = false								# 마우스가 패널 위에 있는지 확인
var windowFocused = false								# 윈도우가 포커스되어 있는지 확인

func _ready():
	settingPanel.position = hidePosition				# 프로그램 실행 시 기본적으로 숨깁니다.
	
	# 필요한 시그널 연결 (포커스 아웃, 포커스됨)
	get_window().focus_exited.connect(_on_window_focus_exited)
	get_window().focus_entered.connect(_on_window_focus_entered)

func _process(delta: float) -> void:
	var mousePos = get_viewport().get_mouse_position()			# 현재 마우스 위치 (Vector2i)
	var mouseInWindow = get_viewport_rect().has_point(mousePos) # 현재 마우스가 뷰포트 내에 있는지 (bool)
	mouseOnPanel = mouse_on_panel(mousePos)
	
	# 마우스가 창 안에 있고, 마우스 위치가 감지 영역 내에 있거나 메뉴 위에 있을 때 -> 메뉴 표시하기
	if mouseInWindow and (mousePos.x <= detectArea or mouseOnPanel):
		show_menu()
		
	# 메뉴가 활성화되어 있고, 마우스가 창 밖에 있거나 메뉴 바깥에 있는 경우 -> 메뉴 숨기기
	elif menuEnabled and (not mouseInWindow or not mouseOnPanel):
		hide_menu()

func mouse_on_panel(mousePos: Vector2) -> bool:				# 마우스가 설정 패널 안에 있는지 확인합니다.
	var panelRect = settingPanel.get_global_rect()
	return panelRect.has_point(mousePos)
	
func show_menu() -> void:
	if !menuEnabled and windowFocused:							# 메뉴가 숨겨져 있고, 창이 포커스되어 있을 때
		menuEnabled = true
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(settingPanel, "position", showPosition, animSpeed)

func hide_menu() -> void:
	if menuEnabled:												# 메뉴가 표시되어 있을 때
		menuEnabled = false
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(settingPanel, "position", hidePosition, animSpeed)

# ──────────────────────────────────────────────────────────────────────────── #

func _on_window_focus_entered() -> void:
	windowFocused = true
	
func _on_window_focus_exited() -> void:
	windowFocused = false
	hide_menu()
