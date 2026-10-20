# Teste da Fase 20 estabilizada

Extraia o ZIP completo e abra `jogo/EchoesOfAethel-Fase20.exe`, mantendo o `.pck` na mesma pasta. Windows 64 bits, OpenGL 3.3; Godot já incluída no executável exportado.

1. No menu, teste Opções (tela cheia, volume e tecla E/F). Inicie Novo jogo. Continuar só fica disponível quando existe save.
2. Mova com WASD/setas e clique. O ataque por clique seleciona/persegue um inimigo; Shift+clique ataca parado. J é o ataque alternativo.
3. Ajuste a câmera com a roda do mouse. O tamanho inicial é 12, limitado entre 10 e 18. H abre/fecha a ajuda sem ocupar permanentemente o topo. Em Opções é possível desativar a memorização do zoom.
4. Procure Maera (marcador azul), use E/F e atravesse o portal roxo a leste com a mesma tecla.
5. No Bairro, derrote cinco Rasuras, incluindo a campeã. Teste Q com escudo, Espaço para esquiva e 1–4 para poções.
6. Clique nos drops ou use E/F perto deles. Alt revela todos os rótulos. Abra I/Tab e confira os itens na grade.
7. Clique em equipamento para equipar, ou no slot para desequipar. Confira dano/defesa em C. Aparências são placeholders geométricos cadastrados, com raridade individual por slot; acessórios não exigem visual.
8. Ao subir de nível, distribua atributos em C. Consulte as técnicas em K e execute com F1–F3 ou pela barra: agora executam diretamente. O botão direito repete a última técnica. Neste pacote as três técnicas existentes já estão liberadas para teste, inclusive em saves anteriores. F2 reduz dano por oito segundos; uma segunda pressão cancela sem reembolso nem reiniciar a recarga. Cada botão mostra Pronto, Ativa, Recarga, Sem Éter ou indisponibilidade.
9. Retorne ao portal após limpar a área e conclua a missão. Em Vigília, aproxime-se de Doma (avental, martelo e nome) e use E/F ou L; compre, equipe e venda pelo botão direito na mochila.
10. F5 salva; altere equipamento/ouro, pressione F9 e confira a restauração. O save v4 aceita v2/v3 e faz backup. Novo jogo não apaga o save anterior até você salvar.
11. Esc pausa a simulação. Teste Retomar, Salvar, Opções e Voltar ao menu; escolha Continuar. Após derrota, R inicia sessão nova.

## Conteúdo e limitações

Esta entrega é derivada do ZIP da Fase 20 e dos módulos das Fases 21/22. Use o novo **EchoesOfAethel-Fase20-Estabilizado-Windows-x64.zip**. Os pacotes anteriores não contêm estas correções.

Cenário geométrico compartilhado entre map_01/map_02; map_04 e campanha completa pendentes. Clique usa direção direta: ainda não existe NavigationMesh para contornar obstáculos automaticamente. Modelos, animações e emissão localizada são placeholders; sem rigs/arte/áudio finais. Outras quatro classes têm somente contratos de dados.

O pacote usa exportação Windows release da Godot 4.7.2, template oficial, sem assinatura ou instalador. Fonte editável em `fonte/`; documentação e logs em `evidencias/`.

Smoke automatizado do export: execute `EchoesOfAethel-Fase20.exe --headless --quit-after 120 -- --smoke-gameplay`. Esse argumento entra numa sessão nova apenas para conferir o carregamento; não salva.

As verificações automáticas e capturas gráficas não substituem um playtest humano completo. Registre mapa, ação, mensagem de erro e passos para reproduzir cada problema encontrado.

## Regressões específicas para conferir manualmente

- Clique na cabeça e no corpo da Rasura campeã, inclusive após alterar zoom. Deve selecionar o mesmo alvo, aproximar e atacar, sem buscar o ponto atrás dele. O jogo ainda não inclui um chefe de campanha; os testes exercitam também o rank Único grande do controlador existente.
- Clique repetidamente no alvo durante a aproximação. Segure Shift e clique para atacar sem deslocamento. WASD continua cancelando um comando anterior como controle explícito do jogador.
- Use F1 em alcance e confira dano/Éter/recarga. Com movimento ativo, o golpe interrompe o deslocamento anterior durante sua recuperação.
- Use F2, confira o círculo discreto da guarda e a redução de dano, pressione novamente para cancelar e confira a recarga. Deixe expirar naturalmente em outra tentativa.
- Use F3 com inimigos próximos em lados diferentes: é o Corte do Eco existente, dano 360° com raio 3,4 e custo 18 de Éter. A mira e o dano não dependem da animação.
- Gaste Éter e observe Sem Éter; use a poção do cinto. Uma tentativa bloqueada não deve cobrar recurso nem iniciar nova recarga.
- Confira Doma de perto e abra sua loja tanto com interação configurada quanto com L. A colisão e a área de interação pertencem ao NPC físico, não às peças do modelo.
