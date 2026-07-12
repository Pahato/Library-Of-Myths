extends CanvasLayer

@onready var hearts_container = $HeartsContainer
@onready var game_over_screen = $GameOverScreen
@onready var victory_screen = $VictoryScreen

@onready var retry_button = $GameOverScreen/Panel/RetryButton
@onready var menu_button = $VictoryScreen/Panel/MenuButton

var go_menu_button: Button = null # Botão "Voltar ao Menu" na tela de Game Over

var player: CharacterBody2D = null
var boss: CharacterBody2D = null

# --- Novos Elementos de UI Dinâmicos (Elden Ring HUD & Munição) ---
var boss_hud_container: Control = null
var boss_health_bar: ProgressBar = null
var boss_health_lag_bar: ProgressBar = null
var sb_fill: StyleBoxFlat = null
var sb_lag_fill: StyleBoxFlat = null
var boss_name_label: Label = null
var altars_label: Label = null
var ammo_label: Label = null
var dash_label: Label = null

# --- Keystroke HUD ---
var keystroke_container: Control = null
var key_labels: Dictionary = {}

# Diálogo de vitória mostrado antes do ecrã de vitória
var victory_dialogue_scene: PackedScene = preload("res://scenes/dialogue_box.tscn")
var victory_lines: Array = [
	{"name": "char_apolo", "text": "dialogue_apolo_victory_1"},
	{"name": "char_apolo", "text": "dialogue_apolo_victory_2"},
]

func _ready():
	# Interface e botões funcionam mesmo com o jogo pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	game_over_screen.hide()
	victory_screen.hide()
	
	# Localizar ecrãs de fim de jogo
	var is_rhythm = false
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "RhythmGame":
		is_rhythm = true
		
	if is_rhythm:
		$GameOverScreen/Panel/TitleLabel.text = GameGlobals.get_text("gameover_title_shiva")
		retry_button.text = GameGlobals.get_text("gameover_retry")
		$VictoryScreen/Panel/TitleLabel.text = GameGlobals.get_text("victory_title_shiva")
		menu_button.text = GameGlobals.get_text("victory_menu")
		_apply_rhythm_hud_styles()
	else:
		$GameOverScreen/Panel/TitleLabel.text = GameGlobals.get_text("gameover_title")
		retry_button.text = GameGlobals.get_text("gameover_retry")
		$VictoryScreen/Panel/TitleLabel.text = GameGlobals.get_text("victory_title")
		menu_button.text = GameGlobals.get_text("victory_menu")
		_apply_apollo_hud_styles()
	
	# Ligar botões base
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	if GameGlobals:
		retry_button.mouse_entered.connect(GameGlobals.play_hover_sound)
		menu_button.mouse_entered.connect(GameGlobals.play_hover_sound)
	
	# Adicionar botão "Voltar ao Menu" na tela de Game Over
	_add_go_menu_button()
	
	# Inicializar HUD de munição
	_setup_ammo_ui()
	
	# Inicializar Keystroke HUD
	_setup_keystroke_hud()
	
	# Inicializar fundos das HUDs para legibilidade
	_setup_hud_backgrounds(is_rhythm)
	
	# Procurar e conectar-se ao Jogador
	_setup_player()
	# Procurar e conectar-se ao Boss
	_setup_boss()

