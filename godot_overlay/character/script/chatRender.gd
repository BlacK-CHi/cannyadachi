# 말풍선 자동 크기 조절 ──────────────────────────────────────────────────────────
# 채팅 텍스트를 받아오고, 텍스트 길이에 따라 자동으로 말풍선의 가로 길이를 조절합니다.
# ──────────────────────────────────────────────────────────────────────────── #

extends RichTextLabel
const MAX_WIDTH = 200

func set_chat(chat_data: Dictionary):
	var message = chat_data["message"]
	var emojis = chat_data.get("emojis", {})
	var emojiCache = globalNode.chzzkHandler.emojiCache

	
	for emoji_id in emojis.keys():
		var emoji_key = "{:" + emoji_id + ":}"
		if emoji_key in message and emoji_id in emojiCache:
			message = message.replace(emoji_key, "[img=32x32]user://emoji_cache/" + emoji_id + ".tres[/img]")
	
	self.text = message
	await adjust_size()
func adjust_size():
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	self.custom_minimum_size.x = MAX_WIDTH
	self.size.x = MAX_WIDTH
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	autowrap_mode = TextServer.AUTOWRAP_OFF
	await get_tree().process_frame
	
	var contentWidth = get_content_width()
	if contentWidth<= MAX_WIDTH:
		custom_minimum_size.x = contentWidth
		size.x = contentWidth
	else:
		autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		custom_minimum_size.x = MAX_WIDTH
		size.x = MAX_WIDTH
		await get_tree().process_frame
	
	custom_minimum_size.y = get_content_height()
	size.y = get_content_height()
	
	get_parent().reset_size()
