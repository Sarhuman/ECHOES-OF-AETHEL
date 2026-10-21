# Auditoria anterior à integração — 21/10/2026

Projeto real: `fase27/project.godot`, Godot 4.7.2 Compatibility. Branch inicial feat/fase27-mundo em 4d8b4366687e27fefe924135c3ab9fefd7ec778f. Nova branch feat/fase27-2-bastiao para revisão independente sobre #15. PR #15 aberto, Draft, sem merge; CI Windows execução 17/39550439457 concluída com sucesso. main/README consultado pelo conector GitHub: código Godot ainda não integrado; origin/main local 10980c6. Rede Git direta indisponível na leitura, conector confirmou a referência do PR. Sem AGENTS.md encontrado no projeto.

Lidos ART_REGISTRY, FASE27_VALIDATION, FASE27_WORLD, HUD_ENXUTA_FASE27 e TESTING. Inspecionados hybrid_player (movimento, combate e sincronização de equipamentos), follow_camera, hybrid_world (save/load), character_visual, character_visual_definition, equipment_visual e contratos .tres. Alterações locais anteriores: .import sem diferenças substantivas de conteúdo e logs não rastreados, preservados.

Sem .glb/.gltf/.blend utilizável no checkout ou projetos irmãos pesquisados. BastionPlaceholder instancia procedural_knight.gd: malhas primitivas, pivôs Node3D e tweens, sem Skeleton3D, clipes esqueléticos ou sockets de mão. Gerador Blender antigo não foi executado: Blender não disponível e recurso gerado ausente. Não há licença/topologia/rig de asset externo para presumir.

Reaproveitar AethelCharacterVisual e AethelEquipmentVisual, sete slots, os mesmos appearance_id, contratos de cápsula e âncoras, câmera e save v6. Ataque básico alterna attack_1/attack_2; F1/F3 usam o mesmo evento visual de ataque; F2 usa block; há hit/death/dodge e bloqueio manual. Interação existe no controlador narrativo. Não adicionar novas habilidades nem root motion.

Plano: medir baseline antes de alterar o personagem; criar estudo original de malha facetada via fonte Python editável, GLB com skin/rig e clipes chaveados, adaptador mínimo para o pipeline existente e validação. Estado artístico continua PLACEHOLDER/ART_REVIEW_PENDING: estudo técnico não equivale a personagem final modelado/retopologizado/aprovado. Sem produção nesta etapa de NPCs, inimigos ou cenário.
