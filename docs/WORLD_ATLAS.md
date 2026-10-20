# Atlas de mundo — 15 mapas canônicos

**Escopo fechado:** 15 mapas distintos, sendo 12 áreas não-dungeon (incluindo 3 hubs) e 3 dungeons. Quatro atos. Cada dungeon possui chefe, checkpoint, retorno e uma decisão persistente. Um chefe de superfície encerra o Ato III.

| ID | Região | Ato | Tipo | Identidade | NPCs / ameaças | Função |
|---|---|---|---|---|---|---|
| 01 | Vigília — Praça dos Sinos | I | hub | Cidade sobreposta a endereços impossíveis | Maera Voss; Teren Hal; Doma Ferreiro | Introdução, comércio e escolhas persistentes |
| 02 | Bairro que Faltava | I | exterior | Casas de duas épocas ocupam a mesma rua | Nela, arquivista; Rasuras | Três âncoras e caminhos alternativos |
| 03 | Pátio dos Endereços | I | exterior | Cartas sem destinatário marcam as rotas | Edrin, carteiro; Vigias do Mapa | Emboscadas e mapa parcial |
| 04 | Arquivo das Portas Seladas | I | dungeon | Corredores mudam conforme placas encontradas | Porteiro das Portas Seladas | Chefe do Ato I; decisão sobre moradores |
| 05 | Estrada dos Retornos | II | exterior | Caravanas regressam de viagens nunca feitas | Olan, condutor; Coletores | Rastreamento de mercadorias e atalhos |
| 06 | Cais de Sal | II | hub | Porto de navios impossíveis e maré cristalina | Lira Ancorista; Iven Mercador | Comércio, investigação e contratos |
| 07 | Estaleiro de Vidro | II | exterior | Cascos transparentes exibem tripulações alternativas | Neris, mergulhadora; Vigias | Pontes móveis e armadilhas |
| 08 | Porão da Travessia Nula | II | dungeon | Navio preso dentro de um dique subterrâneo | Almirante Sem Travessia | Chefe do Ato II; arquivo de rotas |
| 09 | Várzea das Promessas | III | exterior | Colheitas de estações incompatíveis | Alda, botânica; Testemunhas Partidas | Efeitos ambientais e coleta |
| 10 | Jardim de Cobre | III | hub | Árvores ressoam vozes de gerações possíveis | Sive; Teren Hal | Escolha de Sive e serviços mutáveis |
| 11 | Pomar dos Nomes | III | exterior | Frutos gravados com nomes de pessoas ausentes | Isha, guardiã; Não-Nascidos | Diálogos ramificados e combate |
| 12 | Estufa das Causas | III | exterior | Máquinas vegetais mantêm destinos artificiais | Jardineiro das Causas | Chefe do Ato III e mudança de arena |
| 13 | Fenda dos Registros | IV | exterior | Geometria partida entre versões de Aethel | Maera; Conclave | Revisita consequências dos atos |
| 14 | Observatório da Linha Única | IV | exterior | Lentes gigantes selecionam realidades | Iro Sen; Conclave | Confronto ideológico e guardas elites |
| 15 | Atlas do Nunca | IV | dungeon | Mapas vivos reconfiguram salas e saídas | Cartógrafo sem Norte | Chefe final e três desfechos |

## Grafo de progressão

```text
ATO I   [01 HUB] -> [02] -> [03] -> [04 DUNGEON / PORTEIRO]
                                  |
ATO II                            v
        [05] -> [06 HUB] -> [07] -> [08 DUNGEON / ALMIRANTE]
                                  |
ATO III                           v
        [09] -> [10 HUB] -> [11] -> [12 / JARDINEIRO]
                                  |
ATO IV                            v
        [13] -> [14] -> [15 DUNGEON / CARTÓGRAFO]
```

## Regras de construção

- Mapas possuem ID imutável (`map_01` a `map_15`), spawn de entrada e saída, checkpoint e região de navegação própria.
- Hubs: combate desabilitado na praça central, serviços reativos e pontos de viagem; exteriores: combate, eventos e loot; dungeons: encontros autorais e arenas com telegráficos.
- A passagem entre regiões salva estado e usa transição, sem carregar os 15 mapas simultaneamente.
- Cada mapa possui 1 caminho crítico, 1 desvio opcional e 1 segredo, exceto hubs que priorizam serviços e diálogos.
- Os mapas são conceitos de design, não cenas Godot já implementadas.

## Metas de escala (provisórias, sujeitas a playtest)

- Hubs: 90–150 m de extensão útil; exteriores: 160–300 m; dungeons: 3–5 setores, 20–35 minutos.
- Densidade de encontros e checkpoints ajustada por telemetria local, sem grind obrigatório.
- Desafios de navegação devem ser legíveis com câmera ortográfica e colisões 3D reais.
