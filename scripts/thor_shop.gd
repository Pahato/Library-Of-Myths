extends Control

# =============================================================================
# THOR SHOP — Loja do Mercador
# Livro III: Thor vs Jörmungandr
# =============================================================================

var font_bold: FontFile = null
var font_reg: FontFile = null
const GOLD_COLOR = Color(1.0, 0.8, 0.2, 1.0)
const ACCENT_COLOR = Color(0.2, 0.5, 0.8, 1.0) # Azul mercador
const CARD_WIDTH = 130
const CARD_HEIGHT = 180

var cards_for_sale: Array = []
var card_prices: Array = []
var gold_label: Label

func _ready():
	font_bold = _load_font(true)
	font_reg = _load_font(false)
	
	_generate_shop_items()
	_build_ui()
	
	if GameGlobals:
		GameGlobals.play_music("res://assets/music/time_for_adventure.mp3", -8.0)

func _load_font(bold: bool = false) -> FontFile:
	var path = "res://assets/fonts/Cinzel-Bold.ttf" if bold else "res://assets/fonts/Cinzel-Regular.ttf"
	var f = FontFile.new()
	if f.load_dynamic_font(path) != OK:
		return null
	return f

func _generate_shop_items():
	var possible_cards = ThorCardDatabase.get_reward_pool(-1)
	possible_cards.shuffle()
	
	for i in range(3):
		if i < possible_cards.size():
			var c_id = possible_cards[i]
			cards_for_sale.append(c_id)
			var c_data = ThorCardDatabase.get_card(c_id)
			var base_price = 40
			if c_data.rarity == ThorCardDatabase.CardRarity.UNCOMMON:
				base_price = 70
			elif c_data.rarity == ThorCardDatabase.CardRarity.RARE:
				base_price = 120
			card_prices.append(randi_range(base_price - 10, base_price + 20))

func _build_ui():
	var bg_color = ColorRect.new()
	bg_color.color = Color(0.05, 0.05, 0.08, 1.0)
	bg_color.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg_color)
	
	var bg_tex = load("res://assets/sprites/Sprites Thor/Cenários/shop_bg.png")
	if bg_tex:
		var bg_rect = TextureRect.new()
		bg_rect.texture = bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
		bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg_rect.modulate = Color(1.0, 1.0, 1.0, 0.5)
		bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(bg_rect)
	
	var is_pt = true
	if GameGlobals:
		is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	
	# Top Bar
	var top_bar = ColorRect.new()
	top_bar.color = Color(0.02, 0.02, 0.04, 0.95)
	top_bar.custom_minimum_size = Vector2(0, 60)
	top_bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	add_child(top_bar)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 60)
	top_bar.add_child(top_hbox)
	
	var current_hp = GameGlobals.thor_hp if GameGlobals else 80
	var max_hp = GameGlobals.thor_max_hp if GameGlobals else 80
	var hp_label = Label.new()
	hp_label.text = "❤️ HP: %d/%d" % [current_hp, max_hp]
	hp_label.add_theme_font_size_override("font_size", 22)
	top_hbox.add_child(hp_label)
	
	gold_label = Label.new()
	var current_gold = GameGlobals.thor_gold if GameGlobals else 100
	gold_label.text = "💰 %s: %d" % ["Ouro" if is_pt else "Gold", current_gold]
	gold_label.add_theme_font_size_override("font_size", 22)
	gold_label.add_theme_color_override("font_color", GOLD_COLOR)
	top_hbox.add_child(gold_label)
	
	# Main Content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.anchor_left = 0.5
	vbox.anchor_top = 0.5
	vbox.anchor_right = 0.5
	vbox.anchor_bottom = 0.5
	vbox.offset_left = -400
	vbox.offset_top = -250
	vbox.offset_right = 400
	vbox.offset_bottom = 250
	vbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	vbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Mercador Anão" if is_pt else "Dwarven Merchant"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold: title.add_theme_font_override("font", font_bold)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	vbox.add_child(title)
	
	# Cards
	var cards_hbox = HBoxContainer.new()
	cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(cards_hbox)
	
	for i in range(cards_for_sale.size()):
		var c_id = cards_for_sale[i]
		var price = card_prices[i]
		var card_data = ThorCardDatabase.get_card(c_id)
		
		var card_vbox = VBoxContainer.new()
		card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		card_vbox.add_theme_constant_override("separation", 10)
		cards_hbox.add_child(card_vbox)
		
		var c_panel = _create_card_button(card_data)
		card_vbox.add_child(c_panel)
		
		var buy_btn = Button.new()
		buy_btn.text = "💰 " + str(price)
		buy_btn.custom_minimum_size = Vector2(100, 35)
		buy_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.2, 0.15, 0.05, 0.9)
		sb.border_width_left = 2; sb.border_width_top = 2; sb.border_width_right = 2; sb.border_width_bottom = 2
		sb.border_color = GOLD_COLOR
		sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6; sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
		buy_btn.add_theme_stylebox_override("normal", sb)
		
		buy_btn.pressed.connect(func():
			if GameGlobals and GameGlobals.thor_gold >= price:
				GameGlobals.thor_gold -= price
				GameGlobals.thor_deck.append(c_id)
				_update_gold_label()
				GameGlobals.play_click_sound()
				buy_btn.disabled = true
				buy_btn.text = "Comprado" if is_pt else "Bought"
				c_panel.modulate = Color(0.3, 0.3, 0.3, 0.5)
		)
		card_vbox.add_child(buy_btn)
	
	# Services
	var services_hbox = HBoxContainer.new()
	services_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	services_hbox.add_theme_constant_override("separation", 30)
	vbox.add_child(services_hbox)
	
	# Heal Service
	var heal_price = 30
	var heal_btn = Button.new()
	heal_btn.text = ("Curar 20 HP (💰 %d)" % heal_price) if is_pt else ("Heal 20 HP (💰 %d)" % heal_price)
	heal_btn.custom_minimum_size = Vector2(200, 45)
	_style_service_btn(heal_btn)
	heal_btn.pressed.connect(func():
		if GameGlobals and GameGlobals.thor_gold >= heal_price and GameGlobals.thor_hp < GameGlobals.thor_max_hp:
			GameGlobals.thor_gold -= heal_price
			GameGlobals.thor_hp = mini(GameGlobals.thor_hp + 20, GameGlobals.thor_max_hp)
			_update_gold_label()
			hp_label.text = "❤️ HP: %d/%d" % [GameGlobals.thor_hp, GameGlobals.thor_max_hp]
			GameGlobals.play_click_sound()
			heal_btn.disabled = true
	)
	services_hbox.add_child(heal_btn)
	
	# Max HP Service
	var maxhp_price = 75
	var maxhp_btn = Button.new()
	maxhp_btn.text = ("+10 Max HP (💰 %d)" % maxhp_price) if is_pt else ("+10 Max HP (💰 %d)" % maxhp_price)
	maxhp_btn.custom_minimum_size = Vector2(200, 45)
	_style_service_btn(maxhp_btn)
	maxhp_btn.pressed.connect(func():
		if GameGlobals and GameGlobals.thor_gold >= maxhp_price:
			GameGlobals.thor_gold -= maxhp_price
			GameGlobals.thor_max_hp += 10
			GameGlobals.thor_hp += 10
			_update_gold_label()
			hp_label.text = "❤️ HP: %d/%d" % [GameGlobals.thor_hp, GameGlobals.thor_max_hp]
			GameGlobals.play_click_sound()
			maxhp_btn.disabled = true
	)
	services_hbox.add_child(maxhp_btn)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer)
	
	# Leave
	var leave_btn = Button.new()
	leave_btn.text = "Sair da Loja" if is_pt else "Leave Shop"
	leave_btn.custom_minimum_size = Vector2(250, 50)
	leave_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if font_bold: leave_btn.add_theme_font_override("font", font_bold)
	leave_btn.add_theme_font_size_override("font_size", 16)
	
	var c_sb = StyleBoxFlat.new()
	c_sb.bg_color = ACCENT_COLOR.darkened(0.4)
	c_sb.border_width_left = 2; c_sb.border_width_top = 2; c_sb.border_width_right = 2; c_sb.border_width_bottom = 2
	c_sb.border_color = ACCENT_COLOR
	c_sb.corner_radius_top_left = 6; c_sb.corner_radius_top_right = 6; c_sb.corner_radius_bottom_left = 6; c_sb.corner_radius_bottom_right = 6
	leave_btn.add_theme_stylebox_override("normal", c_sb)
	
	leave_btn.pressed.connect(func():
		if GameGlobals: GameGlobals.play_click_sound()
		var transition = get_node_or_null("/root/SceneTransition")
		if transition: transition.fade_to("res://scenes/thor_map.tscn")
		else: get_tree().change_scene_to_file("res://scenes/thor_map.tscn")
	)
	vbox.add_child(leave_btn)

