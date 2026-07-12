extends Node2D
class_name RhythmGame

# --- Preloads ---
var arrow_scene = preload("res://scenes/shiva_rudra/rhythm_arrow.tscn")
var dialogue_scene = preload("res://scenes/dialogue_box.tscn")
var pause_menu_scene = preload("res://scenes/pause_menu.tscn")

# --- Constantes de Ritmo ---
const BPM: float = 130.0
const BEAT_TIME: float = 60.0 / BPM # ~0.46s
var SCROLL_SPEED: float = 400.0 # Ajustado pela dificuldade
var TARGET_Y: float = 100.0 # Y dos recetores
var SPAWN_Y: float = 580.0  # Y onde as setas nascem
var SPAWN_AHEAD_TIME: float = 1.2 # Quanto tempo antes o note spawna

# --- Configurações do Jogo ---
var difficulty: int = 1 # 0: Fácil, 1: Normal, 2: Hard
var rhythm_scroll_down: bool = false # Falso = setas sobem, Verdade = descem

# --- Estado do Áudio e Sincronização ---
var is_playing: bool = false
var song_time: float = 0.0
var time_begin: int = 0
var time_delay: float = 0.0
var last_beat: int = -1
var song_length: float = 80.0 # Tempo total de jogo
var pause_start_time: int = 0 # Guarda carimbo de hora da pausa

# --- Estado da Jogabilidade ---
var active_notes: Array = []
var notes_chart: Array = []
var note_index: int = 0
var cutscene_active: bool = true

# --- Estatísticas ---
var player_score: int = 0
var player_combo: int = 0
var last_displayed_combo: int = 0
var player_max_combo: int = 0
var notes_hit: int = 0
var total_chart_notes: int = 0
var accuracy: float = 100.0
var timing_total: float = 0.0 # Média de precisão

# --- Barra de Vida (Tug of War) ---
# 50.0 é equilíbrio, 0.0 é Rudra domina (derrota), 100.0 é Shiva domina (vitória)
var tug_of_war: float = 50.0 

# --- Penalizações e Atordoamento ---
var stun_timer: float = 0.0 # Jogador paralisado se apanhar choque

# --- Referências de Nós ---
var audio_player: AudioStreamPlayer
var background: TextureRect
var lightning_rect: ColorRect
var shiva_duck: AnimatedSprite2D
var rudra_duck: Sprite2D
var shiva_platform: Panel
var rudra_platform: Panel

# Texturas
var duck_tex: Texture2D
var rudra_boss_tex: Texture2D

# Etiquetas de pista
var boss_lane_label: Label
var player_lane_label: Label

# Receptores
var rudra_receptors: Array = []
var shiva_receptors: Array = []

# UI Nodes
var hud_node: Control
var stats_panel: Panel # Referência para reposicionamento dinâmico
var score_label: Label
var combo_label: Label
var accuracy_label: Label
var rating_label: Label

# HUD Layout Dinâmico
var tug_of_war_y: float = 15.0 # Y da barra Tug-of-War (ajustado pelo scroll)

# Pause Menu Instance
var pause_menu_instance = null

# --- Efeitos Sonoros ---
var sound_tap: AudioStreamPlayer
var sound_hurt: AudioStreamPlayer
var sound_powerup: AudioStreamPlayer

# --- Balanceamento por Dificuldade ---
var boss_hit_chance: float = 0.78
var boss_note_dmg: float = 0.25
var heal_perfect: float = 2.0
var heal_good: float = 1.0
var heal_okay: float = 0.3
var miss_dmg: float = 2.5
var shock_dmg: float = 7.0

func _ready():
	# Parar música de menu principal
	if GameGlobals:
		GameGlobals.stop_music()
		difficulty = int(GameGlobals.current_difficulty)
		rhythm_scroll_down = GameGlobals.rhythm_scroll_down
	
	# Ajustar velocidade de scroll por dificuldade
	match difficulty:
		0: SCROLL_SPEED = 320.0 # Fácil
		1: SCROLL_SPEED = 420.0 # Normal
		2: SCROLL_SPEED = 540.0 # Difícil
		
	# Inicializar parâmetros de balanceamento por dificuldade
	match difficulty:
		0: # Fácil
			boss_hit_chance = 0.60; boss_note_dmg = 0.10
			heal_perfect = 3.0; heal_good = 1.5; heal_okay = 0.5
			miss_dmg = 0.8; shock_dmg = 2.5
		1: # Normal
			boss_hit_chance = 0.72; boss_note_dmg = 0.22
			heal_perfect = 2.0; heal_good = 1.0; heal_okay = 0.5
			miss_dmg = 2.0; shock_dmg = 6.0
		2: # Difícil
			boss_hit_chance = 0.85; boss_note_dmg = 0.38
			heal_perfect = 1.2; heal_good = 0.6; heal_okay = 0.1
			miss_dmg = 5.0; shock_dmg = 12.0
			
	# Layout inicial: definido pelo _update_hud_layout() após setup
	if rhythm_scroll_down:
		TARGET_Y = 490.0
		SPAWN_Y = 110.0
		tug_of_war_y = 600.0
	else:
		TARGET_Y = 130.0
		SPAWN_Y = 580.0
		tug_of_war_y = 15.0
		
	# Recalcular SPAWN_AHEAD_TIME
	SPAWN_AHEAD_TIME = abs(SPAWN_Y - TARGET_Y) / SCROLL_SPEED
		
	# 1. Configurar Áudio Principal
	audio_player = AudioStreamPlayer.new()
	audio_player.stream = load("res://assets/music/orbital_colossus.wav")
	audio_player.volume_db = -4.0
	audio_player.bus = "Music"
	audio_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(audio_player)
	
	# 2. Configurar Efeitos Sonoros
	sound_tap = AudioStreamPlayer.new()
	sound_tap.stream = load("res://assets/sounds/best_snare.wav")
	sound_tap.volume_db = 0.0
	sound_tap.bus = "SFX"
	add_child(sound_tap)
	
	sound_hurt = AudioStreamPlayer.new()
	sound_hurt.stream = load("res://assets/sounds/hurt.wav")
	sound_hurt.volume_db = -1.0
	sound_hurt.bus = "SFX"
	add_child(sound_hurt)
	
	sound_powerup = AudioStreamPlayer.new()
	sound_powerup.stream = load("res://assets/sounds/power_up.wav")
	sound_powerup.volume_db = -3.0
	sound_powerup.bus = "SFX"
	add_child(sound_powerup)
	
	# 3. Montar Cenário Dinamicamente
	_setup_environment()
	
	# 4. Criar HUD e Pistas
	_setup_rhythm_lanes()
	_setup_hud() # _setup_hud chama _update_hud_layout() internamente
	
	# 5. Iniciar Sequência de Entrada Cinemática
	_play_intro_animation()

