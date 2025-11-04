# 말풍선 자동 크기 조절 ──────────────────────────────────────────────────────────
# 채팅 텍스트를 받아오고, 텍스트 길이에 따라 자동으로 말풍선의 가로 길이를 조절합니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends PanelContainer

func set_text(text: String):
	$Chat.text = text
	await get_tree().process_frame
	var textLength = $Chat.get_theme_font("font").get_string_size(
		text, HORIZONTAL_ALIGNMENT_LEFT, -1, $Chat.get_theme_font_size("font_size"))
	
	# 200px를 넘으면 Custom Minimum Size를 200으로 설정하여 더 길어지지 않게 합니다.
	if textLength.x > 200:
		$Chat.custom_minimum_size.x = 200
		
	# 200px 미만인 경우 텍스트 길이만큼 늘어나도록 합니다.
	else:
		$Chat.custom_minimum_size.x = textLength.x
