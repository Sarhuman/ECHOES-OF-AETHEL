# Mockups funcionais — UX e level design

Mockups **textuais**, não screenshots de implementação. Orientação top-down oblíqua, câmera ortográfica 3D, UI em CanvasLayer.

## Tela principal (16:9)

```text
┌────────────────────────────────────────────────────────────────┐
│ ECHOES OF AETHEL                          [CONTINUAR] [OPÇÕES] │
│                                                                │
│                 PRAÇA DOS SINOS / NOITE                        │
│               [restaurador diante da torre]                   │
│                                                                │
│  NOVO JOGO                                                     │
│  CONTINUAR                                                     │
│  CRÉDITOS                                                      │
└────────────────────────────────────────────────────────────────┘
```

## HUD de exploração

```text
┌────────────────────────────────────────────────────────────────┐
│ [REGIÃO / checkpoint]                   [MISSÃO ATIVA / ETAPA] │
│                                                                │
│                 [CENA 3D + SPRITES 3D]                        │
│                                                                │
│ [HP] [ÉTER] [FÔLEGO]             [1] [2] [3] [4] [Q] [I]     │
└────────────────────────────────────────────────────────────────┘
```

## Layout conceitual: mapa 02 — Bairro que Faltava

```text
                    NORTE
       ┌────────── PORTÃO SELADO ──────────┐
       │     [arena opcional]   [segredo]  │
       │            │               │      │
       │ [placa]── PRAÇA ── [livro]        │
       │            │                      │
       │       [sino rachado]              │
       │            │                      │
       └────── ENTRADA DE VIGÍLIA ─────────┘
```

## Layout conceitual: dungeon 04 — Arquivo das Portas

```text
 ENTRADA -> HALL -> [CHAVE A] -> BIBLIOTECA
                \                 |
                 -> [CHAVE B] -> CHECKPOINT -> ARENA PORTEIRO -> SAÍDA
```

## UI / acessibilidade

- Escala de interface configurável; cores de raridade acompanhadas por texto/ícone.
- Telegraphs de ataque distinguíveis sem depender somente de cor.
- HUD não cobre o personagem em resolução 1280×720; navegação por teclado e controle em fase posterior.
- Menu de pausa, opções de áudio e remapeamento de teclas antes de alpha público.
