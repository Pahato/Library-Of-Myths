extends Control

# =============================================================================
# THOR BATTLE — Motor de Combate RPG por Turnos (Slay the Spire)
# Livro III: Thor vs Jörmungandr
# =============================================================================

# --- Estados ---
enum BattleState { INTRO, PLAYER_TURN, ENEMY_TURN, ANIMATION, REWARD, VICTORY, DEFEAT }
var state: BattleState = BattleState.INTRO

# --- Dados do Jogador (Thor) ---
# Serão puxados do GameGlobals no _ready()
var player_hp: int = 80
var player_max_hp: int = 80
var player_block: int = 0
var player_energy: int = 3
var player_max_energy: int = 3
var player_strength: int = 0
var player_draw_count: int = 5
var player_block_per_turn: int = 0
var player_draw_bonus: int = 0
var player_gold: int = 0
var player_relics: Array = []

# --- Deck ---
var deck: Array = []          # Deck completo (referência)
var draw_pile: Array = []     # Pilha de compra
var hand: Array = []          # Mão do jogador
var discard_pile: Array = []  # Pilha de descarte
var powers_active: Array = [] # Poderes ativos (permanentes)
var combat_waves: Array = []  # Reforços / inimigos adicionais nesta fase

# --- Dados do Inimigo ---
var enemy_data: Dictionary = {}
var enemy_hp: int = 0
var enemy_max_hp: int = 0
var enemy_block: int = 0
var enemy_strength: int = 0
var enemy_vulnerable: int = 0
var enemy_intent: Dictionary = {}

# --- Referências de UI (criadas programaticamente) ---
var bg_rect: TextureRect = null
var player_sprite: TextureRect = null
var player_node: CharacterBody2D = null
var player_container: VBoxContainer = null
var enemy_container: VBoxContainer = null
var enemy_texture_rect: TextureRect = null
var dialogue_scene = preload("res://scenes/dialogue_box.tscn")
var player_vulnerable: int = 0
var anim_time: float = 0.0
var enemy_panel: Panel = null
var enemy_icon_label: Label = null

var player_hp_bar: ProgressBar = null
var player_hp_label: Label = null
var player_block_label: Label = null
var enemy_hp_bar: ProgressBar = null
var enemy_hp_label: Label = null
var enemy_block_label: Label = null
var enemy_name_label: Label = null
var enemy_intent_label: Label = null

var energy_label: Label = null
var end_turn_btn: Button = null
var card_container: HBoxContainer = null
var info_label: Label = null        # Feedback de ação (ex: "PERFEITO!", "-12 HP")
var deck_count_label: Label = null

# --- Configuração ---
var font_bold: FontFile = null
var font_reg: FontFile = null

const CARD_WIDTH: int = 110
const CARD_HEIGHT: int = 155
const ACCENT_COLOR = Color(0.3, 0.6, 1.0, 1.0)       # Azul elétrico
const GOLD_COLOR = Color(1.0, 0.85, 0.25, 1.0)         # Dourado
const DAMAGE_COLOR = Color(1.0, 0.3, 0.3, 1.0)         # Vermelho
const HEAL_COLOR = Color(0.3, 1.0, 0.5, 1.0)           # Verde
const BLOCK_COLOR = Color(0.5, 0.7, 1.0, 1.0)          # Azul claro
const ENERGY_COLOR = Color(1.0, 0.8, 0.2, 1.0)         # Amarelo energia

# =============================================================================
# INICIALIZAÇÃO
# =============================================================================

func _ready():
	# Carregar fontes
	font_bold = _load_font(true)
	font_reg = _load_font(false)
	
	# Inicializar deck starter
	_init_deck()
	
	# Inicializar inimigo do nó atual do mapa (ou draugr por padrão)
	_init_enemy("")
	
	# Construir toda a UI
	_build_ui()
	_update_all_ui()
	
	# Música temática do Thor
	if GameGlobals:
		GameGlobals.play_music("res://assets/music/time_for_adventure.mp3", -8.0)
	
	# Começar com a animação de entrada e história
	_play_intro_animation()

func _get_trans(pt: String, en: String) -> String:
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	return pt if is_pt else en

func _process(delta):
	anim_time += delta
	if enemy_panel and enemy_panel.visible:
		# Breathing pulse scale (wiggle)
		var pulse = 1.0 + sin(anim_time * 3.5) * 0.03
		enemy_panel.scale = Vector2(pulse, pulse)
		enemy_panel.pivot_offset = enemy_panel.size / 2
		
		# Slight slither tilt rotation
		var tilt = sin(anim_time * 2.2) * 2.0
		enemy_panel.rotation_degrees = tilt

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

func _init_deck():
	if GameGlobals and GameGlobals.thor_run_active:
		# Puxar dados da run atual
		player_hp = GameGlobals.thor_hp
		player_max_hp = GameGlobals.thor_max_hp
		player_gold = GameGlobals.thor_gold
		deck = GameGlobals.thor_deck.duplicate()
	else:
		# Teste isolado (fallback)
		player_hp = 80
		player_max_hp = 80
		player_gold = 0
		deck = ThorCardDatabase.get_starter_deck()
	
	draw_pile = deck.duplicate()
	draw_pile.shuffle()
	hand.clear()
	discard_pile.clear()

func _init_enemy(enemy_id: String = ""):
	var id_to_spawn = enemy_id
	var is_elite = false
	var is_boss = false
	combat_waves.clear()
	
	if id_to_spawn == "" and GameGlobals and GameGlobals.thor_run_active:
		# Encontrar o nó atual no mapa (corrigindo a leitura direta do dicionário de layers)
		var current_node = null
		if not GameGlobals.thor_map_data.is_empty():
			for layer_idx in GameGlobals.thor_map_data:
				var layer = GameGlobals.thor_map_data[layer_idx]
				for node in layer:
					if node.id == GameGlobals.thor_node_id:
						current_node = node
						break
				if current_node: break
				
		if current_node:
			# 0 = COMBAT, 1 = ELITE, 2 = REST, 3 = SHOP, 4 = BOSS
			var act = GameGlobals.thor_act
			if current_node.type == 4: # BOSS
				is_boss = true
				id_to_spawn = "jormungandr"
			elif current_node.type == 1: # ELITE
				is_elite = true
				var elites = ["hel_rainha", "fenrir_gigante"]
				id_to_spawn = elites.pick_random()
			else:
				# COMBAT normal — Spawna inimigo aleatório e tem 40% de chance de ter um segundo inimigo (onda de reforço)
				var normals = ThorEnemyDatabase.get_enemies_for_act(act)
				if normals.size() > 0:
					normals.shuffle()
					id_to_spawn = normals[0]
					
					# 40% de chance de spawnar um segundo inimigo como reforço (fase com múltiplos inimigos em ondas)
					if randf() < 0.4 and normals.size() > 1:
						combat_waves = [normals[1]]
				else:
					id_to_spawn = "draugr"
		else:
			id_to_spawn = "draugr"
	elif id_to_spawn == "":
		id_to_spawn = "draugr"
		
	enemy_data = ThorEnemyDatabase.get_enemy(id_to_spawn)
	var diff_mult = 1.0
	if GameGlobals:
		match GameGlobals.current_difficulty:
			GameGlobals.Difficulty.EASY: diff_mult = 0.8
			GameGlobals.Difficulty.HARD: diff_mult = 1.25
			
	var hp = int(randi_range(enemy_data.hp_min, enemy_data.hp_max) * diff_mult)
	enemy_hp = hp
	enemy_max_hp = hp
	enemy_block = 0
	enemy_strength = 0
	enemy_vulnerable = 0
	enemy_intent = ThorEnemyDatabase.get_random_intent(id_to_spawn)

# =============================================================================
# CONSTRUÇÃO DA UI (100% PROGRAMÁTICA)
# =============================================================================

func _build_ui():
	# --- Fundo ---
	var bg_color = ColorRect.new()
	bg_color.color = Color(0.05, 0.07, 0.12, 1.0) # Azul escuro nórdico
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	# Tentar carregar o fundo dinâmico por inimigo (Cenários folder) ou fallback geral
	var enemy_bg_map = {
		"draugr": "draugr_bg",
		"lobo_fenrir": "loboFenrir_bg",
		"gigante_gelo": "giganteGelo_bg",
		"corvos_hel": "corvosHel_bg",
		"esqueleto_viking": "esqueletoViking_bg",
		"hel_rainha": "helRainhaBoss_bg",
		"fenrir_gigante": "fenrirGignateBoss_bg",
		"jormungandr": "fenrirGignateBoss_bg"
	}
	var bg_file = enemy_bg_map.get(enemy_data.get("id", ""), "")
	var bg_tex = null
	if bg_file != "":
		var cenario_path = "res://assets/sprites/Sprites Thor/Cenários/" + bg_file + ".png"
		if ResourceLoader.exists(cenario_path):
			bg_tex = load(cenario_path)
	if bg_tex == null:
		bg_tex = load("res://assets/sprites/ThorJormungandr_bg.png")
	if bg_tex:
		bg_rect = TextureRect.new()
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.modulate = Color(1, 1, 1, 0.45)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_rect)
		
	# Vignette para profundidade e atmosfera premium
	var vignette = TextureRect.new()
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var grad = Gradient.new()
	grad.colors = [Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.85)]
	grad.offsets = [0.0, 1.0]
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_RADIAL
	grad_tex.fill_from = Vector2(0.5, 0.5)
	grad_tex.fill_to = Vector2(1.2, 1.2)
	
	vignette.texture = grad_tex
	add_child(vignette)
	
	# Plataformas Nórdicas de Basalto com brilho elétrico
	var sb_platform = StyleBoxFlat.new()
	sb_platform.bg_color = Color(0.08, 0.1, 0.14, 1.0) # Basalto azul-escuro nórdico
	sb_platform.border_width_top = 3
	sb_platform.border_color = Color(0.3, 0.75, 1.0, 0.85) # Carga elétrica/relâmpago
	sb_platform.corner_radius_top_left = 6
	sb_platform.corner_radius_top_right = 6
	sb_platform.shadow_size = 12
	sb_platform.shadow_color = Color(0.2, 0.6, 0.9, 0.35) # Glow ciano
	
	var player_platform = Panel.new()
	player_platform.size = Vector2(180, 20)
	player_platform.position = Vector2(180, 370)
	player_platform.add_theme_stylebox_override("panel", sb_platform)
	add_child(player_platform)
	
	var enemy_platform = Panel.new()
	enemy_platform.size = Vector2(180, 20)
	enemy_platform.position = Vector2(792, 370)
	enemy_platform.add_theme_stylebox_override("panel", sb_platform)
	add_child(enemy_platform)
	
	# --- Área de Combate (centro) ---
	_build_player_area()
	_build_enemy_area()
	
	# --- Barra inferior (cartas + energia) ---
	_build_bottom_bar()
	
	# --- Info Label (feedback central) ---
	info_label = Label.new()
	info_label.set_anchors_preset(Control.PRESET_CENTER)
	info_label.anchor_left = 0.5
	info_label.anchor_top = 0.35
	info_label.anchor_right = 0.5
	info_label.anchor_bottom = 0.35
	info_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_bold:
		info_label.add_theme_font_override("font", font_bold)
	info_label.add_theme_font_size_override("font_size", 28)
	info_label.add_theme_color_override("font_color", GOLD_COLOR)
	info_label.add_theme_constant_override("outline_size", 6)
	info_label.add_theme_color_override("font_outline_color", Color.BLACK)
	info_label.modulate.a = 0.0
	info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(info_label)

