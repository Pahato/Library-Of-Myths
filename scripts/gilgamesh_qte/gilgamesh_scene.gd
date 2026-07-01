extends Control

## Controlador principal da Batalha do Livro V: Gilgamesh vs O Touro dos Céus.
## Implementa QTEs de teclado e cliques de precisão, culminando na ativação do Portão da Babilónia.

# Preloads de cenas e recursos
var player_scene: PackedScene = preload("res://scenes/apolo_python/player.tscn")
var dialogue_box_scene: PackedScene = preload("res://scenes/dialogue_box.tscn")
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")

# Caminhos de texturas do boss e itens
var boss_idle_tex := preload("res://assets/sprites/Trocas/gilgaBossIdle.png")
var boss_atk_tex := preload("res://assets/sprites/Trocas/gilgaBossAtk.png")
var boss_defeat_tex := preload("res://assets/sprites/Trocas/gilgaBossDefeat.png")
var portal_tex := preload("res://assets/sprites/Trocas/portalDourado.png")

# Texturas de armas douradas
var weapon_textures := [
	preload("res://assets/sprites/Trocas/espadaDourada.png"),
	preload("res://assets/sprites/Trocas/adagaDourada.png"),
	preload("res://assets/sprites/Trocas/lancaDourada.png"),
	preload("res://assets/sprites/Trocas/machadoDourado.png")
]

# Estado de jogo
var game_active: bool = false
var in_attack_phase: bool = false
var intro_done: bool = false

# Estatísticas de vida e fúria
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var boss_hp: float = 300.0
var boss_max_hp: float = 300.0
var royal_fury: float = 0.0
var royal_fury_max: float = 100.0
var boss_phase: int = 1

# Referências a nós na UI (Criados dinamicamente no script do tscn)
var player_instance: Node2D = null
var boss_sprite: Sprite2D = null
var bg_rect: TextureRect = null
var portals_node: Node2D = null

# Nós do CanvasLayer HUD
var boss_hp_bar: ProgressBar = null
var boss_name_label: Label = null
var player_hp_bar: ProgressBar = null
var fury_bar: ProgressBar = null
var fury_title_label: Label = null
var qte_container: Control = null
var precision_container: Control = null
var feedback_label: Label = null
var screen_flash: ColorRect = null
var game_over_panel: Panel = null
var pause_menu_instance: Node = null

# Timers de QTE
var qte_timer_active: float = 0.0
var qte_timer_max: float = 2.0
var current_qte_key: int = -1
var qte_bar: ProgressBar = null
var qte_key_label: Label = null

# Temporizador da Fase de Ataque (Portão da Babilónia)
var attack_phase_timer: float = 0.0
var active_portals: Array = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Instanciar e desenhar os componentes visuais
	_setup_visual_hierarchy()
	
	# Inicia música tema do Gilgamesh
	if GameGlobals:
		GameGlobals.play_music("res://assets/music/battle_theme.mp3", -10.0) # Se não existir, toca o tema geral
		
	# Trava inputs e inicia diálogos da introdução
	get_tree().paused = true
	_play_intro()

func _process(delta: float) -> void:
	if not game_active:
		return
		
	if in_attack_phase:
		_process_attack_phase(delta)
	else:
		_process_defense_phase(delta)

