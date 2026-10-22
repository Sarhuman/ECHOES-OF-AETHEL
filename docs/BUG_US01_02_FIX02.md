# BUG-US01-02 — Percepção e navegação inimiga / Fix02

Data: 22/10/2026. Branch exclusiva `audit/us-01-baseline-godot-472`. Base confirmada c043d5c747e03b7cea1b516860733f4add967f58; fetch/fast-forward não encontrou commits novos. Godot 4.7.2.stable.official.ed1daf0bf. PR #18 permanece Draft, sem merge. Aprovação manual do Fix01 informada pelo PO é preservada; não constitui homologação global G1/G2 deste pacote.

## Causa raiz confirmada

Em hybrid_enemy.gd, aquisição era determinada pela distância horizontal (<18m) e leash da origem (<24m), sem raycast. A direção de perseguição começava apontando diretamente ao jogador e só era substituída se o agente fornecesse waypoint; caminho vazio/indisponível ou mapa não sincronizado mantinha movimento direto. Não havia memória da última posição observada nem tempo de busca. O início do golpe e sua resolução usavam alcance numérico sem verificar sólidos.

A mesma regressão final foi executada em uma extração isolada do commit anterior: importação exit 0; IA 23 checks/14 falhas, exit 1. Após a correção: 23 checks/zero falhas, exit 0. Não se trata apenas de cálculos vetoriais: são corpos físicos, paredes/pilares BoxShape3D, move_and_slide e NavigationRegion3D/NavigationAgent3D reais em execução Godot.

## Alterações

Somente `scripts/hybrid_enemy.gd` altera comportamento de produção nesta rodada:

- PhysicsDirectSpaceState3D.intersect_ray entre pontos a 1m acima dos pés. Máscara 1|8: sólidos do cenário (1), sólidos NPC (8); exclui RIDs do inimigo/alvo e ignora Areas. Jogador usa layer 2, inimigos 4 e picking 16, que não bloqueiam a percepção de outros atores.
- Aquisição exige linha de visão, mantendo distâncias 18m/24m. Não consulta posições atuais ocultas para guiar movimento: memoriza somente uma posição vista.
- Mantém patrol/chase/return/hit/attack/death e acrescenta search. Memória dura 5s desde a última observação; ao expirar, retorna à origem e patrulha. Após abandono, intervalo de 3s para nova aquisição evita alternância a cada frame.
- Navegação distingue waiting, unavailable, available, reached e blocked. Consulta o agente a cada frame em movimento, valida caminho não vazio, alvo alcançável, ponto final e término. iteration_id positivo sozinho não aprova rota. Sem rota válida, velocidade é zero: não há fallback direto ao jogador.
- Atualiza destino quando ele muda (>0,5m), muda a iteração do mapa ou há falha/bloqueio; não reinicia o mesmo caminho saudável a cada 0,3s. O reinício constante fazia o ator recuar para vértices anteriores nas curvas. Tolerância de waypoint 0,2m e de destino 0,45m evitam pular curvas; distância de ataque permanece a anterior.
- Mede deslocamento físico durante tentativa de navegação. Após 1,5s sem progresso na perseguição/busca, abandona; retorno inviável é limitado. Separação mantém coeficiente 0,8 e evita inverter a direção do caminho.
- Confere linha de visão no início e no fim do windup. Intervalo 0,4s, alcances 1,55/1,95m, dano, ranks, atributos, cooldowns, stagger e modificadores numéricos permanecem iguais. Dano periódico corrupted também respeita sólidos, mantendo raio, intervalo e valor. Buff guardian permanece igual.
- Alvo morto/inválido cancela windup e memória; respawn visível pode ser adquirido novamente. Persistência continua reconstruindo atores pelo fluxo existente.

Outros arquivos modificados:

- `tests/test_us01_fix02.gd` e UID: 23 checks físicos permanentes, mapas próprios isolados e cleanup de RIDs.
- `tools/test.ps1`: adiciona Fix02 ao runner, agora 24 suítes.
- `.github/workflows/windows.yml`: nomes de exportação/artifact Fix02.
- `docs/README_TESTE_US01.txt` e `README.md`: apontam o novo pacote e passos de teste.
- Este relatório e `docs/evidence/fix02/`: resultados, logs, antes/depois.

Não foram modificados arquivos do Fix01, jogador, visual do Bastião, missões, narrativa, habilidades, loot, dados de balanceamento, mapas ou âncoras. Os testes de IA desativam/posicionam atores somente em fixtures.

## Regressão física — cobertura

