import os

os.chdir(r'C:\Users\rodri\Desktop\TudoSobre__PAP\jogo-pap')

with open('scripts/thor_jormungandr/thor_map.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the bottleneck logic that removes connections from non-bottleneck nodes
old_code = '''		# Se esta layer tem o nó bottleneck obrigatório, forçar TODAS as ligações da próxima layer
		# a passarem por ele (tornando-o um verdadeiro bottleneck)
		if bottleneck_node:
			# Remover conexões diretas de outros nós da camada atual para a próxima
			for c_node in current_layer_nodes:
				if c_node != bottleneck_node:
					# Remover conexões para a próxima layer
					var new_connections = []
					for conn_id in c_node.connections:
						var is_next_layer = false
						for nn in next_layer_nodes:
							if nn.id == conn_id:
								is_next_layer = true
								break
						if not is_next_layer:
							new_connections.append(conn_id)
					c_node.connections = new_connections
			
			# Conectar bottleneck a TODOS os nós da próxima layer
			bottleneck_node.connections = []
			for n_node in next_layer_nodes:
				bottleneck_node.connections.append(n_node.id)
			
			# Garantir que todos os nós da próxima layer tenham conexão com o bottleneck
			for n_node in next_layer_nodes:
				if not bottleneck_node.id in n_node.connections:
					n_node.connections.append(bottleneck_node.id)

	# NORMAL: Garantir que todos os nós conectados ao boss sejam REST'''

new_code = '''		# Se esta layer tem o nó bottleneck obrigatório, garantir que ele conecta a TODOS os nós da próxima layer
		# e que todos os nós da próxima layer conectam de volta a ele (bottleneck real)
		if bottleneck_node:
			# Conectar bottleneck a TODOS os nós da próxima layer
			bottleneck_node.connections = []
			for n_node in next_layer_nodes:
				bottleneck_node.connections.append(n_node.id)
			
			# Garantir que todos os nós da próxima layer tenham conexão com o bottleneck
			for n_node in next_layer_nodes:
				if not bottleneck_node.id in n_node.connections:
					n_node.connections.append(bottleneck_node.id)

	# NORMAL: Garantir que todos os nós conectados ao boss sejam REST'''

content = content.replace(old_code, new_code)

with open('scripts/thor_jormungandr/thor_map.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed bottleneck logic')