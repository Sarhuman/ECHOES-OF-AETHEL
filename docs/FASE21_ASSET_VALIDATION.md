# Fase 21 — Produção e validação de assets

O script `tools/build_character_prototypes.py` é um **gerador experimental** de protótipos para Bastião e Maera. Cria malhas de volumes suavizados, armatures e ações com keyframes (idle/walk/run/attack/hit/dodge/death). **Não equivale a modelos artísticos finais** nem comprova rigging correto no runtime.

## Execução (máquina com Blender 4.x)
```bash
blender --background --python tools/build_character_prototypes.py
```
Saída esperada: `assets/characters/bastiao.glb` e `assets/characters/maera.glb`. Conferir arquivos produzidos e nomes das ações na importação; versões da API Blender podem requerer ajustes.

## Integração pendente
1. Importar a Fase 20 executável na branch anterior e resolver os scripts `procedural_knight.gd` e `procedural_npc.gd` sem quebrar `set_motion`, `play_attack` e interações existentes.
2. Abrir cada GLB no editor Godot; confirmar Skeleton3D, AnimationPlayer e os sete clipes. Ajustar offsets, parentagem, materiais e convenções de coordenadas.
3. Criar cenas de personagem com `CharacterVisual`, adaptar os nomes dos clipes importados e ligar ao controlador autoritativo.
4. Validar animações em 60 FPS, equipamento, ataques, colisões e transições.
5. Substituir protótipos por malhas autorais finais e animações refinadas, com licenças verificadas.

## Estado de verificação
- [x] Script de geração publicado.
- [ ] Blender executado e arquivos GLB exportados.
- [ ] Rig e clipes inspecionados no Blender.
- [ ] Godot executada; importação e cenas validadas.
- [ ] Testes e playtest concluídos.

**Não declarar integração concluída nem mesclar enquanto essas etapas estiverem pendentes.**