func _build_player_area():
	# Container do jogador (lado esquerdo) - Posicionado de forma absoluta sobre a cabeça (estilo HSR)
	player_container = VBoxContainer.new()
	player_container.layout_mode = 0
	player_container.position = Vector2(170, 195) # Posicionado 15px mais alto (Y=195) para ficar perfeitamente acima da cabeça sem sobrepor
	player_container.size = Vector2(200, 100)
	player_container.add_theme_constant_override("separation", 2)
	player_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(player_container)
	
	# Nome "THOR"
	var name_lbl = Label.new()
	name_lbl.text = "⚡ THOR"
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		name_lbl.add_theme_font_override("font", font_bold)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.add_theme_color_override("font_color", ACCENT_COLOR)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	player_container.add_child(name_lbl)
	
	player_sprite = TextureRect.new() # Mantido apenas para compatibilidade
	
	# HP Bar
	player_hp_bar = ProgressBar.new()
	player_hp_bar.custom_minimum_size = Vector2(140, 16)
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	player_hp_bar.show_percentage = false
	
	# Estilo premium da barra de vida com moldura dourada
	var hp_sb = StyleBoxFlat.new()
	hp_sb.bg_color = Color(0.04, 0.04, 0.06, 0.85)
	hp_sb.border_width_left = 1
	hp_sb.border_width_top = 1
	hp_sb.border_width_right = 1
	hp_sb.border_width_bottom = 1
	hp_sb.border_color = GOLD_COLOR
	hp_sb.corner_radius_top_left = 5
	hp_sb.corner_radius_top_right = 5
	hp_sb.corner_radius_bottom_left = 5
	hp_sb.corner_radius_bottom_right = 5
	player_hp_bar.add_theme_stylebox_override("background", hp_sb)
	
	var hp_fill = StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.12, 0.75, 0.35, 1.0) # Emerald Green
	hp_fill.corner_radius_top_left = 4
	hp_fill.corner_radius_top_right = 4
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	player_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	hp_fill.corner_radius_bottom_left = 4
	hp_fill.corner_radius_bottom_right = 4
	player_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	player_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	player_container.add_child(player_hp_bar)
	
	# HP Label
	player_hp_label = Label.new()
	player_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		player_hp_label.add_theme_font_override("font", font_reg)
	player_hp_label.add_theme_font_size_override("font_size", 11)
	player_hp_label.add_theme_color_override("font_color", Color.WHITE)
	player_container.add_child(player_hp_label)
	
	# Block Label
	player_block_label = Label.new()
	player_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		player_block_label.add_theme_font_override("font", font_reg)
	player_block_label.add_theme_font_size_override("font_size", 11)
	player_block_label.add_theme_color_override("font_color", BLOCK_COLOR)
	player_container.add_child(player_block_label)

func _build_enemy_area():
	# Jogador Visível (Pato - player.tscn)
	var player_scene = preload("res://scenes/player.tscn")
	player_node = player_scene.instantiate()
	player_node.name = "Player"
	player_node.is_cutscene = true
	player_node.current_god_mode = 2 # GodMode.THOR = 2
	player_node.position = Vector2(270, 328) # Alinhado com a plataforma (pés assentam no rebordo)
	
	# Desativar física, inputs da cena e UI padrão do jogador
	player_node.set_physics_process(false)
	player_node.set_process(false)
	player_node.set_process_input(false)
	player_node.set_process_unhandled_input(false)
	
	# Remover a câmara se ela existir para não chocar com a UI
	for child in player_node.get_children():
		if child is Camera2D:
			child.queue_free()
			
	add_child(player_node)
	
	# Iniciar animação Idle e definir escala
	var anim_sprite = player_node.get_node_or_null("AnimatedSprite2D")
	if anim_sprite:
		anim_sprite.play("Idle")
		anim_sprite.scale = Vector2(3.5, 3.5)
		anim_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	
	# Painel visual do inimigo — posicionado sobre a plataforma (Y=370)
	enemy_panel = Panel.new()
	enemy_panel.custom_minimum_size = Vector2(140, 140)
	enemy_panel.position = Vector2(812, 230)
	enemy_panel.size = Vector2(140, 140)
	enemy_panel.visible = false # Oculto por padrão até a animação de entrada iniciar
	add_child(enemy_panel)
	
	# Sprite de textura (carregado dinamicamente)
	enemy_texture_rect = TextureRect.new()
	enemy_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	enemy_texture_rect.custom_minimum_size = Vector2(130, 130)
	enemy_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	enemy_panel.add_child(enemy_texture_rect)
	
	# Ícone do inimigo (emoji grande - fallback se não houver textura)
	enemy_icon_label = Label.new()
	enemy_icon_label.set_anchors_preset(Control.PRESET_CENTER)
	enemy_icon_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	enemy_icon_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	enemy_icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy_icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	enemy_icon_label.add_theme_font_size_override("font_size", 48)
	enemy_panel.add_child(enemy_icon_label)
	
	# Container do inimigo (topo da tela - estilo Boss de Honkai Star Rail, perfeitamente centralizado)
	enemy_container = VBoxContainer.new()
	enemy_container.layout_mode = 1 # Usar âncoras para alinhamento robusto
	enemy_container.anchor_left = 0.5
	enemy_container.anchor_right = 0.5
	enemy_container.anchor_top = 0.0
	enemy_container.anchor_bottom = 0.0
	enemy_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	enemy_container.size = Vector2(320, 120)
	enemy_container.offset_left = -160
	enemy_container.offset_right = 160
	enemy_container.offset_top = 25
	enemy_container.offset_bottom = 145
	enemy_container.add_theme_constant_override("separation", 2)
	enemy_container.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(enemy_container)
	
	# Nome do inimigo
	enemy_name_label = Label.new()
	enemy_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		enemy_name_label.add_theme_font_override("font", font_bold)
	enemy_name_label.add_theme_font_size_override("font_size", 14)
	enemy_name_label.add_theme_color_override("font_color", DAMAGE_COLOR)
	enemy_name_label.add_theme_constant_override("outline_size", 3)
	enemy_name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	enemy_container.add_child(enemy_name_label)
	
	# HP Bar do inimigo (estilo boss HSR: larga no topo da tela, preenche os 320px do container)
	enemy_hp_bar = ProgressBar.new()
	enemy_hp_bar.custom_minimum_size = Vector2(320, 16)
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_hp
	enemy_hp_bar.show_percentage = false
	
	# Estilo premium da barra de vida com moldura vermelha
	var enemy_hp_sb = StyleBoxFlat.new()
	enemy_hp_sb.bg_color = Color(0.04, 0.04, 0.06, 0.85)
	enemy_hp_sb.border_width_left = 1
	enemy_hp_sb.border_width_top = 1
	enemy_hp_sb.border_width_right = 1
	enemy_hp_sb.border_width_bottom = 1
	enemy_hp_sb.border_color = Color(0.8, 0.2, 0.2, 0.8) # Red border
	enemy_hp_sb.corner_radius_top_left = 5
	enemy_hp_sb.corner_radius_top_right = 5
	enemy_hp_sb.corner_radius_bottom_left = 5
	enemy_hp_sb.corner_radius_bottom_right = 5
	enemy_hp_bar.add_theme_stylebox_override("background", enemy_hp_sb)
	
	var enemy_hp_fill = StyleBoxFlat.new()
	enemy_hp_fill.bg_color = Color(0.85, 0.15, 0.15, 1.0) # Crimson Red
	enemy_hp_fill.corner_radius_top_left = 4
	enemy_hp_fill.corner_radius_top_right = 4
	enemy_hp_fill.corner_radius_bottom_left = 4
	enemy_hp_fill.corner_radius_bottom_right = 4
	enemy_hp_bar.add_theme_stylebox_override("fill", enemy_hp_fill)
	enemy_hp_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	enemy_container.add_child(enemy_hp_bar)
	
	# HP Label
	enemy_hp_label = Label.new()
	enemy_hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		enemy_hp_label.add_theme_font_override("font", font_reg)
	enemy_hp_label.add_theme_font_size_override("font_size", 11)
	enemy_hp_label.add_theme_color_override("font_color", Color.WHITE)
	enemy_container.add_child(enemy_hp_label)
	
	# Block Label
	enemy_block_label = Label.new()
	enemy_block_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		enemy_block_label.add_theme_font_override("font", font_reg)
	enemy_block_label.add_theme_font_size_override("font_size", 11)
	enemy_block_label.add_theme_color_override("font_color", BLOCK_COLOR)
	enemy_container.add_child(enemy_block_label)

