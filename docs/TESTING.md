# Teste da Fase 20.2 integrada

Pacote atual: `EchoesOfAethel-PreAlpha-Windows-x64.zip`, versão 0.20.2. Para validar o export, execute `tools/smoke_windows.ps1` no fonte após gerar o build. O script inicia o EXE com `-- --verify-build` e perfil isolado obrigatório, aguarda sua saída e exige `BUILD SMOKE: 10 checks, 0 failures`. Verifica menu, HUD, câmera, movimento, seleção de alvo grande, aproximação/ataque, F1–F3, interação de Doma e pausa. Este modo diagnóstico não altera a sessão normal.

Extraia o ZIP completo e abra `jogo/EchoesOfAethel-Fase20.exe`, mantendo o `.pck` na mesma pasta. Windows 64 bits, OpenGL 3.3; Godot jÃ¡ incluÃ­da no executÃ¡vel exportado.

1. No menu, teste OpÃ§Ãµes (tela cheia, volume e tecla E/F). Inicie Novo jogo. Continuar sÃ³ fica disponÃ­vel quando existe save.
2. Mova com WASD/setas e clique. O ataque por clique seleciona/persegue um inimigo; Shift+clique ataca parado. J Ã© o ataque alternativo.
3. Ajuste a cÃ¢mera com a roda do mouse. O tamanho inicial Ã© 12, limitado entre 10 e 18. H abre/fecha a ajuda sem ocupar permanentemente o topo. Em OpÃ§Ãµes Ã© possÃ­vel desativar a memorizaÃ§Ã£o do zoom.
4. Procure Maera (marcador azul), use E/F e atravesse o portal roxo a leste com a mesma tecla.
5. No Bairro, derrote cinco Rasuras, incluindo a campeÃ£. Teste Q com escudo, EspaÃ§o para esquiva e 1â€“4 para poÃ§Ãµes.
6. Clique nos drops ou use E/F perto deles. Alt revela todos os rÃ³tulos. Abra I/Tab e confira os itens na grade.
7. Clique em equipamento para equipar, ou no slot para desequipar. Confira dano/defesa em C. AparÃªncias sÃ£o placeholders geomÃ©tricos cadastrados, com raridade individual por slot; acessÃ³rios nÃ£o exigem visual.
8. Ao subir de nÃ­vel, distribua atributos em C. Consulte as tÃ©cnicas em K e execute com F1â€“F3 ou pela barra: agora executam diretamente. O botÃ£o direito repete a Ãºltima tÃ©cnica. Neste pacote as trÃªs tÃ©cnicas existentes jÃ¡ estÃ£o liberadas para teste, inclusive em saves anteriores. F2 reduz dano por oito segundos; uma segunda pressÃ£o cancela sem reembolso nem reiniciar a recarga. Cada botÃ£o mostra Pronto, Ativa, Recarga, Sem Ã‰ter ou indisponibilidade.
9. Retorne ao portal apÃ³s limpar a Ã¡rea e conclua a missÃ£o. Em VigÃ­lia, aproxime-se de Doma (avental, martelo e nome) e use E/F ou L; compre, equipe e venda pelo botÃ£o direito na mochila.
10. F5 salva; altere equipamento/ouro, pressione F9 e confira a restauraÃ§Ã£o. O save v4 aceita v2/v3 e faz backup. Novo jogo nÃ£o apaga o save anterior atÃ© vocÃª salvar.
11. Esc pausa a simulaÃ§Ã£o. Teste Retomar, Salvar, OpÃ§Ãµes e Voltar ao menu; escolha Continuar. ApÃ³s derrota, R inicia sessÃ£o nova.

## ConteÃºdo e limitaÃ§Ãµes

Esta entrega Ã© derivada do ZIP da Fase 20 e dos mÃ³dulos das Fases 21/22. Use o novo **EchoesOfAethel-PreAlpha-Windows-x64.zip**. Os pacotes anteriores nÃ£o contÃªm estas correÃ§Ãµes.

CenÃ¡rio geomÃ©trico compartilhado entre map_01/map_02; map_04 e campanha completa pendentes. Clique usa direÃ§Ã£o direta: ainda nÃ£o existe NavigationMesh para contornar obstÃ¡culos automaticamente. Modelos, animaÃ§Ãµes e emissÃ£o localizada sÃ£o placeholders; sem rigs/arte/Ã¡udio finais. Outras quatro classes tÃªm somente contratos de dados.

O pacote usa exportaÃ§Ã£o Windows release da Godot 4.7.2, template oficial, sem assinatura ou instalador. Fonte editÃ¡vel em `fonte/`; documentaÃ§Ã£o e logs em `evidencias/`.

Smoke automatizado do export: execute `EchoesOfAethel-Fase20.exe --headless --quit-after 120 -- --smoke-gameplay`. Esse argumento entra numa sessÃ£o nova apenas para conferir o carregamento; nÃ£o salva.

As verificaÃ§Ãµes automÃ¡ticas e capturas grÃ¡ficas nÃ£o substituem um playtest humano completo. Registre mapa, aÃ§Ã£o, mensagem de erro e passos para reproduzir cada problema encontrado.

## RegressÃµes especÃ­ficas para conferir manualmente

- Clique na cabeÃ§a e no corpo da Rasura campeÃ£, inclusive apÃ³s alterar zoom. Deve selecionar o mesmo alvo, aproximar e atacar, sem buscar o ponto atrÃ¡s dele. O jogo ainda nÃ£o inclui um chefe de campanha; os testes exercitam tambÃ©m o rank Ãšnico grande do controlador existente.
- Clique repetidamente no alvo durante a aproximaÃ§Ã£o. Segure Shift e clique para atacar sem deslocamento. WASD continua cancelando um comando anterior como controle explÃ­cito do jogador.
- Use F1 em alcance e confira dano/Ã‰ter/recarga. Com movimento ativo, o golpe interrompe o deslocamento anterior durante sua recuperaÃ§Ã£o.
- Use F2, confira o cÃ­rculo discreto da guarda e a reduÃ§Ã£o de dano, pressione novamente para cancelar e confira a recarga. Deixe expirar naturalmente em outra tentativa.
- Use F3 com inimigos prÃ³ximos em lados diferentes: Ã© o Corte do Eco existente, dano 360Â° com raio 3,4 e custo 18 de Ã‰ter. A mira e o dano nÃ£o dependem da animaÃ§Ã£o.
- Gaste Ã‰ter e observe Sem Ã‰ter; use a poÃ§Ã£o do cinto. Uma tentativa bloqueada nÃ£o deve cobrar recurso nem iniciar nova recarga.
- Confira Doma de perto e abra sua loja tanto com interaÃ§Ã£o configurada quanto com L. A colisÃ£o e a Ã¡rea de interaÃ§Ã£o pertencem ao NPC fÃ­sico, nÃ£o Ã s peÃ§as do modelo.