func _setup_environment():
	# Fundo do Monte Kailash
	background = TextureRect.new()
	background.name = "Background"
	background.texture = load("res://assets/sprites/kailash_bg.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_SCALE
	background.size = Vector2(1152, 648)
	background.modulate = Color(0.75, 0.75, 0.9, 1.0) # Tom frio de tempestade
	add_child(background)
	
	# Rect de Relâmpago para flashes
	lightning_rect = ColorRect.new()
	lightning_rect.name = "LightningFlash"
	lightning_rect.color = Color.WHITE
	lightning_rect.size = Vector2(1152, 648)
	lightning_rect.visible = false
	lightning_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lightning_rect)
	
	# Plataformas de Pedra sob as personagens
	var sb_platform = StyleBoxFlat.new()
	sb_platform.bg_color = Color(0.12, 0.10, 0.08, 1.0)
	sb_platform.border_width_top = 2
	sb_platform.border_color = Color(0.85, 0.65, 0.25, 0.7) # Borda ouro antiga
	sb_platform.corner_radius_top_left = 6
	sb_platform.corner_radius_top_right = 6
	sb_platform.shadow_size = 10
	sb_platform.shadow_color = Color(0, 0, 0, 0.5)
	
	rudra_platform = Panel.new()
	rudra_platform.size = Vector2(180, 24)
	rudra_platform.position = Vector2(90, 435)
	rudra_platform.add_theme_stylebox_override("panel", sb_platform)
	add_child(rudra_platform)
	
	shiva_platform = Panel.new()
	shiva_platform.size = Vector2(180, 24)
	shiva_platform.position = Vector2(880, 435)
	shiva_platform.add_theme_stylebox_override("panel", sb_platform)
	add_child(shiva_platform)
	
	# Carregar Textura do Pato para a HUD e do Rudra Boss
	duck_tex = load("res://assets/sprites/Duck.png")
	rudra_boss_tex = load("res://assets/sprites/Trocas/novo_Rudra.png")
	
	# Carregar frames do jogador para Shiva
	var temp_player = load("res://scenes/apolo_python/player.tscn").instantiate()
	var player_sprite = temp_player.get_node("AnimatedSprite2D")
	var sprite_frames = player_sprite.sprite_frames
	
	# Rudra Boss (Sprite2D) - Começa invisível para a queda de trovão
	rudra_duck = Sprite2D.new()
	rudra_duck.name = "RudraDuck"
	rudra_duck.texture = rudra_boss_tex
	rudra_duck.position = Vector2(180, 363) # Ajustado Y para assentar na plataforma (não afundar/flutuar)
	rudra_duck.scale = Vector2(0.11, 0.11)
	rudra_duck.visible = false # Fica visível no impacto do trovão
	add_child(rudra_duck)
	
	# Pato Shiva (Jogador) - Começa no céu e invisível para a queda cinemática
	shiva_duck = AnimatedSprite2D.new()
	shiva_duck.name = "ShivaDuck"
	shiva_duck.sprite_frames = sprite_frames.duplicate()
	shiva_duck.animation = "Idle"
	shiva_duck.play("Idle")
	shiva_duck.position = Vector2(970, -250)
	shiva_duck.scale = Vector2(4.5, 4.5)
	shiva_duck.visible = false # Fica visível quando iniciar a sua queda
	shiva_duck.flip_h = true # virado para a esquerda (para o boss)
	add_child(shiva_duck)
	
	# Libertar o pato temporário
	temp_player.queue_free()
	
	# Ligar sinal para voltar ao Idle após animação de Hit
	shiva_duck.animation_finished.connect(func():
		if shiva_duck.animation == "Hit":
			shiva_duck.play("Idle")
	)

