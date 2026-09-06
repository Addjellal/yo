# Toolbox `reseaux-antennes`

```
% Phased Array System Toolbox — réseaux d'antennes.
%
% Signature d'une direction
%   steeringVector  - Le déphasage que subit chaque élément
%
% Formation de voies
%   arrayGain       - Gain du réseau pointé dans une direction
%   beamformerDAS   - Retard et somme : gain de 10 log N décibels
%
% Estimation de direction
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
     sortie = beamformerDAS(recu, 0.5, deg2rad(20));
     var(sortie) / var(beamformerDAS(recu, 0.5, deg2rad(50)))

  Voir aussi STEERINGVECTOR, MUSICSPECTRUM, ARRAYGAIN.
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
     [spectre, angles] = musicSpectrum(recu, 0.5, 2);
     [~, pics] = findpeaks(spectre / max(spectre));
     rad2deg(angles(pics))

  Voir aussi BEAMFORMERDAS, STEERINGVECTOR, ARRAYGAIN.
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

