# Mini-TP C — bits et machine d'états (2 × 20 min)

**Plateforme** : https://www.onlinegdb.com (langage : C) — colle le fichier,
bouton *Run*. Aucune installation.
**Prérequis** : cours 01 §3.2 (bits) et §12 (FSM) lus.

---

## Exercice 1 — `bits_a_trous.c` (20 min)

Colle [`bits_a_trous.c`](bits_a_trous.c) dans OnlineGDB et complète les
4 trous (set, clear, toggle, extraction de champ).

**Résultat attendu à l'exécution :**

```
1) apres SET bit 3    : 0x08
2) apres CLEAR bit 3  : 0x00
3) apres TOGGLE x2    : 0x40 puis 0x00
4) champ MODE         : 3
TOUS LES TESTS PASSENT
```

Si un test échoue, le programme affiche la valeur obtenue : compare-la en
binaire avec l'attendu (papier !) avant de retoucher le code.
En cas de blocage > 10 min : cours 01 §3.2, puis solution dans
[`../../code/c/bits.c`](../../code/c/bits.c) (l'esprit, pas le copier-coller).

## Exercice 2 — `fsm_a_trous.c` (20 min)

Une mini machine d'états de porte (FERMEE → OUVERTURE → OUVERTE →
FERMETURE) avec le temps simulé. Complète les 3 transitions manquantes.

**Résultat attendu :**

```
t=   0 ms  etat=FERMEE
t= 100 ms  etat=OUVERTURE   (bouton presse)
t=2100 ms  etat=OUVERTE     (fin de course haut)
t=7100 ms  etat=FERMETURE   (tempo 5 s ecoulee)
t=9100 ms  etat=FERMEE      (fin de course bas)
SEQUENCE CORRECTE
```

**Question bonus** (à l'oral/papier) : pourquoi la FSM mémorise-t-elle
`t_entree_etat` plutôt que de compter avec un `delay()` ? *(réponse au
cours 01 §12 et TD 03 — la boucle doit rester libre.)*
