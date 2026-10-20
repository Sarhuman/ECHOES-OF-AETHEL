# Fase 20 — aproximação do ritmo e das regras de um ARPG clássico

Objetivo: aproximar a **jogabilidade** de Diablo II: Resurrected usando mecânicas padrão do gênero, com nomes, itens e lore próprios (nada de assets ou nomes do jogo original).

## O que foi implementado (e testado na Godot 4.4.1 headless)
1. **Câmera dimétrica 30°/45°** (pitch 30°, yaw 45°) e WASD alinhado à tela.
2. **Controle por mouse:** clique move (segurar segue o cursor), clique em inimigo persegue e ataca, Shift ataca parado, botão direito usa a habilidade selecionada, clique em item pega.
3. **Itens com afixos:** qualidade Normal / Mágico (azul, 1–2 afixos) / Raro (amarelo, 3–4 afixos, nome gerado) / Único (dourado, afixos fixos). 22 afixos (prefixos e sufixos), 23 tipos-base em 9 slots, 5 únicos, 6 poções. Chance de itens mágicos (magic find) aumenta qualidade.
4. **Requisitos de equipamento** (nível, Força, Destreza), 11 slots (dois anéis), equipar/desequipar pela mochila, troca devolve o item anterior.
5. **Atributos:** Força, Destreza, Vitalidade, Energia; 5 pontos por nível; Vida = 55 + 4·Vit; Éter = 10 + 1,5·Ene; dano = arma × (1 + Força/100 + %dano); defesa; chance de bloquear com a fórmula clássica (bloqueio × (Dest − 15) / (2·nível)).
6. **Acerto e defesa:** chance de acertar depende de precisão, defesa e níveis (fórmula clássica 2·AR/(AR+DEF) · nívelA/(nívelA+nívelB), 5%–95%).
7. **Monstros com nível e rank:** Normal, **Campeão** (nome azul, 2,6× vida, 4× XP, item mágico garantido) e **Único** (dourado, 5× vida). Recuo ao ser atingido, golpe com aviso de 0,4 s, separação entre inimigos. Barra do alvo no topo da tela.
8. **Loot no chão:** rótulos coloridos por qualidade (mágicos e melhores sempre visíveis; comuns com Alt ou ao passar o mouse), ouro em pilhas, poções.
9. **Cinto de poções** (4 slots, empilha até 4) com teclas 1–4; **loja** com estoque gerado, compra e venda; **ficha do personagem** (C) com distribuição de pontos; barra de XP; habilidades no botão direito com custo de Éter.
10. **Save v3** com afixos, equipamento, cinto e atributos; migração de saves v2; backup `.bak`.

## O que ainda NÃO existe (honestidade)
Portal de cidade, waypoints, baú, penalidade de morte, dificuldades Pesadelo/Inferno, resistências e dano elemental, conjuntos, runas/sockets, mais classes, atos e chefes, automapa, animações e arte reais, áudio e navegação por pathfinding (NavigationMesh não gerada). A interface foi verificada por testes de runtime, **não visualmente**: faça o playtest e ajuste posições e tamanhos.

## Balanceamento
`tests/balance_bot.gd` joga o Bairro que Faltava 10 vezes: vitória em ~16–24 s usando 0–2 poções (a área inicial está fácil; aumente nível ou quantidade de inimigos quando houver mais conteúdo).

## Próximos passos de maior impacto
1. Gerar `NavigationRegion3D` para cliques com pathfinding e inimigos que contornam obstáculos.
2. Portal de cidade + baú + penalidade de morte.
3. Dano elemental e resistências (e afixos correspondentes).
4. Mais mapas (Fase 21+) e um chefe com 3 fases legíveis.
5. Substituir modelos procedurais e adicionar áudio de impacto, pois isso define o "peso" do combate.
