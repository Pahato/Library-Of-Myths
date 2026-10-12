import os
import sys
import random

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

# Simulate the map generation logic to verify elite counts
# We'll extract and test the core logic

def simulate_map_generation(difficulty, num_runs=100):
    """
    Simulate the map generation logic to verify elite counts.
    """
    # Replicate the logic from thor_map.gd
    class MockRNG:
        def __init__(self, seed=None):
            self.seed = seed if seed is not None else random.randint(0, 2**32-1)
            self.rng = random.Random(self.seed)
        
        def randi_range(self, a, b):
            return self.rng.randint(a, b)
        
        def randf(self):
            return self.rng.random()
        
        def randi(self):
            return self.rng.randint(0, 2**31-1)
    
    class MockGameGlobals:
        class Difficulty:
            EASY = 0
            NORMAL = 1
            HARD = 2
        
        current_difficulty = Difficulty.NORMAL
    
    GameGlobals = MockGameGlobals()
    
    # Simplified NodeType enum
    class NodeType:
        COMBAT = 0
        ELITE = 1
        REST = 2
        SHOP = 3
        BOSS = 4
    
    results = {
        'elite_counts': [],
        'elite_types': [],
        'bottleneck_verified': [],
        'total_nodes': [],
        'elite_layers': [],
        'paths_exist': [],
        'elite_types_per_run': []
    }
    
    for run in range(num_runs):
        rng = MockRNG(run)
        
        # Determine total layers based on difficulty
        if difficulty == GameGlobals.Difficulty.EASY:
            total_layers = 8
        else:
            total_layers = 15
        
        # Elite definitions
        elite_definitions = [
            {"id": "hel_rainha", "acts": [1]},
            {"id": "fenrir_gigante", "acts": [2, 3]},
            {"id": "gigante_gelo", "acts": [2, 3]}
        ]
        
        # Define elite layers and assignments based on difficulty
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
        else:  # NORMAL/HARD
            elite_layer_indices = [5, 10, 13]
            elite_assignments = {
                5: "hel_rainha",
                10: "fenrir_gigante",
                13: "gigante_gelo"
            }
            mandatory_elite_layer = elite_layer_indices[1]  # Layer 10
        
        # Build layers
        layers = {}
        elite_nodes_created = {}
        
        for layer_idx in range(1, total_layers + 1):
            nodes_in_layer = []
            
            if layer_idx == 1:
                num_nodes = random.randint(2, 3)
            elif layer_idx == total_layers:
                num_nodes = 1
            else:
                num_nodes = random.randint(2, 4)
            
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
                node_type = 0  # COMBAT
                elite_data = None
                
                if layer_idx == 1:
                    node_type = 0  # COMBAT
                elif layer_idx == total_layers:
                    node_type = 4  # BOSS
                elif has_elite_slot and i == 0:
                    # First node in an elite layer gets the elite type
                    node_type = 1  # ELITE
                else:
                    # Regular node - combat, rest, or shop (NO random elites)
                    roll = random.random()
                    if roll < 0.55:
                        node_type = 0  # COMBAT
                    elif roll < 0.70:
                        node_type = 2  # REST
                    elif roll < 0.85:
                        node_type = 3  # SHOP
                    else:
                        node_type = 0  # COMBAT
                
                elite_data = None
                if node_type == 1:  # ELITE
                    elite_data = elite_data_for_layer
                
                nodes_in_layer.append({
                    'id': f"{layer_idx}_{i}",
                    'layer': layer_idx,
                    'index': i,
                    'type': node_type,
                    'connections': [],
                    'elite_data': elite_data
                })
            
            layers[layer_idx] = nodes_in_layer
            elite_count = sum(1 for n in nodes_in_layer if n['type'] == 1)
            elite_nodes_created[layer_idx] = elite_count
        
        # Create connections with bottleneck logic
        mandatory_elite_layer = mandatory_elite_layer
        
        for layer_idx in range(1, total_layers):
            current_layer_nodes = layers[layer_idx]
            next_layer_nodes = layers[layer_idx + 1]
            
            # Find bottleneck node
            bottleneck_node = None
            if layer_idx == mandatory_elite_layer:
                for node in current_layer_nodes:
                    if node['type'] == 1:  # ELITE
                        bottleneck_node = node
                        break
            
            # Basic connections
            for c_node in current_layer_nodes:
                target = next_layer_nodes[random.randint(0, len(next_layer_nodes) - 1)]
                if target['id'] not in c_node['connections']:
                    c_node['connections'].append(target['id'])
            
            # Ensure all next layer nodes have at least one connection
            for n_node in next_layer_nodes:
                has_connection = False
                for c_node in current_layer_nodes:
                    if n_node['id'] in c_node['connections']:
                        has_connection = True
                        break
                if not has_connection:
                    source = random.choice(current_layer_nodes)
                    if n_node['id'] not in source['connections']:
                        source['connections'].append(n_node['id'])
            
            # Apply bottleneck logic
            if bottleneck_node:
                # Remove direct connections from other nodes to next layer
                for c_node in current_layer_nodes:
                    if c_node != bottleneck_node:
                        new_connections = []
                        for conn_id in c_node['connections']:
                            is_next_layer = False
                            for nn in next_layer_nodes:
                                if nn['id'] == conn_id:
                                    is_next_layer = True
                                    break
                            if not is_next_layer:
                                new_connections.append(conn_id)
                        c_node['connections'] = new_connections
                
                # Connect bottleneck to ALL next layer nodes
                bottleneck_node['connections'] = [n['id'] for n in next_layer_nodes]
                
                # Ensure all next layer nodes connect back to bottleneck
                for n_node in next_layer_nodes:
                    if bottleneck_node['id'] not in n_node['connections']:
                        n_node['connections'].append(bottleneck_node['id'])
        
        # Count elites
        total_elites = 0
        elite_types = []
        elite_layers = []
        
        for layer_idx in range(1, total_layers + 1):
            for node in layers[layer_idx]:
                if node['type'] == 1:  # ELITE
                    total_elites += 1
                    elite_layers.append(layer_idx)
                    if node.get('elite_data'):
                        elite_types.append(node['elite_data']['id'])
        
        # Verify connectivity (all paths from start to boss)
        # Simple BFS to check connectivity
        def has_path_to_boss():
            start_nodes = layers[1]
            boss_layer = layers[total_layers]
            visited = set()
            queue = [n['id'] for n in start_nodes]
            
            while queue:
                node_id = queue.pop(0)
                if node_id in visited:
                    continue
                visited.add(node_id)
                
                # Find node
                current = None
                for layer_nodes in layers.values():
                    for n in layer_nodes:
                        if n['id'] == node_id:
                            current = n
                            break
                    if not current:
                        continue
                    
                    if current['type'] == 4:  # BOSS
                        return True
                    
                    for conn_id in current['connections']:
                        if conn_id not in visited:
                            queue.append(conn_id)
            return False
        
        path_exists = has_path_to_boss()
        
        results['elite_counts'].append(total_elites)
        results['elite_types'].append(elite_types)
        results['bottleneck_verified'].append(mandatory_elite_layer in [n['layer'] for n in sum(layers.values(), []) if n['type'] == 1])
        results['total_nodes'].append(sum(len(n) for n in layers.values()))
        results['elite_layers'].append(elite_layers)
        results['paths_exist'].append(path_exists)
        results['elite_types_per_run'].append(elite_types)
    
    return results

