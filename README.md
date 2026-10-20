# ECHOES OF AETHEL

**ARPG single-player de fantasia sombria sobre futuros que nunca aconteceram.** Projeto orientado à **Godot 4.7.2**, câmera top-down oblíqua e prototipação híbrida **2.5D** (mundo 3D, câmera ortográfica, sprites e UI 2D).

> **Status real:** documentação de pré-produção publicada. O projeto Godot testado anteriormente ainda **não está versionado neste repositório**. Não há build executável ou 15 mapas implementados aqui.

## O Direito ao Impossível

Em Aethel, as consequências de escolhas não realizadas invadem o presente. Um **Restaurador** pode estabilizar a realidade, mas perde uma memória verdadeira a cada intervenção irreversível. A campanha confronta o jogador com a pergunta: **quem tem o direito de decidir qual vida é real?**

A narrativa evita o antigo enredo de Coração de Éter, Vael e corrupção ancestral. Consulte a [Bíblia Narrativa v3](docs/NARRATIVE_BIBLE.md).

## Mundo: 15 mapas, incluindo 3 dungeons

| Ato | Mapas | Dungeon | Chefe de ato |
|---|---|---|---|
| I — O Bairro que Faltava | 01 Vigília; 02 Bairro que Faltava; 03 Pátio dos Endereços; 04 Arquivo das Portas Seladas | 04 | Porteiro das Portas Seladas |
| II — Maré de Vidro | 05 Estrada dos Retornos; 06 Cais de Sal; 07 Estaleiro de Vidro; 08 Porão da Travessia Nula | 08 | Almirante Sem Travessia |
| III — Jardim dos Ausentes | 09 Várzea das Promessas; 10 Jardim de Cobre; 11 Pomar dos Nomes; 12 Estufa das Causas | — | Jardineiro das Causas |
| IV — Atlas do Nunca | 13 Fenda dos Registros; 14 Observatório da Linha Única; 15 Atlas do Nunca | 15 | Cartógrafo sem Norte |

**Total: 15 mapas = 12 regiões não-dungeon + 3 dungeons.** Três hubs (01, 06, 10), com serviços, diálogos e escolhas reativas. Ver [Atlas dos Mapas](docs/WORLD_ATLAS.md), [mockups de interface e layout](docs/MOCKUPS.md) e [catálogo JSON de regiões](data/maps.json).

## Personagens

Maera Voss (cartógrafa), Teren Hal (sineiro), Sive (duas histórias incompatíveis), Iro Sen (primeiro Restaurador) e NPCs regionais com objetivos, conflitos e consequências de escolhas. Cinco arquétipos de combate previstos: Bastião, Tecelã, Sentinela, Invocadora e Inquisidor; nomes de classes são provisórios.

## Direção técnica

- **Mundo:** `Node3D`, `CharacterBody3D`, `NavigationAgent3D`, colisões físicas e transições por mapa.
- **Visual:** `Camera3D` ortográfica, `Sprite3D` para personagens quando apropriado, materiais e iluminação 3D, `CanvasLayer` para HUD.
- **Dados:** IDs estáveis (`map_01`…`map_15`), missões e diálogos desacoplados das cenas; saves versionados com migração.
- **Produto:** PC Windows primeiro; sem multiplayer ou backend obrigatório no MVP.

## Roadmap verificável

1. Importar e versionar a Fase 5 testada, com verificação de licenças e assets.
2. Validar importação e execução na Godot 4.7.2, corrigir erros de parser e runtime.
3. Implementar mapa 01 (hub), mapa 02 (exterior) e mapa 04 (dungeon) com vertical slice de combate e missão.
4. Criar pipeline de mapas modulares, inventário, saves migráveis e testes de regressão.
5. Expandir para 15 mapas somente após aprovação do vertical slice.

## Arte e propriedade intelectual

Arte conceitual e mockups são referências de pré-produção, não assets finais de jogo. Revisar disponibilidade de nome, licenças de imagens e semelhanças narrativas antes de distribuição comercial.
