# US-01 — Auditoria da baseline executável (em andamento)

**Status:** auditoria preliminar; **G1 não concluído**; G2 não iniciado. **Não homologado. Não realizar merge.**

## Escopo e origem

- Branch independente: `audit/us-01-baseline-godot-472`.
- Ponto de partida: `feat/fase27-mundo` (código experimental existente, **não** uma baseline já homologada).
- PR alvo: `main` em modo **Draft**.
- Esta seleção **não** aprova o gameplay da Fase 27 nem antecipa US-02 a US-12.
- Não introduzir o atalho map_02→map_04, novo custo narrativo ou habilidade do Bastião.

## Verificações realizadas (somente leitura da API GitHub)

- `project.godot` presente, com `run/main_scene="res://scenes/main_menu.tscn"` e recursos Godot 4.7/GL Compatibility.
- `scenes/main_menu.tscn` presente; referencia `res://src/ui/main_menu.gd` (**existência e integridade da referência ainda não verificadas**).
- `docs/FASE27_WORLD.md` e `docs/TESTING.md` presentes; descrevem quatro mapas experimentais, procedimentos e limitações.
- `.gitignore` exclui `.godot/`, `.tools/` e arquivos ZIP.
- Documentação anterior relata testes e métricas, mas **nenhum teste foi executado nesta branch durante a US-01**. Não atribuir aprovação atual a logs históricos.

## G1 — pendências bloqueantes

- [ ] Inventariar **todos** os arquivos, cenas, scripts, autoloads, dependências e licenças, incluindo assets de terceiros.
- [ ] Executar importação headless na Godot **4.7.2**, capturando stdout/stderr e código de saída.
- [ ] Executar validação de parsing/referências e a cena inicial, registrando logs e erros.
- [ ] Executar suítes automatizadas disponíveis ou documentar objetivamente impedimentos.
- [ ] Confirmar que instruções de execução funcionam em checkout limpo.
- [ ] Registrar arquivos integrados/alterados e limitações encontradas.
- [ ] Validar que o projeto não depende de artefatos locais ou ZIPs ausentes.

**Limitação do ambiente de auditoria atual:** o conector GitHub permite leitura/escrita de arquivos, mas não fornece execução da Godot nem checkout completo do repositório; a tentativa de acessar GitHub por git no ambiente de execução falhou por resolução de DNS. Portanto **não há logs de importação/execução válidos**, e o G1 permanece bloqueado até execução real em ambiente com Godot.

## Execução proposta no Windows do PO (não realizada)

1. Faça checkout da branch `audit/us-01-baseline-godot-472` em pasta limpa.
2. Abra `project.godot` na Godot **4.7.2** (registrar versão exata).
3. Antes de executar, capture o painel de erros/avisos da importação.
4. Execute a cena principal (F6/F5 conforme contexto) e capture o menu, erros do debugger e saída.
5. Em PowerShell, use o roteiro de `docs/TESTING.md` para testar scripts disponíveis **somente após conferir os caminhos e dependências**. Guarde os logs integrais.
6. Informe Windows, CPU, GPU, RAM, renderer, resolução, versão exata da Godot e comportamento observado.

**Importante:** essas capturas auxiliam a auditoria, mas não significam G2 automaticamente. O G2 exige homologação expressa do PO após G1 concluído.

## Inventário preliminar (incompleto)

| Item | Origem | Licença | Estado |
| --- | --- | --- | --- |
| Código Godot e cenas | `feat/fase27-mundo` | Não verificada | A auditar |
| UI e arte provisória | Branch de origem | Não verificada | A auditar |
| Assets externos | Não inventariados | Não verificada | A auditar |
| Godot 4.7.2 e templates | Dependência de ferramenta | Termos não revisados nesta auditoria | A verificar |

## Estado dos testes nesta US-01

- Testes automatizados executados: **nenhum**.
- Testes gráficos executados: **nenhum**.
- Parsing validado: **não**.
- Referências validadas: **não**.
- Compatibilidade de assets/licenças: **não**.
- G1: **não aprovado**.
- G2: **não aprovado**.
- Merge: **proibido até autorização expressa e separada do PO**.
