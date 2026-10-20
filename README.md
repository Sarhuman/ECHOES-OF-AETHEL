# ECHOES OF AETHEL

### Um ARPG de fantasia sombria sobre realidades que nunca deveriam existir

**Em desenvolvimento · Godot 4 · PC Windows · Single-player · Perspectiva isométrica 2.5D**

*Quando futuros que ninguém escolheu começam a existir, quem tem o direito de decidir qual realidade deve permanecer?*

---

## O jogo

**Echoes of Aethel** é um Action RPG *hack and slash* de fantasia sombria inspirado no ritmo de combate, progressão e exploração dos ARPGs clássicos, especialmente **Diablo II: Resurrected**, mas com universo, personagens, mecânicas narrativas e identidade próprios.

A direção técnica é **3D com câmera ortográfica inclinada** (apresentação 2.5D), cenários exploráveis, combate em tempo real, equipamentos e escolhas que repercutem na campanha.

> **Estado público do repositório (20/10/2026):** este repositório contém a documentação do projeto, mas **o código executável da Godot ainda não foi integrado à branch `main`**. Há protótipos ZIP testados e versões experimentais compartilhadas durante o desenvolvimento; a Fase 11 precisa de validação na Godot 4.7.2. Os 15 mapas **ainda não estão implementados**. Não há build pública homologada.

## História — O Direito ao Impossível

Em Aethel, certas escolhas jamais realizadas deixam consequências reais. Esses vestígios, chamados **Ecos**, podem transformar ruas, memórias e pessoas. Um distrito surge de madrugada onde antes havia um vazio; navios chegam de expedições que ninguém realizou; crianças lembram aniversários de vidas incompatíveis.

O jogador assume o papel de um **Restaurador**, alguém capaz de encontrar as âncoras materiais desses acontecimentos e estabilizar o mundo. Cada intervenção irreversível, porém, apaga uma memória verdadeira do protagonista.

Não existe apenas um tirano a derrotar: facções disputam o poder de definir **quem merece existir**. A história é contada por ambientes, NPCs, itens, missões e decisões persistentes.

### Personagens principais

| Personagem | Função narrativa |
| --- | --- |
| **Maera Voss** | Cartógrafa exilada e mentora; ajudou a disseminar a cartografia de futuros proibidos. |
| **Teren Hal** | Sineiro sem voz; documenta o preço das escolhas. |
| **Sive** | Jovem com duas histórias igualmente reais; luta por autonomia. |
| **Iro Sen** | Primeiro Restaurador; quer fixar uma realidade única para impedir novas rupturas. |
| **Doma Ferren** | Ferreiro de Vigília, cuja história familiar foi alterada por um Eco. |

## Campanha — 15 mapas, incluindo 3 dungeons

**Escopo fechado:** 4 atos, **12 regiões não-dungeon** (incluindo 3 hubs) e **3 dungeons**. A numeração abaixo é também o identificador de conteúdo planejado (`map_01` a `map_15`).

| ID | Ato | Local | Tipo |
| --- | --- | --- | --- |
| 01 | I — O Bairro que Faltava | **Vigília — Praça dos Sinos** | Hub |
| 02 | I | Bairro que Faltava | Exterior |
| 03 | I | Pátio dos Endereços | Exterior |
| 04 | I | **Arquivo das Portas Seladas** | **Dungeon 1** |
| 05 | II — Maré de Vidro | Estrada dos Retornos | Exterior |
| 06 | II | **Cais de Sal** | Hub |
| 07 | II | Estaleiro de Vidro | Exterior |
| 08 | II | **Porão da Travessia Nula** | **Dungeon 2** |
| 09 | III — Jardim dos Ausentes | Várzea das Promessas | Exterior |
| 10 | III | **Jardim de Cobre** | Hub |
| 11 | III | Pomar dos Nomes | Exterior |
| 12 | III | Estufa das Causas | Exterior / chefe |
| 13 | IV — Atlas do Nunca | Fenda dos Registros | Exterior |
| 14 | IV | Observatório da Linha Única | Exterior |
| 15 | IV | **Atlas do Nunca** | **Dungeon 3 / final** |

**Chefes principais:** Porteiro das Portas Seladas, Almirante Sem Travessia, Jardineiro das Causas e Cartógrafo sem Norte.

A campanha foi concebida com **três conclusões** — *Linha Única*, *Mundo Poroso* e *Atlas Aberto* — condicionadas por escolhas anteriores. Esses desfechos são planejamento narrativo, não funcionalidades já implementadas.

## Classes jogáveis planejadas

| Classe | Especialidade |
| --- | --- |
| **Bastião do Crepúsculo** | Resistência, machado e escudo, controle corpo a corpo. |
| **Tecelã do Éter** | Magia ofensiva, manipulação de área e controle. |
| **Sentinela das Cinzas** | Arco, mobilidade, ataques precisos e armadilhas. |
| **Invocadora dos Véus** | Invocações, espíritos e enfraquecimentos. |
| **Inquisidor da Aurora** | Combate híbrido, proteção e julgamento. |

**Prioridade de implementação:** Bastião. As demais classes ainda dependem de implementação e balanceamento.

