# Fase 21 — Character Art & Animation Pipeline

**Estado: fundação técnica, sem modelos ou animações finais.**

## Objetivo
Substituir os visuais procedurais do Bastião, NPCs e Rasuras por modelos 3D estilizados com rig e animações, sem modificar a física, a IA, as hitboxes, os cálculos de combate ou os saves.

## Arquitetura
- `src/characters/character_visual.gd`: adaptador visual, instancia modelo `PackedScene`, resolve `AnimationPlayer`, orienta o visual e solicita animações.
- `src/characters/character_visual_definition.gd`: metadados de personagem e nomes de animações.
- O `CharacterBody3D` continua sendo a fonte de verdade para movimento, colisão, combate e IA.
- Contrato de importação: GLB com raiz Node3D e AnimationPlayer configurável; estados idle, walk, run, attack, hit, dodge e death, com variantes específicas por personagem.

## Ordem de implementação
1. **Bastião:** concept, malha, UV, materiais licenciados, rig, sete animações, GLB e validação na câmera dimétrica.
2. **Maera Voss:** modelo, idle, caminhada, gestos de diálogo e interação.
3. **Demais classes:** rigs compartilhados quando compatíveis; silhuetas, equipamentos e ataques próprios.
4. **NPCs e Rasuras:** bibliotecas por famílias; chefes com rigs e telegráficos exclusivos.
5. **Equipamentos:** sockets em ossos, offsets padronizados e troca de armas/escudos.
6. **Performance:** medir materiais, draw calls, FPS e memória antes de definir LOD.

## Critérios de aceitação
- [ ] Bastião com malha não procedural, rig e sete estados visíveis.
- [ ] Maera com malha não procedural e animações sociais.
- [ ] Importação de GLB e transições sem erro no editor Godot alvo.
- [ ] Hitboxes, timing de dano, física, inventário e save sem regressão.
- [ ] Testes automatizados e playtest com evidências.
- [ ] Expansão para demais heróis, NPCs, inimigos e chefes após validação do piloto.

## Limitações atuais
Estes arquivos são somente a fundação de código e documentação: **não incluem modelos 3D, rigs ou clipes de animação**. A Fase 20 ainda precisa ter seus arquivos executáveis importados ao repositório para que os adaptadores possam ser conectados. Nenhum teste de Godot foi executado neste commit.
