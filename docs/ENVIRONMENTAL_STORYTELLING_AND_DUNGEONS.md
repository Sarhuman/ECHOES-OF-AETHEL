# Direção de arte e narrativa ambiental — Fase de consolidação

> **Estado:** especificação de design, não funcionalidades implementadas. Escopo canônico: 15 mapas, dos quais `map_04`, `map_08` e `map_15` são as três dungeons. Godot alvo informada: 4.7.2. Nenhuma homologação de runtime inferida deste documento.

## Princípios de experiência

1. **Silhueta e material identificáveis:** o jogador deve reconhecer a zona sem depender do texto do HUD.
2. **Legibilidade antes da decoração:** paredes, colisões, telegráficos de combate e saídas devem ser discerníveis à escala da câmera.
3. **Causa e consequência observáveis:** decisões mudam NPCs, arquitetura, serviços e caminhos, com estado salvo.
4. **Economia de produção:** kit modular de geometria para reutilização, mas composição única por mapa; LOD e texturas otimizadas antes de povoar uma cena.
5. **Persistência determinística:** variações do mundo partem de flags persistidas, nunca de sorteio ao carregar uma área crítica.

## Paleta de regiões

| Zona | Material dominante | Cor de referência | Som/ambiente | Marco de navegação |
|---|---|---|---|---|
| `map_01` Vigília | basalto, bronze escurecido, vitrais | âmbar e azul frio | sinos incompletos, vento nas telhas | torre de treze badaladas |
| `map_02` Bairro que Faltava | pedra duplicada, reboco de duas épocas | violeta discreto + luz doméstica | cartas e passos em quartos vazios | rua que bifurca no mesmo endereço |
| `map_03` Pátio dos Endereços | calçamento marcado, marcos de latão | azul e cobre | metal arrastado | bússola inscrita no pátio |
| `map_04` Arquivo | estantes de pedra, papel e ferro | ouro empoeirado + sombras profundas | folhas, fechaduras e sino rachado | grande porta numerada |
| `map_05` Estrada dos Retornos | cascalho, sinais de rota contraditórios | cinza frio e púrpura | rodas de carroças ausentes | marco de quilometragem impossível |
| `map_08` Porão da Travessia Nula | madeira úmida, metal, sal translúcido | turquesa pálido + âmbar | estalos de casco | quilha do navio suspenso |
| `map_15` Atlas do Nunca | pedra suspensa, pergaminho e vazio | violeta espectral e prata | ressonância de páginas | mesa central do Atlas |

## Dungeon 1 — map_04 / Arquivo das Portas Seladas

**Fantasia:** uma repartição monumental erguida para registrar possibilidades não escolhidas. Não é uma catacumba genérica.

**Layout crítico:** entrada → salão de triagem → duas alas de chaves (ordem livre) → arquivo de registros → checkpoint → câmara do Porteiro → saída. Uma passagem opcional oferece um registro sobre Nela, sem bloquear progressão.

**Asset kit:** arquivadores de pedra (3 larguras), estantes derrubadas (2), pilhas de papel (3), fechaduras de bronze (2), correntes, mesas, folhas isoladas. Decoração não bloqueia o corredor crítico; somente colisões autoradas.

**Atmosfera:** `GPUParticles3D` de poeira de baixa densidade, feixes de luz quente estacionários e partículas de papel apenas em momentos narrativos. Partículas sem colisão relevante para gameplay.

**Chefe — Porteiro das Portas Seladas:** três ataques telegráficos: arco frontal, selo de área no chão e fechar/abrir temporariamente uma porta lateral; segunda fase intensifica combinações sem tornar saídas impossíveis. Registrar resultado da decisão `act1_district_fate` em `welcome` ou `seal`.

**Aceitação:** o jogador identifica os dois objetivos por pistas visuais, reconhece os telegráficos e alcança o checkpoint sem bloqueios de colisão.

## Dungeon 2 — map_08 / Porão da Travessia Nula

**Fantasia:** o interior de um navio que nunca partiu, agora preso em um dique subterrâneo.

**Layout:** rampa → convés inferior → compartimentos de sal (caminho aberto por cristais) → estação de bombeamento/checkpoint → câmara da Almirante → regresso.

**Materiais e efeitos:** madeira encharcada, metal oxidado, água rasa com reflexos economicamente controlados, cristais de sal translúcidos. Cristais destrutíveis usam `StaticBody3D` ou `Area3D`, HP definido e estados `intact` / `broken`; nunca dependem exclusivamente de simulação física cara.

**Chefe — Almirante Sem Travessia:** investida em linha, comando de maré que preenche faixas claramente sinalizadas, convocação de ecos de tripulação. A quebra voluntária de cristais abre espaços de segurança.

