# Fase 6 — Integração experimental do prólogo

## Entrega local

Foi preparado um ZIP do protótipo Godot 2.5D baseado na Fase 5, com Maera Voss, missão inicial, portal e cinco Rasuras. **O ZIP ainda não foi enviado ao GitHub**; o pacote está disponível como anexo na conversa. Este documento registra o escopo para integração posterior e não declara que a implementação está versionada.

## Fluxo a validar

1. Abrir `project.godot` na Godot 4.7.2 e executar `scenes/main.tscn`.
2. Em Vigília, aproximar-se de Maera (bloco azul) e pressionar E.
3. Aproximar-se do portal roxo a leste e pressionar E.
4. No Bairro que Faltava, derrotar cinco Rasuras.
5. Aproximar-se do portal de retorno e pressionar E.
6. Confirmar que a missão fica concluída no hub durante a sessão.

## Limitações conhecidas

- Hub e área de combate usam a mesma geometria provisória e alternância de estado; não são dois mapas completos.
- Missão não é salva em disco; reiniciar o jogo reinicia o progresso narrativo.
- Sem diálogos ramificados, Sprite3D de produção, NavigationAgent3D, loot integrado ou testes de execução automatizados.
- A verificação de ZIP não comprova compatibilidade com a engine.

## Próximo marco verificável

Versionar os arquivos `project.godot`, `scenes/main.tscn`, `scripts/hybrid_world.gd`, `scripts/hybrid_player.gd` e `scripts/hybrid_enemy.gd`, e depois migrar para cenas de mapa independentes e saves versionados. O atlas continua com 15 mapas e três dungeons previstos.
