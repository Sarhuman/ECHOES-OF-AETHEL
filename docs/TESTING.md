# Teste da Fase 27 — mundo inicial e HUD enxuta

Extraia EchoesOfAethel-Fase27-Windows-x64.zip inteiro em uma pasta nova. Execute jogo/EchoesOfAethel-Fase27.exe com o PCK ao lado. Fonte editável: fonte/project.godot. Engine Godot4.7.2.stable.official.ed1daf0bf; build pré-alpha Windows sem assinatura/instalador.

## Roteiro humano — pendente

1. Novo jogo: J/F1/F3 devem ser recusados em Vigília sem gasto. Fale com Maera, aceite explicitamente a investigação provisória e visite Doma. Equipamentos e comércio continuam disponíveis. Portal leste exige aceitação.
2. E/F no portal entra no Bairro. Confirme F1/F3 com dano e custo reais. O grupo especial fica distante da chegada. Explorar rota principal/desvios, baús, altar, poço, vestígio e Âncora. Retornar pelo portal sul deve restaurar a regra de zona segura.
3. Sair de novo e seguir ao portal nordeste do Bairro. O Pátio dos Endereços é a passagem obrigatória; não existe salto02→04. No Pátio, explorar terraço a leste pela escadaria visual com colisor de rampa. Subir/descer sem tremor, cliques errados ou queda. Observar pisos0/1 no minimapa.
4. Portal norte do Pátio leva ao Arquivo. Descobrir Âncora, abrir porta com E/F, percorrer corredor e alas, derrotar guardas e abrir recompensa uma única vez. Arena reservada, sem chefe/cutscene/decisão definitiva. Regressar Arquivo→Pátio→Bairro→Vigília e falar com Doma.
5. M alterna mapa compacto/ampliado/oculto. Só áreas exploradas e marcadores do piso ativo devem aparecer; legenda só no expandido. Status/XP e objetivo ficam à esquerda; menus I/C/U/H/Esc sob o minimapa; poções, F1–F3 e M2 na única barra inferior. Conferir cliques e atalhos e que Espaço continua esquivando depois de clicar habilidades. M2 repete a técnica escolhida.
6. I/Tab abre a mochila. Hover/foco abre tooltip estável, inclusive Escudo de Madeira/Eco de Vidro. Roda sobre o item ou PgUp/PgDn rola texto longo. Enter equipa/retira, M+setas+Enter move, Esc cancela; arraste fora da grade deve cancelar. Largar[Del] transfere a pilha inteira ao chão e permite recolher. Itens de missão/protegidos não podem ser largados; desequipe antes. Comparação usa deltas de itens, não DPS final.
7. F5/F9 no Arquivo/terraço: conferir região, altura, posição segura, mapa, porta, inventário, loot e âncoras. Recarregar duas vezes não repete recompensa. Salvar/recarregar após largar uma pilha deve manter uma única instância. Continuar no menu usa o save existente; Novo jogo não substitui até salvar.
8. Testar1280×720 e1920×1080, HUD85/100/110%, mouse e teclado. Observar sobreposição, nome da Âncora, torso de inimigos atrás de prédios, chão nas bordas, menus roláveis, áudio e derrota. Registrar região/coordenada de qualquer bloqueio. Três recursos e cinco canais de áudio mantêm dados reais.

WASD/setas ou clique: mover; clique/J: ataque; Shift+clique: parado; F1Golpe/F2Guarda/F3Eco; botão direito repete técnica; Qbloqueia; Espaçoesquiva;1–4poções; E/Finteração configurável; Lloja perto de Doma; Catributos; Ktécnicas; Udiário; Htodos os controles; Oloot; Altitens; rodazoom; Escpausa; Rnovo jogo após derrota. Inventário multicélula10×4 e cinco raridades preservados.

## Reprodução automatizada

```powershell
./tools/fetch_godot.ps1
python tools/fetch_windows_template.py
./tools/test.ps1 -GodotExe <caminho-do-Godot-console>
./tools/build_windows.ps1 -GodotExe <caminho-do-Godot-console>
./tools/smoke_windows.ps1
python tools/package_windows.py
```

O validador tools/validate_regions.gd confere grafo e chegadas;21 suítes usam perfis isolados via AETHEL_TEST_SAVE_DIR. Smoke do EXE:32 verificações de menu/gameplay/comércio/exploração/transições. A automação GUI usa inputs nativos e movimento real para o circuito, com inimigos neutralizados nessa fixture de inspeção. Bot e regressões exercitam combate separadamente. Capturas reais em docs/evidence/fase27-*.png; métricas locais em fase27-performance.json. Sem garantia de60FPS. Scripts não alteram o save pessoal durante testes.

Resultados e pendências: FASE27_VALIDATION.md. Arquitetura/limites: FASE27_WORLD.md, HUD_ENXUTA_FASE27.md. Sistemas anteriores: FASE24_NPCS.md e FASE25_EXPLORATION.md. Arte/sons/greybox iniciais, missão de Maera provisória, sem campanha definitiva. Automação e inspeção visual não são playtest humano: homologação humana completa continua pendente.
