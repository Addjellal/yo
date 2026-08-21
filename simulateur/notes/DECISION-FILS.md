# Comment on tire un fil — décision

Ce document tranche la question du câblage au schéma : ce que font les
logiciels de référence, ce que valent les idées relevées à l'usage, et ce
qu'on retient. Il est écrit avant le code exprès, pour que le code ait une
raison plutôt qu'un goût.

## Le défaut à corriger

Trois observations, faites en utilisant l'application :

1. tirer un fil depuis un fil existant fait basculer en mode sélection ;
2. les fils ne décrivent pas de chemin propre ;
3. la molette servait à sélectionner au lieu de se déplacer *(corrigé)*.

La première est la plus grave, et elle n'est pas un détail de réglage : elle
dit que le logiciel demande à l'utilisateur de déclarer son intention avant
d'agir, là où les autres la déduisent.

## Ce que font les quatre références

| | Chemin | Choix du mode | Depuis un fil |
|---|---|---|---|
| **Proteus** | auto-routeur (WAR) | **aucun mode** | clic direct |
| **Simulink** | auto, orthogonal | sans objet | Ctrl + glisser |
| **Altium** | 4 modes dont Auto Wire | `Maj+Espace` | jonction automatique |
| **KiCad** | manuel | `Maj+Espace` | jonction manuelle |
| **LibrePCB** | manuel, 5 postures | outil modal | **découpe du fil** |

### Proteus — le câblage sans mode

C'est la référence explicite du projet, et c'est celle qui va le plus loin.
Labcenter appelle cela *modeless wiring* : « you can connect at any time ».
Il n'y a pas d'outil « fil » à choisir.

La désambiguïsation ne se fait pas par un mode mais **par ce qui est sous le
curseur** : au-dessus d'une broche, le curseur devient un crayon ; au-dessus
de l'extrémité d'un fil, il verdit. Cliquer sur le corps d'un composant le
sélectionne, cliquer sur sa broche commence un fil. La même main, le même
bouton, deux gestes distingués par la cible.

Le chemin : « placing a wire can be as simple as clicking on the two pins you
want to connect — the Wire Auto-Router does the rest ». Pour imposer un
tracé, on clique aux coins intermédiaires, ce qui **ancre** le segment déjà
routé et rend la main à l'auto-routeur pour la suite. Un tracé qui déplaît se
reprend après coup en attrapant le fil. Et le routeur repasse tout seul quand
on déplace un composant.

### Simulink — le principe qui manque aux autres

Segments orthogonaux, chemin le plus court à nombre minimal de virages, sans
recouvrir blocs ni lignes, avec **aperçu avant de relâcher**.

Ce que Simulink apporte de propre, c'est une règle : le *minimum
disturbance*. L'algorithme « changes the shape of existing signal lines as
little as possible ». C'est ce qui empêche un auto-routeur d'être insupportable
— sans cette règle, chaque déplacement rebat toute la feuille et l'utilisateur
perd le travail de mise en page qu'il vient de faire.

La dérivation s'y fait par `Ctrl` + glisser depuis une ligne existante.

### Altium — la jonction automatique

Quatre modes au clavier (`Maj+Espace` : 90°, 45°, libre, Auto Wire),
`Espace` retournant la posture du coude. Surtout : *Auto Junction* pose un
point de jonction dès qu'un fil **commence ou finit sur un autre fil**. La
dérivation en T n'y est pas une opération à part, c'est une conséquence.

### KiCad — le contre-exemple utile

Trois postures (90°, 45°, libre) au `Maj+Espace`, et **pas d'auto-routeur au
schéma**. Le tracé est entièrement manuel.

C'est le rappel que l'auto-routage n'est pas une évidence : l'outil libre le
plus utilisé s'en passe, et ses utilisateurs ne s'en plaignent pas. Ce qu'ils
ont en échange, c'est un tracé prévisible.

### LibrePCB — le seul dont on puisse lire le code

Sur le tracé, LibrePCB est du côté de KiCad : un outil modal
(`SchematicEditorState_DrawWire`), cinq postures — `HV`, `VH`, `90/45`,
`45/90`, `Straight` —, et **aucun auto-routeur**. Rien à en tirer sur ce
point.