func _build_bottom_bar():
	# Painel inferior escuro
	var bottom_panel = Panel.new()
	bottom_panel.layout_mode = 1
	bottom_panel.anchor_left = 0.0
	bottom_panel.anchor_top = 0.68
	bottom_panel.anchor_right = 1.0
	bottom_panel.anchor_bottom = 1.0
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.08, 0.92)
	sb.border_width_top = 2
	sb.border_color = ACCENT_COLOR.darkened(0.4)
	bottom_panel.add_theme_stylebox_override("panel", sb)
	add_child(bottom_panel)
	
	# --- Energia (lado esquerdo) ---
	var energy_container = VBoxContainer.new()
	energy_container.layout_mode = 1
	energy_container.anchor_left = 0.02
	energy_container.anchor_top = 0.1
	energy_container.anchor_right = 0.12
	energy_container.anchor_bottom = 0.9
	energy_container.alignment = BoxContainer.ALIGNMENT_CENTER
	energy_container.add_theme_constant_override("separation", 4)
	bottom_panel.add_child(energy_container)
	
	energy_label = Label.new()
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		energy_label.add_theme_font_override("font", font_bold)
	energy_label.add_theme_font_size_override("font_size", 28)
	energy_label.add_theme_color_override("font_color", ENERGY_COLOR)
	energy_label.add_theme_constant_override("outline_size", 4)
	energy_label.add_theme_color_override("font_outline_color", Color.BLACK)
	energy_container.add_child(energy_label)
	
	var energy_title = Label.new()
	energy_title.text = _get_trans("ENERGIA", "ENERGY")
	energy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		energy_title.add_theme_font_override("font", font_reg)
	energy_title.add_theme_font_size_override("font_size", 9)
	energy_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	energy_container.add_child(energy_title)
	
	# Deck count
	deck_count_label = Label.new()
	deck_count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		deck_count_label.add_theme_font_override("font", font_reg)
	deck_count_label.add_theme_font_size_override("font_size", 9)
	deck_count_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	energy_container.add_child(deck_count_label)
	
	# --- Container de Cartas (centro) ---
	card_container = HBoxContainer.new()
	card_container.layout_mode = 1
	card_container.anchor_left = 0.13
	card_container.anchor_top = 0.05
	card_container.anchor_right = 0.82
	card_container.anchor_bottom = 0.95
	card_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card_container.alignment = BoxContainer.ALIGNMENT_CENTER
	card_container.add_theme_constant_override("separation", 8)
	bottom_panel.add_child(card_container)
	
	# --- Botão Terminar Turno (lado direito) ---
	var btn_container = VBoxContainer.new()
	btn_container.layout_mode = 1
	btn_container.anchor_left = 0.83
	btn_container.anchor_top = 0.1
	btn_container.anchor_right = 0.98
	btn_container.anchor_bottom = 0.9
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 8)
	bottom_panel.add_child(btn_container)
	
	end_turn_btn = Button.new()
	end_turn_btn.text = _get_trans("Terminar\nTurno", "End\nTurn")
	end_turn_btn.custom_minimum_size = Vector2(100, 50)
	if font_bold:
		end_turn_btn.add_theme_font_override("font", font_bold)
	end_turn_btn.add_theme_font_size_override("font_size", 11)
	var btn_sb = StyleBoxFlat.new()
	btn_sb.bg_color = ACCENT_COLOR.darkened(0.5)
	btn_sb.border_width_left = 2
	btn_sb.border_width_top = 2
	btn_sb.border_width_right = 2
	btn_sb.border_width_bottom = 2
	btn_sb.border_color = ACCENT_COLOR
	btn_sb.corner_radius_top_left = 6
	btn_sb.corner_radius_top_right = 6
	btn_sb.corner_radius_bottom_left = 6
	btn_sb.corner_radius_bottom_right = 6
	end_turn_btn.add_theme_stylebox_override("normal", btn_sb)
	var btn_hover = btn_sb.duplicate()
	btn_hover.bg_color = ACCENT_COLOR.darkened(0.3)
	end_turn_btn.add_theme_stylebox_override("hover", btn_hover)
	end_turn_btn.add_theme_color_override("font_color", Color.WHITE)
	end_turn_btn.pressed.connect(_on_end_turn_pressed)
	btn_container.add_child(end_turn_btn)
	
	# Discard count removido a pedido do usuário

# =============================================================================
# LÓGICA DE COMBATE
# =============================================================================

func _start_battle():
	player_block = 0
	player_energy = player_max_energy
	_update_all_ui()
	_start_player_turn()

func _start_player_turn():
	state = BattleState.PLAYER_TURN
	
	# Decrementar Vulnerável do jogador
	if player_vulnerable > 0:
		player_vulnerable -= 1
	
	# Reset block do jogador
	player_block = 0
	
	# Aplicar poderes passivos
	if player_block_per_turn > 0:
		player_block += player_block_per_turn
	
	# Restaurar energia
	player_energy = player_max_energy
	
	# Comprar cartas até atingir o limite da mão (draw_amount)
	var draw_limit = player_draw_count + player_draw_bonus
	while hand.size() < draw_limit:
		if draw_pile.is_empty() and discard_pile.is_empty():
			break
		_draw_card()
	
	_update_all_ui()
	_show_info(_get_trans("Teu Turno!", "Your Turn!"), ACCENT_COLOR)
	
	# Ativar botão
	end_turn_btn.disabled = false

func _draw_card():
	if draw_pile.is_empty():
		# Reciclar descarte
		draw_pile = discard_pile.duplicate()
		discard_pile.clear()
		draw_pile.shuffle()
	
	if draw_pile.is_empty():
		return  # Sem cartas
	
	var card_id = draw_pile.pop_back()
	hand.append(card_id)

func _play_card(index: int):
	if state != BattleState.PLAYER_TURN:
		return
	if index < 0 or index >= hand.size():
		return
	
	var card_id = hand[index]
	var card = ThorCardDatabase.get_card(card_id)
	
	if card.is_empty():
		return
	
	# Verificar energia
	if card.cost > player_energy:
		_show_info(_get_trans("Sem Energia!", "No Energy!"), DAMAGE_COLOR)
		return
	
	# Gastar energia
	player_energy -= card.cost
	
	# Aplicar efeitos
	_apply_card_effects(card)
	
	# Remover da mão e adicionar ao descarte (POWERs não vão para o descarte)
	hand.remove_at(index)
	if card.type != ThorCardDatabase.CardType.POWER:
		discard_pile.append(card_id)
	
	# Verificar se inimigo morreu (ou se há reforços/ondas)
	if enemy_hp <= 0:
		if combat_waves.size() > 0:
			_spawn_next_wave()
		else:
			_on_enemy_defeated()
		return
	
	# Atualizar UI
	_rebuild_hand_ui()
	_update_all_ui()
	
	# Feedback sonoro
	if GameGlobals:
		GameGlobals.play_click_sound()

func _apply_card_effects(card: Dictionary):
	var effect = card.get("effect", {})
	
	# --- Dano ---
	if effect.has("damage"):
		var base_dmg: int = effect.damage
		var hits: int = effect.get("hits", 1)
		
		# Escalar com Força
		if effect.has("damage_per_strength"):
			base_dmg += player_strength * effect.damage_per_strength
		else:
			base_dmg += player_strength
		
		# Vulnerável
		if enemy_vulnerable > 0:
			base_dmg = int(base_dmg * 1.5)
		
		# Reproduzir SFX e VFX apropriados de acordo com a carta
		var is_lightning = card.id.contains("trovao") or card.id.contains("relampago") or card.id.contains("tempestade") or card.id.contains("mjolnir")
		if is_lightning:
			_play_sfx("explosion", 0.95, -6.0) # Som de trovão
			# _play_lightning_vfx() # Clarão removido para conforto visual
		else:
			_play_sfx("shoot", 1.25, -4.0) # Som de golpe normal
		
		for i in range(hits):
			_deal_damage_to_enemy(base_dmg)
			if hits > 1:
				await get_tree().create_timer(0.12).timeout # Pequeno delay entre hits múltiplos
	
	# --- Escudo ---
	if effect.has("block"):
		player_block += effect.block
		_show_info("🛡 +" + str(effect.block), BLOCK_COLOR)
		_play_sfx("clink", 1.1, -4.0) # Clink metálico
	
	# --- Força ---
	if effect.has("strength"):
		player_strength += effect.strength
		_show_info("💪 +" + str(effect.strength) + _get_trans(" Força", " Strength"), GOLD_COLOR)
		_play_sfx("power_up", 1.2, -6.0)
	
	# --- Vulnerável (ao inimigo) ---
	if effect.has("vulnerable"):
		enemy_vulnerable += effect.vulnerable
		_show_info(_get_trans("Vulnerável! (", "Vulnerable! (") + str(effect.vulnerable) + _get_trans(" turnos)", " turns)"), DAMAGE_COLOR)
		_play_sfx("shoot", 0.8, -6.0)
	
	# --- Comprar cartas ---
	if effect.has("draw"):
		for i in range(effect.draw):
			_draw_card()
		_rebuild_hand_ui()
	
	# --- Cura ---
	if effect.has("heal"):
		player_hp = mini(player_hp + effect.heal, player_max_hp)
		_show_info("❤️ +" + str(effect.heal) + " HP", HEAL_COLOR)
		_play_sfx("power_up", 0.95, -6.0) # Cura som
	
	# --- Auto-dano ---
	if effect.has("self_damage"):
		player_hp -= effect.self_damage
		_play_sfx("hurt", 1.1, -4.0)
	
	# --- Ganhar energia ---
	if effect.has("energy"):
		player_energy += effect.energy
		_show_info("⚡ +" + str(effect.energy) + _get_trans(" Energia", " Energy"), ENERGY_COLOR)
		_play_sfx("power_up", 1.3, -6.0)
	
	# --- Perder escudo ---
	if effect.has("lose_block"):
		player_block = maxi(0, player_block - effect.lose_block)
	
	# --- Enfraquecer inimigo ---
	if effect.has("weaken"):
		enemy_strength = maxi(0, enemy_strength - effect.weaken)
		_show_info(_get_trans("👎 Inimigo -", "👎 Enemy -") + str(effect.weaken) + _get_trans(" Força", " Strength"), ACCENT_COLOR)
		_play_sfx("clink", 0.75, -6.0)
	
	# --- Poderes (efeitos permanentes) ---
	if card.type == ThorCardDatabase.CardType.POWER:
		if effect.has("block_per_turn"):
			player_block_per_turn += effect.block_per_turn
			_show_info("🛡 +" + str(effect.block_per_turn) + _get_trans(" Escudo/Turno", " Block/Turn"), BLOCK_COLOR)
		if effect.has("draw_per_turn"):
			player_draw_bonus += effect.draw_per_turn
			_show_info(_get_trans("🃏 +1 Carta/Turno", "🃏 +1 Card/Turn"), GOLD_COLOR)
		powers_active.append(card.id)

