# Echoes of Aethel — Fase 13

## Entrega experimental integrada

- Menu inicial funcional com Iniciar/Continuar e Sair.
- Inventário visual 10x4 aberto com **I**; itens de diferentes dimensões.
- Inimigos no Bairro que Faltava soltam itens físicos coloridos. **E** coleta o item mais próximo até 2,5 m.
- Clique em um item na mochila para equipar armas, escudos, anéis ou amuletos; bônus recalculam HP, Éter e dano e enviam sinais ao HUD.
- F5 salva e F9 carrega inventário, equipamentos e missão em `user://aethel_phase13_save.json`.
- Iluminação noturna com luz fria, tochas quentes, sombra direcional e névoa discreta.

## Limites honestos

- NÃO há 15 mapas implementados. Hub e Bairro ainda alternam estado de uma mesma cena experimental.
- O inventário visual não implementa drag-and-drop ou rotação de itens; clique equipa.
- Drops são gerados por um catálogo de quatro itens com pesos provisórios; raridades não equivalem a balanceamento final.
- Animações e personagens low-poly são procedurais e provisórios.
- Não houve execução real nesta máquina na Godot 4.7.2; fazer importação e teste de parser antes de publicar o código na `main`.
- Para manter o protótipo estável, movimento por clique e GridMap ficam para a próxima fase.

## Validação manual

1. Na Godot 4.7.2, importe `project.godot`, execute F5 e escolha Iniciar/Continuar.
2. Fale com Maera (E), atravesse o portal e derrote uma Rasura.
3. Aproxime-se do item no chão e pressione E; pressione I para abrir a mochila.
4. Clique em um item de equipamento e confira os globos de vida/éter.
5. Salve com F5, reinicie, e confirme que inventário e equipamento persistiram.