func _process(delta):
	# Fallback caso o jogador ou o boss sejam redefinidos
	if not is_instance_valid(player):
		_setup_player()
	if not is_instance_valid(boss):
		_setup_boss()
		if boss_hud_container:
			boss_hud_container.hide()
	else:
		if not boss_hud_container:
			_setup_boss_hud()
			
		# Atualiza valores do HUD da Píton estilo Elden Ring
		if boss_hud_container and is_instance_valid(boss):
			boss_hud_container.show()
			
			# Sincroniza valores máximos e atuais de vida (clamped a 0)
			boss_health_bar.max_value = boss.max_health
			boss_health_bar.value = max(0, boss.current_health)
			
			if is_instance_valid(boss_health_lag_bar):
				boss_health_lag_bar.max_value = boss.max_health
				boss_health_lag_bar.value = lerp(boss_health_lag_bar.value, float(max(0, boss.current_health)), 2.5 * delta)
				if abs(boss_health_lag_bar.value - max(0, boss.current_health)) < 0.1:
					boss_health_lag_bar.value = max(0, boss.current_health)
			
			# Atualiza o nome do boss dinamicamente com suporte a traduções
			if is_instance_valid(boss):
				if boss.is_phase_2:
					boss_name_label.text = GameGlobals.get_text("boss_name_phase_2")
				else:
					boss_name_label.text = GameGlobals.get_text("boss_name_phase_1")
				
			if boss.is_phase_2:
				# Roxo escuro / macabro para a forma evoluída
				if sb_fill:
					sb_fill.bg_color = Color(0.52, 0.05, 0.65, 0.95)
				if sb_lag_fill:
					sb_lag_fill.bg_color = Color(0.72, 0.35, 0.82, 0.9)
				boss_name_label.add_theme_color_override("font_color", Color(0.78, 0.2, 0.95, 1.0))
			else:
				# Vermelho clássico para a primeira fase
				if sb_fill:
					sb_fill.bg_color = Color(0.68, 0.08, 0.08, 0.95)
				if sb_lag_fill:
					sb_lag_fill.bg_color = Color(0.85, 0.55, 0.1, 0.9)
				boss_name_label.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15, 1.0))
			
			# Ocultar as barras antigas em cima da cabeça do boss para limpar o ecrã
			if boss.has_node("ProgressBar"):
				boss.get_node("ProgressBar").hide()
			if boss.has_node("Label"):
				boss.get_node("Label").hide()
				
			# Atualiza estado dos Altares Solares
			var level = get_parent()
			if level and "left_altar" in level and "right_altar" in level:
				var la_active = level.left_altar.is_active if is_instance_valid(level.left_altar) else false
				var ra_active = level.right_altar.is_active if is_instance_valid(level.right_altar) else false
				
				if boss.is_phase_2:
					if boss.shield_active:
						var la_char = "☀️" if la_active else "◯"
						var ra_char = "☀️" if ra_active else "◯"
						altars_label.text = GameGlobals.get_text("ui_shield_active") + la_char + "    " + ra_char
						altars_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
					elif boss.is_stunned:
						altars_label.text = GameGlobals.get_text("ui_stunned")
						altars_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.2, 1.0))
					else:
						altars_label.text = GameGlobals.get_text("ui_shield_broken")
						altars_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
				else:
					altars_label.text = GameGlobals.get_text("ui_phase_1")
					altars_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95, 1.0))

	# Atualiza o mostrador de flechas/recarga de Apolo
	if is_instance_valid(player) and ammo_label:
		if "current_arrows" in player:
			var arrows_text = ""
			for i in range(player.current_arrows):
				arrows_text += "⚡"
			
			if player.current_arrows == 0:
				ammo_label.text = GameGlobals.get_text("ui_recharging")
				ammo_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
			else:
				ammo_label.text = GameGlobals.get_text("ui_arrows") + arrows_text
				ammo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))

	# Atualiza o mostrador do Dash Solar de Apolo
	if is_instance_valid(player) and dash_label:
		if "dash_cooldown_timer" in player:
			if player.dash_cooldown_timer > 0.0:
				dash_label.text = GameGlobals.get_text("ui_dash_cooldown") + str(snapped(player.dash_cooldown_timer, 0.1)) + "s"
				dash_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6, 1.0))
			else:
				dash_label.text = GameGlobals.get_text("ui_dash_ready")
				dash_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))

	# Atualizar o Keystroke HUD
	_update_keystroke_hud()

func _setup_player():
	player = get_tree().root.find_child("Player", true, false)
	if is_instance_valid(player):
		# Prevenir conexões duplicadas
		if not player.health_changed.is_connected(_on_player_health_changed):
			player.health_changed.connect(_on_player_health_changed)
		if not player.player_died.is_connected(_on_player_died):
			player.player_died.connect(_on_player_died)
		# Inicializa corações
		_on_player_health_changed(player.current_health)

