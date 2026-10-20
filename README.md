# ECHOES OF AETHEL

Pré-alpha de ARPG de fantasia sombria, single-player, Windows x64, Godot **4.7.2.stable.official.ed1daf0bf**. Cenário 3D com câmera ortográfica inclinada, controle por clique e WASD relativo à câmera.

Esta branch consolida o **ZIP completo da Fase 20** com os adaptadores das Fases 21 e 22. Não usa o protótipo antigo de Downloads como base. Histórico, fontes e escolha de ancestral: [auditoria](docs/CONSOLIDATION_AUDIT.md) e [manifesto](docs/SOURCE_MANIFEST.json).

## Estabilização crítica da Fase 20

Branch `fix/fase20-jogabilidade`, baseada na consolidação `596d9e6`. Câmera inicial 12 com zoom 10–18 pela roda, raycast para selecionar inimigos e validar o chão, aproximação limitada ao alcance, F1/F2/F3 com execução direta e estado visível, Doma humano com avental/martelo e ajuda recolhível em H. [Causas, regressões e limites](docs/FASE20_STABILIZATION.md).

As três técnicas já existentes são disponibilizadas como kit de teste desta vertical slice, inclusive ao carregar saves anteriores. Não foram criadas habilidades novas nem declarado balanceamento final; a tela K continua mostrando seus dados e o botão direito repete a última técnica usada. A árvore genérica de progressão continua disponível no componente existente.

## Estado real

| Situação | Conteúdo |
|---|---|
| Implementado e testado localmente | Bastião; movimento; ataque e alternância de golpes; bloqueio Q; esquiva; Rasuras; loot; cinco raridades; afixos; mochila; 12 slots; loja; atributos; habilidades; HUD Vida/Éter/Fôlego; missão com Maera; save v4, migração v2/v3 e backup; menu, pausa e opções |
| Implementado com placeholders | Personagem procedural articulado; estados visuais; variantes de equipamento cadastradas; câmera 35,264°/45° com acompanhamento suave |
| Validado em execução gráfica | Menu, mundo, HUD em 1280×720, 1366×768 e 1280×800, mochila, personagem, habilidades, loja, pausa e opções |
| Ainda requer playtest humano | Sensação de combate, percurso por mouse, balanceamento amplo e experiência em outras máquinas |
| Planejado | Quatro outras classes jogáveis; modelos/rigs/animações finais; áudio de produção; navmesh; dungeon map_04; 15 mapas, três dungeons e três finais completos |
| CI | A consolidação anterior foi aprovada no run #1; o novo workflow desta branch gera o pacote **Estabilizado**. Consultar o PR de correção para o resultado remoto atual |

Vigília (`map_01`) e Bairro que Faltava (`map_02`) compartilham a geometria de teste e mudam NPCs, inimigos e objetivos. Não são dois mapas artísticos finalizados. Não há conteúdo executável do Arquivo das Portas Seladas (`map_04`).

## Executar

No pacote Windows, extraia **todo** o ZIP e abra `jogo/EchoesOfAethel-Fase20.exe`. Mantenha o `.pck` junto ao executável. Nenhuma instalação separada da Godot é necessária.

Para editar: importe o **project.godot da raiz deste repositório** na Godot 4.7.2. Execute com F6/F5 conforme a cena escolhida; a cena principal é `scenes/main_menu.tscn`.

## Controles

| Ação | Entrada |
|---|---|
| Mover | WASD/setas ou clique esquerdo no chão |
| Atacar/perseguir | Clique em inimigo; Shift+clique para atacar parado; J para ataque básico |
| Bloquear | Segurar Q com escudo; bloqueio manual consome Fôlego |
| Esquivar | Espaço |
| Habilidade | F1: Golpe; F2: Guarda (novamente cancela); F3: Eco. Barra também executa; botão direito repete a última técnica |
| Interagir/coletar | E; configurável para F em Opções; clique também coleta drops |
| Mochila/personagem/habilidades/loja | I ou Tab / C / K / L perto de Doma |
| Mostrar itens comuns | Alt |
| Poções | 1–4 |
| Salvar/carregar | F5 / F9 |
| Câmera / ajuda | Roda: zoom limitado; H: controles recolhíveis |
| Pausa | Esc; retomar, salvar, opções, menu e saída |
| Reiniciar após derrota | R, inicia uma nova sessão |

