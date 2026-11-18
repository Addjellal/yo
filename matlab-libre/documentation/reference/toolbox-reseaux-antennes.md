# Toolbox `reseaux-antennes`

```
% Phased Array System Toolbox — réseaux d'antennes.
%
% Signature d'une direction (signatures de MATLAB)
%   steervec        - Vecteurs de pointage d'un réseau quelconque, phases quantifiées
%   sensorcov       - Covariance spatiale théorique des capteurs
%
% Estimation de direction (signatures de MATLAB)
%   musicdoa        - Pics du pseudo-spectre de MUSIC
%   rootmusicdoa    - MUSIC polynomial, sans grille d'angles
%   espritdoa       - ESPRIT, par moindres carrés totaux
%
% Fonctions propres à MatLibre
%   steeringVector  - Le déphasage que subit chaque élément d'un réseau linéaire
%   arrayGain       - Gain du réseau pointé dans une direction
%   beamformerDAS   - Retard et somme : gain de 10 log N décibels
%   musicSpectrum   - Super-résolution, au prix du nombre de sources
```

## `arrayGain`

```
ARRAYGAIN Gain d'un réseau pointé dans une direction.
  G = ARRAYGAIN(N,D,THETA,THETA0) rend le gain normalisé d'un réseau
  pointé vers THETA0, pour une onde arrivant de THETA.

  Le gain vaut un dans la direction visée — toute la puissance — et bien
  moins ailleurs. Il ne peut jamais dépasser un : c'est une moyenne de
  termes de module un.

  C'est ce contraste qui sépare deux sources voisines, et son ouverture
  se resserre comme l'inverse de la longueur du réseau. À espacement
  d'une longueur d'onde, une autre direction est confondue avec la
  visée : c'est l'ambiguïté spatiale.

  Exemple :
     arrayGain(8, 0.5, 0, 0)         % 1 : dans la direction visee
     angles = linspace(-pi/2, pi/2, 3601);
     beamwidth(angles, arrayGain(8, 0.5, angles, 0))

  Voir aussi STEERINGVECTOR, BEAMFORMERDAS, MUSICSPECTRUM.
```

## `beamformerDAS`

```
BEAMFORMERDAS Formation de voies par retard et somme.
  SIGNAUX est une matrice éléments x échantillons, D l'espacement en
  longueurs d'onde, THETA la direction visée.

  Le plus simple des traitements d'antenne : remettre les capteurs en
  phase pour la direction voulue, puis sommer. Le signal de cette
  direction s'additionne de façon cohérente, le bruit non — d'où un gain
  de traitement de 10 log N décibels.

  Pointer ailleurs perd le signal : c'est bien une direction que l'on
  choisit, non un simple moyennage.

  Sa limite est l'ouverture du réseau : il ne sépare pas deux sources
  plus proches que cela, quel que soit le rapport signal à bruit. MUSIC,
  qui exploite la structure de la covariance, le peut.

  Exemple :
     rng(1);
     % Huit capteurs, une source a vingt degres, et du bruit.
     a = steeringVector(8, 0.5, deg2rad(20));
     recu = a * (randn(1, 200) + 1i * randn(1, 200)) / sqrt(2) ...
            + 0.1 * (randn(8, 200) + 1i * randn(8, 200));
     sortie = beamformerDAS(recu, 0.5, deg2rad(20));
     var(sortie) / var(beamformerDAS(recu, 0.5, deg2rad(50))) > 1    % 1

  Voir aussi STEERINGVECTOR, MUSICSPECTRUM, ARRAYGAIN.
```

## `espritdoa`

```
ESPRITDOA Directions d'arrivée par la méthode ESPRIT.
  ANG = ESPRITDOA(R,NSIG) estime, en degrés depuis la normale, les
  directions d'arrivée de NSIG ondes planes reçues par un réseau
  linéaire uniforme d'éléments espacés d'une demi-longueur d'onde, dont
  R est la covariance spatiale N x N. ANG est une ligne 1 x NSIG.
  ANG = ESPRITDOA(R,NSIG,'ElementSpacing',D) donne l'espacement en
  longueurs d'onde.

  Le réseau se voit comme deux sous-réseaux identiques décalés d'un
  élément : leurs sous-espaces signal E1 et E2 se déduisent l'un de
  l'autre par une rotation dont les valeurs propres valent exp(i 2 pi d
  sin(theta)). MatLibre la résout par moindres carrés totaux (Roy et
  Kailath, 1989), sans balayage ni recherche de racines.

  L'option 'RowWeighting' de MATLAB n'est acceptée qu'à sa valeur par
  défaut, un : une autre pondération est refusée en le disant.

  Exemple :
     % Documentation de MATLAB.
     R = sensorcov((0:9) * 0.5, [0 -25 30], db2pow(-5));
     doa = espritdoa(R, 3)               % 30, 0, -25 (dans un ordre ou un autre)

  Voir aussi ROOTMUSICDOA, MUSICDOA, SENSORCOV.
```

