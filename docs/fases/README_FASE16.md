# Fase 16 — HUD e inventário existentes corrigidos

- Preserva `AethelHUDManager`, `AethelGlobe` e `AethelInventoryView` da Fase 15; evita HUD duplicada.
- Adiciona `stamina_changed`, custo de 24 de fôlego por dash e regeneração de 17/s.
- Adiciona barra de Fôlego integrada entre os globos.
- Ajusta ordem de criação do painel e superfícies de mouse do inventário.
- Mantém o inventário tipado `AethelItemInstance`, identificadores individuais e sinais de atualização.
- Esconde texto redundante de HP/atalhos de debug, sem alterar a lógica de combate e drop.

## Testar

1. Importe `project.godot` na Godot 4.7.2 e pressione F5.
2. Verifique globos inferiores vermelho/azul e Fôlego dourado no centro.
3. Segure Espaço e WASD para esquivar; Fôlego deve diminuir e regenerar.
4. Pressione I para abrir a mochila com 40 células visíveis.
5. Converse com Maera, derrote Rasuras, colete com E e confira a grade e tooltip.
6. Confira Output/Debugger para erros de GDScript.

**Status:** alteração estática e ZIP testado quanto à integridade; Godot não disponível neste ambiente, execução pendente. Não é build homologada.
