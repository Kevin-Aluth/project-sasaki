extends CanvasLayer

const COLOR_TEXT := Color(0.85, 0.85, 0.85)
const COLOR_TEXT_SELECTED := Color.WHITE
const COLOR_BAR := Color(0.0, 0.656, 0.818, 1.0)

@export var chars_per_sec = 40.0
@onready var dialog_manager: CanvasLayer = $"."
@onready var dialog_box: Control = $DialogBox
@onready var name_label: Label = $DialogBox/NameLabel
@onready var portrait: TextureRect = $DialogBox/Portrait
@onready var next_icon: Label = $DialogBox/NextIcon
@onready var dialog_text: RichTextLabel = $DialogBox/MainPanel/TextMargin/DialogText
@onready var choice_container: VBoxContainer = $ChoiceContainer

var _choosing := false

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

func start(lines: Array) -> void:
	_lines = lines
	_index = 0
	dialog_box.show()
	dialog_started.emit()
	_show_line()
	
func _show_line():
	var line = _lines[_index]
	choice_container.hide()
	
	name_label.text = line.get("name", "")
	name_label.visible = name_label.text != ""
	
	if line.has("portrait"):
		var p = line["portrait"]
		portrait.texture = load(p) if p is String else p
	else:
		portrait.texture = null
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
	_stop_blink()
	dialog_text.visible_characters = -1
	
	var line =_lines[_index]
	
	if line.has("choices") and not line["choices"].is_empty():
		_show_choices(line["choices"])
		return
	
	next_icon.show()
	_blink_tween = create_tween().set_loops()
	_blink_tween.tween_property(next_icon, "modulate:a", 0.2, 0.5)
	_blink_tween.tween_property(next_icon, "modulate:a", 1.0, 0.5)

func _stop_blink():
	if _blink_tween:
		_blink_tween.kill()
	next_icon.modulate.a = 1.0

func _unhandled_input(event: InputEvent) -> void:
	# Ignora tutto se il dialogo non è aperto
	if not dialog_box.visible:
		return
	# Durante le scelte l'input lo gestiscono i pulsanti
	if _choosing:
		return
		
	# Conferma: tasto accept, tasto interact o click sinistro
	var pressed := event.is_action_pressed("accept") or event.is_action_pressed("interact")
	
	if event is InputEventMouseButton:
		pressed = pressed or (event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	
	if _is_typing():
		_type_tween.kill()
		_on_line_done()
	else:
		_goto(_lines[_index].get("next", _index + 1))

# True se l'animazione di scrittura è ancora in corso
func _is_typing():
	return _type_tween != null and _type_tween.is_running()

# Crea un pulsante già stilizzato
func _make_choice_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_RIGHT
	b.focus_mode = Control.FOCUS_ALL
	b.size_flags_horizontal = Control.SIZE_FILL
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.add_theme_font_size_override("font_size", 8)
	
	# Stile normale
	var empty := StyleBoxEmpty.new()
	empty.content_margin_left = 4
	empty.content_margin_right = 4
	empty.content_margin_top = 2
	empty.content_margin_bottom = 2
	b.add_theme_stylebox_override("normal", empty)
	b.add_theme_stylebox_override("pressed", empty)
	
	#Stile selezionato
	var bar := StyleBoxFlat.new()
	bar.bg_color = COLOR_BAR
	bar.content_margin_left = 4
	bar.content_margin_right = 4
	bar.content_margin_top = 2
	bar.content_margin_bottom = 2
	b.add_theme_stylebox_override("hover", bar)
	b.add_theme_stylebox_override("focus", bar)
	
	#Colori del tasto nei vari stati
	b.add_theme_color_override("font_color", COLOR_TEXT)
	b.add_theme_color_override("font_hover_color", COLOR_TEXT_SELECTED)
	b.add_theme_color_override("font_focus_color", COLOR_TEXT_SELECTED)
	b.add_theme_color_override("font_pressed_color", COLOR_TEXT_SELECTED)
	return b
	
# Crea e mostra i pulsanti delle scelte
func _show_choices(choices: Array) -> void:
		_choosing = true
		next_icon.hide()
		_clear_choices()
		for c in choices:
			var b := _make_choice_button(c.get("text", ""))
			b.pressed.connect(_on_choice_selected.bind(c))
			b.mouse_entered.connect(b.grab_focus)
			choice_container.add_child(b)
		choice_container.show()
		if choice_container.get_child_count() > 0:
			choice_container.get_child(0).grab_focus()

# Elimina i pulsanti creati in precedenza
func _clear_choices() -> void:
	for c in choice_container.get_children():
		choice_container.remove_child(c)
		c.queue_free()

# Chiamata quando il giocatore effettua una scelta
func _on_choice_selected(choice: Dictionary) -> void:
	_choosing = false
	_clear_choices()
	choice_container.hide()
	_goto(choice.get("next", _index + 1))

# Va alla riga i; se è fuori dai limiti
func _goto(i: int) -> void:
	if i < 0 or i >= _lines.size():
		_end()
	else:
		_index = i
		_show_line()

#Chiude il dialogo e avvisa il resto del gioco
func _end() -> void:
	choice_container.hide()
	dialog_box.hide()
	dialog_finished.emit()