func _setup_rhythm_lanes():
	# Criar Recetores (targets) fixos no ecrã e esconder para o intro
	# Pista Rudra (Esquerda): X = 320, 370, 420, 470
	for i in range(4):
		var rec = arrow_scene.instantiate()
		rec.lane = i
		rec.is_receptor = true
		rec.is_player = false
		rec.position = Vector2(320 + i * 65, TARGET_Y)
		rec.modulate.a = 0.0 # Escondido para a animação inicial
		add_child(rec)
		rudra_receptors.append(rec)
		
	# Pista Shiva (Direita): X = 630, 680, 730, 780
	for i in range(4):
		var rec = arrow_scene.instantiate()
		rec.lane = i
		rec.is_receptor = true
		rec.is_player = true
		rec.position = Vector2(630 + i * 65, TARGET_Y)
		rec.modulate.a = 0.0 # Escondido para a animação inicial
		add_child(rec)
		shiva_receptors.append(rec)

func _setup_hud():
	hud_node = Control.new()
	hud_node.name = "HUD"
	hud_node.size = Vector2(1152, 648)
	hud_node.modulate.a = 0.0 # Escondido no início
	add_child(hud_node)
	hud_node.draw.connect(_draw_hud)
	
	# Fontes
	var cinzel_bold = _load_font(true)
	var _cinzel_reg = _load_font(false)
	
	# Painel de Estatísticas de Ritmo Premium
	stats_panel = Panel.new()
	stats_panel.name = "StatsPanel"
	stats_panel.size = Vector2(240, 54)
	stats_panel.position = Vector2(456, 38)
	
	var sb_stats = StyleBoxFlat.new()
	sb_stats.bg_color = Color(0.06, 0.04, 0.12, 0.78)
	sb_stats.border_width_left = 1
	sb_stats.border_width_top = 1
	sb_stats.border_width_right = 1
	sb_stats.border_width_bottom = 1
	sb_stats.border_color = Color(0.85, 0.65, 0.25, 0.6)
	sb_stats.corner_radius_top_left = 4
	sb_stats.corner_radius_top_right = 4
	sb_stats.corner_radius_bottom_left = 4
	sb_stats.corner_radius_bottom_right = 4
	stats_panel.add_theme_stylebox_override("panel", sb_stats)
	hud_node.add_child(stats_panel)
	
	# Label de Pontos
	score_label = Label.new()
	score_label.text = GameGlobals.get_text("ui_rhythm_score") + "0"
	score_label.position = Vector2(12, 6)
	score_label.add_theme_font_override("font", cinzel_bold)
	score_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	score_label.add_theme_constant_override("outline_size", 4)
	score_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_panel.add_child(score_label)
	
	# Label de Precisão
	accuracy_label = Label.new()
	accuracy_label.text = GameGlobals.get_text("ui_rhythm_accuracy") + "100%"
	accuracy_label.position = Vector2(120, 6)
	accuracy_label.add_theme_font_override("font", cinzel_bold)
	accuracy_label.add_theme_font_size_override("font_size", 12)
	accuracy_label.add_theme_color_override("font_color", Color(0.8, 0.95, 1.0))
	accuracy_label.add_theme_constant_override("outline_size", 4)
	accuracy_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_panel.add_child(accuracy_label)
	
	# Label de Combo
	combo_label = Label.new()
	combo_label.text = GameGlobals.get_text("ui_rhythm_combo") + "0"
	combo_label.position = Vector2(12, 28)
	combo_label.size = Vector2(216, 20)
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_label.add_theme_font_override("font", cinzel_bold)
	combo_label.add_theme_font_size_override("font_size", 13)
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25))
	combo_label.add_theme_constant_override("outline_size", 4)
	combo_label.add_theme_color_override("font_outline_color", Color.BLACK)
	stats_panel.add_child(combo_label)
	
	# Rating Text (PERFECT!, MISS!)
	rating_label = Label.new()
	rating_label.text = ""
	rating_label.position = Vector2(0, 260)
	rating_label.size = Vector2(1152, 60)
	rating_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating_label.add_theme_font_override("font", cinzel_bold)
	rating_label.add_theme_font_size_override("font_size", 30)
	rating_label.add_theme_constant_override("outline_size", 6)
	rating_label.add_theme_color_override("font_outline_color", Color.BLACK)
	rating_label.pivot_offset = Vector2(576, 30)
	hud_node.add_child(rating_label)
	
	# Criar etiquetas de indicação das pistas
	boss_lane_label = Label.new()
	boss_lane_label.text = GameGlobals.get_text("ui_rhythm_boss_lane")
	boss_lane_label.add_theme_font_override("font", cinzel_bold)
	boss_lane_label.add_theme_font_size_override("font_size", 10)
	boss_lane_label.add_theme_color_override("font_color", Color(0.95, 0.35, 0.35)) # Vermelho
	boss_lane_label.add_theme_constant_override("outline_size", 4)
	boss_lane_label.add_theme_color_override("font_outline_color", Color.BLACK)
	boss_lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_lane_label.size = Vector2(250, 20)
	hud_node.add_child(boss_lane_label)
	
	player_lane_label = Label.new()
	player_lane_label.text = GameGlobals.get_text("ui_rhythm_player_lane")
	player_lane_label.add_theme_font_override("font", cinzel_bold)
	player_lane_label.add_theme_font_size_override("font_size", 10)
	player_lane_label.add_theme_color_override("font_color", Color(0.35, 0.75, 1.0)) # Azul/Ciano
	player_lane_label.add_theme_constant_override("outline_size", 4)
	player_lane_label.add_theme_color_override("font_outline_color", Color.BLACK)
	player_lane_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	player_lane_label.size = Vector2(250, 20)
	hud_node.add_child(player_lane_label)
	
	_update_hud_layout()

