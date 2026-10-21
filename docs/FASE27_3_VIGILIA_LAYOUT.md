# Vigília — variante arquitetônica inicial

Plano autorado antes da construção em art/source/vigilia/layout.json. Somente map_01 recebe a variante; Bairro, Pátio e Arquivo mantêm o cenário anterior. Não há novos NPCs, missões, interiores exploráveis ou eventos narrativos.

## Espaços e marcos preservados

| Área | Coordenadas de referência | Construção e circulação |
|---|---|---|
| Praça dos Sinos | Spawn(0,0,4) | Pavimento claro sobre o percurso existente e dois anéis incompletos deslocados; comunicação visual dos Ecos sem nova interação |
| Torre dos Sinos | (-10,0,-10), mesmo footprint noroeste | Base em pedra, armação de madeira, sino/aro em bronze, cobertura inclinada; altura visual até ~5,47 m |
| Oficina de Doma | NPC(-9,0,2), fornalha(-11,0,-3) | Fornalha, bigorna, banco e expositor existentes permanecem; cobertura/chaminé visuais sobre a área de trabalho |
| Maera | (-4,0,2) | Área de aproximação livre; luz quente próxima, sem colisor adicional |
| Âncora de Travessia | (3,0,6), vigilia_anchor | Mesmo objeto, alcance e registro de descoberta; pavimento integra o marco |
| Saída leste | (11,0,0), map_01_to_map_02 | Arco visual sobre o marcador original; chegada leste(9,0,0) e destino map_02/south intactos |
| Ruas secundárias | Entre os cinco footprints existentes | Rotas originais da grade, sem abrir/fechar passagens ou acrescentar sólidos |

Cinco edifícios usam os retângulos já bloqueados em regions.json. Fachadas estreitas, madeira escura, juntas de pedra, ferragens, portas decorativas, caixilhos e telhados inclinados substituem os volumes visuais anteriores. Os interiores continuam fechados; uma porta de fachada não implica interação nova. Um contorno de janela deslocado e os anéis incompletos dão identidade inicial de realidades sobrepostas, sem alterar o cânone.

## Kit compartilhado e limites artísticos

Treze módulos em art/imported/vigilia/modules: piso, rua, meio-fio, parede, arco/porta, janela, coluna, telhado, escada, rampa, estrutura de madeira, lanterna e inserção de Eco. Escadas/rampas estão preparadas como visuais; o hub continua plano. O teste isolado tem colisão/rampa reais. Nenhuma ponte foi adicionada sem necessidade.

Sete materiais no cenário ativo: stone, dark_stone, timber, roof, iron, bronze e echo. Geometria agrupada por edifício/material em ArrayMesh; módulos e posições continuam editáveis nos arquivos Godot e parâmetros no GDScript-fonte. Batching elimina primitivos individuais na cena gerada; não se afirma que isso seja uma malha esculpida ou arquivo Blender.

Dois novos pontos de luz quentes, sem sombra dinâmica, somam-se às cinco luzes já presentes na fixture do hub. Ambiente global, neblina e câmera não mudam. A inspeção da torre usa zoom18 dentro do controle existente e retorna a12; isso é apenas uma captura de inspeção, não uma alteração global de câmera.

## Navegação, física e oclusão

data/regions.json e map_01.tscn originais não foram alterados. Map_01_summer.tscn herda a cena original e acrescenta apresentação. Mesmas988 células, mesmos polígonos NavigationRegion3D e assinatura de formas/transforms de colisão. Materiais e malhas novas não possuem CollisionObject/NavigationRegion/Camera; candidatos com esses nós são recusados pelo adaptador.

Edifícios visuais ficam filhos dos corpos antigos. Limites AABB adicionais de apresentação cobrem os telhados acima dos colisores existentes; testes de segmento a cada atualização de oclusão os tornam translúcidos quando encobrem jogador/inimigos próximos. Não há nova camada física ou novo sistema de navegação. Materiais de superfície dos ArrayMeshes são tratados pelo mesmo fader Compatibility, com restauração do material original.

Alternância de desenvolvimento em Project Settings: aethel/world/vigilia_variant = SUMMER ou GREYBOX. Não aparece no save. Recarregar a região aplica a seleção; GREYBOX recupera a composição anterior. A variante Summer passou nas validações antes da escolha como padrão desta entrega. Arte permanece ART_REVIEW_PENDING.
