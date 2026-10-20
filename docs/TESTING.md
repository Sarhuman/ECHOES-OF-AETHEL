# Teste da versão consolidada

Extraia o ZIP completo e abra `jogo/EchoesOfAethel-Fase20.exe`, mantendo o `.pck` na mesma pasta. Windows 64 bits, OpenGL 3.3; Godot já incluída no executável exportado.

1. No menu, teste Opções (tela cheia, volume e tecla E/F). Inicie Novo jogo. Continuar só fica disponível quando existe save.
2. Mova com WASD/setas e clique. O ataque por clique seleciona/persegue um inimigo; Shift+clique ataca parado. J é o ataque alternativo.
3. Procure Maera (marcador azul), use E/F e atravesse o portal roxo a leste com a mesma tecla.
4. No Bairro, derrote cinco Rasuras, incluindo a campeã. Teste Q com escudo, Espaço para esquiva e 1–4 para poções.
5. Clique nos drops ou use E/F perto deles. Alt revela todos os rótulos. Abra I/Tab e confira os itens na grade.
6. Clique em equipamento para equipar, ou no slot para desequipar. Confira dano/defesa em C. Aparências são placeholders geométricos cadastrados, com raridade individual por slot; acessórios não exigem visual.
7. Ao subir de nível, distribua atributos em C e desbloqueie habilidades em K. Selecione com F1–F3 ou pela barra e use o botão direito.
8. Retorne ao portal após limpar a área e conclua a missão. Em Vigília, aproxime-se de Doma e use L; compre, equipe e venda pelo botão direito na mochila.
9. F5 salva; altere equipamento/ouro, pressione F9 e confira a restauração. O save v4 aceita v2/v3 e faz backup. Novo jogo não apaga o save anterior até você salvar.
10. Esc pausa a simulação. Teste Retomar, Salvar, Opções e Voltar ao menu; escolha Continuar. Após derrota, R inicia sessão nova.

## Conteúdo e limitações

Esta entrega é derivada do ZIP da Fase 20 e dos módulos das Fases 21/22. Não use o pacote antigo `EchoesOfAethel-Teste-Windows-x64.zip` para avaliar este progresso.

Cenário geométrico compartilhado entre map_01/map_02; map_04 e campanha completa pendentes. Clique usa direção direta: ainda não existe NavigationMesh para contornar obstáculos automaticamente. Modelos, animações e emissão localizada são placeholders; sem rigs/arte/áudio finais. Outras quatro classes têm somente contratos de dados.

O pacote usa exportação Windows release da Godot 4.7.2, template oficial, sem assinatura ou instalador. Fonte editável em `fonte/`; documentação e logs em `evidencias/`.

Smoke automatizado do export: execute `EchoesOfAethel-Fase20.exe --headless --quit-after 120 -- --smoke-gameplay`. Esse argumento entra numa sessão nova apenas para conferir o carregamento; não salva.

As verificações automáticas e capturas gráficas não substituem um playtest humano completo. Registre mapa, ação, mensagem de erro e passos para reproduzir cada problema encontrado.