# ---------------------------------------------------------------------------
# Montagem Programática da UI & Sprite Hierachy
# ---------------------------------------------------------------------------
func _setup_visual_hierarchy():
	# 1. Fundo do ecrã
	bg_rect = TextureRect.new()
	bg_rect.name = "Background"
	bg_rect.texture = preload("res://assets/sprites/Trocas/batalhaUruk_bg.png")
	bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.size = Vector2(1152, 648)
	add_child(bg_rect)
	
	# 2. Container dos Portais (Fica atrás de Gilgamesh)
	portals_node = Node2D.new()
	portals_node.name = "PortalsContainer"
	add_child(portals_node)
	
	# 3. Instancia Gilgamesh (Pato Apolo com modulação dourada)
	if player_scene:
		player_instance = player_scene.instantiate()
		player_instance.name = "GilgameshPlayer"
		player_instance.position = Vector2(250, 530)
		player_instance.scale = Vector2(3.8, 3.8)
		player_instance.set_physics_process(false)
		player_instance.set_process(false)
		player_instance.set_process_input(false)
		
		# Modula o pato para dourado brilhante
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.modulate = Color(1.0, 0.85, 0.15, 1.0)
			anim_sprite.play("Idle")
			
		add_child(player_instance)
		
	# 4. Boss (O Touro dos Céus)
	boss_sprite = Sprite2D.new()
	boss_sprite.name = "BullOfHeaven"
	boss_sprite.texture = boss_idle_tex
	boss_sprite.position = Vector2(900, 465)
	boss_sprite.scale = Vector2(0.35, 0.35)
	add_child(boss_sprite)
	
	# 5. CanvasLayer HUD
	var hud_layer = CanvasLayer.new()
	hud_layer.name = "HUD"
	add_child(hud_layer)
	
	# Flash de ecrã (dano/portas)
	screen_flash = ColorRect.new()
	screen_flash.name = "ScreenFlash"
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(screen_flash)
	
	# Barra de HP do Boss (Topo do Ecrã)
	boss_hp_bar = ProgressBar.new()
	boss_hp_bar.name = "BossHPBar"
	boss_hp_bar.size = Vector2(600, 26)
	boss_hp_bar.position = Vector2(276, 25)
	boss_hp_bar.min_value = 0
	boss_hp_bar.max_value = boss_max_hp
	boss_hp_bar.value = boss_hp
	boss_hp_bar.show_percentage = false
	
	var sb_boss_bg = StyleBoxFlat.new()
	sb_boss_bg.bg_color = Color(0.12, 0.02, 0.02, 0.75)
	sb_boss_bg.border_width_left = 2
	sb_boss_bg.border_width_top = 2
	sb_boss_bg.border_width_right = 2
	sb_boss_bg.border_width_bottom = 2
	sb_boss_bg.border_color = Color(0.3, 0.05, 0.05, 1.0)
	
	var sb_boss_fill = StyleBoxFlat.new()
	sb_boss_fill.bg_color = Color(0.85, 0.1, 0.15, 1.0) # Vermelho rubi
	sb_boss_fill.border_width_left = 1
	sb_boss_fill.border_width_top = 1
	sb_boss_fill.border_width_right = 1
	sb_boss_fill.border_width_bottom = 1
	sb_boss_fill.border_color = Color(1.0, 0.3, 0.3, 0.6)
	
	boss_hp_bar.add_theme_stylebox_override("background", sb_boss_bg)
	boss_hp_bar.add_theme_stylebox_override("fill", sb_boss_fill)
	hud_layer.add_child(boss_hp_bar)
	
	# Nome do Boss
	boss_name_label = Label.new()
	boss_name_label.name = "BossNameLabel"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.size = Vector2(600, 20)
	boss_name_label.position = Vector2(276, 2)
	boss_name_label.add_theme_font_override("font", _load_font(true))
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 1.0))
	hud_layer.add_child(boss_name_label)
	
	# Barra de HP de Gilgamesh (Canto inferior esquerdo)
	player_hp_bar = ProgressBar.new()
	player_hp_bar.name = "PlayerHPBar"
	player_hp_bar.size = Vector2(240, 20)
	player_hp_bar.position = Vector2(40, 560)
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_bar.show_percentage = false
	
	var sb_p_bg = StyleBoxFlat.new()
	sb_p_bg.bg_color = Color(0.05, 0.05, 0.05, 0.8)
	
	var sb_p_fill = StyleBoxFlat.new()
	sb_p_fill.bg_color = Color(0.15, 0.75, 0.15, 1.0) # Verde de vida
	
	player_hp_bar.add_theme_stylebox_override("background", sb_p_bg)
	player_hp_bar.add_theme_stylebox_override("fill", sb_p_fill)
	hud_layer.add_child(player_hp_bar)
	
	var p_lbl = Label.new()
	p_lbl.text = "HP"
	p_lbl.position = Vector2(40, 538)
	p_lbl.add_theme_font_override("font", _load_font(true))
	p_lbl.add_theme_font_size_override("font_size", 12)
	p_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 0.9, 1.0))
	hud_layer.add_child(p_lbl)
	
	# Barra de Fúria Real (Base do ecrã)
	fury_bar = ProgressBar.new()
	fury_bar.name = "FuryBar"
	fury_bar.size = Vector2(240, 20)
	fury_bar.position = Vector2(40, 610)
	fury_bar.max_value = royal_fury_max
	fury_bar.value = royal_fury
	fury_bar.show_percentage = false
	
	var sb_f_fill = StyleBoxFlat.new()
	sb_f_fill.bg_color = Color(1.0, 0.75, 0.1, 1.0) # Ouro cintilante
	sb_f_fill.border_width_left = 1
	sb_f_fill.border_width_top = 1
	sb_f_fill.border_width_right = 1
	sb_f_fill.border_width_bottom = 1
	sb_f_fill.border_color = Color(1.0, 1.0, 0.6, 0.8)
	
	fury_bar.add_theme_stylebox_override("background", sb_p_bg)
	fury_bar.add_theme_stylebox_override("fill", sb_f_fill)
	hud_layer.add_child(fury_bar)
	
	fury_title_label = Label.new()
	fury_title_label.name = "FuryTitleLabel"
	fury_title_label.position = Vector2(40, 588)
	fury_title_label.add_theme_font_override("font", _load_font(true))
	fury_title_label.add_theme_font_size_override("font_size", 12)
	fury_title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))
	hud_layer.add_child(fury_title_label)
	
	# Container do QTE de Teclado
	qte_container = Control.new()
	qte_container.name = "QTEContainer"
	qte_container.size = Vector2(300, 160)
	qte_container.set_anchors_preset(Control.PRESET_CENTER)
	qte_container.grow_horizontal = 2
	qte_container.grow_vertical = 2
	qte_container.position = -qte_container.size / 2.0
	qte_container.position.y -= 40.0
	qte_container.visible = false
	hud_layer.add_child(qte_container)
	
	var qte_panel = Panel.new()
	qte_panel.size = qte_container.size
	var sb_qte = StyleBoxFlat.new()
	sb_qte.bg_color = Color(0.08, 0.07, 0.05, 0.9)
	sb_qte.border_width_left = 3
	sb_qte.border_width_top = 3
	sb_qte.border_width_right = 3
	sb_qte.border_width_bottom = 3
	sb_qte.border_color = Color(1.0, 0.8, 0.2, 1.0)
	sb_qte.corner_radius_top_left = 10
	sb_qte.corner_radius_top_right = 10
	sb_qte.corner_radius_bottom_left = 10
	sb_qte.corner_radius_bottom_right = 10
	qte_panel.add_theme_stylebox_override("panel", sb_qte)
	qte_container.add_child(qte_panel)
	
	qte_key_label = Label.new()
	qte_key_label.name = "QTEKeyLabel"
	qte_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qte_key_label.size = Vector2(300, 60)
	qte_key_label.position = Vector2(0, 30)
	qte_key_label.add_theme_font_override("font", _load_font(true))
	qte_key_label.add_theme_font_size_override("font_size", 34)
	qte_key_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	qte_container.add_child(qte_key_label)
	
	qte_bar = ProgressBar.new()
	qte_bar.name = "QTEProgressBar"
	qte_bar.size = Vector2(220, 10)
	qte_bar.position = Vector2(40, 110)
	qte_bar.max_value = 1.0
	qte_bar.value = 1.0
	qte_bar.show_percentage = false
	var sb_qbar_fill = StyleBoxFlat.new()
	sb_qbar_fill.bg_color = Color(1.0, 0.85, 0.2, 1.0)
	qte_bar.add_theme_stylebox_override("fill", sb_qbar_fill)
	qte_container.add_child(qte_bar)
	
	# Container de Círculos de Precisão (Clicker estilo Osu!)
	precision_container = Control.new()
	precision_container.name = "PrecisionContainer"
	precision_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	precision_container.mouse_filter = Control.MOUSE_FILTER_PASS
	hud_layer.add_child(precision_container)
	
	# Feedback Label (PERFEITO!, BOM!, FALHA!)
	feedback_label = Label.new()
	feedback_label.name = "FeedbackLabel"
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.size = Vector2(400, 40)
	feedback_label.set_anchors_preset(Control.PRESET_CENTER)
	feedback_label.grow_horizontal = 2
	feedback_label.grow_vertical = 2
	feedback_label.position = -feedback_label.size / 2.0
	feedback_label.position.y += 80.0
	feedback_label.modulate.a = 0.0
	feedback_label.add_theme_font_override("font", _load_font(true))
	feedback_label.add_theme_font_size_override("font_size", 24)
	feedback_label.add_theme_constant_override("outline_size", 4)
	feedback_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hud_layer.add_child(feedback_label)
	
	_update_hud_text()

