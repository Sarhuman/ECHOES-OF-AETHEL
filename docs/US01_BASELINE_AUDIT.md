# US-01 — Baseline executável e auditoria

Data: 22/10/2026. Branch exclusiva: `audit/us-01-baseline-godot-472`. Base inspecionada: `e71ccb5f9237aadd0443d2cb543ba419289a5a97`. PR #18 permanece Draft, sem merge. Candidato técnico ao G1, sujeito às limitações abaixo; G2 aguarda homologação expressa do PO.

## A. Diagnóstico

O erro global AethelInventoryView relatado na linha 38 de hybrid_world.gd **não foi reproduzido** no checkout isolado com Godot 4.7.2.stable.official.ed1daf0bf, inclusive antes das alterações. Não há causa-raiz demonstrada nem correção de parser que possa ser honestamente atribuída a este trabalho. Não há duplicação de class_name. InventoryView instancia AethelInventoryItemButton e este tipa seu owner como AethelInventoryView: a dependência circular existe e é resolvida pela engine testada. As dependências transitivas foram carregadas pela importação, testes de integridade e nova regressão que carrega todos os scripts. Os tipos foram preservados.

O checkout raiz local estava em integration/fase20-arpg-windows com exclusões preexistentes; foi preservado. Foi criado o checkout us01 a partir da branch remota autorizada, sem misturar fases posteriores. Cache antigo ou divergência local são hipóteses para o relato, não causas confirmadas. Recomenda-se reproduzir nessa branch limpa antes de atribuir o erro ao código.

F5/F9 continuam salvar/carregar. A nova regressão injeta eventos reais, salva ouro 321, altera para 1 e verifica restauração 321 e árvore sem pausa. A execução gráfica existente também percorreu save/load. O congelamento no editor do PO não foi reproduzido. A documentação oficial de atalhos 4.6 lista F9 como toggle_breakpoint e F7 como pausa; não comprova a configuração local 4.7.2 do PO: https://docs.godotengine.org/en/4.6/tutorials/editor/default_key_mapping.html . Verificar foco da janela e breakpoints, sem alterar o sistema de save/load por hipótese.

## B. Alterações completas de implementação

- src/core/input_actions.gd: casts explícitos Key/MouseButton.
- src/ui/options_panel.gd: scale_option evita sombrear Control.scale.
- scripts/hybrid_enemy.gd e src/world/exploration.gd: tipos compatíveis nos ramos de ternários, preservando cálculos.
- src/world/exploration.gd: new_label evita declarações confundíveis, mantendo dicionários e nós.
- src/items/inventory_view.gd: _keyboard preserva assinatura; sinal público equipment_drop_requested mantido com supressão localizada e justificativa porque emitido pelo botão externo.
- src/ui/hud_manager.gd: effect_name evita sombrear Node.name.
- scripts/hybrid_world.gd: pointer_position evita sombrear Node3D.position.
- scripts/hybrid_player.gd, src/ui/item_tooltip.gd e scripts/hybrid_world.gd: INTEGER_DIVISION intencional documentada e suprimida somente no cálculo existente. Não converter para float: mudaria defesa/preço.
- tests/test_us01_baseline.gd: regressão de parsing, instâncias tipadas, sinal e F5/F9 em perfil isolado.
- tools/test.ps1: incorpora a regressão às 21 suítes anteriores (22 ao todo).
- tools/build_windows.ps1: nome de build parametrizável, mantém guardas de versão/hash.
- tools/package_windows.py: nome US01 por argumento, allowlist do jogo, README e evidências selecionadas.
- tools/audit_baseline.py: inventário completo e checagem de referências literais.
- .github/workflows/windows.yml: build/teste/package e artifact US01 com engine exata.
- docs/README_TESTE_US01.txt, docs/US01_DEPENDENCIES_LICENSES.md e este relatório: execução e auditoria atualizadas. README.md aponta a entrega atual. Evidências selecionadas em docs/evidence/us01.

Não há alteração de mapas, narrativa de Maera, regras de combate, loot ou progressão. Arquivos .import regenerados localmente não integram as mudanças intencionais.

## C. Execuções reais e reprodução

