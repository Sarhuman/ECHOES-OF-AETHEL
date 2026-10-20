# Aethel — fundação visual gótica: Sino e Limiar

## Escopo e referência

Branch feat/aethel-gothic-ui sobre a Fase 20.2 (b3ebad8). Referência lida: guia_ui_diablo2.md fornecido pelo autor em Downloads. A diretriz oficial do pedido tem precedência: atmosfera/materialidade como inspiração, arte original e três recursos independentes. O prompt de exemplo ao final do guia não é uma instrução de implementação. Não foram extraídos modelos, imagens ou fontes de outros jogos.

SHA256 do guia consultado: 382bd489c7d25833ff08afb4d2df2a1bc9f42213e9f2325067aacd8edc0cc85f.

Esta entrega prepara e aplica estilos em componentes existentes. Não conclui a arte do HUD, a interface definitiva do inventário, retratos, biblioteca de ícones ou um sistema de diálogos. Não altera combate, raridades, dados de inventário, câmera ou decisões narrativas.

## Fonte dos tokens e tema

src/ui/aethel_ui.gd centraliza tokens e fábricas de StyleBox. assets/ui/aethel_theme.tres é o Theme reutilizável versionado, ligado por gui/theme/custom no project.godot, herdado inclusive por Controls sob CanvasLayer. Regenerar o recurso após modificar o gerador/tokens:

```powershell
& <Godot4.7.2_console.exe> --headless --path . --script res://tools/generate_ui_theme.gd
```

O script deve ser executado após a primeira importação para registrar as classes. Alterações locais em .tres que devam persistir precisam ser incorporadas em AethelUI.create_theme(). Não há segundo inventário ou gerenciador de UI global.

| Papel | Token | Cor |
|---|---|---|
| Carvão / fundo principal | BACKGROUND | #0B0A08 |
| Pedra escura / superfície | SURFACE | #1F1A13 |
| Bronze envelhecido | BRONZE | #3A3226 |
| Latão estrutural | BRASS | #5C4F3C |
| Pergaminho / texto | TEXT | #D3C3A3 |
| Foco de teclado | FOCUS | #F0D999 |
| Ação inválida | INVALID | #ED9385 |
| Vida | LIFE | #8F303B |
| Éter | ETHER | #304E85 |
| Fôlego | STAMINA | #695123 |

As barras têm nomes e valores numéricos; cor não é o único indicador. Os fundos opacos evitam interferência do cenário nos painéis e tooltips. Molduras finas, filetes e ornamentos geométricos originais de sino/portal sugerem pedra e metal; não são texturas finais.

## Convenções de raridade

