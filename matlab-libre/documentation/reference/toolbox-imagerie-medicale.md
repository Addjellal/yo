# Toolbox `imagerie-medicale`

```
% Medical Imaging Toolbox — imagerie médicale.
%
% Tomographie
%   radonTransform  - Projections d'une image, angle par angle
%   iradonTransform - Reconstruction par rétroprojection filtrée
%
% Affichage
%   windowLevel     - Fenêtrage densitométrique, en unités Hounsfield
%
% Comparaison de segmentations
%   diceIndex       - Indice de recouvrement de deux segmentations
%   hausdorffDist   - Le pire écart local entre deux contours
```

## `diceIndex`

```
DICEINDEX Indice de Dice entre deux segmentations binaires.
  D = DICEINDEX(A,B) rend deux fois l'aire commune divisée par la somme
  des deux aires. Il vaut un quand les deux segmentations coïncident,
  zéro quand elles ne se touchent pas.

  C'est la mesure de référence pour comparer une segmentation
  automatique à celle d'un radiologue. Elle pénalise plus durement les
  petites structures que les grandes : manquer dix pixels sur cent coûte
  bien plus que dix sur mille, ce qui est voulu.

  Le Dice n'est pas la proportion de pixels bien classés : sur une image
  où la lésion occupe un pour cent de la surface, tout marquer comme
  fond donne 99 %% de bonne classification et un Dice nul. C'est
  précisément pourquoi on emploie l'un plutôt que l'autre.

  Exemple :
     a = false(10); a(3:7, 3:7) = true;
     diceIndex(a, a)                 % 1 : identiques
     b = false(10); b(5:9, 5:9) = true;
     diceIndex(a, b)                 % le recouvrement partiel
     diceIndex(a, ~a)                % 0 : disjointes

  Voir aussi HAUSDORFFDIST, BWLABEL, IMBINARIZE.
```

## `hausdorffDist`

```
HAUSDORFFDIST Distance de Hausdorff entre deux ensembles de points.
  D = HAUSDORFFDIST(A,B) rend la plus grande des distances qu'un point
  de l'un doit parcourir pour atteindre le plus proche de l'autre. A et
  B ont une ligne par point et une colonne par coordonnée.

  La distance est symétrique parce qu'elle prend le maximum des deux
  sens : sans cela, un contour entièrement contenu dans un autre
  paraîtrait à distance nulle de lui.

  Là où le Dice mesure un recouvrement global, celle-ci mesure le pire
  écart local. Deux segmentations peuvent avoir un excellent Dice et une
  mauvaise distance de Hausdorff : il suffit d'une petite excroissance
  loin du reste. C'est pourquoi on rapporte les deux.

  Exemple :
     a = [0 0; 1 0; 0 1];
     hausdorffDist(a, a)             % 0
     hausdorffDist(a, a + 0.5)       % le decalage impose
     hausdorffDist([0 0], [3 4])     % 5

  Voir aussi DICEINDEX, PDIST2.
```

## `iradonTransform`

```
IRADONTRANSFORM Rétroprojection filtrée.
  IMAGE = IRADONTRANSFORM(S,ANGLES,TAILLE) reconstruit une image à
  partir de son sinogramme. ANGLES est la liste des angles de
  projection, en degrés ; TAILLE le côté de l'image rendue.

  Rétroprojeter sans filtrer étale chaque projection sur toute l'image
  et donne un résultat flou : chaque point y contribue à tout ce qui est
  sur sa droite. Le filtre rampe — multiplier le spectre de chaque
  projection par la fréquence — corrige exactement ce flou, parce que
  l'étalement pèse les basses fréquences comme l'inverse de la
  fréquence. C'est ce qui fait que la reconstruction marche.

  Le filtre rampe amplifie donc les hautes fréquences, et avec elles le
  bruit : c'est le compromis de toute tomographie, et la raison pour
  laquelle les scanners réels adoucissent la rampe.

  Exemple :
     image = zeros(64); image(24:40, 24:40) = 1;
     s = radonTransform(image, 0:179);
     reconstruite = iradonTransform(s, 0:179, 64);

  Voir aussi RADONTRANSFORM, WINDOWLEVEL.
```

## `radonTransform`

```
RADONTRANSFORM Projections de l'image pour une série d'angles.
  [S,ANGLES] = RADONTRANSFORM(IMAGE) rend le sinogramme : une colonne
  par angle, chacune donnant la somme des valeurs de l'image le long de
  chaque droite de cet angle. Les angles vont de 0 à 179 degrés par
  défaut.
  RADONTRANSFORM(IMAGE,ANGLES) impose la liste des angles.

  C'est exactement ce que mesure un scanner : chaque détecteur relève
  l'atténuation cumulée le long d'un rayon. Reconstruire l'image à
  partir de ces sommes est le problème que résout IRADONTRANSFORM.

  Le sinogramme porte bien son nom : un point isolé de l'image y trace
  une sinusoïde, dont l'amplitude est sa distance au centre et la phase
  son azimut.

  La somme de chaque colonne est la même quel que soit l'angle — c'est
  la masse totale de l'image, que la projection conserve. C'est la
  vérification la plus simple d'un sinogramme.

  Exemple :
     image = zeros(64); image(28:36, 28:36) = 1;
     s = radonTransform(image, 0:5:175);
     sum(s(:, 1)) - sum(s(:, 10))    % 0 a l'arrondi pres

  Voir aussi IRADONTRANSFORM, WINDOWLEVEL.
```

## `windowLevel`

```
WINDOWLEVEL Fenêtrage densitométrique, comme sur une console de scanner.
  S = WINDOWLEVEL(IMAGE,CENTRE,LARGEUR) ramène entre zéro et un la bande
  d'unités Hounsfield qui va de CENTRE-LARGEUR/2 à CENTRE+LARGEUR/2 ;
  ce qui est en dessous devient noir, ce qui est au-dessus blanc.

  Un scanner mesure de -1000 (l'air) à plus de 1000 (l'os compact) : un
  écran n'en montre qu'environ 256 niveaux. Le fenêtrage choisit donc la
  tranche qu'on veut voir, et sacrifie le reste. C'est un choix, non une
  dégradation : regarder le poumon et regarder l'os demandent deux
  fenêtres différentes de la même acquisition.

  Les fenêtres usuelles, en unités Hounsfield :
     poumon      centre -600,  largeur 1500
     tissu mou   centre   40,  largeur  400
     os          centre  300,  largeur 1500
     cerveau     centre   40,  largeur   80

  Exemple :
     image = [-1000 -500 0 40 200 1000];
     windowLevel(image, 40, 400)     % fenetre tissu mou
     windowLevel(image, -600, 1500)  % fenetre poumon

  Voir aussi IMADJUST, RADONTRANSFORM, MAT2GRAY.
```