func _deal_damage_to_enemy(damage: int):
	var actual_dmg = damage
	
	# Aplicar contra escudo do inimigo
	if enemy_block > 0:
		if enemy_block >= actual_dmg:
			enemy_block -= actual_dmg
			actual_dmg = 0
			_play_sfx("clink", 0.9, -2.0) # Defendido!
		else:
			actual_dmg -= enemy_block
			enemy_block = 0
			_play_sfx("clink", 0.9, -2.0) # Escudo quebra
	
	enemy_hp = maxi(0, enemy_hp - actual_dmg)
	
	if actual_dmg > 0:
		_show_info("⚔️ " + str(actual_dmg) + _get_trans(" dano!", " damage!"), DAMAGE_COLOR)
		_shake_node(enemy_panel)
		_play_spark_vfx(enemy_panel.global_position + enemy_panel.size / 2) # Partículas!

func _deal_damage_to_player(damage: int):
	var actual_dmg = damage
	
	if player_vulnerable > 0:
		actual_dmg = int(actual_dmg * 1.5)
	
	# Aplicar contra escudo do jogador
	if player_block > 0:
		if player_block >= actual_dmg:
			player_block -= actual_dmg
			actual_dmg = 0
			_play_sfx("clink", 1.1, -2.0) # Defendido!
		else:
			actual_dmg -= player_block
			player_block = 0
			_play_sfx("clink", 1.1, -2.0) # Escudo quebra
	
	player_hp = maxi(0, player_hp - actual_dmg)
	
	if actual_dmg > 0:
		_show_info("💥 -" + str(actual_dmg) + " HP!", DAMAGE_COLOR)
		_play_sfx("hurt", 1.0, -2.0) # Som de dano sofrido
		if player_node:
			_shake_node(player_node)

# =============================================================================
# TURNO DO INIMIGO
# =============================================================================

func _on_end_turn_pressed():
	if state != BattleState.PLAYER_TURN:
		return
	
	if GameGlobals:
		GameGlobals.play_click_sound()
	
	end_turn_btn.disabled = true
	
	# NÃO descartar a mão! O jogador mantém as cartas que não jogou para o próximo turno.
	# Apenas atualiza a UI
	_rebuild_hand_ui()
	
	# Iniciar turno do inimigo
	_start_enemy_turn()

func _start_enemy_turn():
	state = BattleState.ENEMY_TURN
	
	# Reset block do inimigo
	enemy_block = 0
	
	_show_info(_get_trans("Turno do Inimigo...", "Enemy Turn..."), DAMAGE_COLOR)
	_update_all_ui()
	
	# Pequena pausa para feedback visual
	var timer = get_tree().create_timer(0.8)
	timer.timeout.connect(_execute_enemy_intent)

func _execute_enemy_intent():
	if state != BattleState.ENEMY_TURN:
		return
	
	var intent = enemy_intent
	
	match intent.type:
		ThorEnemyDatabase.IntentType.ATTACK:
			var dmg: int = intent.get("damage", 0) + enemy_strength
			
			# Dificuldade
			if GameGlobals:
				match GameGlobals.current_difficulty:
					GameGlobals.Difficulty.EASY: dmg = int(dmg * 0.8)
					GameGlobals.Difficulty.HARD: dmg = int(dmg * 1.25)
					
			var hits: int = intent.get("hits", 1)
			for i in range(hits):
				_deal_damage_to_player(dmg)
			if intent.has("vulnerable") and intent.vulnerable > 0:
				player_vulnerable += intent.vulnerable
				_show_info(_get_trans("Vulnerável! (", "Vulnerable! (") + str(intent.vulnerable) + _get_trans(" turnos)", " turns)"), DAMAGE_COLOR)
		
		ThorEnemyDatabase.IntentType.DEFEND:
			var block_val: int = intent.get("block", 0)
			enemy_block += block_val
			_show_info(_get_trans("🛡 Inimigo +", "🛡 Enemy +") + str(block_val) + _get_trans(" Escudo", " Block"), BLOCK_COLOR)
		
		ThorEnemyDatabase.IntentType.BUFF:
			if intent.has("strength") and intent.strength > 0:
				enemy_strength += intent.strength
				_show_info(_get_trans("💪 Inimigo +", "💪 Enemy +") + str(intent.strength) + _get_trans(" Força!", " Strength!"), DAMAGE_COLOR)
			if intent.has("heal") and intent.heal > 0:
				enemy_hp = mini(enemy_hp + intent.heal, enemy_max_hp)
				_show_info(_get_trans("❤️ Inimigo curou ", "❤️ Enemy healed ") + str(intent.heal) + " HP!", HEAL_COLOR)
		
		ThorEnemyDatabase.IntentType.ATTACK_DEFEND:
			var dmg: int = intent.get("damage", 0) + enemy_strength
			
			# Dificuldade
			if GameGlobals:
				match GameGlobals.current_difficulty:
					GameGlobals.Difficulty.EASY: dmg = int(dmg * 0.8)
					GameGlobals.Difficulty.HARD: dmg = int(dmg * 1.25)
					
			_deal_damage_to_player(dmg)
			var block_val: int = intent.get("block", 0)
			enemy_block += block_val
			_show_info(_get_trans("🛡 Inimigo +", "🛡 Enemy +") + str(block_val) + _get_trans(" Escudo", " Block"), BLOCK_COLOR)
		
		ThorEnemyDatabase.IntentType.DEBUFF:
			if intent.has("vulnerable") and intent.vulnerable > 0:
				player_vulnerable += intent.vulnerable
				_show_info(_get_trans("Vulnerável! (", "Vulnerable! (") + str(intent.vulnerable) + _get_trans(" turnos)", " turns)"), DAMAGE_COLOR)
	
	# Reduzir vulnerável do inimigo
	if enemy_vulnerable > 0:
		enemy_vulnerable -= 1
	
	_update_all_ui()
	
	# Verificar se jogador morreu
	if player_hp <= 0:
		_on_player_defeated()
		return
	
	# Novo intent para o próximo turno
	enemy_intent = ThorEnemyDatabase.get_random_intent(enemy_data.id)
	_update_all_ui()
	
	# Pausa antes de passar turno ao jogador
	var timer = get_tree().create_timer(0.6)
	timer.timeout.connect(_start_player_turn)

# =============================================================================
# VITÓRIA / DERROTA
# =============================================================================

func _on_enemy_defeated():
	state = BattleState.VICTORY
	_show_info(_get_trans("VITÓRIA!", "VICTORY!"), GOLD_COLOR)
	_update_all_ui()
	
	# Pausa e depois mostrar ecrã de vitória (ou diálogo final se for Boss)
	if enemy_data.get("type", 0) == ThorEnemyDatabase.EnemyType.BOSS:
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func():
			var d = dialogue_scene.instantiate()
			d.dialogue_list = [
				{"name": "char_narrator", "text": "dialogue_thor_victory_1"},
				{"name": "char_thor", "text": "dialogue_thor_victory_2"}
			]
			d.dialogue_finished.connect(_show_victory_screen)
			add_child(d)
		)
	else:
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(_show_victory_screen)

