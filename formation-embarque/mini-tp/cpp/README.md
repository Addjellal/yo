# Mini-TP C++ — RAII en 20 minutes

**Plateforme** : https://www.onlinegdb.com (langage : **C++17**).
**Prérequis** : cours 02 §3 (RAII) lu.

## Exercice — `raii_a_trous.cpp`

Colle [`raii_a_trous.cpp`](raii_a_trous.cpp). Une fausse broche « chip
select » enregistre chaque montée/descente ; ta mission : écrire la classe
RAII `SelectionSPI` (3 trous : constructeur, destructeur, interdiction de
copie) pour que la broche soit TOUJOURS relâchée, même quand la fonction
sort par un `return` anticipé.

**Résultat attendu :**

```
-- transfert normal --
CS: BAS
CS: HAUT
-- transfert avec erreur (return anticipe) --
CS: BAS
CS: HAUT
VERIF : 2 descentes, 2 remontees -> RAII OK
```

**Le test qui compte** : la 2ᵉ remontée. Sans RAII (version « à la main »),
le `return` anticipé saute la remontée et le bus reste bloqué — c'est
exactement le bug que le destructeur rend impossible (cours 02 §3, TD 02
exercice 3).

**Question bonus** : décommente la ligne `// SelectionSPI copie = cs;` →
le compilateur doit **refuser**. Pourquoi une copie serait-elle dangereuse ?
*(deux destructeurs relâcheraient CS deux fois.)*
