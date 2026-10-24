# Fase 20 — Núcleo ARPG: relatório de integração

## Origem e escopo
Pacote fornecido: `echoes_of_aethel_fase20_nucleo_arpg.zip` e relatório `FASE20_NUCLEO_ARPG.pdf` (20/10/2026).
O ZIP passou em `unzip -t`. O conteúdo ainda **não foi importado para esta branch**; este documento é a preparação de integração, não uma homologação.

## Funcionalidades declaradas no pacote
- Câmera dimétrica 30°/45°, movimentação WASD e mouse, perseguição e ataque, habilidade no botão direito.
- Itens Normal/Mágico/Raro/Único, afixos, requisitos, 11 posições de equipamento.
- Força, Destreza, Vitalidade e Energia; acerto/defesa; inimigos normais, campeões e únicos.
- Loot no chão, cinto de quatro poções, loja, painel de personagem, barra de XP.
- Save v3, migração v2 e backup `.bak`.

## Compatibilidade e riscos
1. O `project.godot` do ZIP declara `config/features=PackedStringArray("4.3", "GL Compatibility")`; relatório cita Godot 4.4.1 headless; o README atual menciona Godot 4.7.2 como alvo. É obrigatório validar parsing e execução na versão-alvo antes de afirmar compatibilidade.
2. O protótipo inclui `scripts/hybrid_world.gd` extenso; modularizar progressivamente em mundo, entidades, combate, inventário, persistência e UI, sem refatoração simultânea à importação.
3. A nomenclatura e a progressão devem respeitar o cânone da `main`: Restaurador, Maera, Doma, Vigília, Bairro que Faltava, 15 mapas e três dungeons. Não sobrescrever documentação narrativa com material experimental.
4. Não confundir arquivos `.gd.uid` com validação de importação; manter somente UIDs consistentes com scripts.
5. O relatório afirma que não há pathfinding com NavigationMesh preparada, áudio/arte final, portal de cidade, waypoints, baú, penalidade de morte, resistências, dano elemental, conjuntos, runas, dificuldades avançadas, atos ou chefes completos.

## Checklist de aceitação
- [x] Inspecionar conteúdo do ZIP e verificar integridade do arquivo.
- [x] Conferir README atual da `main` e divergências de escopo.
- [ ] Importar scripts, cenas, recursos, assets e testes do ZIP em commit versionado.
- [ ] Abrir no editor Godot 4.7.2 e validar importação, cenas e referências.
- [ ] Executar `tests/test_items.gd`, `test_combat.gd`, `test_gameplay.gd`, `test_ui_smoke.gd`, `test_rpg_systems.gd` e `balance_bot.gd`.
- [ ] Playtest manual de HUD, interação, clique-movimento, inventário, loot, loja, equipamento, morte e save/load v2→v3.
- [ ] Atualizar README raiz com controles e estado real de validação, após importação.
- [ ] Verificar direitos de uso dos assets antes de distribuição.

## Política de merge
PR em draft; não mesclar até que o código do ZIP esteja integrado, testes executados e regressões resolvidas.