# Atualiza layout dinâmico do HUD com base na direção das setas
func _update_hud_layout():
	if rhythm_scroll_down:
		# Setas descem: recetores no fundo, HUD no topo/baixo longe deles
		TARGET_Y = 490.0
		SPAWN_Y = 110.0
		tug_of_war_y = 610.0
		if is_instance_valid(stats_panel):
			stats_panel.position = Vector2(456, 538)
	else:
		# Setas sobem: recetores no topo, HUD bem acima deles
		TARGET_Y = 160.0
		SPAWN_Y = 580.0
		tug_of_war_y = 15.0
		if is_instance_valid(stats_panel):
			stats_panel.position = Vector2(456, 38)
	
	SPAWN_AHEAD_TIME = abs(SPAWN_Y - TARGET_Y) / SCROLL_SPEED
	
	# Atualizar posições dos recetores
	for i in range(4):
		if i < rudra_receptors.size():
			rudra_receptors[i].position.y = TARGET_Y
			rudra_receptors[i].queue_redraw()
		if i < shiva_receptors.size():
			shiva_receptors[i].position.y = TARGET_Y
			shiva_receptors[i].queue_redraw()
	
	# Atualizar posições das etiquetas de pista (para não ficarem na frente das setas)
	if is_instance_valid(boss_lane_label) and is_instance_valid(player_lane_label):
		var label_y: float
		if rhythm_scroll_down:
			label_y = TARGET_Y + 36.0 # Abaixo das setas (notas vêm de cima)
		else:
			label_y = TARGET_Y - 36.0 # Acima das setas (notas vêm de baixo)
		boss_lane_label.position = Vector2(320 + (65.0 * 1.5) - 125.0, label_y)
		player_lane_label.position = Vector2(630 + (65.0 * 1.5) - 125.0, label_y)
	
	if is_instance_valid(hud_node):
		hud_node.queue_redraw()

func _draw_hud():
	# Barra de HP Tug-of-War: posicionada dinamicamente com tug_of_war_y
	var bar_y = tug_of_war_y
	var bar_rect = Rect2(376, bar_y, 400, 16)
	
	# 1. Borda Dourada Estilizada
	var border_style = StyleBoxFlat.new()
	border_style.bg_color = Color(0.08, 0.05, 0.12, 1.0)
	border_style.border_width_left = 2
	border_style.border_width_top = 2
	border_style.border_width_right = 2
	border_style.border_width_bottom = 2
	border_style.border_color = Color(0.85, 0.65, 0.25, 1.0)
	border_style.corner_radius_top_left = 4
	border_style.corner_radius_top_right = 4
	border_style.corner_radius_bottom_left = 4
	border_style.corner_radius_bottom_right = 4
	border_style.shadow_size = 8
	border_style.shadow_color = Color(0, 0, 0, 0.6)
	hud_node.draw_style_box(border_style, Rect2(bar_rect.position.x - 3, bar_rect.position.y - 3, bar_rect.size.x + 6, bar_rect.size.y + 6))
	
	# 2. Lado Rudra (Vermelho)
	hud_node.draw_rect(bar_rect, Color(0.75, 0.15, 0.15, 1.0), true)
	
	# 3. Lado Shiva (Azul brilhante)
	var shiva_width = bar_rect.size.x * (tug_of_war / 100.0)
	var shiva_rect = Rect2(bar_rect.position.x + (bar_rect.size.x - shiva_width), bar_rect.position.y, shiva_width, bar_rect.size.y)
	hud_node.draw_rect(shiva_rect, Color(0.2, 0.6, 0.95, 1.0), true)
	
	# 4. Divisor Central
	hud_node.draw_line(Vector2(bar_rect.position.x + bar_rect.size.x/2, bar_rect.position.y - 2), Vector2(bar_rect.position.x + bar_rect.size.x/2, bar_rect.position.y + bar_rect.size.y + 2), Color(1.0, 0.85, 0.2, 1.0), 2.0)
	
	# 5. Ícones das Cabeças dos Patos (FNF Style) deslizando a meio
	var split_x = bar_rect.position.x + (1.0 - (tug_of_war / 100.0)) * bar_rect.size.x
	
	if duck_tex:
		var icon_y = bar_rect.position.y + bar_rect.size.y / 2 - 20.0
		
		# Círculos translúcidos de contraste atrás das cabeças
		hud_node.draw_circle(Vector2(split_x + 20, icon_y + 20), 20.0, Color(0.04, 0.08, 0.15, 0.65)) # Shiva BG
		hud_node.draw_circle(Vector2(split_x - 20, icon_y + 20), 20.0, Color(0.15, 0.04, 0.04, 0.65)) # Rudra BG
		
		# Shiva fica na direita, Rudra na esquerda do divisor
		# Shiva (Pato Amarelo, virado para a esquerda, compensado em X para centrar)
		var shiva_icon_rect = Rect2(split_x + 32, icon_y, -40, 40)
		# Rudra (Lorde da Tempestade, virado para a direita)
		var rudra_icon_rect = Rect2(split_x - 40, icon_y, 40, 40)
		
		hud_node.draw_texture_rect_region(duck_tex, shiva_icon_rect, Rect2(0, 0, 32, 32), Color.WHITE)
		if rudra_boss_tex:
			hud_node.draw_texture_rect(rudra_boss_tex, rudra_icon_rect, false)
	else:
		# Fallback com circulos coloridos se texturas falharem
		hud_node.draw_circle(Vector2(split_x, bar_rect.position.y + bar_rect.size.y/2), 12.0, Color(0.1, 0.08, 0.05, 1.0))
		hud_node.draw_circle(Vector2(split_x, bar_rect.position.y + bar_rect.size.y/2), 10.0, Color(1.0, 0.85, 0.2, 1.0) if tug_of_war > 50.0 else Color(0.85, 0.3, 0.3, 1.0))

