# Ce que la critique a retenu des cent propositions

Cinq agents ont jugé les cinq lots, sources à l'appui. Ce document remplace
`PROPOSITIONS-INTERFACE.md` comme référence de travail : il ne garde que ce
qui tient, et dit pourquoi le reste tombe.

Le résultat le plus utile n'est pas la liste des idées adoptées — c'est la
liste des **défauts déjà présents** que la critique a mis au jour en allant
lire le code. Ils passent devant toute idée neuve.

---

## 0. Mes propres erreurs, d'abord

Sept des cent propositions citaient un précédent que je n'avais pas vérifié.
Trois étaient carrément faux :

| # | Ce que j'ai écrit | Ce qui est vrai |
|---|---|---|
| 7 | LTspice affiche les noms de nœuds en permanence | **Non.** Il faut poser soi-même un `Label Net` ; LTspice ne montre le nom qu'au survol, en barre d'état |
| 9 | Multisim anime le courant | **Non.** NI le dit explicitement : pas d'animation, il faut des sondes. Falstad anime, mais par des **points jaunes**, pas par l'épaisseur |
| 21 | `R` = rotation « (KiCad, Altium, Proteus) » | Vrai pour KiCad seul. **Altium : `Espace`. Proteus : `+`/`−` du pavé numérique** |
| 27 | `F5` « (Visual Studio, Arduino IDE) » | Visual Studio oui. **Arduino IDE : `Ctrl+R` / `Ctrl+U`**, pas F5 |
| 38 | `Ctrl+E` « (KiCad : `E`) » | La proposition se contredisait : KiCad utilise **`E`** tout court |
| 49 | `Alt+clic` « (Illustrator, Figma) » | **Inkscape et Blender.** Illustrator et Figma utilisent `Ctrl+clic` |
| 95 | Info-bulles d'aide « (KiCad) » | **Non vérifié.** En revanche le projet le fait déjà lui-même |

J'avais demandé aux agents de ne jamais affirmer un précédent sans source. Je
ne me l'étais pas appliqué en écrivant le corpus.

---

## 1. Défauts confirmés dans le code (avant toute idée neuve)

Treize, trouvés en lisant les sources. Deux sont déjà corrigés.

### Corrigés

- **Le clic droit ouvrait un menu qu'on n'avait pas demandé** en abandonnant
  un fil. Les deux rôles s'excluent désormais.
- **La grille se traçait à tout zoom**, jusqu'à faire de la feuille un aplat
  gris à l'échelle 0,15 — et ces milliers de lignes invisibles étaient
  retracées à chaque image.

### À corriger, par ordre de gravité

1. **Les raccourcis n'ont pas de portée.** `R` et `Suppr` sont des `QAction`
   de fenêtre : sur la page Circuit imprimé, ils agissent sur la sélection du
   **schéma invisible**. Les branches `Key_R` de `SceneSchema` et de `VuePcb`
   sont du code mort — l'action de fenêtre gagne toujours.
2. **`Ctrl+D` et `Ctrl+F` volent la frappe à l'éditeur de programme.**
   L'agent l'a *mesuré* plutôt que supposé : Qt protège tout seul les touches
   uniques (`R`, `M`, `W`, `A`) parce que `QPlainTextEdit` accepte le
   `ShortcutOverride`, mais laisse passer les `Ctrl+lettre` et les touches de
   fonction. Ma consigne de départ visait donc le mauvais danger. Taper
   `Ctrl+D` dans le code duplique un composant en silence.
3. **La molette zoome sur la page PCB et déplace sur la page Schéma.** Deux
   conventions contradictoires dans la même fenêtre, sans avertissement.
4. **La sortie du compilateur part dans une boîte modale.** `avertir()` passe
   le compte rendu entier d'`avr-g++` à une `QMessageBox` non
   redimensionnable, qu'il faut fermer pour regarder son code.
5. **L'ERC ouvre une boîte modale qui recouvre le schéma qu'elle décrit.**
6. **La compilation gèle la fenêtre** : appel synchrone sur le fil
   d'interface.
