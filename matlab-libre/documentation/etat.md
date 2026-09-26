# État des lieux de MatLibre

Ce document dit ce qui est fait, comment on le sait, et ce qui reste. Il
est écrit à la main ; `documentation/audit.md`, lui, est produit par
`outils/audit.m` et donne les chiffres bruts.

## 1. Ce que MatLibre est aujourd'hui

Un interpréteur du langage MATLAB écrit en C++17, et une bibliothèque de
fonctions couvrant le noyau et cinquante-trois boîtes à outils. Rien n'y
reprend de code MathWorks : chaque fonction est écrite d'après la
documentation publique et vérifiée sur la propriété qui la définit.

| partie | contenu | lignes |
|---|---|---:|
| `src/coeur` | lexeur, analyseur, interpréteur, algèbre linéaire | 10 087 |
| `src/bibliotheque` | 679 fonctions natives, en C++ | 20 223 |
| `src/graphique`, `src/console`, `src/bureau` | tracé, console, application de bureau | 5 902 |
| `toolbox` | 2 992 fichiers `.m`, dont 2 233 fonctions publiques recensées par `outils/audit.m` | 137 158 |
| `tests` | 44 scripts `.m` et 2 fichiers C++ | 24 030 |
| `exemples` | 53 programmes d'école, un par boîte à outils | 9 132 |

La couverture par rapport à la liste de référence tirée de la
documentation MathWorks est complète : `outils/manques.m` compte **2 377
fonctions attendues, 0 manquante**. La liste elle-même est vivante : une
fonction courante qui n'y figurait pas est une fonction qui n'existait
pas, et cent trente-six ont été ajoutées de cette façon — la famille
moderne des chaînes, les extrema locaux et les ruptures, les méthodes de
Krylov, les estimations de norme et de conditionnement, les graphes, les
résumés par groupe, les vingt-quatre validateurs d'arguments, les solveurs d'équations aux
dérivées partielles et de problèmes aux limites, la géométrie de calcul, les
interpolants, la lecture et l'écriture du XML, les
régions du plan et leurs opérations booléennes.

## 2. Ce qui est vérifié, et comment

Trois questions différentes, trois outils.

**Est-ce présent ?** `outils/manques.m` compare l'existant à
`documentation/reference-matlab/*.txt`, une liste par domaine. Il écrit
`documentation/manques.md`.

**Est-ce documenté ?** `outils/audit.m` mesure, pour chaque boîte à
outils, la part de fonctions dont l'aide dépasse une ligne, celles qui
portent un exemple, et celles qu'un test ou un exemple nomme. Il écrit
`documentation/audit.md`. Les trois colonnes sont à **100 %**.

**Est-ce que ça marche ?** Trois niveaux de contrôle :

- `outils/verifierExemples.m` exécute le bloc « Exemple » de chaque fiche
  `.m`, chacun dans une portée à lui. Il sert à écrire ; il a trouvé
  quatre-vingt-onze exemples cassés dans douze boîtes à outils, presque
  tous employant une variable que personne n'avait définie.
- `tests/scripts/test_aide.m` fait le même contrôle dans la suite de
  tests, sur les 655 fiches natives et les 2 198 fiches de toolbox, et
  exige de surcroît un « Voir aussi » sur chacune.
- `tests/scripts/test_exemples.m` exécute les 53 programmes d'école, qui
  ne se contentent pas d'appeler les fonctions : chacun vérifie ce que la
  théorie prédit.

La règle de vérification est la même partout : **on vérifie la propriété
qui définit la fonction, jamais une constante recopiée**. Le tableau
suivant en donne quelques-unes, prises dans les tests.