func _play_intro_animation():
	_run_intro_step_1_narrator()

func _run_intro_step_1_narrator():
	cutscene_active = true
	shiva_duck.visible = false
	rudra_duck.visible = false
	
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_narrator", "text": "dialogue_narrator_shiva_1"},
		{"name": "char_narrator", "text": "dialogue_narrator_shiva_2"}
	]
	d.dialogue_finished.connect(_run_intro_step_2_shiva_reflect)
	add_child(d)

func _run_intro_step_2_shiva_reflect():
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_shiva", "text": "dialogue_shiva_reflect_1"},
		{"name": "char_shiva", "text": "dialogue_shiva_reflect_2"}
	]
	d.dialogue_finished.connect(_run_intro_step_3_shiva_fall)
	add_child(d)

func _run_intro_step_3_shiva_fall():
	# Shiva cai do céu!
	shiva_duck.position.y = -250.0
	shiva_duck.visible = true
	shiva_duck.play("Idle")
	
	var shiva_fall = create_tween()
	shiva_fall.tween_property(shiva_duck, "position:y", 388.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	shiva_fall.tween_callback(func():
		# Shiva aterra! Tremor, flash e som de impacto
		_shake_screen(10.0)
		_trigger_lightning_flash()
		sound_tap.play() # Som de aterragem
		shiva_duck.play("Hit")
		
		# Deformidade elástica (Squash & Stretch) do pato ao aterrar
		shiva_duck.scale = Vector2(4.5 * 1.35, 4.5 * 0.7)
		var shiva_recover = create_tween()
		shiva_recover.tween_property(shiva_duck, "scale", Vector2(4.5, 4.5), 0.22).set_trans(Tween.TRANS_BOUNCE)
		
		# Pausa dramática e avança para a fala de Shiva
		get_tree().create_timer(0.55).timeout.connect(_run_intro_step_4_shiva_callout)
	)

func _run_intro_step_4_shiva_callout():
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_shiva", "text": "dialogue_shiva_rudra_1"}
	]
	d.dialogue_finished.connect(_run_intro_step_5_rudra_respond)
	add_child(d)

func _run_intro_step_5_rudra_respond():
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_rudra", "text": "dialogue_rudra_shiva_1"}
	]
	d.dialogue_finished.connect(_run_intro_step_6_rudra_strike)
	add_child(d)

func _run_intro_step_6_rudra_strike():
	# Rudra aparece vindo de um trovão
	# Criar um raio visual (uma barra branca/ciano vertical na posição dele)
	var lightning_beam = ColorRect.new()
	lightning_beam.name = "RudraLightningBeam"
	lightning_beam.color = Color(0.8, 0.95, 1.0, 1.0)
	lightning_beam.size = Vector2(12, 435) # Do topo do ecrã até à plataforma
	lightning_beam.position = Vector2(180 - 6, 0)
	add_child(lightning_beam)
	
	# Disparar flash, tremor e som de trovão imediato
	_shake_screen(12.0)
	_trigger_lightning_flash_high()
	sound_hurt.play() # Som de impacto elétrico/explosão
	
	# Efeito de piscar do relâmpago: fazê-lo piscar 3 vezes muito rápido para parecer um raio real
	var flash_tween = create_tween()
	flash_tween.tween_property(lightning_beam, "modulate:a", 0.3, 0.04)
	flash_tween.tween_property(lightning_beam, "modulate:a", 1.0, 0.04)
	flash_tween.tween_property(lightning_beam, "modulate:a", 0.2, 0.04)
	flash_tween.tween_property(lightning_beam, "modulate:a", 1.0, 0.04)
	flash_tween.tween_property(lightning_beam, "modulate:a", 0.0, 0.25) # Desvanecimento final
	
	# Revelar Rudra surgindo/materializando-se no meio do raio!
	# Para isso, pomos Rudra como visível mas com opacidade zero, e fazemo-lo aparecer gradualmente
	rudra_duck.visible = true
	rudra_duck.modulate.a = 0.0
	
	var rudra_fade = create_tween()
	rudra_fade.tween_interval(0.1) # Começa logo a seguir ao pico do raio
	rudra_fade.tween_property(rudra_duck, "modulate:a", 1.0, 0.28) # Surge do meio do raio
	
	# Pequena animação de ressalto (bounce) de escala no Rudra
	rudra_duck.scale = Vector2.ZERO
	var rudra_bounce = create_tween()
	rudra_bounce.tween_interval(0.1)
	rudra_bounce.tween_property(rudra_duck, "scale", Vector2(0.11, 0.11), 0.35).set_trans(Tween.TRANS_BOUNCE)
	
	flash_tween.tween_callback(func():
		lightning_beam.queue_free()
		# Pausa dramática pequena pós-relâmpago e depois a última fala
		get_tree().create_timer(0.6).timeout.connect(_run_intro_step_7_shiva_final)
	)

