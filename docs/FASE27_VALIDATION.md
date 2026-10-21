# Fase 27 — resultados e pendências

21/10/2026. Base Fase26 / 431cdb6; Godot 4.7.2.stable.official.ed1daf0bf, Windows x64 Compatibility. PR Draft, sem merge.

## Executado

- Validador do grafo: zero erros; IDs/cenas, entradas, retornos e caminhos críticos conferidos.
- 21 suítes completas aprovadas, incluindo inventário/arraste, NPCs/comércio, combate, HUD, persistência, consolidação e bot10/10. Resultados em relatorios-fase20/results.json e logs *-final.log no ZIP.
- Fase27: 138 verificações finais, incluindo ataques/custos/dano na transição, retorno seguro, buffer dos encontros, rampa/altura/raycast, navegação/porta, fog por piso, posições inválidas, migração, recompensas e XP parcial. O número pode variar com pares de rótulos visíveis; todas as falhas são explícitas.
- GUI headless:157 verificações; renderizador real:169 verificações, inputs nativos, circuito completo e12 capturas reais (quatro regiões nas duas resoluções, mapa expandido, retorno a Doma e XP parcial nas duas resoluções). Inspeção visual realizada. Fixtures neutralizam movimento/colisão de combate dos inimigos; preservam piso e gravidade. Combate é testado separadamente.
- EXE Windows exportado:32 verificações aprovadas de menu, movimento, combate, comércio, save/loot/objetos, âncoras e conexões canônicas.
- XP50% validada no preenchimento fino e em ganho real de progressão; painel de status/missão≈260px; minimapa compacto centrado no jogador; rastreador de pendência no Bairro não usa mortes do Arquivo para completar missão.

## Perfil local final

1920×1080, AMD Radeon RX5802048SP, OpenGL Compatibility, teto60FPS;90 frames por região, cenário e HUD finais, IA neutralizada. Intervalos observados incluem o desktop de teste, sem isolamento deGPU/CPU. Não é garantia de60FPS ou benchmark de campanha completa.

| Região | Mediana ms/frame | p95 ms/frame | Draw calls |
|---|---:|---:|---:|
| map_01 | 35.51 | 42.89 | 267 |
| map_02 | 35.77 | 43.27 | 229 |
| map_03 | 35.90 | 42.23 | 207 |
| map_04 | 36.01 | 40.43 | 222 |

Reproduzir: Godot gráfico com `--path . --script res://tools/profile_regions.gd`, em perfil AETHEL_TEST_SAVE_DIR isolado. Dados completos em docs/evidence/fase27-performance.json.

## Não homologado / pendências

Playtest humano completo continua pendente. Não confundir automação gráfica ou inspeção de capturas com teste humano. Seguir TESTING.md para exploração livre, sensação do combate, pontos escuros, caminhos dinâmicos e acessibilidade. Revisão editorial no Godot e assets finais ainda dependem de produção futura.

Mapas são estruturas greybox iniciais, sem o chefe do Arquivo, cutscenes, decisão canônica ou campanha completa. Perfil de desempenho ainda requer otimização e medições na máquina do jogador. Avisos ambientais de certificados/cache/editor e avisos de encerramento de ObjectDB em algumas suítes estão nos logs; nenhuma falha crítica de GDScript passou nas validações finais.

A planilha fornecida não foi alterada nem marcada como concluída. As restrições são respeitadas pela implementação: mesmos donos de estado, combate e save; layout usa âncoras da viewport. Alterações funcionais da Fase27 (navegação, segurança e contador regional) estão separadas da reorganização visual na documentação.
