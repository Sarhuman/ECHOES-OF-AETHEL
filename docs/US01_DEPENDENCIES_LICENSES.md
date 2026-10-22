# US-01 — Dependências e licenças

Auditoria local de 22/10/2026; branch audit/us-01-baseline-godot-472.

| Componente | Evidência | Situação |
|---|---|---|
| Godot 4.7.2 e template Windows x64 | versão oficial ed1daf0bf; hash fixado nos scripts; licenses/GODOT_LICENSE.txt | MIT verificada no arquivo distribuído |
| Bibliotecas incorporadas à Godot | licenses/GODOT_COPYRIGHT.txt | atribuições distribuídas; termos por biblioteca nesse arquivo, sem presumir licença única |
| Código GDScript, cenas, JSON, shaders e UI | arquivos versionados inventariados em us01-inventory.json | procedência na branch; não foi localizada licença geral do projeto que autorize comercialização |
| PNG/SVG dos itens, NPCs e HUD | assets/; documentação histórica de validação | autoria/licença comercial não comprovada independentemente: confirmação do PO pendente |
| Fonte padrão da Godot | nenhuma fonte externa identificada em assets | dependência incorporada à engine, ver atribuições Godot |
| Addons, plugins, autoloads | não há pasta addons nem seção autoload em project.godot nesta baseline | nenhuma dependência externa desse tipo identificada |
| Ferramentas de build | PowerShell, Python stdlib, Git; GitHub Actions checkout@v4/setup-python@v5/upload-artifact@v4 | ferramentas de desenvolvimento; ações obtidas pelo CI, sem incorporar seus códigos ao jogo |
| Meshy, Blender, MakeHuman e modelos posteriores | ausentes desta baseline | não necessários ao build; nenhuma operação paga realizada |

Inventário completo por arquivo, tamanho e SHA-256: `evidencias/us01-inventory.json` no ZIP. O scanner inspeciona referências literais res:// em scripts/cenas/recursos/projeto; não substitui a execução para caminhos construídos dinamicamente. A referência res://bad.gd em test_phase24 é dado propositalmente inválido para testar rejeição de escolha persistida, não dependência ausente. Um caminho dinâmico é registrado separadamente.

Template externo necessário somente para reconstrução: tools/fetch_windows_template.py baixa e verifica o hash fixado. Engine: tools/fetch_godot.ps1 usa versão exata e hash de arquivo oficial. Usuário final precisa apenas de EXE e PCK juntos. O pacote usa listas de diretórios e arquivos para excluir .git, .godot, .tools, saves e credenciais; inclui apenas proveniência selecionada de ferramentas. Não é certificação de licença comercial dos assets nem auditoria jurídica.
