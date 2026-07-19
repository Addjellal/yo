# Mini-TP Java — décodage binaire et le piège du byte signé (20 min)

**Plateforme** : https://www.onlinegdb.com (langage : **Java**) ou
https://www.jdoodle.com. ⚠️ Sur OnlineGDB, le fichier doit s'appeler
`Main.java` — notre classe s'appelle déjà `Main`, colle tel quel.
**Prérequis** : cours 05 §2 (le `byte` signé) et TD 05 exercice 3.

## Exercice — `Main.java` (décodeur à trous)

Colle [`Main.java`](Main.java) et complète les 3 trous : validation de la
tête de trame **avec le masque `& 0xFF`**, extraction de l'id, assemblage
de la valeur 16 bits.

**Résultat attendu :**

```
trame valide     : id=7 valeur=500
mauvaise tete    : rejetee (OK)
trame trop courte: rejetee (OK)
piege du byte    : (byte)0xA5 = -91, avec & 0xFF = 165
TOUS LES TESTS PASSENT
```

**Le point du mini-TP** : la 4ᵉ ligne. En Java, `byte` est **signé**
(−128..127) : `(byte) 0xA5` vaut −91, et sans `& 0xFF` la comparaison avec
`0xA5` (=165) échoue TOUJOURS — donc toutes les trames valides seraient
rejetées. C'est le bug n°1 de tout code Java qui touche au binaire (ports
série, sockets, fichiers). Compare avec le même décodeur en C
([`../../code/c/trame.c`](../../code/c/trame.c)) : mêmes étapes, seul le
signe change.