| Cenário | Resultado corrigido |
|---|---|
| Área aberta | aquisição e deslocamento físico >0,5m |
| Parede entre atores próximos | sem aquisição por distância |
| Jogador observado e depois oculto | search e última posição igual à observada |
| Busca expirada | return/patrol; reaparecimento pode ser adquirido |
| Pilar de 2x4m com rota | contorna >2,3m lateralmente e passa para x>1,5m |
| Ilhas de navegação desconectadas com visão aberta | unavailable; sem fallback físico através do intervalo |
| Polígonos desatualizados diante de parede física | blocked observado, busca termina e ator retorna |
| Mapa ainda inativo/sem sincronização | waiting e sem movimento; retoma após sincronizar |
| Parede dentro do alcance corpo a corpo | não inicia nem causa dano |
| Parede surge durante windup | golpe não atinge através do sólido |
| Dano periódico corrompido atrás da parede | sem dano através do sólido |
| Três inimigos | todos fazem progresso físico sem travar a simulação |
| Jogador morto, respawn e morte inimiga | cancela windup, readquire alvo vivo e remove inimigo derrotado |
| Save/load e controles após morte | regressão Fix01 separada: 28 checks/zero falhas |

A fixture usa células e polígonos compartilhando vértices, equivalentes ao mecanismo de region_level.gd; obstáculos removem células com margem. `map_force_update` é usado somente na fixture para estabelecer cenários reproduzíveis. Um rascunho que desabilitava uma região já registrada observou consultas ainda usando a rota anterior; foi substituído por duas ilhas realmente desconectadas. Isso não foi apresentado como defeito corrigido da engine nem como cobertura de edição dinâmica arbitrária do navmesh.

## Execução real e comandos

Cache local .godot anterior preservado em .archive antes da importação limpa.

```powershell
$engine = 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe'
./tools/build_windows.ps1 -GodotExe $engine -BuildName EchoesOfAethel-US01-Fix02-Windows-x64
./tools/smoke_windows.ps1 -Executable "$pwd/teste-fase20/EchoesOfAethel-US01-Fix02-Windows-x64.exe"
& $engine --headless --path . --quit-after 120
python tools/audit_baseline.py
python tools/package_windows.py --build-name EchoesOfAethel-US01-Fix02-Windows-x64 --archive-name EchoesOfAethel-US01-Fix02-Windows-x64.zip
```

Importação limpa, grafo, parsing de todos os scripts, 24 suítes e exportação: exit 0. IA Fix02: 23/0. Fix01: 28/0. Consolidação: 5117/0. Bot: 10/10 vitórias (tempos mudaram com a navegação; não foi alterado o balanceamento). Cena principal 120 frames: exit 0. EXE smoke: 40/0, exit 0, mantendo checks de load após morte do Fix01. Scanner: zero referências ausentes não intencionais, uma referência dinâmica documentada.

Logs individuais e results.json ficam no pacote. Evidência versionada em docs/evidence/fix02 inclui regressão original reprovada, regressões finais, smoke e importação/cena inicial. Erros temporários de indentação/tipagem durante implementação foram corrigidos antes da rodada completa; a rodada final não tem SCRIPT ERROR/Parse Error.

## Build, reprodução e homologação

Novo pacote: EchoesOfAethel-US01-Fix02-Windows-x64.zip; EXE/PCK correspondentes exportados novamente na engine exata. Windows x64, GL Compatibility, viewport 1280x720, template release oficial/PCK externo, sem assinatura. Não é release comercial. GitHub Actions executa todas as suítes e publica artifact Fix02; link, commit final e hashes exatos do CI constam na entrega/PR. Não inserir o hash do próprio ZIP dentro dele por autorreferência.

Extraia o artifact e depois o ZIP interno; execute jogo/EchoesOfAethel-US01-Fix02-Windows-x64.exe mantendo o PCK ao lado. Confira inimigos nos mapas reais e o Fix01 manualmente. O EXE pode manter hash idêntico ao template anterior porque o jogo está no PCK externo; houve nova exportação e o PCK é novo.

Referência técnica: [NavigationAgent3D oficial](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html); get_next_path_position atualiza o agente e navigation_finished também pode ocorrer no último ponto de uma rota inalcançável. Por isso término não é tratado isoladamente como sucesso.

## Limitações e avisos

A regressão IA é headless física, não homologação gráfica nem medição de FPS. Percurso é testado em fixtures representativas, não em todas as combinações de paredes, degraus e ranks dos mapas. Colisores baixos abaixo da altura do raio permitem visão acima deles; a oclusão é a interseção física ao longo do raio, não uma classificação semântica de qualquer objeto próximo. Edição dinâmica arbitrária de navmesh não foi homologada. Massas maiores que três inimigos exigem playtest/desempenho específicos.

Suítes legadas emitiram avisos de 2–6 ObjectDB instances leaked no encerramento; exit 0 e asserts concluídos. Logs mantidos, sem alegação de correção desses avisos. Licenciamento comercial dos assets continua pendente conforme auditoria anterior.

PR #18 Draft, sem merge. Nenhuma nova história. Fix01 manualmente aprovado pelo PO foi preservado e sua regressão repetida; G1/G2 globais e homologação gráfica Fix02 dependem do PO.
