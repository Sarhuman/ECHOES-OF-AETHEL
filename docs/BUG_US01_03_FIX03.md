# BUG-US01-03 — Fix03: Âncoras somente fora de combate

Data: 23/10/2026 (America/Bahia). Branch `audit/us-01-baseline-godot-472`. Base `1371cfca37426630b1ee53b3dd66fe7884f23682`. PR #18 Draft, sem merge. Godot `4.7.2.stable.official.ed1daf0bf`, Windows x64.

## Regra aprovada e implementada

O PO respondeu "sim" à proposta de bloquear abertura e viagem durante chase/search/attack, fechar o menu quando surgir ameaça e manter o mundo ativo. A modalização dos atalhos de combate fazia parte da proposta apresentada. Não há pausa global, alteração de HP ou imunidade nova.

Um inimigo vivo, não removido, cujo alvo seja o jogador e esteja em chase, search ou attack impede a travessia. Windup ativo também bloqueia, mesmo no intervalo anterior à atualização de ai_state. Inimigo apenas próximo em patrol/return, morto, inválido ou sem o jogador como alvo não é automaticamente combate. Não foi criado temporizador de dano recente nem uma regra arbitrária de raio de proximidade.

- A abertura revalida combate antes de mostrar o menu.
- travel() revalida imediatamente antes das demais condições e da troca de região; chamada direta também é bloqueada.
- Se surgir ameaça enquanto o painel estiver aberto, tick() fecha o menu e mostra feedback de combate.
- J, F1–F3, M2 e ativação de habilidade pelo HUD não executam ações nem consomem recursos com o menu aberto. Movimento/esquiva mantêm os bloqueios existentes.
- Fechar/Escape liberam o lock da viagem imediatamente, respeitando diálogo ou loja ainda abertos. Mudança de região, morte e load também passam pela sincronização da visibilidade do painel.
- Mundo, inimigos e recebimento de dano continuam processando normalmente. Um menu não concede proteção.

## Causa e evidência anterior

O diagnóstico histórico em docs/BUG_US01_03_DIAGNOSTICO.md confirmou abertura e viagem durante chase/windup e perda de HP com menu aberto; J/F1/M2 continuavam funcionando apesar de interaction_input_locked. O script diagnose_us01_03.gd registra aquela baseline anterior e deve ser executado no commit histórico para reproduzir essas observações; não é a suíte de aceite do novo comportamento.

A correção usa um único predicado de ameaça na exploração, sem alterar IA, dano, cooldowns, ranks, loot, missões, narrativa ou a implementação de save/load. Os scripts de produção de Fix01 e de IA Fix02 não receberam alterações nesta rodada.

## Arquivos alterados

- `src/world/exploration.gd`: travel_combat_active, fechamento/rejeição com feedback, validação em open_travel/travel/tick e sincronização do lock por visibility_changed, respeitando diálogo/loja. Limpa comandos/hold ao abrir um modal permitido.
- `scripts/hybrid_world.gd`: guardas de input em _unhandled_key_input, _cast_right_skill e _activate_skill. O caminho F9 após morte do Fix01 foi preservado.
- `tests/test_us01_fix03.gd` e UID: regressão permanente de 28 checks.
- `tools/test.ps1`: inclui Fix03, total 25 suítes.
- `.github/workflows/windows.yml`: nomes de exportação e artifact Fix03.
- `docs/README_TESTE_US01.txt`, `README.md`, este relatório e evidências em `docs/evidence/fix03/`: instruções e validação.
- `docs/BUG_US01_03_DIAGNOSTICO.md`: somente nota de atualização, preservando achados históricos.

## Testes reais

| Verificação | Resultado local |
|---|---|
| Importação sem cache anterior e parsing | exit 0; sem SCRIPT ERROR/Parse Error |
| Regressão Fix03 | 28 checks, zero falhas, exit 0 |
| Fix01 aprovado pelo PO | 28 checks, zero falhas, exit 0 |
| Fix02 aprovado pelo PO | 23 checks, zero falhas, exit 0 |
| Runner completo | 25 suítes, todas exit 0 |
| Consolidação existente | 5117 verificações sem falha |
| Bot de balanceamento | 10/10 vitórias |
| Exportação Windows Fix03 | exit 0; EXE e PCK novos exportados |
| Smoke do EXE | 40 checks, zero falhas, exit 0 |
| Cena principal, 120 frames | exit 0 |

