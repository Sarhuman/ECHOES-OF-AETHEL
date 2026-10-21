# Summer Engine → Godot oficial: fluxo verificado

## Ferramenta e acesso

Summer Engine0.7.3 instalado em C:/Users/Sarumano/AppData/Local/SummerEngine/current/Summer.exe; binário4.7.2.stable.mono.custom_build.487400890. É aplicativo externo, não addon Godot. O jogo continua na Godot oficial4.7.2/Compatibility e o build Windows usa o template oficial anterior.

O fluxo local por scripts headless é [documentado pelo fornecedor](https://docs.summerengine.com/automation/headless). Não utiliza Summer Agent, MCP, conta, serviços de geração ou créditos. O conector Summer não está exposto nesta sessão, mas não é necessário para este fluxo. Não houve substituição silenciosa por outra ferramenta: a criação de PackedScene/ArrayMesh foi executada pelo Summer instalado, e o resultado foi consumido/testado pela Godot oficial.

## Reprodução no computador do usuário

Na raiz do projeto Godot:

```powershell
./tools/build_summer_maps.ps1 -SummerExe 'C:\Users\Sarumano\AppData\Local\SummerEngine\current\Summer.exe' -Mode ISOLATED
$env:AETHEL_TEST_SAVE_DIR = Join-Path $PWD 'relatorios-fase20/profiles/summer-isolated-manual'
New-Item -ItemType Directory -Force -Path $env:AETHEL_TEST_SAVE_DIR
& 'C:\Users\Sarumano\Documents\Godot_v4.7.2-stable_win64_console.exe' --path . --script res://tests/test_phase27_3_isolated.gd --quit-after 2400 --log-file isolated-manual.log
./tools/build_summer_maps.ps1 -SummerExe 'C:\Users\Sarumano\AppData\Local\SummerEngine\current\Summer.exe' -Mode VIGILIA
```

Ajustar os caminhos dos executáveis em outra máquina. ISOLATED cria um projeto descartável em .tools/summer273 e produz piso, parede, vão de porta e rampa. O segundo comando deve rodar **sem --headless** para validar renderização e criar prova gráfica vinculada ao hash da cena. VIGILIA recusa execução sem prova aprovada da cena atual, ou se o binário Summer mudou desde o teste. Se qualquer etapa falhar, conservar GREYBOX; não importar a variante como padrão.

O wrapper impõe timeout de60s ao processo Summer, verifica marcador de sucesso e erros de script e grava versão/hash/procedência. Usa o executável escolhido, sem baixar/atualizar Summer. Não abre o projeto principal no editor Summer: apenas copia o script/layout para o sandbox e recebe recursos gerados. A biblioteca pode depois ser aberta manualmente para edição, conforme [authoring oficial](https://docs.summerengine.com/automation/authoring).

## Fontes, saída e formatos

- Fonte paramétrica original: art/source/vigilia/build_summer_scene.gd e layout.json.
- Saídas: art/imported/vigilia/integration_test.tscn, vigilia_summer.tscn, modules/*.tscn e materials/*.tres.
- Formatos efetivamente testados: .tscn/PackedScene, .tres/StandardMaterial3D, ArrayMesh, formas Box e NavigationMesh. A cena isolada preservou os nós físicos e a navegação no round-trip.
- Não foi testada exportação GLB/FBX/Blend pelo Summer, nem geração de assets de nuvem; não presumir que preserve esses fluxos. A editabilidade entregue é a de cenas/meshes Godot e seus scripts-fonte, não um arquivo Blender.
- IDs de nós e parâmetros são reproduzíveis; IDs internos de subresources e hashes de arquivo podem mudar ao salvar novamente. Logs/hashs identificam a geração realmente testada, não prometem binário idêntico entre versões.

A estrutura .tools e caches não entram no Git/pacote de fonte. As saídas nativas somam aproximadamente1,4MB, sem necessidade demonstrada de LFS nesta entrega. Os binários Summer/instalador não são redistribuídos. CI testa os recursos gerados na Godot oficial, sem instalar Summer proprietário.

O gerador/layout são a fonte paramétrica; regenerar substitui as saídas. Guardar alterações manuais em Git antes de regenerar. Edição topológica interativa no editor Summer não foi validada: o batching preserva ArrayMesh e grupos transformáveis, mas não mantém cada pedra/janela como primitivo individual. Não confundir essa editabilidade de recursos/fonte com modelagem Blender.

## Colisão e preservação do jogo

Somente integration_test.tscn contém colisão/navmesh própria, por ser fixture isolada. O cenário de Vigília contém apenas apresentação e duas luzes. O coordenador, AStar3D, NavigationRegion3D, exploração, NPCs e save existentes continuam autoritativos. A variante herda map_01 e mantém IDs/chegadas. Não migrar saves por arte. Nenhum dos demais mapas foi reconstruído.

## Procedência e licenças

Geometria, layout e materiais foram autorados por Codex nesta tarefa, executados no Summer local, sem downloads de modelos/texturas ou acervo de terceiros. LICENSE.txt da instalação lista desenvolvimento comercial/não comercial e restrições de redistribuição da engine; não atribuir a mesma licença a todo asset de loja ou IA.

As [licenças de assets Summer](https://docs.summerengine.com/art-system/licensing) são específicas por item; nenhum desses assets foi utilizado. Serviços hospedados e seu licenciamento comercial não foram validados nesta entrega. Não há runtime Summer no executável entregue, que usa Godot oficial e seus notices existentes. Não se atribui aprovação jurídica ou artística automática aos recursos autorados.

## Limites

Fluxo local editável e interoperabilidade foram executados. Chat/Agent/MCP/cloud e exportação de executável pelo Summer: NOT_EXECUTED. Nenhum bloqueio impede o fluxo local comprovado. Operações que exijam a UI do editor/conta devem ser validadas separadamente; não afirmar que o Codex executou esses caminhos.
