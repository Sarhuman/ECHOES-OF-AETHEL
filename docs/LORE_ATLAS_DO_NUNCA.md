# O Atlas do Nunca — Compêndio da Realidade Porosa

> **Cânone literário proposto para Echoes of Aethel.** Esta obra documenta o mundo; não representa conteúdo já implementado na Godot. A origem de Aethel e seus finais seguem a Bíblia Narrativa v3, com os detalhamentos abaixo.

## I. A física do Eco e a dor do Restaurador

### Ruptura de Contingência

Aethel não sofreu um cataclismo de fogo ou pedra. O seu presente tornou-se incapaz de conter o acúmulo de consequências de escolhas não realizadas. As guerras recusadas, as cidades não fundadas e as travessias jamais iniciadas deixaram vestígios materiais, conservados nas margens da história. A tensão entre essas possibilidades e o presente rompeu a continuidade do mundo: a **Ruptura de Contingência**.

Cada **Eco** é uma consequência material de uma escolha que não aconteceu: tem peso, ocupa espaço, pode ferir e pode ser ferido. Não é um fantasma nem uma ilusão. Quando um bairro impossível aparece, os seus habitantes podem lembrar famílias, mortes e afetos que a história oficial não conhece. O mundo não tem meios simples de declarar que essas lembranças são falsas.

### Âncoras e estabilização

Cada Eco está associado a uma **âncora material**: um sino, carta, diário, pedra gravada, mapa ou outra coisa que conserva uma consequência rejeitada. Um Restaurador pode identificar a âncora e escolher entre formas de intervenção: destruí-la, selá-la ou estabelecer uma coexistência controlada, quando as condições da missão permitirem. Nem toda possibilidade oferece as três opções; nenhuma opção é gratuita.

A compensação da intervenção irreversível é a perda de uma **memória verdadeira e identificável** do Restaurador. A perda deve aparecer em narrativas, diálogo e diário. A amnésia não é uma barra genérica nem punição arbitrária de controles do jogador: é consequência dramática explícita, com testemunhas e persistência.

### Fragmento encontrado em Vigília

> “A praça é a mesma de ontem. O sino, não. Contou treze horas. Meu irmão jura que sempre foram treze; eu me lembro de doze. Um de nós está dizendo a verdade, e tenho medo de descobrir qual.”  
> — Caderno da zeladora dos sinos, registro sem data.

## II. Crônicas das três dungeons

### Crônica I — Arquivo das Portas Seladas (`map_04`)

> “Aqui jaz o conhecimento que incomodava o presente.”  
> — Inscrição do átrio.

O Arquivo nasceu como uma instituição de contenção: seus arquivistas reuniam mapas, cartas, endereços e registros de futuros proibidos. A política de confisco transformou a instituição em um cárcere de possibilidades. As estantes são tão altas que dividem o teto; os papéis cobrem passagens; fechaduras de bronze respondem a nomes que não foram pronunciados.

O **Porteiro das Portas Seladas** mantém o sistema que protege e aprisiona aqueles registros. As **Rasuras Literárias** são propostas de inimigos formados de tinta, papel e vontade de não desaparecer: projetam folhas cortantes e procuram reconstituir parágrafos apagados.

*Motivo jogável:* recuperar duas chaves documentais, escolher as passagens, enfrentar o Porteiro e decidir o destino do distrito. Poeira e papel voadores devem enriquecer a leitura sem encobrir saídas e ataques.

### Crônica II — Porão da Travessia Nula (`map_08`)

> “O sal preserva a carne, mas não absolve uma travessia.”  
> — Diário de bordo de uma viagem nunca iniciada.

Sob o Cais de Sal existe um navio que jamais deixou o porto. Em seus porões, madeira úmida e cristais disputam o espaço; o metal apodrece sob camadas de sal, e o teto ressoa com vozes que parecem vir de praias inexistentes. O **Almirante Sem Travessia** não comanda um exército de mortos: governa as consequências de uma expedição recusada.

