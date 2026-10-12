import os
import re

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Find the function
idx = content.find('func _get_card_img_name(card_id: String) -> String:')
if idx == -1:
    print('Function not found')
    exit(1)

# Find the end of the function
end_idx = content.find('\nfunc ', content.find('\n', content.find('func _get_card_img_name')))
if idx == -1:
    end_idx = len(content)

old_func = content[idx:end_idx]
print('Found function, length:', len(content[idx:idx+500]))

# The exact old function content (from the file)
old_func = '''func _get_card_img_name(card_id: String) -> String:
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
		"mjolnir_desperto": return "card_mjolnir_wrath"
		"surto_temporal": return "card_lightning_storm"
		"trovao_estrondeante": return "card_thunder"
		"egide_asgard": return "card_divine_armor"
		"reflexos_relampago": return "card_odins_blessing"
		"poder_odin": return "card_odins_blessing"
		"golpe_ragnarok": return "card_mjolnir_wrath"
		"graca_valhalla": return "card_valhalla"
		_: return ""'''

new_func = '''func _get_card_img_name(card_id: String) -> String:
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
		# Novas cartas do Awakening (usam ficheiros PNG com o mesmo nome do ID)
		"mjolnir_desperto": return "mjolnir_desperto"
		"surto_temporal": return "surto_temporal"
		"trovao_estrondeante": return "trovao_estrondeante"
		"egide_asgard": return "egide_asgard"
		"reflexos_relampago": return "reflexos_relampago"
		"poder_odin": return "poder_odin"
		"golpe_ragnarok": return "golpe_ragnarok"
		"graca_valhalla": return "graca_valhalla"
		_: return ""'''

with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    content = f.read()

old_func = '''func _get_card_img_name(card_id: String) -> String:
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
		"mjolnir_desperto": return "card_mjolnir_wrath"
		"surto_temporal": return "card_lightning_storm"
		"trovao_estrondeante": return "card_thunder"
		"egide_asgard": return "card_divine_armor"
		"reflexos_relampago": return "card_odins_blessing"
		"poder_odin": return "card_odins_blessing"
		"golpe_ragnarok": return "card_mjolnir_wrath"
		"graca_valhalla": return "card_valhalla"
		_: return ""'''

new_func = '''func _get_card_img_name(card_id: String) -> String:
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
		# Novas cartas do Awakening (usam ficheiros PNG com o mesmo nome do ID)
		"mjolnir_desperto": return "mjolnir_desperto"
		"surto_temporal": return "surto_temporal"
		"trovao_estrondeante": return "trovao_estrondeante"
		"egide_asgard": return "egide_asgard"
		"reflexos_relampago": return "reflexos_relampago"
		"poder_odin": return "poder_odin"
		"golpe_ragnarok": return "golpe_ragnarok"
		"graca_valhalla": return "graca_valhalla"
		_: return ""'''

with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    content = f.read()

if old_func in content:
    content = content.replace(old_func, new_func)
    with open('scripts/thor_jormungandr/thor_battle.gd', 'w', encoding='utf-8') as f:
        content.write(content)
    print("Replacement successful!")
else:
    print("Old function not found exactly")
    # Show what we have
    idx = content.find('func _get_card_img_name')
    if idx >= 0:
        print("Found at:", idx)
        print(repr(content[idx:idx+500]))