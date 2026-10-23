# BUG-US01-03 — Diagnóstico das Âncoras durante combate

**Somente investigação. Nenhuma correção funcional implementada.**

22/10/2026; Godot 4.7.2.stable.official.ed1daf0bf; Windows x64. Branch audit/us-01-baseline-godot-472 atualizada e sem novos commits remotos sobre e154fd08b3abbcb93ec259315adf22d684e9de9e, base de produção examinada. PR #18 permanece Draft. Fix01/Fix02 aprovados manualmente pelo PO e preservados. Este diagnóstico não aprova G1/G2.

## Conclusão comprovada

O menu é modal para parte dos comandos, mas **não pausa o mundo nem concede proteção**. Foi aberto durante perseguição e durante windup de uma Rasura Campeã. O jogador recebeu dano enquanto o menu permaneceu aberto e pôde viajar durante esses estados. A hipótese "viagem somente fora de combate, mundo ativo" ainda não está implementada e exige aprovação do PO.

Não foi reproduzido input permanentemente travado após fechar, viajar, morrer ou carregar. Foi constatado bloqueio incompleto: WASD e clique esquerdo no mundo são impedidos, mas J, F1 e M2 executam ações de combate com o menu aberto. Não interpretar interaction_input_locked como invulnerabilidade ou bloqueio de todos os comandos.

## Método e limites

Adicionado apenas tests/diagnose_us01_03.gd, sem integrar uma regra nova ao runner. Instancia a cena main real, usa região map_02 e sua âncora real district_anchor, player em (3,0,10); destinos previamente marcados descobertos apenas na fixture. Remove encontros iniciais para isolar cada caso e acrescenta uma Campeã real via _spawn_enemy, mantendo dano, atributos e IA de produção. Caso "próximo sem agressão" desativa física somente desse inimigo na fixture: é um controle de proximidade, não prova de que uma Campeã visível naturalmente permanece pacífica. Nos demais casos a IA está ativa; perseguição e windup são verificados como pré-condições.

RNG do jogador usa seed 42 na fixture, sem alterar chances/atributos. Cliques usam InputEventMouseButton real com transformação do viewport; teclado usa InputEventKey/Input.action_press conforme caso. Primeiro rascunho sem transformação de coordenadas não clicava os botões e um spawn atrás de geometria não estabelecia chase; ambos foram corrigidos antes da execução final e não foram registrados como defeitos do jogo.

Saves são isolados por AETHEL_TEST_SAVE_DIR, sem tocar saves do PO. A saída distingue erros de fixture de observações: o sucesso do diagnóstico significa que os cenários foram executados, não que o comportamento atual foi aprovado.

## Resultados — execução final

31 observações, zero erros de fixture; exit 0. JSON completo em docs/evidence/us01-03/anchor-observations.json. Cada amostra inclui HP, Éter, posição, região, menu, input_locked, pausa, invulnerabilidade, recovery/cooldowns, transição/veil e estado/posição/windup do inimigo quando ainda válido.

| Cenário | Comportamento efetivamente reproduzido |
|---|---|
| Sem inimigos | menu abre; HP 155; lock true; paused false |
| Próximo sem agressão, controle com física desativada | menu abre; HP 155→155 em 1s; inimigo patrol |
| Perseguição ativa | menu abre com chase; botão de destino leva map_02→map_01, HP 155→155 |
| Windup ativo | menu abre com attack/windup=true |
| Dano com menu aberto | em 3s HP 155→149; menu continua true e lock true |
| Viagem durante windup | travel retorna true; map_02→map_01; HP 155→155; inimigo anterior queued e depois removido |
| Viagem após dano e com ameaça | travel retorna true; map_02→map_03; HP 149→149 no retorno síncrono e após 3 frames |
| Estado após viagem | menu false, lock false, transitioning true só no restante do frame; nova posição segura e inimigos de destino reconstruídos |
| Ameaça controlada no destino | Campeã adicionada próxima após chegada; HP 149→142 em 3s. Não há proteção permanente pós-viagem |
| Morte com menu aberto | HP 1→0; game_over true; menu fecha e lock false |
| Botão Fechar, clique real | menu false, lock false após frames; movimento posterior ≈1,30m |
| Escape, tecla real | fecha menu sem pausar; lock false; movimento posterior ≈0,76m, limitado inicialmente pelo recovery de habilidade anterior |
| Load com menu aberto, F9 | menu false, lock false; HP 155 restaurado; movimento posterior ≈1,30m |
| Movimento/clique esquerdo no mundo com menu aberto | deslocamento zero; nenhum move_target |
| J/F1 com menu aberto | attack_recovery/cooldown ativados; não são barrados pelo modal |
| M2 com menu aberto | Éter 25→15 e heavy_strike em cooldown; menu e lock permanecem true na amostra seguinte |

