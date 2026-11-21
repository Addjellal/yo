# Reprendre le travail sur MatLibre

Fiche de passation d'une session à la suivante. À lire en premier ; elle
renvoie aux documents de fond : `etat.md` (ce qui est fait et ce qui
reste, par boîte à outils), `architecture.md` (comment l'interpréteur et
le rendu sont bâtis), `developpeur.md` (compiler, ajouter une fonction,
conventions), `reference-matlab/hors-fonctions.md` (ce qui diffère de
MATLAB, domaine par domaine).

Dernière mise à jour : 21 novembre 2026, après le commit 9f0c666. La
batterie complète passait alors : 49 tests sur 49.

## 1. Les règles du dépôt

- **Branche** : `claude/matlab-libre-reprise-lgnad9` sur `addjellal/yo`.
  On ne pousse que là. Pas de pull request sans demande explicite.
- **Tout commiter et pousser avant de rendre la main** : un hook d'arrêt
  le vérifie et relance la session tant qu'il reste des modifications.
- **Messages de commit** : en français **sans accents**, un titre
  « Domaine : résumé » (`Graphique : ...`, `Coeur : ...`,
  `Simulink : ...`), un corps qui dit le pourquoi et ce qui a été
  mesuré. Ils se terminent par les deux lignes d'attribution
  (`Co-Authored-By: ...` et `Claude-Session: ...`) que la session donne.
- **Langue** : code commenté, aide, documents et messages d'erreur
  propres à MatLibre en français. Les identifiants d'erreur suivent
  MATLAB (`MATLAB:hg:InvalidProperty`) quand MATLAB en a un, sinon
  `MatLibre:domaine:Cause`.
- **Lignes de 100 colonnes au plus**, en C++ comme en `.m`.
- **Chaque fiche d'aide** porte un bloc « Exemple : » ou « Exemples : »
  et une ligne « Voir aussi » : `tests/scripts/test_aide.m` exécute
  **tous** les exemples et exige le « Voir aussi ». Les fonctions natives
  ont leur fiche dans `toolbox/aide/*.txt`, sous `### nom`.
- **Fonctions internes** préfixées `matlibre_` (elles n'existent pas dans
  MATLAB et le disent dans leur aide). Deux fichiers dont les noms ne
  diffèrent que par la casse (`addMF`/`addmf`) : l'un va dans le
  sous-dossier `homonymes/` du module.
- **La fidélité à MATLAB fait foi.** Quand un test encode un
  comportement propre à MatLibre et faux au regard de MATLAB, c'est le
  test qu'on corrige, en le disant dans le commit (exemples récents :
  `bar3` rend une poignée par colonne, `patch` un seul objet, `'r'` vaut
  `[1 0 0]`, `xticks` rend les graduations montrées).
- **Après un ajout ou un retrait de fonction**, régénérer la
  documentation :

  ```
  build/bin/matlibre --path toolbox outils/manques.m
  build/bin/matlibre --path toolbox outils/genererReference.m
  build/bin/matlibre --path toolbox outils/majComptes.m
  ```

  Le texte des écarts à MATLAB s'écrit dans
  `documentation/reference-matlab/hors-fonctions.md` ; `manques.md` en
  est tiré.