Son intérêt est ailleurs, et il est décisif : il montre **comment** on fait
tenir le reste.

**1. Une extrémité de fil ne sait pas à quoi elle s'accroche.** Broche de
symbole, point de fil, jonction de bus dérivent tous de `SI_NetLineAnchor`.
Un fil relie deux *ancres*, pas deux broches. C'est cette abstraction qui
fait que « partir d'un fil » n'est pas un cas particulier — il n'y a rien à
prévoir, une ancre en vaut une autre.

**2. La dérivation en T est une découpe.** Quand un fil se termine sur un fil
existant (`SGI_NetLine` sous le curseur), le code fait exactement ceci :

```
ajouter un point au lieu du clic
ajouter deux fils : point→P1 et point→P2   (les deux moitiés de l'ancien)
supprimer le fil d'origine
```

Le tout dans un seul groupe d'annulation, pour que ça se défasse d'un coup.
Aucune notion de « jonction » n'est nécessaire : le T *est* trois fils
partageant une ancre.

**3. Le « sans mode » se ramène à une table de priorités.** LibrePCB
n'est pas modeless, mais il résout la même question — que vise le curseur ?
— et il le fait par un classement explicite, commenté dans le source :

| priorité | objet |
|---|---|
| 0 | points de fil visibles |
| 15 | jonctions de bus |
| 20 | **fils** |
| 40 | **broches** |
| 50 | symbole dont l'origine est proche |
| 70 | symbole sous le curseur |

Tout ce à quoi on peut se connecter passe **avant** le corps du composant.
S'y ajoutent deux paliers de distance : `+1000` pour un objet proche du
curseur sans être dessous, `+2000` pour un objet au pas de grille suivant —
l'aimantation fait partie du même classement, elle n'est pas un traitement à
part.

C'est la recette qui manquait. Proteus dit *ce que* fait un logiciel sans
mode ; LibrePCB montre *comment* on décide, ligne par ligne.

## Ce que valent les idées relevées

**« Des chemins comme dans Simulink » — retenu.** Les deux références qui
comptent ici le font, dont Proteus, qui est un outil de circuit et non de
schéma-bloc. L'objection qu'on pouvait faire — un schéma électrique n'est pas
un graphe orienté de blocs, ses nœuds sont multipoints — ne tient pas :
Proteus route des nets, pas des liaisons point à point.

**« Chemins modifiables » — retenu, et c'est la condition du reste.** Proteus
comme Altium laissent reprendre le tracé. Un auto-routeur qu'on ne peut pas
contredire est un auto-routeur qu'on subit. C'est aussi ce qui rend le premier
point acceptable : on peut se tromper puisqu'on peut être corrigé.

**« La sélection ne doit pas se déclencher quand je pars d'un fil » — retenu,
et promu au rang de principe.** L'idée était formulée comme une gêne ; c'est
en réalité le cœur du sujet. La réponse de Proteus n'est pas « corriger le
basculement » mais **supprimer les modes** : l'intention se lit sous le
curseur. Celle d'Altium est la jonction automatique. Les deux disent la même
chose — commencer un fil sur un fil est une action de plein droit, pas un cas
particulier.

**Dérivations en T — retenu**, comme conséquence du point précédent et non
comme fonction séparée (Altium), avec le geste dédié de Simulink en second.

**La molette — déjà fait**, et cohérent avec tout le reste.

## Décision

**Le modèle Proteus, tempéré par la règle de Simulink et la jonction
d'Altium.**

1. **Sans mode.** Plus d'outil « fil » à choisir. Ce qui est sous le curseur
   décide : corps de composant → sélection et déplacement ; broche ou fil →
   début d'un fil. Le curseur l'annonce avant le clic — c'est ce qui rend
   l'absence de mode lisible plutôt que surprenante.
2. **Auto-routage orthogonal**, chemin le plus court à nombre minimal de
   coudes, contournant composants et fils, avec aperçu pendant le geste.
