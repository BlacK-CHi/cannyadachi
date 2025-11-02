extends Window

const ANIMATION_NAME = [
	"idle",
	"walk",
	"jump",
	"fall",
	"grab",
	"sit",
	"stand"
]


@onready var atlasLoader = $AtlasLoader
@onready var avatarSaver = $AvatarSaver

# OptionButton으로 변경!
@onready var animSelector = $AnimSelector
@onready var previewSprite = $previewSprite


# 데이터
var loadedAtlasImage: Image
var spriteSet: SpriteFrames
var spriteWidth: int = 32
var spriteHeight: int = 32
var animData: Dictionary = {}

func _ready():
	$Save.disabled = true
	$Generate.disabled = true
	animSelector.disabled = true

func generate_frames():
	animData.clear()
	spriteSet = SpriteFrames.new()
	
	var cols = loadedAtlasImage.get_width() / spriteWidth
	var rows = loadedAtlasImage.get_height() / spriteHeight
	
	for row in range(rows):
		var animName = ANIMATION_NAME[row] if row < ANIMATION_NAME.size() else "row_" + str(row)
		
		spriteSet.add_animation(animName)
		spriteSet.set_animation_speed(animName, $FrameSec.value)
		spriteSet.set_animation_loop(animName, true)
		
		var frameTextures = []
		
		for col in range(cols):
			var frameImage = Image.create(spriteWidth, spriteWidth, false, loadedAtlasImage.get_format())
			frameImage.blit_rect(
				loadedAtlasImage,
				Rect2i(col * spriteWidth, row * spriteHeight, spriteWidth, spriteWidth),
				Vector2i(0, 0)
			)
			
			if is_frame_empty(frameImage):
				continue  # 빈 프레임은 건너뛰기
				
			var frameTexture = ImageTexture.create_from_image(frameImage)
			spriteSet.add_frame(animName, frameTexture)
			frameTextures.append(frameTexture)
		
		animData[row] = {
			"name": animName,
			"frames": frameTextures,
			"frame_count": cols
		}

func update_animation_selector():
	animSelector.clear()
	
	# 애니메이션 목록을 OptionButton에 추가
	for row in animData.keys():
		var data = animData[row]
		animSelector.add_item(data.name)
		animSelector.set_item_metadata(animSelector.item_count - 1, row)
	
	if animSelector.item_count > 0:
		animSelector.select(0)
		_on_animation_selected(0)

func is_frame_empty(image: Image) -> bool:
	if not image.detect_alpha():
		return false

	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			if pixel.a > 0.01:
				return false

	return true

func reset_all():
	$AtlasLocation.text = ""
	$AvatarName.text = ""
	$AvatarAuthor.text = ""
	$AvatarDesc.text = ""
	$Width.value = 32
	$Height.value = 32
	$FrameSec.value = 5
	
	loadedAtlasImage = null
	spriteSet = null
	animData.clear()
	
	animSelector.clear()
	animSelector.disabled = true
	$Generate.disabled = true
	$Save.disabled = true
	previewSprite.sprite_frames = null
	previewSprite.stop()

# ──────────────────────────────────────────────────────────────────────────── #
func _on_load_button_pressed():
	atlasLoader.popup_centered()

func _on_file_selected(path: String):
	$AtlasLocation.text = path
	loadedAtlasImage = Image.load_from_file(path)
	
	if loadedAtlasImage == null:
		return
	
	$Generate.disabled = false

func _on_generate_button_pressed():
	spriteWidth = $Width.value
	spriteHeight = $Height.value
	
	generate_frames()
	update_animation_selector()
	
	$Save.disabled = false
	animSelector.disabled = false

func _on_animation_selected(index: int):
	var row = animSelector.get_item_metadata(index)
	var animName = animData[row].name
	
	# 프리뷰 스프라이트에 적용
	previewSprite.sprite_frames = spriteSet
	previewSprite.animation = animName
	previewSprite.play()

func _on_save_button_pressed():
	if spriteSet == null:
		return
		
	avatarSaver.popup_centered()
	
func _on_avatar_save_selected(path: String):
	spriteSet.set_meta("avatar_name", $AvatarName.text)
	spriteSet.set_meta("author", $AvatarAuthor.text)
	spriteSet.set_meta("description", $AvatarDesc.text)

	var error = ResourceSaver.save(spriteSet, path)
	if error == OK: pass
	else: pass

func _on_cancel_button_pressed() -> void:
	reset_all()
	hide()
	
func _on_close_requested() -> void:
	reset_all()
	hide()