Os **Fantasmas de Sal** e as **Rasuras Marinhas** são propostas de inimigos locais. Cristais que se quebram ao receber impacto alteram a arena e liberam caminhos, mas devem ter telegráficos e estados determinísticos para evitar bloqueios irreversíveis.

*Motivo jogável:* provar a origem dos manifestos, atravessar compartimentos modificáveis, derrotar a Almirante e decidir o destino dos registros de rota.

### Crônica III — Atlas do Nunca (`map_15`)

> “Não há tirano a derrotar. Há quem decida o que um mapa pode negar.”  
> — Nota atribuída a Iro Sen, autenticidade disputada.

O Atlas é uma catedral sem alicerces, suspensa sobre uma fratura de possibilidades. Plataformas de pedra conectam salas que lembram outras versões de Aethel. Relógios marcam horas nunca vividas; abaixo das fendas, luz violeta revela paisagens que não pertencem à mesma história.

O **Cartógrafo sem Norte** governa esse espaço de classificação e exclusão. Os **Ecos de Bastiões Caídos** são proposta de inimigos que reproduzem gestos de antigos Restauradores — sem implicar que o Bastião seja o único arquétipo existente. O antagonismo central permanece filosófico e material: quem recebe o poder de traçar os limites do real?

*Motivo jogável:* revisitar as consequências dos atos anteriores, reconhecer chão transitável, derrotar o Cartógrafo e decidir a organização futura das realidades.

## III. Três conclusões

As conclusões dependem das decisões anteriores; não são meras opções cosméticas ao derrotar o chefe.

- **Linha Única.** O mundo ganha estabilidade à custa do apagamento de possibilidades e de parte da identidade do Restaurador. A praça final pode conservar o sino e perder quem saberia contar a sua história.
- **Mundo Poroso.** Realidades incompatíveis coexistem sob acordos locais, com perigo, negociação e mudanças previsíveis. A vitória exige instituições e personagens capazes de sustentar a convivência.
- **Atlas Aberto.** O monopólio do mapa é rompido, e nenhuma autoridade central define quais futuros podem existir. A abertura produz incerteza e conflitos, não uma reinicialização automática do universo que invalide todas as escolhas anteriores.

A apresentação final deve consultar flags salvas e personagens afetados. Nenhum desfecho é declarado universalmente correto.

## IV. Diretrizes de implementação atmosférica (Godot 4.7.2)

A aparência gótica é resultado de **geometria, materiais, composição, iluminação, sons e narrativa ambiental**. Um filtro de cor sozinho não cria o mapa.

| Mapa | Fundo sugerido | Névoa inicial para teste | Luz fria proposta | Atenções |
|---|---|---:|---|---|
| `map_04` | `#07070f` | 0,05 | `#4b547a`, 0,12 | evitar perda de contraste em pergaminhos e telegráficos |
| `map_08` | `#020805` | 0,08 | `#1f3a2b`, 0,05 | testar visibilidade de plataformas e cristais |
| `map_15` | `#12021c` | 0,06 | `#8a2be2`, 0,20 | não confundir fenda decorativa com área caminhável |

Os valores são **hipóteses de arte** e precisam de calibração em jogo. `WorldEnvironment` e `Environment` podem definir perfil por zona, mas os mapas precisam de suas próprias luzes de destaque. Evitar duplicar `WorldEnvironment` por carregamento ou sobrescrever recursos compartilhados sem duplicação. `Decal` projeta marcas em superfícies compatíveis com o renderizador; não substituir colisão e malha por efeitos.

## V. Entregáveis editoriais e verificações

- Manuscritos colecionáveis devem possuir ID estável, região, versão e condição de obtenção.
- O diário separa relatos encontrados, fatos confirmados e versões contraditórias.
- Decisões de dungeons registram `act1_district_fate`, `act2_manifest_fate` e `act3_sive_fate`, com migração de saves.
- Nomes e imagens passam por revisão editorial e de licenciamento antes de distribuição comercial.
- Esta documentação **não comprova** cenas finalizadas, NavMesh, chefes implementados ou build homologada.
