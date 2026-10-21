# Fase 24 — NPCs, diálogos e comércio

## Integração

Base: PR #11 (Fase 23), sobre PRs #10/#9, ainda não mesclados. Auditoria anterior à implementação: FASE24_AUDIT.md. Um único inventário, equipamento do jogador, ouro do mundo e arquivo de save continuam responsáveis pelas transações. AethelNPCController coordena interação e narrativa, sem cópias desses sistemas.

`data/npcs.json` define IDs, funções canônicas, categorias combináveis, disponibilidade, visual/animações existentes, diálogo, comerciante, indicador e retratos. Doma e Maera estão instanciados. Teren, Sive e Iro têm contratos preparados; presença, animações e conversas definitivas aguardam as respectivas cenas. Teren continua sineiro sem voz.

`data/dialogues.json` define nós/respostas/condições/efeitos/próximo/encerramento. Condições reconhecidas: região, flags de missão existentes, recompensa, classe, ato, atributo, posse de item (mochila ou equipamento), escolha, serviço, corrupção mínima e estado do hub. O ato efetivo desta fatia é I; não há campanha completa escondida. Condições desconhecidas falham. Efeitos permitidos: abrir loja Doma, registrar a escolha cadastrada da oficina, iniciar e entregar investigação Maera. Não se executam scripts, caminhos ou métodos arbitrários fornecidos pelos dados. Novos efeitos exigem código e revisão explícitos.

AethelDialogueView existente apresenta texto e botões com foco, retrato e encerramento. Setas/Tab/Enter selecionam; Esc encerra antes de abrir pausa. O personagem não caminha ou esquiva enquanto conversa ou usa a loja; dano interrompe a conversa. Estado transitório de janela/posição no diálogo não é restaurado; escolhas e nós já vistos são.

## Interação e oficina

Raycast da câmera inclui NPCs, terreno, paredes e inimigos; a primeira colisão impede seleção através de cenário. Inimigo mantém prioridade no comando de ataque. Clique no NPC inicia aproximação pelo comando de movimento existente, para dentro de 2,6 unidades, orienta o jogador e abre diálogo. E/F funciona perto ou apontando para NPC distante. Chão, combate, movimento manual e Esc cancelam aproximação. Caminho bloqueado/sem progresso cancela com mensagem, sem teleporte. **Não há navegação com desvio automático de obstáculos**: reposicione pelo caminho livre.

Oficina de Doma: bigorna, fornalha iluminada, bancada/ferramentas e armas expostas; sólidos ficam atrás dele, preservando acesso pela praça. Luvas, avental, costuras, proteção de ferro e martelo distinguem a silhueta. Geometria e retratos SVG foram compostos originalmente neste projeto e são **provisórios**, sem assets de outros jogos. Substituição por modelos/animações/retratos finais permanece pendente.

Retratos usam IDs simbólicos em whitelist de preloads, com expressão → estado narrativo → ato → padrão → fallback. Doma/Maera possuem ilustrações vetoriais provisórias; demais personagens usam o portal autoral. Variantes artísticas de expressão/ato ainda não foram produzidas.

## Comércio

`data/merchants.json` usa o catálogo da Fase 23: espada, machado, escudo, armadura, luvas, botas e três materiais. Nove instâncias normais fixas, sem rolagem ou reposição automática. Preço de equipamento/material = valor unitário × multiplicador configurado × quantidade; venda = máximo(1, valor unitário/4 truncado) × quantidade. Poções básicas têm suprimento ilimitado, preço de catálogo e nível mínimo 4 para hp_medium. Materiais não habilitam forja.

Validações ocorrem antes de entregar/debitar: loja aberta, NPC/serviço disponível, alcance, linha de visão, instância ainda no estoque, ouro e capacidade. Inventário existente planeja inserção atomicamente. Poções usam o plano de cinto/mochila existente. Venda verifica propriedade da instância na mochila; objetos `kind=quest` e definições `sale_locked` são protegidos. Equipamento vestido precisa ser retirado antes de vender. Compra pode adquirir item cujos requisitos não são atendidos: comparação informa requisitos, e equipamento continua bloqueado pelo Player. Compra não exige poder vestir imediatamente.

Estoque remanescente, ouro e itens são salvos juntos; IDs preservados. Transações confirmadas antes do último F5 são recuperadas, como no restante do jogo; não há autosave independente ou diário financeiro paralelo.

## Missão e compatibilidade

O cânone de Uma Porta para Ninguém exige três âncoras e decisão no mapa 04, ausentes nesta fatia. O ciclo implementado é **investigação provisória de teste**: aceitar explicitamente com Maera → atravessar portal → derrotar cinco Rasuras reais → voltar → relatar a Maera → receber 60 ouro uma vez. Retorno pelo portal sozinho não conclui mais a missão. Interface e fala deixam explícito que não se trata do desfecho canônico.

Save v5 acrescenta narrativa e estoque ao payload atômico com backup existente. Versões 1–4 são aceitas; estoque inicial só é criado quando ausente, nunca ao carregar uma loja esgotada. Conclusão legada é considerada já recompensada, sem conceder ouro retroativo. Dados desconhecidos/malformados são rejeitados e o backup existente é tentado. Escolhas, nós visitados, estado de NPC, disponibilidade da loja e recompensa persistem. Corrupção/hub possuem condições e estado preparado, sem degradação ambiental implementada.

## Verificação e limites

Resultados finais e roteiro em TESTING.md e docs/evidence/fase24-results.json. A inspeção gráfica usa eventos de entrada automatizados e capturas reais OpenGL, em 1280×720 e 1920×1080. **Playtest humano interativo completo não foi realizado**; o roteiro é entregue para o usuário. Não confundir testes automatizados com esse requisito humano.

Permanecem pendentes: assets finais, expressões/retratos por ato, navegação de contorno, cenas dos demais NPCs, três âncoras/decisão canônica e playtest humano. Sem forja avançada, novos sistemas de inventário, campanha dos atos posteriores ou degradação integral do hub. Avisos do ambiente sobre certificados/cache/editor são registrados; falhas críticas de GDScript tornam os testes inválidos.


### Resultados desta entrega

Quinze suítes locais exit 0: Fase 24 59 verificações, GUI 20 em headless; Fase 23 103 + GUI 19; fundação gótica 33; integridade 39; consolidação 5.117; jogabilidade 77; bot 10/10, além de itens/combate/gameplay/UI/RPG/HUD. Execução gráfica OpenGL/AMD RX 580: GUI 26 verificações, incluindo seis capturas gravadas e inspecionadas. Export Windows oficial executado: BUILD SMOKE 15 verificações, zero falhas, incluindo leitura de dados NPC/diálogo exportados, compra real e save/load de saldo/instância/estoque.

O preset inclui explicitamente `data/*.json`; testes/docs/ferramentas continuam fora do PCK. A fonte e esses testes acompanham o ZIP. O smoke do EXE usa somente perfil isolado de teste e não escreve no save do usuário.
