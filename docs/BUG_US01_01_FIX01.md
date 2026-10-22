# BUG-US01-01 — Validação e build Fix01

Data: 22/10/2026. Branch `audit/us-01-baseline-godot-472`; PR #18 Draft. Godot `4.7.2.stable.official.ed1daf0bf`, Windows x64. Sem merge e sem aprovação automática G1/G2.

## Diagnóstico do commit recebido

Checkout atualizado por fast-forward até b2c78d7bec0d0f9aa96b6da7219f9eb90eff04f6, incluindo b99fbb3 e 916f82c. As alterações recebidas foram preservadas. `_load_state()` já restaurava HP e chamava `reset_transient_state_after_load()` para save vivo; este já limpava bloqueios e chamava `CharacterVisual.reset_after_load()`.

Defeitos comprovados restantes:

1. `CharacterVisual` mandava idle ao modelo procedural, mas `procedural_knight.play_state()` retornava imediatamente se `_visual_state == death`. O torso e a trava interna permaneciam caídos; o modelo atual não depende de AnimationPlayer.
2. `_unhandled_key_input()` retornava em game_over antes de tratar F9. O carregamento direto funcionava, a tecla na tela de derrota não.
3. Recargas de habilidades, não persistidas, sobreviviam ao load e bloqueavam o comando da sessão restaurada.
4. Após permitir reset real do modelo, um save de HP zero carregado de uma sessão viva precisava restaurar explicitamente o estado visual death. HP zero já bloqueava controle; não foi adicionado mecanismo de ressurreição.

## Correções e arquivos modificados

- `scripts/procedural_knight.gd`: hook explícito reset_after_load; mata tween de morte, limpa estado interno/temporizador e rotações das partes, retira indicador de guarda. Requests normais continuam proibidos de sair de death.
- `src/characters/character_visual.gd`: chama hook de reset do modelo, quando suportado, antes de idle; mantém caminho AnimationPlayer existente.
- `scripts/hybrid_player.gd`: limpa somente skill_cooldowns no reset transitório já existente. Mantém custo, duração e regras normais das habilidades.
- `scripts/hybrid_world.gd`: permite F9 na derrota e aplica visual death para snapshot com HP zero.
- `tests/test_us01_fix01.gd` e UID: regressão permanente com input F5/F9, morte real, HP/posição, locks, torso/modelo, movimento, ataque, habilidade, inventário/equipamentos/narrativa, load durante tween e HP zero; captura gráfica opcional.
- `tools/test.ps1`: integra a regressão ao runner, agora 23 suítes.
- `src/core/build_smoke.gd`: oito checks extras somente no diagnóstico opt-in do EXE, incluindo J/F2/F9 reais; não altera execução normal.
- `tools/smoke_windows.ps1`: exige 40 checks concluídos.
- `.github/workflows/windows.yml`: exporta e publica pacote Fix01 distinto; executa inventário antes de empacotar.
- `docs/README_TESTE_US01.txt`, `README.md`, este relatório e evidências em `docs/evidence/fix01`: instruções, diagnóstico e resultados.

IA e âncoras não foram modificadas. Testes desativam física de atores apenas na fixture para isolar o fluxo; não alteram scripts de inimigos. Sem alteração de combate, narrativa, navegação ou balanceamento.

## Evidências antes/depois

A regressão final foi copiada para uma extração independente do commit original b2c78d7. Importação original exit 0; regressão original exit 1: 29 checks, 8 falhas, incluindo F9, estado interno de morte, torso, tween, cooldown, locomoção e habilidade. Um check extra executa somente quando F9 falha e tenta load direto para separar causas.

Com correções: 28 checks, zero falhas, exit 0. Execução gráfica OpenGL 3.3 Compatibility/Radeon RX 580: mesmos 28 checks, zero falhas. Capturas reais: fix01-dead.png, fix01-restored.png, fix01-moving.png. HP restaurado 145/155; torso vertical após load e após 30 frames; deslocamento por entrada de movimento >0,2m; ataque básico arma cooldown/animação e habilidade consome Éter/arma recarga. Snapshot de HP zero mantém derrota, modelo em death, movimento e habilidade bloqueados.

O primeiro rascunho do teste comparava estruturas nativas com JSON parseado, gerando duas falsas falhas de preservação por tipos numéricos. A comparação final usa snapshots nativos antes/depois e passa também no commit original; não foi feita alteração no inventário/equipamento.

Smoke inicial Fix01 falhou somente na fixture de morte sob guarda e redução de exploração: dano 2x HP não era necessariamente letal. Ajustado o dano da fixture para 10x HP, sem modificar as regras do jogador. Reexportado e repetido: 40 checks, zero falhas, exit 0.

## Comandos e resultados reais

Cache `.godot` anterior movido para `.archive` antes da importação limpa, sem apagar trabalho do usuário.

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
./tools/build_windows.ps1 -GodotExe $engine -BuildName EchoesOfAethel-US01-Fix01-Windows-x64
./tools/smoke_windows.ps1 -Executable "$pwd/teste-fase20/EchoesOfAethel-US01-Fix01-Windows-x64.exe"
& $engine --headless --path . --quit-after 120
python tools/audit_baseline.py
python tools/package_windows.py --build-name EchoesOfAethel-US01-Fix01-Windows-x64 --archive-name EchoesOfAethel-US01-Fix01-Windows-x64.zip
```

Build script: importação limpa + grafo de regiões + 23 suítes (inclui parsing de todos os GDScripts e regressão Fix01) + exportação, exit 0. Todas as suítes exit 0; consolidação 5117 checks sem falha, bot 10/10 vitórias. Após ajustar apenas a fixture de smoke, nova exportação -SkipTests exit 0 e EXE smoke exit 0; CI repete integralmente o conjunto final. Cena principal 120 frames exit 0. Logs e results.json incluídos nas evidências e no pacote.

## Build e hashes

Godot 4.7.2; Windows Desktop x86_64; GL Compatibility; viewport base 1280x720; template release oficial com PCK externo, sem assinatura. Build de teste, não release comercial. Houve nova exportação: não foi copiado o EXE anterior. O SHA do EXE coincide com o template e o anterior porque modify_resources=false e o conteúdo do jogo está no PCK externo, que mudou.

EXE SHA-256: `D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562`.
PCK SHA-256: `668DA6555F12D7374829E72B54FB61B1DCDFD9F4DD5F141B9792EB4E81564157` (build local).
ZIP e artifact CI: hashes e link na entrega e no PR, pois incluir o hash do próprio ZIP dentro dele causa autorreferência. Pacote inclui EXE/PCK, README_TESTE e fontes/evidências. Extraia o artifact e o ZIP interno, abra `jogo/` e mantenha EXE/PCK juntos.

## Limitações e governança

Algumas suítes legadas emitiram avisos de 2–4 ObjectDB instances leaked no encerramento, com exit 0 e sem falhas de assertions. Não foram mascarados nem tratados como corrigidos; logs integrais preservados. A regressão final Fix01 e sua execução gráfica não emitiram esse aviso. Inspeção manual prolongada, outros modelos importados/rigs e estabilidade em outras GPUs não foram homologados. A restauração do modelo procedural atual foi comprovada; nenhum novo modelo foi integrado.

Licenciamento comercial dos assets continua pendente conforme US01_DEPENDENCIES_LICENSES.md. PR #18 permanece Draft. Nenhum merge, nova história ou mudança em IA/âncoras. PO decide G1/G2 após revisar evidências e testar o build.