func _run_intro_step_7_shiva_final():
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_shiva", "text": "dialogue_shiva_rudra_2"}
	]
	d.dialogue_finished.connect(_start_song)
	add_child(d)

func _start_song():
	cutscene_active = false
	
	# Configurar o chart
	notes_chart = _generate_chart(difficulty)
	total_chart_notes = 0
	for note in notes_chart:
		if note["is_player"] and note["type"] == "normal":
			total_chart_notes += 1
			
	note_index = 0
	active_notes.clear()
	
	# Fade in do HUD e recetores em 0.6s
	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(hud_node, "modulate:a", 1.0, 0.6)
	for rec in rudra_receptors:
		fade_tween.tween_property(rec, "modulate:a", 1.0, 0.6)
	for rec in shiva_receptors:
		fade_tween.tween_property(rec, "modulate:a", 1.0, 0.6)
	
	# Iniciar reprodução da música
	audio_player.play()
	time_begin = Time.get_ticks_usec()
	time_delay = AudioServer.get_time_to_next_mix() + AudioServer.get_output_latency()
	is_playing = true
	last_beat = -1
	tug_of_war = 50.0
	player_score = 0
	player_combo = 0
	player_max_combo = 0
	notes_hit = 0
	accuracy = 100.0
	timing_total = 0.0
	
	_update_hud_labels()

func _generate_chart(diff_level: int) -> Array:
	var chart = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 1337 # Chart consistente por semente
	
	var start_time = 3.5
	var end_time = 72.0
	var time = start_time
	
	while time < end_time:
		var section = 1
		if time < 22.0: section = 1
		elif time < 42.0: section = 2
		elif time < 60.0: section = 3
		else: section = 4
		
		var step = BEAT_TIME
		
		if diff_level == 0: # Fácil
			step = BEAT_TIME * (2.0 if rng.randf() > 0.5 else 1.0)
			var is_player_turn = (int(time / 4.0) % 2 == 1)
			chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": is_player_turn, "type": "normal"})
			
		elif diff_level == 1: # Normal
			step = BEAT_TIME * (1.0 if rng.randf() > 0.25 else 0.5)
			var is_player_turn = (int(time / 4.0) % 2 == 1) or section == 4
			
			chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": is_player_turn, "type": "normal"})
			
			if not is_player_turn and rng.randf() > 0.4:
				chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": false, "type": "normal"})
			
			if is_player_turn and rng.randf() > 0.4:
				chart.append({"time": time + 0.25, "lane": rng.randi_range(0, 3), "is_player": false, "type": "normal"})
				
			# Notas de Relâmpago (Normal: 12% na secção 3)
			if section == 3 and is_player_turn and rng.randf() < 0.12:
				chart.append({"time": time + 0.25, "lane": rng.randi_range(0, 3), "is_player": true, "type": "storm"})
				
		else: # Hard
			step = BEAT_TIME * (0.5 if rng.randf() > 0.3 else 0.25)
			
			chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": true, "type": "normal"})
			chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": false, "type": "normal"})
			
			if rng.randf() > 0.7:
				chart.append({"time": time, "lane": rng.randi_range(0, 3), "is_player": true, "type": "normal"})
				
			if (section == 3 or section == 4) and rng.randf() < 0.25:
				chart.append({"time": time + 0.125, "lane": rng.randi_range(0, 3), "is_player": true, "type": "storm"})
				
		time += step
		
	chart.sort_custom(func(a, b): return a["time"] < b["time"])
	return chart

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel") and is_playing and not get_tree().paused:
		_toggle_pause()
		return

	if not is_playing:
		return
		
	# Reduzir atordoamento do choque
	if stun_timer > 0.0:
		stun_timer -= delta
		if stun_timer <= 0.0:
			shiva_duck.modulate = Color.WHITE
			
	# Calcular tempo da música com alta precisão via relógio de áudio
	if audio_player.playing:
		var audio_time = audio_player.get_playback_position() + AudioServer.get_time_since_last_mix()
		audio_time -= AudioServer.get_output_latency()
		song_time = max(0.0, audio_time)
	else:
		song_time = 0.0
	
	# Verificar fim da música
	if song_time >= song_length or not audio_player.playing:
		_end_game(true) # Vitória
		return
		
	# Detetar batidas
	var current_beat = int(song_time / BEAT_TIME)
	if current_beat > last_beat:
		last_beat = current_beat
		_on_beat_hit()
		
	# Spawn de Notas do Chart
	while note_index < notes_chart.size() and notes_chart[note_index]["time"] - song_time < SPAWN_AHEAD_TIME:
		_spawn_note(notes_chart[note_index])
		note_index += 1
		
	# Mover notas ativas
	var notes_to_remove = []
	for note in active_notes:
		if not is_instance_valid(note):
			notes_to_remove.append(note)
			continue
			
		var t_diff = note.target_time - song_time
		var final_y = TARGET_Y
		
		if rhythm_scroll_down:
			final_y = TARGET_Y - (t_diff * SCROLL_SPEED)
		else:
			final_y = TARGET_Y + (t_diff * SCROLL_SPEED)
			
		note.position.y = final_y
		
		# Passou do limite sem ser tocada
		if t_diff < -0.16:
			if note.is_player and not note.was_hit and note.type != "storm":
				_handle_miss()
			notes_to_remove.append(note)
			note.queue_free()
			
		# IA do Boss (pista esquerda)
		elif not note.is_player and not note.was_hit and abs(t_diff) < 0.03:
			_handle_boss_play(note)
			
	for note in notes_to_remove:
		active_notes.erase(note)