func _style_service_btn(btn: Button):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	sb.border_width_left = 2; sb.border_width_top = 2; sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color = Color(0.4, 0.4, 0.5)
	sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6; sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
	btn.add_theme_stylebox_override("normal", sb)

func _update_gold_label():
	var is_pt = true
	if GameGlobals: is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	var current_gold = GameGlobals.thor_gold if GameGlobals else 0
	gold_label.text = "💰 %s: %d" % ["Ouro" if is_pt else "Gold", current_gold]

func _create_card_button(card: Dictionary) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
	
	var card_color: Color
	match card.type:
		ThorCardDatabase.CardType.ATTACK: card_color = Color(0.6, 0.15, 0.15, 1.0)
		ThorCardDatabase.CardType.SKILL: card_color = Color(0.15, 0.3, 0.6, 1.0)
		ThorCardDatabase.CardType.POWER: card_color = Color(0.5, 0.35, 0.1, 1.0)
		_: card_color = Color(0.2, 0.2, 0.2, 1.0)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = card_color
	sb.border_width_left = 2; sb.border_width_top = 2; sb.border_width_right = 2; sb.border_width_bottom = 2
	sb.border_color = card_color.lightened(0.3)
	if card.rarity == ThorCardDatabase.CardRarity.RARE:
		sb.border_color = GOLD_COLOR
	
	sb.corner_radius_top_left = 6; sb.corner_radius_top_right = 6; sb.corner_radius_bottom_left = 6; sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 6; vbox.offset_top = 6; vbox.offset_right = -6; vbox.offset_bottom = -6
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)
	
	var is_pt = true
	if GameGlobals: is_pt = GameGlobals.current_language == GameGlobals.Language.PT
	
	var name_lbl = Label.new()
	name_lbl.text = card.name_pt if is_pt else card.name_en
	name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_bold: name_lbl.add_theme_font_override("font", font_bold)
	name_lbl.add_theme_font_size_override("font_size", 10)
	name_lbl.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_lbl)
	
	var sep = HSeparator.new()
	sep.add_theme_color_override("separator_color", card_color.lightened(0.3))
	vbox.add_child(sep)
	
	var desc_lbl = Label.new()
	desc_lbl.text = card.desc_pt if is_pt else card.desc_en
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if font_reg: desc_lbl.add_theme_font_override("font", font_reg)
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_lbl)
	
	return panel
