# Echoes of Aethel

**ARPG de fantasia estranha e sombria**, projetado para **Godot 4.7.2**, com perspectiva top-down oblíqua e evolução planejada para apresentação híbrida 2.5D.

## Nova direção narrativa

Aethel está sendo invadida por consequências de decisões que nunca foram tomadas. O jogador é um Restaurador capaz de estabilizar realidades contraditórias, mas cada reparo apaga uma memória verdadeira. O eixo dramático é **quem decide o que tem direito de existir**.

Leia a [bíblia narrativa v2](docs/NARRATIVE_BIBLE.md) para premissa, personagens, regras de mundo, campanha de quatro atos e o recorte jogável.

## Estado do código

Este repositório continha apenas um README quando a nova documentação foi preparada. **O protótipo Godot da Fase 5 ainda não foi publicado aqui**; a documentação não deve ser confundida com uma build executável. O próximo passo técnico é importar o projeto testado, validar licença e origem dos assets e executar testes na versão instalada da engine.

## Critérios para a próxima entrega

1. Versionar o projeto Godot real e uma cena principal que abre sem erros de parser.
2. Confirmar compatibilidade com Godot 4.7.2 via importação e execução local.
3. Trocar os elementos narrativos do protótipo por dados, preservando lógica de combate e saves legados.
4. Separar domínios de combate, missões, itens e persistência das cenas visuais.
5. Publicar screenshots e licença apenas depois da verificação de autoria e permissões de distribuição.

## Direção técnica

- Mundo: `Node3D`; movimento: `CharacterBody3D`; câmera: `Camera3D` ortográfica.
- Personagens: geometria 3D e/ou `Sprite3D` conforme protótipos; interface em `CanvasLayer`.
- Conteúdo narrativo externo ao código, com identificadores estáveis e migrações de save.
- Sem dependência de backend para o primeiro lançamento single-player.

> O nome do projeto é provisório para verificação de disponibilidade comercial.
