# Fase 20 — estabilização crítica da jogabilidade

## Base e preservação

Branch `fix/fase20-jogabilidade`, descendente de `596d9e6` da consolidação. A pasta original havia sido reorganizada pelo usuário com o ZIP extraído em fonte/jogo/evidencias e deleções na raiz. As correções foram realizadas em worktree isolada, sem restaurar essas deleções nem sobrescrever o pacote anterior. Comparação dos arquivos de fonte/ com o commit: nenhuma divergência de conteúdo. Nenhum avanço para a Fase 23 ou merge automático.

Cena principal: `scenes/main_menu.tscn` → `scenes/main.tscn`. Mundo: `scripts/hybrid_world.gd`; jogador: `scripts/hybrid_player.gd`; câmera: `src/core/follow_camera.gd`; ações: InputMap em project.godot / `src/core/input_actions.gd`; habilidades: `src/skills/skill_tree.gd`; NPCs: `scripts/procedural_npc.gd`; HUD: `src/ui/hud_manager.gd` e composição no mundo.

## Causas identificadas e correções

| Problema | Evidência na versão anterior | Correção no componente existente |
|---|---|---|
| Câmera próxima | Tamanho ortográfico 10, sem zoom configurável | Inicial 12; roda 10–18; interpolação, centro limitado ao mapa e preferência opcional |
| Clique no inimigo vira movimento em direção errada | Seleção por distância fixa de 46 pixels ao centro; cabeça de rank grande fora desse círculo. A falha cai no plano do chão atrás do modelo | Raycast único da câmera; volumes de seleção proporcionais ao visual; corpo/área resolvidos para a entidade. Inimigo tem prioridade sobre loot/chão |
| Piso inválido | Interseção matemática com plano y=0 ignorava obstáculos | Raycast no mundo físico, aceitando somente collider de chão marcado; cliques fora da tela ou sobre obstáculos são rejeitados |
| Aproximação oscilante/ataque em movimento | Comando em velocidade integral até o centro, sem limitar o último passo ao alcance; recuperação não interrompia velocidade | Alvo persistente, comando repetido idempotente, passo limitado à distância restante, orientação antes do golpe, pausa curta na recuperação e máscaras físicas explícitas |
| Ataque parado desvia | Ao segurar Shift+clique a atualização de mira voltava ao chão sob a cabeça do inimigo | Atualização contínua usa a mesma seleção física e orienta ao alvo, sem deslocamento |
| F1/F2/F3 não executam | Teclas apenas selecionavam a habilidade do botão direito; todas começavam bloqueadas | Teclas e botões executam a mesma implementação existente; três técnicas do kit liberadas na slice; right-click continua disponível |
| Falta de feedback das habilidades | Botões cinzentos sem informação de Éter/recarga | Estados Pronto, Ativa, Recarga, Sem Éter, Recuperação e Indisponível; tentativas inválidas sem custo/recarga; guarda com indicador e cancelamento |
| Doma sem representação | Uma CapsuleMesh, sem traje nem ferramenta | Papel blacksmith no visual procedural de NPC existente, com corpo humano, roupa, avental, barba, botas, martelo e nome. Corpo e área de interação separados do visual |
| Excesso de texto no topo | Título técnico, XP, pontos, ouro e linha longa de controles | Topo com região/objetivo; resumo do personagem no rodapé; ajuda recolhida em H; habilidades com contraste |

Não foi encontrado erro de sinal na inversão matemática da câmera: o round-trip de projeção permanece correto. O erro reproduzido estava na seleção em pixels e no destino de chão usado como fallback/mira. A correção não consiste em inverter arbitrariamente um vetor.

## Reprodução antes da correção

Executado `tests/reproduce_manual_report.gd` usando o projeto extraído anterior como res://, em perfil isolado:

```text
REPORT: zoom=10.0 head_click_selects=false
REPORT: F1_damage=0 mana_spent=0
REPORT: Doma_apron=false
```

O teste original de gameplay selecionava o primeiro inimigo mesmo quando sua projeção ficava fora da tela. Foi ajustado para posicionar a câmera/jogador diante de um alvo visível e aguardar registro dos colliders físicos. Selecionar projeções fora da tela não é um controle a preservar.

## Técnicas e regras preservadas

Golpe Pesado: custo 10, dano 1,5×, recarga 1 s. Guarda de Ferro: custo 12, redução de dano 40% por 8 s, recarga 12 s; repetir cancela sem reembolso ou reinício da recarga. Corte do Eco: custo 18, dano 1,25×, raio 3,4, 360°, recarga 4 s. Animação continua sendo apresentação, sem determinar os acertos.

As três técnicas foram disponibilizadas como kit de treinamento da vertical slice para permitir teste imediato dos controles, também ao carregar saves antigos. Os dados de nível/pré-requisitos do componente de progressão foram preservados; isso não homologa o balanceamento final da campanha nem adiciona habilidades novas.

## Testes e evidências

Nove suítes GDScript com exit 0, incluindo `test_playability.gd` com 69 verificações: projeção/raycast em três resoluções e três zooms, cabeça de inimigo rank 2, rejeição de obstáculo, repetição de clique, aproximação, parada no alcance, orientação, ataque parado, F1, F2 ativa/cancela/expira, F3 em área, recursos e cooldowns, movimento interrompido para golpe, E/F/L em Doma, InputMap legado, ajuda, limites e persistência do zoom.

As 5.105 verificações de consolidação continuam passando; bot 10/10 vitórias. A suíte usa input sintético despachado pela árvore para as teclas; não equivale a playtest humano completo.

Capturas locais em OpenGL 3.3 / AMD RX 580: HUD em 1280×720, 1366×768 e 1280×800, Doma, ajuda, guarda ativa, mochila, loja, pausa e opções. Artefatos e logs acompanham o pacote Windows. Mensagens ambientais do sandbox sobre certificados, preferências e cache de shaders estão registradas; não foram ocultadas como se fossem erros de gameplay resolvidos.

## Limites

Nenhum chefe de campanha foi implementado nesta etapa. O relato de clique no chefe foi exercitado sobre o mesmo controlador com rank 2 e volume grande; o campeão do Bairro usa essa mesma lógica. Modelos continuam placeholders; Doma não é arte final. Pathfinding para contornar obstáculos complexos continua ausente. O trabalho estabiliza controles e combate da Fase 20; não amplia inventário, campanhas ou efeitos finais. Playtest humano de aprovação permanece necessário.