## `matlibre_doa_options`

```
MATLIBRE_DOA_OPTIONS Vérifie la covariance et lit les options d'estimation de direction.
  [R,D,O] = MATLIBRE_DOA_OPTIONS(R,NSIG,ARGUMENTS,FONCTION,PERMIS) rend
  la covariance rendue hermitienne, (R + R')/2 comme MATLAB, l'espacement
  D des éléments (0.5 longueur d'onde par défaut) et les autres options
  permises dans la structure O.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [R, d] = matlibre_doa_options(eye(4), 1, {}, 'rootmusicdoa', {'ElementSpacing'})

  Voir aussi ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
```

## `matlibre_positions_capteurs`

```
MATLIBRE_POSITIONS_CAPTEURS Positions de capteurs ramenées à trois lignes (x ; y ; z).
  P = MATLIBRE_POSITIONS_CAPTEURS(POS) : une ligne de POS donne y, deux
  lignes donnent (y ; z), trois lignes (x ; y ; z), comme STEERVEC.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     P = matlibre_positions_capteurs(0:0.5:1.5)     % 3 x 4

  Voir aussi STEERVEC, SENSORCOV.
```

## `musicSpectrum`

```
MUSICSPECTRUM Estimation de direction d'arrivée par la méthode MUSIC.
  [SPECTRE,ANGLES] = MUSICSPECTRUM(SIGNAUX,D,NSOURCES,ANGLES) rend un
  spectre dont les pics donnent les directions d'arrivée.

  Le principe : la matrice de covariance des signaux reçus se
  décompose en un sous-espace signal, de dimension NSOURCES, et un
  sous-espace bruit orthogonal. Les directions cherchées sont celles où
  le vecteur de pointage est orthogonal au sous-espace bruit — le
  spectre y diverge.

  La résolution n'est donc plus bornée par l'ouverture du réseau, mais
  par le rapport signal à bruit et le nombre d'échantillons. C'est ce
  qu'on appelle la super-résolution : là où la formation de voies ne
  voit qu'une bosse, MUSIC voit deux pics.

  Le prix : il faut connaître le nombre de sources. En annoncer un de
  moins en fait perdre une ; un de trop ajoute un pic parasite. C'est la
  faiblesse de la méthode, et elle est de principe.

  Exemple :
     rng(1);
     % Huit capteurs, une source a vingt degres, et du bruit.
     a = steeringVector(8, 0.5, deg2rad(20));
     recu = a * (randn(1, 200) + 1i * randn(1, 200)) / sqrt(2) ...
            + 0.1 * (randn(8, 200) + 1i * randn(8, 200));
     [spectre, angles] = musicSpectrum(recu, 0.5, 1);
     [~, k] = max(spectre);
     abs(rad2deg(angles(k)) - 20) < 5      % 1 : la source est retrouvee

  Voir aussi BEAMFORMERDAS, STEERINGVECTOR, ARRAYGAIN.
```

## `musicdoa`

```
MUSICDOA Directions d'arrivée par le spectre de MUSIC.
  DOAS = MUSICDOA(COVMAT,NSIG) cherche les NSIG pics du pseudo-spectre
  de MUSIC (Schmidt, 1986) d'un réseau linéaire uniforme d'éléments
  espacés d'une demi-longueur d'onde, dont COVMAT est la covariance
  spatiale. DOAS est une ligne de NSIG angles en degrés, du pic le plus
  haut au plus bas.
  [DOAS,SPEC,SPECANG] = MUSICDOA(...) rend aussi le spectre et ses
  angles.
  Options : 'ScanAngles' (les angles balayés, croissants, -90:90 par
  défaut) et 'ElementSpacing' (0.5 longueur d'onde par défaut).

  Le spectre vaut 1 / (a' En En' a), a = STEERVEC : il diverge là où le
  vecteur de pointage est orthogonal au sous-espace bruit En. La
  résolution ne dépend donc plus de l'ouverture du réseau, mais du
  rapport signal sur bruit et du nombre d'échantillons. Les directions
  sont celles de la grille : un angle entre deux points est arrondi.

  Exemple :
     % Documentation de MATLAB.
     covmat = sensorcov((0:10) * 0.5, [0 -12 85], db2pow(-5));
     doas = musicdoa(covmat, 3)          % 0, 85, -12

  Voir aussi ROOTMUSICDOA, ESPRITDOA, SENSORCOV, MUSICSPECTRUM.
```

## `rootmusicdoa`

