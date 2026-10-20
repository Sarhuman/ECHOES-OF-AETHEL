# Fase 8 — Integração de assets Meshy / Godot 4.7.2

Foi preparada uma ferramenta local que organiza **8 exports FBX e suas texturas** sem sobrescrever arquivos existentes. O kit anterior era para Unity e não deve ser usado diretamente em Godot.

## Escopo real

- Manifesto de 8 assets (Bastião, Lobo, Machado, Escudo, Árvore, Rocha, Pilar e Piso);
- Extrator seguro com hashes SHA-256, modo dry-run e bloqueio de sobrescrita;
- Cena isolada `asset_inspection.tscn` para inspecionar pivô, orientação, escala e import;
- O protótipo jogável não foi substituído por modelos não validados.

## Procedimento

O pacote Godot com o manifesto, script e cena de inspeção foi disponibilizado no chat como `echoes_of_aethel_fase8_pipeline_godot.zip`. Para usá-lo, mantenha os 8 ZIPs originais Meshy em uma pasta e rode:

```powershell
python pipeline/stage_for_godot.py --archives "C:\Caminho\Dos\ZIPs" --project .
python pipeline/stage_for_godot.py --archives "C:\Caminho\Dos\ZIPs" --project . --apply
```

Depois abra a cena `scenes/asset_inspection.tscn` no Godot 4.7.2 e execute-a usando F6. Isso **não valida automaticamente** materiais, pivôs, rigging ou FPS. Conversão para GLB e otimização de malhas são pendências.

## Próximo passo

Importar o Cavaleiro otimizado, confirmar AnimationPlayer/AnimationLibrary, gerar Idle/Attack/Hit/Dodge/Death e substituir somente o nó visual do CharacterBody3D. Depois, integrar Maera e Rasuras, que ainda necessitam assets adequados.
