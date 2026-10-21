# Bastião do Crepúsculo — especificação de produção, v0.1

Estado: SPECIFIED, aprovação artística e dimensões propostas pendentes. Nenhum modelo externo final recebido. Não usar a fixture azul como referência artística.

## Identidade

Veterano de fantasia sombria, postura robusta, ombro do escudo reforçado e ombro da arma com mobilidade. Ferro escurecido e aço envelhecido legíveis pelas bordas gastas; couro nas articulações, bronze discreto em fechos. Assimetria funcional, sem coroa, símbolos de outras franquias ou ornamentação excessiva. Marca original de Éter como uma junta fraturada reparada, com emissão localizada e fraca; não transformar a armadura em fonte de luz.

Frente reconhecível por proteção do tórax em planos sobrepostos e faixa de couro diagonal; costas por capa curta dividida, distinta do peito. Espada e escudo precisam conservar silhueta a zoom 12 na câmera atual. Foles, bainha e tecido não devem cobrir o pé de apoio nem ocultar a direção da lâmina.

## Arquivos a produzir externamente

1. `.blend` editável com malhas, modificadores, UVs, armature e ações nomeadas; exportar `.glb` com skin, materiais e clipes incorporados.
2. Texturas originais 1024²: base color, normal e ORM quando aplicável; registrar espaço de cor. 2048² só mediante justificativa registrada.
3. Fonte editável dos materiais/texturas e manifesto de procedência: autor, ferramenta/versão, data, origem, termos de uso e plano de serviço, se houver. Um link de download ou assinatura de serviço não comprova direitos comerciais.
4. Corpo, espada, escudo e malhas modulares para os sete slots, evitando buracos ao retirar equipamento. Não incluir câmera, luz, colisores, NavigationAgent ou scripts de gameplay no GLB.

Orçamento equipado: até 20.000 triângulos, 65 ossos deformantes, quatro materiais efetivamente usados, quatro influências por vértice. Consolidar atlas/material compartilhado. LFS não é necessário para a fixture de 35 KB; avaliar tamanho e frequência das revisões ao receber fontes/arte, sem adicionar binários grandes por conveniência.

## Escala, rig e exportação

Metros, Y para cima, frente local -Z e pés na origem. Aplicar rotação/escala no Blender antes de exportar glTF; não aplicar novamente conversão manual de eixos na Godot. Proposta de envelope: altura de corpo/equipamento 1,60–2,20 m e extensão horizontal máxima 2,20 m em repouso, incluindo equipamentos. **Envelope de integração é proposta técnica, não altura canônica aprovada.** Cápsula do ator permanece raio 0,32 m e altura 1,60 m.

Rig humano de produção: root → pelvis → spine/chest → neck/head, cadeias upper_arm/forearm/hand e thigh/shin/foot; nomes exatos podem variar mediante configuração. Root motion desativado. Animar nos ossos, sem transladar root/hips nem mover o CharacterBody. Armas rígidas nos ossos de mão; capa pode usar ossos auxiliares dentro do orçamento.

Wrapper Godot com `SocketMain` e `SocketOffhand` como BoneAttachment3D, ligados a ossos existentes. `SocketName` Y=2,40 e `SocketHealth` Y=2,15 reutilizam o contrato atual. `SocketFX` perto do torso é visual; sua posição não altera origem/alcance de dano. Bainha é opcional e deverá ser documentada quando existir. Não usar offsets ocultos: ajustar no wrapper autorado com justificativa.

## Ações e tempos

Contrato de nomes: idle, walk, run, attack_basic, attack_heavy, skill_f1, skill_f2, skill_f3, hit_reaction, death, interact, block e dodge (esquiva existente). Idle/walk/run em loop; demais conforme ação, death sem loop. A tabela detalhada de disponibilidade fica em docs/FASE27_2_PIPELINE.md.

Gameplay continua autoritativo: ataque básico tem cooldown 0,55/attack_speed_mult e recuperação 0,18; F1 0,70 e recuperação 0,22; F3 0,80 e recuperação 0,25; guarda dura oito segundos. Dano já é aplicado pela lógica existente, sem esperar frame de animação. O adaptador ajusta apresentação à duração recebida; clipes não aplicam dano, custo, deslocamento ou cooldown. Cancelamentos continuam nos scripts atuais. Marcadores de efeito podem ser adicionados somente após revisão e teste de não duplicação.

## Aprovação humana necessária

Inspecionar frente/costas/perfil, silhueta a 720p e 1080p, arma/escudo em movimento, pés, deformações, sombras e oclusão no ambiente real. Avaliar identidade original e materiais na iluminação do jogo. Apenas revisão humana pode mudar ART_REVIEW_PENDING para ART_APPROVED. Validar novamente custos e gameplay ao receber o asset definitivo.
