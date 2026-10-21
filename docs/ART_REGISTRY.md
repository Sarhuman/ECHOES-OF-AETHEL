# Contrato e registro de arte

Todos os elementos abaixo continuam **protótipos sem aprovação artística**. Código procedural animado não equivale a rig ou animação final aprovada.

| Elemento | Estado | Movimento disponível | Próximo passo |
|---|---|---|---|
| Bastião | Protótipo procedural | idle, deslocamento e ações procedurais | Modelo de referência da escala, depois rig |
| Rasura comum | Protótipo procedural roxo | flutuação procedural | Modelo da família |
| Rasura Campeã | Variação procedural azul, cristas curtas | flutuação procedural | Derivar da família aprovada |
| Rasura Elite | Variação procedural dourada, cristas altas | flutuação procedural | Derivar da família aprovada |
| Maera Voss | Protótipo procedural | idle procedural | Modelo e retrato originais |
| Doma Ferren | Protótipo procedural | idle procedural | Modelo e retrato originais |
| Lyra e Sera | Não implementadas nesta base | Nenhuma | Validar cânone e especificação antes de implementar |
| Vigília, Bairro, Pátio e Arquivo | Geometria inicial | Não se aplica | Kit modular original após contratos dos atores |

## Substituição

`AethelActorPresentationContract` e os recursos `data/characters/*_contract.tres` definem dimensões em metros, eixo Y para cima, origem nos pés e âncoras `feet`, `weapon`, `label`, `health`. Instalado no ator, fora do modelo. Herói: cápsula 0,32 m × 1,60 m; Rasura: 0,34 m × 1,60 m multiplicada por 1/1,2/1,45; Doma: 0,40 m × 1,80 m. Maera usa seleção/interação, sem colisão física adicionada. Nenhuma dimensão de gameplay foi alterada.

O modelo é filho substituível (`BastiaoVisual/Model`, `RasuraVisual`, `MaeraVisual`, `DomaVisual`). `AethelCharacterVisual.replace_model` troca a apresentação do herói sem recriar o ator. NPCs e Rasuras mantêm seus filhos visuais independentes. Importar com pés na origem e escala unitária antes do multiplicador da categoria. Equipamento esquelético deverá ligar os sockets do rig às âncoras; marcadores preparados não constituem rig implementado.

Colisão, seleção, NavigationAgent, estatísticas, alcance e eventos de dano permanecem no ator. Nunca importar CollisionShape, scripts de combate ou NavigationAgent dentro do modelo. Testar troca com cápsula, posição e recursos inalterados antes de aprovar cada asset.

Ordem: Bastião → família Rasura → NPCs confirmados no cânone → kit modular. Herói tem armadura e equipamento; NPCs usam roupa e cor própria; Rasuras têm manto flutuante, Campeã cristas curtas azuis e Elite cristas altas douradas. Cor não é a única indicação de categoria.

## Fase 27.2 — registro separado de arte e técnica

| ID / versão | Caminho / formato | Estado artístico | Estado técnico | Rig / animações / sockets |
|---|---|---|---|---|
| bastion_placeholder / legado 4d8b436 | scenes/characters/bastion_placeholder.tscn + scripts/procedural_knight.gd / Godot e GDScript | PLACEHOLDER | INTEGRATED, regressões executadas | Sem rig esquelético; movimento procedural; âncoras no ator |
| bastion_production_spec / 0.1 | art/source/bastiao/PRODUCTION_SPEC.md / Markdown | SPECIFIED | Contrato preparado | Modelo humano, rig e animações finais ausentes |
| bastion_pipeline_fixture / 1 | art/imported/bastiao/test_fixture.glb / glTF 2.0 binário | PLACEHOLDER, TEST ONLY | TECHNICALLY_VALIDATED como fixture | Quatro ossos, skin e 13 clipes de teste; BoneAttachment nas mãos |
| bastion_external_model / ausente | Futuro GLB e fonte editável | SPECIFIED | Não recebido | Aguardando todos os recursos de produção |

Responsável pela atualização: Codex na tarefa do usuário, 21/10/2026. Fonte da fixture: art/source/bastiao/build_test_fixture.py, Python 3.12.14, biblioteca padrão. Nenhum Blender, Meshy ou outro serviço de modelos foi utilizado. Não existe .blend entregue. Procedência, hash, origem do pedido e restrições em art/source/bastiao/TEST_FIXTURE_PROVENANCE.md. Sem assets externos no GLB; não se presume exclusividade ou homologação jurídica/comercial. Licença e termos do futuro modelo externo permanecem pendentes. O código legado mantém sua procedência anterior, sem licença nova atribuída nesta etapa.

Dependências: Godot 4.7.2, adaptadores character_visual/equipment_visual e contratos .tres existentes. Slots da fixture: elmo, peito, luvas, botas, capa, sword/axe/mace e shield; são tokens, sem malhas modulares de produção ou contatos finais de empunhadura. Sem bainha funcional. Animações/durações em FASE27_2_PIPELINE.md; dimensões em FASE27_2_SCALE.md; testes em FASE27_2_VALIDATION.md.

Nenhum ART_APPROVED atribuído. A integração visual de produção e a revisão artística do Bastião permanecem pendentes. A fixture não deve ser submetida como personagem final: seu estado técnico não implica qualidade artística. Evidências do viewport identificam explicitamente PLACEHOLDER ou TESTE DE PIPELINE.

## Revisão da captura do Arquivo

Os +50 XP foram gerados explicitamente por `Progression.gain_xp(50)` na fixture gráfica para verificar preenchimento e percentual. Não são recompensa de inimigo nem ganho espontâneo em gameplay. O aviso agora nasce acima do modelo. O rastreador explicita Rasuras e Bairro; M2 usa Golpe Pesado; cabeçalho compacto usa Arquivo/Pátio/Bairro/Vigília; fila compartilha a borda do minimapa. Rótulos de portal têm contorno e maior tamanho.

Oclusão testa torso de inimigos próximos e até quatro obstáculos sucessivos. A HUD continua sobre a cena: transparência de parede não faz inimigos aparecerem por cima do minimapa. Não revelar nomes através da HUD; alvo selecionado continua identificado no painel de alvo. Playtest humano e arte definitiva permanecem pendentes.
