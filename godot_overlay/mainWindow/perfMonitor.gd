# 간단한 퍼포먼스 모니터 (FPS, 메모리 사용량) ──────────────────────────────────────
# FPS 카운터의 경우에는 항상 작동하지만, 메모리 사용량의 경우에는 디버그 빌드에서만 작동합니다!
# 메모리 사용량 체크 전 Memory라는 이름의 Label Node를 perfMonitor 하위에 추가해주세요.
# ──────────────────────────────────────────────────────────────────────────── #

extends VBoxContainer

@onready var fpsMonitor: Label = $FPS
#@onready var memMonitor: Label = $Memory						# 해당 구문은 디버그 빌드에서만 작동합니다.

func _process(delta: float) -> void:
	_perf_monitor()
	
	if Input.is_action_just_pressed("FPSCounter"):				# FPSCounter 이벤트는 기본적으로 F2에 할당되어 있음
		self.visible = !self.visible
	
func _perf_monitor():
	var fps = Engine.get_frames_per_second()
	#var memory = OS.get_static_memory_usage() / 1024 / 1024  	# 해당 구문은 디버그 빌드에서만 작동합니다.
	
	fpsMonitor.text = "FPS %s" % fps
	#memMonitor.text = "MEM %sMB" % memory						# 해당 구문은... 말 안 해도 이제 아시죠?
