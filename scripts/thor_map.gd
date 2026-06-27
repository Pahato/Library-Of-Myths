extends Control

enum NodeType { COMBAT, ELITE, REST, SHOP, BOSS }

var font_bold: FontFile = null
var font_reg: FontFile = null
var tooltip_title: Label = null
var tooltip_desc: Label = null

const GOLD_COLOR = Color(1.0, 0.85, 0.25, 1.0)

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

func _ready():
	font_bold = _load_font(true)
	font_reg = _load_font(false)
	
	# Inicializa as variáveis da run caso ainda não esteja ativa
	if not GameGlobals.get("thor_run_active"):
		GameGlobals.thor_hp = 80
		GameGlobals.thor_max_hp = 80
		
		GameGlobals.thor_deck = ThorCardDatabase.get_starter_deck()
			
		GameGlobals.thor_gold = 0
		GameGlobals.thor_act = 1
		GameGlobals.thor_current_layer = 1
		GameGlobals.thor_map_path = []
		GameGlobals.thor_map_data = {}
		GameGlobals.thor_run_active = true
		
	if GameGlobals.thor_map_data.is_empty():
		_generate_map()
		
	_build_ui()
	
	# Música temática do Thor
	GameGlobals.play_music("res://assets/music/time_for_adventure.mp3", -8.0)

func _generate_map():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var layers = {}
	
	# Gera 15 layers de nós
	for layer_idx in range(1, 16):
		var nodes_in_layer = []
		var num_nodes = 1
		
		if layer_idx == 1:
			num_nodes = rng.randi_range(2, 3)
		elif layer_idx == 15:
			num_nodes = 1
		else:
			num_nodes = rng.randi_range(2, 4)
			
		for i in range(num_nodes):
			var node_type = NodeType.COMBAT
			if layer_idx == 1:
				node_type = NodeType.COMBAT
			elif layer_idx == 15:
				node_type = NodeType.BOSS
			else:
				var roll = rng.randf()
				if roll < 0.55:
					node_type = NodeType.COMBAT
				elif roll < 0.75:
					node_type = NodeType.ELITE
				elif roll < 0.85:
					node_type = NodeType.REST
				else:
					node_type = NodeType.SHOP
					
			nodes_in_layer.append({
				"id": str(layer_idx) + "_" + str(i),
				"layer": layer_idx,
				"index": i,
				"type": node_type,
				"connections": []
			})
			
		layers[layer_idx] = nodes_in_layer
		
	# Gera conexões entre as layers
	for layer_idx in range(1, 15):
		var current_layer_nodes = layers[layer_idx]
		var next_layer_nodes = layers[layer_idx + 1]
		
		# Cada nó em N conecta a pelo menos um em N+1
		for c_node in current_layer_nodes:
			var target = next_layer_nodes[rng.randi() % next_layer_nodes.size()]
			if not target.id in c_node.connections:
				c_node.connections.append(target.id)
				
		# Cada nó em N+1 deve ter pelo menos uma ligação vinda de N
		for n_node in next_layer_nodes:
			var has_connection = false
			for c_node in current_layer_nodes:
				if n_node.id in c_node.connections:
					has_connection = true
					break
					
			if not has_connection:
				var source = current_layer_nodes[rng.randi() % current_layer_nodes.size()]
				if not n_node.id in source.connections:
					source.connections.append(n_node.id)
					
	GameGlobals.thor_map_data = layers