func _setup_boss():
	boss = get_tree().root.find_child("Python", true, false)
	if is_instance_valid(boss):
		if not boss.boss_died.is_connected(_on_boss_died):
			boss.boss_died.connect(_on_boss_died)

func _on_player_health_changed(health: int):
	# Limpar corações antigos
	for child in hearts_container.get_children():
		child.queue_free()
	
	# Desenhar corações novos usando texto ❤
	for i in range(max(0, health)):
		var heart_label = Label.new()
		heart_label.text = "❤"
		heart_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25, 1.0))
		heart_label.add_theme_font_size_override("font_size", 24)
		hearts_container.add_child(heart_label)

func _on_player_died():
	print("[DEATH DEBUG] Player died. Setting up game over screen...")
	# Toca som de derrota temático antes de pausar
	if GameGlobals:
		GameGlobals.play_defeat_sound()
	get_tree().paused = true
	game_over_screen.show()
	
	# Garantir que todos os controlos da tela de morte processam sempre e não ignoram rato
	game_over_screen.process_mode = Node.PROCESS_MODE_ALWAYS
	game_over_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var panel = game_over_screen.get_node_or_null("Panel")
	if panel:
		panel.process_mode = Node.PROCESS_MODE_ALWAYS
		panel.mouse_filter = Control.MOUSE_FILTER_STOP
		
	if retry_button:
		retry_button.process_mode = Node.PROCESS_MODE_ALWAYS
		retry_button.mouse_filter = Control.MOUSE_FILTER_STOP
		print("[DEATH DEBUG] RetryButton configuration: visible=", retry_button.visible, " process_mode=", retry_button.process_mode, " mouse_filter=", retry_button.mouse_filter)
		
	if go_menu_button:
		go_menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
		go_menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
		print("[DEATH DEBUG] GoMenuButton configuration: visible=", go_menu_button.visible, " process_mode=", go_menu_button.process_mode, " mouse_filter=", go_menu_button.mouse_filter)

func _on_boss_died():
	# Ocultar imediatamente o HUD do boss para evitar a barra roxa persistente
	if boss_hud_container:
		boss_hud_container.hide()
	# Primeiro mostra o diálogo de vitória, depois o ecrã de vitória
	get_tree().create_timer(0.5).timeout.connect(func():
		if not get_tree().paused:
			var dialogue = victory_dialogue_scene.instantiate()
			dialogue.dialogue_list = victory_lines
			dialogue.dialogue_finished.connect(func():
				# Toca som de vitória triunfante
				if GameGlobals:
					GameGlobals.play_victory_sound()
				get_tree().paused = true
				victory_screen.show()
				victory_screen.process_mode = Node.PROCESS_MODE_ALWAYS
				victory_screen.mouse_filter = Control.MOUSE_FILTER_STOP
				var v_panel = victory_screen.get_node_or_null("Panel")
				if v_panel:
					v_panel.process_mode = Node.PROCESS_MODE_ALWAYS
					v_panel.mouse_filter = Control.MOUSE_FILTER_STOP
				if menu_button:
					menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
					menu_button.mouse_filter = Control.MOUSE_FILTER_STOP
			)
			get_parent().add_child(dialogue)
	)

func _add_go_menu_button():
	# Criar o botão "Voltar à Biblioteca" na tela de Game Over
	var go_panel = $GameOverScreen/Panel
	if not go_panel:
		return
	
	# Garantir que o painel tem largura suficiente para 2 botões (segurança adicional)
	go_panel.offset_left = -190.0
	go_panel.offset_right = 190.0
	
	# Reposicionar o botão Retry para a metade esquerda
	retry_button.anchor_left = 0.5
	retry_button.anchor_right = 0.5
	retry_button.anchor_top = 1.0
	retry_button.anchor_bottom = 1.0
	retry_button.offset_left = -185.0
	retry_button.offset_right = -5.0
	retry_button.offset_top = -58.0
	retry_button.offset_bottom = -22.0
	retry_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	retry_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	# Criar botão "Voltar à Biblioteca" na metade direita
	go_menu_button = Button.new()
	go_menu_button.name = "GoMenuButton"
	go_menu_button.text = GameGlobals.get_text("gameover_menu") if GameGlobals else "Voltar à Biblioteca"
	go_menu_button.anchor_left = 0.5
	go_menu_button.anchor_top = 1.0
	go_menu_button.anchor_right = 0.5
	go_menu_button.anchor_bottom = 1.0
	go_menu_button.offset_left = 5.0
	go_menu_button.offset_right = 185.0
	go_menu_button.offset_top = -58.0
	go_menu_button.offset_bottom = -22.0
	go_menu_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	go_menu_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	go_panel.add_child(go_menu_button)
	
	go_menu_button.pressed.connect(_on_menu_pressed)
	if GameGlobals:
		go_menu_button.mouse_entered.connect(GameGlobals.play_hover_sound)
		go_menu_button.pressed.connect(GameGlobals.play_click_sound)


