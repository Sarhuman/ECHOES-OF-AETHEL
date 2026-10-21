# Fase 26 — implementação e limites

## Arquitetura

Reutiliza HUDManager, AethelGlobe, Settings, ProgressionManager, inventário, diálogo, pausa e save existentes. Sem EventBus paralelo. Player emite recursos, uso/cooldown, equipamentos e efeitos; progressão emite XP/nível; exploração emite altar; mundo emite troca de alvo/missão. HUD desconecta alvo anterior e não duplica listeners no mesmo mundo. Skills usam cache de apresentação e não atualizam estilos a cada quadro parado.

Vida e Éter usam globos com números atuais/máximos/percentual, shader canvas simples e fallback TextureProgressBar. Fôlego é linear com alerta abaixo do custo de esquiva. Escala 85–110% afeta HUD de recursos e habilidades; não altera grade física do inventário. Animação de preenchimento/nível respeita redução de movimento. Três ícones SVG originais; texturas originais já existentes continuam provisórias.

Alvos comuns, campeões e elites usam dados reais. Apresentação para miniboss/boss tem barra própria e teste com fixture; não cria chefe canônico. Duração de Guarda/altar, recarga, custo, técnica selecionada e XP refletem os proprietários do estado. Badges têm tooltip. Não foram inventadas imunidades ou fórmulas elementais novas.

Diário U apresenta flags reais da investigação provisória de Maera. A missão canônica completa permanece pendente. Pausa reutilizada inclui atributos e opções. Derrota oferece carregar save, novo jogo ou menu; não grava automaticamente nem cria cadáver.

## Áudio e desempenho

Master/Music/SFX/UI/Ambience idempotentes. ConfigFile separado do save persiste volumes, resolução, escala e acessibilidade. Cues sintéticos originais usam cache de WAV, debounce por tipo e máximo de oito vozes; trilhas Music/Ambience finais pendentes. Popups de combate limitados a 32. Regressão mede apresentação parada por 30 frames sem novas atualizações de estilo, listeners únicos e limite de popups. Isto não é benchmark de cem inimigos nem demonstra FPS em outras GPUs; pooling agressivo fica condicionado a perfil real.

## Tooltip e descarte solicitados

A altura do tooltip não depende mais de get_content_height a cada quadro. Área limitada de 340×420, clamped ao viewport, ancora na célula/oferta; scrollbar ignora captura de mouse. Isso elimina o ciclo largura/rolagem/quebra de linha. Texto continua rolável por roda sobre item e PgUp/PgDn.

Largar [Del] transfere a instância completa da mochila para o mesmo sistema de drops no chão; mantém UID, quantidade, atributos e persistência existente. Só remove da bolsa após criar drop; desfaz se remoção falhar. Sem venda ou ouro. Bloqueia morte, UID obsoleto, missão e sale_locked. Equipamento deve voltar à bolsa antes. Arrastar fora mantém cancelamento anterior. Não há destruição permanente nesta ação.

## Compatibilidade e próximas fases

Save v6 preservado. A mochila já tem 10×4 células e itens multicélula desde a base; não foi criada uma segunda grade. Uma expansão futura exige revisar dimensões, posicionamento/transações, validação de saves e layout; deve incluir migração testada de posições inválidas, sem estimar prazo sem escopo. Fase 27 pode fornecer arte, música/ambiente, campanha e chefes sobre os componentes atuais.

## Evidências

19 suítes passaram; nova suíte gráfica verifica HUD em três resoluções e três escalas, hover estável, Delete nativo, diário e pausa. Capturas em docs/evidence/fase26-*.png. Teste backend Fase26: 132 verificações; gráfico: 136 sem capturas / 143 com capturas. Teste gráfico executado com renderizador OpenGL Compatibility e inspecionado visualmente. Playtest humano pendente. Sem merge automático.