A regressão Fix03 instancia a cena principal real e uma Campeã. Testa patrol permitido, rejeição de chase/search/attack, rejeição de windup, chamada direta a travel sem mutação de região/HP, nova ameaça após abertura, viagem pacífica, destino/fonte não descobertos, input modal, recursos inalterados, movimento após Escape, botão Fechar, locks de loja/diálogo, morte e load. Um cenário com IA ativa confirma que perseguição real fecha o painel; os demais estados são controlados na fixture para cobertura determinística, sem editar o script inimigo.

Perfis de save são isolados. O botão Fechar é verificado pela emissão de seu sinal real; teclado usa InputEventKey, movimento usa Input.action_press e M2/HUD são verificados por seus handlers. Não se declara playtest manual nem cobertura universal de todos os dispositivos/estados de UI.

## Reprodução

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
./tools/build_windows.ps1 -GodotExe $engine -BuildName EchoesOfAethel-US01-Fix03-Windows-x64
./tools/smoke_windows.ps1 -Executable "$pwd/teste-fase20/EchoesOfAethel-US01-Fix03-Windows-x64.exe"
& $engine --headless --path . --quit-after 120
python tools/audit_baseline.py
python tools/package_windows.py --build-name EchoesOfAethel-US01-Fix03-Windows-x64 --archive-name EchoesOfAethel-US01-Fix03-Windows-x64.zip
```

O cache .godot foi movido para .archive antes da importação, preservado. O runtime auxiliar local foi reinicializado após atualização de caminho/disponibilidade; a engine exigida permaneceu a mesma. Uma tentativa de preparação do README teve erro de nome de encoding antes da execução; corrigido sem alterar produto. Os resultados acima são da execução real concluída.

## Entrega e limites

Pacote: `EchoesOfAethel-US01-Fix03-Windows-x64.zip`, EXE/PCK correspondentes, fontes, logs e README_TESTE. Renderer GL Compatibility, Windows x86_64, viewport 1280x720 com escala existente; template release oficial sem assinatura, destinado a diagnóstico. Não é release comercial. O hash do EXE pode continuar igual ao template porque o código está no PCK externo, que foi reexportado. Link do CI, commit exato e hashes do conteúdo publicado constam no PR e na entrega final.

Suítes legadas emitiram avisos de 2–8 ObjectDB instances leaked ao encerrar, com exit 0 e checks concluídos; logs preservados. A regra de combate usa os estados aprovados, não todo evento possível de dano/aggro. Estados transitórios como hit sem windup ou dano recente não receberam nova classificação temporal nesta entrega. Licenciamento comercial continua pendente conforme a auditoria anterior. A validação gráfica final do Fix03 depende do PO, com atenção a ameaça surgindo no clique e coexistência de outros modais.

PR #18 permanece Draft. Nenhum merge. Nenhuma nova história. Aprovação da regra não é aprovação automática G1/G2 nem homologação do executável.

## Verificacao adicional do CI e fixture Fix02

A primeira execucao do CI deste Fix03 (39903685554) aprovou Fix03 28/0, mas parou em Fix02: `agent resumes after map synchronizes` (23 checks/1 falha). A falha foi preservada, nao ignorada/repetida ate passar. O teste usa frames fixos e um mapa privado recem-ativado; a sincronizacao assincrona da navegacao nao e uma barreira de prontidao por numero de frames.

Ajuste limitado a tests/test_us01_fix02.gd: `map_set_use_async_iterations(nav_map, false)` somente nos mapas criados pela fixture. A configuracao do mapa de producao e scripts de IA continuam intactos. Mantidos os 23 checks, os 35 frames e o deslocamento minimo >0,3m; nenhum criterio foi removido ou relaxado. Tres execucoes locais independentes passaram (23/0 cada), com logs anexados, e o CI integral sera repetido no novo commit. O teste registra a iteracao e o tamanho do caminho ao fim da espera. Isso torna a fixture deterministica; nao constitui homologacao de desempenho/scheduling assincrono em producao.

Referencia da API: https://docs.godotengine.org/en/stable/classes/class_navigationserver3d.html#class-navigationserver3d-method-map-set-use-async-iterations .