Os índices persistidos continuam **0 Comum, 1 Mágico, 2 Raro, 3 Épico, 4 Lendário**. Não há nova raridade de conjunto ou único. SET_REFERENCE (#00B400) e UNIQUE_REFERENCE (#B8A058) são referências visuais do guia; o segundo também serve como acento ornamental, não como classificação de loot. Nenhum valor de item/save foi remapeado.

| Índice | Moldura semântica | Texto legível no carvão |
|---|---|---|
| 0 Comum | #D3C3A3 | #D3C3A3 |
| 1 Mágico | #4850B8 | #A3A9FF |
| 2 Raro | #D0C020 | #D0C020 |
| 3 Épico | #A779C6 | #C9A4E4 |
| 4 Lendário | #DE9E54 | #EFBA7A |

Azul semântico exato é reservado à moldura; a variante clara do texto evita baixo contraste. Loot no chão, nomes na mochila e nomes em tooltip compartilham a mesma tabela de texto. O teste exige contraste mínimo 4,5:1 dos cinco textos contra BACKGROUND e do texto principal contra SURFACE. Não se declara certificação geral de acessibilidade ou contraste de todos os objetos 3D.

## Tipografia e espaçamento

Usa-se a fonte padrão distribuída pela Godot e suas licenças já incluídas no projeto. Nenhuma dependência de fonte instalada no Windows. Uma família serifada original/licenciada poderá ser atribuída ao Theme no futuro, após avaliação de acentos e leitura em 720p. Não se simula uma fonte proprietária.

Base do tema: 16 px; nomes/títulos locais: 19 px; tooltips nativos: 14 px; HUD mantém tamanhos compactos preexistentes de 13/14 px e valores numéricos. Sombra preta 1 px horizontal/2 px vertical. Grade de espaçamento de 6 px, margem de painel de 12 px; slots da mochila preservam 48 px e geometria do sistema atual. Respostas têm altura mínima de 40 px e quebra de linha. Não aplicar escala arbitrária no Control raiz: há layouts absolutos na mochila/HUD. Escala global configurável em runtime fica pendente de reflow responsivo; tokens e Theme já permitem configurar tipografia/espaçamento no editor. A expansão do viewport existente cobre 720p e 1080p sem mudar câmera ou zoom.

## Componentes e estados

| Componente | Implementação / uso |
|---|---|
| Botão | Theme para Button, OptionButton e CheckButton: normal pedra; hover bronze; pressionado carvão; desabilitado discreto; foco com contorno dourado de 2 px independente do hover |
| Painel | Panel/PanelContainer/PopupPanel e TooltipPanel; fundos sólidos, borda de latão e margem comum |
| Recursos | AethelHUDManager existente, três barras com sinais independentes; AethelOrnament desenha sino/portal sem bloquear input |
| Slots | AethelUI.style_slot(button, quality) aplicado aos botões já criados por AethelInventoryView; cinco estados, sem duplicar equipar/vender/mover |
| Ícone preparado | scenes/ui/item_icon.tscn, TextureRect com proporção preservada, mouse ignorado e glyph original de portal; atribuir textura autorizada por item no futuro |
| Tooltip | AethelItemTooltip usa o formatador existente, paleta compartilhada, posição limitada ao viewport e âncora do botão quando acessado por foco de teclado |
| Comparação preparada | show_comparison(item, equipped) renderiza os dois itens usando build_text; chamador escolhe o equipado. Não há escolha automática de slot/anel nem cálculo paralelo de atributos |
| Inválido | Inventário emite flash de 160 ms quando o controlador existente rejeita equipamento. Mensagem original preservada; não muda os critérios de validação |
| NPC / diálogo preparado | AethelDialogueView e variantes AethelNPCName, AethelQuest, AethelPortrait, AethelSpeech, AethelDialogue e AethelComparison |

O diálogo é apenas view: present(speaker, line, choices, quest_hint, portrait, interaction_hint). O chamador fornece a tecla de interação para refletir E/F configurado. response_selected(index) comunica a escolha. focus_first_response() dá foco apenas quando o controlador decidir abrir a janela. Não contém estado de missão, gravação de progresso, conteúdo canônico ou substituição de Maera/Doma. O glyph no retrato é placeholder, não uma imagem dos NPCs.

Menus mantêm foco por teclado e ativação padrão. Slots usam foco para mostrar tooltip sem exigir mouse. Botões de habilidades permanecem FOCUS_NONE: F1–F3 já são seus atalhos; isso preserva Espaço para esquiva após clique na barra. O teste reproduz esta proteção. A animação desta fundação limita-se ao feedback discreto de erro; não há pulsação contínua ou atraso que bloqueie ações.

## Preparação para Fases 23–26

Reutilizar os mesmos tokens, variantes, molduras, glyph/icon slot, tooltip/comparação e view de diálogo nas próximas fases. Conectar componentes ao inventário e sistema narrativo existentes, passando dados/signais. Antes de declarar interfaces finais: produzir retratos/ícones licenciados, arte de molduras, layout responsivo, comparação com resolução de slots e fluxo narrativo definitivo. Não se presume que essas próximas fases estejam implementadas por existirem estilos.

## Verificação e limites

Comandos: tools/test.ps1 -GodotExe <engine>; para capturas, configurar AETHEL_CAPTURE_DIR e AETHEL_TEST_SAVE_DIR em pastas de teste e executar tests/capture_gothic_ui.gd com renderização gráfica. A galeria é uma ferramenta de teste, não uma tela do jogo nem um sistema narrativo paralelo.

test_gothic_ui.gd: tema global, cinco estados, contraste, cinco raridades, tooltip por foco, comparação, erro, Enter em resposta, reutilização Maera/Doma e encaixe 1280×720 / 1920×1080. Capturas de componentes, HUD e inventário em docs/evidence/. Suítes anteriores preservadas e executadas; CI executará também o export e smoke Windows existente. Avisos ambientais conhecidos de certificados/cache/configuração do sandbox permanecem visíveis nos logs e não são falhas de parsing.

Validação local com Godot 4.7.2.stable.official.ed1daf0bf: onze suítes exit 0; teste visual final com 33 verificações, integridade com 36, consolidação com 5.105, jogabilidade com 76 e bot 10/10. EXE release exportado e executado no Windows: BUILD SMOKE: 10 checks, 0 failures. Capturas gráficas de componentes e HUD nas duas resoluções e inventário em 720p inspecionadas. Resultados em docs/evidence/gothic-results.json; comandos e logs seguem o pipeline da Fase 20.2. A cobertura automatizada não declara concluída a experiência de navegação do inventário completo ou de diálogos de campanha.
