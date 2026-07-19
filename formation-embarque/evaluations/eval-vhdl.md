# Évaluation pratique — VHDL (2 h 30, sur simulateur)

> Épreuve sur https://www.edaplayground.com (GHDL) ou GHDL local.
> Documents autorisés. Rendu : les `.vhd` + le **journal de simulation**
> (copie de la console) + 2 captures de chronogrammes annotées.
> Spécificité VHDL : **le testbench vaut autant que le design** — c'est la
> discipline du métier FPGA.

## Sujet — Générateur d'impulsion calibrée (« one-shot »)

Concevoir `oneshot` : sur un front montant de `declencher`, la sortie
`pulse` passe à '1' pendant **exactement N cycles** (N = generic, défaut
10), puis retombe. Les re-déclenchements pendant l'impulsion sont
**ignorés** (non re-déclenchable).

```vhdl
entity oneshot is
    generic ( N : natural := 10 );
    port ( clk, declencher : in std_logic;
           pulse : out std_logic );
end entity;
```

## Travail demandé et barème

| # | Livrable | Points |
|---|---|---|
| 1 | Détecteur de front interne (2 bascules — `declencher` est déjà synchrone, on ne demande PAS le synchroniseur) | /3 |
| 2 | FSM ou compteur : `pulse` haut N cycles **pile** (vérifié au curseur) | /5 |
| 3 | Non-redéclenchement : un 2ᵉ front pendant l'impulsion ne prolonge rien | /3 |
| 4 | **Testbench auto-vérifiant** : ≥ 4 `assert` (largeur exacte, repos avant/après, re-déclenchement ignoré, second tir possible après retombée) | /6 |
| 5 | Chronogramme annoté : largeur mesurée aux curseurs + retour ligne | /2 |
| 6 | Zéro `wait for` dans le design (simulation seulement), zéro latch | /1 |

**Seuil : 14/20.** Éliminatoire : un design qui ne passe pas son propre
testbench, ou un testbench qui ne teste que le cas nominal.

## Questions orales de soutenance (5 min, ajustent ±2)

1. Ton compteur compte de 0 à N−1 ou de 1 à N ? Montre au chronogramme
   pourquoi ta borne donne exactement N cycles.
2. Que synthétise ton détecteur de front ? (dessine les 2 bascules + la
   porte).
3. Si `declencher` venait d'un bouton physique, que faudrait-il ajouter
   et pourquoi ? *(synchroniseur + anti-rebond — cours 04 §4.2/TD 04.)*
