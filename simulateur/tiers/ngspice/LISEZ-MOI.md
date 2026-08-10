# ngspice — second moteur analogique

Trois fichiers, extraits de la distribution officielle `ngspice-46_dll_64` :

| Fichier | Rôle |
|---|---|
| `include/ngspice/sharedspice.h` | l'en-tête que `NgspiceEngine` inclut |
| `dll-vs/ngspice.dll` | la bibliothèque, chargée à l'exécution |
| `lib/lib-vs/ngspice.lib` | bibliothèque d'import (Visual Studio) |

La distribution complète en contient dix fois plus — modèles, exemples,
exécutable en ligne de commande, greffons. Rien de tout cela ne sert ici :
le simulateur n'appelle que l'interface partagée.

## À quoi ça sert, et à quoi ça ne sert pas

**Ce n'est pas nécessaire pour simuler.** Le solveur intégré au projet fait
tout : point de repos, transitoire, `.dc`, `.ac`, bruit. ngspice n'est là que
comme **référence indépendante** — on résout le même circuit des deux côtés et
l'on compare.

C'est ainsi qu'a été trouvé le défaut du modèle de Zener : le point de repos
ne convergeait pas sous 10 V d'entrée, et la comparaison a montré où.

Sans ngspice, le projet compile et fonctionne ; les sections du banc d'essai
qui comparent les deux moteurs s'annoncent simplement ignorées.

## Origine et licence

<https://ngspice.sourceforge.io/> — ngspice est sous licence BSD à trois
clauses, qui autorise la redistribution binaire. Version 46, 64 bits.
