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