Ações centralizadas no InputMap (`project.godot`) e em `AethelInput`; opções controlam tela cheia, volume do bus Master, tecla de interação e persistência do zoom. O jogo ainda não possui trilha ou efeitos de áudio finais.

## Testar e exportar

Requer Godot 4.7.2 e Python 3 (biblioteca padrão para obter o template oficial).

```powershell
python tools/fetch_windows_template.py
./tools/test.ps1 -GodotExe 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
./tools/build_windows.ps1 -GodotExe 'C:/caminho/Godot_v4.7.2-stable_win64_console.exe'
python tools/package_windows.py
```

O template Windows x64 é obtido por intervalos HTTP do pacote oficial, com CRC e SHA256 registrados em `.tools/templates/provenance.json`. A build usa exportação release com `.pck`, não o editor renomeado. Saída em `teste-fase20/`; ZIP final na raiz. CI em `.github/workflows/windows.yml` disponibiliza artefato de pré-alpha, sem publicar release estável.

Os testes usam perfis isolados em `relatorios-fase20/profiles/`; não apagam os saves reais. `--fixed-fps 60` acelera a simulação sem alterar o passo lógico de 1/60 s. Logs e códigos de saída ficam em `relatorios-fase20/`. Resultados e limites em [VALIDATION](docs/VALIDATION.md); roteiro manual em [TESTING](docs/TESTING.md).

## Persistência

Save v4 mantém IDs de itens das fases anteriores e aceita saves v2/v3. Salva personagem, atributos, equipamentos, afixos, cinto, recursos, posição válida, região, habilidade selecionada e missão. Faz escrita temporária e backup `.bak`; dados inválidos tentam recuperar o backup. A posição fora do mapa ou dentro de colisão volta ao ponto inicial da região.

O nome histórico do arquivo continua `aethel_phase13_save.json` no diretório de dados do projeto da Godot. Novo jogo ignora o save existente para a sessão, sem apagá-lo; salvar depois substitui o principal e preserva o anterior em backup. Não é um gerenciador de múltiplos personagens.

## Estrutura

- `scripts/`: mundo, física/combate do Bastião, Rasuras e placeholders procedurais recuperados.
- `src/core/`: atributos, progressão, InputMap, configurações, caminhos de save e câmera.
- `src/items/`: catálogo, instâncias, afixos, gerador único de loot e inventário único.
- `src/characters/`: adaptadores visuais existentes e contratos extensíveis das cinco classes.
- `src/ui/`, `src/skills/`: HUD, menus, interfaces e habilidades.
- `scenes/`, `assets/`: cenas 3D e recursos locais; sem dependências de assets remotos.
- `data/`, `docs/`: catálogo de mapas planejados, cânone, histórico e evidências.
- `tests/`, `tools/`: regressões, capturas e distribuição reproduzível.

O mundo ainda concentra parte da integração; a modularização foi incremental, preservando os sistemas funcionais da Fase 20. O legado 2D foi retirado do projeto ativo e continua recuperável no ZIP de origem.

## Narrativa e limites

**O Direito ao Impossível:** Ecos materializam consequências de escolhas nunca realizadas. O Restaurador encontra âncoras e decide como estabilizar realidades, pagando com memórias. Maera Voss orienta a missão inicial. A missão deste protótipo não implementa ainda o sistema narrativo de escolhas e custos de memória.

Referências: [bíblia narrativa](docs/NARRATIVE_BIBLE.md), [atlas dos mapas](docs/WORLD_ATLAS.md), [Atlas do Nunca](docs/LORE_ATLAS_DO_NUNCA.md), [identidade dos mapas](docs/MAP_IDENTITY_MATRIX.md). São documentos de design; não representam funcionalidades já implementadas.

Avisos da engine em `licenses/`. Assets procedurais/texturas vieram do pacote fornecido; não foi concluída uma auditoria jurídica para publicação comercial. O repositório não define ainda uma licença geral de redistribuição do jogo. Build não assinada, destinada a testes de pré-alpha.
