# Auditoria e decisão de integração — 20/10/2026

## Base escolhida

Branch `integration/fase20-arpg-windows`, criada a partir de `f66184a` (Fase 22). Esse commit descende de `ac0ba22` (Fase 21), `858b658` (Fase 20) e `10980c6` (main). Preserva os adaptadores e o histórico de revisão sem mesclar PRs existentes. O projeto executável é o ZIP da Fase 20 fornecido pelo usuário; o protótipo antigo de Downloads não é sua base.

## Repositório e PRs inspecionados

Fetch remoto concluído; main permanece em `10980c6` e contém apenas README. Metadados e árvores das seis propostas conferidos:

| PR | Estado na auditoria | Conteúdo real | Decisão |
|---|---|---|---|
| #1 | aberto | Bíblia narrativa, atlas, mockups e catálogo de mapas | Referência de cânone; não são cenas |
| #2 | aberto, depende #1 | .gitignore e preparação Godot | Aproveitar práticas; sem jogo implementado |
| #3 | aberto, depende #1 | Lore, identidade dos mapas, dungeons e balanceamento proposto | Referência; mapas 04/08/15 ainda ausentes |
| #4 | Draft, base main | Relatórios de integração e requisito de HUD unificado | Implementar sobre o ZIP real |
| #5 | Draft, depende #4 | AethelCharacterVisual/Definition e gerador Blender | Reutilizar adaptadores; rigs finais ausentes |
| #6 | Draft, depende #5 | AethelEquipmentVisual | Integrar ao equipamento existente |

Nenhum desses PRs foi mesclado ou alterado automaticamente. Os PRs #1–3 mantêm histórico próprio; seu conteúdo narrativo não é substituído por enredo legado.

## Material recuperado

`echoes_of_aethel_fase20_nucleo_arpg.zip`: CRC de todas as entradas válido; contém projeto, cenas, texturas, 33 scripts, testes e documentação. PDF de duas páginas extraído e renderizado para conferência. O PDF relata testes anteriores na 4.4.1; eles não foram tratados como evidência da execução atual.

ZIPs completos originais das Fases 11–18 não foram fornecidos nesta solicitação. A documentação histórica dessas fases vem dentro da Fase 20; isso não comprova recuperação independente de cada pacote.

## Núcleo existente reutilizado

- CharacterBody3D, controles por clique e teclado relativos à câmera, esquiva e combate com precisão/defesa/bloqueio.
- Cinco Rasuras no Bairro, incluindo campeão; recuo, aviso de ataque e perseguição.
- Uma autoridade de inventário (`AethelInventoryManager`), loot (`AethelLootGenerator`) e atributos/dano no jogador e `AethelCharacterStats`.
- Recursos de definições de itens, instâncias, afixos, mochila, equipamento, loja, cinto, habilidades e progressão.
- Missão com Maera, portais entre map_01/map_02, save v3 e migração v2.
- Testes originais: itens, combate, gameplay, UI, RPG e bot de balanceamento.

## Lacunas e redundâncias encontradas

- Cena 2D e seus scripts/save_repository são legado fora do fluxo principal. Não manter segunda implementação ativa de inventário/loot.
- Duas orbes e Fôlego disperso contrariavam o PR #4; painel único implementado e verificado em três proporções.
- Qualidade 3 era reservada a conjunto, sem loot épico. Normal/Magic/Rare/Unique eram as quatro qualidades efetivas.
- Adaptadores 21/22 sem ligação ao jogador. Nenhum GLB final ou esqueleto de produção foi disponibilizado.
- Menu original combinava iniciar/continuar; sem pausa/opções. InputMap não centralizado.
- Save usava o mesmo nome histórico que testes apagavam; execução dos testes agora usa diretório isolado por variável de ambiente.
- Sem navmesh, dungeon, campanha completa, áudio final ou assets finais. Placeholders 3D procedurais precisam continuar identificados.
- Templates Windows não estavam instalados; pacote anterior usou engine completa + PCK. A distribuição deve indicar explicitamente o runtime utilizado.

## Plano aplicado

Importar o ZIP preservando IDs e sistemas; estabilizar parser; unificar HUD; centralizar ações e fluxo menu/pausa; completar cinco qualidades e contrato visual por slot; endurecer persistência; executar regressões; gerar pacote Windows e CI; publicar proposta Draft com limitações reais. Nenhum merge automático.

Resultados finais, hashes e limitações são registrados em `VALIDATION.md` junto aos logs da execução local.