## 2. Construire et tester

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release      # une fois
cmake --build build -j4                             # tout, bureau Qt compris
build/bin/matlibre --path toolbox script.m          # lancer un script
build/bin/matlibre --path toolbox --path tests/scripts tests/scripts/test_graphique.m
cd build && ctest -j2 --timeout 7000 > log          # la batterie complète
cd build && ctest -R bureau                          # l'application de bureau, hors écran
```

- La batterie compte 49 tests et dure **environ une demi-heure** avec
  `-j2` : `test_simulink` à lui seul 25 minutes, `test_aide` 15. Les
  autres tiennent en quelques secondes ou minutes ; on les lance un par un
  pendant le travail.
- **Ne rien modifier pendant que la batterie tourne** : les `.m` de
  `toolbox/` sont lus au fil de l'exécution, et une fonction réécrite en
  cours de route fait échouer des tests qui n'ont rien à voir (c'est
  arrivé). Ne pas reconstruire non plus : le binaire change sous les
  tests.
- Les tests de cas de la littérature, un par boîte à outils, sont dans
  `tests/scripts/test_litterature.m` (49 boîtes à outils). Les exemples
  d'école, un par boîte, dans `exemples/toolboxes/` (`test_exemples.m`).
- Les avertissements de compilation dans `Base.cpp`, `Mat.cpp`,
  `Math.cpp` et `Statistiques.cpp` sont anciens ; une modification ne
  doit pas en ajouter.

### Outils de vérification

- `outils/capturer.js` rend en PNG les SVG d'un dossier (Playwright et
  son Chromium sont installés dans le conteneur) :
  `node outils/capturer.js dossier_svg dossier_png`. Les figures
  s'écrivent avec `matlibre_svg()`. Les PNG se regardent avec l'outil de
  lecture d'images : c'est ainsi que chaque nouveauté graphique a été
  contrôlée, figure par figure.
- `outils/comparerImages.py avant_png apres_png` compare deux corpus au
  pixel (demande Pillow) : la façon de vérifier qu'un remaniement du rendu
  ne change pas l'image.
- `outils/vueFigure.sh script.m dossier_png` peint les figures d'un
  script dans la fenêtre du bureau (`VueFigure`), hors écran, pour les
  comparer au SVG.
- **Vérifications croisées en Python** : les cas de la littérature ont
  été confrontés à des implémentations indépendantes. L'environnement se
  recrée ainsi (le scratchpad d'une session ne survit pas) :

  ```
  python3 -m venv /tmp/venv
  /tmp/venv/bin/pip install numpy scipy scikit-learn statsmodels pillow numfi fxpmath nltk
  /tmp/venv/bin/python -I script.py
  ```

  `libngspice.so.0` est installé (le hook de démarrage y veille) et se
  pilote par `ctypes` pour contrôler Simscape.

## 3. Ce qui a été fait dans les dernières sessions

| commit | contenu |
|---|---|
| `5c67b1a` → `7f78f6e` | Cas de la littérature, six lots, 49 boîtes à outils, chacun confronté à une référence publiée ou à une implémentation indépendante ; les résultats faux trouvés en route ont été corrigés (`ea52b93`, `933828e`). |
| `7335314` | Bureau : le ruban se replie quand la fenêtre rétrécit. |
| `4294110` | Collisions de casse (`homonymes/`), `dir` (`**`, plusieurs étoiles, `.` et `..`), et le générateur aléatoire de MATLAB : `rng(0); rand` rend 0.8147, `randn` 0.5377, comme la documentation (Mersenne Twister, ziggurat). |
| `c055708`, `bbe23bf` | Les tests et exemples qui ne tenaient qu'à la graine, rendus indépendants de la chance ; deux vrais défauts trouvés (`pcfitplane`, `mussv`). |
| `554052c` | Tableaux en copie sur écriture (`Tampon.h`) : passer un tableau de 16 Mo à une fonction ne le recopie plus (3,99 s → 0 s pour 200 appels). |
| `a9a20b9` | Une toile commune au SVG et à la fenêtre du bureau : le dessin n'est écrit qu'une fois. |
| `17ed9dd` | `scatter` propre (aires, couleurs par point, creux), la barre de couleurs dans ses huit positions avec étiquette et graduations, `xtickangle`/`ytickangle`, une graduation par barre, couleurs pures des lettres. |
| `9f0c666` | La perspective (`surf`, `mesh`, `plot3`, `scatter3`, `fill3`, `patch`, `bar3`, `stem3`, `quiver3`, `slice`, `meshc`...), l'interprète TeX des textes, `yyaxis` et `plotyy`. |

## 4. Les pièces récentes, et où elles sont

- **Rendu graphique** — `include/matlibre/Toile.h` déclare la toile
  (traits, polygones, rectangles, cercles, textes en morceaux, découpe).
  `src/graphique/Dessin.cpp` dessine un axe plan ; `Espace.cpp` un axe en
  perspective (projection de `viewmtx`, boîte étirée, tri du peintre) ;
  `Tex.cpp` coupe un texte en morceaux selon le TeX de MATLAB ;
  `ToileSVG.cpp` écrit le SVG ; `src/bureau/VueFigure.cpp` contient la
  toile Qt. `src/graphique/Commun.h` partage les aides entre plan et
  espace. Le modèle (séries, axes, figure) est dans
  `include/matlibre/Graphique.h` ; les fonctions de tracé dans
  `src/bibliotheque/TracesGraphiques.cpp` ; les poignées et leurs
  propriétés dans `src/bibliotheque/PoigneesGraphiques.cpp`.
- **Les tests du SVG lisent des formes précises** : la boîte d'un axe
  s'écrit `<rect ... fill="white" stroke="#222"/>`, une ligne `<path`,
  la couleur d'un texte est son dernier attribut (`fill="#FFFFFF">blanc`),
  un exposant `<tspan baseline-shift="super"`. `ToileSVG` les garde ;
  les changer casse `test_graphique`.
- **Générateur aléatoire** — `include/matlibre/Aleatoire.h` et
  `src/coeur/Aleatoire.cpp` ; `rng`, `rand`, `randn`, `randi`,
  `randperm` dans `src/bibliotheque/Base.cpp`.
- **Copie sur écriture** — `include/matlibre/Tampon.h`. Une fonction
  native qui ne fait que lire son argument le prend par référence const
  (`const Valeur& v = args[0]`) : lu par une copie non const, `v.re[k]`
  détache le tampon (voir `architecture.md`).
- **Calcul parallèle** — `src/coeur/Parallele.cpp` (`analyserParfor`, les
  fils sont créés à chaque `parfor`), `src/bibliotheque/Parallele.cpp`.
- **Base de données** — `toolbox/base-de-donnees/` : des tables en
  mémoire (`dbTable`, `dbSelect`...) sauvées en CSV.

## 5. Ce qui reste, par ordre d'intérêt

1. **Un pool de travailleurs persistant pour `parfor`.** Chaque `parfor`
   crée ses fils et ses interpréteurs, environ 0,5 s de coût fixe qu'une
   boucle courte ne rembourse pas (mesure dans `hors-fonctions.md`). Il
   faudrait garder les travailleurs d'une boucle à l'autre (`parpool`,
   `gcp`, `delete(gcp)` en règlent la vie dans MATLAB), en s'assurant
   que leur état ne fuit pas d'une boucle à la suivante.
2. **L'interface SQL de la Database Toolbox** : `sqlite`, `database`,
   `fetch`, `sqlread`, `sqlwrite`, `execute`, `close`. `libsqlite3-dev`
   est installé dans le conteneur ; la construction pour Windows
   (`outils/mingw.cmake`) devra soit trouver SQLite, soit embarquer
   l'amalgame `sqlite3.c`, soit construire sans ces fonctions en le
   disant. Les tables en mémoire existantes (`dbTable`...) restent.
3. **`get(h,'Color')` rend un code `'#FF0000'`** là où MATLAB rend le
   triplet `[1 0 0]` (idem `MarkerFaceColor`, `FaceColor` quand c'est
   une couleur). Les deux s'écrivent déjà ; changer la lecture touche
   `findobj` et des tests qui comparent des chaînes.
4. **L'API d'acquisition de MATLAB** : `addinput`, `read`, `write`,
   `start` manquent ; `addAnalogInput`, `readData`, `writeData` en
   tiennent lieu (`toolbox/acquisition`).
5. **Les limites du rendu**, toutes écrites dans `hors-fonctions.md` :
   - perspective : deux faces qui se traversent ne sont pas découpées
     (algorithme du peintre) ; `shading interp` donne la moyenne d'une
     maille au lieu d'un dégradé ; pas d'éclairage ; `bar3h` garde des
     barres verticales ; `slice` coupe sur le plan de grille le plus
     proche au lieu d'interpoler ;
   - texte : l'interprète `'latex'` n'est que du TeX sans dollars
     (`\frac`, `\sqrt{}` ne sont pas mis en page) ; un texte en cellule
     s'écrit sur une ligne ;
   - légende : `AutoUpdate` et `NumColumns` acceptés sans effet ; une
     légende de surface montre un trait ;
   - les étiquettes de graduation ne s'inclinent pas d'elles-mêmes quand
     elles se chevauchent ;
   - axes polaires sans graduation angulaire du cadre, `histogram2` en
     carte et non en barres, bandes de `contourf` posées en champ
     continu ;
   - pas d'interaction à la souris (zoom, rotation 3D, curseur), pas de
     format `.fig`.
6. **Interface utilisateur** : `uicontrol`, `uifigure` et App Designer
   absents ; pas de boucle d'événements modale (`uiwait` n'attend pas).

## 6. Pour démarrer un nouveau chat

Coller ce message :

> Reprends le projet MatLibre (dépôt `addjellal/yo`, dossier
> `matlab-libre`, branche `claude/matlab-libre-reprise-lgnad9`). Lis
> d'abord `matlab-libre/documentation/reprise.md`, puis `etat.md` et
> `architecture.md`. Construis (`cmake -S . -B build
> -DCMAKE_BUILD_TYPE=Release` puis `cmake --build build -j4`), vérifie
> que la batterie passe (`cd build && ctest -j2 --timeout 7000`, une
> demi-heure), puis propose-moi la suite parmi « Ce qui reste »
> (section 5).
