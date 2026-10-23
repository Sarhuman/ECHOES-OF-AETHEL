# BUG-US01-03 â€” Fix03: Ã‚ncoras somente fora de combate

Data: 23/10/2026 (America/Bahia). Branch `audit/us-01-baseline-godot-472`. Base `1371cfca37426630b1ee53b3dd66fe7884f23682`. PR #18 Draft, sem merge. Godot `4.7.2.stable.official.ed1daf0bf`, Windows x64.

## Regra aprovada e implementada

O PO respondeu "sim" Ã  proposta de bloquear abertura e viagem durante chase/search/attack, fechar o menu quando surgir ameaÃ§a e manter o mundo ativo. A modalizaÃ§Ã£o dos atalhos de combate fazia parte da proposta apresentada. NÃ£o hÃ¡ pausa global, alteraÃ§Ã£o de HP ou imunidade nova.

Um inimigo vivo, nÃ£o removido, cujo alvo seja o jogador e esteja em chase, search ou attack impede a travessia. Windup ativo tambÃ©m bloqueia, mesmo no intervalo anterior Ã  atualizaÃ§Ã£o de ai_state. Inimigo apenas prÃ³ximo em patrol/return, morto, invÃ¡lido ou sem o jogador como alvo nÃ£o Ã© automaticamente combate. A revisÃ£o Fix03R1 implementa a janela de 5000 ms apÃ³s dano efetivo de inimigo, conforme autorizaÃ§Ã£o explÃ­cita do PO. NÃ£o existe bloqueio arbitrÃ¡rio por raio de proximidade.

- A abertura revalida combate antes de mostrar o menu.
- travel() revalida imediatamente antes das demais condiÃ§Ãµes e da troca de regiÃ£o; chamada direta tambÃ©m Ã© bloqueada.
- Se surgir ameaÃ§a enquanto o painel estiver aberto, tick() fecha o menu e mostra feedback de combate.
- J, F1â€“F3, M2 e ativaÃ§Ã£o de habilidade pelo HUD nÃ£o executam aÃ§Ãµes nem consomem recursos com o menu aberto. Movimento/esquiva mantÃªm os bloqueios existentes.
- Fechar/Escape liberam o lock da viagem imediatamente, respeitando diÃ¡logo ou loja ainda abertos. MudanÃ§a de regiÃ£o, morte e load tambÃ©m passam pela sincronizaÃ§Ã£o da visibilidade do painel.
- Mundo, inimigos e recebimento de dano continuam processando normalmente. Um menu nÃ£o concede proteÃ§Ã£o.

## Causa e evidÃªncia anterior

O diagnÃ³stico histÃ³rico em docs/BUG_US01_03_DIAGNOSTICO.md confirmou abertura e viagem durante chase/windup e perda de HP com menu aberto; J/F1/M2 continuavam funcionando apesar de interaction_input_locked. O script diagnose_us01_03.gd registra aquela baseline anterior e deve ser executado no commit histÃ³rico para reproduzir essas observaÃ§Ãµes; nÃ£o Ã© a suÃ­te de aceite do novo comportamento.

A correÃ§Ã£o usa um Ãºnico predicado de ameaÃ§a na exploraÃ§Ã£o, sem alterar IA, dano, cooldowns, ranks, loot, missÃµes, narrativa ou a implementaÃ§Ã£o de save/load. Fix01 permanece intacto. No script inimigo Fix02, somente os dois pontos de envio de dano passam agora `self` como origem; estados, navegaÃ§Ã£o, probabilidades, dano, cooldowns e balanceamento permanecem iguais.

## Arquivos alterados

- `src/world/exploration.gd`: travel_combat_active, fechamento/rejeiÃ§Ã£o com feedback, validaÃ§Ã£o em open_travel/travel/tick e sincronizaÃ§Ã£o do lock por visibility_changed, respeitando diÃ¡logo/loja. Limpa comandos/hold ao abrir um modal permitido.
- `scripts/hybrid_world.gd`: guardas de input em _unhandled_key_input, _cast_right_skill e _activate_skill. O caminho F9 apÃ³s morte do Fix01 foi preservado.
- `tests/test_us01_fix03.gd` e UID: regressÃ£o permanente de 28 checks.
- `tools/test.ps1`: inclui Fix03, total 26 suÃ­tes.
- `.github/workflows/windows.yml`: nomes de exportaÃ§Ã£o e artifact Fix03.
- `docs/README_TESTE_US01.txt`, `README.md`, este relatÃ³rio e evidÃªncias em `docs/evidence/fix03/`: instruÃ§Ãµes e validaÃ§Ã£o.
- `docs/BUG_US01_03_DIAGNOSTICO.md`: somente nota de atualizaÃ§Ã£o, preservando achados histÃ³ricos.

## Testes reais