func _update_hud_text():
	if boss_name_label:
		boss_name_label.text = GameGlobals.get_text("char_touro").to_upper()
	if fury_title_label:
		fury_title_label.text = GameGlobals.get_text("fury_title") if GameGlobals.translations["PT"].has("fury_title") else "FÚRIA REAL"
		if in_attack_phase:
			fury_title_label.text = "PORTÃO DA BABILÓNIA!" if GameGlobals.current_language == GameGlobals.Language.PT else "GATE OF BABYLON!"
			fury_title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
		else:
			fury_title_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2, 1.0))

func _load_font(bold: bool) -> Font:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	return load(path) as Font

func _play_lightning_effect():
	_play_sfx("explosion", randf_range(1.2, 1.5), -2.0)
	if screen_flash:
		screen_flash.color = Color(1.0, 1.0, 1.0, 0.45)
		var flash_tw = create_tween()
		flash_tw.tween_property(screen_flash, "color:a", 0.0, 0.25)
	_shake_camera(6.0)

# ---------------------------------------------------------------------------
# Sequências de Diálogo e Cutscene
# ---------------------------------------------------------------------------
func _play_intro():
	var box = dialogue_box_scene.instantiate()
	box.dialogue_list = [
		{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_1"},
		{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_2"},
		{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_3"},
		{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_4"}
	]
	box.dialogue_finished.connect(func():
		get_tree().paused = false
		game_active = true
		intro_done = true
		_start_new_qte()
	)
	add_child(box)

func _trigger_victory() -> void:
	game_active = false
	qte_container.visible = false
	# Limpar precision targets
	for child in precision_container.get_children():
		child.queue_free()
		
	# Mudar sprite do boss para derrotado/morto
	if boss_sprite:
		boss_sprite.texture = boss_defeat_tex
		var tw = create_tween()
		tw.tween_property(boss_sprite, "modulate", Color(0.4, 0.4, 0.4, 1.0), 1.0)
		tw.tween_property(boss_sprite, "scale", Vector2.ZERO, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		
	# Desativa processamento e toca som glorioso
	_play_sfx("power_up", 0.8, 6.0)
	
	# Instancia diálogo final
	var tw_wait = create_tween()
	tw_wait.tween_interval(1.8)
	tw_wait.tween_callback(func():
		var box = dialogue_box_scene.instantiate()
		box.dialogue_list = [
			{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_victory_1"},
			{"name": "char_narrator", "text": "dialogue_narrator_gilgamesh_victory_2"}
		]
		box.dialogue_finished.connect(func():
			# Volta ao menu principal
			var transition = get_node_or_null("/root/SceneTransition")
			if transition:
				transition.fade_to("res://scenes/main_menu.tscn")
			else:
				get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		)
		add_child(box)
	)

# ---------------------------------------------------------------------------
# Lógica da Fase de Defesa (QTE e Precision Clicker)
# ---------------------------------------------------------------------------
func _process_defense_phase(delta: float):
	if qte_timer_active > 0.0:
		qte_timer_active -= delta
		if qte_bar:
			qte_bar.value = qte_timer_active / qte_timer_max
			
		if qte_timer_active <= 0.0:
			_on_qte_failed("TEMPO ESGOTADO!" if GameGlobals.current_language == GameGlobals.Language.PT else "TIMEOUT!")

func _start_new_qte():
	if not game_active or in_attack_phase:
		return
		
	# Limpar qualquer input ou alvo anterior
	qte_container.visible = false
	current_qte_key = -1
	for child in precision_container.get_children():
		child.queue_free()
		
	# Configurar velocidade/dificuldade baseado nas fases do Boss
	# boss_phase 1: 100% - 66% hp
	# boss_phase 2: 66% - 33% hp
	# boss_phase 3: 33% - 0% hp
	
	var rand_val = randf()
	
	# Fase 1: Apenas QTE de Teclado
	# Fase 2: QTE e Clickers de Precisão misturados
	# Fase 3: Clickers de precisão ultra rápidos e QTEs
	if boss_phase == 1:
		_spawn_keyboard_qte()
	elif boss_phase == 2:
		if rand_val < 0.6:
			_spawn_keyboard_qte()
		else:
			_spawn_precision_click()
	else:
		if rand_val < 0.35:
			_spawn_keyboard_qte()
		else:
			_spawn_precision_click()

# --- QTE de Teclado ---
func _spawn_keyboard_qte():
	var keys = [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SPACE]
	current_qte_key = keys[randi() % keys.size()]
	
	var key_text = ""
	match current_qte_key:
		KEY_W: key_text = "W"
		KEY_A: key_text = "A"
		KEY_S: key_text = "S"
		KEY_D: key_text = "D"
		KEY_SPACE: key_text = "ESPAÇO" if GameGlobals.current_language == GameGlobals.Language.PT else "SPACE"
		
	qte_key_label.text = "PRESSIONA [" + key_text + "]" if GameGlobals.current_language == GameGlobals.Language.PT else "PRESS [" + key_text + "]"
	
	# Ajustar tempo do QTE conforme fase e dificuldade
	var base_time = 2.0
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY: base_time = 2.4
		GameGlobals.Difficulty.HARD: base_time = 1.4
		
	if boss_phase == 2: base_time *= 0.85
	elif boss_phase == 3: base_time *= 0.70
	
	qte_timer_max = base_time
	qte_timer_active = base_time
	qte_container.visible = true
	
	# Faz boss piscar indicando que vai atacar
	if boss_sprite:
		boss_sprite.texture = boss_atk_tex
		var tw = create_tween()
		tw.tween_property(boss_sprite, "modulate", Color(1.5, 0.4, 0.4, 1.0), 0.15)
		tw.tween_property(boss_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_delay(base_time - 0.2)
		
	# Efeito de relâmpago ao iniciar o ataque
	_play_lightning_effect()

func _input(event: InputEvent) -> void:
	if not game_active or in_attack_phase:
		return
		
	# ESC Menu de Pausa
	if event.is_action_pressed("ui_cancel"):
		_toggle_pause()
		return
		
	if current_qte_key != -1 and event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == current_qte_key:
			_on_qte_success()
		else:
			_on_qte_failed("TECLA INCORRETA!" if GameGlobals.current_language == GameGlobals.Language.PT else "WRONG KEY!")

# --- QTE de Precisão (Estilo Osu!) ---
func _spawn_precision_click():
	# Criar o alvo circular programaticamente no precision_container
	var target = Control.new()
	target.name = "PrecisionTarget"
	
	# Posição aleatória na tela (evitando cobrir o jogador e barras da UI)
	var random_pos = Vector2(
		randf_range(300.0, 800.0),
		randf_range(160.0, 480.0)
	)
	target.position = random_pos
	precision_container.add_child(target)
	
	# Desenhar o círculo interno (Alvo estático)
	var circle = TextureRect.new()
	circle.name = "Circle"
	circle.texture = preload("res://icon.svg") # Usar icon como base modificado para círculo
	circle.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	circle.stretch_mode = TextureRect.STRETCH_SCALE
	circle.size = Vector2(80, 80)
	circle.position = -circle.size / 2.0
	circle.modulate = Color(1.0, 0.8, 0.2, 0.9) # Dourado
	
	# Usar um shader ou apenas modulação redonda (como criamos dinamicamente)
	var sb_circle = StyleBoxFlat.new()
	sb_circle.bg_color = Color(1.0, 0.85, 0.2, 0.35)
	sb_circle.border_width_left = 3
	sb_circle.border_width_top = 3
	sb_circle.border_width_right = 3
	sb_circle.border_width_bottom = 3
	sb_circle.border_color = Color(1.0, 0.85, 0.2, 1.0)
	sb_circle.corner_radius_top_left = 40
	sb_circle.corner_radius_top_right = 40
	sb_circle.corner_radius_bottom_left = 40
	sb_circle.corner_radius_bottom_right = 40
	
	var panel = Panel.new()
	panel.size = circle.size
	panel.position = circle.position
	panel.add_theme_stylebox_override("panel", sb_circle)
	target.add_child(panel)
	
	# Desenhar o anel exterior que encolhe (Approach Ring)
	var sb_ring = StyleBoxFlat.new()
	sb_ring.bg_color = Color(0, 0, 0, 0)
	sb_ring.border_width_left = 2
	sb_ring.border_width_top = 2
	sb_ring.border_width_right = 2
	sb_ring.border_width_bottom = 2
	sb_ring.border_color = Color(1.0, 1.0, 0.6, 0.85)
	sb_ring.corner_radius_top_left = 120
	sb_ring.corner_radius_top_right = 120
	sb_ring.corner_radius_bottom_left = 120
	sb_ring.corner_radius_bottom_right = 120
	
	var ring = Panel.new()
	ring.name = "ApproachRing"
	ring.size = Vector2(240, 240)
	ring.position = -ring.size / 2.0
	ring.add_theme_stylebox_override("panel", sb_ring)
	target.add_child(ring)
	
	# Configurar botão transparente de clique sobre o painel
	var btn = TextureButton.new()
	btn.name = "ClickButton"
	btn.size = panel.size
	btn.position = panel.position
	target.add_child(btn)
	
	# Animar o encolhimento do anel exterior
	var click_time = 1.3
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY: click_time = 1.6
		GameGlobals.Difficulty.HARD: click_time = 0.95
		
	if boss_phase == 3: click_time *= 0.8
	
	var shrink_tween = create_tween().bind_node(target)
	shrink_tween.tween_property(ring, "size", panel.size, click_time).set_trans(Tween.TRANS_SINE)
	shrink_tween.set_parallel(true)
	shrink_tween.tween_property(ring, "position", panel.position, click_time).set_trans(Tween.TRANS_SINE)
	
	var has_clicked = { "val": false }
	btn.pressed.connect(func():
		if has_clicked["val"] or in_attack_phase: return
		has_clicked["val"] = true
		shrink_tween.kill()
		
		# Calcula a precisão com base no tamanho do anel exterior
		var ring_current_size = ring.size.x
		var diff = abs(ring_current_size - panel.size.x)
		
		if diff < 15.0:
			_on_qte_success(1.2) # Perfeito!
		elif diff < 45.0:
			_on_qte_success(0.7) # Bom!
		else:
			_on_qte_failed("PREMEDITADO/ATRASADO!" if GameGlobals.current_language == GameGlobals.Language.PT else "TOO EARLY/LATE!")
		if is_instance_valid(target):
			target.queue_free()
	)
	
	# Se expirar sem clique, falha
	shrink_tween.chain().tween_callback(func():
		if not has_clicked["val"]:
			has_clicked["val"] = true
			_on_qte_failed("TEMPO ESGOTADO!" if GameGlobals.current_language == GameGlobals.Language.PT else "TIMEOUT!")
			if is_instance_valid(target):
				target.queue_free()
	)
	
	# Toca som sutil de aviso de clique (tap)
	_play_sfx("tap", 1.0, -10.0)
	
	# Efeito de relâmpago ao iniciar o ataque de precisão
	_play_lightning_effect()

# --- Sucesso e Falha de QTE ---
func _on_qte_success(score_mult: float = 1.0):
	_show_feedback("PERFEITO!" if score_mult >= 1.0 else "BOM!", Color(1.0, 0.9, 0.3, 1.0))
	_play_sfx("tap", 1.5, -4.0)
	
	# Pato Gilgamesh dá um pulo de vitória rápido
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("Jump")
			var reset_tw = create_tween()
			reset_tw.tween_interval(0.35)
			reset_tw.tween_callback(func(): if not in_attack_phase: anim_sprite.play("Idle"))
			
	# Carrega fúria
	var fury_gain = 20.0 * score_mult
	royal_fury = min(royal_fury + fury_gain, royal_fury_max)
	if fury_bar:
		fury_bar.value = royal_fury
		
	# Ativa o Portão da Babilónia se fúria atingir 100%
	if royal_fury >= royal_fury_max:
		var wait_tw = create_tween()
		wait_tw.tween_interval(0.3)
		wait_tw.tween_callback(_enter_attack_phase)
	else:
		# Avança para o próximo
		var wait_tw = create_tween()
		wait_tw.tween_interval(0.4)
		wait_tw.tween_callback(_start_new_qte)

func _on_qte_failed(reason_text: String):
	_show_feedback(reason_text, Color(0.95, 0.2, 0.2, 1.0))
	_play_sfx("hurt", 1.0, 2.0)
	
	# Flash de ecrã vermelho
	if screen_flash:
		screen_flash.color = Color(1.0, 0.1, 0.1, 0.35)
		var flash_tw = create_tween()
		flash_tw.tween_property(screen_flash, "color:a", 0.0, 0.3)
		
	# Treme a câmara
	_shake_camera(8.0)
	
	# Reduz vida
	var damage = 20.0
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY: damage = 14.0
		GameGlobals.Difficulty.HARD: damage = 28.0
		
	player_hp = max(player_hp - damage, 0.0)
	if player_hp_bar:
		player_hp_bar.value = player_hp
		
	if player_hp <= 0.0:
		_trigger_game_over()
	else:
		# Próximo QTE
		var wait_tw = create_tween()
		wait_tw.tween_interval(0.6)
		wait_tw.tween_callback(_start_new_qte)

func _show_feedback(text: String, color: Color):
	if feedback_label:
		feedback_label.text = text
		feedback_label.add_theme_color_override("font_color", color)
		feedback_label.modulate.a = 1.0
		feedback_label.position.y = (size.y / 2.0) + 80.0
		
		# Animação de subida e fade out
		var tw = create_tween().set_parallel(true)
		tw.tween_property(feedback_label, "modulate:a", 0.0, 0.6).set_delay(0.2)
		tw.tween_property(feedback_label, "position:y", feedback_label.position.y - 30.0, 0.6).set_trans(Tween.TRANS_SINE)

func _shake_camera(amount: float):
	var cam = player_instance.get_node_or_null("Camera2D") if player_instance else null
	if not cam:
		# Procura uma câmara geral na cena se o pato não tiver
		cam = get_node_or_null("Camera2D")
		
	if cam:
		var start_offset = cam.offset
		var shake_tw = create_tween()
		for i in range(6):
			var offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
			shake_tw.tween_property(cam, "offset", offset, 0.03)
		shake_tw.tween_property(cam, "offset", start_offset, 0.03)

# ---------------------------------------------------------------------------
# Lógica da Fase de Ataque (Portão da Babilónia)
# ---------------------------------------------------------------------------
func _enter_attack_phase():
	in_attack_phase = true
	qte_container.visible = false
	current_qte_key = -1
	for child in precision_container.get_children():
		child.queue_free()
		
	_update_hud_text()
	_play_sfx("power_up", 1.1, 4.0)
	
	# Flash dourado de ativação
	if screen_flash:
		screen_flash.color = Color(1.0, 0.85, 0.2, 0.45)
		var flash_tw = create_tween()
		flash_tw.tween_property(screen_flash, "color:a", 0.0, 0.6)
		
	# Treme a tela levemente
	_shake_camera(4.0)
	
	# Abrir os portais dourados atrás de Gilgamesh (Pato)
	var portal_positions = [
		Vector2(100, 150), Vector2(100, 270), Vector2(100, 390), Vector2(100, 510),
		Vector2(200, 120), Vector2(200, 240), Vector2(200, 360), Vector2(200, 480),
		Vector2(300, 180), Vector2(300, 300), Vector2(300, 420), Vector2(300, 540)
	]
	
	active_portals.clear()
	for i in range(portal_positions.size()):
		var portal = Sprite2D.new()
		portal.texture = portal_tex
		portal.position = portal_positions[i]
		portal.scale = Vector2.ZERO
		portal.modulate.a = 0.85
		portals_node.add_child(portal)
		active_portals.append(portal)
		
		# Animação de abertura do portal (escala cresce e brilha)
		var open_tw = create_tween()
		open_tw.tween_interval(i * 0.05) # Escalonamento na abertura
		open_tw.tween_property(portal, "scale", Vector2(0.06, 0.06), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	# Pato Gilgamesh faz pose de ataque (Animação de Corrida ou Salto estático)
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("Run")
			
	# Inicia o tempo limite da fase de ataque (5 segundos)
	attack_phase_timer = 5.0
	_show_feedback("SPAM DE CLIQUES!" if GameGlobals.current_language == GameGlobals.Language.PT else "SPAM CLICKS!", Color(1.0, 0.82, 0.2, 1.0))

func _process_attack_phase(delta: float):
	if attack_phase_timer > 0.0:
		attack_phase_timer -= delta
		
		# Barra de fúria diminui visualmente indicando o tempo que resta
		if fury_bar:
			fury_bar.value = (attack_phase_timer / 5.0) * royal_fury_max
			
		if attack_phase_timer <= 0.0:
			_exit_attack_phase()

func _unhandled_input(event: InputEvent) -> void:
	# Só processa cliques de spam na fase de ataque
	if not game_active or not in_attack_phase:
		return
		
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		_fire_golden_weapon()

func _fire_golden_weapon():
	if active_portals.is_empty():
		return
		
	# Escolhe um portal aleatório para disparar
	var portal = active_portals[randi() % active_portals.size()]
	
	# Cria a arma dourada programaticamente
	var weapon = Sprite2D.new()
	weapon.texture = weapon_textures[randi() % weapon_textures.size()]
	weapon.position = portal.position
	weapon.scale = Vector2(0.08, 0.08)
	
	# Roda o sprite da arma para apontar na direção do Boss
	var target_pos = Vector2(880 + randf_range(-40.0, 40.0), 380 + randf_range(-80.0, 80.0))
	weapon.rotation = (target_pos - weapon.position).angle()
	add_child(weapon)
	
	# Animação de disparo rápido em direção ao Boss
	var shoot_tw = create_tween()
	shoot_tw.tween_property(weapon, "position", target_pos, 0.45).set_trans(Tween.TRANS_SINE)
	shoot_tw.tween_callback(func():
		# Ao colidir com o boss
		_on_weapon_impact(weapon, target_pos)
	)
	
	# Brilha o portal momentaneamente
	var portal_tw = create_tween()
	portal_tw.tween_property(portal, "scale", Vector2(0.08, 0.08), 0.08)
	portal_tw.tween_property(portal, "scale", Vector2(0.06, 0.06), 0.08)
	
	# Som de disparo
	_play_sfx("shoot", randf_range(1.0, 1.4), -8.0)

func _on_weapon_impact(weapon: Sprite2D, impact_pos: Vector2):
	weapon.queue_free()
	
	# Som de clink e flash
	_play_sfx("clink", randf_range(0.9, 1.2), -5.0)
	_shake_camera(2.0)
	
	# Dano no boss
	var damage = 3.5
	match GameGlobals.current_difficulty:
		GameGlobals.Difficulty.EASY: damage = 5.0
		GameGlobals.Difficulty.HARD: damage = 2.5
		
	boss_hp = max(boss_hp - damage, 0.0)
	if boss_hp_bar:
		boss_hp_bar.value = boss_hp
		
	# Brilha o boss em vermelho momentaneamente
	if boss_sprite:
		var boss_tw = create_tween()
		boss_sprite.modulate = Color(1.8, 0.5, 0.5, 1.0)
		boss_tw.tween_property(boss_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)
		
	# Atualiza a fase do boss com base no HP restante
	var hp_pct = boss_hp / boss_max_hp
	if hp_pct <= 0.33:
		boss_phase = 3
	elif hp_pct <= 0.66:
		boss_phase = 2
		
	if boss_hp <= 0.0:
		_trigger_victory()

func _exit_attack_phase():
	in_attack_phase = false
	royal_fury = 0.0
	if fury_bar:
		fury_bar.value = 0.0
		
	_update_hud_text()
	_show_feedback("PREPARA-TE PARA DEFENDER!" if GameGlobals.current_language == GameGlobals.Language.PT else "PREPARE TO DEFEND!", Color(0.9, 0.9, 0.9, 1.0))
	
	# Fecha os portais com animação
	for portal in active_portals:
		var close_tw = create_tween()
		close_tw.tween_property(portal, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		close_tw.tween_callback(portal.queue_free)
		
	active_portals.clear()
	
	# Pato Gilgamesh regressa à animação Idle
	if player_instance:
		var anim_sprite = player_instance.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			anim_sprite.play("Idle")
			
	# Aguarda e inicia nova defesa
	var wait_tw = create_tween()
	wait_tw.tween_interval(0.8)
	wait_tw.tween_callback(_start_new_qte)

# ---------------------------------------------------------------------------
# Menu de Pausa & Defeat / Game Over
# ---------------------------------------------------------------------------
func _toggle_pause():
	if is_instance_valid(pause_menu_instance):
		return # Já está aberto
	get_tree().paused = true
	pause_menu_instance = pause_menu_scene.instantiate()
	pause_menu_instance.tree_exited.connect(func(): pause_menu_instance = null)
	add_child(pause_menu_instance)

func _trigger_game_over():
	game_active = false
	qte_container.visible = false
	for child in precision_container.get_children():
		child.queue_free()
		
	# Parar música
	if GameGlobals:
		GameGlobals.stop_music()
		
	# Toca som de derrota
	_play_sfx("explosion", 0.7, 4.0)
	
	# Escurecer o ecrã e mostrar painel de Game Over programático
	var overlay = ColorRect.new()
	overlay.name = "GameOverOverlay"
	overlay.color = Color(0.08, 0.02, 0.02, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	game_over_panel = Panel.new()
	game_over_panel.name = "GameOverPanel"
	game_over_panel.size = Vector2(380, 240)
	game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	game_over_panel.grow_horizontal = 2
	game_over_panel.grow_vertical = 2
	game_over_panel.position = -game_over_panel.size / 2.0
	
	var sb_go = StyleBoxFlat.new()
	sb_go.bg_color = Color(0.12, 0.03, 0.03, 0.95)
	sb_go.border_width_left = 3
	sb_go.border_width_top = 3
	sb_go.border_width_right = 3
	sb_go.border_width_bottom = 3
	sb_go.border_color = Color(0.95, 0.15, 0.15, 1.0)
	sb_go.corner_radius_top_left = 12
	sb_go.corner_radius_top_right = 12
	sb_go.corner_radius_bottom_left = 12
	sb_go.corner_radius_bottom_right = 12
	game_over_panel.add_theme_stylebox_override("panel", sb_go)
	overlay.add_child(game_over_panel)
	
	var go_lbl = Label.new()
	go_lbl.text = GameGlobals.get_text("gameover_title")
	go_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_lbl.size = Vector2(380, 40)
	go_lbl.position = Vector2(0, 30)
	go_lbl.add_theme_font_override("font", _load_font(true))
	go_lbl.add_theme_font_size_override("font_size", 28)
	go_lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
	game_over_panel.add_child(go_lbl)
	
	# Botão Recomentar (Retry)
	var btn_retry = Button.new()
	btn_retry.name = "RetryButton"
	btn_retry.text = GameGlobals.get_text("gameover_retry")
	btn_retry.size = Vector2(240, 40)
	btn_retry.position = Vector2(70, 100)
	btn_retry.add_theme_font_override("font", _load_font(false))
	game_over_panel.add_child(btn_retry)
	_setup_hover_events(btn_retry)
	btn_retry.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/gilgamesh_qte/gilgamesh_scene.tscn")
	)
	
	# Botão Menu Principal
	var btn_menu = Button.new()
	btn_menu.name = "MenuButton"
	btn_menu.text = GameGlobals.get_text("gameover_menu")
	btn_menu.size = Vector2(240, 40)
	btn_menu.position = Vector2(70, 160)
	btn_menu.add_theme_font_override("font", _load_font(false))
	game_over_panel.add_child(btn_menu)
	_setup_hover_events(btn_menu)
	btn_menu.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)

func _setup_hover_events(button: Button):
	button.pivot_offset = button.size / 2
	if GameGlobals:
		button.mouse_entered.connect(GameGlobals.play_hover_sound)
		button.pressed.connect(GameGlobals.play_click_sound)
		
	button.mouse_entered.connect(func():
		var tw = create_tween()
		tw.tween_property(button, "scale", Vector2(1.05, 1.05), 0.15)
	)
	button.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15)
	)

# ---------------------------------------------------------------------------
# Efeitos Sonoros Locais
# ---------------------------------------------------------------------------
func _play_sfx(sound_name: String, pitch: float = 1.0, volume: float = 0.0):
	var sfx = AudioStreamPlayer.new()
	var stream = load("res://assets/sounds/" + sound_name + ".wav")
	if stream:
		sfx.stream = stream
		sfx.pitch_scale = pitch
		sfx.volume_db = volume
		sfx.bus = "SFX"
		add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)