```
ROOTMUSICDOA Directions d'arrivée par la méthode MUSIC polynomiale (root-MUSIC).
  ANG = ROOTMUSICDOA(R,NSIG) estime, en degrés depuis la normale, les
  directions d'arrivée de NSIG ondes planes reçues par un réseau
  linéaire uniforme d'éléments espacés d'une demi-longueur d'onde, dont
  R est la covariance spatiale N x N. ANG est une ligne 1 x NSIG.
  ANG = ROOTMUSICDOA(R,NSIG,'ElementSpacing',D) donne l'espacement en
  longueurs d'onde.

  Le sous-espace bruit En (les N - NSIG vecteurs propres des plus
  petites valeurs propres) est orthogonal aux vecteurs de pointage des
  sources. Le spectre nul a(z)' En En' a(z), où z = exp(i 2 pi d
  sin(theta)), est un polynôme en z dont les coefficients sont les
  sommes des diagonales de En En' : ses racines les plus proches du
  cercle unité donnent les directions (Barabell, 1983). Contrairement
  au spectre de MUSIC, il n'y a pas de grille d'angles à balayer.

  Exemple :
     % Documentation de MATLAB.
     R = sensorcov((0:9) * 0.5, [0 -25 30], db2pow(-5));
     doa = rootmusicdoa(R, 3)            % -25, 0, 30 (dans un ordre ou un autre)

  Voir aussi ESPRITDOA, MUSICDOA, SENSORCOV, STEERVEC.
```

## `sensorcov`

```
SENSORCOV Covariance spatiale théorique des signaux reçus par un réseau.
  XCOV = SENSORCOV(POS,ANG) rend la matrice N x N de covariance des
  capteurs pour des ondes planes de bande étroite arrivant des
  directions ANG, non corrélées et de puissance un, sans bruit :
     XCOV = A * SCOV * A' + NCOV,   A = STEERVEC(POS,ANG).
  POS et ANG ont les formes de STEERVEC.

  XCOV = SENSORCOV(POS,ANG,NCOV) ajoute le bruit : un scalaire (même
  puissance sur chaque capteur, bruits indépendants), un vecteur 1 x N
  (une puissance par capteur) ou une matrice N x N.
  XCOV = SENSORCOV(POS,ANG,NCOV,SCOV) donne la covariance des signaux :
  un scalaire (même puissance, non corrélés), un vecteur 1 x M ou une
  matrice M x M (signaux corrélés).

  Exemple :
     % Documentation de MATLAB.
     xcov = sensorcov((0:2) * 0.5, [30 60])
     % xcov(1,2) = -0.9127 - 1.4086i

  Voir aussi STEERVEC, ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
```

## `steeringVector`

```
STEERINGVECTOR Vecteur de pointage d'un réseau linéaire uniforme.
  A = STEERINGVECTOR(N,D,THETA) pour N éléments espacés de D longueurs
  d'onde, la direction THETA étant comptée en radians depuis la normale
  au réseau.

  C'est la signature d'une direction sur le réseau : le déphasage que
  subit chaque élément quand l'onde arrive de cet angle. Tout le reste —
  formation de voies, MUSIC, estimation de direction — en découle.

  Le déphasage entre voisins vaut 2 pi d sin(theta). Le vecteur est
  unimodulaire — il ne change que les phases — et de norme racine de N.

  Au-delà d'un demi-pas d'onde, deux directions distinctes donnent le
  même jeu de phases : c'est le repliement d'échantillonnage, transposé
  en espace, et c'est ce qui fixe le pas maximal d'un réseau.

  Exemple :
     a = steeringVector(8, 0.5, deg2rad(30));
     angle(a(2) / a(1))              % pi/2 : 2 pi d sin(30)

  Voir aussi ARRAYGAIN, BEAMFORMERDAS, MUSICSPECTRUM.
```

## `steervec`

```
STEERVEC Vecteurs de pointage d'un réseau de capteurs isotropes.
  SV = STEERVEC(POS,ANG) rend la matrice N x M des déphasages que subit
  chacun des N capteurs pour chacune des M ondes planes, comme MATLAB :
     SV = exp(1i * 2 * pi * POS.' * u),
  où u est le vecteur unitaire de la direction d'arrivée.

  POS donne les positions en longueurs d'onde :
     1 x N  réseau linéaire le long de l'axe y ;
     2 x N  réseau plan dans le plan yz, lignes (y ; z) ;
     3 x N  forme quelconque, lignes (x ; y ; z).
  ANG donne les directions en degrés : 1 x M azimuts (élévation nulle),
  ou 2 x M colonnes [az ; el]. L'azimut se compte de l'axe x vers l'axe
  y, l'élévation depuis le plan xy vers l'axe z.

  SV = STEERVEC(POS,ANG,NQBITS) quantifie les phases sur NQBITS bits,
  comme un déphaseur numérique : la phase est arrondie au multiple de
  2 pi / 2^NQBITS le plus proche. NQBITS = 0, la valeur par défaut, ne
  quantifie pas.

  Exemple :
     % Documentation de MATLAB.
     sv = steervec((0:0.1:0.4) / (physconst('LightSpeed') / 1e9), [45; 0])
     % 1, 0.0887 + 0.9961i, -0.9843 + 0.1767i, -0.2633 - 0.9647i, ...
     sv3 = steervec((0:0.1:0.4) / 0.2998, [45; 0], 3)   % 1, i, -1, -i, 1

  Voir aussi SENSORCOV, ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
```

