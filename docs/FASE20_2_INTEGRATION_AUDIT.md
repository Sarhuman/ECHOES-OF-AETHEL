# Fase 20.2 — auditoria de integração

## Referências verificadas em 2026-10-20

Consulta aos PRs pela API GitHub e `git fetch origin`, `git ls-tree -r`, histórico e inspeção do código. Todos os PRs abaixo estavam abertos, Draft e não mesclados.

| Referência | Commit | Conteúdo aproveitável / dependência |
|---|---|---|
| main | 10980c6 | Somente README; nenhum projeto Godot executável |
| #4 feat/fase20-nucleo-arpg | 858b658 | Documentação preparatória; não contém o núcleo completo |
| #5 feat/fase21-character-art-pipeline | ac0ba22 | AethelCharacterVisual, Definition, gerador Blender; depende de #4 |
| #6 feat/fase22-equipment-visual-contract | f66184a | AethelEquipmentVisual seguro por slot/raridade; depende de #5 |
| #7 integration/fase20-arpg-windows | 596d9e6 | ZIP completo original importado em a38a240, adaptadores ligados, menus/save/HUD/build; depende da cadeia #4–6 |
| #8 fix/fase20-jogabilidade | e66f451 | Correções 37e4ae1, regressão de foco b6659cd, evidências e documentação; depende de #7 |

As demais referências remotas de narrativa, ambientes e fundação constam da auditoria anterior `CONSOLIDATION_AUDIT.md`; a narrativa corrente está em `NARRATIVE_BIBLE.md`, `WORLD_ATLAS.md`, `LORE_ATLAS_DO_NUNCA.md` e `data/maps.json`. Mantidos O Direito ao Impossível, Maera Voss, Doma Ferren, quatro atos, 15 mapas planejados e três desfechos. Planejamento não equivale a mapas executáveis.

## Estratégia e base única

Branch `integration/fase20-2-godot`, descendente de e66f451, PR contra main para permitir revisão de uma base completa sem depender de merges automáticos. Os commits anteriores são preservados; não há cherry-pick duplicado nem reimplementação de inventário/combate/visual. PRs empilhados antigos continuam abertos e deverão ser reconciliados pelo mantenedor após revisão.

O diretório local original foi reorganizado pelo usuário em fonte/jogo/evidencias; suas deleções e arquivos não foram restaurados. Checkout dedicado `build-fase20-2` contém um único project.godot na raiz. O ZIP distribui a mesma base sob fonte/ e o export sob jogo/. Não se deve copiar fonte/ para dentro do projeto ativo.

Cena principal: scenes/main_menu.tscn → scenes/main.tscn. Controladores scripts/hybrid_world.gd, hybrid_player.gd e hybrid_enemy.gd. InputMap em project.godot, defaults centralizados em src/core/input_actions.gd. Câmera em src/core/follow_camera.gd; HUD em src/ui/hud_manager.gd; persistência e dados reutilizam os componentes existentes. Paths mantidos para preservar referências.

## Verificação da Fase 20.1

As seis correções estão no código e passaram novamente nos testes: câmera ortográfica 12 com roda 10–18 e preferência; picking físico da cabeça/corpo do rank grande; alvo persistente/limite de alcance; execução real F1/F2/F3, cooldown/Éter; Doma humano com avental/martelo e interação separada; HUD compacto com ajuda H. Os testes não inventam chefe de campanha: usam o rank grande existente.

Não há inversão de sinal comprovada na câmera: a falha anterior era seleção em pixels, com fallback para o chão atrás do alvo. Detalhes/reprodução em FASE20_STABILIZATION.md. Nesta fase a matriz foi ampliada para 1920×1080, mantendo 1280×720, 1366×768 e 1280×800, três níveis de zoom: 76 verificações de jogabilidade.

## Compatibilidade, duplicação e apresentação

Importação Godot 4.7.2.stable.official.ed1daf0bf sem erros de parsing. Novo teste test_project_integrity.gd carrega cenas/Resources e rejeita class_name duplicado: 31 verificações. Não foram necessárias supressões genéricas. Não há segundo controlador ativo para os sistemas consolidados; diablo_globe.gd é componente legado inativo, não uma segunda HUD instanciada. Scripts de reprodução/teste não são gameplay paralelo e ficam fora do export.

Visual: AethelCharacterVisual/Definition e AethelEquipmentVisual ligados ao Bastião; modelo visual e slots separados do CharacterBody3D, atributos e regras de ataque. As variantes existentes são registradas por identificador; caminhos externos arbitrários são rejeitados, com cobertura em test_consolidation. Sockets de rig final permanecem dependentes dos assets finais. Não foi substituída arquitetura 3D por 2D.

Mantida câmera yaw 45°, pitch -35,264°, com suavização e limites. Capturas gráficas em quatro resoluções, incluindo docs/evidence/hud-1920x1080.png, inspecionadas em OpenGL 3.3 / AMD RX 580. Sombras e materiais continuam procedurais.

## Pipeline e validação

Engine oficial fixada por versão/commit e SHA512 do ZIP publicado pela Godot; template Windows release oficial validado por CRC e SHA256 fixado. tools/build_windows.ps1 recusa engine/template divergente. Download da entrada parcial evita baixar templates de outras plataformas. Procedência registrada no pacote.

tools/test.ps1 executa dez suítes isoladas: integridade do projeto, itens, combate, gameplay, UI, RPG, HUD, consolidação, jogabilidade e bot. A consolidação cobre 5.105 verificações, inclusive equipamentos, save v2/v3/v4/backup, troca de cena, menus e pausa. Bot com 10/10 vitórias. Resultados e comandos em relatorios-fase20/results.json e logs *-final.log.

Novo smoke de export executa o EXE Windows, não o editor: menu, HUD, câmera, movimento, picking grande, ataque após aproximação, F1–F3, interação de Doma e pausa. Dez condições verificadas, perfil isolado, fechamento/código de saída e marcador final obrigatórios. O script PowerShell aguarda explicitamente o processo GUI antes de ler o log e impõe timeout. Exportação e execução local Windows são evidências distintas. O workflow agora também roda este smoke em windows-latest antes de empacotar.

Artefato versão 0.20.2: EchoesOfAethel-PreAlpha-Windows-x64.zip, com EXE/PCK, licenças, fonte, evidências e manifesto de hashes. Nenhuma release estável automática. CI desta branch deve ser registrado após execução; sucesso anterior não substitui validação desta alteração.

## Limites e pendências

Não há bloqueador de parsing ou regressão automatizada conhecida na base. Ainda dependem de produção: modelos/rigs/animações/áudio finais; navmesh; outras quatro classes; map_04 e campanha completa. map_01/map_02 compartilham geometria de teste. Kit das três técnicas liberado para teste, não balanceamento definitivo. Playtest humano completo e outras máquinas continuam necessários.

O sandbox local registra falha no repositório de certificados e em gravação de configurações/cache de shaders da engine fora da workspace. Esses avisos não foram suprimidos nem classificados como erros GDScript. Execução gráfica e smoke concluíram; logs preservam a distinção.
