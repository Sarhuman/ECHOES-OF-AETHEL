# Fase 25 — exploração, risco e recompensa

## Base e integração

Branch feat/fase25-exploracao, sobre f162147 / PR Draft #12 (Fase 24), dependente do PR #11 e anteriores, sem merge automático. Auditoria anterior ao código: FASE25_AUDIT.md. Versão 0.25.0 / Godot 4.7.2 / Windows x64.

AethelLootGenerator continua sendo o gerador; AethelDroppedItem, o objeto de chão; InventoryManager e cinto, os destinos reais. HybridEnemy mantém combate e XP. AethelExploration coordena dados/encontros/objetos e acrescenta seu estado ao mesmo save do HybridWorld; não há inventário, atributos, economia ou arquivo de save paralelo.

## Dados e taxas provisórias

`data/loot_tables.json` configura pesos de raridade [55,27,12,5,1], ajuste por rank/magic find, tentativas, chance de recompensa, mínimos, ouro e categorias. **Valores experimentais para testes, não balanceamento definitivo.** Normal: 1 tentativa a 55%; campeão: 2 a 75% e 1 equipamento garantido no mínimo mágico; elite: 4 a 75% e 3 equipamentos no mínimo mágicos. Contêiner comum: 2 a 80%; baú especial: 3 a 100% e 1 equipamento no mínimo raro. Distribuição de categorias e materiais está inteiramente no JSON.

As cinco qualidades permanecem Comum/Mágico/Raro/Épico/Lendário. Cores e tooltips reutilizam AethelUI e ItemTooltip; afixos continuam no catálogo existente: mágico 1–2, raro 3–4, épico 4, lendário 5, sujeitos à elegibilidade e limite de atributos distintos. Definições nomeadas legadas continuam carregáveis, mas esta geração não transforma qualidade lendária em classificação Única; conjuntos/novos únicos seguem reservados.

O contexto de recompensa aceita ID, nível, rank, região, dificuldade, tabela, magic find e multiplicador de ouro. Somente mapas existentes e dificuldade experimental cadastrada são aceitos. Fontes estáveis têm semente própria derivada do ID; itens recebem IDs reproduzíveis dentro do resultado. Testes podem usar set_seed. Não há sorteio de objetos narrativos: precisam de futura tabela e autorização explícita, sem inserir itens de missão aleatoriamente.

## Encontros e modificadores

`data/exploration.json`: um comum, um campeão e uma elite com dois lacaios, cinco inimigos no total, preservando o objetivo provisório da Fase 24. Configura ID de grupo/membro, tipo permitido (Rasura), posições, rank, nível, condição de missão, tabela e multiplicador de recompensa. Lacaios têm vínculo de líder e recompensas próprias; não há invocação ilimitada. Grupos de missão/mini-chefe podem usar o mesmo contrato de membros, nome fixo, rank e condição, mas não foram acrescentados chefes canônicos.

Modificadores originais: Punho de Cinza (dano ×1,2), Pele de Ardósia (defesa ×1,5), Passo Partido (velocidade ×1,2), Ferida de Eco (2 de dano periódico a cada 2s num raio de 2,8) e Vigília de Ferro (protege aliados próximos por 2s a cada 6s, reduzindo dano em 20%). Regras ficam nos dados, nomes são apresentados no mundo. Nenhum aumenta permanentemente o Player. Perfis de vida do encontro são experimentais e moderados; bot de combate existente continua sendo uma regressão obrigatória.

## Loot e filtro

Coleta valida objeto vivo pertencente ao mundo, região, alcance e linha livre; só remove após inventário/cinto confirmar inserção, ou após creditar ouro. Sem espaço, permanece no chão. Clique aproxima; movimento manual/combate/caminho bloqueado cancela a coleta. E/F coleta perto. Há área de interação por drop, cor/emissão e anel discreto para raro ou superior.

Nomes aparecem temporariamente por quatro segundos; Alt os mantém. Mágicos ou melhores/ouro preservam indicação padrão existente. Rótulos são separados em tela, limitados à área entre cabeçalho e HUD; se não houver espaço visual, algum nome pode ser omitido temporariamente sem ocultar/destruir o item. Painéis ficam à frente. `O` abre filtro para cinco qualidades, ouro, consumíveis e materiais; filtros são preferências salvas no ConfigFile existente. Filtro controla apresentação/seleção, não existência. Pode ser reativado a qualquer momento.

