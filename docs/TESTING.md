# Teste da Fase 27.3 — Vigília modular e pipeline Summer

Extraia EchoesOfAethel-Fase27.3-Windows-x64.zip inteiro. Execute jogo/EchoesOfAethel-Fase27.3.exe com o PCK ao lado. Summer Engine não é necessário para jogar: o executável usa Godot oficial. Fonte em fonte/project.godot. A nova apresentação de Vigília é inicial e aguarda revisão artística humana.

Conferir praça, torre/sino, oficina de Doma, Maera, Âncora e saída leste. Testar clique/aproximação, E/F, loja e inventário; aceitar a investigação, visitar Bairro e retornar; F5/F9 deve preservar posição, loot, serviços e exploração sem migração. Ataques ofensivos continuam bloqueados no hub. Repetir720p/1080p e observar telhados se tornando translúcidos sem alterar colisão. Interiores de fachadas não foram implementados.

Rollback de desenvolvimento: definir aethel/world/vigilia_variant como GREYBOX em Project Settings e recarregar região/projeto. SUMMER recupera a nova apresentação. Nenhum modo é gravado no save. Não mudar câmera global ou posição de NPCs para mascarar problemas.

Regeneração pelo Summer e teste isolado em FASE27_3_SUMMER_PIPELINE.md; layout em FASE27_3_VIGILIA_LAYOUT.md; medições/limites em FASE27_3_VALIDATION.md. As rotinas de build/test/package abaixo agora produzem Fase27.3:26 suítes e smoke Windows38 verificações, conforme logs finais.

Playtest humano completo permanece pendente. As instruções históricas seguintes continuam úteis ao gameplay; para este pacote usar o EXE Fase27.3.

---

# Teste da Fase 27.2 — pipeline visual do Bastião

Extraia EchoesOfAethel-Fase27.2-Windows-x64.zip e execute jogo/EchoesOfAethel-Fase27.2.exe com o PCK ao lado. O Bastião continua o PLACEHOLDER anterior por padrão. Nenhum modelo artístico externo final está disponível. Fonte editável: fonte/project.godot; especificação externa em art/source/bastiao/PRODUCTION_SPEC.md.

A seleção IMPORTED_MODEL da definição de produção sem candidato deve voltar ao placeholder. Para testar o pipeline no editor, atribua explicitamente bastion_fixture_visual.tres ao adaptador de apresentação e chame select_mode("IMPORTED_MODEL") em ferramenta de desenvolvimento; a fixture azul é TEST ONLY, nunca personagem final. Alterar a seleção não deve alterar HP/Éter/Fôlego, equipamentos, cápsula, timers, posição ou save v6. Rever FASE27_2_PIPELINE.md e FASE27_2_VALIDATION.md antes de promover um asset externo.

Não ativar candidato acima do orçamento como padrão sem aprovação explícita. Homologação humana de arte e gameplay permanece pendente. Os roteiros seguintes continuam aplicáveis ao gameplay preservado; onde mencionam o EXE Fase27, usar Fase27.2 nesta entrega.

---

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
