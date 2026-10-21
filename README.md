# Fase 25 — exploração, loot e interações

Versão Windows 0.25.0, Godot 4.7.2. Base: Fase 24 / PR #12. Loot por tabelas, cinco raridades, filtro, campeão e elite com dois lacaios, contêineres, altar, poço e Âncoras de Travessia funcionais. Mortes, fontes consumidas, âncoras e loot pendente persistem no mesmo save do personagem.

Extraia o ZIP e abra `jogo/EchoesOfAethel-Fase25.exe` com PCK junto. Fonte: `fonte/project.godot`. Clique/E/F interage; Alt mostra nomes; O filtra; I inventário; F5/F9 salva/carrega. Aceite a investigação provisória com Maera para sair ao Bairro. [Roteiro](docs/TESTING.md), [auditoria](docs/FASE25_AUDIT.md), [regras e limites](docs/FASE25_EXPLORATION.md).

Área hostil, arte e sons são provisórios. Campanha e playtest humano continuam pendentes. PR Draft, sem merge automático.

---

## Histórico da Fase 24

# Fase 24 — NPCs, diálogo e comércio integrado

Versão Windows 0.24.0, Godot 4.7.2. Parte da Fase 23 (PR #11), preservando inventário, equipamentos e combate. Doma tem diálogo ramificado, oficina provisória, estoque determinístico persistente e compra/venda reais; Maera apresenta uma investigação provisória com recompensa única. A missão canônica completa permanece pendente.

Execute `jogo/EchoesOfAethel-Fase24.exe` com PCK junto após extrair o ZIP. Fonte: `fonte/project.godot`. E/F conversa; clique em NPC distante aproxima; L abre loja perto de Doma; I mochila; F5/F9 salva/carrega. [Roteiro](docs/TESTING.md), [auditoria](docs/FASE24_AUDIT.md), [arquitetura e limites](docs/FASE24_NPCS.md). Arte procedural e retratos são provisórios. Playtest humano pendente. PR Draft, sem merge automático.

---

## Histórico da Fase 23

# ECHOES OF AETHEL

## Fase 23 — inventário funcional da vertical slice

Versão **0.23.0**, Godot **4.7.2.stable.official.ed1daf0bf**, branch `feat/fase23-inventario` sobre a fundação visual do PR #10. A `main` e os PRs anteriores não foram mesclados automaticamente. [Auditoria e implementação](docs/FASE23_INVENTORY_AUDIT.md) · [Roteiro de teste atual](docs/TESTING.md).

**I/Tab** abre a mochila real: 40 células configuráveis, ícones individuais, quantidades, cinco raridades, seleção/foco, comparação numérica e botão Organizar. Arraste para mover/trocar/equipar/retirar; **M**, setas e Enter movem pelo teclado, Esc cancela. Slots canônicos funcionais, com cinto/talismã legados preservados. Requisitos, ocupação e compatibilidade de mãos são validados antes da transferência; falhas mantêm itens e posições. O mesmo gerenciador, cálculo de atributos, adaptador visual e save v4 continuam em uso.

43 ícones vetoriais próprios são **placeholders**; materiais/objetos de missão têm registros reservados, sem novas recompensas ou sistemas de crafting. Comparação mostra deltas do item, separando dano base dos bônus do personagem. Equipamentos 3D usam apenas os modelos procedurais existentes; acessórios não recebem modelos falsos. Conjuntos/encaixes/Sigilos não foram antecipados.

Pacote desta fase: **EchoesOfAethel-Fase23-Windows-x64.zip**. Extraia tudo e abra `jogo/EchoesOfAethel-Fase23.exe` com o PCK junto. Para editar, use o `project.godot` desta branch; no ZIP, `fonte/project.godot`. O workflow **Windows Fase 23** executa treze suítes, exporta e roda o EXE antes de publicar o artefato. Comandos de build permanecem em tools/build_windows.ps1 e tools/smoke_windows.ps1; veja docs/TESTING.md. As seções abaixo preservam o histórico da base anterior.

## Fundação visual gótica — Sino e Limiar

Tema reutilizável aplicado à base da Fase 20.2: paleta de carvão/pedra/bronze, texto pergaminho, molduras de cinco raridades, foco visível e painel compacto com Vida/Éter/Fôlego independentes. Tooltips da mochila também abrem por teclado. Componentes de ícone, comparação e diálogo estão preparados para integração futura; retratos e interfaces definitivas continuam pendentes. [Design system, estados, tipografia e limites](docs/GOTHIC_UI_DESIGN_SYSTEM.md).

## Fase 20.2 — base Godot integrada

Branch `integration/fase20-2-godot`, baseada em `e66f451`, proposta contra `main`. Os PRs #4–8 estão abertos e não mesclados; esta branch preserva sua cadeia de commits e disponibiliza o projeto completo. [Auditoria da Fase 20.2](docs/FASE20_2_INTEGRATION_AUDIT.md).

Versão do jogo **0.20.2**, engine **4.7.2.stable.official.ed1daf0bf**. Projeto na raiz da branch; no pacote, abra `fonte/project.godot`. Para jogar, abra `jogo/EchoesOfAethel-Fase20.exe` mantendo o PCK junto.

```powershell
./tools/fetch_godot.ps1
python tools/fetch_windows_template.py
./tools/build_windows.ps1 -GodotExe "$pwd/.tools/Godot_v4.7.2-stable_win64_console.exe"
./tools/smoke_windows.ps1
python tools/package_windows.py
```

O download verifica SHA512 do ZIP oficial da engine; o template verifica CRC e SHA256 fixado. O build recusa outra versão/commit da engine ou hash do template. Dez suítes incluem integridade de cenas/Resources e unicidade de classes; a matriz de clique inclui 1920×1080. O smoke executa o EXE Windows em perfil isolado e verifica dez condições de gameplay, além do marcador do menu e saída correta.

Artefato atual: **EchoesOfAethel-PreAlpha-Windows-x64.zip**, com `jogo/`, `fonte/`, `evidencias/` e manifesto SHA256. Na aba Actions, selecione **Windows PreAlpha Fase 20.2** e baixe o artefato de mesmo nome. O workflow exporta e executa o EXE em Windows; não publica release estável. As seções de estabilização e o CI #4 abaixo registram o histórico da Fase 20.1.

[Pipeline da Fase 20.2 aprovado](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39515919505) no código a06b725, incluindo execução do EXE em Windows. [Baixar artefato Windows](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39515919505/artifacts/12307887323) · [PR #9 para revisão](https://github.com/Sarhuman/ECHOES-OF-AETHEL/pull/9).

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
| CI validado | [Estabilização Windows #4](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39511987807) aprovada: nove suítes, exportação e [artefato Windows](https://github.com/Sarhuman/ECHOES-OF-AETHEL/actions/runs/39511987807/artifacts/12306003453) |

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
