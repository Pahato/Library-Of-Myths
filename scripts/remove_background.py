from PIL import Image
import sys

def remove_background(file_path):
    print(f"Processando imagem: {file_path}")
    try:
        img = Image.open(file_path).convert("RGBA")
    except Exception as e:
        print(f"Erro ao abrir imagem: {e}")
        return

    width, height = img.size
    pixels = img.load()

    # Fila para o flood fill
    queue = []
    visited = set()

    # Adicionar os cantos à fila inicial
    corners = [
        (0, 0),
        (width - 1, 0),
        (0, height - 1),
        (width - 1, height - 1)
    ]
    for c in corners:
        queue.append(c)
        visited.add(c)

    # Condição para determinar se um pixel é fundo (branco ou cinza claro do checkerboard)
    def is_background_color(r, g, b):
        # Branco / Off-white
        if r >= 242 and g >= 242 and b >= 242:
            return True
        # Cinza claro (checkerboard)
        if r >= 220 and g >= 220 and b >= 220:
            if abs(r - g) <= 8 and abs(r - b) <= 8 and abs(g - b) <= 8:
                return True
        return False

    background_pixels = []

    # Flood fill BFS
    while queue:
        x, y = queue.pop(0)
        r, g, b, a = pixels[x, y]

        if is_background_color(r, g, b):
            background_pixels.append((x, y))
            # Verificar vizinhos (4 direções)
            for dx, dy in [(-1, 0), (1, 0), (0, -1), (0, 1)]:
                nx, ny = x + dx, y + dy
                if 0 <= nx < width and 0 <= ny < height:
                    if (nx, ny) not in visited:
                        visited.add((nx, ny))
                        queue.append((nx, ny))

    # Definir pixels de fundo como transparentes
    for x, y in background_pixels:
        pixels[x, y] = (0, 0, 0, 0)

    # Gravar a imagem com transparência
    img.save(file_path, "PNG")
    print(f"Sucesso! {len(background_pixels)} pixéis de fundo removidos.")

if __name__ == "__main__":
    targets = [
        "C:/Users/rodri/Desktop/TudoSobre__PAP/jogo-pap/assets/sprites/susanoo_orochi/Orochi_head.png",
        "C:/Users/rodri/Desktop/TudoSobre__PAP/jogo-pap/assets/sprites/Trocas/novo_Rudra.png",
        "C:/Users/rodri/Desktop/TudoSobre__PAP/jogo-pap/assets/sprites/susanoo_orochi/sake_barrel.png"
    ]
    for t in targets:
        remove_background(t)
