extends VBoxContainer

@onready var errorPopup = preload("res://mainWindow/errorPopup.tscn")


func pop_error(errorLevel: String, errorText: String):
	var popup = errorPopup.instantiate()
	self.add_child(popup)
	
	popup.set_error_text(errorLevel, errorText)
	
	# 말풍선을 페이드인 효과로 표시합니다.
	popup.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 1.0, 0.2)
	
	# 최대 개수를 초과하면 가장 오래된 말풍선을 제거합니다.
	if self.get_child_count() > 5:
		var oldest = self.get_child(0)
		remove_popup(oldest)
	
	# 말풍선 지속 시간이 초과된 경우 말풍선을 제거합니다.
	await get_tree().create_timer(5.0).timeout
	if is_instance_valid(popup):
		remove_popup(popup)

func remove_popup(popup: Node):
	if not is_instance_valid(popup): return
	
	var tween = create_tween()
	tween.tween_property(popup, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func(): 
		if is_instance_valid(popup):
			popup.queue_free()
		tween.kill())
		