func _show_victory_screen():
	var is_boss = (enemy_data.get("type", 0) == ThorEnemyDatabase.EnemyType.BOSS)
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	# Overlay escuro
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.85)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.1
	vbox.anchor_top = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_bottom = 0.9
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 24)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	var title = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", GOLD_COLOR)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(title)
	
	if is_boss:
		title.text = "🏆 VITÓRIA DE THOR! 🏆" if is_pt else "🏆 THOR'S VICTORY! 🏆"
		
		var desc = Label.new()
		desc.text = "Concluíste a lenda de Thor e salvaste Midgard do Ragnarök!" if is_pt else "You have completed the legend of Thor and saved Midgard from Ragnarök!"
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if font_reg:
			desc.add_theme_font_override("font", font_reg)
		desc.add_theme_font_size_override("font_size", 16)
		desc.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		vbox.add_child(desc)
	else:
		title.text = "⚡ VITÓRIA! ⚡" if is_pt else "⚡ VICTORY! ⚡"
		
		# Determinar Recompensas (Rebalanceado: mais ouro para run mais curta)
		var reward_gold = randi_range(35, 55)
		if enemy_data.get("type", 0) == ThorEnemyDatabase.EnemyType.ELITE:
			reward_gold = randi_range(70, 95)
			
		var reward_cards = _generate_card_rewards()
		
		# Recompensas Label
		var rewards_title = Label.new()
		rewards_title.text = "Recompensas:" if is_pt else "Rewards:"
		rewards_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if font_reg:
			rewards_title.add_theme_font_override("font", font_reg)
		rewards_title.add_theme_font_size_override("font_size", 16)
		rewards_title.add_theme_color_override("font_color", Color.WHITE)
		vbox.add_child(rewards_title)
		
		# Ouro
		var gold_btn = Button.new()
		gold_btn.text = "+ " + str(reward_gold) + " Ouro" if is_pt else "+ " + str(reward_gold) + " Gold"
		gold_btn.custom_minimum_size = Vector2(250, 40)
		gold_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		if font_bold:
			gold_btn.add_theme_font_override("font", font_bold)
		gold_btn.add_theme_font_size_override("font_size", 14)
		gold_btn.add_theme_color_override("font_color", GOLD_COLOR)
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.15, 0.05, 0.9)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		sb.border_color = GOLD_COLOR
		sb.corner_radius_top_left = 6
		sb.corner_radius_top_right = 6
		sb.corner_radius_bottom_left = 6
		sb.corner_radius_bottom_right = 6
		gold_btn.add_theme_stylebox_override("normal", sb)
		var sb_h = sb.duplicate()
		sb_h.bg_color = Color(0.3, 0.25, 0.1, 0.9)
		gold_btn.add_theme_stylebox_override("hover", sb_h)
		
		gold_btn.pressed.connect(func():
			player_gold += reward_gold
			gold_btn.disabled = true
			gold_btn.text = "Recebido" if is_pt else "Claimed"
			gold_btn.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))
			if GameGlobals:
				GameGlobals.play_click_sound()
		)
		vbox.add_child(gold_btn)
		
		# Container das cartas
		var card_title = Label.new()
		card_title.text = "Escolhe 1 carta:" if is_pt else "Choose 1 card:"
		card_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if font_reg:
			card_title.add_theme_font_override("font", font_reg)
		card_title.add_theme_font_size_override("font_size", 14)
		card_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		vbox.add_child(card_title)
		
		var cards_hbox = HBoxContainer.new()
		cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		cards_hbox.add_theme_constant_override("separation", 20)
		vbox.add_child(cards_hbox)
		
		var card_buttons = []
		for card_id in reward_cards:
			var card = ThorCardDatabase.get_card(card_id)
			var c_btn = _create_reward_card_button(card)
			cards_hbox.add_child(c_btn)
			card_buttons.append(c_btn)
			
			# Conectar clique para escolher
			c_btn.get_child(c_btn.get_child_count() - 1).pressed.connect(func():
				deck.append(card_id)
				if GameGlobals:
					GameGlobals.play_click_sound()
				# Desabilitar todas
				for b in card_buttons:
					b.modulate = Color(0.3, 0.3, 0.3, 0.5)
					var btn_node = b.get_child(b.get_child_count() - 1)
					btn_node.disabled = true
				c_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
				card_title.text = ("Adicionado: " + card.name_pt) if is_pt else ("Added: " + card.name_en)
				card_title.add_theme_color_override("font_color", HEAL_COLOR)
			)
			
	# Skip/Continue Button
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	var menu_btn = Button.new()
	menu_btn.text = ("Finalizar Run" if is_pt else "Finish Run") if is_boss else ("Continuar Jornada" if is_pt else "Continue Journey")
	menu_btn.custom_minimum_size = Vector2(250, 45)
	menu_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font_bold:
		menu_btn.add_theme_font_override("font", font_bold)
	menu_btn.add_theme_font_size_override("font_size", 14)
	
	var c_sb = StyleBoxFlat.new()
	c_sb.bg_color = ACCENT_COLOR.darkened(0.4)
	c_sb.border_width_left = 2
	c_sb.border_width_top = 2
	c_sb.border_width_right = 2
	c_sb.border_width_bottom = 2
	c_sb.border_color = ACCENT_COLOR
	c_sb.corner_radius_top_left = 6
	c_sb.corner_radius_top_right = 6
	c_sb.corner_radius_bottom_left = 6
	c_sb.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", c_sb)
	var c_sb_h = c_sb.duplicate()
	c_sb_h.bg_color = ACCENT_COLOR.darkened(0.2)
	menu_btn.add_theme_stylebox_override("hover", c_sb_h)
	menu_btn.add_theme_color_override("font_color", Color.WHITE)
	
	menu_btn.pressed.connect(func():
		if GameGlobals:
			GameGlobals.play_click_sound()
			
		var transition = get_node_or_null("/root/SceneTransition")
		if is_boss:
			if GameGlobals: GameGlobals.thor_run_active = false
			if transition: transition.fade_to("res://scenes/main_menu.tscn")
			else: get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		else:
			# Salvar estado de volta ao globals
			if GameGlobals:
				GameGlobals.thor_hp = player_hp
				GameGlobals.thor_gold = player_gold
				GameGlobals.thor_deck = deck.duplicate()
			if transition: transition.fade_to("res://scenes/thor_map.tscn")
			else: get_tree().change_scene_to_file("res://scenes/thor_map.tscn")
	)
	vbox.add_child(menu_btn)

func _spawn_next_wave():
	if combat_waves.is_empty():
		return
		
	var next_enemy_id = combat_waves.pop_front()
	
	# Reset status do inimigo
	enemy_block = 0
	enemy_vulnerable = 0
	enemy_strength = 0
	
	# Carregar novo inimigo
	enemy_data = ThorEnemyDatabase.get_enemy(next_enemy_id)
	
	var diff_mult = 1.0
	if GameGlobals:
		match GameGlobals.current_difficulty:
			GameGlobals.Difficulty.EASY: diff_mult = 0.8
			GameGlobals.Difficulty.HARD: diff_mult = 1.25
			
	var hp = int(randi_range(enemy_data.hp_min, enemy_data.hp_max) * diff_mult)
	enemy_hp = hp
	enemy_max_hp = hp
	
	# Novo intent
	enemy_intent = ThorEnemyDatabase.get_random_intent(next_enemy_id)
	
	# Atualizar fundo dinamicamente
	if bg_rect:
		var enemy_bg_map = {
			"draugr": "draugr_bg",
			"lobo_fenrir": "loboFenrir_bg",
			"gigante_gelo": "giganteGelo_bg",
			"corvos_hel": "corvosHel_bg",
			"esqueleto_viking": "esqueletoViking_bg",
			"hel_rainha": "helRainhaBoss_bg",
			"fenrir_gigante": "fenrirGignateBoss_bg",
			"jormungandr": "fenrirGignateBoss_bg"
		}
		var bg_file = enemy_bg_map.get(next_enemy_id, "")
		var bg_tex = null
		if bg_file != "":
			var cenario_path = "res://assets/sprites/Sprites Thor/Cenários/" + bg_file + ".png"
			if ResourceLoader.exists(cenario_path):
				bg_tex = load(cenario_path)
		if bg_tex == null:
			bg_tex = load("res://assets/sprites/ThorJormungandr_bg.png")
		bg_rect.texture = bg_tex
		
	# Som de spawn
	_play_sfx("power_up", 0.8, -4.0)
	_show_info(_get_trans("REFORÇOS INIMIGOS!", "ENEMY REINFORCEMENTS!"), DAMAGE_COLOR)
	
	_update_all_ui()
	_rebuild_hand_ui()

func _generate_card_rewards() -> Array:
	var possible_cards = ThorCardDatabase.get_reward_pool(-1)
	possible_cards.shuffle()
	
	var rewards = []
	for i in range(3):
		if i < possible_cards.size():
			rewards.append(possible_cards[i])
	return rewards

func _get_card_icon(card_id: String) -> String:
	match card_id:
		"golpe_mjolnir": return "🔨"
		"escudo_asgard": return "🛡️"
		"trovao": return "⚡"
		"muralha_gelo": return "❄️"
		"rugido_trovao": return "🦁"
		"golpe_duplo": return "⚔️"
		"relampago_bifrost": return "🌈"
		"martelo_giratorio": return "🌀"
		"bencao_odin": return "🦅"
		"armadura_divina": return "🛡️"
		"cadeia_fenrir": return "⛓️"
		"investida_thor": return "🐏"
		"cura_runas": return "🌿"
		"furia_berserker": return "😡"
		"tempestade_raios": return "⛈️"
		"sacrificio_valquiria": return "👼"
		"valhalla": return "🏰"
		"frenesi_nordico": return "🔥"
		"escudo_yggdrasil": return "🌳"
		_: return "🃏"

func _get_card_img_name(card_id: String) -> String:
	match card_id:
		"golpe_mjolnir": return "card_strike"
		"escudo_asgard": return "card_defend"
		"trovao": return "card_thunder"
		"muralha_gelo": return "card_ice_wall"
		"rugido_trovao": return "card_thunder_roar"
		"golpe_duplo": return "card_double_strike"
		"relampago_bifrost": return "card_bifrost_lightning"
		"martelo_giratorio": return "card_spinning_hammer"
		"bencao_odin": return "card_odins_blessing"
		"armadura_divina": return "card_divine_armor"
		"cadeia_fenrir": return "card_fenrirs_chain"
		"investida_thor": return "card_thors_charge"
		"cura_runas": return "card_rune_healing"
		"furia_berserker": return "card_berserker_fury"
		"tempestade_raios": return "card_lightning_storm"
		"sacrificio_valquiria": return "card_valkyrie_sacrifice"
		"valhalla": return "card_valhalla"
		"frenesi_nordico": return "card_nordic_frenzy"
		"escudo_yggdrasil": return "card_yggdrasil_shield"
		"ira_mjolnir": return "card_mjolnir_wrath"
	return ""

