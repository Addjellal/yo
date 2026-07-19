# Mini-TP VHDL — compteur avec enable sur EDA Playground (30 min)

**Plateforme** : https://www.edaplayground.com (compte gratuit requis pour
exécuter). Réglages : *Testbench + Design → VHDL*, *Tools & Simulators →
GHDL*, coche *Open EPWave after run* pour voir les chronogrammes.
**Alternative locale** : `ghdl` + `gtkwave` (voir
[`../../tp/tp2-fiches/seance-1.md`](../../tp/tp2-fiches/seance-1.md)).
**Prérequis** : cours 04 §3 (process synchrone) lu.

## Exercice — `compteur_a_trous.vhd`

1. Colle [`compteur_a_trous.vhd`](compteur_a_trous.vhd) dans la fenêtre
   **design** (droite) et [`tb_compteur_a_trous.vhd`](tb_compteur_a_trous.vhd)
   dans la fenêtre **testbench** (gauche). Dans *Top entity*, mets
   `tb_compteur`.
2. Complète les 3 trous du design : le reset synchrone, l'incrément
   conditionné par `en`, et le drapeau `plein` (combinatoire, hors process).
3. *Run*. **Résultat attendu dans le journal :**

```
tb_compteur.vhd:XX:9:@...:(report note): MINI-TP VHDL : TOUS LES TESTS PASSENT
```

Si un `assert` échoue, son message te dit quel comportement est faux
(reset ? enable ? enroulement 15→0 ?). Ouvre EPWave et regarde `cpt` au
front d'horloge fautif — lire le chronogramme EST l'exercice.

**Les 3 pièges visés** (cours 04 §3) :
- le reset doit être **dans** le `if rising_edge` (synchrone) ;
- sans `en`, le compteur ne doit **pas** bouger ;
- `plein` est du **combinatoire** : une affectation concurrente, pas un
  process — et surtout pas une bascule de plus.
