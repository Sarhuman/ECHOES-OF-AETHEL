# Fase 22 — Integração visual de equipamentos (incremental)

Base: Fase 21, que depende da Fase 20. Não integrar diretamente à main.

## Implementado
- `AethelEquipmentVisual`: componente visual independente de stats, física, combate e loot.
- Slots helmet, chest, gloves, boots, cape, weapon_main e offhand.
- Raridades common, magic, rare, epic e legendary.
- Referências apenas a nós de cena previamente autorizados: `EquipmentVisuals/<slot>/<appearance_id>`.
- Em caso de referência inválida, mantém a aparência anterior e retorna false.
- `snapshot()` para inspeção; não constitui save de inventário.

## Pendente
- Importação dos assets GLB, sockets BoneAttachment3D e rigs reais.
- Contrato de identificação de itens, afixos, drop e persistência do projeto executável.
- Integração com os sinais de inventário após Fase 20.
- Testes em Godot e validação de orçamento de renderização.
- Tratamento de fallback de peça-base por slot e variantes de material.

## Critérios
1. Nenhuma troca de equipamento recria personagem ou AnimationPlayer.
2. IDs inválidos não podem disparar load de caminhos arbitrários.
3. Trocas em slots diferentes são independentes.
4. Regressões de animação, combate e salvamento devem ser verificadas antes de merge.

Nota: módulo preparado para integração; não é sistema de loot completo.