## Sistemas do ARPG

| Sistema | Situação |
| --- | --- |
| Movimento WASD e câmera ortográfica | Protótipo local |
| Ataque, esquiva e inimigos simples | Protótipo local |
| Indicadores de dano | Protótipo local; requer regressão |
| Interação com Maera e missão introdutória | Protótipo experimental |
| Modelos autorais low-poly para Bastião, Maera e Rasuras | Fase 11 preparada; aguardando teste |
| Machado, escudo e animação procedural | Fase 11 preparada; aguardando teste |
| Navegação por clique com `NavigationAgent3D` | Planejado |
| Inventário em grade e equipamentos persistentes | Planejado para arquitetura 2.5D |
| Loot com raridades, afixos e tabelas | Planejado |
| Habilidades e árvore de progressão | Planejado |
| Missões ramificadas e consequências em save | Planejado |
| 15 mapas e 3 dungeons | Design definido; implementação pendente |
| Cinemáticas, áudio e interface definitiva | Planejado |

## Direção visual

- **Câmera:** ortográfica em ângulo fixo, com leitura isométrica/oblíqua.
- **Cenários:** geometria 3D, materiais, iluminação e sombras dinâmicas.
- **Personagens:** visuais autorais com animações e equipamentos; a Fase 11 abandona o FBX externo do Bastião no fluxo principal.
- **Interface:** HUD 2D independente do mundo (`CanvasLayer`), com vida, recursos, atalhos e feedback de combate.
- **Atmosfera:** cidades impossíveis, ruínas, arquitetura gótica, iluminação quente em contraste com azuis e violetas espectrais.

Ilustrações e mockups produzidos durante a pré-produção **não representam screenshots de funcionalidades implementadas**.

## Engenharia

**Engine-alvo informada pelo projeto:** Godot **4.7.2**. Verificar compatibilidade real no editor antes de anunciar uma versão homologada.

Arquitetura planejada (migração incremental; não implica existência atual de todos os diretórios):

```text
res://
├── assets/
│   ├── art/
│   ├── audio/
│   └── shaders/
├── src/
│   ├── core/               # estado e eventos
│   ├── entities/           # player, NPCs, inimigos e componentes
│   ├── combat/             # acertos, dano e efeitos
│   ├── items/              # Resources, inventário e loot
│   ├── skills/             # dados de habilidades e execução
│   ├── quests/             # progressão narrativa
│   ├── persistence/        # saves versionados
│   └── ui/                 # HUD, menus e acessibilidade
├── scenes/
│   ├── maps/               # um mapa carregável por região
│   └── menus/
└── data/                   # catálogo de IDs e conteúdo
```

**Princípios:** `CharacterBody3D` para movimento físico; `NavigationAgent3D` somente com navegação preparada; lógica de combate desacoplada de animações; `Resource` tipados para itens e habilidades; identificadores estáveis para mapa, NPC, quest e item; saves com versionamento e migração; testes de regressão ao substituir a camada visual.

## Próximos marcos

1. **Estabilizar a Fase 11:** validar parsing na Godot, caminhada, ataque, efeitos, interações, machado e escudo.
2. **Versionar o projeto executável**, sem arquivos temporários e com licenças de assets revisadas.
3. **Construir uma vertical slice de três áreas:** Vigília (hub), Bairro que Faltava (exterior) e Arquivo das Portas Seladas (dungeon).
4. **Modularizar o jogo:** cenas de entidades, combate, inventário, missões e persistência.
5. **Escalar o conteúdo:** expandir para as 15 regiões somente após estabilidade da vertical slice.

## Documentação de design

A documentação expandida está atualmente em uma **branch de revisão**, não na `main`:

- [Bíblia narrativa](https://github.com/Sarhuman/ECHOES-OF-AETHEL/blob/feat/original-narrative-foundation/docs/NARRATIVE_BIBLE.md)
- [Atlas dos 15 mapas](https://github.com/Sarhuman/ECHOES-OF-AETHEL/blob/feat/original-narrative-foundation/docs/WORLD_ATLAS.md)
- [Mockups de UX e mapas](https://github.com/Sarhuman/ECHOES-OF-AETHEL/blob/feat/original-narrative-foundation/docs/MOCKUPS.md)
- [Catálogo JSON dos mapas](https://github.com/Sarhuman/ECHOES-OF-AETHEL/blob/feat/original-narrative-foundation/data/maps.json)
- [PR #1 — documentação narrativa](https://github.com/Sarhuman/ECHOES-OF-AETHEL/pull/1)
- [PR #2 — preparação de integração Godot](https://github.com/Sarhuman/ECHOES-OF-AETHEL/pull/2)

## Situação de lançamento

**Pré-alpha / protótipo experimental.** Não há release, instalador ou build final disponível neste repositório. O código local e os assets precisam ser integrados, testados e documentados antes de distribuição.

**Autoria e propriedade intelectual:** este projeto busca uma identidade própria; referências a outros jogos descrevem influências de gênero, não afiliação. Verificar direitos de uso de imagens, modelos, áudio, tipografia e nome antes de publicar comercialmente.