Posições registradas: origem (3,0,10); chegada Vigília (3,0,7,4); chegada Pátio (-3,0,11,4). JSON usa arrays [x,y,z] com ponto decimal, sem ambiguidade de separadores.

### Dano durante a transição

`move_to()` é síncrono e não contém await: nesta execução não houve perda de HP entre a chamada e seu retorno nem nos primeiros frames amostrados. O inimigo de origem entra em queue_free na reconstrução da região. O guard transitioning dura o restante do frame e evita entradas duplicadas; não é imunidade. O veil visual dura aproximadamente 0,3s, mas não pausa o mundo. As observações não provam invulnerabilidade universal durante o fade, todas as ordens de processamento ou todos os destinos. Não foi reproduzido dano vindo do inimigo antigo após a viagem. A redução 149→142 foi produzida por uma ameaça nova e controlada no destino, não deve ser atribuída à troca síncrona.

## Arquivos/funções e causa técnica

- src/world/exploration.gd: `request/activate` conferem alcance/visibilidade/reachable e abrem âncora sem consultar combate; `open_travel` mostra o painel e seta lock; `travel` valida descoberta, fonte, distância, progressão e game_over, mas não ameaça ativa. `tick` reafirma lock enquanto o painel está visível. `update_region` fecha o painel.
- scripts/hybrid_player.gd: `_keyboard_direction`, dodge e bloqueio manual respeitam interaction_input_locked. `_try_attack`, `use_skill`, `receive_attack` e `take_damage` não o tratam como bloqueio geral/imunidade. A física e o recebimento de dano continuam.
- scripts/hybrid_world.gd: `_mouse_over_ui`/clique esquerdo bloqueiam comandos no mundo; `_unhandled_key_input` continua tratando J/F1; `_cast_right_skill` não barra o modal da âncora e `_activate_skill` usa over_ui para mira, não para vetar execução. `_on_player_died` fecha travel_panel. Escape fecha o painel antes do caminho de pausa global.
- src/narrative/npc_controller.gd: `tick` recalcula lock a partir de diálogo/loja a cada frame; em seguida exploration.tick reafirma o lock da viagem. Ao fechar, o próximo tick normal limpa o lock. O botão Fechar só chama hide, portanto a liberação não é necessariamente síncrona no próprio callback.
- src/world/region_manager.gd: `move_to` limpa comandos, troca região, reposiciona, reconstrói encontros, salva e ativa veil; não verifica combate. Não há transação assíncrona nem proteção temporal de dano adicionada.

**Causa confirmada do comportamento:** ausência de regra de combate na entrada e execução da viagem, combinada com um lock parcial de input que não suspende inimigos ou dano. Isso explica a exposição do jogador e a fuga por viagem. A imagem original sozinha não demonstra quando ocorreu o popup; o diagnóstico agora comprova que dano com o menu aberto é possível. Ainda cabe ao PO definir se esse comportamento é proibido por design.

