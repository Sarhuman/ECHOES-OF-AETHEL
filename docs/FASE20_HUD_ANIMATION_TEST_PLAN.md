# Fase 20 — Revisão de HUD, animações e validação

## Evidências verificadas em 20/10/2026
- `unzip -t echoes_of_aethel_fase20_nucleo_arpg.zip`: **sem erros**.
- Arquivo compactado: 98 entradas; arquivos GDScript, cenas, texturas, testes e documentação.
- `src/ui/hud_manager.gd` declara `hp_globe: AethelGlobe`, `ether_globe: AethelGlobe` e `stamina_bar: ProgressBar`; cria duas orbes de 160 × 160 e uma barra independente.
- Modelos atuais em `scripts/procedural_knight.gd`, `scripts/procedural_npc.gd` e `scripts/procedural_rasura.gd`. A documentação do próprio pacote informa que não há animações e arte finais.
- O ambiente de inspeção não dispõe de executável Godot: **nenhum teste GDScript, smoke test ou playtest foi executado**. O relatório do pacote relata execução anterior em Godot 4.4.1, mas essa alegação não substitui testes independentes na versão-alvo 4.7.2.

## Mudança obrigatória: painel de recursos unificado
Substituir a apresentação em duas orbes (Vida e Éter) e uma barra solta de Fôlego por **um único painel de HUD**, inspirado na organização compacta de Castlevania, sem copiar arte protegida.

Critérios:
1. Um único contêiner `Control`/`CanvasLayer` com três indicadores distintos de Vida, Éter e Fôlego, preferencialmente barras horizontais empilhadas; manter recursos e cálculos separados no modelo de domínio.
2. Vida prioritária visualmente; Éter e Fôlego identificados por rótulos e não apenas cor. Exibir valor atual/máximo, feedback de dano, gasto e regeneração.
3. Responsivo em 16:9, 16:10 e 1366×768; sem cobrir menus, inventário, cinto de poções ou barra de XP.
4. Acessibilidade: contraste, leitura sem depender exclusivamente da cor, atualização sem cintilação.
5. Remover instanciação das orbes da composição ativa apenas após migrar testes e referências; preservar `diablo_globe.gd` temporariamente se houver outras dependências.
6. Adicionar teste de HUD que valide a presença de **um** painel e **três** recursos, e ausência de orbes na árvore de UI ativa.

## Mudança obrigatória: animação de personagens
O visual atual é procedural/em blocos; isso **não está concluído**. Substituir por modelos/sprites definitivos autorizados e estados de animação (idle, locomoção, ataque, recuperação, impacto, esquiva, morte). Adotar `AnimationTree`/`AnimationPlayer` quando apropriado ao rig, transições coerentes, eventos de hit sincronizados com animação, sem acoplar cálculo de dano ao frame visual. Testar orientação na câmera dimétrica, equipamentos, colisões e hitboxes. Não anunciar como implementado antes de assets e runtime validados.

## Validação obrigatória antes de merge
- [x] Integridade do ZIP.
- [x] Inspeção estática de HUD, scripts procedurais e documentação.
- [ ] Importar integralmente o projeto na branch.
- [ ] Rodar Godot 4.7.2 em headless e registrar saída e exit code.
- [ ] Executar testes `test_items.gd`, `test_combat.gd`, `test_gameplay.gd`, `test_ui_smoke.gd`, `test_rpg_systems.gd`, `balance_bot.gd`.
- [ ] Implementar HUD unificado e regressão automatizada.
- [ ] Implementar e validar animações reais.
- [ ] Playtest visual de HUD, câmera, combate, loot e save/load.
- [ ] Atualizar README com o status real.

**Não mesclar automaticamente.**
