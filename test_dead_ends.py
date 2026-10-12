import os
import random

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

def test_dead_ends(difficulty, num_runs=100):
    class NodeType:
        COMBAT = 0
        ELITE = 1
        REST = 2
        SHOP = 3
        BOSS = 4

    class MockGameGlobals:
        class Difficulty:
            EASY = 0
            NORMAL = 1
            HARD = 2
        current_difficulty = Difficulty.NORMAL

    GameGlobals = MockGameGlobals()

    total_dead_ends = 0
    total_unreachable = 0
    boss_reachable_count = 0
    all_paths_count = 0
    failed_seeds = []

    for run in range(num_runs):
        rng = random.Random(run)

        if difficulty == GameGlobals.Difficulty.EASY:
            total_layers = 8
        else:
            total_layers = 15

        elite_definitions = [
            {"id": "hel_rainha", "acts": [1]},
            {"id": "fenrir_gigante", "acts": [2, 3]},
            {"id": "gigante_gelo", "acts": [2, 3]}
        ]

        elite_layer_indices = []
        elite_assignments = {}

        if total_layers == 8:  # EASY
            chosen_elite = random.choice(elite_definitions)

            if chosen_elite["id"] == "hel_rainha":
                valid_layers = [2, 3, 4, 5]
            else:
                valid_layers = [6, 7]

            chosen_layer = random.choice(valid_layers)
            elite_layer_indices = [chosen_layer]
            elite_assignments = {chosen_layer: chosen_elite["id"]}
            mandatory_elite_layer = chosen_layer
        else:
            elite_layer_indices = [5, 10, 13]
            elite_assignments = {
                5: "hel_rainha",
                10: "fenrir_gigante",
                13: "gigante_gelo"
            }
            mandatory_elite_layer = elite_layer_indices[1]

        layers = {}
        elite_nodes_created = {}

        rng = random.Random(run)

        for layer_idx in range(1, total_layers + 1):
            nodes_in_layer = []

            if layer_idx == 1:
                num_nodes = rng.randint(2, 3)
            elif layer_idx == total_layers:
                num_nodes = 1
            else:
                num_nodes = rng.randint(2, 4)

            has_elite_slot = layer_idx in elite_layer_indices
            elite_id_for_layer = elite_assignments.get(layer_idx, "")
            elite_data_for_layer = None
            if elite_id_for_layer:
                for et in elite_definitions:
                    if et['id'] == elite_id_for_layer:
                        elite_data_for_layer = et
                        break

            is_bottleneck_layer = (layer_idx == mandatory_elite_layer)

            for i in range(num_nodes):
                node_type = 0
                elite_data = None

                if layer_idx == 1:
                    node_type = 0
                elif layer_idx == total_layers:
                    node_type = 4
                elif has_elite_slot and i == 0:
                    node_type = 1
                else:
                    roll = rng.random()
                    if roll < 0.55:
                        node_type = 0
                    elif roll < 0.70:
                        node_type = 2
                    elif roll < 0.85:
                        node_type = 3
                    else:
                        node_type = 0

                nodes_in_layer.append({
                    'id': f"{layer_idx}_{i}",
                    'layer': layer_idx,
                    'index': i,
                    'type': node_type,
                    'connections': [],
                })

            layers[layer_idx] = nodes_in_layer

        # Generate connections with bottleneck logic (FIXED - no removal of non-bottleneck connections)
        for layer_idx in range(1, total_layers):
            current_layer_nodes = layers[layer_idx]
            next_layer_nodes = layers[layer_idx + 1]

            bottleneck_node = None
            if layer_idx == mandatory_elite_layer:
                for node in current_layer_nodes:
                    if node['type'] == 1:
                        bottleneck_node = node
                        break

            for c_node in current_layer_nodes:
                target = next_layer_nodes[rng.randint(0, len(next_layer_nodes) - 1)]
                if target['id'] not in c_node['connections']:
                    c_node['connections'].append(target['id'])

            for n_node in next_layer_nodes:
                has_connection = False
                for c_node in current_layer_nodes:
                    if n_node['id'] in c_node['connections']:
                        has_connection = True
                        break
                if not has_connection:
                    source = rng.choice(current_layer_nodes)
                    if n_node['id'] not in source['connections']:
                        source['connections'].append(n_node['id'])

            if bottleneck_node:
                bottleneck_node['connections'] = []
                for n_node in next_layer_nodes:
                    bottleneck_node['connections'].append(n_node['id'])
                for n_node in next_layer_nodes:
                    if bottleneck_node['id'] not in n_node['connections']:
                        n_node['connections'].append(bottleneck_node['id'])

        # Check for dead ends
        dead_ends = 0
        for layer_idx in range(1, total_layers):
            for node in layers[layer_idx]:
                has_next_layer_connection = False
                for conn_id in node['connections']:
                    for node in layers[layer_idx + 1]:
                        if node['id'] == conn_id:
                            has_next_layer_connection = True
                            break
                    if has_next_layer_connection:
                        break

                if not has_next_layer_connection and node['type'] != 4:
                    dead_ends += 1

        # Check connectivity from start to boss
        start_nodes = layers[1]
        boss_layer = layers[total_layers]

        reachable = set()
        queue = [n['id'] for n in start_nodes]

        while queue:
            node_id = queue.pop(0)
            if node_id in reachable:
                continue
            reachable.add(node_id)

            current = None
            for layer_nodes in layers.values():
                for n in layer_nodes:
                    if n['id'] == node_id:
                        current = n
                        break

            if not current:
                continue

            if current['type'] == 4:
                continue

            for conn_id in current['connections']:
                if conn_id not in reachable:
                    queue.append(conn_id)

        boss_reachable = any(n['id'] in reachable for n in layers[total_layers])

        unreachable = 0
        for layer_idx in range(1, total_layers):
            for node in layers[layer_idx]:
                if node['id'] not in reachable:
                    unreachable += 1

        all_paths_to_boss = True
        for start_node in layers[1]:
            visited = set()
            queue = [start_node['id']]
            found_boss = False

            while queue:
                node_id = queue.pop(0)
                if node_id in visited:
                    continue
                visited.add(node_id)

                current = None
                for layer_nodes in layers.values():
                    for n in layer_nodes:
                        if n['id'] == node_id:
                            current = n
                            break

                if not current:
                    continue

                if current['type'] == 4:
                    found_boss = True
                    break

                for conn_id in current['connections']:
                    if conn_id not in visited:
                        queue.append(conn_id)

            if not found_boss:
                all_paths_to_boss = False
                break

        return {
            'total_dead_ends': dead_ends,
            'total_unreachable': unreachable,
            'boss_reachable_rate': boss_reachable,
            'all_paths_rate': all_paths_to_boss,
            'failed_seeds': failed_seeds if 'failed_seeds' in locals() else []
        }

    for run in range(num_runs):
        result = test_dead_ends(difficulty, 1)
        total_dead_ends += result['dead_ends']
        total_unreachable += result['unreachable_nodes']
        if result['boss_reachable']:
            boss_reachable_count += 1
        if result['all_paths_to_boss']:
            all_paths_count += 1
        if result['dead_ends'] > 0 or not result['boss_reachable'] or not result['all_paths_to_boss']:
            failed_seeds.append(run)

    return {
        'total_dead_ends': total_dead_ends,
        'total_unreachable': total_unreachable,
        'boss_reachable_rate': boss_reachable_count / num_runs,
        'all_paths_rate': all_paths_count / num_runs,
        'failed_seeds': failed_seeds
    }

# Run tests
print("=== DEAD END DETECTION TESTS ===\n")

for difficulty_name, diff_val in [('EASY', 0), ('NORMAL', 1), ('HARD', 2)]:
    print(f"\n=== {difficulty_name} Difficulty ===")
    result = test_dead_ends(diff_val, 100)
    print(f"  Runs: {100}")
    print(f"  Total dead ends: {result['total_dead_ends']}")
    print(f"  Total unreachable nodes: {result['total_unreachable']}")
    print(f"  Boss reachable rate: {result['boss_reachable_rate']:.2%}")
    print(f"  All paths to boss rate: {result['all_paths_rate']:.2%}")
    print(f"  Failed seeds: {len(result['failed_seeds'])}")
    if result['failed_seeds']:
        print(f"  Failed seeds: {result['failed_seeds'][:10]}")

print("\n=== SUMMARY ===")
print("Tests completed. Check results above.")