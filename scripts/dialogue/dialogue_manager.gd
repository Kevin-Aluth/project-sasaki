extends CanvasLayer

## Autoload: mostra i dialoghi dell'esplorazione. Riceve una DialogueResource
## (lo stesso formato del dating sim) e i dati di chi parla:
##
##   DialogueManager.start(dialogo, {
##       DialogueLineResource.Speaker.OTHER: {"name": "Franco", "portrait": texture},
##       DialogueLineResource.Speaker.SASAKI: {"name": "Sasaki", "portrait": texture},
##   })

const COLOR_TEXT := Color(0.85, 0.85, 0.85)
const COLOR_TEXT_SELECTED := Color.WHITE
const COLOR_TEXT_DISABLED := Color(0.45, 0.45, 0.45)
const COLOR_BAR := Color(0.0, 0.656, 0.818, 1.0)

@export var chars_per_sec = 40.0
## Testo mostrato al posto di una scelta bloccata: si vede che c'è, non cosa dice
@export var locked_choice_text := "???"
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

var _dialogue: DialogueResource
# Speaker -> {"name": String, "portrait": Texture2D o percorso}
var _speakers: Dictionary = {}
var _index: int = 0
var _type_tween: Tween
var _blink_tween: Tween

func _ready() -> void:
		dialog_text.bbcode_enabled = true
		dialog_text.scroll_active = false
		dialog_box.hide()

func start(dialogue: DialogueResource, speakers: Dictionary) -> void:
	if dialogue == null or dialogue.lines.is_empty():
		push_warning("DialogueManager: dialogo vuoto")
		return
	_dialogue = dialogue
	_speakers = speakers
	_index = 0
	dialog_box.show()
	dialog_started.emit()
	_show_line()

func _current() -> DialogueLineResource:
	return _dialogue.lines[_index]

func _show_line():
	var line := _current()
	choice_container.hide()

	var speaker: Dictionary = _speakers.get(line.speaker, {})
	name_label.text = speaker.get("name", "")
	name_label.visible = name_label.text != ""

	var p = speaker.get("portrait")
	portrait.texture = load(p) if p is String else p
	portrait.visible = portrait.texture != null

	dialog_text.text = line.text
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

	var line := _current()
	# La battuta è stata letta tutta: ora si sblocca il suo flag, se ne ha uno
	_set_flag(line.sets)

	if not line.responses.is_empty() and _show_choices(line.responses):
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
		_goto(_current().next, _index + 1)

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
	b.add_theme_stylebox_override("disabled", empty)

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
	b.add_theme_color_override("font_disabled_color", COLOR_TEXT_DISABLED)
	return b

# Crea e mostra i pulsanti delle scelte. Le scelte senza il flag richiesto
# compaiono disabilitate e con il testo nascosto (locked_choice_text).
# Ritorna false se nessuna scelta è disponibile: il dialogo prosegue normalmente.
func _show_choices(responses: Array[DialogueResponseResource]) -> bool:
	var first: Button
	_clear_choices()
	for response in responses:
		var b := _make_choice_button(response.text)
		if response.requires and not GameState.has_flag(response.requires):
			b.text = locked_choice_text
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
		else:
			b.pressed.connect(_on_choice_selected.bind(response))
			b.mouse_entered.connect(b.grab_focus)
			if first == null:
				first = b
		choice_container.add_child(b)
	if first == null:
		push_error("DialogueManager: nessuna scelta disponibile per \"%s\"" % _current().text)
		_clear_choices()
		return false
	_choosing = true
	next_icon.hide()
	choice_container.show()
	first.grab_focus()
	return true

# Elimina i pulsanti creati in precedenza
func _clear_choices() -> void:
	for c in choice_container.get_children():
		choice_container.remove_child(c)
		c.queue_free()

# Chiamata quando il giocatore effettua una scelta
func _on_choice_selected(response: DialogueResponseResource) -> void:
	_choosing = false
	_clear_choices()
	choice_container.hide()
	_set_flag(response.sets)
	_goto(response.next, _index + 1)

# Sblocca in GameState un flag (StoryFlag o Weakness), se c'è
func _set_flag(flag: StoryFlag) -> void:
	if flag:
		GameState.set_flag(flag)

# Va alla riga indicata da "next" (vuoto = fallback); se il dialogo è finito chiude
func _goto(next: StringName, fallback: int) -> void:
	var i := _dialogue.resolve(next, fallback)
	if i == -1:
		_end()
	else:
		_index = i
		_show_line()

#Chiude il dialogo e avvisa il resto del gioco
func _end() -> void:
	choice_container.hide()
	dialog_box.hide()
	dialog_finished.emit()