| VerificaÃ§Ã£o | Resultado local |
|---|---|
| ImportaÃ§Ã£o sem cache anterior e parsing | exit 0; sem SCRIPT ERROR/Parse Error |
| RegressÃ£o Fix03 | 28 checks, zero falhas, exit 0 |
| Fix01 aprovado pelo PO | 28 checks, zero falhas, exit 0 |
| Fix02 aprovado pelo PO | 23 checks, zero falhas, exit 0 |
| Runner completo | 26 suÃ­tes, todas exit 0 |
| ConsolidaÃ§Ã£o existente | 5117 verificaÃ§Ãµes sem falha |
| Bot de balanceamento | 10/10 vitÃ³rias |
| ExportaÃ§Ã£o Windows Fix03 | exit 0; EXE e PCK novos exportados |
| Smoke do EXE | 40 checks, zero falhas, exit 0 |
| Cena principal, 120 frames | exit 0 |

A regressÃ£o Fix03 instancia a cena principal real e uma CampeÃ£. Testa patrol permitido, rejeiÃ§Ã£o de chase/search/attack, rejeiÃ§Ã£o de windup, chamada direta a travel sem mutaÃ§Ã£o de regiÃ£o/HP, nova ameaÃ§a apÃ³s abertura, viagem pacÃ­fica, destino/fonte nÃ£o descobertos, input modal, recursos inalterados, movimento apÃ³s Escape, botÃ£o Fechar, locks de loja/diÃ¡logo, morte e load. Um cenÃ¡rio com IA ativa confirma que perseguiÃ§Ã£o real fecha o painel; os demais estados sÃ£o controlados na fixture para cobertura determinÃ­stica, sem editar o script inimigo.

Perfis de save sÃ£o isolados. O botÃ£o Fechar Ã© verificado pela emissÃ£o de seu sinal real; teclado usa InputEventKey, movimento usa Input.action_press e M2/HUD sÃ£o verificados por seus handlers. NÃ£o se declara playtest manual nem cobertura universal de todos os dispositivos/estados de UI.