| ce qui est vérifié | propriété |
|---|---|
| dynamique du bras plan | matrice de masse, gravité et Coriolis contre la forme close, à 1e-15 |
| dynamique directe et inverse | l'une annule l'autre, à 1e-15 |
| séquences d'Euler | les douze font l'aller-retour à 2e-16 |
| cinématique inverse UR5 | converge en neuf itérations à 1e-7 |
| logarithme de matrice | `expm(logm(A)) = A` à 3e-15 sur un bloc de Jordan |
| matrices de Hadamard | orthogonales à zéro machine pour n ∈ {1,2,4,8,12,16,20,24,32} |
| transformations de bande | -3 dB en Wn pour Butterworth, l'ondulation pour Chebyshev I |
| ondelettes | reconstruction parfaite ; l'énergie des sous-bandes somme à 100 % |
| transformée de Hadamard rapide | conserve l'énergie et s'inverse au facteur N près |
| noyau de machine à vecteurs de support | symétrique, multiplicateurs dans la boîte, contrainte d'égalité tenue |
| couleurs | la matrice sRGB envoie le blanc sur D65 ; les aller-retours reviennent |
| code de Gray | deux symboles voisins ne diffèrent que d'un bit |
| entrelaceur | refuse ce qui n'est pas une permutation |
| Kalman | l'incertitude décroît en prédiction, décroît encore en correction |
| navigation à l'estime | l'erreur croît linéairement ; le filtre la borne |
| chaleur en 1-D (`pdepe`) | le mode propre sin(πx)e^(−π²t) retrouvé ; l'écart divisé par quatre quand les mailles doublent |
| symétries cylindrique et sphérique | les modes exacts J₀(j₀r)e^(−j₀²t) et sin(πr)/r e^(−π²t), à l'ordre deux |
| volumes finis (`pdepe`) | à flux nul aux deux bouts, l'intégrale de u se conserve à 1e-6 |
| problème aux limites (`bvp4c`) | sin retrouvé à 1e-6 ; x³ exactement, la formule étant d'ordre quatre |
| interpolation de `pdeval` | exacte sur les paraboles, valeurs et dérivées, maillage inégal compris |
| triangulation de Delaunay | aucun point dans un cercle circonscrit, à 1e-9 ; les triangles pavent exactement l'enveloppe convexe |
| enveloppe convexe de l'espace | Euler V − E + F = 2 ; 2n − 4 facettes quand tous les points y sont ; volume exact du cube et du tétraèdre |
| forme alpha | à rayon infini, l'aire est celle de l'enveloppe convexe ; deux amas éloignés font deux régions |
| interpolant dispersé | exact sur tout plan, et repasse par les données |
| `pchip` contre `spline` | sur une marche, l'un ne dépasse jamais, l'autre ondule de 0,128 |
| `makima` contre `akima` | sur un palier suivi d'une pente, l'un reste plat, l'autre ondule de 0,074 |
| héritage de classe | une dérivée reçoit propriétés et méthodes, la redéfinition l'emporte, `isa` remonte la chaîne |
| formats d'échange | écrire puis relire rend ce qu'on avait — lignes, XML, JSON, attributs et caractères réservés compris |
| courbe de l'espace | `plot3` garde ses trois coordonnées ; sur une hélice, les points tombent sur le cylindre à 1e-16 |
| opérations booléennes | l'union vaut la somme moins l'intersection ; un carré ôté d'un autre laisse un trou, et le centre du trou n'est plus dedans |
| factorisation symbolique | le produit des facteurs vaut l'expression de départ, en six points choisis |
| racines rationnelles | trouvées exactement par le théorème qui les borne : 6x²−5x+1 rend 1/3 et 1/2, x²+1 n'en rend aucune |
| réécriture symbolique | Euler, Weierstrass et les logarithmes : la forme change, la valeur reste, à la précision machine |
| éléments simples | le produit des termes vaut la fraction de départ, en quatre points choisis |
| dérivées hyperboliques et réciproques | comparées à une différence finie, jamais recopiées d'une table |
| une poignée graphique | dit sa vraie classe ; deux sortes concaténées restent des poignées |
| `onCleanup` | la tâche part au retour normal, au `return` anticipé et sur une erreur ; l'ordre est celui d'une pile ; un échec n'arrête pas les autres |
| magasins de données | la boucle « tant qu'il reste, lire » se termine, ne saute rien et ne compte rien deux fois ; la réunion des morceaux redonne le tout |
| magasins appariés et transformés | `combine` s'arrête sur le plus court des magasins, jamais sur le plus long ; `transform` n'évalue sa fonction qu'à la lecture, et sur le morceau lu — le dernier, plus court, lui arrive tel quel |
| calcul différé (`tall`) | `gather` rend exactement ce qu'aurait rendu la même chaîne sur le tableau ordinaire, et une chaîne bâtie sur un calcul qui échoue ne se manifeste qu'au `gather` — preuve qu'aucune étape n'a eu lieu avant |
| matrices symboliques | `A*inv(A)` développé puis évalué en un point rend l'identité, sans qu'aucun pivot n'ait été supposé non nul |
| échange des niveaux d'une table | `inner2outer` appliqué deux fois redonne la table de départ : aucune donnée ne bouge, seule la façon de la nommer change |
| Parquet | la table relue porte les mêmes valeurs et les mêmes classes ; et le fichier de référence de `tests/donnees`, écrit par une autre implémentation, se lit ici — sans quoi l'aller-retour ne prouverait que la cohérence de MatLibre avec lui-même |
| encodages de caractères | `native2unicode(unicode2native(t))` rend `t`, et l'aller-retour par les points de code conserve jusqu'aux caractères à quatre octets |
| spline « not-a-knot » | elle reproduit exactement tout polynôme de degré trois, et à trois points la parabole qui passe par eux |
| réponse impulsionnelle | `y(0)` vaut `C*B`, non zéro : une impulsion charge l'état, et la réponse est la réponse libre qui suit |
| programme linéaire | le point rendu respecte les contraintes, une par une ; un problème sans solution est annoncé comme tel plutôt que résolu de travers, et `intlinprog` s'y appuie pour ne rendre que des entiers admissibles |
| drapeaux des solveurs | ils disent la vérité : `quadprog` et `fmincon` rendent -2 et un résultat vide quand aucun point n'est admissible, `fsolve` -2 quand le résidu n'est pas nul, `fminsearch` 0 quand c'est le compteur d'itérations qui l'a arrêté |
| légende et barre de couleurs | leur chaîne est la leur : écrire dans la légende ne touche pas au titre de l'axe, et le relire ne rend pas le titre à sa place |
| arbre graphique | une figure a ses axes pour enfants, un axe a sa figure pour parent, et `delete` retire vraiment l'objet du tracé |
| aller-retour de `squareform` | il est exact pour deux points comme pour mille : un scalaire est le vecteur de distances d'une paire, non la matrice d'un point unique |
| cycles d'un graphe | chaque cycle est énuméré une fois et une seule — le graphe complet à quatre sommets en a sept, quatre triangles et trois quadrilatères ; la base de cycles en compte E − N + C |
| condensation | elle est toujours sans circuit : s'il en restait un, les composantes qu'il relie n'en feraient qu'une |
| réduction transitive | elle a la même fermeture transitive que le graphe de départ, avec le moins d'arcs possible |
| isomorphisme de graphes | la permutation rendue transporte effectivement les arêtes ; deux graphes de même suite de degrés ne sont pas pour autant isomorphes — le cycle à six sommets n'est pas la réunion de deux triangles |
| schéma-bloc | le rang d'un bloc est le plus long chemin qui y mène, non le plus court : une sommation alimentée par deux branches attend la plus longue ; un lien qui referme une boucle est mis à part, et tracé en retour à sa propre profondeur |
| ordre de calcul d'un schéma | un bloc à transmission directe est calculé après son entrée, fût-il déclaré avant elle : le carré d'une rampe vaut t², non t² d'un pas plus tôt |
| intégrateur discret | les trois méthodes de Simulink se distinguent exactement d'un demi-pas d'échantillonnage sur une entrée constante — Euler avant l'intègre juste, Euler arrière avance d'un pas, le trapèze d'un demi |
| batteries croisées sur le catalogue | chaque type de bloc est simulé seul, sur un scalaire et sur un vecteur, refermé sur lui-même dans une boucle sous trois solveurs, placé seul dans un sous-système activé, déclenché, itéré ou masqué, puis en amont et en aval des autres : plus de deux mille modèles, dont aucun ne tombe sur une erreur interne — chacun se simule, ou il est refusé par une erreur `Simulink:…` dont le message nomme le bloc par son chemin, comme le ferait Simulink. Les paires complètes — treize mille modèles — ont trouvé une Transfer Fcn réduite à un gain qui ne se simulait pas, et une MATLAB Function qui ne se laissait pas refermer dans une boucle |
| paramètres fautifs | chaque paramètre de chaque bloc reçoit une valeur qu'on pourrait taper par erreur — une variable qui n'existe pas, NaN, vide, une matrice, un nombre négatif, un complexe, une expression mal formée : 1 808 essais, et chacun se simule ou tombe sur une erreur de Simulink qui nomme le bloc. Une erreur imprévue pendant la compilation nomme le bloc qu'on compilait ; pendant la simulation, `sim` la rejoue en notant chaque bloc calculé, pour nommer celui où elle tombe et le paramètre qui paraît fautif |
| retard pur | il décale sans déformer : sur une rampe, la sortie est la rampe elle-même translatée du retard, à 1e-12 |
| linéarisation | sur un modèle linéaire, LINMOD rend exactement les matrices que la théorie donne, valeurs propres comprises ; sur une saturation, la pente locale — un dans la bande, zéro au-delà |
| point d'équilibre | TRIM rend la dérivée qu'il a atteinte, non seulement le point : un équilibre se reconnaît à ce que DX y est nul |
| modèle enregistré | SAVE_SYSTEM puis LOAD_SYSTEM redonnent le même câblage, les mêmes paramètres — matrices comprises — et le même comportement sous LINMOD |
| taille d'une figure | `figure('Position',…)` la fixe vraiment : le SVG porte la largeur et la hauteur demandées, et une unité que MatLibre ne mesure pas est refusée plutôt qu'ignorée |
| espace de travail partagé | un paramètre de bloc écrit `'K'` vaut ce que vaut K au moment où l'on simule : changer K et relancer `sim` change le résultat sans que le modèle ait bougé, et le modèle porte toujours l'expression, non sa valeur |
| échanges avec l'espace de travail | un bloc « vers l'espace de travail » y crée sa variable, et un bloc « depuis l'espace de travail » relit la sienne — aux instants donnés, la valeur donnée ; entre eux, la droite qui les joint ; au-delà, la dernière tenue |
| bibliothèque du bureau | chacun des quarante blocs que la fenêtre Simulink propose est posé puis simulé par le test : elle ne peut donc pas offrir au clic un bloc que `sim` ne connaîtrait pas |
| l'éditeur suit l'espace de travail | un bloc ajouté au modèle depuis la console paraît sur la toile de l'éditeur sans qu'on y touche : le test le vérifie en comptant les blocs et les liens que l'explorateur montre |
| la toile et le SVG s'accordent | une surface remplie est peinte de la même façon des deux côtés — la toile figeait l'opacité à 0,4 et prenait le contour sur la couleur de fond, si bien qu'un polygone blanc au bord noir y perdait son bord ; c'est mesuré en comptant des pixels |
| la toile se travaille | prendre un bloc et le déplacer pose sa POSITION dans le modèle, tirer depuis son bord droit jusqu'à un autre bloc pose un lien, « Suppr » retire ce qui est choisi : chaque geste devient une commande, et le test la vérifie en événements de souris puis en relisant le modèle |
| un fil ne revient pas sur ses pas | quand la cible n'est pas devant la source — ce qu'un bloc déplacé à la souris rend courant —, le fil contourne par un couloir et entre par la gauche ; une liaison directe aurait rebroussé chemin, la pointe de flèche à l'envers |
| une place tenue | un bloc qui porte POSITION garde sa place : le rangement par couches ne le déplace plus, et la figure d'OPEN_SYSTEM le montre là où l'éditeur l'a laissé — une seule géométrie pour les deux |
| les réglages d'un bloc | un double-clic les ouvre ; seuls les champs touchés ressortent en `set_param`, et le renommage vient en dernier — quand l'ancien nom désigne encore le bloc |
| renommer un bloc | `set_param(m,'k','Name','correcteur')` le renomme au lieu de poser un réglage nommé Name, les liens le suivent — ils désignent les blocs par leur rang — et le modèle se simule encore |
| défaire et refaire | chaque modification met l'état d'avant en réserve, et `Ctrl+Z` le rend ; un chemin neuf efface ce qu'on pouvait refaire, et défaire quand il n'y a rien à défaire rend le modèle tel quel plutôt que d'échouer |
| choisir plusieurs blocs | un rectangle tracé sur le vide prend ce qu'il touche, `Ctrl+A` prend tout, `Échap` lâche tout ; les déplacer les déplace tous, en une seule commande |
| du schéma au programme | le `.m` que MATLIBRE_SL_PROGRAMME écrit rend les mêmes nombres que `sim`, au bit près — écart maximal nul sur tous les signaux —, sans appeler Simulink : des variables, une boucle sur les instants, de l'arithmétique |
| un réglage figé vaut sa valeur | un gain écrit `'K'` devient `4 * ecart` dans le programme engendré, et la lettre n'y paraît plus : le programme ne peut pas dépendre d'un espace de travail qu'il n'a pas, et changer K après coup ne le change plus |
| un bloc qui ne s'écrit pas est nommé | ce que le traducteur ne sait pas rendre est refusé sous `Simulink:programme:BlocNonEcrit`, le bloc nommé, plutôt que traduit de travers |
| l'aller-retour du schéma | `save_system` puis relecture redonnent le même câblage et les mêmes réglages — l'expression, non sa valeur ; c'est le seul des deux chemins qui revienne, on ne remonte pas d'un calcul au schéma qui l'aurait produit |
| un sous-système est le schéma qu'il abrège | un modèle où un correcteur est enfermé dans un bloc rend, au bit près, ce que rend le même schéma écrit à plat — deux niveaux d'emboîtement compris ; le relevé porte ses blocs sous le nom « sousSysteme/bloc », et le sous-système lui-même la valeur de sa sortie |
| les entrées d'un sous-système se raccordent par leur rang | le lien qui arrive sur la deuxième entrée va au bloc INPORT dont Port vaut 2, quel que soit l'ordre où les INPORT ont été écrits ; un lien sur une entrée qui n'existe pas est refusé en nommant le bloc |
| un schéma emboîté s'écrit et se relit | le `.m` qu'écrit `save_system` bâtit le modèle du sous-système dans sa propre variable avant de le donner au bloc, et le modèle relu se simule à l'identique |
| descendre et remonter | un double-clic sur un sous-système ouvre son schéma dans la toile ; ce qu'on y modifie en sort, est modifié, et y est reposé — en une seule commande, si bien que `Ctrl+Z` le défait d'un coup |
| un retard est porté ou refusé, jamais oublié | `InputDelay`, `OutputDelay` et `IODelay` sont des propriétés du modèle : la réponse temporelle est la même décalée — écart nul après le décalage —, la réponse fréquentielle vaut exactement `H(jw)·e^(-jwD)`, et le module n'en bouge pas d'un ulp |
| un retard mange la marge | un double intégrateur n'a pas de marge de gain finie ; un retard de 0,3 s lui en donne une — c'est ce que `margin` doit voir, et ne voyait pas quand le retard était rangé sans être lu |
| ce qui ne sait pas porter un retard le nomme | `lqr`, `kalman`, `rlocus`, `feedback` et `connect` refusent un modèle retardé sous `Control:ltiobject:delayNotSupported` ; un retour d'état calculé sur (A,B,C,D) aurait ignoré le temps de transport, et le correcteur aurait eu l'air réglé sans l'être |
| Padé serre le retard à chaque ordre | l'écart de phase au retard exact décroît strictement de l'ordre 1 à 3 à 6, et vaut moins d'un millionième de degré à l'ordre six : c'est la propriété qui définit l'approximation, non une tolérance choisie |
| une réponse à plusieurs voies se superpose | `lsim` sur deux entrées rend la somme des réponses à chacune, et chaque sortie la somme des voies qui y arrivent ; `step` et `impulse` rendent NT × NY × NU, `bode` NY × NU × NW, et chaque case égale la voie prise seule par `sys(i,j)` |
| le bloqueur d'ordre zéro est exact, intégrateurs compris | un échelon sur `1/s²` donne `t²/2` exactement aux instants de la grille ; l'ancienne formule se rabattait sur `B·dt` dès que A n'était pas inversible, et rendait 12,475 au lieu de 12,5 à cinq secondes |
| une marge ne se mesure que sur une voie | `margin`, `allmargin` et `bandwidth` refusent une matrice de transferts sous `Control:analysis:RequiresSISO`, au lieu de rendre un nombre calculé sur un tableau aplati |
| la norme d'un modèle | `norm(sys)` rendait 0 — la norme numérique appliquée à l'objet ; c'est la norme H2, égale à `sqrt(trace(C·Wc·C'))` par le grammien, et `norm(sys,Inf)` la norme H∞ |
| valeurs propres généralisées, B singulière | `eig(A,B)` rendait des nombres quelconques par `B\A` ; les valeurs finies annulent à présent `det(A − λB)`, il y a autant de valeurs infinies que B a perdu de rang, et un faisceau singulier rend NaN, comme MATLAB |
| zéros de transmission à plusieurs voies | la matrice de Rosenbrock perd son rang au zéro rendu : `(s+3)/(s+1)` apporte son zéro en −3, exactement |
| une propriété qu'une classe ne déclare pas est refusée | l'écrire la posait sur l'objet, où personne ne la lisait : `sys.InputDelay = 2` avait l'air pris et ne valait rien. L'interpréteur la refuse à présent en nommant la classe et ses propriétés |
| un clic n'est pas un déplacement | choisir un bloc sans le bouger n'écrit plus sa POSITION dans le modèle : la pile d'annulation ne grossit plus d'un état identique, et la commande qui suit le clic ne se perd plus, refusée pendant ce calcul inutile |
| l'ordre d'un solveur se mesure | l'erreur d'ode1, ode2, ode3 et ode4 décroît comme le pas à la puissance 1, 2, 3 et 4 : halver le pas la divise par 2, 4, 8 et 16 — c'est mesuré sur `x' = −x`, dont la solution est connue, et non recopié d'une table |
| un oscillateur non amorti | Euler en enfle l'amplitude, ode4 le suit : au même pas, l'écart au cosinus passe de 5·10⁻² à 7·10⁻¹⁰ ; c'est la différence qui compte en pratique, non la pente asymptotique |
| un état qui n'est pas continu ne s'intègre pas à mi-pas | un modèle portant un retard ou un bloc échantillonné est refusé sous ode2, ode3 ou ode4 en nommant le bloc, et se simule sans rien dire sous ode1 |

