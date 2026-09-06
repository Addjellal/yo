# Toolbox `conduite-automatisee`

```
% Automated Driving Toolbox — perception de voie et suivi de trajectoire.
%
% Voie
%   laneOffset      - Écart signé au centre de la voie
%
% Sécurité
%   timeToCollision - Temps avant collision, non distance
%
% Trajectoire
%   smoothPath      - Arrondit les angles d'un chemin de grille
%   purePursuit     - Suivi de chemin par poursuite pure
```

## `laneOffset`

```
LANEOFFSET Écart latéral au centre de la voie.
  ECART = LANEOFFSET(POSITION,GAUCHE,DROITE) rend la distance signée au
  milieu des deux lignes. Le signe dit de quel côté : c'est ce qui
  permet de savoir de quel bord on s'approche, non seulement de combien.

  La fonction est vectorisée : une trajectoire entière se traite d'un
  coup, et un franchissement de ligne se détecte en comparant la valeur
  absolue à la demi-largeur.

  Le centre suit les lignes où qu'elles soient : une voie décalée — en
  virage, après un rétrécissement — déplace le centre, et l'écart le
  suit.

  Exemple :
     laneOffset(0, -1.75, 1.75)      % 0 : au centre
     laneOffset(0.5, -1.75, 1.75)    % +0.5
     abs(laneOffset(2, -1.75, 1.75)) > 1.75      % ligne franchie

  Voir aussi PUREPURSUIT, SMOOTHPATH, TIMETOCOLLISION.
```

## `purePursuit`

```
PUREPURSUIT Loi de poursuite pure pour suivre un chemin.
  OMEGA = PUREPURSUIT(POSE,CHEMIN,DISTANCEVISEE,VITESSE) rend la vitesse
  angulaire à appliquer. POSE vaut [X Y THETA], CHEMIN une liste de
  points en lignes, DISTANCEVISEE la distance à laquelle regarder
  devant, VITESSE la vitesse d'avance — un par défaut.

  [OMEGA,INDICE] = PUREPURSUIT(...) rend aussi l'indice du point visé.

  Le principe tient en une phrase : viser un point du chemin situé à
  DISTANCEVISEE devant soi, et décrire l'arc de cercle qui y mène. Cet
  arc a pour courbure 2 sin(alpha) / L, où alpha est l'angle entre le
  cap et la direction du point visé, d'où

     omega = 2 V sin(alpha) / L

  Le point visé se cherche en avançant depuis le point du chemin le plus
  proche, jamais depuis le début : passé la distance de visée, le début
  du chemin est lui aussi assez loin, et le viser ferait faire demi-tour
  au véhicule.

  DISTANCEVISEE est le seul réglage. Court, le suivi est nerveux et
  oscille ; long, il coupe les virages. Il se choisit en général
  proportionnel à la vitesse.

  Exemple :
     chemin = [linspace(0, 50, 501).', zeros(501, 1)];
     purePursuit([0 1 0], chemin, 5, 5)   % decale a gauche : omega < 0
     purePursuit([0 0 0], chemin, 5, 5)   % sur le chemin : omega = 0

  Voir aussi SMOOTHPATH, LANEOFFSET, BICYCLEMODEL.
```

## `smoothPath`

```
SMOOTHPATH Lissage d'une trajectoire par descente de gradient.
  LISSE = SMOOTHPATH(CHEMIN,POIDSDONNEES,POIDSLISSAGE,TOLERANCE) arrondit
  les angles d'un chemin en arbitrant entre deux exigences : rester près
  des points d'origine, et minimiser la courbure.

  Un chemin issu d'un planificateur en grille est fait d'angles droits :
  impraticable tel quel, parce qu'aucun véhicule ne tourne sur place.
  Le lissage le rend suivable, et un chemin lissé demande moins de
  braquage — c'est la vérification qui compte.

  Les extrémités ne bougent pas et le nombre de points ne change pas :
  la fonction déplace les points intérieurs, elle n'en ajoute ni n'en
  retire.

  Les deux poids règlent le compromis : plus de lissage donne moins de
  courbure mais plus d'écart aux points d'origine. Un chemin déjà droit
  reste droit — le lissage n'invente rien.

  L'angle le plus vif s'arrondit nettement ; la courbure cumulée, elle,
  se conserve à peu près : le virage est étalé, non supprimé.

  Exemple :
     brut = [0 0; 1 0; 2 0; 3 0; 3 1; 3 2; 3 3];
     lisse = smoothPath(brut, 0.5, 0.3);
     max(vecnorm(diff(lisse, 2), 2, 2))   % bien moins que sqrt(2)

  Voir aussi PUREPURSUIT, ASTAR, LANEOFFSET.
```

## `timeToCollision`

```
TIMETOCOLLISION Temps avant collision, en secondes.
  Rend l'infini si la vitesse relative n'est pas un rapprochement.

  T = TIMETOCOLLISION(DISTANCE,VITESSERELATIVE) rend distance divisée
  par vitesse, en secondes. La fonction est vectorisée : tous les objets
  détectés se traitent d'un coup.

  La distance seule ne dit rien : trente mètres à vitesse égale sont
  sûrs, trente mètres à vingt mètres par seconde de rapprochement
  laissent une seconde et demie. C'est le temps, non la distance, qui
  décide — et le plus urgent n'est donc pas le plus proche.

  Un seuil de freinage d'urgence se pose directement sur ce temps, ce
  qui le rend indépendant de la vitesse du véhicule.

  Exemple :
     timeToCollision(30, 20)         % 1.5 s
     timeToCollision(30, 0)          % Inf : meme vitesse
     [t, k] = min(timeToCollision([50 30 6 12], [10 -2 3 20]))

  Voir aussi LANEOFFSET, PUREPURSUIT.
```