func _on_retry_pressed():
	if GameGlobals:
		GameGlobals.play_click_sound()
	get_tree().paused = false
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.name == "RhythmGame":
		SceneTransition.fade_to("res://scenes/shiva_rudra/rhythm_game.tscn")
	else:
		SceneTransition.fade_to("res://scenes/apolo_python/game.tscn")

func _on_menu_pressed():
	if GameGlobals:
		GameGlobals.play_click_sound()
	get_tree().paused = false
	SceneTransition.fade_to("res://scenes/main_menu.tscn")

# --- Métodos de Criação de Interface Dinâmica ---

func _setup_ammo_ui():
	# Criar rótulo de munição programaticamente abaixo dos corações
	ammo_label = Label.new()
	ammo_label.name = "AmmoLabel"
	ammo_label.position = Vector2(20, 52)
	ammo_label.add_theme_font_size_override("font_size", 9)
	add_child(ammo_label)

	# Criar rótulo do Solar Dash programaticamente abaixo da munição
	dash_label = Label.new()
	dash_label.name = "DashLabel"
	dash_label.position = Vector2(20, 66)
	dash_label.add_theme_font_size_override("font_size", 9)
	add_child(dash_label)

func _setup_boss_hud():
	if not is_instance_valid(boss):
		return
		
	# Criar container para a barra Elden Ring no fundo do ecrã
	boss_hud_container = Control.new()
	boss_hud_container.name = "BossHUD"
	
	# Posiciona na base horizontal total
	boss_hud_container.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	boss_hud_container.offset_top = -80.0
	boss_hud_container.offset_bottom = -20.0
	# Afasta ligeiramente dos lados
	boss_hud_container.offset_left = 80.0
	boss_hud_container.offset_right = -80.0
	add_child(boss_hud_container)
	
	# Nome do Boss (PÍTON, A SERPENTE DE DELFOS)
	boss_name_label = Label.new()
	boss_name_label.text = GameGlobals.get_text("boss_name_phase_1")
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.add_theme_color_override("font_color", Color(0.95, 0.15, 0.15, 1.0))
	boss_name_label.add_theme_font_size_override("font_size", 10)
	boss_name_label.add_theme_constant_override("outline_size", 3)
	boss_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_name_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_name_label.offset_top = 0
	boss_hud_container.add_child(boss_name_label)
	
	# 1. Barra de Dano Persistente (Lag Bar) - Atrás
	boss_health_lag_bar = ProgressBar.new()
	boss_health_lag_bar.name = "BossHealthLagBar"
	boss_health_lag_bar.show_percentage = false
	boss_health_lag_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_health_lag_bar.offset_top = 18.0
	boss_health_lag_bar.offset_bottom = 24.0
	boss_health_lag_bar.max_value = boss.max_health
	boss_health_lag_bar.value = boss.current_health
	
	# Estilo fill da lag bar (amarelo/laranja na fase 1)
	sb_lag_fill = StyleBoxFlat.new()
	sb_lag_fill.bg_color = Color(0.85, 0.55, 0.1, 0.9)
	boss_health_lag_bar.add_theme_stylebox_override("fill", sb_lag_fill)
	
	# Estilo background da lag bar (contorno dourado e fundo escuro)
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.08, 0.08, 0.08, 0.75)
	sb_bg.border_width_left = 1
	sb_bg.border_width_top = 1
	sb_bg.border_width_right = 1
	sb_bg.border_width_bottom = 1
	sb_bg.border_color = Color(0.45, 0.4, 0.22, 0.8) # Dourado antigo
	boss_health_lag_bar.add_theme_stylebox_override("background", sb_bg)
	boss_hud_container.add_child(boss_health_lag_bar)
	
	# 2. Barra de Vida Principal (Vermelha) - À Frente
	boss_health_bar = ProgressBar.new()
	boss_health_bar.name = "BossHealthBar"
	boss_health_bar.show_percentage = false
	boss_health_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	boss_health_bar.offset_top = 18.0
	boss_health_bar.offset_bottom = 24.0
	boss_health_bar.max_value = boss.max_health
	boss_health_bar.value = boss.current_health
	
	# Estilo fill da barra vermelha
	sb_fill = StyleBoxFlat.new()
	sb_fill.bg_color = Color(0.68, 0.08, 0.08, 0.95)
	boss_health_bar.add_theme_stylebox_override("fill", sb_fill)
	
	# Background vazio para a barra principal (para ver a lag bar por trás)
	var sb_empty_bg = StyleBoxEmpty.new()
	boss_health_bar.add_theme_stylebox_override("background", sb_empty_bg)
	boss_hud_container.add_child(boss_health_bar)
	
	# Estado dos Altares Solares
	altars_label = Label.new()
	altars_label.name = "AltarsLabel"
	altars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	altars_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	altars_label.offset_top = 32.0
	altars_label.add_theme_font_size_override("font_size", 10)
	altars_label.add_theme_constant_override("outline_size", 3)
	altars_label.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_hud_container.add_child(altars_label)

