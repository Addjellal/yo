# Évaluation pratique — C / C++ (2 h, sur PC)

> Épreuve sur machine, **documents autorisés** (le vrai métier se fait docs
> ouvertes) mais **zéro copier-coller** depuis les corrigés. Plateforme :
> GCC/G++ local ou https://www.onlinegdb.com. Rendu : les fichiers sources
> + un fichier `REPONSES.md` pour les questions.

## Partie A — Questions flash (20 min, /4)

Répondre en 1 à 3 phrases, sans compiler :
1. Que vaut `uint8_t x = 200; x += 100;` et pourquoi ? (/1)
2. `volatile` garantit-il l'atomicité ? Justifier avec un exemple 16 bits
   sur CPU 8 bits. (/1)
3. Pourquoi `#define CARRE(x) x*x` est-il faux ? Donner l'appel qui le
   piège et la correction complète. (/1)
4. C++ : pourquoi un destructeur virtuel quand on détruit via un pointeur
   de base ? Que se passe-t-il sans ? (/1)

## Partie B — Programmation C (60 min, /10)

Écrire `histogramme.c` : un module qui reçoit des octets un par un
(`void histo_ajouter(uint8_t v)`) et les classe dans 8 tranches de 32
(`0-31`, `32-63`, …). Fournir :
- `histo_init()`, `histo_ajouter()`, `uint32_t histo_tranche(uint8_t n)` ;
- le calcul de la tranche **par décalage** (pas de division ni de `if` en
  cascade) (/3) ;
- un `main` de test avec ≥ 5 `assert` couvrant les bords (0, 31, 32, 255,
  tranche invalide) (/3) ;
- compilation **sans aucun warning** avec `-Wall -Wextra` (/2) ;
- pas de variable globale accessible de l'extérieur (`static`) (/2).

## Partie C — Lecture critique C++ (40 min, /6)

Le code suivant compile. Lister **quatre** défauts du point de vue « C++
embarqué », corriger chacun (code + une phrase), du plus grave au moins
grave :

```cpp
class Journal {
public:
    Journal() { buf = new char[256]; }
    void log(std::string m) { lignes.push_back(m); }
    char* buf;
    std::vector<std::string> lignes;
};
Journal j1, j2 = j1;
```

*(pistes : fuite, copie, passage par valeur, croissance non bornée,
visibilité des membres…)*

## Barème et seuil

| Partie | Points |
|---|---|
| A — questions flash | /4 |
| B — module C testé | /10 |
| C — lecture critique | /6 |
| **Total (seuil : 14/20)** | **/20** |

Spécificité de l'épreuve C/C++ : on note la **robustesse aux bords** et la
**propreté de compilation**, pas la vitesse d'écriture. Un module B sans
les asserts de bord plafonne à 7/10 même s'il « marche ».
