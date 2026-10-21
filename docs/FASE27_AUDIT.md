# Fase 27 — auditoria anterior às alterações

21/10/2026. main continua documental (10980c6). Fetch realizado; PRs #11–#14 abertos, sem merge. Base integrada correta: Fase26 431cdb6, CI Windows 39543783653 aprovado. Branch específica feat/fase27-mundo.

- scenes/main_menu.tscn → scenes/main.tscn / hybrid_world. Fases 20–26 integram jogador, câmera ortográfica, combate, inventário multicélula, NPCs, comércio, loot, objetos, âncoras, HUD por sinais e save v6. Preservar tooltip estável e Largar [Del].
- Mundo atual possui uma geometria procedural de Vigília compartilhada com map_02. Troca só visibilidade/spawn; não há cenas de regiões, navegação com desvio, minimapa ou fog persistente. Clique usa raycast real, mas descarta altura; jogador não aplica gravidade.
- Exploração existente possui objetos/âncoras/encontros em data/exploration.json, mortos e fontes consumidas persistentes. Reutilizar esses componentes, sem segunda economia/missão ou gerenciadores de cena concorrentes.
- data/maps.json e WORLD_ATLAS definem 15 IDs; sequência canônica do Ato I 01→02→03→04. MAP_IDENTITY_MATRIX menciona slice 01→02→04, em conflito. Adotar atlas e instrução expressa da Fase27: preparar passagem jogável pelo map_03, sem atalho 02→04.
- Maera e Doma devem conservar funções/posições. Investigação de cinco Rasuras permanece provisória; âncoras de viagem não substituem as três âncoras narrativas futuras.
- Assets disponíveis: personagem/NPCs/inimigos procedurais originais, caixas/materiais originais, SVGs e UI. Sem kit 3D final de cidades/arquivo. Usar cenas regionais autoradas e módulos geométricos próprios, claramente estrutura inicial.
- Referências em Downloads lidas como referências de design; não autorizam copiar assets, implantar chefes/cutscenes ou reconstruir inventário.
- 19 suítes e pipeline Godot 4.7.2 existentes. Acrescentar grafo, caminhos, elevações, colisões, exploração e regressões; migrar fixtures antigas de combate no hub para região hostil devido à nova regra segura. Playtest humano só pode ser confirmado pelo usuário; automação gráfica será identificada como tal.

Decisão: único coordenador de regiões subordinado ao mundo existente; carregar uma cena regional por vez, política central de segurança, caminhos 3D determinísticos e malha de navegação derivada da mesma geometria, fog por células/andar e minimapa sobre conhecimento salvo. Save compatível por campo opcional de mundo, sem alterar posse de itens.
