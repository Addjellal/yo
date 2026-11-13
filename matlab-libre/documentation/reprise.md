# Reprise du travail — état au 13 novembre 2026

Ce document dit où en est le travail sur Simulink et Stateflow, ce qui
est validé, ce qui ne l'est pas, et comment reprendre. Il se suffit à
lui-même : rien de la session qui l'a écrit n'est nécessaire.

## 1. Où est le code

| Branche | Tête | Contenu |
|---|---|---|
| `main` (origin) | `dd0de200` | jusqu'au lot 90 (batterie de chaque choix de chaque bloc) |
| `claude/matlab-open-source-clone-b1vz9m` | voir ci-dessous | lots 91 à 104, **pas encore sur `main`** |

La branche de développement a 18 commits d'avance sur `main`, dans cet
ordre :

| Lot | Commit | Contenu | Tests |
|---|---|---|---|
| 91 | `90ad377e` | journal des mémoires partagées (`dsmout`) | section 105 |
| 92 | `60403a4e` | API de Simulink par les noms et les poignées | section 106 |
| 93 | `f47a7b4f` | fonctions d'événement, State Reader, State Writer | section 107 |
| — | `31f0e91f` | correctif : State Reader et le tampon des retards purs | |
| 94 | `527eac8c` | jeux de configuration ; `==` sur les poignées (C++) | section 108, test_classes |
| 95 | `a1721934` | rappels des blocs, `gcb`, `gcbh`, `gcs` | section 109 |
| 96 | `c0d30b2e` | `datestr` en entier (C++) | test_texte_es |
| — | `7a9fef75` | correctif d'essai (section 97) | |
| 97 | `eb06ff19` | la fiche du modèle (Created, ModelVersion, Dirty...) | section 110 |
| 98 | `065f2161` | outils de schéma ; sous-systèmes virtuels | section 111 |
| 99 | `5fe3da62` | API des masques (`Simulink.Mask`) | section 112 |
| — | `8e832eb8` | correctif : `open_system(42)` refusé comme avant | test_toolboxes |
| 100 | `c2a45d37` | dictionnaires de données (`.sldd`) ; deux correctifs de l'interpréteur | section 113, test_classes |
| 101 | `4b8569d6` | objets de table (`Simulink.LookupTable`, `Simulink.Breakpoint`), `Simulink.findBlocks` ; correctif d'indexation (C++) | section 114, test_langage |
| 102 | `acc03e9d` | objets de bloc (`get_param(...,'Object')`), Position par défaut, PortConnectivity | section 115 |
| 103 | `208a66c2` | API de Stateflow (`sfnew`, `sfroot`, `Stateflow.State`...) | section 116 |
| 104 | `b0b8cdc3` | **en cours** : Simulation Data Inspector (`Simulink.sdi`) | brouillon hors suite |

Le détail de chaque lot est dans son message de commit, et ce qui est
couvert est décrit dans `documentation/etat.md` (ligne Simulink).

## 2. Ce qui est validé, ce qui ne l'est pas

Une modification ne va sur `main` qu'après une suite complète verte
(`make test NEUF=0`). Aucune des suites lancées sur les lots 91 à 104
n'est allée au bout sans défaut, d'où l'absence de poussée sur `main`.

- **Suite complète sur `065f2161` (lots 91 à 98)** : tout vert, sauf
  `test_toolboxes` (`open_system(42)` rendait une autre erreur depuis le
  lot 95). Corrigé par `8e832eb8` ; `test_toolboxes` passe depuis.
- **Suite complète sur `acc03e9d` (lots 91 à 102)** : noyau 78/78,
  bureau 404 vérifications, `test_toolboxes`, `test_aide` et tous les
  autres tests verts ; **`test_simulink` n'a pas fini** : un redémarrage
  du conteneur l'a coupé.
- **Chaque nouvelle section (105 à 116) passe seule.**
- **`test_simulink` entier sur `208a66c2` (lot 103) : un échec**, dans la
  batterie des paramètres fautifs (vers la ligne 3242) :

  ```
  chart.Diagramme = variableInexistante : erreur interne MATLAB:json:BadNumber
  ```

  Le paramètre `Diagramme` du bloc Chart (ajouté au lot 103) reçoit un
  texte qui n'est pas du JSON ; `jsondecode` lève une erreur MATLAB brute,
  là où la batterie attend une erreur `Simulink:...`. Correctif à faire
  dans `toolbox/stateflow/matlibre_sf_api.m` : protéger le décodage
  (fonction `decoder`) — `ports` doit tolérer un diagramme illisible
  (rendre `[0 0]`), et la compilation (`machine`) le refuser par une
  erreur `Simulink:blocks:...` qui nomme le bloc. Ajouter le cas à la
  section 116.
- **Lot 104 (Simulation Data Inspector) : inachevé.** Le code est dans
  `toolbox/simulink/+Simulink/+sdi/` et `toolbox/simulink/matlibre_sdi*.m`.
  Le brouillon de ses tests, `tests/brouillons/section117_sdi.m`, est hors
  de la suite. Il passe jusqu'aux refus. Il s'arrête au premier :
  `Simulink.sdi.getRun(999999)` rend `MATLAB:nonExistentField` au lieu de
  `SDI:sdi:InvalidRunID`. À examiner : le constructeur de
  `Simulink.sdi.Run`, et `exigerRun` dans `matlibre_sdi.m`. Les refus
  suivants et la batterie croisée (36 comparaisons) n'ont pas encore
  tourné.

## 3. Reprendre, dans l'ordre

1. Partir de la tête de la branche de développement.
2. Corriger le défaut du lot 103 (paramètre `Diagramme` illisible), avec
   son test.
