ECHOES OF AETHEL - US-01 - CANDIDATO DE DIAGNOSTICO
Nao homologado. PR #18 Draft. G2 depende do Product Owner.

Extraia todo o ZIP. Abra jogo/EchoesOfAethel-US01-Fix03R2-Windows-x64.exe.
Mantenha o arquivo .pck ao lado do .exe. Nao e preciso instalar Godot.
Windows x64; Godot 4.7.2.stable.official.ed1daf0bf; GL Compatibility.
Viewport 1280x720, stretch canvas_items/expand. Exportacao release-template,
sem assinatura, destinada exclusivamente a teste; nao e release comercial.

WASD/setas: mover. Mouse esquerdo: acao primaria. Mouse direito: secundaria.
E: interagir. Espaco: esquiva. Q: bloquear. F1-F3: habilidades.
1-4: pocoes. I/Tab: inventario. C: personagem. U: missoes. M: mapa.
H: ajuda. Esc: pausa. F5: salvar. F9: carregar.
Use F5/F9 com a janela do jogo em foco. F9 tambem e atalho de breakpoint
no editor; uma pausa incorporada ao editor precisa de diagnostico separado.
Saves normais: user:// da Godot; testes automatizados usam perfil isolado.

Valide menu, Novo Jogo, Vigilia, Maera, dialogo e transicao ao Bairro.
Confira inventario, tooltip, combate fora do hub, F5/F9 e retorno ao hub.
Teste 1280x720 e 1920x1080; relate erros com log e passos reproduziveis.
Nao ha aprovacao automatica de gameplay nem de desempenho por este pacote.

fonte/: projeto editavel. evidencias/: logs e hashes. MANIFEST-SHA256.json:
hashes dos arquivos empacotados. Licencas Godot em fonte/licenses/.
Licenciamento comercial dos assets do projeto ainda exige confirmacao do PO.
Consulte fonte/docs/US01_BASELINE_AUDIT.md para comandos e limitacoes.

FIX01: salve vivo com F5, morra e pressione F9. Confira HP, posicao,
modelo em pe, movimento, ataque, habilidades e itens/missao preservados.
Save de HP zero deve permanecer em derrota.

FIX02: confira deteccao apenas com visao, busca da ultima posicao,
contorno de pilares e ausencia de dano atraves de paredes.
Fix01 deve continuar funcionando. Homologacao grafica pendente do PO.

FIX03: ancoras somente fora de combate (chase/search/attack).
Nova ameaca fecha o menu; mundo ativo, sem imunidade.
Fechar/Esc restituem controles. Fix01/Fix02 preservados.

Fix03R1: viagem bloqueada por 5 segundos monotônicos após dano efetivo de inimigo; dano ambiental não arma a janela. Menu fecha ao receber dano inimigo; hit com ameaça ativa também bloqueia. Homologação G1/G2 pendente do PO.

Fix03R2: o menu explica quando nenhum outro destino foi descoberto. Recusas de viagem informam descoberta, origem, distância, obstrução, progressão ou transição. Regras de combate e dano preservadas. G2 ainda depende de homologação do PO.