3. **Ancrage au clic.** Un clic en cours de tracé fige ce qui est routé et
   laisse l'auto-routeur continuer. C'est la reprise en main sans changement
   d'outil.
4. **Jonction automatique** dès qu'un fil naît ou meurt sur un autre.
5. **Minimum disturbance.** Déplacer un composant reroute ses fils, et
   uniquement les siens : la mise en page déjà faite ne doit pas être défaite.
6. **Tracé repris après coup** en attrapant un segment.
7. **Échappatoire** : une touche pour le tracé libre, parce qu'aucun
   auto-routeur ne gagne tous les cas — c'est la leçon de KiCad.

Ce qui n'est **pas** retenu : les quatre modes d'Altium au clavier. Ils
existent parce qu'Altium a gardé un outil de placement modal ; sans mode, ils
n'ont plus d'objet. Un unique échappatoire (point 7) suffit.

## Ce que ça implique pour notre code

La lecture de LibrePCB change le diagnostic. Notre `ItemFil` s'écrit :

```cpp
ItemFil(ItemComposant* depart, int borne_depart,
        ItemComposant* arrivee, int borne_arrivee);
```

Un fil y relie **deux broches de composant, et rien d'autre**. Un fil qui
part d'un fil n'est pas seulement mal géré : il est *inexprimable*. Le
basculement en mode sélection constaté à l'usage n'est donc pas une bévue de
gestion de la souris à rattraper avec un `if` — c'est le modèle de données
qui ne sait pas dire ce qu'on lui demande, et l'interface qui retombe sur le
seul geste qu'elle sache faire.

Cela réordonne le travail. Avant l'auto-routeur, avant le curseur qui change
de forme, il faut :

1. **une ancre** — broche, point de fil, ou point sur un fil —, et un
   `ItemFil` qui relie deux ancres ;
2. **la découpe** d'un fil en deux à l'endroit du clic, en une seule
   opération annulable ;
3. **la table de priorités** qui dit ce que vise le curseur, avec ses paliers
   de distance.

Ces trois-là faits, le reste — auto-routage, aperçu, ancrage au clic,
minimum disturbance — se pose dessus. Faits dans le désordre, on écrirait un
auto-routeur qui ne saurait toujours pas partir d'un fil.

## Le point 6, enfin élucidé : par quel geste reprend-on un tracé ?

La décision exigeait « tracé repris après coup en attrapant un segment »
sans dire comment. La réponse est dans le source de LibrePCB 2.1.1, et elle
est plus simple que prévu : **il n'y a pas de geste dédié.** On sélectionne
le segment et on le glisse ; c'est le code de déplacement ordinaire qui
fait le reste.

`SchematicSelectionQuery::addNetPointsOfNetLines()`
(`libs/librepcb/editor/project/schematic/schematicselectionquery.cpp:243`) :

```cpp
foreach (SI_NetLine* netline, mResultNetLines) {
  SI_NetPoint* p1 = dynamic_cast<SI_NetPoint*>(&netline->getP1());
  SI_NetPoint* p2 = dynamic_cast<SI_NetPoint*>(&netline->getP2());
  if (p1 && (…)) mResultNetPoints.insert(p1);
  …
```

Deux détails portent tout :

1. **Le `dynamic_cast` est le filtre.** Une extrémité qui est un point de
   fil devient déplaçable ; une extrémité qui est une **broche** échoue au
   transtypage et n'est simplement pas ajoutée. Glisser un fil dont un bout
   tient à une broche fait donc bouger l'autre bout seulement — la broche
   reste où elle est, sans qu'aucun code ne traite ce cas à part.
2. **`onlyIfAllNetLinesSelected`** : un point n'est déplacé que si *tous*
   les fils qui s'y accrochent sont eux aussi sélectionnés. Sans cette
   garde, attraper un segment déformerait des fils voisins qu'on n'a pas
   désignés.

**Ce que ça donne chez nous.** La traduction est directe, parce que notre
`Ancre` est déjà leur `SI_NetLineAnchor` : `ancre.jonction` se déplace,
`ancre.composant` ne se déplace pas. Le `dynamic_cast` devient un test sur
le membre renseigné. Reste à écrire : rendre `ItemFil` sélectionnable et
glissable, propager le déplacement à ses ancres-jonctions, et poser la garde
du point 2 — un point partagé par trois fils ne bouge que si les trois sont
pris.

