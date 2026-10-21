# Fase 26 — diagnóstico anterior à implementação

21/10/2026. Fetch: main 10980c6 documental; PRs #11/#12/#13 abertos, não mesclados. Base correta: b60ff07 / feat/fase25-exploracao. Fases 23–25 possuem implementação funcional, testes e builds; arte e área hostil permanecem provisórias.

- HUDManager já escuta Vida/Éter/Fôlego; ProgressionManager tem sinais de XP/nível, ainda não conectados diretamente ao HUD. Habilidades/alvo são atualizados a cada frame pelo mundo; estilos são reconstruídos sem mudança.
- AethelGlobe existe, mas está inativo; recursos usam três barras. Texturas próprias de globo e design system gótico disponíveis. Reutilizar componente com shader/fallback.
- Não há EventBus ativo nas fontes integradas; usar sinais nativos dos donos do estado, sem criar barramento global redundante.
- InputMap possui F1/F2/F3, clique, inventário, atributos, pausa e interação E/F. Preservar técnicas e custos. Missões têm flags reais da investigação provisória, sem campanha canônica completa.
- MainMenu/PauseMenu/OptionsPanel e AethelSettings existem; preferências usam ConfigFile separado do save. Volume só Master; AudioManager existente reproduz sons, inclusive placeholders da exploração.
- Efeitos reais: Guarda do Player, altar temporário, DOT e proteção dos inimigos. Apresentar esses estados, sem segundo sistema de status.
- Inventário já é grade configurável 10×4 com largura/altura por definição, instâncias, pilhas e validação espacial. Não migrar nem converter dados. Save atual v6; manter compatibilidade.
- Morte atual encerra ações e permite Novo jogo via R, sem cadáver/equipamento perdido. Acrescentar apresentação e opções sem sobrescrever save automaticamente.
- Dezessete suítes e pipeline Windows 4.7.2 existentes. Guia de dúvidas de arquitetura em Downloads lido como referência; exemplos de pooling, inventário novo ou morte por cadáver não são pedidos desta fase.

Reutilização: HUDManager, AethelGlobe, ProgressionManager, Player, AudioManager, Settings, menus e payload v6. Preparar barra de chefe por categoria para atores reais/futuros, sem inventar chefe canônico. Assets/sons finais e playtest humano continuam pendentes; distinguir automação gráfica de teste humano.