# --- Métodos do Keystroke HUD ---

func _setup_keystroke_hud():
	keystroke_container = Control.new()
	keystroke_container.name = "KeystrokeHUD"
	# Posiciona no canto superior direito
	keystroke_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	keystroke_container.offset_left = -140.0
	keystroke_container.offset_top = 8.0
	keystroke_container.offset_right = -4.0
	keystroke_container.offset_bottom = 115.0
	add_child(keystroke_container)
	
	# Determinar cor temática baseada na cena ativa
	var accent_color = Color(1.0, 0.85, 0.25, 1.0)
	var scene_name = ""
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	if "Rhythm" in scene_name or "Shiva" in scene_name:
		accent_color = Color(0.7, 0.3, 1.0, 1.0)
	elif "Thor" in scene_name or "Battle" in scene_name:
		accent_color = Color(0.3, 0.6, 1.0, 1.0)
	elif "Susano" in scene_name or "Orochi" in scene_name:
		accent_color = Color(0.9, 0.15, 0.15, 1.0)
	elif "Gilgamesh" in scene_name:
		accent_color = Color(1.0, 0.75, 0.1, 1.0)
		
	# Adicionar painel de fundo para o Keystroke HUD
	var keystroke_bg = Panel.new()
	keystroke_bg.name = "KeystrokeBG"
	keystroke_bg.position = Vector2(8, -4)
	keystroke_bg.size = Vector2(94, 94)
	
	var sb_bg = StyleBoxFlat.new()
	sb_bg.bg_color = Color(0.04, 0.03, 0.02, 0.58)
	sb_bg.corner_radius_top_left = 6
	sb_bg.corner_radius_top_right = 6
	sb_bg.corner_radius_bottom_left = 6
	sb_bg.corner_radius_bottom_right = 6
	sb_bg.border_width_bottom = 2
	sb_bg.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.38)
	keystroke_bg.add_theme_stylebox_override("panel", sb_bg)
	keystroke_container.add_child(keystroke_bg)
	# Garante que desenha atrás das teclas
	keystroke_container.move_child(keystroke_bg, 0)
	
	# Layout das teclas: { nome: [texto, size, position] }
	# Coordenadas ajustadas para ficarem compactas e proporcionais
	var layout = {
		"W": ["W", Vector2(24, 22), Vector2(40, 0)],
		"A": ["A", Vector2(24, 22), Vector2(14, 24)],
		"S": ["S", Vector2(24, 22), Vector2(40, 24)],
		"D": ["D", Vector2(24, 22), Vector2(66, 24)],
		"SPACE": ["SPACE", Vector2(76, 18), Vector2(14, 48)],
		"LMB": ["LMB", Vector2(36, 18), Vector2(14, 68)],
		"PARRY": ["PARRY", Vector2(38, 18), Vector2(52, 68)]
	}
	
	for key in layout:
		var data = layout[key]
		var text = data[0]
		var size = data[1]
		var pos = data[2]
		
		var panel = Panel.new()
		panel.name = key + "_Panel"
		panel.position = pos
		panel.size = size
		
		# Estilo padrão da tecla (escuro translúcido com contorno fino)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.06, 0.06, 0.55)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		sb.border_color = Color(0.4, 0.4, 0.4, 0.45)
		sb.corner_radius_top_left = 2
		sb.corner_radius_top_right = 2
		sb.corner_radius_bottom_left = 2
		sb.corner_radius_bottom_right = 2
		panel.add_theme_stylebox_override("panel", sb)
		
		# Texto
		var label = Label.new()
		label.name = key + "_Label"
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 7 if text.length() > 2 else 9)
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color.BLACK)
		label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
		
		panel.add_child(label)
		keystroke_container.add_child(panel)
		key_labels[key] = [panel, label, sb]