## 3. État par boîte à outils

Les trois colonnes de mesure sont à 100 % partout ; la colonne
« profondeur » dit ce qui est réellement couvert, et c'est elle qui
distingue une boîte complète d'une boîte esquissée.

| boîte à outils | fonctions | profondeur |
|---|---:|---|
| statistiques | 272 | complète : lois, tests, régression, classification, mélanges, HMM |
| signal | 205 | complète : conception RIF et RII, analogique et numérique, spectres, mesures d'impulsion |
| matlab | 290 | noyau du langage, en complément des 673 natives |
| finance | 148 | complète : indicateurs techniques, portefeuille, actualisation |
| images | 138 | complète : morphologie, filtres, couleur, segmentation, texture |
| ondelettes | 129 | complète : DWT, paquets, MODWT, CWT, débruitage |
| communications | 115 | complète : modulations, codage, canaux, mesures |
| automatique | 108 | complète : représentations, réponses, lieux, correcteurs |
| apprentissage-profond | 76 | couches, entraînement, différentiation automatique |
| robuste | 73 | valeurs singulières, marges, incertitude |
| flou | 70 | Mamdani et Sugeno, ANFIS, partitionnement |
| robotique | 62 | arbre de corps rigides, RNEA, cinématique inverse, mobiles |
| vision | 60 | points d'intérêt, appariement, géométrie épipolaire, flot optique |
| instruments-financiers | 55 | obligations, options, courbes de taux, arbres |
| types | 40 | tables, temps, durées, catégories |
| econometrie, gestion-risques | 31 | ARIMA, GARCH, valeur en risque, grilles de score |
| identification | 27 | ARX, ARMAX, OE, BJ, sous-espace |
| symbolique | 44 | dérivation, intégration, simplification, limites |
| ajustement-courbes | 23 | modèles nommés, surfaces, lissage |
| optimisation, optimisation-globale | 35 | linéaire, quadratique, non linéaire, génétique, recuit |
| interface | 15 | composants et rappels, sans boucle d'événements modale |
| simulink | 27 | schémas-blocs : cent vingt types de blocs, signaux vecteurs, boucles algébriques, pas fixe et pas variable avec passages par zéro, linéarisation, équilibre |
| les 30 autres | 2 à 9 | esquisses : les fonctions les plus employées du domaine |