3. Finir le lot 104 : corriger le refus de `getRun`, faire passer tout le
   brouillon, puis l'insérer dans `tests/scripts/test_simulink.m` juste
   avant la dernière ligne, `disp('simulink : toutes les verifications
   passent');`. Supprimer alors `tests/brouillons/`. Ajouter le lot à
   `documentation/etat.md`, et vérifier que chaque nouvelle fonction a un
   exemple qui tourne et un « Voir aussi » (`test_aide` le contrôle).
4. Lancer la suite complète : `make test NEUF=0` dans `matlab-libre/`.
   Elle est verte quand elle affiche « tous les tests passent », « 78 / 78
   verifications passees » et « bureau : toutes les verifications passent
   (404) ». Compter plus d'une heure, surtout pour `test_simulink`.
5. Si elle est verte, pousser la branche sur `main` en avance rapide :
   `git fetch origin main && git merge-base --is-ancestor origin/main HEAD
   && git push origin HEAD:main`.

Pistes pour la suite, une fois `main` à jour :

- enregistrer automatiquement dans le Simulation Data Inspector les
  signaux journalisés par `sim`, comme Simulink ;
- Stateflow : fonctions graphiques, fonctions MATLAB et tables de vérité
  par l'API (`Stateflow.Function`, `Stateflow.EMFunction`,
  `Stateflow.TruthTable`) ; événements locaux ;
- les annotations (`Simulink.Annotation`, `find_system` sur
  `'Type','annotation'`) ;
- les signaux de taille variable (absents, voir `etat.md`) ;
- l'unité de Position : MatLibre la range en unités internes (le pixel
  de Simulink divisé par 40, comme le lit `matlibre_sl_slx`) ; des essais
  existants en dépendent ;
- les ports de contrôle d'un sous-système conditionnel comptent comme
  des entrées (`Ports` vaut `[2 1 0 ...]` pour un Enabled Subsystem, là où
  Simulink dit `[1 1 1 ...]`).

## 4. Comment travailler

### Construire et lancer

Depuis `matlab-libre/` :

- tout construire et tout tester : `make test NEUF=0` (sans `NEUF=0`, le
  dossier `build/` est d'abord effacé) ;
- construire seulement l'interpréteur : `make incrementale`, ou
  `cmake --build build -j 3 --target matlibre` ;
- un seul script d'essai :
  `MATLIBRE_TOOLBOX=$PWD/toolbox build/bin/matlibre --path tests/scripts tests/scripts/test_simulink.m`.

L'interpréteur lit la boîte à outils au fil de l'exécution : ne modifiez
pas `toolbox/` pendant qu'un essai tourne sur ce même dossier.
Travaillez dans une copie (`git worktree add`) quand un long essai tourne.

### Essayer une seule section de `test_simulink`

`test_simulink.m` est un script suivi de fonctions locales (à partir de
la première ligne qui commence par `function `). Pour essayer une section
seule, écrire un fichier qui contient la section, puis tout ce qui suit
cette première ligne `function `, et le lancer comme ci-dessus.

### Les conventions de ce travail

- Chaque lot ajoute une section numérotée à la fin de `test_simulink.m`
  (la dernière est la 116). Ses variables portent le numéro de la section
  (`dd113`, `r114`...). Chaque section a ses cas nominaux, une liste de
  refus attendus avec leur identifiant, et une batterie croisée de
  plusieurs facteurs.
- Les erreurs ont un identifiant de la forme de Simulink :
  `Simulink:...`, `SLDD:sldd:...` (dictionnaires), `Stateflow:API:...`,
  `SDI:sdi:...`. Leur message, en français, nomme le bloc fautif. Les
  batteries de `test_simulink` exigent qu'une erreur levée à la pose ou à
  la compilation d'un bloc commence par `Simulink:`.
- Chaque fonction de la boîte à outils a une aide en français : un
  paragraphe d'explication, un bloc « Exemple : » qui tourne tel quel, et
  un « Voir aussi ». Les fonctions internes s'appellent `matlibre_*` et
  le disent dans leur aide.
- Chaque lot met à jour `documentation/etat.md`.
- Les messages de commit sont en français, sans accents, en prose qui
  décrit le changement. Pas de réécriture d'historique : un correctif est
  un nouveau commit.
- Aucun code propriétaire de MathWorks : on suit le comportement décrit
  dans la documentation publique.

### Les pièges connus de l'interpréteur

- Pas d'indexation chaînée sur le résultat d'une fonction (`f(x).champ`,
  `f(x){1}`) : passer par une variable.
- Deux fonctions locales de même nom dans un fichier : la seconde masque
  la première sans rien dire.
- Une classe qui surcharge `subsref` voit cette surcharge appelée même
  dans ses propres méthodes pour `obj(k) = ...` : traiter `'()'` par
  `builtin('subsasgn', ...)`.
- Un tableau d'objets poignées perd l'identité de ses éléments : `==`
  entre un élément et l'objet d'origine échoue. Les objets de l'API
  (Simulink, Stateflow) sont des vues — une poignée de bloc, un numéro —
  et définissent leur propre `eq`.
- Les destructeurs (`delete`) ne sont jamais appelés automatiquement.
- `set(obj, ...)` n'appelle pas les accesseurs `set.Prop` : tester par
  `obj.Prop = v`.
- `save` n'a pas d'option `-mat`, mais écrit un fichier MAT quel que soit
  le nom ; `jsonencode` et `jsondecode` existent.
- Un bloc Chart sans entrée et à période héritée ne calcule qu'une fois :
  lui donner une période (`SampleTime`).