func _spawn_note(note_data: Dictionary):
	var note = arrow_scene.instantiate()
	note.lane = note_data["lane"]
	note.target_time = note_data["time"]
	note.is_player = note_data["is_player"]
	note.type = note_data["type"]
	
	if note.is_player:
		note.position.x = 630.0 + note.lane * 65.0
	else:
		note.position.x = 320.0 + note.lane * 65.0
		
	note.position.y = SPAWN_Y
	add_child(note)
	active_notes.append(note)

func _on_beat_hit():
	_bounce_character(shiva_duck, true)
	_bounce_character(rudra_duck, false)
	
	var section = int(song_time / 20.0)
	if section >= 2:
		if randf() < 0.18:
			_trigger_lightning_flash()

func _bounce_character(duck: Node2D, is_shiva: bool):
	if not duck: return
	var base_scale = Vector2(4.5, 4.5) if is_shiva else Vector2(0.11, 0.11)
	
	if is_shiva and stun_timer > 0.0:
		return
		
	duck.scale = Vector2(base_scale.x * 1.15, base_scale.y * 0.82)
	var tween = create_tween()
	tween.tween_property(duck, "scale", base_scale, 0.15).set_trans(Tween.TRANS_SINE)

func _trigger_lightning_flash():
	lightning_rect.visible = true
	lightning_rect.modulate.a = 0.55
	
	var tween = create_tween()
	tween.tween_property(lightning_rect, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): lightning_rect.visible = false)
	
	_shake_screen(4.0)

func _trigger_lightning_flash_high():
	lightning_rect.visible = true
	lightning_rect.modulate.a = 0.95
	
	var tween = create_tween()
	tween.tween_property(lightning_rect, "modulate:a", 0.0, 0.45)
	tween.tween_callback(func(): lightning_rect.visible = false)

func _shake_screen(amount: float):
	var tween = create_tween()
	var start_pos = background.position
	for i in range(6):
		var offset = Vector2(randf_range(-amount, amount), randf_range(-amount, amount))
		tween.tween_property(background, "position", start_pos + offset, 0.03)
	tween.tween_property(background, "position", start_pos, 0.03)

func _handle_boss_play(note: Node2D):
	note.was_hit = true
	
	if randf() <= boss_hit_chance:
		rudra_receptors[note.lane].pulse()
		_animate_duck_hit(rudra_duck, note.lane, false)
		
		tug_of_war = max(0.0, tug_of_war - boss_note_dmg)
		hud_node.queue_redraw()
		
		if tug_of_war <= 0.0:
			_end_game(false)
	else:
		_bounce_character(rudra_duck, false)
		tug_of_war = min(100.0, tug_of_war + 0.3)
		hud_node.queue_redraw()

func _input(event):
	if not is_playing or cutscene_active or stun_timer > 0.0:
		return
		
	if event.is_echo() or not event.is_pressed():
		return
		
	var lane_pressed = -1
	
	if event.is_action_pressed("move_left"):
		lane_pressed = 0
	elif event.is_action_pressed("move_down"):
		lane_pressed = 1
	elif event.is_action_pressed("move_up") or event.is_action_pressed("jump"):
		lane_pressed = 2
	elif event.is_action_pressed("move_right"):
		lane_pressed = 3
		
	if lane_pressed != -1:
		_on_player_key_pressed(lane_pressed)
		get_viewport().set_input_as_handled()

func _on_player_key_pressed(lane: int):
	shiva_receptors[lane].pulse()
	
	var target_note = null
	var min_diff = 999.0
	
	for note in active_notes:
		if note.is_player and not note.was_hit and note.lane == lane:
			var diff = abs(note.target_time - song_time)
			if diff < 0.16 and diff < min_diff:
				min_diff = diff
				target_note = note
				
	if target_note:
		target_note.was_hit = true
		
		if target_note.type == "storm":
			_handle_shock_penalty(target_note)
		else:
			_handle_player_hit(target_note, min_diff)
		
		active_notes.erase(target_note)
		target_note.queue_free()
	else:
		tug_of_war = max(0.0, tug_of_war - 0.4)
		hud_node.queue_redraw()