func _update_keystroke_hud():
	if not keystroke_container:
		return
	keystroke_container.visible = GameGlobals.keystroke_enabled
	if not GameGlobals.keystroke_enabled or key_labels.is_empty():
		return
		
	# Verifica o estado real das teclas pressionadas pelo jogador
	var states = {
		"W": Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or (is_instance_valid(player) and Input.is_action_pressed("jump")),
		"A": Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or (is_instance_valid(player) and Input.is_action_pressed("move_left")),
		"S": Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN),
		"D": Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or (is_instance_valid(player) and Input.is_action_pressed("move_right")),
		"SPACE": Input.is_physical_key_pressed(KEY_SPACE),
		"LMB": Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or (is_instance_valid(player) and Input.is_action_pressed("shoot")),
		"PARRY": (is_instance_valid(player) and player.is_parrying) or Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_C)
	}
	
	for key in states:
		if not key_labels.has(key):
			continue
		var data = key_labels[key]
		var _panel = data[0]
		var label = data[1]
		var sb = data[2]
		
		var is_pressed = states[key]
		if is_pressed:
			# Destaque de tecla premida
			if key == "PARRY":
				sb.bg_color = Color(1.3, 1.0, 0.3, 0.9) # Dourado brilhante solar para o parry
				sb.border_color = Color(1.0, 0.9, 0.4, 1.0)
				label.add_theme_color_override("font_color", Color.BLACK)
			elif key == "SPACE":
				sb.bg_color = Color(0.85, 0.85, 0.85, 0.85)
				sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
				label.add_theme_color_override("font_color", Color.BLACK)
			else:
				sb.bg_color = Color(0.8, 0.8, 0.8, 0.85)
				sb.border_color = Color(1.0, 1.0, 1.0, 1.0)
				label.add_theme_color_override("font_color", Color.BLACK)
		else:
			# Estilo normal inativo
			sb.bg_color = Color(0.06, 0.06, 0.06, 0.55)
			sb.border_color = Color(0.4, 0.4, 0.4, 0.45)
			label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))

