# Teste da Fase 24 — NPCs, diálogos, comércio e progresso

Extraia todo EchoesOfAethel-Fase24-Windows-x64.zip em uma pasta nova. Abra jogo/EchoesOfAethel-Fase24.exe com o PCK ao lado. Fonte editável em fonte/project.godot; Godot 4.7.2.stable.official.ed1daf0bf. O export é pré-alpha, sem assinatura/instalador.

## Roteiro de playtest

1. Inicie Novo jogo. Mova com WASD/setas ou clique. Procure Maera (azul), interaja com E/F, aceite explicitamente a investigação provisória na resposta e atravesse o portal a leste para o Bairro. A região de teste compartilha geometria com Vigília.
2. Derrote Rasuras usando clique/J, F1 Golpe, F2 Guarda, F3 Eco; Shift+clique ataca parado. Q bloqueia com escudo, Espaço esquiva, 1–4 usam poções. R reinicia após derrota.
3. Observe loot no chão. Alt revela rótulos; clique ou E/F perto para coletar. Ouro soma diretamente. Poções abastecem primeiro o cinto e vão para a mochila quando ele enche. As 40 células aceitam itens de tamanhos diferentes.
4. Abra I/Tab. Confira ícone, moldura de raridade e quantidade em pilhas. Hover ou foco abre dados e comparação numérica. Roda do mouse sobre o item ou PgUp/PgDn com foco rola um tooltip longo. Os deltas mostram valores do item, não DPS final do personagem.
5. Arraste entre células vazias e sobre outro item para trocar. Solte fora da mochila, além do limite ou sobre um slot incompatível: estado anterior deve permanecer. Itens grandes precisam de área livre para toda a forma; não se troca um item por múltiplos itens.
6. Arraste para os slots: elmo, peitoral, luvas, botas, capa, arma principal, mão secundária, amuleto e dois anéis. Cinto e talismã legados permanecem funcionais. Slots com ✓ estão equipados. Joias não exigem modelos 3D.
7. Clique/Enter também equipa; clique/Enter no slot retira para o primeiro espaço livre. Arrastar do slot para a grade desequipa em posição exata. Sem espaço, a operação falha sem remover o equipamento. Uma arma de duas mãos exige mão secundária livre; os tipos-base atuais continuam de uma mão.
8. Pelo teclado, navegue com Tab/setas, use Enter para equipar/retirar. Com foco em um item da mochila, M inicia movimento; setas escolhem célula e Enter confirma. Esc cancela. Organizar usa as mesmas posições reais e preserva tudo se não conseguir reorganizar. Fechar ou I encerra a janela.
9. Confira dano/defesa na mochila e em C após equipar. Verifique o visual do Bastião para os sete slots procedurais cadastrados. Não há modelos finais nem visual falso para acessórios.
10. Encha o cinto e colete mais poções iguais: observe empilhamento até 20 na mochila. Clique na pilha para transferir uma unidade ao cinto; se cheio, a quantidade não muda. Venda com botão direito na mochila, com a loja de Doma aberta: a venda considera a pilha completa.
11. F5 salva. Altere posição/itens/equipamentos, depois F9 recarrega. Confira IDs, quantidades, posições, raridade e afixos. Novo jogo só substitui um save ao salvar. O caminho de produção é o user:// da Godot; testes usam AETHEL_TEST_SAVE_DIR isolado.
12. Esc abre pausa fora do modo de movimento de itens. Retorne a Vigília e interaja com Doma (avental/martelo) por clique ou E/F. Escolha Ver mercadorias; L é atalho perto dele. Confira compra/venda, comparação por hover/foco e rolagem do estoque. H abre ajuda; K técnicas; roda do mouse fora da UI ajusta câmera entre 10 e 18.

## Testes e build reproduzível

```powershell
./tools/fetch_godot.ps1
python tools/fetch_windows_template.py
./tools/build_windows.ps1 -GodotExe "$pwd/.tools/Godot_v4.7.2-stable_win64_console.exe"
./tools/smoke_windows.ps1
python tools/package_windows.py
```

O build executa tools/test.ps1 com quinze suítes e perfis separados. Para somente os testes, passe o mesmo GodotExe a tools/test.ps1. As suítes da Fase 23 preservam os testes de inventário e arraste nativo. As novas suítes test_phase24.gd e test_phase24_gui.gd exercitam NPCs, narrativa, comércio e persistência.

## Estado artístico e limites

43 ícones SVG próprios, explicitamente placeholders, em seis categorias. Armas, armaduras, joias e poções estão ligados ao catálogo real; materiais e objetos de missão têm definições reservadas e não foram introduzidos artificialmente nas recompensas atuais. Não há crafting, conjuntos novos, encaixes ou Sigilos. A comparação usa valores base e modificadores do item; não projeta o DPS final. Para anéis, compara o destino padrão de clique (primeiro livre, senão anel 1); arraste permite escolher anel 2.

Organização é determinística por área e ID, sem rotação de itens; pode recusar uma disposição difícil em vez de perder itens. Grades configuradas maiores usam scroll. Modelos/animações/áudio finais, navmesh e campanha completa continuam pendentes. Testes gráficos automatizados e inspeção de capturas não substituem playtest humano completo; registre mapa, ação, mensagem e passos de qualquer falha.


## Fase 24 — roteiro específico

1. Clique em Doma a distância: observe aproximação em direção a ele, parada e orientação. Tente cancelar com clique no chão, WASD e Esc; tente um caminho bloqueado pela oficina e reposicione quando houver mensagem.
2. Converse por E/F. Setas/Tab/Enter escolhem respostas sem mover o personagem. Esc encerra. Visite a resposta sobre oficina e registre a escolha; volte ao nó para ver a opção condicional.
3. Abra mercadorias, navegue/role a lista, confira saldo e comparação. Compre, abra I e venda com botão direito. Ouro insuficiente, mochila cheia, loja fora de alcance e objetos de missão devem impedir transação sem perder nada.
4. Com Maera, aceite a investigação explicitamente. Atravesse o portal, derrote cinco Rasuras, retorne e relate. Observe +60 ouro; repita conversa e F5/F9 para confirmar ausência de nova recompensa. Não é a conclusão canônica de Uma Porta para Ninguém.
5. Salve após comprar e fazer a escolha da oficina. Compre outro item, carregue: primeiro permanece adquirido, o segundo retorna ao estado do último save, estoque e saldo juntos. Confira escolha condicional preservada.
6. Repita em 1280×720 e 1920×1080. Verifique retratos provisórios, foco, rolagem e legibilidade. Confirme movimento/ataques/F1–F3 após fechar UI.

Automação adicional: test_phase24.gd verifica serviços reais e persistência; test_phase24_gui.gd injeta E/setas/Enter/Esc/L em ambas as resoluções. Rodar o segundo sem --headless e com AETHEL_CAPTURE_DIR gera capturas. A inspeção dessas capturas e os inputs automatizados não substituem o playtest humano acima, que continua pendente. Detalhes em FASE24_NPCS.md.
