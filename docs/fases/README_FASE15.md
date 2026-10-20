# Fase 15 — Tooltip de equipamentos

**Mudanças delimitadas:** um componente visual `AethelItemTooltip` integrado à grade existente da Fase 14. Não houve mudança nos saves, catálogo ou cálculo de atributos.

## Teste manual

1. Importar `project.godot` na versão da Godot utilizada no projeto.
2. Jogar, obter um item e abrir inventário com I.
3. Passar mouse sobre item: conferir nome, raridade, nível, tamanho, preço e modificadores.
4. Aproximar cursor de cada margem da janela: painel deve continuar visível.
5. Fechar/reabrir inventário e equipar um item: não deve ficar tooltip preso.

**Não homologado:** a engine não está instalada no ambiente de geração; parser e execução precisam ser validados pelo usuário.

A tooltip usa o modelo real `AethelItemInstance` / `AethelItemData`, sem `/root/HUD` e sem atributos `meta`.
