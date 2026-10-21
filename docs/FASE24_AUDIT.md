# Fase 24 — auditoria anterior à implementação

20/10/2026. Remoto consultado por fetch; main permanece em 10980c6 (documentação). Base escolhida: 52ceb7c, PR Draft #11, dependente dos PRs #10 e #9. Nenhum merge realizado.

- Fase 23: inventário único, 43 definições, equipamento, comparação, arraste e save v4 existentes; resultados e limitações registrados no PR #11. Será necessário repetir regressões.
- Vigília é construída proceduralmente por hybrid_world.gd; Maera e Doma usam procedural_npc.gd, sem modelos ou retratos finais. Não há cena independente de oficina.
- AethelDialogueView é apenas apresentação. Interação atual usa proximidade; loja usa ouro/inventário reais, mas falta validar estoque obsoleto, proteção de itens e persistência das mercadorias.
- Quest atual: flags quest_started/quest_completed/map_02_cleared. Retornar após cinco Rasuras conclui indevidamente a missão canônica; não há recompensa desse retorno.
- Cânone consultado: NARRATIVE_BIBLE.md. Uma Porta para Ninguém exige placa, livro, sino rachado e escolha posterior: essa campanha não está implementada. A investigação de cinco Rasuras será identificada como demonstração provisória, sem representar o desfecho canônico.
- Maera é cartógrafa/mentora; Teren, sineiro sem voz; Doma, ferreiro; Sive aparece nos mapas 10–12; Iro, primeiro Restaurador, nos mapas 14–15. Preparar dados sem antecipar presenças ou novas biografias.

Integração prevista: dados de NPCs/conversas, controlador ligado ao mundo e à view existente; efeitos explicitamente permitidos; mesmos inventário, ouro, flags e arquivo de save. Oficina e personagens permanecem arte procedural provisória original. Playtest humano será distinguido de inputs automatizados e inspeção de capturas.