Feedback usa pequenos textos, emissão e toques sintéticos originais de aproximadamente 100 ms, com limite de frequência e volume discreto. Sons de queda/coleta/morte/elite/contêiner/altar/poço/travessia são placeholders; não há partículas pesadas nem áudio de terceiros.

## Objetos e travessia

Componente único cobre baú, barril, urna, restos abandonados e túmulo. Áreas de seleção não bloqueiam o movimento. Contêineres concedem loot no chão, registram consumo antes da publicação, mudam indicação e têm movimento discreto. Baú especial exige derrotar toda a elite com lacaios e tem tabela diferenciada.

Altar de Ardósia: um uso por save, 30 segundos de resistência de 20%, duração visível. Integra a mitigação do Player e expira sem mudar permanentemente atributos. A Guarda existente continua separada e combina multiplicativamente. Poço: dois usos por save, restaura 50% da Vida, 50% do Éter e 100% do Fôlego, limitados aos máximos. Não há recarga automática escondida.

Âncoras de Travessia em Vigília e no mapa 02: descobrir por interação, destinos somente descobertos, validar origem/alcance/linha/quest e viajar nas cenas existentes. A janela permite teclado/mouse; Esc fecha antes da pausa. São dispositivos de teste, **não** as três âncoras narrativas de Uma Porta para Ninguém. Não há outros mapas criados.

## Persistência e respawn

Save v6 acrescenta contêineres/usos, IDs mortos, âncoras, efeito com tempo restante e todo loot pendente com IDs, região, posição e item/ouro. Junto a inventário, equipamentos, ouro, progresso e narrativa, no arquivo atômico/backup existente. Coletados deixam de integrar a lista de chão, impedindo reaparecimento no load. Repetir load limpa os objetos antigos antes de restaurar, sem somar cópias. IDs de itens do chão não podem repetir itens possuídos ou estoque.

Inimigos mortos permanecem eliminados ao reentrar, carregar e reiniciar o aplicativo usando esse save. Sobreviventes são recriados com vida cheia; posição/HP, ataques, proteção de elite, aggro e DOT são temporários. Buff do altar conserva segundos restantes de jogo; tempo offline não conta. Fontes e buff não recebem uso/duração extra ao carregar. Novo jogo reinicia mundo; não há reset de instância ou farming automático. Missão/recompensa única da Fase 24 permanece inalterada.

Versões 1–5 migram; região anteriormente limpa permanece limpa, sem entregar recompensas retroativas. Falta de IDs de mortes parciais em saves antigos não permite reconstruir quais inimigos morreram. Dados inválidos são recusados e o backup existente é tentado.

## Verificação e limites

Resultados em docs/evidence/fase25-results.json, logs no pacote e roteiro em TESTING.md. Testes exercitam serviços reais, falhas transacionais, geração reproduzível, todos os modificadores, elite/lacaios, fontes únicas, efeito/poço/travessia, persistência e regressões. GUI usa eventos de entrada automatizados e capturas reais OpenGL em 720p/1080p. Encontros congelados e derrotas por chamada de dano são fixtures da inspeção gráfica; combate real é exercitado pelo bot e testes de combate. **Playtest humano completo não foi realizado.**

A região hostil ainda compartilha a geometria de Vigília como fatia provisória. Mapas definitivos, novos tipos de monstros, mini-chefes canônicos, navegação com desvio de obstáculos, assets/sons finais, dungeons adicionais, convocadores, reinício de instância e playtest humano permanecem pendentes. Não declarar esses sistemas prontos ou a campanha concluída. Avisos ambientais de certificados/cache/editor são registrados e distinguidos de erros críticos de GDScript.


### Resultado executado

Dezessete suítes locais aprovadas: Fase 25 com 713 verificações; GUI final com 134 em headless e 140 em OpenGL/AMD RX 580 (incluindo seis capturas gravadas). Regressões Fase 24 59 + GUI 20, Fase 23 103 + GUI 19, fundação gótica 33, integridade 40, consolidação 5.117, jogabilidade 77, itens/combate/gameplay/UI/RPG/HUD e bot 10/10. O EXE exportado passou em 21 verificações de inicialização, combate, comércio e exploração/persistência.

Foram corrigidos: coleta antiga feita de longe no fixture da Fase 23 (agora aproxima o jogador), prioridade de E/F para objeto ambiental próximo antes de um objeto distante sob o cursor, coordenadas de mouse dos testes na escala 150% e conferência de um objeto já liberado no próprio teste GUI. A proteção real dos lacaios também exigiu que a fixture gráfica aplicasse dano suficiente, sem alterar a mitigação do jogo. Sem relaxar as verificações de transação ou combate.