Les boîtes de deux à neuf fonctions — acquisition, aérospatial, audio,
lidar, maintenance prédictive, radar, RF, véhicule… — ne prétendent pas
couvrir leur domaine. Elles en donnent le rouage central, vérifié, et un
programme d'école qui montre à quoi il sert.

## 4. Ce qui reste à faire

| sujet | état | ce qu'il faudrait |
|---|---|---|
| Interface graphique | `interface` rend des poignées et exécute les rappels au fil de l'eau ; il n'y a pas de boucle d'événements modale | une boucle d'événements, pour que `uiwait` attende vraiment |
| Simulink | cent vingt types de blocs — sources, opérations, logique, non-linéarités, aiguillage, continus, discrets, sous-systèmes, sorties — sur des signaux scalaires, vecteurs et matrices, avec des blocs à plusieurs sorties ; chaque modèle est compilé comme dans Simulink — paramètres, ports, dimensions, périodes vérifiés, chaque erreur nommant le bloc par son chemin — puis ordonné ; les boucles algébriques sont résolues par Newton ; tous les solveurs de Simulink : ode1 à ode5, ode8, ode1be et ode14x (implicites), odeN (la formule que choisit sa méthode d'intégration) et FixedStepDiscrete à pas fixe ; ode45, ode23, ode113 (Adams, ordre variable), ode15s (NDF, ordre variable), daessc (BDF, ordre variable), ode23s, ode23t et ode23tb (raides) à pas variable, avec détection et localisation des passages par zéro, arrêt exact sur les instants d'échantillonnage et les cassures des sources ; les sous-systèmes conditionnels — Enable, Trigger, If, Switch Case, Merge —, avec la tenue ou la remise à zéro de leurs sorties et de leurs états ; les sous-systèmes appelés par un Function-Call Generator ; les sous-systèmes itérés — For Iterator, While Iterator —, qui calculent plusieurs fois par pas ; les blocs de code — Fcn, MATLAB Function avec ses variables persistantes, Interpreted MATLAB Function, S-fonctions de niveau 1 et de niveau 2 (Level-2 MATLAB S-Function : setup, ports dynamiques, paramètres, états continus, vecteurs de travail, Outputs, Update, Derivatives, sur le bloc `Simulink.MSFcnRunTimeBlock`) — et le bloc Chart, qui fait tourner une machine Stateflow un pas par instant — états emboîtés, régions parallèles, historique, logique temporelle en réveils ou en secondes, étiquettes et actions écrites dans le langage d'action (« en: du: ex: », « evenement[condition]{action} », after(3, tick)) ; la boîte « Paramètres de configuration » (Ctrl+E) règle le solveur, les tolérances et les diagnostics ; les blocs courants de la bibliothèque — Chirp, Signal Generator, Band-Limited White Noise, compteurs, Repeating Sequence Stair, Saturation et Dead Zone Dynamic, Wrap To Zero, Interval Test, Manual Switch, mémoires partagées (Data Store Memory, Read, Write), Rate Transition, IC, Width, intégrateur du second ordre, Discrete Derivative, Difference, Tapped Delay, Discrete Zero-Pole, XY Graph, To File ; les filtres discrets (Discrete Transfer Fcn, Discrete Filter) sur un vecteur ou une matrice, chaque élément une voie ; l'intégrateur de Simulink en entier — remise externe sur front ou sur niveau, condition initiale externe, ports de saturation et d'état —, de quoi bâtir la balle qui rebondit ; les masques des sous-systèmes, les bibliothèques et leurs liens ; les bus par nom (Bus Creator, Bus Selector) et leurs types — `Simulink.Bus` et `Simulink.BusElement`, que Bus Creator, entrées, sorties et ports de sous-système prennent par 'Bus: Nom', bus emboîtés compris, avec `Simulink.Bus.createMATLABStruct` et `createObject` — ; la conversion de type (entiers, simple, booléen, arrondi, saturation) ; `linmod`, `dlinmod` et `trim` ; `save_system` écrit un `.m` qui rebâtit le modèle, un `.slx`, ou un programme qui *fait ce qu'il fait* ; `load_system` lit les `.slx` et `.mdl` ; les entrées externes (`sim(m, t, opt, [t, u])`, `LoadExternalInput`, `ExternalInput`) ; les références de modèle, relues à chaque simulation ; les rappels du modèle (`InitFcn`, `StartFcn`, `StopFcn`, `PreLoadFcn`, `PostLoadFcn`, `PreSaveFcn`, `PostSaveFcn`, `CloseFcn`) et `SimulationCommand` ; `sim` sans sortie dépose `out` ; les tables n-D à deux dimensions et les tables directes ; l'éditeur du bureau pose, câble, règle et simule, sous-systèmes masqués compris | types de données propagés d'un bloc à l'autre ; fonctions graphiques, jonctions et tables de vérité de Stateflow |
| Simscape | circuits électriques linéaires, continu et transitoire | composants non linéaires, autres domaines physiques |
| Coder | sous-ensemble scalaire et matriciel vers C et C++ | structures, cellules, fonctions imbriquées |
| Symbolique | dérivation — trigonométriques, hyperboliques, réciproques, logarithmes de toute base —, intégration des formes usuelles, limites, séries de Taylor, jacobienne et hessienne, développement, regroupement, forme de Horner, éléments simples, isolement d'une inconnue, réécriture entre familles de fonctions, factorisation sur les rationnels, résolution exacte des polynômes et numérique du reste, sortie LaTeX | factorisation au-delà des racines rationnelles — x⁴+1 reste entier —, décomposition en éléments simples, arithmétique rationnelle exacte, expressions à plusieurs variables dans COLLECT et FACTOR |
| Calcul parallèle | `parfor`, `spmd` et `parfeval` s'exécutent vraiment sur un pool de fils ; chaque travailleur est un interpréteur neuf, sans mémoire partagée | tableaux distribués sur plusieurs machines, GPU |
| Grandes matrices creuses | stockage et opérations de base ; PCG, BICG, CGS, MINRES et GMRES résolvent sans former la matrice ; ICHOL et ILU préconditionnent, SYMRCM, SYMAMD et COLAMD réordonnent | factorisations creuses complètes — LU et Cholesky creux avec leur permutation |
| Lecture de fichiers | `.mat` v4, v6 et v7, CSV, images PGM et PPM en texte ; un `.mat` v7.3 est reconnu et refusé avec la raison | HDF5, donc `.mat` v7.3 ; PNG, JPEG et TIFF, qui demandent une bibliothèque externe |
| Équations aux dérivées partielles | `pdepe` résout le cas parabolique et elliptique en 1-D, en plan, cylindrique et sphérique, par volumes finis et méthode des lignes ; `bvp4c` les problèmes aux limites par collocation d'ordre quatre | maillage adaptatif dans `bvp4c`, qui garde celui qu'on lui donne ; `bvp5c`, `ode15i`, les EDP en deux et trois dimensions |
| Classes | `classdef` complet : propriétés, méthodes, opérateurs surchargés, `subsref`/`subsasgn`, méthodes statiques, événements, héritage simple et multiple avec appel au constructeur du parent, les paquets — un dossier `+geo` fait `geo.f` et `geo.Point`, emboîtés à toute profondeur —, et la réflexion — `methods`, `properties`, `events`, `enumeration`, `metaclass`, `superclasses` | les membres énumérés comme valeurs — seuls leurs noms se relisent —, le destructeur `delete` d'une classe `handle` (`onCleanup` est écrit au niveau de la portée, ce qui couvre son usage mais pas l'effacement d'une variable), les attributs d'accès (`Access`, `SetAccess`) |
| Géométrie du plan | `polyshape` porte les régions percées, les mesures, les transformations et les quatre opérations booléennes par l'algorithme de Greiner et Hormann | la simplification d'un contour qui se recoupe, et le traitement exact des contacts — deux régions qui se touchent sont séparées d'un cheveu, ce qui coûte six chiffres de précision sur ces cas-là |
| Magasins de données | `datastore`, `tabularTextDatastore`, `imageDatastore` et `arrayDatastore` se parcourent par morceaux — `read`, `hasdata`, `reset`, `readall`, `preview` — et se copient par référence, comme dans MATLAB ; `combine` les apparie du même pas et `transform` applique un prétraitement morceau par morceau, sans rien évaluer avant la lecture | la lecture réellement paresseuse : le fichier est lu une fois pour toutes puis découpé, si bien que le programme est le même mais que la mémoire n'est pas économisée — ce qui est pourtant la seule raison d'employer un magasin. les tableaux répartis reposent dessus et n'en tirent donc pas plus |
| Calcul différé | `tall` diffère vraiment : arithmétique, comparaisons, réductions, indexation logique et filtrage se décrivent sans rien exécuter, et `gather` rend exactement ce qu'aurait rendu la même chaîne sur le tableau ordinaire | l'exécution hors mémoire : le `gather` calcule en mémoire, si bien que le programme est celui de MATLAB mais que la taille des données reste bornée par la mémoire |
| Matrices symboliques | `symmatrix` garde l'algèbre au niveau de la matrice — somme, produit, transposée, inverse, déterminant, trace, puissance, Kronecker — et `symmatrix2sym` descend aux coefficients par cofacteurs | les identités matricielles démontrées sans descendre aux coefficients, et les fonctions de matrice |
| Java | absent, et déclaré tel : `usejava` rend faux, `isjava` aussi, `javaclasspath` est vide, et les constructeurs échouent avec « MATLAB:Java:NoJVM » | une machine virtuelle Java, qui demanderait une dépendance d'un autre ordre |
| Parquet | `parquetwrite`, `parquetread` et `parquetinfo` écrivent et lisent le format en colonnes : protocole compact Thrift pour les métadonnées, encodage PLAIN pour les données, classes restituées par le type converti, colonnes facultatives lues par leurs niveaux de définition | la compression et l'encodage en dictionnaire, refusés par leur nom ; les colonnes répétées ; les valeurs absentes dans une colonne entière, booléenne ou textuelle, faute de valeur pour les dire |
| Graphes | `graph` et `digraph` portent les parcours, les plus courts chemins, les composantes, l'arbre couvrant, le flot maximal, la centralité, et désormais l'énumération des cycles et des chemins simples, la base de cycles, la fermeture et la réduction transitives, la condensation, la renumérotation et l'isomorphisme | la réduction transitive d'un graphe à circuits, refusée parce qu'elle n'y est pas unique ; les composantes biconnexes |
| Boîtes esquissées | 30 boîtes de 2 à 9 fonctions | les compléter domaine par domaine, en gardant la règle : rien sans test |
| Performance | l'interpréteur est un parcours d'arbre | compilation en bytecode, vectorisation des boucles internes |
| Durée des tests | les quarante-quatre scripts tournent de front, autant que la machine a de cœurs ; chacun écrit dans son journal, et seul celui qui échoue est montré. `make test SERIE=1` les remet en file | la suite est passée de cinquante minutes à trente-deux, mesurées sur quatre cœurs. Le gain s'arrête là : elle ne peut plus descendre sous son plus long script, et `test_aide` en occupe à lui seul près de trente — il faudrait le découper pour aller plus loin |

Aucun de ces points n'est une régression : ce sont des limites connues,
écrites dans l'aide des fonctions concernées, qui disent ce qu'elles ne
font pas plutôt que de rendre un résultat faux.

## 5. Ce qu'on ne trouvera pas ici

Une fonction qui ment. La règle tenue tout au long est qu'une fonction
qui ne sait pas faire le dit et lève une erreur — `openfig`, `uicontrol`,
`ginput` en sont les exemples — plutôt que de rendre une valeur
vraisemblable. C'est ce qui permet de se fier au reste.
