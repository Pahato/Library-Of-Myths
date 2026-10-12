import os

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove duplicate function and fix timer connection
content = content.replace(
    '''var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_awakening_step_5_intense_vfx)

func _awakening_step_5_intense_vfx():
	# Despertar elétrico intenso (VFX fortes)
	# Thor desperta - flash mais forte
	var flash = ColorRect.new()
	flash.color = Color(0.3, 0.7, 1.0, 1.0) # Azul elétrico
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cinematic_overlay.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func(): flash.queue_free())
	
	# Som muito forte de trovão
	_play_sfx("explosion", 1.0, 0.0)
	
	# Efeitos visuais no sprite do Thor
	if player_node:
		var anim_sprite = player_node.get_node_or_null("AnimatedSprite2D")
		if anim_sprite:
			# Modulate para brilho elétrico
			var tween2 = create_tween()
			tween2.tween_property(anim_sprite, "modulate", Color(1.5, 1.5, 2.0, 1.0), 0.2)
			tween2.tween_property(anim_sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
		# Partículas intensas
		if thunder_particles:
			thunder_particles.amount = 100
			thunder_particles.scale_amount_min = 3.0
			thunder_particles.scale_amount_max = 6.0
			thunder_particles.color = Color(0.3, 0.8, 1.0, 1.0)
	
	# Screen shake forte
	_shake_node(player_node)
	_shake_node(enemy_panel)
	
	var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_awakening_step_6_jormungandr_reaction)

func _awakening_step_6_jormungandr_reaction():''',
    '''var timer = get_tree().create_timer(1.0)
	timer.timeout.connect(_awakening_step_6_jormungandr_reaction)

func _awakening_step_6_jormungandr_reaction():'''
)

with open('scripts/thor_jormungandr/thor_battle.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done fixing duplicate function')