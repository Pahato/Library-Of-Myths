extends CanvasLayer
class_name DialogueBox

signal dialogue_finished

@onready var name_label = $Panel/NameLabel
@onready var text_label = $Panel/TextLabel
@onready var timer = $Timer

var dialogue_list: Array = []
var current_line: int = 0
var is_typing: bool = false

var input_cooldown: float = 0.25
var is_finished: bool = false

var sound_type: AudioStreamPlayer
var sound_advance: AudioStreamPlayer

func _ready():
	# Executa mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Pausa o resto do jogo para que o combate não decorra durante o diálogo
	get_tree().paused = true
	
	timer.timeout.connect(_on_timer_timeout)
	
	# Diálogo padrão se nenhum outro for passado
	if dialogue_list.is_empty():
		dialogue_list = [
			{"name": "char_apolo", "text": "dialogue_apolo_python_1"},
			{"name": "char_python", "text": "dialogue_python_apolo_1"},
			{"name": "char_apolo", "text": "dialogue_apolo_python_2"}
		]
	
	_show_current_line()
	
	sound_type = AudioStreamPlayer.new()
	sound_type.stream = load("res://assets/sounds/click.wav")
	sound_type.volume_db = -18.0
	sound_type.pitch_scale = 1.6
	sound_type.bus = "SFX"
	sound_type.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound_type)
	
	sound_advance = AudioStreamPlayer.new()
	sound_advance.stream = load("res://assets/sounds/click.wav")
	sound_advance.volume_db = -8.0
	sound_advance.pitch_scale = 1.1
	sound_advance.bus = "SFX"
	sound_advance.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sound_advance)

func _process(delta):
	if input_cooldown > 0:
		input_cooldown -= delta

func _input(event):
	if input_cooldown > 0:
		return
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		get_viewport().set_input_as_handled()
		if is_typing:
			# Se estiver a digitar, mostra todo o texto de uma vez
			is_typing = false
			text_label.visible_characters = text_label.text.length()
			timer.stop()
			if sound_advance and not sound_advance.playing:
				sound_advance.play()
		else:
			# Senão, avança para a próxima linha
			current_line += 1
			if current_line < dialogue_list.size():
				if sound_advance and not sound_advance.playing:
					sound_advance.play()
				# Define um pequeno cooldown para cada nova fala
				input_cooldown = 0.15
				_show_current_line()
			else:
				if sound_advance and not sound_advance.playing:
					sound_advance.play()
				_finish_dialogue()

func _show_current_line():
	var line_data = dialogue_list[current_line]
	var raw_name = line_data["name"]
	var raw_text = line_data["text"]
	
	var display_name = GameGlobals.get_text(raw_name)
	var display_text = GameGlobals.get_text(raw_text)
	
	name_label.text = display_name
	text_label.text = display_text
	text_label.visible_characters = 0
	is_typing = true
	# Inicia o timer para digitação imediata
	timer.start(0.03)

func _on_timer_timeout():
	var total = text_label.text.length()
	if total <= 0:
		return
	if text_label.visible_characters < total:
		text_label.visible_characters += 1
		# Play typing sound (avoid playing on spaces to sound more natural, play every 2nd letter)
		if text_label.visible_characters % 2 == 0 and text_label.text[text_label.visible_characters - 1] != " ":
			if sound_type:
				sound_type.play()
	else:
		is_typing = false
		timer.stop()

func _finish_dialogue():
	if is_finished:
		return
	is_finished = true
	# Despausa o jogo
	get_tree().paused = false
	dialogue_finished.emit()
	queue_free()
