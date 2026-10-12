import os
import re

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the function name and comment for step 4
content = content.replace(
    'func _awakening_step_4_jormungandr_reaction():\n\t# Thor desperta - flash mais forte (sem diálogo)',
    'func _awakening_step_4_thor_awakens():\n\t# Thor fala: "Não posso cair aqui... Mjölnir... chegou a hora de despertar!"'
)

# Replace the timer connection
content = content.replace(
    'timer.timeout.connect(_awakening_step_4_jormungandr_reaction)',
    'timer.timeout.connect(_awakening_step_4_thor_awakens)'
)

# Replace the entire step 4 function and add new functions
old_step4 = '''func _awakening_step_4_jormungandr_reaction():
	# Thor desperta - flash mais forte (sem diálogo)
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
	timer.timeout.connect(_awakening_step_5_transition_to_phase2)

func _awakening_step_5_transition_to_phase2:'''

new_step4 = '''func _awakening_step_4_thor_awakens():
	# Thor fala: "Não posso cair aqui... Mjölnir... chegou a hora de despertar!"
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_thor", "text": "dialogue_awakening_thor_new"}
	]
	d.dialogue_finished.connect(_awakening_step_5_intense_vfx)
	add_child(d)

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

func _awakening_step_6_jormungandr_reaction():
	# Jörmungandr reage: "Impossível... continuas a resistir ao meu veneno?!"
	var d = dialogue_scene.instantiate()
	d.dialogue_list = [
		{"name": "char_jormungandr", "text": "dialogue_awakening_jormungandr_new"}
	]
	d.dialogue_finished.connect(_awakening_step_7_transition_to_phase2)
	add_child(d)

func _awakening_step_7_transition_to_phase2:'''

content = content.replace(old_step4, new_step4)

with open('scripts/thor_jormungandr/thor_battle.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')