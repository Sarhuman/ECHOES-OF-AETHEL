# Fase 25 — auditoria anterior ao código

20/10/2026. Fetch remoto: main 10980c6, documental. PRs #11 (52ceb7c) e #12 (f162147) abertos, não mesclados; base desta fase: feat/fase24-npcs em f162147. Preservar inventário, NPCs, comércio e save atômico existentes.

- LootGenerator gera ouro/poções/equipamentos e cinco raridades; pesos e probabilidades estão no script, sem contexto regional ou materiais.
- DroppedItem representa loot e rótulo 3D, porém não tem volume de seleção e os drops não sobrevivem ao save. Coleta do mundo transfere ao inventário/cinto existentes; falta validar posse do objeto e alcance no próprio método.
- HybridEnemy implementa ranks 0–2 e XP; o rank 2 usa o nome legado Única. Não existem afixos funcionais nem lacaios configurados.
- HybridWorld constrói Vigília e reutiliza sua geometria no mapa 02, com cinco Rasuras fixas. Só a limpeza completa persiste; inimigos parcialmente derrotados reaparecem. Não há contêineres, altar, poço ou viagem rápida.
- Inventário de 43 definições, cinco qualidades, pilhas, equipamentos, atributos, progressão e save v5 serão reutilizados. Não há serviço genérico de efeitos temporários; a Guarda e os multiplicadores do Player são os pontos existentes de integração.
- NARRATIVE_BIBLE.md consultada: três âncoras narrativas da missão não estão implementadas. Âncoras de Travessia desta fase são pontos de transporte de teste, não substituem placa/livro/sino da missão.
- guia_mapas_construcoes_diablo2.md encontrado em Downloads e lido como referência; não adotar suas densidades, cidades, política de morte ou reset. Mapas e arte finais seguem pendentes. Playtest humano deve ser distinguido de automação e inspeção de capturas.

Plano: dados configuráveis, extensão do gerador e componente de exploração integrado ao mundo. Estados de fontes de recompensa e loot pendente salvos junto ao personagem. Sobreviventes voltam com vida cheia ao reentrar/carregar; mortos continuam eliminados nesse save, sem reset automático de sessão. Novo jogo reinicia o mundo.