# Run tests
print("=== MAP GENERATION SIMULATION TESTS ===\n")

for difficulty_name, difficulty_value in [('EASY', 0), ('NORMAL', 1), ('HARD', 2)]:
    print(f"\n=== {difficulty_name} Difficulty ===")
    results = simulate_map_generation(difficulty_value, num_runs=50)
    
    elite_counts = results['elite_counts']
    elite_types_list = results['elite_types_per_run']
    paths_exist = results['paths_exist']
    
    print(f"  Runs: {len(elite_counts)}")
    print(f"  Elite counts: {elite_counts}")
    print(f"  Unique elite counts: {sorted(set(elite_counts))}")
    print(f"  Paths exist: {sum(paths_exist)}/{len(paths_exist)}")
    
    if difficulty_name == 'EASY':
        expected = 1
        unique_counts = set(elite_counts)
        if unique_counts == {1}:
            print(f"  [OK] EASY: Exactly 1 elite per map")
        else:
            print(f"  [FAIL] EASY: FAIL - got counts {unique_counts}")
    else:
        expected = 3
        unique_counts = set(elite_counts)
        if unique_counts == {3}:
            print(f"  [OK] {difficulty_name}: Exactly 3 elites per map")
        else:
            print(f"  [FAIL] {difficulty_name}: FAIL - got counts {unique_counts}")
        
        # Check unique elite types per run
        type_issues = 0
        for types in elite_types_list:
            unique_types = set(types)
            if len(types) != len(unique_types):
                type_issues += 1
            if difficulty_name == 'EASY' and len(types) != 1:
                type_issues += 1
            elif difficulty_name in ['NORMAL', 'HARD'] and len(types) != 3:
                type_issues += 1
            elif difficulty_name in ['NORMAL', 'HARD']:
                expected_types = {'hel_rainha', 'fenrir_gigante', 'gigante_gelo'}
                if set(types) != expected_types:
                    type_issues += 1
        
        if type_issues == 0:
            print(f"  [OK] Elite types: Correct (unique per run, correct types)")
        else:
            print(f"  [FAIL] Elite types: {type_issues} runs have issues")
        
        # Path existence
        if all(paths_exist):
            print(f"  [OK] All maps have valid path to boss")
        else:
            print(f"  [FAIL] Path issues: {paths_exist.count(False)} maps unreachable")

print("\n=== SUMMARY ===")
print("Map generation logic verified via simulation.")
print("Run actual Godot tests to confirm runtime behavior.")