## Testes e comandos

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
$env:AETHEL_TEST_SAVE_DIR = "$pwd/relatorios-fase20/profiles/us01-03"
New-Item -ItemType Directory -Force $env:AETHEL_TEST_SAVE_DIR | Out-Null
& $engine --headless --fixed-fps 60 --quit-after 6000 --path . --script res://tests/diagnose_us01_03.gd --log-file "$pwd/relatorios-fase20/us01-03-diagnosis.log"
```

Também executados na mesma engine, com perfil isolado próprio: tests/test_us01_fix01.gd (28 checks/0 falhas, exit 0) e tests/test_us01_fix02.gd (23 checks/0 falhas, exit 0). Nenhuma linha SCRIPT ERROR/Parse Error na rodada final. O diagnóstico de múltiplas instâncias de mundo emitiu aviso de 8 ObjectDB instances leaked ao encerrar; não foi ocultado nem classificado como corrigido. Regressões Fix01/Fix02 finais não emitiram esse aviso nesta rodada.

Não foi solicitada/produzida uma correção funcional Fix03 nem um novo export manual. Não se declara repetição da baseline inteira nesta investigação. Caso a publicação documental dispare o workflow já existente, seu build continua sendo Fix02, não uma solução deste bug.

## Proposta mínima — NÃO IMPLEMENTADA

Caso o PO aprove "viagem apenas fora de combate, mundo ativo":

1. Definir um predicado local de impedimento da viagem que leia ameaças existentes, sem modificar IA. Proposta inicial conservadora: inimigo vivo que tenha o jogador como alvo e esteja chase/search/attack, windup ativo ou hit com memória de alvo. Decidir se dano recente também conta e por quantos segundos; não foi escolhido um valor arbitrário.
2. Usar a mesma regra ao tentar abrir o menu e, obrigatoriamente, revalidar em travel imediatamente antes de move_to. UI desabilitada sozinha não impede chamadas diretas nem ameaças iniciadas depois de abrir.
3. Se surgir ameaça com o menu aberto, proposta: fechar o menu, limpar somente o lock pertencente à viagem e exibir feedback. Não pausar o mundo, alterar HP ou conceder invulnerabilidade.
4. Tornar a modalização de input coerente: enquanto o menu estiver aberto, vetar J/F1–F3/M2 e novas ordens de combate; manter Fechar/Escape funcionais. PO deve confirmar se deseja essa restrição ou ações de combate que fechem o menu automaticamente.
5. Evitar disputas de escritores do lock com diálogo/loja; liberação deve respeitar outros modais ativos. Não fazer refatoração ampla de UI nem modificar o reset Fix01 sem regressão comprovada.

**Decisões pendentes do PO:** aprovar/rejeitar regra fora de combate; definir ameaça (inclui search e dano recente?); confirmar fechamento automático ao surgir ameaça e política dos atalhos de combate. Inimigo apenas próximo, sem agressão, não deve ser confundido automaticamente com combate sem decisão explícita.

## Critérios de aceite propostos para futura implementação

- Abrir/viajar fora de combate continua funcionando com descoberta, progressão, alcance e visibilidade existentes.
- Chase, windup e demais estados de combate aprovados impedem abertura e execução, inclusive chamada direta de travel.
- Ameaça que surge depois da abertura aplica a política de fechamento aprovada; jogador continua vulnerável no mundo ativo.
- Botão Fechar/Escape restituem controle; nenhum lock residual após morte, save/load ou mudança de região; modais coexistentes respeitados.
- Mouse e teclado obedecem à política única aprovada para ações de combate.
- HP/posição/encontros permanecem consistentes em viagem permitida; guard de transição rejeita duplicação sem instituir proteção não aprovada.
- Fix01/Fix02 e a baseline completa passam; PO reproduz cenários no executável de uma futura correção.

## Entrega e governança

Arquivos novos somente de teste/documentação/evidências: tests/diagnose_us01_03.gd, docs/BUG_US01_03_DIAGNOSTICO.md, docs/evidence/us01-03/. Nenhum arquivo de produção, IA, save/load, combate, balanceamento, missão, narrativa ou âncora foi modificado. Sem pausa global, merge, nova história ou homologação automática. Aguardar aprovação explícita da proposta antes de qualquer implementação funcional.
