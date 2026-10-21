# Fase 27.3 — auditoria anterior à alteração de Vigília

21/10/2026. Projeto real: `fase27/project.godot`, Godot oficial 4.7.2.stable.official.ed1daf0bf, Compatibility, Windows x64.

## Base e dependências

- HEAD inicial c6eac17fc7576dcbe8abe995f66a9a1289516d08, feat/fase27-2-bastiao. PR #16 aberto Draft sobre feat/fase27-mundo, CI 39553563329/execução18 aprovado. Nova branch feat/fase27-3-vigilia-summer sobre essa base, sem merge.
- PR #15 aberto Draft, feat/fase27-mundo em4d8b436 sobre feat/fase26-hud-eventos. main/README remoto consultado pelo conector: ainda documental, sem Godot integrado; origin/main local10980c6. Cadeia anterior #13/#14 não mesclada, conforme auditoria27.2.
- Branches locais/remotas inspecionadas. Mudanças do coordenador, region_level, exploração e scenes/regions estão na Fase27; diferença27.2→27 nesses caminhos é vazia. Fase27.2 altera adaptador visual, contratos e fixture do Bastião; manter essa infraestrutura e PLACEHOLDER padrão.
- Estado local prévio: .import com normalização de fim de linha e logs não rastreados, preservados. Nenhum AGENTS.md no checkout.
- Baseline antes de modificar fontes: validador do grafo e23 suítes aprovados, bot10/10, registrados em phase27-3-baseline-output.log e cópia dos resultados em .archive/phase27-3-baseline-results.json. Não confundir esse baseline funcional com benchmark gráfico.

## Fontes inspecionadas

FASE27_WORLD, FASE27_VALIDATION, TESTING e ART_REGISTRY; project.godot, data/regions.json, scenes/regions/map_01.tscn, region_manager, region_level, follow_camera, hybrid_world, exploration, npcs.json e exploration.json. Map_01 é composto em region_level; cena tem ID estável, uma definição compartilhada para AStar3D, NavigationRegion3D e colisões. Save v6/world_regions pertence ao mundo/coordenador; não duplicar nem migrar por visual.

Pontos preservados: spawn(0,0,4), chegada leste(9,0,0), portal(11,0,0) para map_02/south, Maera(-4,0,2), Doma(-9,0,2), oficina atrás de Doma e Âncora existente. Coordenador carrega uma região de cada vez, mantém segurança pelo destino e usa oclusão por collider. Variante visual deve manter os mesmos corpos/células, anexando paredes/telhados aos corpos existentes para conservar oclusão.

## Summer localizado

Aplicativo externo instalado, não plugin Godot: C:/Users/Sarumano/AppData/Local/SummerEngine/current/Summer.exe. sq.version e instalador em Downloads confirmam0.7.3; binário199.423.040 bytes informa4.7.2.stable.mono.custom_build.487400890. SHA25607ad5b69732c86384b91f54c027c5f6c83a415b824536d064fbbdde5a477bd47. Sem Summer CLI no PATH ou ferramentas Summer expostas nesta sessão. Busca de plugins não retornou conector Summer relevante; nenhum outro plugin foi sugerido como substituto.

Documentação oficial de headless/authoring consultada: https://docs.summerengine.com/automation/headless e https://docs.summerengine.com/automation/authoring. O executável instalado confirmou --headless, --path, --script, --version. Usar scripts SceneTree e ResourceSaver para criar cenas editáveis .tscn/.tres em projeto isolado. Não depende de nuvem ou do Summer Agent/MCP e não afirma uso desses serviços.

LICENSE.txt instalado permite desenvolvimento comercial/não comercial e proíbe redistribuir a engine como produto independente. Os termos atuais e licenças de assets de loja/IA são separados; não foram baixados assets, invocados geradores pagos ou distribuído runtime Summer. Site de compatibilidade genérico está defasado em relação à versão real do binário: somente teste de round-trip com a Godot oficial comprova este caso. Próxima etapa é teste isolado de piso/parede/porta/rampa, antes de tocar Vigília.