7. **Le zoom au bouton de la barre d'outils saute.** `zoomer()` ancre
   toujours sous la souris — laquelle est sur le bouton, pas sur le schéma.
8. **Le pas de zoom est fixe (1,15 par événement).** Un pavé tactile en envoie
   des dizaines par seconde : le pincement part en vrille. Invisible tant
   qu'on teste à la souris.
9. **Le repli des lignes du journal ne compare qu'à la ligne précédente.**
   Deux messages qui alternent le défont entièrement — et le solveur en émet
   justement deux ensemble.
10. **`Anomalie.reference` n'est pas toujours une référence** : c'est un nom
    de nœud pour les nœuds isolés, une liste jointe par virgules pour les
    courts-circuits. Tout clic-vers-le-composant doit traiter ces cas, sinon
    un tiers des lignes seront des clics morts.
11. **Les erreurs du solveur n'ont ni coupable ni remède.** « le point de
    repos n'a pas convergé », sans nœud, sans composant, sans quoi-faire.
    Aucune de mes cent propositions ne les touchait.
12. **Le `sceneRect` est figé** et ne grandit pas avec le contenu.
13. **`Retour arrière` est déjà pris** sur la page PCB (défaire un segment) :
    en faire un synonyme de `Suppr` détruirait un geste de routage.

---

## 2. Ce qui est retenu

Vingt-six propositions sur cent, groupées en cinq chantiers cohérents. L'ordre
est celui d'exécution : chaque chantier s'appuie sur le précédent.

### Chantier 1 — Donner une portée aux commandes

Rien d'autre ne tient tant que ceci n'est pas fait : c'est ce qui corrige les
défauts 1, 2 et 3.

- Raccourcis en `Qt::WidgetWithChildrenShortcut` par page ; dédoublonner `R`
  et `Suppr` ; rebrancher `VuePcb` sur sa propre rotation.
- Aligner la molette du PCB sur celle du schéma. **Une seule règle.**
- `Ctrl+F` selon le contexte : chercher un composant sur le schéma, chercher
  dans le programme quand l'éditeur a le focus (**30**).

### Chantier 2 — Le clavier, et le moyen de l'apprendre

- **40** — `F1` : pense-bête **engendré depuis les `QAction`**, donc jamais
  désynchronisé. À faire *en premier* : sans lui, aucun autre raccourci n'est
  découvert, et en enseignement une fonction cachée n'existe pas.
