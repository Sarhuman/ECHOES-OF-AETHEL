# Fase 27 — mundo explorável inicial

## Estado e sequência

Base 431cdb6 / Fase26, Godot 4.7.2.stable.official.ed1daf0bf, Windows Compatibility. Quatro cenas autoradas iniciais, não quinze mapas completos:

`map_01 Vigília ⇄ map_02 Bairro que Faltava ⇄ map_03 Pátio dos Endereços ⇄ map_04 Arquivo das Portas Seladas`.

Acesso inicial exige aceitar explicitamente a investigação provisória de Maera. Os retornos ficam livres. Map_03 é obrigatório conforme WORLD_ATLAS; não existe ligação 02→04. Não implementa o Porteiro, cutscene, Nela/Edrin, duas chaves definitivas ou decisão sobre moradores. O marcador FuturePorteiroEvent reserva a arena para a narrativa futura. As três âncoras narrativas placa/livro/sino permanecem distintas das Âncoras de Travessia.

## Arquivos e autoria

- data/regions.json: IDs, nomes canônicos, ato/tipo, cena, entradas, saídas, condição, âncoras, POIs, pisos, obstáculos, teto de inimigos e referências narrativas. IDs de conectores e pontos de chegada são estáveis.
- scenes/regions/map_01…04.tscn: cenas independentes com região exportada no Inspector. Editar composição nos arrays de dados; executar `--headless --path . --script res://tools/validate_regions.gd` antes de exportar. Não é um editor de mapas independente.
- src/world/region_level.gd: kit geométrico original, colisões e NavigationRegion3D derivados do mesmo layout. MultiMesh para pavimento e paredes repetidas, materiais compartilhados. Uma cena regional ativa por vez.
- src/world/region_manager.gd: subordinado ao hybrid_world existente; coordena região/condições/chegada/segurança/conhecimento, sem duplicar inventário, missões, save ou gerenciador global de cenas.
- src/ui/minimap.gd: desenho sobre células descobertas; M alterna compacto→ampliado→oculto. Legenda identifica jogador, saídas, âncoras e vestígios; marcadores respeitam conhecimento e piso ativo.

Vigília mantém Maera e Doma nas posições anteriores, oficina e triângulo de serviços. Torre do sino, bronze e pedra indicam ocupação. Bairro tem obstáculos urbanos, desvio opcional, baús, vestígio e elite afastada da chegada. Pátio tem eixo principal, marcos postais provisórios e terraço com escadaria visual/colisor contínuo de rampa. Arquivo tem entrada, porta utilizável, corredor, alas, vestígio, recompensa condicionada ao encontro e arena reservada. Geometria ainda é greybox original: não constitui arte final ou ambientação completa.

## Navegação, câmera e segurança

AStar3D calcula rotas determinísticas sobre células 3D da geometria autorada; NavigationRegion3D usa polígonos derivados da mesma superfície para agentes inimigos existentes. O clique mantém a altura do raycast. Rotas inválidas são rejeitadas, diagonais não cortam cantos bloqueados e conexões não saltam desníveis grandes. Player e inimigos usam gravidade/colisões reais. Escadaria usa rampa física contínua sob degraus visuais; não há step solver genérico para qualquer escada importada. Obstáculos dinâmicos/inimigos podem exigir combate ou novo comando; não existe avoidance global avançado.

Regra de zona segura consulta a definição da região de destino. Encontros não são construídos no hub, ataques ofensivos são negados sem gastar Éter e IA não atua ali; defesa/equipamentos/conversa continuam possíveis. Encerrar a transição emite atualização de habilidades para limpar o texto do HUD. Guardas têm ID/limite por região e mortos persistem; sobreviventes são reconstruídos com vida cheia ao retornar. Sem respawn automático. Entrada no Bairro conserva pelo menos 8m até os spawns iniciais. Não existe spawn narrativo aleatório obrigatório.

A câmera mantém projeção ortográfica, yaw45°, pitch35,264°, zoom10–18 e acompanhamento vertical. Raycasts limitados a cada 0,1s tratam oclusão do jogador e inimigos próximos por sólidos com transparência temporária. Paredes frontais são baixas. Isso não garante oclusão perfeita em futuros assets importados, telhados multicamada ou mapas empilhados.

