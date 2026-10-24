# Echoes of Aethel — Fase 12: HUD de globos e núcleo de itens

Base: Fase 11 (personagens procedurais). Acrescenta os globos Vida/Éter e sistemas de item em Resources com instâncias individuais e grade 10×4.

## O que é funcional
- Globos nos cantos inferiores (texturas PNG locais), enchimento vertical e números ao passar o cursor.
- O dano recebido pelo Bastião atualiza o globo de Vida pelo sinal `hp_changed`.
- `AethelItemData`, `AethelItemInstance`, `AethelInventoryManager` e `AethelLootGenerator` disponíveis, sem conexão com loot de inimigos ou UI de inventário.
- Éter inicial 52/52 como recurso reservado; **não há consumo nem regeneração ainda**.

## Limites
- Este build **não contém** o inventário visual, salvamento dos itens ou integração com drops; somente módulos de lógica. `serialize/restore` prepara a persistência sem gravar arquivos.
- O loot usa pesos por item elegível, portanto raridades dependem da composição do catálogo; não apresenta chances globais fixas.
- Os globos são inspirados em interfaces clássicas, sem copiar arte protegida.
- Revisão estática feita, **sem homologação na Godot 4.7.2**.

## Teste manual
1. Abra `project.godot` na Godot 4.7.2 e pressione F5.
2. Passe o cursor sobre os globos nos cantos inferiores para visualizar números.
3. Entre no Bairro que Faltava e receba dano para verificar a atualização da Vida.
4. Verifique o painel de erros do parser e reporte qualquer mensagem junto com linha e script.