## ReproduÃ§Ã£o

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
./tools/build_windows.ps1 -GodotExe $engine -BuildName EchoesOfAethel-US01-Fix03R1-Windows-x64
./tools/smoke_windows.ps1 -Executable "$pwd/teste-fase20/EchoesOfAethel-US01-Fix03R1-Windows-x64.exe"
& $engine --headless --path . --quit-after 120
python tools/audit_baseline.py
python tools/package_windows.py --build-name EchoesOfAethel-US01-Fix03R1-Windows-x64 --archive-name EchoesOfAethel-US01-Fix03R1-Windows-x64.zip
```

O cache .godot foi movido para .archive antes da importaÃ§Ã£o, preservado. O runtime auxiliar local foi reinicializado apÃ³s atualizaÃ§Ã£o de caminho/disponibilidade; a engine exigida permaneceu a mesma. Uma tentativa de preparaÃ§Ã£o do README teve erro de nome de encoding antes da execuÃ§Ã£o; corrigido sem alterar produto. Os resultados acima sÃ£o da execuÃ§Ã£o real concluÃ­da.

## Entrega e limites

Pacote: `EchoesOfAethel-US01-Fix03R1-Windows-x64.zip`, EXE/PCK correspondentes, fontes, logs e README_TESTE. Renderer GL Compatibility, Windows x86_64, viewport 1280x720 com escala existente; template release oficial sem assinatura, destinado a diagnÃ³stico. NÃ£o Ã© release comercial. O hash do EXE pode continuar igual ao template porque o cÃ³digo estÃ¡ no PCK externo, que foi reexportado. Link do CI, commit exato e hashes do conteÃºdo publicado constam no PR e na entrega final.

SuÃ­tes legadas emitiram avisos de 2â€“8 ObjectDB instances leaked ao encerrar, com exit 0 e checks concluÃ­dos; logs preservados. A regra de combate usa os estados aprovados, nÃ£o todo evento possÃ­vel de dano/aggro. A revisÃ£o Fix03R1 tambÃ©m bloqueia `hit` quando o inimigo vivo tem o jogador como alvo e memÃ³ria ativa de perseguiÃ§Ã£o (`search_remaining > 0`); `hit` sem ameaÃ§a ativa nÃ£o bloqueia por si sÃ³. Licenciamento comercial continua pendente conforme a auditoria anterior. A validaÃ§Ã£o grÃ¡fica final do Fix03 depende do PO, com atenÃ§Ã£o a ameaÃ§a surgindo no clique e coexistÃªncia de outros modais.

PR #18 permanece Draft. Nenhum merge. Nenhuma nova histÃ³ria. AprovaÃ§Ã£o da regra nÃ£o Ã© aprovaÃ§Ã£o automÃ¡tica G1/G2 nem homologaÃ§Ã£o do executÃ¡vel.

## Verificacao adicional do CI e fixture Fix02

A primeira execucao do CI deste Fix03 (39903685554) aprovou Fix03 28/0, mas parou em Fix02: `agent resumes after map synchronizes` (23 checks/1 falha). A falha foi preservada, nao ignorada/repetida ate passar. O teste usa frames fixos e um mapa privado recem-ativado; a sincronizacao assincrona da navegacao nao e uma barreira de prontidao por numero de frames.

Ajuste limitado a tests/test_us01_fix02.gd: `map_set_use_async_iterations(nav_map, false)` somente nos mapas criados pela fixture. A configuracao do mapa de producao e scripts de IA continuam intactos. Mantidos os 23 checks, os 35 frames e o deslocamento minimo >0,3m; nenhum criterio foi removido ou relaxado. Tres execucoes locais independentes passaram (23/0 cada), com logs anexados, e o CI integral sera repetido no novo commit. O teste registra a iteracao e o tamanho do caminho ao fim da espera. Isso torna a fixture deterministica; nao constitui homologacao de desempenho/scheduling assincrono em producao.

Referencia da API: https://docs.godotengine.org/en/stable/classes/class_navigationserver3d.html#class-navigationserver3d-method-map-set-use-async-iterations .

## RevisÃ£o Fix03R1 â€” divergÃªncia corrigida (23/10/2026)

O PO confirmou que a janela de cinco segundos jÃ¡ estava autorizada e faltou no Fix03 anterior. A implementaÃ§Ã£o usa exclusivamente `Time.get_ticks_msec()`: nÃ£o depende do delta, FPS, relÃ³gio civil ou tempo de animaÃ§Ã£o. O predicado compartilhado rejeita abertura e chamada direta a travel durante `[Ãºltimo dano, Ãºltimo dano + 5000 ms)`. Cada nova perda efetiva de HP por inimigo renova a janela. O sinal sÃ­ncrono fecha imediatamente o menu, respeitando os demais locks; o mundo continua ativo.

`hybrid_player.gd` emite `enemy_damage_received` apenas depois da reduÃ§Ã£o de HP e quando a origem pertence a `hybrid_enemies`. `hybrid_enemy.gd` informa a origem em golpes e DOT corrompido. Invulnerabilidade, esquiva e bloqueio sem perda de HP nÃ£o emitem o sinal. Dano ambiental continua aplicando seu dano normal, sem iniciar nem renovar a janela. NÃ£o foram modificadas fÃ³rmulas, imunidades, estado de IA ou navegaÃ§Ã£o. A marca Ã© transitÃ³ria da sessÃ£o, nÃ£o serializada; carregar save na mesma sessÃ£o nÃ£o a limpa.

Os 28 checks originais de `test_us01_fix03.gd` permanecem integralmente intactos. A nova suÃ­te `test_us01_fix03_recent_damage.gd` acrescenta 24 checks: dano ambiental, dano ignorado, bloqueio, HP efetivo, fechamento imediato, abertura proibida, chamada direta sem mutaÃ§Ã£o, renovaÃ§Ã£o, persistÃªncia apÃ³s remoÃ§Ã£o do atacante, expiraÃ§Ã£o real apÃ³s cinco segundos, coexistÃªncia com chase/search/attack antes e depois da expiraÃ§Ã£o, hit com/sem memÃ³ria ativa, melee e DOT inimigo reais. A espera usa o relÃ³gio monotÃ´nico real, nÃ£o avanÃ§o artificial de frames. Os demais estados sÃ£o fixtures controladas; isso nÃ£o substitui homologaÃ§Ã£o grÃ¡fica pelo PO.

A fixture Fix02 conserva o ajuste determinÃ­stico de navegaÃ§Ã£o sÃ­ncrona do commit 984f934, seus 23 checks e critÃ©rios numÃ©ricos. Somente o DummyPlayer aceita o argumento opcional de origem. A suÃ­te Phase25 jÃ¡ recebia DOT inimigo antes da viagem pacÃ­fica: agora aguarda explicitamente a expiraÃ§Ã£o real da janela, mantendo a mesma asserÃ§Ã£o de viagem. NÃ£o limpa a marca nem enfraquece a regra de produÃ§Ã£o.

ValidaÃ§Ã£o local desta revisÃ£o: importaÃ§Ã£o com cache anterior preservado em `.archive`, parsing, grafo, 26 suÃ­tes e exportaÃ§Ã£o pela mesma engine oficial. Os resultados finais, smoke e hashes sÃ£o registrados nas evidÃªncias de `docs/evidence/fix03r1/` e no PR. O CI deve rodar integralmente no commit publicado. A situaÃ§Ã£o de G1/G2 permanece pendente de decisÃ£o humana.

Resultado local final Fix03R1: 26/26 suítes exit 0; Fix03 original 28/0; dano recente 24/0; Fix01 28/0; Fix02 23/0; cena principal 120 frames exit 0; EXE Windows novo 40/0; auditoria sem arquivos ausentes. Evidências em `docs/evidence/fix03r1/`. A importação/exportação local registrou restrições do ambiente (certificados raiz e gravação de editor_settings em AppData), sem erro de parsing nem falha de exportação. O smoke retornou sucesso; uma checagem externa redundante de `$LASTEXITCODE` após o script PowerShell leu valor residual e foi corrigida na orquestração, sem alteração do jogo ou do script de smoke. Os logs efetivos confirmam 40/0. Avisos de ObjectDB de suítes legadas permanecem documentados, sem atribuir homologação humana.