func _create_reward_card_button(card: Dictionary) -> Panel:
	var r_width = CARD_WIDTH * 1.2
	var r_height = CARD_HEIGHT * 1.2
	
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(r_width, r_height)
	panel.clip_contents = false
	
	# Determine colors based on type
	var bg_start: Color
	var bg_end: Color
	var border_color: Color
	
	match card.type:
		ThorCardDatabase.CardType.ATTACK:
			bg_start = Color(0.55, 0.12, 0.12, 1.0)
			bg_end = Color(0.15, 0.08, 0.08, 1.0)
			border_color = Color(0.85, 0.3, 0.3, 0.8)
		ThorCardDatabase.CardType.SKILL:
			bg_start = Color(0.1, 0.25, 0.5, 1.0)
			bg_end = Color(0.06, 0.08, 0.15, 1.0)
			border_color = Color(0.3, 0.6, 0.9, 0.8)
		ThorCardDatabase.CardType.POWER:
			bg_start = Color(0.5, 0.35, 0.08, 1.0)
			bg_end = Color(0.12, 0.1, 0.08, 1.0)
			border_color = Color(0.95, 0.8, 0.3, 0.8)
		_:
			bg_start = Color(0.2, 0.2, 0.2, 1.0)
			bg_end = Color(0.08, 0.08, 0.08, 1.0)
			border_color = Color(0.5, 0.5, 0.5, 0.8)
			
	if card.rarity == ThorCardDatabase.CardRarity.RARE:
		border_color = GOLD_COLOR
		
	# Outer border style
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = border_color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.shadow_size = 6
	sb.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", sb)
	
	# Gradient Background
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var grad = Gradient.new()
	grad.colors = [bg_start, bg_end]
	grad.offsets = [0.0, 1.0]
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.2, 0.0)
	grad_tex.fill_to = Vector2(0.8, 1.0)
	
	bg_tex.texture = grad_tex
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg_tex)
	
	# Inner gold/silver frame border
	var inner_border = Panel.new()
	inner_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_border.offset_left = 6
	inner_border.offset_top = 6
	inner_border.offset_right = -6
	inner_border.offset_bottom = -6
	inner_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var inner_sb = StyleBoxFlat.new()
	inner_sb.bg_color = Color(0, 0, 0, 0)
	inner_sb.border_width_left = 1
	inner_sb.border_width_top = 1
	inner_sb.border_width_right = 1
	inner_sb.border_width_bottom = 1
	inner_sb.border_color = Color(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b, 0.3) if card.rarity == ThorCardDatabase.CardRarity.RARE else Color(1, 1, 1, 0.15)
	inner_sb.corner_radius_top_left = 6
	inner_sb.corner_radius_top_right = 6
	inner_sb.corner_radius_bottom_left = 6
	inner_sb.corner_radius_bottom_right = 6
	inner_border.add_theme_stylebox_override("panel", inner_sb)
	panel.add_child(inner_border)
	
	# VBox layout
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 10
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	# Name
	var name_lbl = Label.new()
	name_lbl.text = card.name_pt if is_pt else card.name_en
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_bold:
		name_lbl.add_theme_font_override("font", font_bold)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", GOLD_COLOR if card.rarity == ThorCardDatabase.CardRarity.RARE else Color.WHITE)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(name_lbl)
	
	# Illustration Frame
	var ill_panel = Panel.new()
	ill_panel.custom_minimum_size = Vector2(0, 60)
	ill_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var ill_sb = StyleBoxFlat.new()
	ill_sb.bg_color = Color(0, 0, 0, 0.45)
	ill_sb.border_width_left = 1
	ill_sb.border_width_top = 1
	ill_sb.border_width_right = 1
	ill_sb.border_width_bottom = 1
	ill_sb.border_color = border_color.darkened(0.2)
	ill_sb.corner_radius_top_left = 4
	ill_sb.corner_radius_top_right = 4
	ill_sb.corner_radius_bottom_left = 4
	ill_sb.corner_radius_bottom_right = 4
	ill_panel.add_theme_stylebox_override("panel", ill_sb)
	vbox.add_child(ill_panel)
	
	# Tenta carregar imagem da carta, se não existir usa emoji
	var card_img_name = _get_card_img_name(card.id)
	var card_img_path = "res://assets/sprites/Sprites Thor/Cartas/" + card_img_name + ".png" if card_img_name != "" else ""
	var has_illustration = false
	if card_img_path != "" and ResourceLoader.exists(card_img_path):
		var card_tex = TextureRect.new()
		card_tex.texture = load(card_img_path)
		card_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_tex.stretch_mode = TextureRect.STRETCH_SCALE
		card_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ill_panel.add_child(card_tex)
		has_illustration = true
		
	# Emoji (fallback se não houver ilustração)
	var emoji_lbl = Label.new()
	emoji_lbl.text = _get_card_icon(card.id)
	emoji_lbl.set_anchors_preset(Control.PRESET_CENTER)
	emoji_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	emoji_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.add_theme_font_size_override("font_size", 32)
	emoji_lbl.add_theme_constant_override("outline_size", 2)
	emoji_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	emoji_lbl.visible = not has_illustration
	ill_panel.add_child(emoji_lbl)
	
	# Separator
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", border_color.darkened(0.3))
	vbox.add_child(sep)
	
	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = card.desc_pt if is_pt else card.desc_en
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_reg:
		desc_lbl.add_theme_font_override("font", font_reg)
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_lbl.add_theme_constant_override("outline_size", 2)
	desc_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)
	
	# Type Label
	var type_lbl = Label.new()
	match card.type:
		ThorCardDatabase.CardType.ATTACK:
			type_lbl.text = "⚔️ Ataque" if is_pt else "⚔️ Attack"
		ThorCardDatabase.CardType.SKILL:
			type_lbl.text = "🛡 Habilidade" if is_pt else "🛡 Skill"
		ThorCardDatabase.CardType.POWER:
			type_lbl.text = "✨ Poder" if is_pt else "✨ Power"
	if font_reg:
		type_lbl.add_theme_font_override("font", font_reg)
	type_lbl.add_theme_font_size_override("font_size", 8)
	type_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)
	
	# circular energy badge
	var energy_badge = Panel.new()
	energy_badge.size = Vector2(26, 26)
	energy_badge.position = Vector2(-7, -7)
	energy_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var badge_sb = StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.08, 0.1, 0.18, 0.95)
	badge_sb.border_width_left = 2
	badge_sb.border_width_top = 2
	badge_sb.border_width_right = 2
	badge_sb.border_width_bottom = 2
	badge_sb.border_color = GOLD_COLOR if card.rarity == ThorCardDatabase.CardRarity.RARE else ENERGY_COLOR
	badge_sb.corner_radius_top_left = 13
	badge_sb.corner_radius_top_right = 13
	badge_sb.corner_radius_bottom_left = 13
	badge_sb.corner_radius_bottom_right = 13
	badge_sb.shadow_size = 2
	badge_sb.shadow_color = Color(0, 0, 0, 0.5)
	energy_badge.add_theme_stylebox_override("panel", badge_sb)
	panel.add_child(energy_badge)
	
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.cost)
	cost_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cost_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cost_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_bold:
		cost_lbl.add_theme_font_override("font", font_bold)
	cost_lbl.add_theme_font_size_override("font_size", 12)
	cost_lbl.add_theme_color_override("font_color", ENERGY_COLOR)
	energy_badge.add_child(cost_lbl)
	
	# Invisible click button
	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.flat = true
	click_btn.modulate.a = 0.0
	
	click_btn.mouse_entered.connect(func():
		panel.pivot_offset = panel.size / 2
		var tw = create_tween()
		tw.tween_property(panel, "scale", Vector2(1.05, 1.05), 0.1)
		if GameGlobals:
			GameGlobals.play_hover_sound()
	)
	click_btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.1)
	)
	
	panel.add_child(click_btn)
	return panel

func _on_player_defeated():
	state = BattleState.DEFEAT
	_show_info(_get_trans("DERROTA...", "DEFEAT..."), DAMAGE_COLOR)
	_update_all_ui()
	
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(_show_defeat_screen)

