# 설정 UI 코드 (우측 패널) ──────────────────────────────────────────────────────
# 이 코드에서는 단순히 설정 패널의 숨기기/보이기 기능만을 정의하고 있습니다.
# (코드의 골자 자체는 settingUI_L.gd와 같습니다, 자세한 주석은 그쪽을 참조 바랍니다)
# ──────────────────────────────────────────────────────────────────────────── #

extends Control
@onready var settingPanel = $OptionPanel
@export var hidePosition = Vector2(1280, 0)
@export var showPosition = Vector2(960, 0)
@export var detectArea = 20
@export var animSpeed = 0.3

var menuEnabled = false
var mouseOnPanel = false
var windowFocused = false

func _ready():
	settingPanel.position = hidePosition
	get_window().focus_exited.connect(_on_window_focus_exited)
	get_window().focus_entered.connect(_on_window_focus_entered)
	
func _process(delta: float) -> void:
	var mousePos = get_viewport().get_mouse_position()
	var mouseInWindow = get_viewport_rect().has_point(mousePos)
	var screenWidth = get_viewport_rect().size.x	# 우측 메뉴의 경우엔 좌표 위치상 화면 너비를 감지에 활용합니다.
	mouseOnPanel = mouse_on_panel(mousePos)
	
	if mouseInWindow and (mousePos.x >= screenWidth - detectArea or mouseOnPanel):
		show_menu()
		
	elif menuEnabled and (not mouseInWindow or not mouseOnPanel):
		hide_menu()
		
func mouse_on_panel(mousePos: Vector2) -> bool:
	var panelRect = settingPanel.get_global_rect()
	return panelRect.has_point(mousePos)
	
func show_menu() -> void:
	if !menuEnabled and windowFocused:
		menuEnabled = true
		var tween = create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(settingPanel, "position", showPosition, animSpeed)

func hide_menu() -> void:
	if menuEnabled:
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
