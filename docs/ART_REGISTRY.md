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

## Revisão da captura do Arquivo

Os +50 XP foram gerados explicitamente por `Progression.gain_xp(50)` na fixture gráfica para verificar preenchimento e percentual. Não são recompensa de inimigo nem ganho espontâneo em gameplay. O aviso agora nasce acima do modelo. O rastreador explicita Rasuras e Bairro; M2 usa Golpe Pesado; cabeçalho compacto usa Arquivo/Pátio/Bairro/Vigília; fila compartilha a borda do minimapa. Rótulos de portal têm contorno e maior tamanho.

Oclusão testa torso de inimigos próximos e até quatro obstáculos sucessivos. A HUD continua sobre a cena: transparência de parede não faz inimigos aparecerem por cima do minimapa. Não revelar nomes através da HUD; alvo selecionado continua identificado no painel de alvo. Playtest humano e arte definitiva permanecem pendentes.