**Aceitação:** cristais quebram ao receber dano válido, bloqueio/navegação recalculados ou rotas pré-configuradas, efeito audiovisual claro, retorno seguro e decisão `act2_manifest_fate` persistida.

## Dungeon 3 — map_15 / Atlas do Nunca

**Fantasia:** cartografia de realidades não vividas flutuando abaixo e acima de uma estrutura fragmentada.

**Layout:** entrada → três câmaras que refletem consequências dos atos I–III → anel de plataformas estáveis → checkpoint → arena Cartógrafo sem Norte → epílogo.

**Visual:** planos e cenários distantes em `SubViewport` ou malhas simples com materiais emissivos; geometria falsa em profundidade para evitar custo de renderizar múltiplos mundos completos. Fendas são distinguíveis dos pisos transitáveis. `Decal` para inscrições, quando suportado pelo renderer e pela superfície.

**Chefe — Cartógrafo sem Norte:** padrões derivados das três decisões anteriores alteram **variação de combate**, não a possibilidade de vitória. Oferecer três finais: `single_line`, `porous_world`, `open_atlas`; requisito de conclusão explícito na UI.

**Aceitação:** indicação de solo seguro inequívoca, todos os finais alcançáveis pelas condições documentadas, transição sem perder o save.

## NPCs e reatividade

**Doma Ferren — map_01:** três estados de oficina:
- `intact`: forja ativa, mercadorias regulares;
- `strained`: itens reparados, bancada parcialmente vazia, comentário sobre uma ferramenta de um filho que não existiu;
- `ruined`: telhado destruído e serviço limitado, mas o jogador ainda tem alternativa para reparar itens.
O estado deriva de flags persistidas e de uma tabela explícita de decisões, não de carga aleatória.

**Sive — map_10–12:** dois figurinos `vigil_childhood` e `survivor`. A escolha narrativa e a progressão de quest decidem a aparência. Pode haver um efeito *curto e deliberado* de sobreposição visual ao encontrar um Eco, sem sorteio no carregamento nem reversão arbitrária da escolha.

**Maera:** falas com condições de `act1_district_fate` e `act2_manifest_fate`, evitando repetir o mesmo diálogo após mudanças do mundo.

## Técnicas Godot

- **Arquitetura:** mapa individual `Node3D`, subcenas de cenário, `StaticBody3D` para colisões, `NavigationRegion3D` e `NavigationAgent3D` com malha validada.
- **Decais:** nó nativo `Decal` (não `Decal3D`); verificar materiais, profundidade, orçamento de decal e renderizador.
- **Iluminação:** `DirectionalLight3D` frio de baixo contraste; tochas `OmniLight3D` quentes, sombras limitadas por orçamento e agrupadas por importância.
- **Poeira:** `GPUParticles3D` com quantidade limitada; alternativa `CPUParticles3D` se necessário.
- **Névoa:** `WorldEnvironment` e `Environment` com testes de legibilidade; efeitos volumétricos apenas após medir FPS.
- **Mapas repetíveis:** kits modulares, materiais e instâncias; não usar modelos Meshy brutos de alta contagem de polígonos como repetição ilimitada.

## Vertical slice prioritária

| Ordem | Região | Resultado mínimo verificável |
|---|---|---|
| 1 | `map_01` Vigília | hub próprio, dois NPCs reconhecíveis, uma loja e diálogo condicional |
| 2 | `map_02` Bairro que Faltava | rota navegável, cinco Rasuras, loot coletável com inventário visível |
| 3 | `map_04` Arquivo das Portas Seladas | dungeon com duas chaves, checkpoint, chefe e escolha persistida |

**Gate de qualidade:** editor Godot 4.7.2 abre sem erros de parser; cena abre; HUD Vida/Éter/Fôlego visível; inventário abre e mostra item recebido; save/load preserva inventário, flags e posição válida; sem paredes atravessáveis nem drops perdidos quando bolsa está cheia. Só então criar as regiões restantes.

## Testes necessários

1. Teste unitário de mapeamento de flags de diálogos/visual.
2. Teste de save/load para cada escolha com versionamento.
3. Teste de dano e cristais destrutíveis sem duplicar loot/XP.
4. Teste de navegação em cada transição com e sem obstáculos destruídos.
5. Playtest visual em 1280×720 e 1920×1080; verificar contraste e interface.

## Não incluído nesta especificação

Nenhuma cena `.tscn`, modelo 3D final, shader, animação ou dungeon executável foi criada neste documento. Os detalhes são requisitos de produção, não comprovação de implementação.
