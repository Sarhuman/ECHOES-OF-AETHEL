# HUD enxuta — referência integrada

Referências fornecidas em21/10/2026: hud-enxuta-echoes-of-aethel.xlsx (abas Mudanças da HUD e Checklist Codex) e hud_enxuta_layout_proposto_1280x720.html. Lidas como proposta de apresentação, sem executar scripts do HTML ou alterar a planilha. Instruções internas para preencher checklist não foram tratadas como autorização para editar o arquivo original.

A direção mais recente substitui a apresentação em globos por três barras (Vida/Éter/Fôlego) e XP no painel superior esquerdo. O componente AethelGlobe continua reutilizável e testado isoladamente, sem HUD paralelo ativo. Shader/fallback dos globos não altera as barras novas.

Nome/nível/ouro e XP usam os mesmos dados/sinais. Missão mostra somente um objetivo real da investigação provisória e contador; diário U conserva detalhes. Nome da região/piso aparece no cabeçalho do minimapa; legenda só no expandido M. I/C/U/H/Esc são botões compactos com tooltip e atalhos existentes. Barra inferior única reúne poções clicáveis1–4, três técnicas e um proxy M2 para a técnica selecionada, com custo de Éter real. M2 não introduz quarta habilidade. Espaço não é capturado pelos botões.

Mensagens de Travessia permanecem três segundos no topo central. Filtro de loot só aparece com drops da região atual. Rótulos por proximidade usam linha livre e não cobrem os retângulos da HUD; nomes de loot continuam com Alt. Removidos os textos soltos inferiores e título/dicas redundantes; controles extensos permanecem em H. Âncoras relativas à viewport e offsets de dimensões/margens lógicas mantêm layout no stretch canvas_items, com escala configurável85/100/110%.

Validação automatizada usa cliques reais nos menus/poção, atalhos, comparação de retângulos e capturas de Vigília/Bairro/Pátio/Arquivo em1280×720 e1920×1080. Isso prova os caminhos testados, sem substituir playtest humano ou edição visual de novos assets. Planilha original e seu status permanecem intactos. Combate, stamina, payload de save e lógica de missão não foram alterados por essa revisão da HUD.