func _apply_rhythm_hud_styles():
	var font_bold = _load_font(true)
	var font_reg = _load_font(false)
	
	# 1. Cores de fundo (ColorRect)
	var go_color_rect = $GameOverScreen/ColorRect
	if go_color_rect:
		go_color_rect.color = Color(0.08, 0.04, 0.15, 0.78) # Roxo escuro
		
	var vic_color_rect = $VictoryScreen/ColorRect
	if vic_color_rect:
		vic_color_rect.color = Color(0.04, 0.08, 0.15, 0.78) # Azul escuro
		
	# 2. Painel de GameOver
	var go_panel = $GameOverScreen/Panel
	if go_panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.04, 0.12, 0.96)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.9, 0.15, 0.75, 1.0) # Neon Magenta
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		sb.shadow_size = 15
		sb.shadow_color = Color(0, 0, 0, 0.8)
		go_panel.add_theme_stylebox_override("panel", sb)
		
	# 3. Painel de Vitória
	var vic_panel = $VictoryScreen/Panel
	if vic_panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.06, 0.12, 0.96)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.15, 0.85, 0.95, 1.0) # Neon Cyan
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_left = 4
		sb.corner_radius_bottom_right = 4
		sb.shadow_size = 15
		sb.shadow_color = Color(0, 0, 0, 0.8)
		vic_panel.add_theme_stylebox_override("panel", sb)
		
	# 4. Textos
	var go_label = $GameOverScreen/Panel/TitleLabel
	if go_label:
		if font_bold: go_label.add_theme_font_override("font", font_bold)
		go_label.add_theme_font_size_override("font_size", 18)
		go_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.8, 1.0)) # Neon Magenta
		go_label.add_theme_constant_override("outline_size", 4)
		go_label.add_theme_color_override("font_outline_color", Color.BLACK)
		
	var vic_label = $VictoryScreen/Panel/TitleLabel
	if vic_label:
		if font_bold: vic_label.add_theme_font_override("font", font_bold)
		vic_label.add_theme_font_size_override("font_size", 20)
		vic_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0, 1.0)) # Neon Cyan
		vic_label.add_theme_constant_override("outline_size", 4)
		vic_label.add_theme_color_override("font_outline_color", Color.BLACK)
		
	# 5. Botões
	_style_rhythm_hud_button(retry_button, font_reg, Color(0.9, 0.15, 0.75, 0.85), Color(1.0, 0.25, 0.85, 1.0))
	_style_rhythm_hud_button(menu_button, font_reg, Color(0.15, 0.85, 0.95, 0.85), Color(0.25, 0.95, 1.0, 1.0))
	if is_instance_valid(go_menu_button):
		_style_rhythm_hud_button(go_menu_button, font_reg, Color(0.15, 0.85, 0.95, 0.85), Color(0.25, 0.95, 1.0, 1.0))

func _style_rhythm_hud_button(btn: Button, font: FontFile, border_color: Color, hover_border_color: Color):
	if not btn: return
	if font: btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.95, 0.92, 0.98, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.08, 0.06, 0.12, 0.9)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.border_color = border_color
	sb_normal.corner_radius_top_left = 3
	sb_normal.corner_radius_top_right = 3
	sb_normal.corner_radius_bottom_left = 3
	sb_normal.corner_radius_bottom_right = 3
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.18, 0.1, 0.28, 0.95)
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.border_color = hover_border_color
	sb_hover.corner_radius_top_left = 3
	sb_hover.corner_radius_top_right = 3
	sb_hover.corner_radius_bottom_left = 3
	sb_hover.corner_radius_bottom_right = 3
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	return load(path) as FontFile

func _setup_hud_backgrounds(is_rhythm: bool):
	if is_rhythm:
		if ammo_label: ammo_label.hide()
		if dash_label: dash_label.hide()
		return
		
	# Criar painel de fundo para o HUD do jogador (corações, munição, dash) no canto superior esquerdo
	var player_hud_bg = Panel.new()
	player_hud_bg.name = "PlayerHUDBG"
	player_hud_bg.position = Vector2(10, 10)
	
	# Ajustar largura do painel dinamicamente consoante a vida máxima (dificuldade) do jogador
	var max_hp = 6
	if GameGlobals:
		max_hp = GameGlobals.get_player_max_health()
		
	var panel_width = 290.0
	match max_hp:
		8: panel_width = 370.0 # Fácil: mais corações
		6: panel_width = 290.0 # Normal: padrão
		4: panel_width = 210.0 # Difícil: menos corações
		_: panel_width = 290.0
		
	player_hud_bg.size = Vector2(panel_width, 78)
	
	# Determinar cor de destaque temática baseada na cena ativa
	var accent_color = Color(1.0, 0.85, 0.25, 1.0) # Apolo por defeito
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.03, 0.02, 0.58) # Translúcido escuro premium
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.border_width_bottom = 2
	sb.border_color = Color(accent_color.r, accent_color.g, accent_color.b, 0.38)
	player_hud_bg.add_theme_stylebox_override("panel", sb)
	
	add_child(player_hud_bg)
	move_child(player_hud_bg, 0) # Desenha por trás de tudo