## Exploração, transição e persistência

Fog é conhecimento cartográfico por célula e piso, atualizado apenas ao mudar de célula/piso (sem milhares de raycasts). Não é uma máscara preta de visibilidade no mundo 3D, nem simulação de visão por linha exata. Piso0 e terraço/piso1 usam chaves separadas; marcadores de outro piso não vazam para o minimapa atual. POIs ficam conhecidos por proximidade. Geometria distante e objetivos não descobertos não aparecem no mapa.

Transição valida origem/alcance/linha livre/condição/destino/entrada, bloqueia repetição no mesmo frame, troca uma cena regional, restaura encontros/objetos, posiciona, estabiliza câmera/HUD e usa o save atômico existente. Feedback curto de Travessia respeita redução de movimento; carregamento é síncrono e medido, sem promessa de streaming assíncrono. Evitar adicionar loading complexo sem perfil que justifique.

Save v6 preservado com extensão opcional world_regions: seed, origem, regiões visitadas, células por região/piso, POIs e portas. Saves anteriores sem o campo continuam carregáveis. O flag legado de Bairro limpo migra somente os cinco encontros do map_02, sem marcar Pátio/Arquivo como concluídos. Inventário, equipamentos, stock, missões, usados/mortos, buffs e loot usam os donos anteriores. Posições fora da superfície, dentro de obstáculos conhecidos ou com altura inválida retornam ao spawn seguro da região. Loot legado fora da nova navegação é trazido a ponto seguro quando sua região é carregada, preservando instância/quantidade.

## Correções após análise das capturas

As imagens são capturas reais do viewport Godot, não imagens geradas. A revisão posterior usa a proposta HUD enxuta fornecida pelo usuário: ver HUD_ENXUTA_FASE27.md. O teste de transição exercita a liberação real de F1/F3 e seu custo/dano no Bairro e Arquivo, com retorno ao hub entre saídas. Verifica restrição no hub e ausência de texto seguro no HUD hostil. Retângulos de habilidades e toolbar são comparados em escala85/100/110%. Texto seguro no HUD é abreviado. Rótulos de objetos próximos evitam os retângulos da HUD; os que não cabem são ocultados. Modificadores saíram dos rótulos 3D duplicados e continuam no painel do alvo. Transparência cobre inimigos próximos também. Não presumimos que tudo visível em uma captura prove colisão, save ou performance.

## Validação e limites

Testes de grafo, retornos, desbloqueio, rotas e colisões, rampa/altura/raycast, porta, fog por piso, repetição de load/recompensa, NPCs e combate. A automação gráfica aceita Maera, percorre entradas com movimento real, usa E nas transições/porta, M, F5/F9 e retorna a Doma; inimigos têm colisão/movimento neutralizados apenas nessa fixture para inspecionar caminho/capturas. O bot e regressões exercitam combate real separadamente. Isso não é playtest humano. Playtest humano completo solicitado permanece pendente e deve seguir TESTING.md.

Métricas em docs/evidence/fase27-performance.json e logs das suítes. A medição gráfica é local, 90 frames por região, 1920×1080, AMD RX5802048SP, OpenGL Compatibility e limite60FPS, sem garantia de desempenho em outras máquinas. Greybox e densidade inicial pequenas, sem benchmark de campanha completa. Avisos de certificados/cache/editor do ambiente não são falhas de script; preservar logs para rastreio.


## Medição observada nesta entrega

Após batching das paredes, capturas reais em 1920×1080: mediana por frame de 35,7–36,8ms (aproximadamente27FPS), p95 de40,0–43,1ms e208–267 draw calls conforme a região. A medição inclui a execução no desktop deste ambiente, com IA congelada na fixture; não isola GPU/CPU e não prova60FPS. No protótipo anterior sem batching o p95 observado foi40,6–43,1ms com296–354 draw calls. A variação de tempo não demonstra ganho deFPS consistente; batching reduz submissões sem justificar pooling/streaming. A construção das cenas medida em headless ficou em torno de25–43ms, maior troca observada63ms; revalidar na máquina do jogador. Capturas/regressões não substituem sessão humana de combate e exploração.