- **36** `A` = ajouter un composant · **37** `W` = fil · **33** `Début` =
  recadrer · **22** `X`/`Y` = miroir (KiCad et Altium d'accord) · **47**
  `Ctrl+A` · **39** flèches = déplacer d'un pas.
- **26** mais en **`Maj+Espace`**, pas `Espace` : c'est ce qu'utilisent KiCad
  *et* Altium, et `Espace` est déjà pris trois fois ici.
- **34** avec les trois liaisons `Ctrl+=`, `Ctrl++`, `Ctrl+plus` du pavé —
  parce que le clavier de l'établissement est un **AZERTY**, où les chiffres
  demandent `Maj`.

### Chantier 3 — Se déplacer sans souris à molette

Le public est sur portable, souvent au pavé tactile. C'est le critère qui
tranche tout ce lot.

- **60** — corriger le pas de zoom en continu (`pow(1.0015, delta)`) : le
  pincement Windows arrive déjà en `Ctrl+molette`, il n'y a donc rien à
  ajouter, seulement un défaut à réparer. **À vérifier sur une vraie machine
  avant d'écrire autre chose.**
- **52** — défilement automatique au bord pendant un tracé : la seule fonction
  qu'un utilisateur sans molette ni bouton du milieu **ne peut remplacer par
  rien**, puisque le bouton gauche est tenu.
- **44** — ancrage du zoom selon l'origine : sous la souris depuis la molette,
  au centre depuis un bouton ou un menu.
- **57** — `Alt+Gauche` = cadrage précédent, contre l'accident le plus
  fréquent au pavé tactile.
- **59** — lignes-guides d'alignement des bornes : la seule proposition qui
  améliore le schéma **produit**, et pas seulement le confort de qui le trace.
- **42 étendu** — le glissement au **bouton droit** déplace aussi la vue
  (défaut de KiCad), avec seuil de 4 px pour préserver le menu contextuel.

### Chantier 4 — Diagnostiquer

- **84** — panneau « Contrôle » à côté du journal, jamais modal : pièce
  porteuse sans laquelle 81, 83 et 86 n'ont nulle part où se brancher.
- **88** — un champ `remede` dans `Anomalie`, une phrase à l'impératif. Le
  modèle est déjà dans le dépôt : le message « aucun firmware » nomme le
  manque *et* les deux remèdes. Les seize règles méritent le même traitement.
- **83** — clic sur l'anomalie = sélectionner et centrer, en traitant les
  trois formes de `reference` (défaut 10).
- **86** — compteur en barre d'état, seul canal permanent de découvrabilité.
- **85** — sortir la sortie du compilateur de la modale (défaut 4).
- **12** — marqueur ERC posé **à côté** du symbole. Et non pas le noircir :
  le noirci-barré dit un fait physique constaté — le composant a grillé.
  Dessiner pareil une broche en l'air enseignerait qu'un fil oublié détruit un
  composant. C'est faux.
- **95** — règle de tenue : tout réglage dont le libellé ne suffit pas porte
  une info-bulle disant ce qu'il **change**, pas ce qu'il est.

### Chantier 5 — Lire le schéma

- **3** grille adaptative *(fait)* · **6** survol qui allume tout le nœud —
  `calculer_noeuds()` fait déjà le calcul, et c'est la question même que pose
  l'élève dont la LED ne s'allume pas.
- **15** icônes de composant dans la palette, **rendues depuis
  `modele->symbole`** : cinquante-trois symboles sans créer un seul fichier
  graphique. **17** fondue dedans — l'info-bulle garde ce que l'icône ne peut
  pas montrer (bornes, valeur par défaut).
- **8 corrigé** — marquer la **borne** non connectée, pas le corps : l'erreur
  réelle est de câbler trois bornes sur quatre, et griser le corps ne la
  montrerait pas.
- **20** cartouche **à l'impression seulement** — trente copies sans nom
  d'auteur ne sont pas corrigeables. Rien de nouveau à l'écran.
- **5** mode présentation : `afficher_page()` sait déjà masquer et restaurer
  les docks, il ne reste qu'à l'appeler. `F11`, sortie par double `Échap` —
  jamais `Échap` seul, qui abandonne le fil.
- **98** trace mémorisée à l'oscilloscope (un seul emplacement, comme la
  touche `REF` d'un oscilloscope d'atelier) : le geste de TP le plus fréquent
  — changer une résistance et voir le déplacement.
- **13** mémoire de la disposition, **avec** « Réinitialiser la disposition » :
  sans elle, un élève qui replie un dock à zéro le lègue au suivant.

---

## 3. Ce qui est écarté, et pourquoi

**Déjà fait** (7 propositions) : 14 le `sceneRect` a déjà 1000 unités de
marge · 16 la recherche instantanée est écrite · 18 les instruments sont déjà
une catégorie · 31 `Tab` est le comportement par défaut de Qt · 41/60 la
molette et le pavé tactile marchent déjà · 82 le repli existe.

**Contredit une décision prise** : 72 (clic sur broche = rôle) et 78 (poignée
de déplacement) rétablissent la déclaration d'intention par zonage que le
câblage sans mode supprime. 74 (menu radial) réclame un bouton droit déjà
promis trois fois. 69 (clic milieu = supprimer) prendrait le bouton qui
déplace la vue.

**Fausse bonne idée** :
- **9** épaisseur selon le courant — le fil code déjà la tension par sa
  couleur, l'épaisseur est prise par la sélection, et six décades de courant
  ne se lisent ni en linéaire ni en logarithmique.
