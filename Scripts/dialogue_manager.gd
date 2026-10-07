extends CanvasLayer

@export var chars_per_sec = 40.0
@onready var dialog_manager: CanvasLayer = $"."
@onready var dialog_box: Control = $DialogBox
@onready var name_label: Label = $DialogBox/NameLabel
@onready var portrait: TextureRect = $DialogBox/Portrait
@onready var next_icon: Label = $DialogBox/NextIcon
@onready var dialog_text: RichTextLabel = $DialogBox/MainPanel/TextMargin/DialogText

signal dialog_started
signal dialog_finished

var _lines: Array = []
var _index: int = 0
var _type_tween: Tween
var _blink_tween: Tween

func _ready() -> void:
		dialog_text.bbcode_enabled = true
		dialog_text.scroll_active = false
		dialog_box.hide()
		#dialog_manager.dialog_finished.connect(func(): print("Dialogo finito"))
		#dialog_manager.start([
		#	{"name": "Sasaki", "text": "Ciao! [color=gold]Negro[/color]", "portrait": preload("res://icon.svg")},
		#	{"name": "Sasaki", "text": "In questa seconda riga, un po' più lunga, per vedere come va a capo il testo, ti dico quanto odio le minoranze"},
		#	{"name": "Franco", "text": "E questa è una battuta di un kabukisborrato."}
	#])

func start(lines: Array) -> void:
	_lines = lines
	_index = 0
	dialog_box.show()
	dialog_started.emit()
	_show_line()
	
func _show_line():
	var line = _lines[_index]
	
	name_label.text = line.get("name", "")
	name_label.visible = name_label.text != ""
	
	if line.has("portrait"):
		var p = line["portrait"]
		portrait.texture = load(p) if p is String else p
	portrait.visible = portrait.texture != null
		
	dialog_text.text = line.get("text", "")
	dialog_text.visible_characters = 0
	_stop_blink()
	next_icon.hide()
	
	var total := dialog_text.get_total_character_count()
	if _type_tween:
		_type_tween.kill()
	_type_tween = create_tween()
	_type_tween.tween_property(dialog_text, "visible_characters", total, total / chars_per_sec)
	_type_tween.finished.connect(_on_line_done)

func _on_line_done():
	dialog_text.visible_characters = -1
	next_icon.show()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(next_icon, "modulate:a", 0.2, 0.5)
	_blink_tween.tween_property(next_icon, "modulate:a", 1.0, 0.5)

func _stop_blink():
	if _blink_tween:
		_blink_tween.kill()
	next_icon.modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	if not dialog_box.visible:
		return
	var pressed := event.is_action_pressed("ui_accept")
	
	if event is InputEventMouseButton:
		pressed = pressed or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	
	if _is_typing():
		_type_tween.kill()
		_on_line_done()
	else:
		_index += 1
		if _index >= _lines.size():
			dialog_box.hide()
			dialog_finished.emit()
		else:
			_show_line()


func _is_typing():
	return _type_tween != null and _type_tween.is_running()