Corollaire : attraper un fil tendu **entre deux broches** ne peut rien
déplacer, puisqu'aucun de ses bouts n'est mobile. Il faudra alors y insérer
une jonction au point saisi — ce que `decouper()` sait déjà faire.

## Ce qu'il faudra vérifier

L'auto-routage est la partie facile à mal faire. Trois pièges connus :

- un routeur qui recalcule tout à chaque déplacement rend la feuille
  instable ; le point 5 est ce qui l'empêche, et c'est lui qu'il faut tester
  en premier ;
- l'aperçu doit être celui du tracé final, sinon il ment ;
- un fil qui contourne un composant en le frôlant se lit mal : la distance de
  garde vaut d'être un réglage, pas une constante enfouie.

## Sources

- Labcenter, *Wiring and Buses — Modeless Wiring* : <https://www.labcenter.com/wiring/>
- Labcenter, *Schematic Capture* : <https://www.labcenter.com/schematic/>
- *ISIS Intelligent Schematic User Manual*, § Wiring Up
- MathWorks, *Smart Signal Routing* : <https://blogs.mathworks.com/simulink/2012/10/11/smart-signal-routing/>
- MathWorks, *Connect Blocks* : <https://www.mathworks.com/help/simulink/ug/connect-blocks.html>
- Altium, *Working with a Wire Object on a Schematic Sheet* : <https://www.altium.com/documentation/altium-designer/sch-obj-wirewire-ad>
- Altium, *Creating Circuit Connectivity in Your Schematics* : <https://www.altium.com/documentation/altium-designer/schematic/creating-circuit-connectivity>
- KiCad, *Schematic Editor 9.0* : <https://docs.kicad.org/9.0/en/eeschema/eeschema.html>
- LibrePCB 2.1.1, source complet (GPL-3.0) — fourni et lu directement, dont
  `libs/librepcb/editor/project/schematic/schematicselectionquery.cpp`
  (`addNetPointsOfNetLines`) et
  `libs/librepcb/editor/project/cmd/cmddragselectedschematicitems.cpp`
  pour la reprise d'un tracé ;
- LibrePCB 2.1.1, source (GPL-3.0) — lu directement :
  `libs/librepcb/editor/project/schematic/fsm/schematiceditorstate_drawwire.{h,cpp}`
  pour les postures et la découpe de fil, et
  `.../fsm/schematiceditorstate.cpp` (`findItemsAtPos`) pour la table de
  priorités.

---

# Le point 6, tranché : déplacer un segment

Écrit après coup, la plainte à la main : « le mouvement des fils quand on
appuie dessus une fois branché est loin d'être comme dans Simulink,
renseigne-toi et applique, repars de zéro s'il le faut ».

## Ce que fait Simulink, vérifié

Un glissé simple sur un segment le **déplace**, et le curseur change de forme
pour annoncer l'axe permis. C'est `Ctrl`+glissé qui **dérive**.

C'est la polarité **inverse** de la nôtre : ici, un clic sur un fil dérive.

## Ce qui a été retenu, et pourquoi pas la lettre de Simulink

Reprendre `Ctrl`+glissé aurait inversé une convention déjà écrite, déjà codée
et déjà éprouvée, pour un public qui n'a aucune habitude Simulink à préserver
— il n'ouvrira jamais Simulink. Le coût du réapprentissage serait payé par
l'élève, le bénéfice encaissé par une ressemblance que personne ne constatera.

Le partage retenu ne demande **aucune touche** : c'est le seuil de glissé de
Qt (`QApplication::startDragDistance()`, dix pixels) qui tranche — celui qui
sépare déjà un clic d'un glissé dans tous les logiciels que l'élève utilise.

- en deçà du seuil : **on dérive**, exactement comme avant. Zéro régression
  sur le geste le plus fréquent du logiciel ;