func _show_defeat_screen():
	var overlay = ColorRect.new()
	overlay.color = Color(0.1, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -180
	vbox.offset_top = -100
	vbox.offset_right = 180
	vbox.offset_bottom = 100
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.add_theme_constant_override("separation", 16)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay.add_child(vbox)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	var title = Label.new()
	title.text = "💀 DERROTA 💀" if is_pt else "💀 DEFEAT 💀"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", DAMAGE_COLOR)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(title)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	
	# Botão Tentar Novamente
	var retry_btn = Button.new()
	retry_btn.text = "Tentar Novamente" if is_pt else "Try Again"
	retry_btn.custom_minimum_size = Vector2(200, 40)
	if font_bold:
		retry_btn.add_theme_font_override("font", font_bold)
	retry_btn.add_theme_font_size_override("font_size", 12)
	var sb = StyleBoxFlat.new()
	sb.bg_color = DAMAGE_COLOR.darkened(0.5)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = DAMAGE_COLOR
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	retry_btn.add_theme_stylebox_override("normal", sb)
	var sb_h = sb.duplicate()
	sb_h.bg_color = DAMAGE_COLOR.darkened(0.3)
	retry_btn.add_theme_stylebox_override("hover", sb_h)
	retry_btn.add_theme_color_override("font_color", Color.WHITE)
	retry_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/thor_battle.tscn")
	)
	vbox.add_child(retry_btn)
	
	# Botão Menu
	var menu_btn = Button.new()
	menu_btn.text = "Voltar à Biblioteca" if is_pt else "Return to Library"
	menu_btn.custom_minimum_size = Vector2(200, 40)
	if font_bold:
		menu_btn.add_theme_font_override("font", font_bold)
	menu_btn.add_theme_font_size_override("font_size", 12)
	var sb2 = StyleBoxFlat.new()
	sb2.bg_color = Color(0.3, 0.3, 0.3, 0.8)
	sb2.border_width_left = 1
	sb2.border_width_top = 1
	sb2.border_width_right = 1
	sb2.border_width_bottom = 1
	sb2.border_color = Color(0.5, 0.5, 0.5)
	sb2.corner_radius_top_left = 6
	sb2.corner_radius_top_right = 6
	sb2.corner_radius_bottom_left = 6
	sb2.corner_radius_bottom_right = 6
	menu_btn.add_theme_stylebox_override("normal", sb2)
	menu_btn.add_theme_color_override("font_color", Color.WHITE)
	menu_btn.pressed.connect(func():
		if GameGlobals:
			GameGlobals.thor_run_active = false # Reset run
		var transition = get_node_or_null("/root/SceneTransition")
		if transition:
			transition.fade_to("res://scenes/main_menu.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	)
	vbox.add_child(menu_btn)

# =============================================================================
# UI DE CARTAS (CONSTRUÇÃO DINÂMICA)
# =============================================================================

func _rebuild_hand_ui():
	# Limpar cartas anteriores removendo-as do layout de imediato para evitar glitches de desenho no Godot
	for child in card_container.get_children():
		card_container.remove_child(child)
		child.queue_free()
	
	# Criar carta visual para cada carta na mão
	for i in range(hand.size()):
		var card_id = hand[i]
		var card = ThorCardDatabase.get_card(card_id)
		if card.is_empty():
			continue
		
		var card_btn = _create_card_button(card, i)
		card_container.add_child(card_btn)

func _create_card_button(card: Dictionary, index: int) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	panel.clip_contents = false
	
	# Determine colors based on type
	var bg_start: Color
	var bg_end: Color
	var border_color: Color
	
	match card.type:
		ThorCardDatabase.CardType.ATTACK:
			bg_start = Color(0.55, 0.12, 0.12, 1.0)
			bg_end = Color(0.15, 0.08, 0.08, 1.0)
			border_color = Color(0.85, 0.3, 0.3, 0.8)
		ThorCardDatabase.CardType.SKILL:
			bg_start = Color(0.1, 0.25, 0.5, 1.0)
			bg_end = Color(0.06, 0.08, 0.15, 1.0)
			border_color = Color(0.3, 0.6, 0.9, 0.8)
		ThorCardDatabase.CardType.POWER:
			bg_start = Color(0.5, 0.35, 0.08, 1.0)
			bg_end = Color(0.12, 0.1, 0.08, 1.0)
			border_color = Color(0.95, 0.8, 0.3, 0.8)
		_:
			bg_start = Color(0.2, 0.2, 0.2, 1.0)
			bg_end = Color(0.08, 0.08, 0.08, 1.0)
			border_color = Color(0.5, 0.5, 0.5, 0.8)
			
	if card.rarity == ThorCardDatabase.CardRarity.RARE:
		border_color = GOLD_COLOR
		
	# Outer border style
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_width_left = 3
	sb.border_width_top = 3
	sb.border_width_right = 3
	sb.border_width_bottom = 3
	sb.border_color = border_color
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	sb.shadow_size = 5
	sb.shadow_color = Color(0, 0, 0, 0.6)
	panel.add_theme_stylebox_override("panel", sb)
	
	# Gradient Background
	var bg_tex = TextureRect.new()
	bg_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	
	var grad = Gradient.new()
	grad.colors = [bg_start, bg_end]
	grad.offsets = [0.0, 1.0]
	
	var grad_tex = GradientTexture2D.new()
	grad_tex.gradient = grad
	grad_tex.fill = GradientTexture2D.FILL_LINEAR
	grad_tex.fill_from = Vector2(0.2, 0.0)
	grad_tex.fill_to = Vector2(0.8, 1.0)
	
	bg_tex.texture = grad_tex
	bg_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(bg_tex)
	
	# Inner Gold/Silver Frame Border
	var inner_border = Panel.new()
	inner_border.set_anchors_preset(Control.PRESET_FULL_RECT)
	inner_border.offset_left = 5
	inner_border.offset_top = 5
	inner_border.offset_right = -5
	inner_border.offset_bottom = -5
	inner_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var inner_sb = StyleBoxFlat.new()
	inner_sb.bg_color = Color(0, 0, 0, 0)
	inner_sb.border_width_left = 1
	inner_sb.border_width_top = 1
	inner_sb.border_width_right = 1
	inner_sb.border_width_bottom = 1
	inner_sb.border_color = Color(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b, 0.3) if card.rarity == ThorCardDatabase.CardRarity.RARE else Color(1, 1, 1, 0.15)
	inner_sb.corner_radius_top_left = 5
	inner_sb.corner_radius_top_right = 5
	inner_sb.corner_radius_bottom_left = 5
	inner_sb.corner_radius_bottom_right = 5
	inner_border.add_theme_stylebox_override("panel", inner_sb)
	panel.add_child(inner_border)
	
	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 8
	vbox.offset_top = 8
	vbox.offset_right = -8
	vbox.offset_bottom = -8
	vbox.add_theme_constant_override("separation", 3)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)
	
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(top_spacer)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	# Card Name
	var name_lbl = Label.new()
	name_lbl.text = card.name_pt if is_pt else card.name_en
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_bold:
		name_lbl.add_theme_font_override("font", font_bold)
	name_lbl.add_theme_font_size_override("font_size", 9)
	name_lbl.add_theme_color_override("font_color", GOLD_COLOR if card.rarity == ThorCardDatabase.CardRarity.RARE else Color.WHITE)
	name_lbl.add_theme_constant_override("outline_size", 3)
	name_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	vbox.add_child(name_lbl)
	
	# Illustration Frame
	var ill_panel = Panel.new()
	ill_panel.custom_minimum_size = Vector2(0, 52)
	ill_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ill_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var ill_sb = StyleBoxFlat.new()
	ill_sb.bg_color = Color(0, 0, 0, 0.45)
	ill_sb.border_width_left = 1
	ill_sb.border_width_top = 1
	ill_sb.border_width_right = 1
	ill_sb.border_width_bottom = 1
	ill_sb.border_color = border_color.darkened(0.2)
	ill_sb.corner_radius_top_left = 4
	ill_sb.corner_radius_top_right = 4
	ill_sb.corner_radius_bottom_left = 4
	ill_sb.corner_radius_bottom_right = 4
	ill_panel.add_theme_stylebox_override("panel", ill_sb)
	vbox.add_child(ill_panel)
	
	# Tenta carregar imagem da carta, se não existir usa emoji
	var card_img_name = _get_card_img_name(card.id)
	var card_img_path = "res://assets/sprites/Sprites Thor/Cartas/" + card_img_name + ".png" if card_img_name != "" else ""
	var has_illustration = false
	if card_img_path != "" and ResourceLoader.exists(card_img_path):
		var card_tex = TextureRect.new()
		card_tex.texture = load(card_img_path)
		card_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		card_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_tex.stretch_mode = TextureRect.STRETCH_SCALE
		card_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ill_panel.add_child(card_tex)
		has_illustration = true
		
	# Emoji Inside Frame (fallback se não houver ilustração)
	var emoji_lbl = Label.new()
	emoji_lbl.text = _get_card_icon(card.id)
	emoji_lbl.set_anchors_preset(Control.PRESET_CENTER)
	emoji_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	emoji_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emoji_lbl.add_theme_font_size_override("font_size", 28)
	emoji_lbl.add_theme_constant_override("outline_size", 2)
	emoji_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	emoji_lbl.visible = not has_illustration
	ill_panel.add_child(emoji_lbl)
	
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", border_color.darkened(0.3))
	vbox.add_child(sep)
	
	# Description
	var desc_lbl = Label.new()
	desc_lbl.text = card.desc_pt if is_pt else card.desc_en
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_reg:
		desc_lbl.add_theme_font_override("font", font_reg)
	desc_lbl.add_theme_font_size_override("font_size", 8)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_lbl.add_theme_constant_override("outline_size", 2)
	desc_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)
	
	# Type Rodapé
	var type_lbl = Label.new()
	match card.type:
		ThorCardDatabase.CardType.ATTACK:
			type_lbl.text = "⚔️ Ataque" if is_pt else "⚔️ Attack"
		ThorCardDatabase.CardType.SKILL:
			type_lbl.text = "🛡 Habilidade" if is_pt else "🛡 Skill"
		ThorCardDatabase.CardType.POWER:
			type_lbl.text = "✨ Poder" if is_pt else "✨ Power"
	if font_reg:
		type_lbl.add_theme_font_override("font", font_reg)
	type_lbl.add_theme_font_size_override("font_size", 7)
	type_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	type_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(type_lbl)
	
	# circular energy badge (top-left)
	var energy_badge = Panel.new()
	energy_badge.size = Vector2(24, 24)
	energy_badge.position = Vector2(-6, -6)
	energy_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var badge_sb = StyleBoxFlat.new()
	badge_sb.bg_color = Color(0.08, 0.1, 0.18, 0.95)
	badge_sb.border_width_left = 2
	badge_sb.border_width_top = 2
	badge_sb.border_width_right = 2
	badge_sb.border_width_bottom = 2
	badge_sb.border_color = GOLD_COLOR if card.rarity == ThorCardDatabase.CardRarity.RARE else ENERGY_COLOR
	badge_sb.corner_radius_top_left = 12
	badge_sb.corner_radius_top_right = 12
	badge_sb.corner_radius_bottom_left = 12
	badge_sb.corner_radius_bottom_right = 12
	badge_sb.shadow_size = 2
	badge_sb.shadow_color = Color(0, 0, 0, 0.5)
	energy_badge.add_theme_stylebox_override("panel", badge_sb)
	panel.add_child(energy_badge)
	
	var cost_lbl = Label.new()
	cost_lbl.text = str(card.cost)
	cost_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	cost_lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	cost_lbl.grow_vertical = Control.GROW_DIRECTION_BOTH
	cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if font_bold:
		cost_lbl.add_theme_font_override("font", font_bold)
	cost_lbl.add_theme_font_size_override("font_size", 11)
	cost_lbl.add_theme_color_override("font_color", ENERGY_COLOR)
	energy_badge.add_child(cost_lbl)
	
	# Invisible interaction button (MUST BE THE LAST CHILD ADDED!)
	var click_btn = Button.new()
	click_btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	click_btn.layout_mode = 1
	click_btn.anchor_right = 1.0
	click_btn.anchor_bottom = 1.0
	click_btn.flat = true
	click_btn.modulate.a = 0.0
	click_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var card_index = index
	var can_play = card.cost <= player_energy and state == BattleState.PLAYER_TURN
	
	click_btn.pressed.connect(func():
		_play_card(card_index)
	)
	panel.add_child(click_btn)
	
	# Hover effects
	click_btn.mouse_entered.connect(func():
		if card.cost <= player_energy and state == BattleState.PLAYER_TURN:
			panel.pivot_offset = panel.size / 2
			var tw = create_tween()
			tw.tween_property(panel, "scale", Vector2(1.12, 1.12), 0.12)
			tw.parallel().tween_property(panel, "position:y", panel.position.y - 12, 0.12)
		if GameGlobals:
			GameGlobals.play_hover_sound()
	)
	click_btn.mouse_exited.connect(func():
		var tw = create_tween()
		tw.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.12)
		tw.parallel().tween_property(panel, "position:y", panel.position.y + 12, 0.12)
	)
	
	# Dim unplayable cards
	if not can_play:
		panel.modulate = Color(0.55, 0.55, 0.55, 0.75)
		
	return panel

# =============================================================================
# ATUALIZAÇÃO DE UI
# =============================================================================