func _apply_apollo_hud_styles():
	var font_bold = _load_font(true)
	var font_reg = _load_font(false)
	
	# 1. Cores de fundo (ColorRect)
	var go_color_rect = $GameOverScreen/ColorRect
	if go_color_rect:
		go_color_rect.color = Color(0.08, 0.05, 0.03, 0.75) # Castanho dourado escuro
		
	var vic_color_rect = $VictoryScreen/ColorRect
	if vic_color_rect:
		vic_color_rect.color = Color(0.08, 0.05, 0.03, 0.75)
		
	# 2. Painel de GameOver
	var go_panel = $GameOverScreen/Panel
	if go_panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.05, 0.03, 0.97) # Castanho rústico antigo
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.85, 0.65, 0.25, 1.0) # Dourado de Apolo
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.shadow_size = 15
		sb.shadow_color = Color(0, 0, 0, 0.8)
		go_panel.add_theme_stylebox_override("panel", sb)
		
	# 3. Painel de Vitória
	var vic_panel = $VictoryScreen/Panel
	if vic_panel:
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.05, 0.03, 0.97)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = Color(0.85, 0.65, 0.25, 1.0)
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		sb.shadow_size = 15
		sb.shadow_color = Color(0, 0, 0, 0.8)
		vic_panel.add_theme_stylebox_override("panel", sb)
		
	# 4. Título de GameOver
	var go_label = $GameOverScreen/Panel/TitleLabel
	if go_label:
		if font_bold: go_label.add_theme_font_override("font", font_bold)
		go_label.add_theme_font_size_override("font_size", 22)
		go_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0)) # Vermelho solar de perigo
		go_label.add_theme_constant_override("outline_size", 3)
		go_label.add_theme_color_override("font_outline_color", Color.BLACK)
		
	# Título de Vitória
	var vic_label = $VictoryScreen/Panel/TitleLabel
	if vic_label:
		if font_bold: vic_label.add_theme_font_override("font", font_bold)
		vic_label.add_theme_font_size_override("font_size", 22)
		vic_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0)) # Dourado de Apolo
		vic_label.add_theme_constant_override("outline_size", 3)
		vic_label.add_theme_color_override("font_outline_color", Color.BLACK)
		
	# 5. Botões
	_style_apollo_hud_button(retry_button, font_reg)
	_style_apollo_hud_button(menu_button, font_reg)
	if is_instance_valid(go_menu_button):
		_style_apollo_hud_button(go_menu_button, font_reg)

func _style_apollo_hud_button(btn: Button, font: FontFile):
	if not btn: return
	if font: btn.add_theme_font_override("font", font)
	btn.add_theme_font_size_override("font_size", 13)
	btn.add_theme_color_override("font_color", Color(0.92, 0.85, 0.70, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0, 1.0))
	
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = Color(0.14, 0.09, 0.05, 0.85)
	sb_normal.border_color = Color(0.55, 0.42, 0.18, 0.7)
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.corner_radius_top_left = 3
	sb_normal.corner_radius_top_right = 3
	sb_normal.corner_radius_bottom_left = 3
	sb_normal.corner_radius_bottom_right = 3
	
	var sb_hover = StyleBoxFlat.new()
	sb_hover.bg_color = Color(0.30, 0.18, 0.05, 0.95)
	sb_hover.border_color = Color(0.9, 0.72, 0.3, 1.0)
	sb_hover.border_width_left = 1
	sb_hover.border_width_top = 1
	sb_hover.border_width_right = 1
	sb_hover.border_width_bottom = 1
	sb_hover.corner_radius_top_left = 3
	sb_hover.corner_radius_top_right = 3
	sb_hover.corner_radius_bottom_left = 3
	sb_hover.corner_radius_bottom_right = 3
	
	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("focus", sb_hover)