func _handle_player_hit(note: Node2D, diff: float):
	notes_hit += 1
	player_combo += 1
	player_max_combo = max(player_max_combo, player_combo)
	
	var rating = ""
	var pts = 0
	var hp_heal = 0.0
	
	if diff < 0.05:
		rating = GameGlobals.get_text("ui_rhythm_perfect")
		rating_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.2))
		pts = 300
		hp_heal = heal_perfect
		sound_tap.play()
	elif diff < 0.10:
		rating = GameGlobals.get_text("ui_rhythm_good")
		rating_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.4))
		pts = 150
		hp_heal = heal_good
		sound_tap.play()
	else:
		rating = GameGlobals.get_text("ui_rhythm_okay")
		rating_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		pts = 50
		hp_heal = heal_okay
		sound_tap.play()
		
	player_score += pts
	tug_of_war = min(100.0, tug_of_war + hp_heal)
	
	timing_total += (1.0 - (diff / 0.16)) * 100.0
	accuracy = timing_total / notes_hit
	
	_show_rating(rating)
	_animate_duck_hit(shiva_duck, note.lane, true)
	_update_hud_labels()

func _handle_miss():
	player_combo = 0
	_show_rating(GameGlobals.get_text("ui_rhythm_miss"))
	rating_label.add_theme_color_override("font_color", Color(0.95, 0.25, 0.25))
	
	tug_of_war = max(0.0, tug_of_war - miss_dmg)
	
	sound_hurt.play()
	_update_hud_labels()
	
	if tug_of_war <= 0.0:
		_end_game(false)

func _handle_shock_penalty(_note: Node2D):
	player_combo = 0
	stun_timer = 0.55
	
	shiva_duck.modulate = Color(2.5, 2.0, 0.3, 1.0) # Amarelo elétrico
	
	_show_rating(GameGlobals.get_text("ui_rhythm_shock"))
	rating_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.0))
	
	var shock_damage = shock_dmg
	tug_of_war = max(0.0, tug_of_war - shock_damage)
	
	_trigger_lightning_flash_high()
	sound_hurt.play()
	_update_hud_labels()
	
	if tug_of_war <= 0.0:
		_end_game(false)

func _animate_duck_hit(duck: Node2D, lane: int, is_shiva: bool):
	if not duck: return
	
	if duck is AnimatedSprite2D:
		duck.play("Hit")
	var base_pos = Vector2(970, 388) if is_shiva else Vector2(180, 350)
	var offset = Vector2.ZERO
	
	match lane:
		0: offset = Vector2(-22, 0)
		1: offset = Vector2(0, 18)
		2: offset = Vector2(0, -22)
		3: offset = Vector2(22, 0)
		
	duck.position = base_pos + offset
	var tween = create_tween()
	tween.tween_property(duck, "position", base_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _show_rating(text: String):
	rating_label.text = text
	rating_label.scale = Vector2(1.4, 1.4)
	
	var tween = create_tween()
	tween.tween_property(rating_label, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_interval(0.4)
	tween.tween_callback(func(): if rating_label.text == text: rating_label.text = "")

func _update_hud_labels():
	score_label.text = GameGlobals.get_text("ui_rhythm_score") + str(player_score)
	combo_label.text = GameGlobals.get_text("ui_rhythm_combo") + str(player_combo)
	accuracy_label.text = GameGlobals.get_text("ui_rhythm_accuracy") + "%.1f" % accuracy + "%"
	
	if player_combo != last_displayed_combo:
		last_displayed_combo = player_combo
		if player_combo > 0:
			combo_label.pivot_offset = combo_label.size / 2
			combo_label.scale = Vector2(1.25, 1.25)
			var tw = create_tween()
			tw.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
	hud_node.queue_redraw()

func _toggle_pause():
	if is_instance_valid(pause_menu_instance):
		return
	get_tree().paused = true
	if is_instance_valid(audio_player):
		audio_player.stream_paused = true
	pause_start_time = Time.get_ticks_usec()
	pause_menu_instance = pause_menu_scene.instantiate()
	# Corrigir bug de desfasamento temporal ao despausar (Microsegundos)
	pause_menu_instance.tree_exited.connect(func():
		pause_menu_instance = null
		if is_instance_valid(audio_player):
			audio_player.stream_paused = false
		var pause_duration = Time.get_ticks_usec() - pause_start_time
		time_begin += pause_duration
		# Garantir que despausa a árvore ao voltar do menu de pausa
		get_tree().paused = false
	)
	get_parent().add_child(pause_menu_instance)

func _end_game(victory: bool):
	is_playing = false
	audio_player.stop()
	
	for note in active_notes:
		if is_instance_valid(note):
			note.queue_free()
	active_notes.clear()
	
	if victory:
		var dialogue = dialogue_scene.instantiate()
		dialogue.dialogue_list = [
			{"name": "char_shiva", "text": "dialogue_shiva_victory_1"},
			{"name": "char_shiva", "text": "dialogue_shiva_victory_2"}
		]
		dialogue.dialogue_finished.connect(_show_victory_screen)
		add_child(dialogue)
	else:
		_show_game_over_screen()

func _show_victory_screen():
	var ui_scene = load("res://scenes/game_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		add_child(ui)
		ui.get_node("VictoryScreen/Panel/TitleLabel").text = GameGlobals.get_text("victory_title_shiva")
		ui.victory_screen.show()
		get_tree().paused = true

func _show_game_over_screen():
	var ui_scene = load("res://scenes/game_ui.tscn")
	if ui_scene:
		var ui = ui_scene.instantiate()
		add_child(ui)
		ui.game_over_screen.show()
		get_tree().paused = true

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f
