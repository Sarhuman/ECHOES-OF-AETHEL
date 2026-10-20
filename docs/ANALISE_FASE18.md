# Análise da Fase 18 e correções da Fase 19

## Como foi validado
- Godot **4.4.1** headless: importação sem erros de parser; cena principal rodou 150 frames sem erro de runtime.
- `tests/test_rpg_systems.gd` passou. Foi criado `tests/test_gameplay.gd`, que **falha no código original** (confirmado) e passa no corrigido.
- **Não validado:** renderização (HUD, câmera, inventário na tela), Godot 4.7.2 (o `project.godot` declara 4.3), 1920×1080 e janela redimensionada. Faça o playtest visual do README_FASE18.

## Bugs confirmados e corrigidos
1. **WASD na diagonal da tela.** A câmera tem yaw de 45°, mas o input era em eixos do mundo: W ia para cima-direita. O input agora é girado 45°.
2. **Esquiva parado não se movia**, mas gastava Fôlego e dava invulnerabilidade. Agora usa a direção do olhar.
3. **Farm infinito:** sair e voltar ao Bairro que Faltava respawnava 5 Rasuras (XP, ouro e loot). Agora a região limpa fica limpa (`map_02_cleared`, salvo no save).
4. **Drops do Bairro apareciam em Vigília** ao voltar ao hub. Cada drop agora pertence à sua região.
5. **Itens perdidos em silêncio** quando o save tinha posição inválida. Agora são recolocados no primeiro espaço livre.
6. **"R para reiniciar" não existia:** o código usava Enter/Espaço (conflito com a esquiva). Agora é R.
7. **Controles escondidos** (`help.visible = false`) e título "ALPHA 0.17". Barra de controles reposicionada acima do Fôlego; título atualizado.
8. **Código morto** `_add_character_details` copiado no jogador e no inimigo (o do inimigo referenciava "Bastiao"). Removido.
9. **Testes com `assert`** podiam passar mesmo com falha. Agora usam checagens explícitas e código de saída.

## Não corrigido (recomendações, em ordem de impacto)
1. **Ataque não mira no mouse.** O clique ataca na direção do último movimento. Em ARPG, mire por raycast câmera→plano do chão.
2. **Navegação não foi baked.** Inimigos andam em linha reta e podem prender em paredes. Crie `NavigationRegion3D` antes de mais mapas.
3. **Slain não é restaurado e a posição não é salva.** Carregar no meio do Bairro respawna os inimigos. Decida se é checkpoint (aceitável) ou salve o estado dos inimigos.
4. **`hybrid_world.gd` (22 KB) faz tudo:** mundo, UI, save, loja, quests. Separe em cenas e scripts por responsabilidade antes da vertical slice.
5. **Dois sistemas de save e dois jogos:** `scripts/save_repository.gd` e `main.gd` (2D legado) não são usados pelo mundo 3D. Mova o legado para uma pasta `legacy/` e use um único save versionado com migração.
6. **Salvar com `rename_absolute`:** confirme no Windows que sobrescreve o arquivo existente; mantenha um `.bak`.
7. **Loot com só 4 itens, sem afixos**, e itens duplicados equipáveis. Expanda o catálogo e use `rng` com seed para testes.
8. **UI:** painéis de habilidades e loja em posição fixa (sobrepõem a mochila); mochila só com botões de texto, sem arrastar, desequipar ou ícones. Considere `stretch/aspect="expand"` para telas ultrawide.
9. **Mundo:** chão de 34×34 sem borda nas entradas da muralha (personagem sai para o vazio); `ground_stone.png` (1,7 MB) não é referenciado por nenhum script ou cena.
10. **Versão da engine:** alinhe `config/features` com a versão realmente usada e confirme que 4.7.2 existe antes de anunciá-la.
