# 캐릭터 우클릭 컨택스트 메뉴 ──────────────────────────────────────────────────────
# 캐릭터를 우클릭했을 때 나타나는 Context Menu (우클릭 메뉴)입니다.
# 설정 패널을 열지 않고도 캐릭터의 디스폰 및 숨기기 기능을 사용할 수 있습니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends PanelContainer

@onready var userDatabase = get_node("/root/mainWindow/UserDatabase")
@onready var userManager = get_node("/root/mainWindow/ChatUserManager")
var selectedCharacter = null

func _ready():
	hide()

func _input(event):
	# 숨겨진 상태에서는 아무 일도 하지 않습니다.
	if not visible:
		return
	
	# 만약 메뉴 바깥쪽을 클릭한 경우 메뉴를 다시 숨깁니다 (보통의 우클릭 메뉴처럼 동작합니다)
	if event is InputEventMouseButton and event.pressed:
		var mousePos = get_local_mouse_position()
		var rect = Rect2(Vector2.ZERO, size)
		
		if not rect.has_point(mousePos):
			hide()
			get_viewport().set_input_as_handled()

func show_character_menu(character: CharacterBody2D):
	selectedCharacter = character									# 선택된 캐릭터의 정보를 참조합니다.
	$VBoxContainer/canName.text = character.userData.nickname		# 사용자 이름
	$VBoxContainer/canUID.text = character.userData.channelId		# 사용자 채널 ID
	
	# 현재 마우스 위치를 컨택스트 메뉴 위치로 설정합니다.
	var mousePosition = get_viewport().get_mouse_position()		
	position = mousePosition
	
	# 현재 마우스 위치가 창 끝에 있다면, 창 밖으로 나가지 않도록 위치를 조정합니다.
	var viewportSize = get_viewport_rect().size
	if position.x + size.x > viewportSize.x:
		position.x = viewportSize.x - size.x
	if position.y + size.y > viewportSize.y:
		position.y = viewportSize.y - size.y
		
	show()
	
# ──────────────────────────────────────────────────────────────────────────── #

func _on_hide_cannyan_pressed() -> void:
	userManager.remove_user($VBoxContainer/canUID.text)
	userDatabase.update_hidden_status($VBoxContainer/canUID.text, true)
	
func _on_despawn_cannyan_pressed() -> void:
	userManager.remove_user($VBoxContainer/canUID.text)
