# Fase 18 — Câmera isométrica e layout responsivo

Mudanças sobre a Fase 17:

- `scripts/hybrid_world.gd`: câmera ortográfica com yaw +45°, pitch -35.264°, `size=12`; posição de acompanhamento ajustada. A câmera permanece filha do jogador.
- `src/ui/hud_manager.gd`: globos ancorados nos cantos inferiores por `anchor` + `offset` em vez de coordenadas absolutas. Barra de Fôlego ancorada ao centro inferior.
- `src/items/inventory_view.gd`: mochila 10×4 ancorada ao centro em 600×380 px.

## Atenção sobre a projeção

O ângulo de câmera é um ponto inicial de composição isométrica. A rotação de 35.264° é o ângulo clássico de uma projeção isométrica matemática, mas a leitura final também depende de orientação da cena e resolução. O `Camera3D.size` controla a extensão da visão em função de `keep_aspect`; não define necessariamente zoom equivalente em todas as proporções.

## GridMap / colisão / navegação

Tamanho candidato de célula: (4,4,4) metros com chão modular 4×4×0,5m e paredes 4×4×4m. **Não foi criado GridMap nem baked NavMesh nesta fase.** Células encaixadas não garantem malha de navegação contínua; é necessário configurar superfícies navegáveis, obstáculos, agente, baked navmesh e validar transições.

## Critérios de aceite em Godot 4.7.2

1. Abrir F5 sem erros de parser.
2. Inspecionar composição e mover WASD: câmera deve acompanhar sem rotação inadvertida.
3. Testar globos e mochila em 1280×720, 1920×1080 e janela redimensionada.
4. Confirmar coleta de item e inventário renderizado.
5. Ajustar tamanho ortográfico (10–16 caso necessário) após playtest, não por suposição.

**Validação:** alterações textuais verificadas; a engine não está disponível aqui para teste de execução. Não representa homologação nem conclusão das áreas definitivas.
