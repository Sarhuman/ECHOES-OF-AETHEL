# Matriz de identidade multissensorial — 15 mapas

**Requisito de produção, não implementação.** Identificar cada região por silhueta, materiais, iluminação, sons, habitantes e uma mecânica exclusiva. Total fechado: 15 mapas, exatamente 3 dungeons (`map_04`, `map_08`, `map_15`).

| ID / Região | Arquitetura característica | Iluminação e paleta | População / ameaças | Mecânica |
|---|---|---|---|---|
| 01 Vigília | arcos góticos e praça do sino | âmbar `#ff9d42` e névoa azul | Maera, Teren, Doma; hub seguro | sino reage a flags de missões |
| 02 Bairro que Faltava | duas épocas na mesma rua | janelas quentes e fendas lilases | Rasuras, testemunhas | encontrar três âncoras |
| 03 Pátio dos Endereços | marcos postais e bússolas inscritas | cobre oxidado e azul | Vigias do Mapa | inscrições revelam trajetos |
| 04 Arquivo das Portas Seladas | estantes monumentais, papel, ferro | luar `#4b547a`, poeira dourada | Porteiro, Rasuras Literárias propostas | duas chaves e inscrições `Decal` |
| 05 Estrada dos Retornos | carroças e sinais contraditórios | cinza e púrpura | Coletores de Restos | rotas sob efeito de manifestos |
| 06 Cais de Sal | guindastes, docas, armazéns | turquesa e fogo | Lira, Iven; hub | contratos e comércio reativos |
| 07 Estaleiro de Vidro | cascos transparentes e pontes | aço azul e âmbar | vigias, ecos de tripulação | pontes de carga móveis |
| 08 Porão da Travessia Nula | quilha e cristais em madeira úmida | violeta e turquesa | Almirante, Fantasmas de Sal propostos | cristais destrutíveis |
| 09 Várzea das Promessas | canais e lavouras de épocas distintas | oliva cinza e auroras | Testemunhas Partidas | ciclos ambientais |
| 10 Jardim de Cobre | árvores metálicas e pergolados | cobre e verde | Sive, moradores; hub | NPC reage ao save |
| 11 Pomar dos Nomes | árvores e placas nominais | dourado e cinza | Não-Nascidos | rastrear relações |
| 12 Estufa das Causas | estufas e engrenagens | verde e bronze | Jardineiro das Causas | arena com máquinas |
| 13 Fenda dos Registros | avenidas cortadas, livros de pedra | gelo azulado e violeta | Conclave | rotas mudam por decisões |
| 14 Observatório da Linha Única | lentes, cúpulas e relógios | prata e azul frio | Iro Sen, Conclave | alinhamento de lentes |
| 15 Atlas do Nunca | passarelas suspensas e relógios estáticos | violeta e magenta | Cartógrafo, Ecos de Bastiões Caídos propostos | colapso territorial telegráfico |

## Regras de qualidade

- `Decal` é o nome do nó Godot; seu uso depende de renderizador/material.
- Cristais, portas e plataformas devem ter estados previsíveis, aviso antes do perigo e saída segura.
- Configurações de NPCs dependem de flags persistidas, nunca de sorteio ao carregar.
- Luzes não podem ocultar ataques, saídas ou a distinção entre piso sólido e vazio.
- A vertical slice obrigatória é `map_01` → `map_02` → `map_04`; map_08 e map_15 aguardam aprovação desse marco.
