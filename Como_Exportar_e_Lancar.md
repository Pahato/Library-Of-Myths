# Guia de Exportação e Lançamento — Library of Myths 🚀

Configurei todas as propriedades do projeto e os presets de exportação para que possas empacotar o teu jogo com aspecto 100% profissional, utilizando as tuas imagens de marca!

---

## 🛠️ O que foi configurado por mim:

1. **Ícone do Jogo:** Configurado no projeto para usar o teu `libraryOfMyths_logo.png`.
2. **Ecrã de Carregamento (Boot Splash Screen):** Configurado com o teu logótipo centralizado sobre um fundo escuro premium (`#0F0A1E`) combinando com o tema do jogo.
3. **Preset "Windows Desktop":**
   - Configurado para exportar o executável (`LibraryOfMyths.exe`).
   - Associado o ícone de aplicação real `.ico` (`libraryOfMyths_logoIco.ico`), para que o executável apareça com o logótipo no ambiente de trabalho (Desktop) do jogador.
4. **Preset "Web" (HTML5):**
   - Ativado o suporte a Progressive Web App (PWA).
   - Associados os logótipos nas resoluções corretas para telemóvel/browser.

---

## 📦 Como Exportar o Jogo no Editor do Godot:

Como os modelos de exportação (Export Templates) são instalados a nível do computador e variam por máquina, precisas de fazer a primeira exportação no teu editor:

### Passo 1: Instalar os Modelos de Exportação (Se ainda não o fizeste)
1. Abre o Godot 4 e carrega o projeto **Jogo_PAP**.
2. No menu superior, vai a **Projeto (Project) -> Exportar (Export)**.
3. Se aparecer um aviso vermelho a dizer que faltam os modelos de exportação:
   - Clica no link azul **"Gerir Modelos de Exportação" (Manage Export Templates)**.
   - Clica no botão **"Descarregar e Instalar" (Download and Install)**. O Godot fará o download da versão oficial `4.6.2` automaticamente.

### Passo 2: Exportar para Windows
1. Na janela de exportação, seleciona **Windows Desktop** na lista à esquerda.
2. Clica no botão **"Exportar Projeto..." (Export Project...)** na barra inferior.
3. Cria ou seleciona a pasta `builds/windows/` e clica em **Guardar**.
4. *Pronto!* Tens agora o teu ficheiro `LibraryOfMyths.exe` com o teu ícone personalizado.

### Passo 3: Exportar para Web (Para jogar no Browser / Itch.io)
1. Na mesma janela de exportação, seleciona **Web** à esquerda.
2. Clica em **"Exportar Projeto..."**.
3. Cria ou seleciona a pasta `builds/web/`, nomeia o ficheiro como `index.html` e guarda.
4. O Godot gerará os ficheiros: `index.html`, `index.js`, `index.wasm`, `index.pck`, etc.

---

## 🌐 Como Publicar no Itch.io:

Para criares uma página linda para o teu jogo no itch.io, segue estes passos:

1. Faz login no [itch.io](https://itch.io) e clica em **Dashboard -> Create New Project**.
2. Preenche os detalhes iniciais:
   - **Title:** `Library of Myths`
   - **Classification:** `Games`
   - **Kind of game:** Seleciona **HTML** (se quiseres que joguem no browser) ou **Downloadable** (se for para descarregar o `.exe`).
3. **🎨 Imagens de Marca (Os teus assets):**
   - **Cover Image (Capa do Jogo):** Carrega o teu `libraryOfMyths_logo.png` (ideal para a grelha de jogos e ícone do site).
   - **Banner Image (Cabeçalho da Página):** Carrega o teu `libraryOfMyths_banner.png` (ficará no topo da página do teu jogo, dando um visual espetacular e imersivo!).
4. **Subir os Ficheiros:**
   - **Para a versão Web (Recomendado):** Junta todos os ficheiros da pasta `builds/web/` num ficheiro comprimido `.zip` (ex: `web_build.zip`), faz o upload no itch.io e marca a opção **"This file will be played in the browser"**.
   - **Para a versão Windows:** Comprime a pasta `builds/windows/` num `.zip` e carrega-o para download.
5. Clica em **Save & View Page** para veres a tua página no ar!
