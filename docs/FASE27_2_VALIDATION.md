# Fase 27.2 — relatório técnico, 21/10/2026

## Marcos

- Pipeline técnico mínimo implementado e validado localmente.
- Integração visual de produção: **PENDENTE**, nenhum modelo externo adequado recebido.
- Aprovação artística e playtest humano: **PENDENTES**. Nenhum ART_APPROVED.
- Personagem jogável padrão continua o PLACEHOLDER anterior. Nenhuma câmera, cápsula, alcance, dano, custo, progressão ou esquema de save foi alterado para acomodar um modelo.

## Artefatos reais

Resource de produção bastion_visual.tres com fallback e candidato vazio; definição de fixture separada; seleção PLACEHOLDER/IMPORTED_MODEL no adaptador existente; validador estrutural e CLI; wrapper com BoneAttachment3D nas mãos e marcadores nome/vida/FX; mesmo adaptador de sete slots, com opção de preservar materiais autorados. Especificação externa completa e tabela de escala. Código Python editável e GLB de teste de 35.340 bytes, 80 triângulos, quatro ossos, um material, uma influência por vértice e 13 clipes esqueléticos de demonstração. Não foi produzido modelo humano final nem arquivo .blend.

GLB importado e validado no Godot 4.7.2.stable.official.ed1daf0bf / Windows / Compatibility. Fonte da fixture é Python 3.12.14 original incluído, não serviço externo. Consulte TEST_FIXTURE_PROVENANCE.md e ART_REGISTRY.md para limites de procedência e estado.

## Testes

23 suítes completas aprovadas em tools/test.ps1, incluindo as 21 anteriores, novo teste do pipeline e teste GUI. results.json e logs *-final.log são incluídos no pacote. O teste de integridade foi atualizado para a versão de artefato 0.27.2; não foi removido para contornar a troca de versão.

Teste específico final: **88 verificações, zero falhas**. Troca conserva recursos, estatísticas, cápsula, posição, inventário, equipamentos e timers; fallback para candidato ausente/inválido; sete slots; pose esquelética real; animações mapeadas; materiais compartilhados; rejeição de orçamentos excedidos, textura 2048, influências excessivas, escala não aplicada, socket ausente, orientação errada e procedência pendente. Tracks de método, alvos fora do modelo e translação de root bone são rejeitados. Testa F1/F2/F3 com custo/evento únicos, dano real em inimigo e recebimento de dano, save/load v6 sem campo novo de visual, morte e novo jogo após derrota. Não há sistema novo de respawn.

GUI headless: **12 verificações**. GUI gráfica: **34 verificações, zero falhas**, **22 PNGs reais** em evidence/fase27-2-*.png, frente/costas/perfil do placeholder e da fixture, movimento, ataque, golpe pesado, escudo e oclusão, em 1280×720 e 1920×1080. Capturas inspecionadas do viewport Godot, com legenda de teste; não são imagens geradas. Nas cenas novas de combate a IA não é desligada, não há invulnerabilidade imposta e colisões são mantidas; o inimigo alvo recebe HP maior e defesa zero na fixture para demonstrar o evento de dano com controle do roll. Isso ainda não é homologação humana do combate. As suítes gráficas históricas da Fase27 continuam com suas neutralizações documentadas.

Windows exportado e executado: **35 verificações aprovadas**, incluindo as 32 anteriores e três de pipeline. Verifica menu/gameplay, importação da fixture no PCK, procedência incorporada e retorno ao protótipo. Relatório da execução efetiva em release-smoke-final.log.

## Benchmark antes/depois

Mesmo hardware RX 580 2048SP, Compatibility, 1920×1080, Vigília/map_01, posição (-4;0;5), câmera original, personagem idle e física ativa. Teto 60 FPS, 30 frames de aquecimento e 180 medidos, execução no desktop sem isolamento de CPU/GPU. Não há inimigos no hub. Reproduzir com tools/profile_bastion.gd; JSONs fase27-2-baseline, after e fixture-profile em evidence.

| Medida | Antes, protótipo | Depois, padrão preservado | Fixture importada de teste |
|---|---:|---:|---:|
| Mediana ms/frame | 35,642 | 35,291 | 34,846 |
| p95 ms/frame | 41,467 | 41,927 | 41,802 |
| FPS pela mediana | 28,06 | 28,34 | 28,70 |
| Draw calls da cena | 267 | 267 | 217 |
| Primitivas renderizadas da cena | 68.800 | 68.800 | 42.864 |
| Memória de vídeo, bytes | 48.789.901 | 48.789.901 | 48.352.497 |
| Memória estática, bytes | 66.369.141 | 66.506.086 | 66.590.459 |

Primitivas do renderizador são uma medida da cena e seus passes, não triângulos únicos do personagem; a fixture tem 80 triângulos de malha. CPU de skinning isolada **NOT_MEASURED**: não há atribuição precisa por personagem nesta ferramenta. Custos individuais de shader/material também não foram isolados. Fixture usa um material simples sem texturas, sem representar o custo do futuro traje. Sem regressão relevante observada no cenário medido; variação pequena de tempo não comprova otimização. Não demonstra 60 FPS nem desempenho do modelo final ou da campanha.

## Limitações e próximo recurso necessário

Validação estrutural não comprova topologia adequada, pesos de qualidade, ausência de clipping em todas as poses, qualidade das animações, identidade artística ou direitos comerciais. Envelope de importação e dimensões artísticas continuam propostas, não cânone novo. Modelo externo, rig humano adequado, materiais/texturas, malhas dos sete slots, contatos reais de espada/escudo e clipes de produção seguem necessários conforme PRODUCTION_SPEC.md.

Avisos ambientais de certificados/cache/editor e avisos de encerramento de ObjectDB em algumas suítes legadas são preservados nos logs. Erros de desenvolvimento foram corrigidos; consultar somente validações finais para o estado entregue. Sem merge automático; PR Draft sobre feat/fase27-mundo, dependente do #15.