Ambiente: Windows x64; Godot 4.7.2.stable.official.ed1daf0bf. GPU real identificada na execução gráfica: AMD Radeon RX 580 2048SP, OpenGL 3.3 Compatibility. Use PowerShell na raiz do projeto:

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
& $engine --headless --path . --editor --import --quit
& $engine --headless --path . --quit-after 120
./tools/build_windows.ps1 -GodotExe $engine -BuildName EchoesOfAethel-US01-Windows-x64
./tools/smoke_windows.ps1 -Executable "$pwd/teste-fase20/EchoesOfAethel-US01-Windows-x64.exe"
python tools/audit_baseline.py
python tools/package_windows.py --build-name EchoesOfAethel-US01-Windows-x64 --archive-name EchoesOfAethel-US01-Windows-x64.zip
```

Reconstrução em checkout limpo: execute antes tools/fetch_godot.ps1 e python tools/fetch_windows_template.py; então use a engine de .tools no comando de build. O teste cria perfis isolados; não use o perfil real do jogador.

| Verificação executada | Resultado |
|---|---|
| Importação inicial, sem alterações | exit 0, erro de parser não reproduzido |
| Cena principal headless, 120 frames | exit 0 |
| Importação final + region graph | exit 0; zero erros no grafo |
| 22 suítes no runner final | todos exit 0; results.json e logs individuais |
| Nova regressão US01 | 83 checks, zero falhas |
| Consolidação existente | 5117 verificações, zero falhas |
| Bot de balanceamento existente | 10/10 vitórias, sem mudar balanceamento |
| Exportação Windows | exit 0; EXE e PCK reais |
| Smoke do EXE exportado | exit 0; 32 checks, zero falhas |
| Teste gráfico phase27_gui real | exit 0; 169 checks, zero falhas; capturas 720p/1080p |
| Scanner de referências literais | zero ausências não intencionais; fixture inválida e caminho dinâmico registrados |

Limites das evidências: o teste gráfico congela movimento/ataque de inimigos como fixture; captura rápida não mede FPS. Não representa playtest humano de combate, acessibilidade ou estabilidade prolongada. A suíte intermediária rodou durante pequenos ajustes e não é tratada como baseline anterior imutável; a rodada final foi integral após os ajustes de GDScript.

Uma execução ad-hoc inicial de inventário falhou no save porque o diretório do perfil não havia sido criado; o runner oficial cria a pasta e passou. Falhas de certificado/configuração global da Godot ocorreram sob sandbox inicial, não em execuções autorizadas; não foram classificadas como defeito do jogo. Logs preliminares preservados no pacote quando selecionados.

## D. Avisos

Os 13 pontos fornecidos receberam alterações localizadas: enum; scale; defesa/divisão; ternário de dano; divisão de preço/tooltip; sinal externo; parâmetro keyboard; name; duas declarações label; ternário de movimento; position; divisão no vendedor. As três divisões e o sinal externo ficam explicitamente suprimidos, com razões no código. Nenhum sinal público foi removido. Importação e execução final não apresentaram SCRIPT ERROR/Parse Error. Isso não é afirmação de zero avisos em todas as configurações do editor: não houve extração exaustiva do painel de warnings do editor do PO.

## E. Build Windows

Nome: EchoesOfAethel-US01-Windows-x64.exe, com PCK externo obrigatório. x86_64, renderer gl_compatibility, viewport 1280x720 com canvas_items/expand. Preset Windows Desktop; template release oficial verificado, recursos do executável sem modificação, sem assinatura. É um pacote de diagnóstico para teste, não lançamento comercial nem export debug.

EXE: 109268480 bytes; SHA-256 D34D36F3BE1A6C49C56525AE86469B92E4F417DDF0B43CF00DD80C385C4B0562.
PCK: 1859068 bytes; SHA-256 A809DF76CF6B260D3F20781451766E575B3AF0EEE7305A8278E4391647FBE92E.

O hash do EXE iguala o template porque o PCK é externo e modify_resources=false. O conteúdo do jogo está no PCK. O ZIP contém fontes, instruções e logs, além do jogo. Hash do ZIP é registrado na entrega externa para evitar autorreferência. Workflow Windows publica artifact no PR; não versionar binários. README_TESTE.txt explica extração e controles.

## F. Riscos e dependências

Ver US01_DEPENDENCIES_LICENSES.md e inventário por arquivo. Godot MIT e atribuições estão disponíveis. Licença comercial geral dos assets/código do projeto ainda não comprovada, exigindo confirmação do PO antes de distribuição comercial. Baseline é experimental e mantém arte provisória. Nenhum modelo Meshy/arte das fases posteriores foi incorporado.

## G. Governança

PR #18 Draft. Nenhum merge. Somente US-01. O resultado é candidato à revisão G1 com limitações declaradas, nunca homologação G2. PO deve validar graficamente o executável, incluindo Maera, combate, inventário, save/load, ambas resoluções e relatório do eventual congelamento no editor.
## Complemento — pacote extraído sem cache

O ZIP local foi extraído em `.archive/us01-clean-validation`, sem `.godot` e sem `.tools`. Todos os hashes do manifesto foram conferidos. A Godot 4.7.2 importou `fonte/project.godot` com exit 0 e nenhuma linha ERROR; a regressão US01 executada nessa cópia passou novamente: 83 checks, zero falhas, exit 0. Logs: us01-clean-checkout.log e us01-clean-runtime.log. Essa prova valida o conteúdo empacotado, sem depender do cache de importação do checkout de trabalho.
