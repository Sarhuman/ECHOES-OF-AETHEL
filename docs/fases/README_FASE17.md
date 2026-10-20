# Fase 17 — Correção visual verificável (Godot 4.x)

Esta atualização corrige o posicionamento explícito dos globos nos cantos inferiores, reposiciona o inventário no centro da viewport e troca os blocos aleatórios da praça por uma composição procedural com muralhas, pilares, pedestal, caminho livre, tochas e pavimentação de pedras. **Não é um mapa final com arte de produção.**

## Testar

1. Extraia em **pasta nova**, importe `project.godot` na Godot e aguarde importação.
2. Inicie o jogo no menu; confirme **globo vermelho à esquerda, azul à direita, Fôlego no centro**.
3. Aperte `I`: a janela central 10x4 deve aparecer, mesmo com zero itens.
4. No Bairro que Faltava, derrote Rasuras, colete itens com `E`, reabra `I` e confira nomes nas células. O loot é sorteado, não garantido por inimigo.
5. Redimensione a janela e confirme que os globos seguem visíveis.

## Limites de validação

ZIP conferido e arquivos revisados estaticamente. A Godot **não está instalada** neste ambiente, então o parsing e execução ainda exigem teste local. As mudanças de arquitetura do mapa ainda são compartilhadas entre as duas regiões; a separação de cenas permanece pendente. Não publicar como build homologada.
