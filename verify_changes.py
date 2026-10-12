import os

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

# Check card database
with open('scripts/thor_jormungandr/thor_card_database.gd', 'r', encoding='utf-8') as f:
    c = f.read()

print('=== Card Database Check ===')
print('cost 2:', 'cost\": 2' in c)
print('skip_enemy_turn:', 'skip_enemy_turn' in c)
print('desc contains prender:', 'prende o inimigo' in c or 'prende o inimigo' in c)

# Check game_globals
with open('scripts/game_globals.gd', 'r', encoding='utf-8') as f:
    g = f.read()

print('\n=== Game Globals Check ===')
print('dialogue_awakening_thor_new:', 'dialogue_awakening_thor_new' in g)
print('dialogue_awakening_jormungandr_new:', 'dialogue_awakening_jormungandr_new' in g)
print('Thor new text PT:', 'Não posso cair aqui' in g)
print('Jormungandr new text PT:', 'continuas a resistir' in g)

# Check battle script
with open('scripts/thor_jormungandr/thor_battle.gd', 'r', encoding='utf-8') as f:
    b = f.read()

print('\n=== Battle Script Check ===')
print('enemy_skip_turn var:', 'enemy_skip_turn' in b)
print('skip_enemy_turn effect:', 'skip_enemy_turn' in b)
print('Cadeia de Fenrir effect handling:', 'enemy_skip_turn = effect.skip_enemy_turn' in b)
print('Stack prevention:', 'enemy_skip_turn > 0' in b)
print('Narrative protection:', 'not (state == BattleState.CINEMATIC_DEATH' in b)
print('New dialogue Thor:', 'dialogue_awakening_thor_new' in b)
print('New dialogue Jörmungandr:', 'dialogue_awakening_jormungandr_new' in g)
print('Awakening step 4 renamed:', '_awakening_step_4_thor_awakens' in b)
print('Intense VFX function:', '_awakening_step_5_intense_vfx' in b)
print('Jörmungandr reaction step:', '_awakening_step_6_jormungandr_reaction' in b)
print('New Jörmungandr dialogue:', 'dialogue_awakening_jormungandr_new' in b)
print('Skip turn check in execute:', 'enemy_skip_turn > 0' in b)
print('Narrative protection in execute:', 'not (state == BattleState.CINEMATIC_DEATH' in b)