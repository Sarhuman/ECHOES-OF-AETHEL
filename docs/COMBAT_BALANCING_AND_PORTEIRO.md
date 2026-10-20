# Contrato de balanceamento e chefe do Ato I

**Status:** design técnico a implementar e testar na Godot 4.7.2. Não é código executável aprovado.

## Hipóteses de dificuldade

| Parâmetro | Normal | Pesadelo | Inferno |
|---|---:|---:|---:|
| Vida | 1,0× | 2,5× | 5,0× |
| Dano | 1,0× | 1,8× | 3,2× |
| Velocidade | 1,0× | 1,15× | 1,3× |
| XP | 1,0× | 2,2× | 4,5× |
| Bônus de chance de drop, pontos percentuais propostos | 0 | 15 | 35 |
| Redução de cooldown em segundos | 0 | 0,2 | 0,4 |

**Invariantes:** balancear uma vez por spawn a partir dos atributos base imutáveis; jamais reescalar cumulativamente ao carregar saves, nem usar `tree_exited` para conceder XP. Usar evento `defeated` emitido uma única vez após morte efetiva. Semântica de bônus de drop deve ser explícita e limitada; velocidade maior não equivale a inteligência maior.

## Porteiro das Portas Seladas (`map_04`)

FSM proposta: `IDLE -> CHASE -> TELEGRAPH -> COMBO -> RECOVERY -> CHASE`, com `SUMMON_TELEGRAPH -> SUMMON -> RECOVERY` e `DEAD` terminal.

- Combo frontal: aviso de 0,55–0,75 s, impacto frontal, segunda onda após 0,4 s; cada impacto registra no máximo um dano por alvo e respeita esquiva/invulnerabilidade.
- Aos 70% e 35% HP: invocações separadas de até três Rasuras, com gatilhos independentes mesmo quando um golpe ultrapassa ambos os limiares.
- Máximo de seis invocados simultâneos; spawn dentro de navegação válida, sem sobreposição com jogador.
- Flash de dano com material/shader em `MeshInstance3D` (não `modulate`, propriedade de `CanvasItem`).
- Morte: emite `defeated(boss_id, encounter_id)` uma vez, concede XP uma vez, registra checkpoint e consequência de missão; cancelamento seguro de timers e tweens.
- Colisão, NavMesh e orientação são testados com player se movendo; ataques sem telegráfico não são aceitos.
- Limites de dificuldade e XP devem passar por playtests de sobrevivência e duração do combate.

## Critérios de teste

Teste de escala idempotente, disparos 70/35% com dano que ultrapassa limiares, contagem máxima de summons, ausência de XP por despawn, ausência de duplicação de dano e save/load sem multiplicar atributos.
