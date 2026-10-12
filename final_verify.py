import os

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

with open('scripts/thor_jormungandr/thor_map.gd', 'r', encoding='utf-8') as f: m = f.read()
with open('scripts/thor_jormungandr/thor_enemy_database.gd', 'r', encoding='utf-8') as f: e = f.read()
with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f: b = f.read()
with open('scripts/game_globals.gd', 'r', encoding='utf-8') as f: g = f.read()
with open('scripts/thor_jormungandr/thor_card_database.gd', 'r', encoding='utf-8') as f: c = f.read()

checks = {
    'Map: 3 elites fixed layers': 'elite_layer_indices' in m and 'elite_assignments' in m,
    'Map: Elite act matching': 'hel_rainha' in m and 'fenrir_gigante' in m and 'gigante_gelo' in m,
    'Map: Mandatory elite': 'mandatory_elite_layer' in m,
    'Map: Elite data in nodes': 'elite_data' in m,
    'Map: Normal boss predecessors REST': 'current_difficulty == GameGlobals.Difficulty.NORMAL' in m,
    'Battle: Elite specific ID': 'thor_current_elite' in b,
    'Battle: Weighted enemies': 'get_weighted_normal_enemy' in b,
    'Battle: Skip turn var': 'enemy_skip_turn' in b,
    'Battle: Skip effect': 'skip_enemy_turn' in b,
    'Battle: Narrative protection': 'CINEMATIC_DEATH' in b and 'CINEMATIC_AWAKENING' in b,
    'Battle: Skip turn logic': 'enemy_skip_turn > 0' in b,
    'Battle: Narrative protection in execute': 'not (state == BattleState.CINEMATIC_DEATH' in b,
    'DB: Weighted enemy function': 'get_weighted_normal_enemy' in e,
    'DB: Weights 30/20/30/20': all(x in e for x in ['corvos_hel', 'draugr', 'esqueleto_viking', 'lobo_fenrir']),
    'DB: Cadeia de Fenrir cost 2': 'cost": 2' in c and 'cadeia_fenrir' in c,
    'DB: Cadeia skip_enemy_turn': 'skip_enemy_turn' in c,
    'Globals: thor_current_elite': 'thor_current_elite' in g,
    'Globals: New dialogues': all(x in g for x in ['dialogue_awakening_thor_new', 'dialogue_awakening_jormungandr_new']),
    'Battle: New Thor dialogue': 'dialogue_awakening_thor_new' in b,
    'Battle: New Jormungandr dialogue': 'dialogue_awakening_jormungandr_new' in b,
    'Battle: Awakening steps': all(x in b for x in ['_awakening_step_4_thor_awakens', '_awakening_step_5_intense_vfx', '_awakening_step_6_jormungandr_reaction', '_awakening_step_7_transition_to_phase2']),
    'Battle: 999 visual isolation': 'cinematic_highlight' in b and 'pulse_tween' in b,
    'Battle: Skip turn logic in execute': 'enemy_skip_turn > 0' in b,
    'Battle: Narrative protection in execute': 'CINEMATIC_DEATH' in b and 'CINEMATIC_AWAKENING' in b,
}

print('=== FINAL VERIFICATION ===')
all_pass = True
for name, result in checks.items():
    status = 'PASS' if result else 'FAIL'
    if not result: all_pass = False
    print(f'  [{status}] {name}')

print()
if all_pass:
    print('ALL CHECKS PASSED!')
else:
    print('SOME CHECKS FAILED!')