func _update_all_ui():
	# Jogador
	if player_hp_bar:
		player_hp_bar.max_value = player_max_hp
		player_hp_bar.value = player_hp
	if player_hp_label:
		player_hp_label.text = "❤️ " + str(player_hp) + " / " + str(player_max_hp)
	if player_block_label:
		player_block_label.text = "🛡 " + str(player_block) if player_block > 0 else ""
	# Inimigo
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	
	if enemy_name_label:
		enemy_name_label.text = enemy_data.get("name_pt", "???") if is_pt else enemy_data.get("name_en", "???")
	if enemy_hp_bar:
		enemy_hp_bar.max_value = enemy_max_hp
		enemy_hp_bar.value = enemy_hp
	if enemy_hp_label:
		enemy_hp_label.text = "❤️ " + str(enemy_hp) + " / " + str(enemy_max_hp)
	if enemy_block_label:
		enemy_block_label.text = "🛡 " + str(enemy_block) if enemy_block > 0 else ""
	
	# Painel do inimigo (cor, borda e textura)
	if enemy_panel:
		var panel_sb = StyleBoxFlat.new()
		var color_hex = enemy_data.get("color", "#444444")
		var has_texture = false
		var tex_path = ""
		
		var paths_to_check = [
			"res://assets/sprites/Sprites Thor/Inimigos/" + enemy_data.id + "_boss.png",
			"res://assets/sprites/Sprites Thor/Inimigos/" + enemy_data.id + ".png",
			"res://assets/sprites/" + enemy_data.id + "_boss.png",
			"res://assets/sprites/" + enemy_data.id + ".png"
		]
		
		for p in paths_to_check:
			if ResourceLoader.exists(p):
				tex_path = p
				has_texture = true
				break
				
		if has_texture:
			panel_sb.bg_color = Color(0, 0, 0, 0) # Completely transparent
			panel_sb.border_width_left = 0
			panel_sb.border_width_top = 0
			panel_sb.border_width_right = 0
			panel_sb.border_width_bottom = 0
			panel_sb.shadow_size = 0
		else:
			panel_sb.bg_color = Color.html(color_hex).darkened(0.2)
			panel_sb.corner_radius_top_left = 8
			panel_sb.corner_radius_top_right = 8
			panel_sb.corner_radius_bottom_left = 8
			panel_sb.corner_radius_bottom_right = 8
			
			# Custom borders based on tier (only for emoji fallbacks)
			var type = enemy_data.get("type", 0)
			if type == ThorEnemyDatabase.EnemyType.BOSS:
				panel_sb.border_color = GOLD_COLOR
				panel_sb.border_width_left = 4
				panel_sb.border_width_top = 4
				panel_sb.border_width_right = 4
				panel_sb.border_width_bottom = 4
				panel_sb.shadow_size = 12
				panel_sb.shadow_color = Color(1.0, 0.85, 0.25, 0.4)
			elif type == ThorEnemyDatabase.EnemyType.ELITE:
				panel_sb.border_color = Color(0.8, 0.1, 0.8, 1.0)
				panel_sb.border_width_left = 3
				panel_sb.border_width_top = 3
				panel_sb.border_width_right = 3
				panel_sb.border_width_bottom = 3
				panel_sb.shadow_size = 8
				panel_sb.shadow_color = Color(0.8, 0.1, 0.8, 0.3)
			else:
				panel_sb.border_color = Color.html(color_hex).lightened(0.3)
				panel_sb.border_width_left = 2
				panel_sb.border_width_top = 2
				panel_sb.border_width_right = 2
				panel_sb.border_width_bottom = 2
				panel_sb.shadow_size = 6
				panel_sb.shadow_color = Color(0, 0, 0, 0.4)
			
		enemy_panel.add_theme_stylebox_override("panel", panel_sb)
		
		if enemy_texture_rect:
			if has_texture:
				var tex = load(tex_path)
				enemy_texture_rect.texture = tex
				enemy_texture_rect.visible = true
				if tex:
					var tex_w = tex.get_width()
					var tex_h = tex.get_height()
					var max_size = 130.0
					var aspect = float(tex_w) / float(tex_h)
					var new_w = max_size
					var new_h = max_size
					if aspect > 1.0:
						new_h = max_size / aspect
					else:
						new_w = max_size * aspect
					enemy_texture_rect.custom_minimum_size = Vector2(new_w, new_h)
					enemy_texture_rect.size = Vector2(new_w, new_h)
					enemy_texture_rect.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
					# Centralizar horizontalmente e colocar exatamente no fundo do painel (Y=140) para não flutuar
					enemy_texture_rect.position = Vector2((140 - new_w) / 2, 140 - new_h)
				if enemy_icon_label:
					enemy_icon_label.visible = false
			else:
				enemy_texture_rect.texture = null
				enemy_texture_rect.visible = false
				if enemy_icon_label:
					enemy_icon_label.visible = true
					
	if enemy_icon_label and enemy_icon_label.visible:
		enemy_icon_label.text = enemy_data.get("icon", "👾")
	
	# Energia
	if energy_label:
		energy_label.text = str(player_energy) + "/" + str(player_max_energy)
	
	# Contadores de deck
	if deck_count_label:
		deck_count_label.text = "📚 Deck: " + str(draw_pile.size())
	
	# Rebuild cartas se estamos no turno do jogador
	if state == BattleState.PLAYER_TURN:
		_rebuild_hand_ui()

# =============================================================================
# EFEITOS VISUAIS
# =============================================================================

func _show_info(text: String, color: Color = GOLD_COLOR):
	if not info_label:
		return
	info_label.text = text
	info_label.add_theme_color_override("font_color", color)
	info_label.modulate.a = 1.0
	info_label.scale = Vector2(0.5, 0.5)
	info_label.pivot_offset = info_label.size / 2
	
	var tw = create_tween()
	tw.tween_property(info_label, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(info_label, "modulate:a", 0.0, 0.5).set_delay(0.8)

func _shake_node(node: Node):
	if not node or not is_instance_valid(node):
		return
	var original_pos = node.position
	var tw = create_tween()
	tw.tween_property(node, "position:x", original_pos.x + 8, 0.05)
	tw.tween_property(node, "position:x", original_pos.x - 8, 0.05)
	tw.tween_property(node, "position:x", original_pos.x + 4, 0.05)
	tw.tween_property(node, "position:x", original_pos.x, 0.05)

# =============================================================================
# INPUT
# =============================================================================

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		# ESC → Pausa (usa o mesmo pause_menu que as outras fases)
		var pause_scene = load("res://scenes/pause_menu.tscn")
		if pause_scene:
			var pause = pause_scene.instantiate()
			add_child(pause)
			get_tree().paused = true

# =============================================================================
# ANIMAÇÃO DE ENTRADA E HISTÓRIA (Livro III)
# =============================================================================

func _play_intro_animation():
	state = BattleState.INTRO
	
	# Esconder cartas e botões durante a intro
	if card_container:
		card_container.visible = false
	if end_turn_btn:
		end_turn_btn.visible = false
	if energy_label:
		energy_label.get_parent().visible = false
		
	# Colocar Thor no céu para a queda
	if player_node:
		player_node.position.y = -100
		player_node.visible = true
	
	# Tornar os HUDs do jogador e inimigo invisíveis inicialmente
	if player_container:
		player_container.modulate.a = 0.0
	if enemy_container:
		enemy_container.modulate.a = 0.0
	if enemy_panel:
		# Posicionar o inimigo completamente fora do ecrã à direita de forma dinâmica e mantê-lo invisível
		enemy_panel.visible = false
		enemy_panel.position.x = get_viewport_rect().size.x + 200
		enemy_panel.modulate.a = 1.0
		
	# Iniciar narrativa do Livro III
	_run_intro_step_1()

func _run_intro_step_1():
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_thor", "text": "dialogue_thor_intro_1"},
		{"name": "char_thor", "text": "dialogue_thor_intro_2"}
	]
	d.dialogue_finished.connect(_run_intro_step_2_thor_fall)
	add_child(d)

func _run_intro_step_2_thor_fall():
	# Thor cai do céu!
	if player_node:
		var tw = create_tween()
		tw.tween_property(player_node, "position:y", 328.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			# Tremor de ecrã e som
			_shake_node(player_node)
			if GameGlobals:
				GameGlobals.play_click_sound() # Som de impacto
			
			# Fade-in do HUD do jogador após o impacto
			var tw_player_hud = create_tween()
			tw_player_hud.tween_property(player_container, "modulate:a", 1.0, 0.45)
			
			# Revelar inimigo deslizando a opacidade do HUD
			var tw_enemy = create_tween()
			tw_enemy.tween_property(enemy_container, "modulate:a", 1.0, 0.5)
			
			# Revelar o inimigo com animação de entrada: torna-se visível e desliza suavemente da direita para a plataforma!
			if enemy_panel:
				enemy_panel.visible = true
				var tw_panel = create_tween()
				tw_panel.tween_property(enemy_panel, "position:x", 812.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			
			tw_enemy.tween_callback(func():
				_run_intro_step_3_confrontation()
			)
		)

func _run_intro_step_3_confrontation():
	var d = dialogue_scene.instantiate()
	if enemy_data.id == "jormungandr":
		d.dialogue_list = [
			{"name": "char_thor", "text": "dialogue_thor_jormungandr_1"},
			{"name": "jormungandr", "text": "dialogue_jormungandr_thor_1"},
			{"name": "char_thor", "text": "dialogue_thor_jormungandr_2"}
		]
	else:
		# Combate genérico contra monstros
		d.dialogue_list = [
			{"name": "char_thor", "text": "dialogue_generic_thor_fight_1"},
			{"name": enemy_data.id, "text": "dialogue_draugr_intro" if enemy_data.id == "draugr" else "dialogue_generic_monster_growl"}
		]
	d.dialogue_finished.connect(_on_intro_finished)
	add_child(d)

func _on_intro_finished():
	# Restaurar visibilidade dos controlos e cartas
	if card_container:
		card_container.visible = true
	if end_turn_btn:
		end_turn_btn.visible = true
	if energy_label:
		energy_label.get_parent().visible = true
		
	# Iniciar combate real
	_start_battle()

func _play_sfx(sound_name: String, pitch: float = 1.0, volume: float = 0.0):
	var sfx_player = AudioStreamPlayer.new()
	var path = "res://assets/sounds/" + sound_name + ".wav"
	if ResourceLoader.exists(path):
		sfx_player.stream = load(path)
	else:
		return
	sfx_player.bus = "SFX"
	sfx_player.pitch_scale = pitch
	sfx_player.volume_db = volume
	sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(sfx_player)
	sfx_player.play()
	sfx_player.finished.connect(sfx_player.queue_free)

func _play_lightning_vfx():
	var flash = ColorRect.new()
	flash.color = Color(0.8, 0.95, 1.0, 0.6) # Cyan-white electric flash
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(flash.queue_free)

func _play_spark_vfx(pos: Vector2):
	for i in range(15):
		var p = Panel.new()
		p.size = Vector2(randf_range(6, 12), randf_range(6, 12))
		p.position = pos - p.size / 2 + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.75, 1.0, 1.0) # Electric cyan sparks
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		p.add_theme_stylebox_override("panel", style)
		add_child(p)
		
		# Animate flying away
		var angle = randf_range(0, 2 * PI)
		var speed = randf_range(120, 280)
		var dest = p.position + Vector2(cos(angle), sin(angle)) * speed * 0.45
		
		var tw = create_tween()
		tw.set_parallel(true)
		tw.tween_property(p, "position", dest, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(p, "modulate:a", 0.0, 0.45)
		tw.chain().tween_callback(p.queue_free)