func _build_ui():
	# Fundo
	var bg = ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.12, 1.0)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# ScrollContainer para navegar o mapa (deslocado para caber o título fixo)
	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 120 # Espaço para Top Bar (60) e Title Banner (60)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	
	var map_container = Control.new()
	var layer_height = 130
	var map_height = 15 * layer_height + 200
	map_container.custom_minimum_size = Vector2(1152, map_height)
	map_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(map_container)
	
	var node_positions = {}
	var layers = GameGlobals.thor_map_data
	
	# Assumimos uma largura base para centralizar os nós
	var screen_w = 1152.0
	
	# 1. Calcula posições de cada nó
	for layer_idx in layers.keys():
		var layer_nodes = layers[layer_idx]
		var layer_y = map_height - (layer_idx * layer_height) - 100
		var num_nodes = layer_nodes.size()
		
		for i in range(num_nodes):
			var node_data = layer_nodes[i]
			var spacing = 180
			var start_x = (screen_w / 2.0) - ((num_nodes - 1) * spacing / 2.0)
			var node_x = start_x + (i * spacing)
			
			# Ligeira variação para dar aspeto orgânico
			var rng = RandomNumberGenerator.new()
			rng.seed = hash(node_data.id)
			node_x += rng.randf_range(-30.0, 30.0)
			var final_y = layer_y + rng.randf_range(-15.0, 15.0)
			
			node_positions[node_data.id] = Vector2(node_x, final_y)
			
	# 2. Desenha conexões
	for layer_idx in range(1, 15):
		for c_node in layers[layer_idx]:
			var start_pos = node_positions[c_node.id]
			for target_id in c_node.connections:
				var end_pos = node_positions[target_id]
				var line = Line2D.new()
				line.add_point(start_pos)
				line.add_point(end_pos)
				line.width = 4.0
				
				# Verifica se o jogador fez este caminho
				var is_taken = false
				var path = GameGlobals.thor_map_path
				var idx = path.find(c_node.id)
				if idx != -1 and idx + 1 < path.size() and path[idx + 1] == target_id:
					is_taken = true
					
				if is_taken:
					line.default_color = Color(0.9, 0.8, 0.2, 1.0) # Dourado se percorrido
				else:
					line.default_color = Color(0.4, 0.4, 0.4, 0.5) # Cinza se por percorrer
					
				map_container.add_child(line)
				
	# 3. Desenha os nós (Buttons)
	for layer_idx in layers.keys():
		for node_data in layers[layer_idx]:
			var pos = node_positions[node_data.id]
			var btn = Button.new()
			var icon_text = ""
			var icon_file = ""
			var base_color = Color.WHITE
			
			match node_data.type:
				NodeType.COMBAT:
					icon_text = "⚔️"
					icon_file = "node_combat"
					base_color = Color(0.8, 0.8, 0.8)
				NodeType.ELITE:
					icon_text = "💀"
					icon_file = "node_elite"
					base_color = Color(0.9, 0.3, 0.3)
				NodeType.REST:
					icon_text = "🏕️"
					icon_file = "node_rest"
					base_color = Color(0.3, 0.9, 0.3)
				NodeType.SHOP:
					icon_text = "💰"
					icon_file = "node_shop"
					base_color = Color(0.8, 0.8, 0.2)
				NodeType.BOSS:
					icon_text = "👑"
					icon_file = "node_boss"
					base_color = Color(0.8, 0.2, 0.8)
					
			var icon_path = "res://assets/sprites/Sprites Thor/Icones/" + icon_file + ".png"
			btn.text = ""
			if ResourceLoader.exists(icon_path):
				var icon_tex = TextureRect.new()
				icon_tex.texture = load(icon_path)
				icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
				icon_tex.offset_left = 13
				icon_tex.offset_top = 13
				icon_tex.offset_right = -13
				icon_tex.offset_bottom = -13
				icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
				btn.add_child(icon_tex)
			else:
				btn.text = icon_text
			var btn_size = 64
			btn.custom_minimum_size = Vector2(btn_size, btn_size)
			btn.position = pos - Vector2(btn_size / 2.0, btn_size / 2.0)
			
			var is_visited = GameGlobals.thor_map_path.has(node_data.id)
			var is_reachable = false
			
			# Lógica de reachable
			if GameGlobals.thor_current_layer == node_data.layer:
				if node_data.layer == 1:
					is_reachable = true
				else:
					var last_id = GameGlobals.thor_map_path.back()
					var prev_layer = node_data.layer - 1
					for p_node in layers[prev_layer]:
						if p_node.id == last_id and node_data.id in p_node.connections:
							is_reachable = true
							break
							
			var style = StyleBoxFlat.new()
			style.corner_radius_top_left = btn_size / 2
			style.corner_radius_top_right = btn_size / 2
			style.corner_radius_bottom_left = btn_size / 2
			style.corner_radius_bottom_right = btn_size / 2
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.shadow_size = 4
			style.shadow_color = Color(0, 0, 0, 0.4)
			
			if is_visited:
				style.bg_color = Color(0.05, 0.05, 0.07, 0.9)
				style.border_color = Color(0.3, 0.3, 0.3, 0.7)
				btn.modulate = Color(0.5, 0.5, 0.5)
				btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
			elif is_reachable:
				style.bg_color = Color(0.1, 0.12, 0.18, 0.95)
				style.border_color = Color(0.85, 0.65, 0.25) # Gold border for reachable!
				style.shadow_color = Color(0.85, 0.65, 0.25, 0.3)
				style.shadow_size = 6
				btn.modulate = base_color.lightened(0.15)
				btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			else:
				style.bg_color = Color(0.04, 0.04, 0.05, 0.9)
				style.border_color = Color(0.2, 0.2, 0.2, 0.6)
				btn.modulate = Color(0.35, 0.35, 0.35)
				btn.mouse_default_cursor_shape = Control.CURSOR_ARROW
				
			btn.add_theme_stylebox_override("normal", style)
			btn.add_theme_stylebox_override("hover", style)
			btn.add_theme_stylebox_override("pressed", style)
			btn.add_theme_stylebox_override("disabled", style)
			btn.add_theme_font_size_override("font_size", 28)
			
			if is_reachable:
				btn.pressed.connect(_on_node_clicked.bind(node_data))
				
			btn.mouse_entered.connect(func():
				_on_node_hovered(node_data)
				if is_reachable:
					btn.pivot_offset = btn.size / 2
					var tw = create_tween()
					tw.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.1)
			)
			btn.mouse_exited.connect(func():
				_on_node_hover_ended()
				var tw = create_tween()
				tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
			)
				
			map_container.add_child(btn)
			
	# Scroll automático para a layer atual
	await get_tree().process_frame
	var target_layer = min(15, GameGlobals.thor_current_layer)
	var target_y = map_height - (target_layer * layer_height) - (scroll.size.y / 2.0)
	scroll.scroll_vertical = int(max(0, target_y))
	
	# Top Bar
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.05, 0.05, 0.05, 0.95)
	top_bar.custom_minimum_size = Vector2(0, 60)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(top_bar)
	
	var hbox = HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 60)
	top_bar.add_child(hbox)
	
	var hp_label = Label.new()
	hp_label.text = "❤️ HP: %d/%d" % [GameGlobals.thor_hp, GameGlobals.thor_max_hp]
	hp_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(hp_label)
	
	var gold_label = Label.new()
	gold_label.text = "💰 Ouro: %d" % GameGlobals.thor_gold
	gold_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(gold_label)
	
	var deck_label = Label.new()
	var deck_size = GameGlobals.thor_deck.size() if typeof(GameGlobals.thor_deck) == TYPE_ARRAY else 0
	deck_label.text = "🃏 Deck: %d" % deck_size
	deck_label.add_theme_font_size_override("font_size", 22)
	hbox.add_child(deck_label)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	# Title Banner (Fixo abaixo da Top Bar)
	var title_banner = Panel.new()
	title_banner.custom_minimum_size = Vector2(1152, 60)
	title_banner.position = Vector2(0, 60)
	var tb_style = StyleBoxFlat.new()
	tb_style.bg_color = Color(0.06, 0.06, 0.09, 0.85)
	tb_style.border_width_bottom = 2
	tb_style.border_color = Color(0.85, 0.65, 0.25, 0.4)
	title_banner.add_theme_stylebox_override("panel", tb_style)
	add_child(title_banner)
	
	var tb_vbox = VBoxContainer.new()
	tb_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tb_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	tb_vbox.add_theme_constant_override("separation", 2)
	title_banner.add_child(tb_vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "⚡ MAPA DE MIDGARD — ESCOLHA A SUA FASE ⚡" if is_pt else "⚡ MIDGARD MAP — CHOOSE YOUR STAGE ⚡"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		title_lbl.add_theme_font_override("font", font_bold)
	title_lbl.add_theme_font_size_override("font_size", 15)
	title_lbl.add_theme_color_override("font_color", GOLD_COLOR)
	title_lbl.add_theme_constant_override("outline_size", 3)
	title_lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	tb_vbox.add_child(title_lbl)
	
	var subtitle_lbl = Label.new()
	subtitle_lbl.text = "Planeie o seu caminho através dos reinos para enfrentar a Serpente do Mundo!" if is_pt else "Plan your path through the realms to confront the World Serpent!"
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg:
		subtitle_lbl.add_theme_font_override("font", font_reg)
	subtitle_lbl.add_theme_font_size_override("font_size", 9)
	subtitle_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	tb_vbox.add_child(subtitle_lbl)
	
	# Legend Panel (Fixo à esquerda)
	var legend_panel = Panel.new()
	legend_panel.size = Vector2(240, 240)
	legend_panel.position = Vector2(25, 140)
	var legend_style = StyleBoxFlat.new()
	legend_style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	legend_style.border_width_left = 2
	legend_style.border_width_top = 2
	legend_style.border_width_right = 2
	legend_style.border_width_bottom = 2
	legend_style.border_color = Color(0.85, 0.65, 0.25, 0.5)
	legend_style.corner_radius_top_left = 8
	legend_style.corner_radius_top_right = 8
	legend_style.corner_radius_bottom_left = 8
	legend_style.corner_radius_bottom_right = 8
	legend_panel.add_theme_stylebox_override("panel", legend_style)
	add_child(legend_panel)
	
	var leg_vbox = VBoxContainer.new()
	leg_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	leg_vbox.offset_left = 12
	leg_vbox.offset_top = 10
	leg_vbox.offset_right = -12
	leg_vbox.offset_bottom = -10
	leg_vbox.add_theme_constant_override("separation", 6)
	legend_panel.add_child(leg_vbox)
	
	var leg_title = Label.new()
	leg_title.text = "LEGENDA DO MAPA" if is_pt else "MAP LEGEND"
	leg_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		leg_title.add_theme_font_override("font", font_bold)
	leg_title.add_theme_font_size_override("font_size", 12)
	leg_title.add_theme_color_override("font_color", GOLD_COLOR)
	leg_vbox.add_child(leg_title)
	
	var leg_sep = HSeparator.new()
	leg_sep.add_theme_color_override("separator_color", Color(0.85, 0.65, 0.25, 0.3))
	leg_vbox.add_child(leg_sep)
	
	var add_legend_item = func(icon_file: String, text_pt: String, text_en: String):
		var item_hbox = HBoxContainer.new()
		item_hbox.add_theme_constant_override("separation", 10)
		
		# A Panel container to hold the icon to create a nice round golden circular border!
		var icon_panel = Panel.new()
		icon_panel.custom_minimum_size = Vector2(28, 28)
		
		var icon_style = StyleBoxFlat.new()
		icon_style.bg_color = Color(0.08, 0.1, 0.15, 0.9)
		icon_style.border_width_left = 1
		icon_style.border_width_top = 1
		icon_style.border_width_right = 1
		icon_style.border_width_bottom = 1
		icon_style.border_color = Color(0.85, 0.65, 0.25, 0.8) # Gold border!
		icon_style.corner_radius_top_left = 14
		icon_style.corner_radius_top_right = 14
		icon_style.corner_radius_bottom_left = 14
		icon_style.corner_radius_bottom_right = 14
		icon_panel.add_theme_stylebox_override("panel", icon_style)
		
		var icon_tex = TextureRect.new()
		icon_tex.set_anchors_preset(Control.PRESET_FULL_RECT)
		var tex_path = "res://assets/sprites/Sprites Thor/Icones/" + icon_file + ".png"
		if ResourceLoader.exists(tex_path):
			icon_tex.texture = load(tex_path)
		icon_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		# Add margins so the icon doesn't touch borders
		icon_tex.offset_left = 4
		icon_tex.offset_top = 4
		icon_tex.offset_right = -4
		icon_tex.offset_bottom = -4
		icon_panel.add_child(icon_tex)
		
		item_hbox.add_child(icon_panel)
		
		var text_lbl = Label.new()
		text_lbl.text = text_pt if is_pt else text_en
		if font_reg:
			text_lbl.add_theme_font_override("font", font_reg)
		text_lbl.add_theme_font_size_override("font_size", 10)
		text_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
		text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		text_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		item_hbox.add_child(text_lbl)
		
		leg_vbox.add_child(item_hbox)
		
	add_legend_item.call("node_combat", "Combate Normal", "Normal Combat")
	add_legend_item.call("node_elite", "Inimigo Elite", "Elite Enemy")
	add_legend_item.call("node_rest", "Fogueira (Descanso)", "Rest Site (Heal)")
	add_legend_item.call("node_shop", "Mercador (Loja)", "Merchant Shop")
	add_legend_item.call("node_boss", "Chefe Final", "Final Boss")
	
	# Tooltip Panel (Fixo à direita)
	var tooltip_panel = Panel.new()
	tooltip_panel.size = Vector2(240, 240)
	tooltip_panel.position = Vector2(887, 140)
	var tooltip_style = StyleBoxFlat.new()
	tooltip_style.bg_color = Color(0.04, 0.05, 0.08, 0.85)
	tooltip_style.border_width_left = 2
	tooltip_style.border_width_top = 2
	tooltip_style.border_width_right = 2
	tooltip_style.border_width_bottom = 2
	tooltip_style.border_color = Color(0.85, 0.65, 0.25, 0.5)
	tooltip_style.corner_radius_top_left = 8
	tooltip_style.corner_radius_top_right = 8
	tooltip_style.corner_radius_bottom_left = 8
	tooltip_style.corner_radius_bottom_right = 8
	tooltip_panel.add_theme_stylebox_override("panel", tooltip_style)
	add_child(tooltip_panel)
	
	var tool_vbox = VBoxContainer.new()
	tool_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tool_vbox.offset_left = 12
	tool_vbox.offset_top = 10
	tool_vbox.offset_right = -12
	tool_vbox.offset_bottom = -10
	tool_vbox.add_theme_constant_override("separation", 8)
	tooltip_panel.add_child(tool_vbox)
	
	tooltip_title = Label.new()
	tooltip_title.text = "DESTINO" if is_pt else "DESTINATION"
	tooltip_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold:
		tooltip_title.add_theme_font_override("font", font_bold)
	tooltip_title.add_theme_font_size_override("font_size", 12)
	tooltip_title.add_theme_color_override("font_color", GOLD_COLOR)
	tool_vbox.add_child(tooltip_title)
	
	var tool_sep = HSeparator.new()
	tool_sep.add_theme_color_override("separator_color", Color(0.85, 0.65, 0.25, 0.3))
	tool_vbox.add_child(tool_sep)
	
	tooltip_desc = Label.new()
	tooltip_desc.text = "Passe o rato por cima de uma fase para ver os seus detalhes." if is_pt else "Hover over a stage to see its details."
	tooltip_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if font_reg:
		tooltip_desc.add_theme_font_override("font", font_reg)
	tooltip_desc.add_theme_font_size_override("font_size", 10)
	tooltip_desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	tooltip_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tool_vbox.add_child(tooltip_desc)

func _on_node_hovered(node_data: Dictionary):
	if GameGlobals and GameGlobals.has_method("play_hover_sound"):
		GameGlobals.play_hover_sound()
		
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	match node_data.type:
		NodeType.COMBAT:
			tooltip_title.text = "⚔️ COMBATE" if is_pt else "⚔️ COMBAT"
			tooltip_desc.text = "Enfrente criaturas de Midgard.\nVença para ganhar ouro e novas cartas para o seu deck!" if is_pt else "Face creatures of Midgard.\nWin to earn gold and new cards for your deck!"
		NodeType.ELITE:
			tooltip_title.text = "💀 ELITE" if is_pt else "💀 ELITE"
			tooltip_desc.text = "Enfrente um monstro poderoso.\nRecompensa muito mais ouro e melhores cartas!" if is_pt else "Face a powerful monster.\nRewards much more gold and better cards!"
		NodeType.REST:
			tooltip_title.text = "🏕️ FOGUEIRA" if is_pt else "🏕️ REST SITE"
			tooltip_desc.text = "Um local de descanso.\nRecupere 30% do seu HP máximo!" if is_pt else "A safe place to rest.\nRecover 30% of your max HP!"
		NodeType.SHOP:
			tooltip_title.text = "💰 MERCADOR" if is_pt else "💰 MERCHANT"
			tooltip_desc.text = "Visite a loja do mercador.\nGaste o seu ouro para comprar cartas fortes!" if is_pt else "Visit the merchant shop.\nSpend your gold to buy strong cards!"
		NodeType.BOSS:
			tooltip_title.text = "👑 CHEFE FINAL" if is_pt else "👑 FINAL BOSS"
			tooltip_desc.text = "O confronto final contra Jörmungandr!\nDerrote a Serpente do Mundo para vencer o Livro III!" if is_pt else "The final showdown against Jörmungandr!\nDefeat the World Serpent to win Book III!"

func _on_node_hover_ended():
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
		
	tooltip_title.text = "DESTINO" if is_pt else "DESTINATION"
	tooltip_desc.text = "Passe o rato por cima de uma fase para ver os seus detalhes." if is_pt else "Hover over a stage to see its details."

func _on_node_clicked(node_data: Dictionary):
	if GameGlobals and GameGlobals.has_method("play_click_sound"):
		GameGlobals.play_click_sound()
		
	GameGlobals.thor_map_path.append(node_data.id)
	GameGlobals.thor_current_layer = node_data.layer + 1
	GameGlobals.thor_node_id = node_data.id
	
	# Determina qual cena carregar com base no tipo de nó
	var scene_path = "res://scenes/thor_battle.tscn" # COMBAT, ELITE, BOSS
	
	if node_data.type == NodeType.REST:
		scene_path = "res://scenes/thor_rest.tscn"
	elif node_data.type == NodeType.SHOP:
		scene_path = "res://scenes/thor_shop.tscn"
		
	if not ResourceLoader.exists(scene_path):
		# Fallback na pasta raiz, caso movido
		var file_name = scene_path.get_file()
		scene_path = "res://" + file_name
		
	if ResourceLoader.exists(scene_path):
		var transition = get_node_or_null("/root/SceneTransition")
		if transition:
			transition.fade_to(scene_path)
		else:
			get_tree().change_scene_to_file(scene_path)
	else:
		push_error("Cena não encontrada! Esperado: " + scene_path)
