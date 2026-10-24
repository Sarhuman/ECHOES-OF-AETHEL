# Fase 14 — Progressão e sistemas de campanha (experimental)

Esta entrega continua a Fase 13 com **XP/nível**, árvore de habilidades (K), Golpe Pesado (1), ferreiro de Vigília (L), ouro, navegação condicional de Rasuras e persistência v2.

## Controles e testes
- Elimine Rasuras no Bairro para ganhar 25 XP e 7 moedas por eliminação.
- Pressione K para abrir a árvore (um ponto por nível acima de 1). Compre Golpe Pesado e pressione 1 para gastar 10 Éter.
- Em Vigília aproxime-se de Doma, a figura castanha em (-9, 2), e pressione L para comprar. Comprar exige ouro e espaço livre.
- F5 salva, F9 carrega. O save v1 é lido; saves com versão futura não são interpretados.
- A navegação por NavMesh somente ativa caminhos quando um mapa de navegação já está sincronizado; o fallback ainda é perseguição direta. **NavMesh de produção ainda não está construída.**

## Limites de entrega
- UI de skills e comércio funcional mas provisória, sem ilustrações, descrição completa ou drag-and-drop.
- Guard e Corte do Eco possuem dados e pré-requisitos, mas ainda não executam efeitos.
- O shader de Ecos e AudioManager foram incluídos como módulos, não estão conectados ao gameplay (sem arquivos de áudio fornecidos).
- O conteúdo de mapas continua com o cenário experimental compartilhado dos mapas 01/02.
- Não houve execução do editor Godot neste ambiente; verificar GDScript e runtime localmente antes de merge.
- O código não foi enviado ao GitHub nesta etapa.

## Testes automatizados (a executar localmente)

`godot --headless --path . --script res://tests/test_rpg_systems.gd` testa XP, desbloqueio único, persistência de progressão, duplicação e ocupação de inventário. Não foi executado aqui: binário Godot ausente.
