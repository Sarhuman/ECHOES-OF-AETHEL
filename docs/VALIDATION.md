# Validação local — 20/10/2026

Engine: **Godot 4.7.2.stable.official.ed1daf0bf**, Windows x64. Exportação: template oficial `windows_release_x86_64.exe`, SHA256 `d34d36f3be1a6c49c56525ae86469b92e4f417ddf0b43cf00dd80c385c4b0562`; CRC do arquivo no TPZ validado. Não foi usado o editor como runtime desta entrega.

## Testes automatizados

| Suíte | Resultado |
|---|---|
| Importação headless | Sem erros de parsing, scripts ou referências ausentes |
| test_items | Exit 0; 4.000 rolagens e testes de afixos, requisitos e serialização |
| test_combat | Exit 0; equipamentos, bloqueio, poções, movimentação e combate |
| test_gameplay | Exit 0; câmera, WASD, clique, missão, drops, equipamentos, habilidades e migração de save |
| test_ui_smoke | Exit 0; mochila, 12 slots, tooltips, loja, compras e vendas |
| test_rpg_systems | Exit 0; progressão e habilidades |
| test_hud_revision | Exit 0; um painel, três recursos, sem orbes, sinais e limites em três resoluções |
| test_consolidation | Exit 0; 5.105 verificações, incluindo catálogos, cinco classes/uma jogável, 5.000 drops, afixos inválidos, raridades mistas por slot, troca visual sem recriar modelo, classe incompatível, bloqueio manual, backup, posição inválida, reconfiguração de interação, pausa e transições de menu |
| balance_bot | 10/10 vitórias; passo fixo de 1/60 s; RNG do jogador fixado por ensaio; falha se algum ensaio perder |

Distribuição de 5.000 itens nível 12 (seed 2020): Comum 2.801; Mágico 1.311; Raro 606; Épico 232; Lendário 50. Pesos iniciais 55/27/12/5/1; não representam balanceamento definitivo.

Cada suíte usa seu próprio diretório de save. Nenhum teste depende dos saves reais do usuário. A simulação foi acelerada com `--fixed-fps 60`, mantendo o passo lógico; os tempos reportados pelo bot são tempo simulado, não medições de performance.

## Execução gráfica e exportação

- Windows release exportado como EXE + PCK. Executado a partir da pasta de distribuição, sem acesso necessário ao projeto fonte.
- Menu do export inicializado; argumento de smoke iniciou sessão nova e registrou `SMOKE GAMEPLAY READY: player=true inventory=true hp=155 equipment=7`.
- Export renderizado em **OpenGL 3.3 / AMD Radeon RX 580 2048SP**. Frame do jogo exportado inspecionado: [captura](evidence/release-validado.png).
- Capturas do projeto inspecionadas: menu, Vigília, Bairro, mochila/ficha, habilidades, loja, pausa e opções.
- HUD renderizado em imagens de dimensões reais 1280×720, 1366×768 e 1280×800; stretch em `expand`, sem corte do painel. Ajustadas as instruções que antes transbordavam na lateral.
- Evidências estáticas: [mochila e personagem](evidence/inventario-personagem.png), [pausa](evidence/pausa.png). ZIP inclui os demais PNGs e logs.

Os primeiros smokes tentaram `--scene` no template release; esse binário desabilita sobreposição de caminhos. A validação final usa `-- --smoke-gameplay`, suportado pelo menu do próprio jogo, e não depende dessa opção da engine.

## Avisos ambientais observados

O sandbox impede leitura do armazenamento de certificados e gravação das preferências do editor em AppData. Esses erros estão nos logs originais e não foram removidos para simular uma execução limpa. Não foram erros de GDScript. Logs de testes e saves foram direcionados ao workspace. O gameplay não usa rede.

## Pendências explícitas

- Playtest humano completo, outros computadores, performance prolongada e controle de regressões de sensação de combate.
- Assets finais, GLB/rig de produção, clipes artísticos e áudio. Os estados idle/walk/run/attack_1/attack_2/block/dodge/hit/death usam placeholders articulados e não devem ser apresentados como animações finais homologadas.
- Silhuetas/ornamentos finais das cinco raridades; o protótipo possui variantes geométricas de armas, visibilidade por slot, cores e emissão localizada em pequenos detalhes. Não é uma coleção final de armaduras.
- Navmesh/pathfinding: movimento direto pode parar em obstáculos. IA possui patrulha, perseguição, aviso/ataque, retorno e morte, sem navegação completa.
- Map_04, restante da campanha, quatro outras classes, decisões narrativas persistentes além da missão introdutória, portal de cidade/baú/resistências.
- Build sem assinatura/instalador. Auditoria de direitos para lançamento comercial e licença geral do jogo ainda pendentes.
## CI remoto aprovado

[Windows pre-alpha #1](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39502230965), commit de código `a38a240`: todos os passos concluídos com sucesso, incluindo download oficial, importação, oito suítes, exportação Windows, empacotamento e upload. [Artefato Windows](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39502230965/artifacts/12302045753) e logs disponibilizados. As evidências gráficas são da máquina local; o runner remoto fez validação headless.

A cópia de `fonte/` extraída do ZIP local também foi importada em diretório limpo e passou pelas 5.105 verificações de consolidação, sem depender do cache de desenvolvimento.

O PR deve permanecer **Draft** pelas pendências de arte/animações finais e validação humana. O núcleo executável pode ser testado com essas limitações documentadas.
