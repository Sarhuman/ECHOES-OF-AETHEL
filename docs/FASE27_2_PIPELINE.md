# Fase 27.2 — pipeline do Bastião

## Diagnóstico inicial

| Componente | Existe? | Estado inicial | Reutilização / ação |
|---|---|---|---|
| Modelo Bastião | Sim | PLACEHOLDER, procedural_knight.gd | Manter como padrão |
| Materiais | Sim | Cores procedurais, sem texturas finais | Preservar fallback; futuro material autorado |
| Rig | Não no personagem | Pivôs Node3D sem Skeleton3D | Importar no candidato externo |
| Animações | Sim, procedurais | Tweens/oscilação, sem clipes de produção | Preservar; mapear importados |
| Sockets | Parciais | Âncoras do ator, sem rig | Contrato e BoneAttachment no candidato |
| Adaptador visual | Sim | AethelCharacterVisual | Estender, sem novo controlador |
| Equipamentos | Sim | Sete slots e aparências provisórias | Reutilizar AethelEquipmentVisual |
| Fallback | Sim | Cena anterior | Seleção reversível e validação |

Cadeia auditada: #13 feat/fase25-exploracao → feat/fase24-npcs; #14 feat/fase26-hud-eventos → feat/fase25-exploracao; #15 feat/fase27-mundo → feat/fase26-hud-eventos. Todos abertos Draft, não mesclados no momento da auditoria. Esta entrega depende de #15 e deve ser revisada com base feat/fase27-mundo, sem mesclar etapas anteriores automaticamente. Detalhes em FASE27_2_AUDIT.md.

## Importar um candidato

Manter fontes em art/source/bastiao e GLB preparado em art/imported/bastiao; não mover recursos anteriores. Criar wrapper de apresentação e AethelCharacterVisualDefinition com cena de fallback, imported_scene, animation_map e socket_names. A definição de produção bastion_visual.tres tem imported_scene vazio até chegar arte adequada. A definição bastion_fixture_visual.tres é exclusivamente de teste.

Na Godot, importar GLB sem colisões/root motion/câmeras/luzes de autoria externa. O wrapper expõe EquipmentAdapter usando as aparências já existentes. Os materiais autorados podem ser preservados pelo mesmo adaptador, evitando recolorir todo o traje por raridade. Validar após importação:

```powershell
Godot_console.exe --headless --path . --editor --import --quit
Godot_console.exe --headless --path . --script res://tools/validate_character_asset.gd -- res://data/characters/bastion_fixture_visual.tres
```

Substituir o caminho pela definição autorada do candidato real. O CLI retorna erro quando não há candidato ou o contrato falha. Verificar relatório, escala, rig, sockets, nomes/duração/loop dos clipes e orçamento. O validador é estrutural: não comprova qualidade de pesos, qualidade artística, direitos comerciais ou ausência de problemas em todas as poses.

Limites iniciais são configuráveis no Resource, mas não aumentar para ativar um candidato excedente sem aprovação explícita. Documentar violações, otimização proposta e impacto. A contagem conservadora inclui também variantes ocultas de equipamento: não subestima o personagem equipado. Materiais são contados por recursos efetivos nas superfícies/overrides da instância, não por arquivos no disco.

## Seleção e reversibilidade

`aethel/visuals/bastion_mode` nas configurações de desenvolvimento aceita PLACEHOLDER e IMPORTED_MODEL; padrão PLACEHOLDER. A definição de produção precisa de imported_scene aprovado para integração técnica. Sem candidato válido, IMPORTED_MODEL retorna ao fallback e guarda last_validation; não lê caminhos de assets do save ou loot. A fixture só é ativada explicitamente por testes/ferramentas.

`AethelCharacterVisual.select_mode()` troca somente o filho Model, conserva o ator e restaura as aparências equipadas. Não serializa modo no save e não modifica cápsula, transform, navegação, atributos ou recursos. Trocas durante ações mantêm o temporizador visual; autoridade de combate segue no ator. Um candidato inválido não remove o visual anterior antes da validação. Fallback disponível mesmo sem rig.

Não há novo inventário, sistema narrativo ou controlador de combate. F1/F3 mantêm sua chamada de ataque existente; o mapeamento de apresentação identifica cada habilidade pelos sinais existentes. Interação visual é subordinada ao controlador narrativo. Sem eventos de dano em AnimationPlayer.

## Disponibilidade de animações

| Identificador | Ação existente | Personagem padrão | Fixture GLB | Duração fixture | Loop |
|---|---|---|---|---:|---|
| idle | Parado | Procedural | Teste chaveado | 1,20 s | Sim |
| walk | Caminhada | Procedural | Teste chaveado | 0,80 s | Sim |
| run | Locomoção rápida | Procedural | Teste chaveado | 0,50 s | Sim |
| attack_basic | Combo básico 1 | Procedural | Teste chaveado | 0,45 s | Não |
| attack_heavy | Combo básico 2 | Procedural | Teste chaveado | 0,45 s | Não |
| skill_f1 | Golpe pesado | Compartilha ataque | Teste chaveado | 0,45 s | Não |
| skill_f2 | Guarda de Ferro | Block procedural | Teste chaveado | 0,30 s | Não |
| skill_f3 | Eco | Compartilha ataque | Teste chaveado | 0,45 s | Não |
| hit_reaction | Dano recebido | Procedural | Teste chaveado | 0,20 s | Não |
| death | Derrota | Procedural | Teste chaveado | 0,60 s | Não |
| interact | Diálogo existente | Sem animação dedicada | Teste chaveado | 0,40 s | Não |
| block | Bloqueio manual | Pose procedural | Teste chaveado | 0,30 s | Sim |
| dodge | Esquiva existente | Procedural | Teste chaveado | 0,20 s | Não |

Clipes de teste importados e esqueléticos não equivalem a animações artísticas de produção. Nenhum clipe externo final disponível. A fixture tem quatro ossos e tokens, inadequados como rig humano final.

## Equipamentos e sockets

Sete slots anteriores preservados: helmet, chest, gloves, boots, cape, weapon_main, offhand. Fixture oferece tokens ligados ao skin e aparências sword/axe/mace/shield. Não representa malhas modulares acabadas. O personagem padrão conserva suas aparências e limitações anteriores.

SocketMain/SocketOffhand são BoneAttachment em hand_r/hand_l na fixture. SocketName (0;2,4;0), SocketHealth (0;2,15;0), SocketFX (0;1,1;-0,2) e Forward (0;0;-1) ficam no wrapper de teste. Offsets são dados autorados explícitos; produção precisará ajustar contatos reais de empunhadura e articulações. Não há bainha funcional.

## Marcos independentes

Conclusão técnica mínima depende de validações e regressões; integração visual de produção aguarda GLB adequado, rig humano, clipes e materiais reais; conclusão artística aguarda revisão humana. Não promover a fixture a modelo padrão nem declarar Bastião finalizado. Especificação externa completa em art/source/bastiao/PRODUCTION_SPEC.md.