- **29** grouper — notion de dessin vectoriel, sans aucun sens électrique. La
  vraie réponse est le bloc hiérarchique.
- **35** touches `1`-`9` — neuf raccourcis brûlés sur AZERTY pour une palette
  de recherche qui fait déjà le travail en trois frappes.
- **46** rectangle selon le sens — Altium le livre **désactivé par défaut** ;
  deux glissements identiques à l'œil donnant deux résultats, c'est une source
  d'erreur payée en code.
- **51** `Tab` entre composants — enfermerait au clavier dans le canevas.
- **58** aimantation débrayable — ici la connexion s'ancre sur des objets, pas
  sur des coordonnées : on ne gagnerait qu'un schéma de travers.
- **89** contrôle continu — une borne en l'air est classée *Erreur* ; en
  continu le compteur serait rouge du premier composant au dernier, et
  l'élève apprendrait à ne plus le regarder.
- **97** historique de simulation — sauvegarder à chaque trame l'état du cœur
  et du solveur, pour un besoin que le gel de l'oscilloscope couvre déjà.

**Fréquence insuffisante** : 10 miniature · 54 signets de vue · 55 vue scindée
(inutilisable en 1366×768) · 92 annulation du routage (à ne rouvrir que si une
mesure montre plus de deux secondes).

**Sans objet** : 73 poignées de redimensionnement — aucun objet redimensionnable
n'existe. 90 différentiel de compilation — ne répond à aucune question que
l'élève se pose.

---

## 4. Manques relevés — que mes cent propositions ne couvraient pas

1. **Cliquer une erreur de compilation pour atteindre la ligne fautive.**
   C'est la première erreur que rencontre un élève, l'éditeur est dans la même
   fenêtre, et la sortie d'`avr-g++` est aujourd'hui déversée telle quelle.
2. **Les messages du solveur, sans coupable ni remède** (défaut 11).
3. **L'éditeur de programme n'a ni recherche, ni `Ctrl+S`, ni numéros de
   ligne, ni coloration** — alors qu'on lui prend `Ctrl+F` et `Ctrl+D`. C'est
   la moitié du sujet du logiciel, et aucune de mes vingt propositions de
   « lisibilité » ne la regardait.
4. **Aucun éditeur de raccourcis**, alors que KiCad et Proteus en ont un et
   que l'AZERTY en fait une soupape nécessaire.
5. **Rien pour les objets les plus posés en TP** : masse, étiquette de net,
   jonction. J'ai donné `X`/`Y` pour le miroir et rien pour la masse.
6. **Exclusions d'anomalies** : sans elles, un montage d'exercice
   volontairement partiel affiche des erreurs permanentes.
7. **Reprendre un tracé de fil en attrapant un segment** — exigé par
   `DECISION-FILS` §6, et aucune proposition ne disait par quel geste.
8. **Actionner un composant pendant la simulation** : appuyer sur un bouton,
   tourner un potentiomètre. C'est le cœur de l'usage, et le clic gauche sur
   le corps est déjà pris par le déplacement.
9. **Aucune datation dans le journal**, alors que le temps simulé est suivi en
   permanence.
10. **Pas d'impression**, alors que la sortie papier est l'usage déclaré.
11. **Taille de police de l'interface** pour la projection — plus déterminant
    en salle qu'un thème sombre.

---

## 5. Ordre de marche

1. Chantier 1 (portée) — corrige trois défauts, débloque tout le reste.
2. Défauts 4, 5, 6 (les modales et le gel) — ce sont des corrections, pas des
   ajouts.
3. Chantier 2, en commençant par `F1`.
4. Chantier 3, en commençant par une **mesure sur une machine à pavé
   tactile**.
5. Chantier 4, dans l'ordre 84 → 88 → 83 → 86.
6. Chantier 5.
7. Manques 1, 2 et 3 — qui pèsent plus lourd que la moitié des propositions
   retenues.
