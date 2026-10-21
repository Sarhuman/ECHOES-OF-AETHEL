# Fase 27.3 — validação e limites

21/10/2026. Base c6eac17/Fase27.2 sobre #15. Godot oficial4.7.2.stable.official.ed1daf0bf para jogo/testes/exportação; Summer0.7.3, engine4.7.2.stable.mono.custom_build.487400890, para autoria isolada de recursos. Nenhum runtime Summer redistribuído.

## Integração isolada antes de Vigília

Summer instalado executou build_summer_scene.gd em .tools/summer273 e salvou integration_test.tscn. Godot oficial leu o PackedScene com piso, parede, vão de porta, rampa, colisores e cinco polígonos NavigationRegion3D. O primeiro teste detectou uma borda de0,125m na junção do patamar; o patamar foi alinhado ao fim da rampa e o teste repetido antes de criar a variante principal.

Resultado gráfico aprovado:9 verificações, incluindo caminho nativo, passagem real da cápsula0,32×1,60 pela porta, subida atéY≈1,001, descida/retorno e bloqueio pela parede. Duas capturas reais em720p/1080p; metadados e hash da cena vinculados à prova em evidence/fase27-3-isolated.json. O ator de teste reutiliza visual/cápsula do Bastião, com movimento controlado pela fixture; não é um segundo controlador de gameplay. Testes de jogo real são separados abaixo.

## Preservação e regressões

Baseline antes das fontes:23 suítes aprovadas e bot10/10. Novo teste específico:30 verificações, zero falhas. Compara GREYBOX e SUMMER:988 células/alturas AStar, polígonos e assinatura de todos os colisores/transforms iguais; posições de NPCs/portal iguais; câmera ortográfica/zoom iguais. Testa aproximação real de Maera/Doma, aceitação de missão, comércio com débito/entrega atômicos, Âncora existente, fog/inventário/save v6, transição hostil/retorno seguro e rollback. Rejeita camada visual com colisor e verifica data/regions.json intacto.

Novo teste gráfico:42 verificações aprovadas,18 capturas reais da Godot em1280×720 e1920×1080 (GREYBOX/SUMMER na praça, Doma, Maera, Âncora, oclusão, torre, rua e minimapa). Clique nativo e aproximação, diálogos, compra/menus, E nos objetos/portais, F5/F9 e retorno ao hub. Não neutraliza IA/colisões nessa nova fixture; a estadia breve no Bairro usa o ponto de chegada protegido já existente. Capturas da torre em zoom18 usam o controle existente somente para inspeção, com retorno a12. Demais capturas mantêm a configuração habitual.

As suítes históricas da Fase27 conservam suas neutralizações de IA documentadas; não usar suas capturas como homologação de combate. A suíte completa desta etapa passou em26 testes, incluindo7 verificações isoladas headless e24 GUI headless, validador do grafo e bot de combate10/10; os logs finais e results.json são a referência da execução. Playtest humano completo e revisão artística continuam pendentes.

## Perfil local de Vigília

Mesma RX5802048SP, Compatibility,1920×1080, hub sem inimigos, personagem idle(-4,0,5), câmera/zoom originais,30 frames de aquecimento+180 medidos, teto60FPS. Dados em evidence/fase27-3-before.json e after.json. Execução no desktop sem isolamento deCPU/GPU.

| Medida | GREYBOX antes | SUMMER depois |
|---|---:|---:|
| Mediana ms/frame | 35,787 | 36,255 |
| p95 ms/frame | 41,800 | 43,579 |
| FPS pela mediana | 27,94 | 27,58 |
| Draw calls da cena | 267 | 297 |
| Primitivas renderizadas da cena | 68.800 | 73.420 |
| Memória de vídeo, bytes | 48.789.901 | 49.782.745 |
| Memória estática, bytes | 66.533.216 | 67.119.465 |
| Materiais em malhas visíveis da cena | 75 | 77 |
| Luzes na fixture | 5 | 7 |
| Células navegáveis | 988 | 988 |
| Construção da região, µs | 39.970 | 44.735 |
| Média de100 consultas de caminho, µs | 49,54 | 100,22 |

Mediana+1,3%, p95+4,3%, draw calls+11,2%; não há regressão relevante de tempo de frame observada nessa amostra. Caminho subiu cerca de0,051ms por consulta: a grade/código de busca são os mesmos, mas o teste não isola contenção/escalonamento do desktop; não afirmar custo idêntico de navegação. O acréscimo permanece pequeno em valor absoluto. Construção/consultas não representam carregamento assíncrono nem benchmark de campanha.

Primitivas são contadores da cena/passes, não triângulos únicos de assets. Custo isolado de materiais/luzes/GPU e custo de cada consulta individual: NOT_MEASURED. Sete materiais no recurso arquitetônico e batching por edifício/material evitam centenas de chamadas por pedra; a fixture completa inclui personagens/objetos anteriores. Não comprova60FPS. Manter GREYBOX disponível e reavaliar se novos assets elevarem os tempos significativamente.

## Oclusão e limites visuais

## Executável Windows

Exportação pela Godot oficial concluída e EXE executado com **38 verificações aprovadas**, incluindo as35 anteriores e três de arquitetura/nav/oclusão de Vigília. O teste usa o PCK exportado; não depende da pasta de desenvolvimento nem de Summer instalado. Menu, combate, comércio, exploração, persistência, transições e seleção visual do Bastião continuam cobertos. Logs em release-smoke-final.log e exportacao-release.log no pacote.

## Oclusão e limites visuais

Sete bounds de apresentação cobrem cinco edifícios, cobertura da forja e arco. AABB testa segmento na atualização de oclusão existente; não adiciona colisores nem altera navegação. Fader agora reconhece material de superfície em ArrayMesh e restaura a origem, além de suportar os overrides antigos. Teste funcional e capturas verificam alpha em Compatibility.

Variante arquitetônica inicial, estilizada, ART_REVIEW_PENDING. Malhas/cores originais sem texturas finais, escultura, interiores ou novos eventos. Nenhuma aprovação humana. Kit preparado para outros mapas, sem reconstruí-los nesta etapa. Summer Agent/MCP/cloud e exportação pelo Summer não foram executados; somente autoria local documentada foi usada. Exportação Windows segue pipeline Godot oficial.

Avisos ambientais de certificados/cache/editor e avisos de ObjectDB em algumas suítes legadas são preservados. Logs de desenvolvimento podem conter tentativas que falharam; somente os resultados finais representam a entrega.