- au-delà, et perpendiculairement au fil : **on déplace le segment** ;
- `Ctrl`+clic : **on désigne** le fil, sans rien câbler. Les flèches le
  déplacent ensuite — ce mécanisme existait déjà et n'attendait que ça.

De Simulink, on garde donc le geste (glisser déplace), l'aimant sur la grille,
le curseur qui annonce l'axe, et le dérangement minimal. On n'en prend pas la
touche modificatrice.

## Le corollaire, réglé

« Un fil tendu entre deux broches n'a rien à déplacer. » On lui donne de quoi :
chaque extrémité tenue par une **broche** reçoit un point de fil, relié à la
broche par un bout de fil neuf ; c'est ce point qui suit la souris. Le
composant ne bouge pas d'un pixel, et rien n'est débranché — la netlist est
identique avant et après, ce que le banc vérifie.

Une extrémité qui est **déjà** un point de fil se déplace telle quelle : ses
autres fils s'allongent. C'est le dérangement minimal appliqué.

Un fil **en équerre** n'a pas d'axe unique : le déplacement lui est refusé, et
le clic y garde son sens de dérivation — ce qui permet justement d'y poser les
coudes qui le rendront d'aplomb.

Reposé là où il était, le segment ne laisse **rien** : les points insérés pour
le tenir sont retirés, et la pile d'annulation reste vide. Un geste sans effet
ne doit pas modifier la topologie — c'est le même principe que celui qui a
fait corriger le clic immobile.

## Correction : les DEUX boutons, comme dans Simulink

Le partage au seuil de glissé était une invention pour éviter une touche
modificatrice. Il ne fallait pas l'éviter — MathWorks documente **deux
boutons**, pas un seuil :

> « Déplacer des segments : cliquez sur un segment de fil horizontal ou
> vertical, glissez-le pour ajuster sa position **sans déconnecter les
> blocs**. »
> « Créer une dérivation : cliquez avec le bouton **droit** sur un fil
> existant, glissez le curseur vers le nouveau bloc. »

D'où la règle définitive, sur un fil :

| geste | effet |
|---|---|
| clic gauche | **désigne** le fil (les flèches le déplacent ensuite) |
| glissé gauche perpendiculaire | **déplace le segment** |
| glissé au bouton **droit** | **dérive** — un fil neuf naît de celui-là |
| clic droit sans glissé | menu contextuel, comme avant |

Sur une **broche**, rien ne change : le bouton gauche câble, comme dans
Simulink où l'on tire un signal d'un port à la souris.

Ce que ce partage débloque, et qui n'était pas atteignable autrement : un fil
devient **touchable**. Avant, le montrer en faisait pousser un autre.

Le seuil de glissé de Qt reste, mais pour une seule question désormais : un
clic gauche a-t-il bougé assez pour être un déplacement plutôt qu'une
désignation.

## Ce qui reste à faire

Les points 2 (auto-routage orthogonal), 5 (reroutage à dérangement minimal
lors du déplacement d'un **composant**) et 7 (échappatoire en tracé libre) ne
sont toujours pas écrits.

Trois gestes de Simulink relevés par l'utilisateur et **non repris** :

- **insérer un composant sur un fil** en le glissant par-dessus : le fil se
  coupe et le composant s'intercale. Rien de tel ici — c'est le manque le
  plus utile de la liste ;
- **`Ctrl+R` pour redresser** un fil tordu (*Smart Signal Routing*) ;
- **`Maj` pendant le glissé** pour forcer les angles droits — sans objet
  chez nous, où tout fil est déjà tracé en équerre.

## Sources ajoutées

- MathWorks, *Connect Blocks* (glissé d'un segment, `Ctrl`+glissé pour
  dériver) : <https://www.mathworks.com/help/simulink/ug/connect-blocks.html>
- Qt 6, `QApplication::startDragDistance()` — seuil clic/glissé, dix pixels
  par défaut : <https://doc.qt.io/qt-6/qapplication.html#startDragDistance-prop>
- KiCad 9, *Schematic Editor* — `G` glisse en gardant les connexions, `M`
  déplace en les détachant : <https://docs.kicad.org/9.0/en/eeschema/eeschema.html>
