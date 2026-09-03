# Toolbox `ondelettes`

```
% Wavelet Toolbox — analyse en ondelettes.
%
% Bancs de filtres
%   wfilters          - Filtres d'analyse et de synthèse (dbN, symN, haar,
%                       biorNr.Nd, rbioNd.Nr)
%   orthfilt          - Banc orthogonal à partir du filtre d'échelle
%   biorfilt          - Banc biorthogonal à partir des deux filtres
%   daubechiesFiltre  - Filtre de Daubechies par factorisation spectrale
%   qmf               - Miroir en quadrature d'un filtre
%   wavefun           - Fonctions d'échelle et d'ondelette (cascade)
%   wavenames         - Liste des ondelettes disponibles
%   dwtmode           - Mode de prolongement des bords
%   waveinfo          - Renseignements sur une famille d'ondelettes
%   centfrq           - Fréquence centrale d'une ondelette
%   scal2frq          - Conversion échelle vers fréquence
%
% Familles d'ondelettes
%   dbaux, dbwavf     - Filtre d'échelle de Daubechies, par ordre ou par nom
%   symaux, symwavf   - Filtre d'échelle d'un symlet
%   biorwavf          - Couple biorthogonal spline
%   rbiowavf          - Le même, analyse et synthèse échangées
%   meyer, meyeraux   - Ondelette de Meyer et sa fonction de transition
%   mexihat           - Chapeau mexicain
%   morlet            - Ondelette de Morlet réelle
%   gauswavf          - Dérivées de la gaussienne, ordres 1 à 8
%   cgauwavf          - Les mêmes, modulées : gaussiennes complexes
%   cmorwavf          - Morlet complexe
%   shanwavf          - Ondelette de Shannon
%   fbspwavf          - Spline en fréquence
%
% Transformée discrète, une dimension
%   dwt, idwt         - Transformée à un niveau et son inverse
%   wavedec, waverec  - Décomposition et reconstruction multiniveaux
%   wmaxlev           - Niveau maximal utile
%   appcoef, detcoef  - Extraction des coefficients d'un niveau
%   wrcoef            - Reconstruction d'un seul niveau
%   upcoef            - Reconstruction directe d'un vecteur de coefficients
%   upwlev            - Remontée d'un niveau dans la décomposition
%   wenergy           - Répartition de l'énergie par niveau
%
% Transformée stationnaire et à chevauchement maximal
%   swt, iswt         - Transformée stationnaire d'un signal
%   swt2, iswt2       - La même, pour une image
%   modwt, imodwt     - Transformée à chevauchement maximal
%   modwtmra          - Analyse multirésolution correspondante
%   modwtvar          - Variance par échelle
%   modwtcorr         - Corrélation par échelle entre deux signaux
%   modwtxcorr        - Corrélation croisée par échelle
%
% Transformée continue
%   cwt, icwt         - Transformée continue et son inverse
%
% Transformée discrète, deux dimensions
%   dwt2, idwt2       - Transformée à un niveau et son inverse
%   wavedec2, waverec2 - Décomposition et reconstruction multiniveaux
%   appcoef2, detcoef2 - Extraction des coefficients d'un niveau
%   wrcoef2           - Reconstruction d'un seul niveau
%   upcoef2           - Reconstruction directe d'un bloc de coefficients
%   upwlev2           - Remontée d'un niveau dans la décomposition
%   wenergy2          - Répartition de l'énergie par niveau
%   wthcoef2          - Seuillage ou atténuation par bloc
%   wavefun2          - Les quatre fonctions de la base bidimensionnelle
%   wcodemat          - Mise à l'échelle pour l'affichage
%
% Transformées redondantes
%   swt, iswt         - Transformée stationnaire (à trous)
%   modwt, imodwt     - Transformée à chevauchement maximal
%   modwtmra          - Analyse multirésolution associée
%   cwt               - Transformée continue (mexh, morl, gausP, dbN)
%
% Débruitage et compression
%   wthresh           - Seuillage dur ou doux
%   wthcoef           - Seuillage des coefficients d'une décomposition
%   thselect          - Choix du seuil (rigrsure, heursure, sqtwolog, minimaxi)
%   wnoisest          - Estimation robuste de l'écart type du bruit
%   ddencmp           - Réglages par défaut du débruitage
%   wdencmp           - Débruitage ou compression par seuillage
%   wdenoise          - Débruitage par seuillage universel
%   wdenoise2         - Le même, pour une image
%   wden              - Débruitage automatique, interface d'origine
%   wnoise            - Signaux d'essai de Donoho et Johnstone
%   measerr           - Mesures de qualité : PSNR, erreur, énergie gardée
%
% Paquets d'ondelettes
%   wpdec, wprec      - Décomposition et reconstruction d'un signal
%   wpdec2, wprec2    - Les mêmes, pour une image
%   wpcoef, wprcoef   - Coefficients d'un nœud, composante d'un nœud
%   wpsplt, wpjoin    - Scinder une feuille, refermer une branche
%   leaves, tnodes    - Nœuds terminaux
%   ntnode, treedpth  - Nombre de feuilles, profondeur de l'arbre
%   depo2ind, ind2depo - Indice d'un nœud et son couple profondeur-place
%   wentropy          - Entropie d'un bloc de coefficients
%   besttree          - Meilleure base au sens de l'entropie
%   wpthcoef          - Seuillage des coefficients de l'arbre
%   wpdencmp          - Débruitage ou compression par paquets
%   wpfun             - Fonctions de paquets W0, W1, W2, ...
%   modwpt, imodwpt   - Paquets à chevauchement maximal, en ordre de
%                       séquence
%
% Séries longue mémoire
%   wfbm              - Mouvement brownien fractionnaire
%   wfbmesti          - Estimation du paramètre de Hurst
%   wvarchg           - Détection de ruptures de variance
%
% Outils sur les signaux
%   wextend           - Prolongement aux bords (9 modes)
%   wkeep             - Extraction centrée
%   wrev              - Renversement
%   dyadup, dyaddown  - Sur- et sous-échantillonnage dyadique
%   wconv1, wconv2    - Convolution en une et deux dimensions
```

## `appcoef`

```
APPCOEF Coefficients d'approximation d'une décomposition WAVEDEC.
  A = APPCOEF(C,L,ONDELETTE) rend l'approximation du dernier niveau.
  A = APPCOEF(C,L,ONDELETTE,N) reconstruit celle du niveau N.
```

## `appcoef2`

```
APPCOEF2 Coefficients d'approximation d'une image décomposée.
  A = APPCOEF2(C,S,NOM,N) reconstruit l'approximation du niveau N.
```

## `besttree`

```
BESTTREE Meilleur arbre de paquets au sens de l'entropie.
  T = BESTTREE(T) élague l'arbre : un nœud garde ses enfants si leur
  entropie totale est plus petite que la sienne, sinon ils sont
  supprimés. La base retenue est celle qui concentre le plus l'énergie
  du signal, ce qui est exactement ce qu'on veut pour comprimer ou
  débruiter.

  La recherche remonte des feuilles vers la racine : chaque nœud est
  comparé au meilleur de ses descendants, si bien que le résultat est
  optimal sur tout l'arbre, non seulement de proche en proche.

  [T,E,E0] = BESTTREE(T) rend aussi l'entropie retenue et l'entropie
  propre de chaque nœud, indexées comme « donnees ».

  Le critère est celui que WPDEC a enregistré ; WENTROPY les décrit.

  Exemple :
     t = wpdec(sin((1:256) / 3), 4, 'db2');
     meilleur = besttree(t);
     ntnode(meilleur) <= ntnode(t)  % vrai : l'arbre est élagué

  Voir aussi WENTROPY, WPDEC, WPDEC2, LEAVES, WPJOIN.
```

## `biorfilt`

```
BIORFILT Banc de filtres biorthogonal à partir des deux filtres d'échelle.
  [LO_D,HI_D,LO_R,HI_R] = BIORFILT(DF,RF) construit le banc à partir du
  filtre d'échelle d'analyse DF et de celui de synthèse RF, que rend
  BIORWAVF.

  Les relations sont celles du banc biorthogonal :

     Lo_D[n] = DF[N+1-n],       Lo_R[n] = RF[n],
     Hi_D[n] = (-1)^n Lo_R[n],  Hi_R[n] = (-1)^(n+1) Lo_D[n],

  chaque filtre d'échelle étant d'abord normalisé à une somme de racine
  de deux. Le passe-haut d'analyse se lit sur le passe-bas de synthèse,
  et le passe-haut de synthèse sur le passe-bas d'analyse : c'est là
  toute la différence avec l'orthogonal, où un seul filtre suffit. Le
  croisement est ce qui fait que

     conv(Lo_D,Lo_R) + conv(Hi_D,Hi_R)

  vaut deux au centre et zéro partout ailleurs — la reconstruction
  parfaite.

  Ces relations donnent Hi_D(z) = -Lo_R(-z) et Hi_R(z) = Lo_D(-z) :
  c'est ce qui annule le repliement, la partie du signal que le
  sous-échantillonnage a repliée. Encore faut-il que les deux filtres
  d'échelle soient alignés à un décalage pair près, faute de quoi le
  demi-bande change de parité et le repliement subsiste — la distorsion
  restant nulle, l'erreur ne se voit qu'à la reconstruction. C'est
  pourquoi les zéros de complètement s'ajoutent par paires à gauche.

  Exemple :
     [df, rf] = biorwavf('bior2.2');
     [lod, hid, lor, hir] = biorfilt(df, rf);
     max(abs(conv(lod, lor) + conv(hid, hir) - ...
             [zeros(1, numel(lod) - 1), 2, zeros(1, numel(lod) - 1)]))

  Voir aussi BIORWAVF, RBIOWAVF, ORTHFILT, WFILTERS.
```

## `biorwavf`

```
BIORWAVF Filtres d'une ondelette biorthogonale spline.
  [RF,DF] = BIORWAVF('biorNr.Nd') rend le filtre d'échelle de synthèse
  RF et celui d'analyse DF, tous deux de somme un et complétés de zéros
  pour avoir la même longueur — c'est la convention de MATLAB.

  La construction est celle de Cohen, Daubechies et Feauveau : le
  filtre de synthèse est le spline d'ordre Nr, c'est-à-dire le binôme
  (1+z)^Nr ; le produit des deux filtres doit être le demi-bande de
  Daubechies d'ordre L = (Nr+Nd)/2, ce qui détermine l'analyse. Nr+Nd
  doit donc être pair.

  L'intérêt du biorthogonal est la symétrie : aucune ondelette
  orthogonale à support compact ne l'est, sauf Haar. On la retrouve en
  séparant analyse et synthèse.

  Les noms reconnus sont bior1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1,
  3.3, 3.5, 3.7, 3.9 et 4.4 — cette dernière étant le couple 9/7 de
  JPEG 2000. bior5.5 et bior6.8 de MATLAB ne sont pas des splines mais
  des couples ajustés au plus près de l'orthonormalité : ils ne sortent
  pas de cette construction, et sont refusés plutôt qu'approchés.

  Exemple :
     [rf, df] = biorwavf('bior2.2');
     sum(rf)                        % 1
     max(abs(rf - fliplr(rf)))      % 0 : le filtre est symétrique

  Voir aussi BIORFILT, RBIOWAVF, WFILTERS, DBWAVF.
```

## `centfrq`

```
CENTFRQ Fréquence centrale d'une ondelette.
  F = CENTFRQ(NOM) rend la fréquence de la raie dominante du spectre de
  la fonction d'ondelette, en cycles par unité de support. C'est elle
  qui fait le lien entre échelle et fréquence (voir SCAL2FRQ).

  L'ondelette est échantillonnée par WAVEFUN sur son support [0, L-1] ;
  la transformée de Fourier discrète d'une période exacte de ce support
  a donc un pas de 1/(L-1) hertz, et la fréquence centrale est un
  multiple entier de ce pas.

  F = CENTFRQ(NOM,ITER) fixe le nombre d'itérations de la cascade
  (8 par défaut).

  Les ondelettes continues — 'mexh', 'morl', 'gausP' — sont
  échantillonnées sur leur support effectif : [-8, 8] pour le chapeau
  mexicain et Morlet, [-5, 5] pour les gaussiennes. Le pas fréquentiel
  vaut alors 1/16 et 1/10.

  Exemple :
     centfrq('db2')    % 0.6667 = 2/3
     centfrq('db4')    % 0.7143 = 5/7
     centfrq('mexh')   % 0.2500 = 4/16
     centfrq('morl')   % 0.8125 = 13/16

  Voir aussi SCAL2FRQ, WAVEFUN.
```

## `cgauwavf`

```
CGAUWAVF Ondelette gaussienne complexe.
  [PSI,X] = CGAUWAVF(LB,UB,N,P) échantillonne sur N points de [LB,UB]
  la dérivée P-ième de exp(-i x) exp(-x^2), normalisée à une norme deux
  unitaire. P va de 1 à 8.

  La modulation par exp(-i x) rend l'ondelette complexe : sa
  transformée ne couvre que les pulsations positives, si bien que la
  transformée continue en rend module et phase séparément — ce qu'une
  ondelette réelle ne permet pas.

  La dérivée se calcule par récurrence sur le polynôme qui multiplie
  l'exponentielle : P_0 = 1, P_{k+1} = P_k' + (-2x - i) P_k.

  Exemple :
     [psi, x] = cgauwavf(-5, 5, 1000, 1);
     trapz(x, abs(psi) .^ 2)        % un
     abs(trapz(x, psi))             % nul : moyenne nulle

  Voir aussi GAUSWAVF, CMORWAVF, SHANWAVF, MEXIHAT, CWT.
```

## `cmorwavf`

```
CMORWAVF Ondelette de Morlet complexe.
  [PSI,X] = CMORWAVF(LB,UB,N,FB,FC) échantillonne sur N points de
  [LB,UB] l'ondelette

     psi(x) = 1/sqrt(pi FB) exp(2 i pi FC x) exp(-x^2 / FB),

  où FB est le paramètre de largeur de bande (un par défaut) et FC la
  fréquence centrale (un par défaut).

  C'est une gaussienne modulée : sa transformée est une gaussienne
  centrée sur FC. Plus FB est grand, plus l'ondelette est étalée en
  temps et fine en fréquence — c'est le réglage du compromis.

  Exemple :
     [psi, x] = cmorwavf(-8, 8, 1000, 1.5, 1);
     trapz(x, abs(psi) .^ 2)        % 1/sqrt(2 pi FB) : la norme deux

  Voir aussi MORLET, CGAUWAVF, SHANWAVF, FBSPWAVF, CWT.
```

## `convolutionCirculaire`

```
CONVOLUTIONCIRCULAIRE Corrélation périodique, longueur conservée.
  Le signal est prolongé périodiquement : la sortie a exactement la
  longueur de l'entrée, ce qu'exige la transformée stationnaire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `cwt`

```
CWT Transformée en ondelettes continue.
  C = CWT(X,ECHELLES,NOM) rend une ligne de coefficients par échelle :

     C(a,b) = 1/sqrt(a) * somme_k X(k) psi((k-b)/a)

  NOM peut désigner une ondelette continue — 'mexh' (chapeau mexicain,
  par défaut), 'morl' (Morlet réelle), 'gausP' pour P de 1 à 8 — ou une
  ondelette discrète, 'dbN' ou 'symN', dont la fonction d'ondelette est
  alors calculée par l'algorithme en cascade puis rééchantillonnée.

  [C,F] = CWT(X,ECHELLES,NOM,DELTA) rend en plus les pseudo-fréquences
  associées aux échelles, DELTA étant le pas d'échantillonnage :
  F = CENTFRQ(NOM) ./ (ECHELLES * DELTA).

  Les bords ne sont pas prolongés : la somme se limite aux indices
  présents, ce qui atténue les coefficients sur une largeur d'échelle
  à chaque extrémité.

  Exemple :
     t = (0:1023) / 1024;
     x = sin(2 * pi * 60 * t);
     [c, f] = cwt(x, 1:64, 'morl', 1/1024);
     [~, k] = max(max(abs(c), [], 2));
     f(k)     % voisin de 60 Hz

  Voir aussi CENTFRQ, SCAL2FRQ, MEXIHAT, MORLET, GAUSWAVF.
```

## `daubechiesFiltre`

```
DAUBECHIESFILTRE Filtre d'échelle de Daubechies à N moments nuls.
  LO = DAUBECHIESFILTRE(N) construit le filtre de longueur 2N par
  factorisation spectrale, sans recopier aucune table.

  La méthode est celle de Daubechies : le module carré du filtre vaut

     |H(w)|^2 = 2 cos(w/2)^(2N) P(sin(w/2)^2),
     P(y) = somme des C(N-1+k, k) y^k,

  et l'on en prend une racine carrée en factorisant P. Chaque racine de
  P donne une paire de racines réciproques en z : garder celle de
  l'intérieur donne le filtre à phase minimale, c'est-à-dire dbN ;
  choisir la combinaison la moins asymétrique donne le symlet symN.

  PHASE vaut 'minimale' (par défaut) ou 'symetrique'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `dbaux`

```
DBAUX Filtre d'échelle de Daubechies d'ordre N.
  W = DBAUX(N) rend le filtre d'échelle de l'ondelette dbN, de longueur
  2N et de somme un.
  W = DBAUX(N,SOMME) le normalise à la somme donnée ; SOMME nulle
  demande la normalisation en norme deux, c'est-à-dire une somme de
  racine de deux — celle du banc orthonormé.

  Le filtre n'est pas lu dans une table : il vient de la factorisation
  spectrale du polynôme de Daubechies, et existe donc à tout ordre.

  Exemple :
     w = dbaux(2);
     sum(w)                         % 1
     norme = dbaux(2, 0);
     sum(norme .^ 2)                % 1 : le filtre orthonormé

  Voir aussi DBWAVF, SYMAUX, WFILTERS, ORTHFILT.
```

## `dbwavf`

```
DBWAVF Filtre d'échelle d'une ondelette de Daubechies.
  F = DBWAVF('dbN') rend le filtre d'échelle de dbN, de longueur 2N et
  de somme un. C'est DBAUX(N), pris par le nom de l'ondelette.

  'db1' et 'haar' désignent la même ondelette.

  Exemple :
     F = dbwavf('db4');
     numel(F)                       % 8
     sum(F)                         % 1

  Voir aussi DBAUX, SYMWAVF, WFILTERS, WAVEINFO.
```

## `ddencmp`

```
DDENCMP Réglages par défaut du débruitage ou de la compression.
  [THR,SORH,KEEPAPP] = DDENCMP('den','wv',X) rend le seuil universel de
  Donoho et Johnstone mis à l'échelle du bruit estimé, le seuillage
  doux, et l'ordre de garder l'approximation. 'cmp' vise la
  compression : le seuillage y est dur et le seuil plus bas.

  [THR,SORH,KEEPAPP,CRIT] = DDENCMP('den','wp',X) donne les réglages
  pour une décomposition en paquets d'ondelettes ; CRIT nomme alors le
  critère d'entropie, et le seuil tient compte du nombre de bases que
  la recherche du meilleur arbre explore.

  Le bruit est estimé par l'écart médian absolu des détails du premier
  niveau, divisé par 0.6745 : c'est l'estimateur robuste standard, qui
  rend l'écart type d'une gaussienne.

  Exemple :
     [thr, sorh, keepapp] = ddencmp('den', 'wv', randn(1, 256));

  Voir aussi WDENCMP, THSELECT, WNOISEST.
```

## `depo2ind`

```
DEPO2IND Indice d'un nœud d'arbre, à partir de sa profondeur et de sa place.
  N = DEPO2IND(ORD,[D P]) rend l'indice du nœud de profondeur D et de
  position P dans un arbre d'ordre ORD — deux pour un signal, quatre
  pour une image :

     N = (ORD^D - 1) / (ORD - 1) + P.

  La racine porte l'indice zéro. Les indices numérotent l'arbre en
  largeur : tous les nœuds d'une profondeur avant ceux de la suivante.

  [D P] peut avoir plusieurs lignes ; N en a alors autant.

  Exemple :
     depo2ind(2, [0 0])             % 0 : la racine
     depo2ind(2, [1 1])             % 2
     depo2ind(2, [3 5])             % 12

  Voir aussi IND2DEPO, WPDEC, LEAVES, TNODES.
```

## `detcoef`

```
DETCOEF Coefficients de détail d'un niveau donné.
  D = DETCOEF(C,L,N) extrait le bloc du niveau N dans le vecteur rendu
  par WAVEDEC. Le niveau 1 est le plus fin.

  Exemple :
     [c, l] = wavedec(1:8, 2, 'db1');
     numel(detcoef(c, l, 1))   % 4
```

## `detcoef2`

```
DETCOEF2 Coefficients de détail d'une image décomposée.
  D = DETCOEF2('h',C,S,N) rend le détail horizontal du niveau N ;
  'v' le vertical, 'd' le diagonal, 'compact' ou 'all' les trois.
```

## `dilaterFiltres`

```
DILATERFILTRES Insère 2^niveau - 1 zéros entre les coefficients.
  C'est l'algorithme « à trous » : au lieu de décimer le signal, on
  étire le filtre, ce qui garde toutes les positions.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `dwt`

```
DWT Transformée en ondelettes discrète, un niveau.
  [A,D] = DWT(X,NOM) rend l'approximation et le détail, sous-échantillonnés
  d'un facteur deux. Les bords sont prolongés périodiquement, ce qui
  correspond au mode 'per' de MATLAB : A et D comptent chacun
  NUMEL(X)/2 échantillons.

  L'analyse convolue le signal par les filtres de décomposition, ce qui
  revient à le corréler avec ces mêmes filtres renversés :

     A(k) = somme_j Lo_D(N+1-j) X(2k-2+j)
     D(k) = somme_j Hi_D(N+1-j) X(2k-2+j)

  Pour une ondelette orthogonale, Lo_D renversé est Lo_R : c'est la
  forme habituelle. Pour une biorthogonale les deux diffèrent, et c'est
  bien le filtre d'analyse qu'il faut employer ici.

  Exemple :
     [a, d] = dwt([1 2 3 4], 'haar')   % a = [2.1213 4.9497]
                                       % d = [-0.7071 -0.7071]

  Voir aussi IDWT, WAVEDEC, WFILTERS, SWT, MODWT.
```

## `dwt2`

```
DWT2 Transformée en ondelettes discrète bidimensionnelle, un niveau.
  [CA,CH,CV,CD] = DWT2(X,ONDELETTE) rend l'approximation et les détails
  horizontal, vertical et diagonal. La transformée est séparable : on
  applique DWT aux lignes puis aux colonnes.

  Exemple :
     [a, h, v, d] = dwt2(ones(4), 'db1');   % a = 2*ones(2), h = v = d = 0
```

## `dwtmode`

```
DWTMODE Mode de prolongement des bords de la transformée discrète.
  DWTMODE affiche le mode courant.
  DWTMODE(MODE) le change. MODE vaut 'per' (périodique), 'zpd'
  (zéros), 'sym' (symétrie), 'spd' (prolongement affine), 'sp0'
  (répétition du bord), 'ppd' (périodique sans ajustement de parité).
  ST = DWTMODE('status') rend le mode courant sans rien afficher.
  DWTMODE(MODE,'nodisp') change le mode sans l'annoncer.

  MatLibre ne sait analyser qu'en périodique : DWT, WAVEDEC et leurs
  voisines prolongent le signal par périodicité, ce qui garde le nombre
  de coefficients égal à celui des échantillons. Le mode est donc lu et
  conservé, mais seul 'per' est accepté ; demander autre chose lève une
  erreur au lieu d'analyser autrement que promis.

  Exemple :
     dwtmode('status')              % 'per'
     dwtmode('per', 'nodisp');

  Voir aussi DWT, WAVEDEC, WEXTEND.
```

## `dyaddown`

```
DYADDOWN Sous-échantillonnage dyadique : un échantillon sur deux.
  Y = DYADDOWN(X) garde les indices pairs ; DYADDOWN(X,1) les impairs.

  Exemple :
     dyaddown([1 2 3 4 5])      % [2 4]
     dyaddown([1 2 3 4 5], 1)   % [1 3 5]
```

## `dyadup`

```
DYADUP Suréchantillonnage dyadique : un zéro entre deux échantillons.
  Y = DYADUP(X) intercale des zéros à partir de l'indice 2 ;
  DYADUP(X,0) les intercale à partir de l'indice 1.

  Exemple :
     dyadup([1 2 3])      % [1 0 2 0 3]
     dyadup([1 2 3], 0)   % [0 1 0 2 0 3 0]
```

## `fbspwavf`

```
FBSPWAVF Ondelette spline en fréquence.
  [PSI,X] = FBSPWAVF(LB,UB,N,M,FB,FC) échantillonne sur N points de
  [LB,UB] l'ondelette

     psi(x) = sqrt(FB) sinc(FB x / M)^M exp(2 i pi FC x),

  où M est l'ordre du spline (entier au moins un, deux par défaut), FB
  la largeur de bande (un par défaut) et FC la fréquence centrale (un
  par défaut).

  Élever le sinus cardinal à la puissance M revient à convoler la porte
  avec elle-même M fois : la transformée est le spline d'ordre M, donc
  toujours à support borné, mais de bords adoucis. M vaut un pour
  l'ondelette de Shannon.

  Exemple :
     [psi, x] = fbspwavf(-20, 20, 1000, 2, 1, 1.5);
     [shan, ~] = fbspwavf(-20, 20, 1000, 1, 1, 1.5);
     max(abs(shan - shanwavf(-20, 20, 1000, 1, 1.5)))   % nul

  Voir aussi SHANWAVF, CMORWAVF, CGAUWAVF, CWT.
```

## `filtresSplines`

```
FILTRESSPLINES Couple de filtres biorthogonaux splines.
  [RF,DF] = FILTRESSPLINES(NR,ND) construit le couple de Cohen,
  Daubechies et Feauveau : RF est le binôme d'ordre NR, DF le filtre
  d'ordre ND qui complète le demi-bande.

  Le produit RF(z) DF(1/z) doit valoir le demi-bande de Daubechies

     H(w) = 2 (1-y)^L P(y),   y = sin(w/2)^2,   L = (Nr+Nd)/2,
     P(y) = somme_{k<L} C(L-1+k,k) y^k,

  qui est le seul polynôme de ce degré à annuler ses L premières
  dérivées aux deux bouts.

  Reste à répartir P entre les deux filtres. Jusqu'à l'ordre trois,
  tout P va du côté de l'analyse : la synthèse est alors le spline pur,
  ce qui est la famille « bior » de Cohen, Daubechies et Feauveau — le
  5/3 de bior2.2, le 8/4 de bior3.3. À l'ordre quatre, ce partage
  donnerait un filtre de cinq coefficients contre un de onze ; on
  partage alors les racines en deux groupes de longueurs aussi voisines
  que possible, ce qui donne pour bior4.4 une analyse de neuf
  coefficients et une synthèse de sept — le couple 9/7 de JPEG 2000.

  Un groupe de racines n'est pas séparable : il réunit une racine, sa
  conjuguée, son inverse et l'inverse de sa conjuguée. C'est ce qui
  garde chaque filtre réel et symétrique.

  Les deux filtres sortent de même longueur, complétés de zéros comme
  le fait MATLAB, et de somme un.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `gauswavf`

```
GAUSWAVF Ondelettes gaussiennes : les dérivées de exp(-x^2).
  [PSI,X] = GAUSWAVF(LB,UB,N,P) échantillonne sur N points de [LB,UB] la
  dérivée P-ième de la gaussienne, normalisée à une norme deux unitaire.
  P va de 1 à 8. La dérivée s'écrit avec les polynômes d'Hermite :

     d^p/dx^p exp(-x^2) = (-1)^p H_p(x) exp(-x^2)

  et la constante de normalisation se calcule exactement par Parseval :

     ||d^p/dx^p exp(-x^2)||^2 = sqrt(2 pi) (2p-1)!! / 2

  Exemple :
     [psi, x] = gauswavf(-5, 5, 1000, 1);
     trapz(x, psi .^ 2)   % un

  Voir aussi MEXIHAT, MORLET, CWT.
```

## `icwt`

```
ICWT Transformée en ondelettes continue inverse.
  X = ICWT(C,ECHELLES,NOM) reconstruit le signal à partir des
  coefficients que rend CWT, par la formule de reconstruction à une
  seule somme :

     X(b) = (1/K) somme_a Re C(a,b) da / a^(3/2)

  où da est le pas local entre échelles : la somme approche ainsi
  l'intégrale, que les échelles soient réparties linéairement ou par
  octaves.

  K n'est pas une constante tabulée, ni même une constante : analyse
  puis somme forment un filtre, qu'on mesure en transformant une
  impulsion, et qu'on inverse dans la bande où il a du gain. Diviser
  par une seule constante laisserait plusieurs dixièmes d'erreur, le
  gain n'étant pas plat ; inverser le filtre les efface.

  Ce que les échelles ne couvrent pas n'est pas reconstruit : la
  composante continue et tout ce qui sort de la bande sont perdus, et
  c'est fidèle à ce que la transformée a réellement gardé. Les bords
  restent approchés, la transformée continue y étant tronquée.

  X = ICWT(...,'Constante') emploie au lieu de cela le gain moyen dans
  la bande, comme la formule de reconstruction d'usage : plus grossier,
  mais sans repli possible.

  Exemple :
     t = (0:511) / 512;
     x = sin(2 * pi * 8 * t);
     echelles = 2 .^ (0:0.25:6);
     y = icwt(cwt(x, echelles, 'morl'), echelles, 'morl');
     norm(y - x) / norm(x)          % quelques centièmes

  Voir aussi CWT, CENTFRQ, SCAL2FRQ.
```

## `idwt`

```
IDWT Reconstruction à partir de l'approximation et du détail.
  X = IDWT(A,D,NOM) inverse DWT. L'extension étant périodique,
  l'inverse redistribue chaque coefficient sur les positions que
  l'analyse avait lues, cette fois avec les filtres de synthèse.

  X = IDWT(A,D,NOM,L) ne garde que les L premiers échantillons : c'est
  ce qu'il faut quand le signal analysé était de longueur impaire, DWT
  l'ayant alors prolongé d'un point.

  Exemple :
     [a, d] = dwt(1:8, 'db2');
     max(abs(idwt(a, d, 'db2') - (1:8)))   % nul à l'arrondi près

  Voir aussi DWT, WAVEREC, WFILTERS.
```

## `idwt2`

```
IDWT2 Reconstruction bidimensionnelle, un niveau.
  Réciproque de DWT2 : on remonte d'abord les colonnes, puis les lignes.

  Exemple :
     [a,h,v,d] = dwt2(magic(4), 'db2');
     max(max(abs(idwt2(a,h,v,d,'db2') - magic(4))))   % nul
```

## `imodwpt`

```
IMODWPT Paquets d'ondelettes à chevauchement maximal, inverse.
  X = IMODWPT(W) reconstruit le signal à partir des paquets que rend
  MODWPT. X = IMODWPT(W,NOM) nomme l'ondelette ('sym4' par défaut).

  La reconstruction est exacte : la transformée est un cadre ajusté de
  constante un, comme la MODWT dont elle sort.

  Exemple :
     x = cos((1:256) / 7);
     max(abs(imodwpt(modwpt(x, 3), 'sym4') - x))   % nul

  Voir aussi MODWPT, IMODWT, WPREC.
```

## `imodwt`

```
IMODWT Transformée à chevauchement maximal inverse.
  Reconstruction exacte : la MODWT est un cadre ajusté de constante 1.
```

## `ind2depo`

```
IND2DEPO Profondeur et place d'un nœud, à partir de son indice.
  [D P] = IND2DEPO(ORD,N) est l'inverse de DEPO2IND : la profondeur D
  est le plus grand entier tel que (ORD^D - 1)/(ORD - 1) ne dépasse pas
  N, et P ce qui reste.

  N peut être un vecteur ; le résultat a alors une ligne par nœud.

  Exemple :
     ind2depo(2, 0)                 % [0 0]
     ind2depo(2, 12)                % [3 5]
     ind2depo(2, [1 2 3])           % [1 0; 1 1; 2 0]

  Voir aussi DEPO2IND, WPDEC, LEAVES, TREEDPTH.
```

## `indiceDeNoeud`

```
INDICEDENOEUD Indice d'un nœud donné par son numéro ou par [D P].

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `iswt`

```
ISWT Transformée en ondelettes stationnaire inverse.
  X = ISWT(SWA,SWD,NOM) reconstruit le signal. Comme la transformée
  est redondante, la reconstruction moyenne les deux décimations
  possibles à chaque niveau.

  Exemple :
     [a, d] = swt(1:8, 2, 'haar');
     max(abs(iswt(a, d, 'haar') - (1:8)))   % nul

  Voir aussi SWT, ISWT2, IMODWT, IDWT.
```

## `iswt2`

```
ISWT2 Transformée stationnaire inverse d'une image.
  X = ISWT2(A,H,V,D,NOM) reconstruit l'image à partir des quatre
  familles que rend SWT2.

  La transformée étant redondante, chaque niveau se reconstruit en
  moyennant les décimations possibles : le facteur est un quart en deux
  dimensions, contre un demi en une.

  Exemple :
     [a, h, v, d] = swt2(magic(8), 2, 'haar');
     max(max(abs(iswt2(a, h, v, d, 'haar') - magic(8))))   % nul

  Voir aussi SWT2, ISWT, WAVEREC2, IDWT2.
```

## `leaves`

```
LEAVES Nœuds terminaux d'un arbre de paquets d'ondelettes.
  N = LEAVES(T) rend, en colonne et par indice croissant, les nœuds que
  l'arbre ne scinde pas : ce sont eux qui portent la décomposition.

  N = LEAVES(T,'dp') les rend sous la forme [profondeur position].
  N = LEAVES(T,'sort') les trie par profondeur puis par position, ce
  qui revient au même que par indice.
  N = LEAVES(T,'sortdp') combine les deux.

  [N,TAILLES] = LEAVES(T) rend aussi la taille des coefficients de
  chaque feuille.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     leaves(t)'                     % 7 8 9 10 11 12 13 14
     leaves(t, 'dp')                % huit lignes [3 0] .. [3 7]

  Voir aussi TNODES, NTNODE, TREEDPTH, WPDEC, BESTTREE.
```

## `lireNoeud`

```
LIRENOEUD Coefficients d'un nœud, vides s'il n'est pas dans l'arbre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `measerr`

```
MEASERR Mesures de qualité entre un signal et son approximation.
  [PSNR,MSE,MAXERR,L2RAT] = MEASERR(X,XAPP) compare l'approximation
  XAPP à l'original X et rend :
    PSNR    rapport signal sur bruit de crête, en décibels
    MSE     erreur quadratique moyenne
    MAXERR  plus grand écart en valeur absolue
    L2RAT   rapport des énergies, XAPP sur X

  MEASERR(X,XAPP,BPS) donne le nombre de bits par échantillon, dont
  dépend la valeur de crête : 2^BPS - 1. Par défaut, huit bits.

  Le PSNR est la mesure d'usage pour juger une compression : il
  rapporte l'erreur à la dynamique du codage, non au signal lui-même,
  ce qui le rend comparable d'une image à l'autre.

  Exemple :
     x = double(0:255);
     approx = x + 0.5;
     [p, m, e, r] = measerr(x, approx);
     m                              % 0.25
     e                              % 0.5

  Voir aussi WDENCMP, WDENOISE, WTHRESH, WPDENCMP.
```

## `mexihat`

```
MEXIHAT Ondelette « chapeau mexicain ».
  [PSI,X] = MEXIHAT(LB,UB,N) échantillonne sur N points de [LB,UB] la
  dérivée seconde de la gaussienne, normalisée à une norme deux
  unitaire :

     psi(x) = 2 / (sqrt(3) pi^(1/4)) * (1 - x^2) * exp(-x^2/2)

  Elle a deux moments nuls et pas de fonction d'échelle : c'est une
  ondelette de la transformée continue seulement.

  Exemple :
     [psi, x] = mexihat(-5, 5, 1000);
     trapz(x, psi)          % nul : moyenne nulle
     trapz(x, psi .^ 2)     % un

  Voir aussi MORLET, GAUSWAVF, CWT.
```

## `meyer`

```
MEYER Ondelette et fonction d'échelle de Meyer.
  [PSI,X] = MEYER(LB,UB,N) échantillonne l'ondelette de Meyer sur N
  points de [LB,UB]. N doit être une puissance de deux.
  [PHI,X] = MEYER(LB,UB,N,'phi') rend la fonction d'échelle ;
  'psi' (défaut) rend l'ondelette.

  L'ondelette de Meyer est définie par sa transformée de Fourier, à
  support borné et infiniment dérivable :

     phi(w) = 1                          si |w| <= 2 pi/3,
     phi(w) = cos(pi/2 nu(3|w|/(2pi)-1)) si 2 pi/3 <= |w| <= 4 pi/3,
     phi(w) = 0                          au-delà,

  où nu est MEYERAUX. L'ondelette s'en déduit par la relation
  habituelle du banc de filtres. Elle n'est pas à support compact, mais
  décroît plus vite que toute puissance : c'est le compromis inverse de
  celui des Daubechies.

  Exemple :
     [psi, x] = meyer(-8, 8, 1024);
     abs(trapz(x, psi))             % nul : moyenne nulle

  Voir aussi MEYERAUX, MORLET, MEXIHAT, WAVEFUN.
```

## `meyeraux`

```
MEYERAUX Fonction auxiliaire de l'ondelette de Meyer.
  Y = MEYERAUX(X) évalue

     nu(x) = 35 x^4 - 84 x^5 + 70 x^6 - 20 x^7.

  C'est le polynôme de plus bas degré qui vaut zéro en zéro, un en un,
  et dont les trois premières dérivées s'annulent aux deux bouts. Il
  sert de transition douce dans la fenêtre de Meyer : c'est cette
  platitude qui donne à l'ondelette sa décroissance rapide.

  La fonction complémentaire vérifie nu(x) + nu(1-x) = 1, ce qui fait
  de la fenêtre une partition de l'unité.

  Exemple :
     meyeraux(0)                    % 0
     meyeraux(1)                    % 1
     meyeraux(0.5) + meyeraux(0.5)  % 1

  Voir aussi MEYER, MORLET, MEXIHAT.
```

## `modwpt`

```
MODWPT Paquets d'ondelettes à chevauchement maximal.
  W = MODWPT(X) décompose X en paquets sans décimation, jusqu'au niveau
  quatre : W a 2^4 lignes, toutes de la longueur du signal, rangées par
  bande de fréquence croissante.

  W = MODWPT(X,NIVEAU) impose le niveau ; W = MODWPT(X,NOM) ou
  MODWPT(X,NOM,NIVEAU) choisit l'ondelette ('fk18' n'existe pas ici ;
  'sym4' est le défaut).

  [W,E] = MODWPT(...) rend en outre l'énergie relative de chaque bande.
  Leur somme vaut un : comme la MODWT, la transformée conserve
  l'énergie.

  Les lignes sont en ordre de séquence, non en ordre naturel : à chaque
  scission, un nœud de rang impair échange ses deux voies, ce qui remet
  les bandes dans l'ordre des fréquences. Sans cette permutation, la
  ligne K ne correspondrait pas à la K-ième bande.

  Exemple :
     t = (0:1023) / 1024;
     x = sin(2 * pi * 100 * t);
     [w, e] = modwpt(x, 3);
     [~, k] = max(e);               % la bande qui porte le ton

  Voir aussi IMODWPT, MODWT, WPDEC, MODWTMRA.
```

## `modwt`

```
MODWT Transformée en ondelettes à chevauchement maximal.
  W = MODWT(X,NOM,N) rend N+1 lignes : les N détails, puis
  l'approximation. Comme SWT, elle ne décime pas ; à la différence de
  SWT, ses filtres sont divisés par racine de deux à chaque niveau, ce
  qui conserve l'énergie : la somme des carrés des lignes vaut celle du
  signal.

  Exemple :
     w = modwt(1:8, 'haar', 2);
     abs(sum(sum(w.^2)) - sum((1:8).^2))   % nul
```

## `modwtcorr`

```
MODWTCORR Corrélation par échelle entre deux signaux.
  R = MODWTCORR(W1,W2) rend le coefficient de corrélation entre les
  deux transformées, échelle par échelle. On voit ainsi à quelle
  échelle deux séries se ressemblent : deux signaux peuvent être liés
  sur le long terme et indépendants d'un jour à l'autre.

  R = MODWTCORR(W1,W2,NOM) écarte les coefficients atteints par le
  repli circulaire, comme MODWTVAR.

  [R,BORNES] = MODWTCORR(...,P) rend l'intervalle de confiance au
  niveau P (0,95 par défaut), par la transformation de Fisher.

  Exemple :
     x = cumsum(randn(1, 1024));
     r = modwtcorr(modwt(x, 'db2', 4), modwt(x, 'db2', 4), 'db2');
     max(abs(r - 1))                % nul : un signal avec lui-même

  Voir aussi MODWTVAR, MODWTXCORR, MODWT, CORRCOEF.
```

## `modwtmra`

```
MODWTMRA Analyse multirésolution issue d'une MODWT.
  MRA = MODWTMRA(W,NOM) rend, pour chaque ligne de W, la composante du
  signal qu'elle porte : leur somme redonne le signal exactement.

  Exemple :
     w = modwt(1:8, 'haar', 2);
     max(abs(sum(modwtmra(w, 'haar')) - (1:8)))   % nul
```

## `modwtvar`

```
MODWTVAR Variance par échelle d'une transformée à chevauchement maximal.
  V = MODWTVAR(W) rend la variance portée par chaque ligne de W, c'est
  à dire par chaque échelle. La somme des variances vaut celle du
  signal : la MODWT conserve l'énergie, ce qui fait de cette
  décomposition un vrai partage de la variance.

  V = MODWTVAR(W,NOM) nomme l'ondelette, ce qui permet d'écarter les
  coefficients atteints par le repli circulaire aux bords : seuls les
  coefficients dits « non touchés » entrent alors dans le compte.

  [V,BORNES] = MODWTVAR(W,NOM,P) rend en outre l'intervalle de
  confiance au niveau P (0,95 par défaut), par l'approximation
  gaussienne sur le nombre de coefficients non touchés.

  Exemple :
     w = modwt(cumsum(randn(1, 1024)), 'db2', 5);
     v = modwtvar(w, 'db2');
     numel(v)                       % 6 : cinq détails et l'approximation

  Voir aussi MODWT, MODWTMRA, MODWTCORR, MODWTXCORR.
```

## `modwtxcorr`

```
MODWTXCORR Corrélation croisée par échelle entre deux signaux.
  C = MODWTXCORR(W1,W2) rend, dans une cellule, la corrélation croisée
  normalisée de chaque échelle : C{K} porte les valeurs pour tous les
  décalages. Le maximum dit de combien la seconde série est en retard
  sur la première, à cette échelle-là.

  [C,DECALAGES] = MODWTXCORR(...) rend aussi le vecteur des décalages.
  MODWTXCORR(W1,W2,NOM,MAXDEC) borne le décalage.

  Exemple :
     x = cumsum(randn(1, 512));
     y = circshift(x, 8);
     [c, d] = modwtxcorr(modwt(x, 'db2', 3), modwt(y, 'db2', 3));
     [~, i] = max(c{3});
     d(i)                           % environ 8

  Voir aussi MODWTCORR, MODWTVAR, XCORR, MODWT.
```

## `morlet`

```
MORLET Ondelette de Morlet réelle.
  [PSI,X] = MORLET(LB,UB,N) échantillonne sur N points de [LB,UB]

     psi(x) = exp(-x^2/2) * cos(5x)

  C'est la version réelle, non normalisée, de MATLAB : une sinusoïde de
  pulsation cinq sous une enveloppe gaussienne. Sa moyenne n'est nulle
  qu'à 1e-5 près — la condition d'admissibilité n'est vérifiée qu'en
  pratique, ce qui est le défaut connu de Morlet réelle.

  Exemple :
     [psi, x] = morlet(-4, 4, 1000);

  Voir aussi MEXIHAT, GAUSWAVF, CWT.
```

## `normaliserSomme`

```
NORMALISERSOMME Met un filtre d'échelle à la somme demandée.
  W = NORMALISERSOMME(W,SOMME) met la somme de W à SOMME. Une somme
  nulle veut dire « norme deux unitaire », ce qui pour un filtre
  d'échelle revient à une somme de racine de deux : c'est la convention
  de DBAUX et SYMAUX.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `ntnode`

```
NTNODE Nombre de nœuds terminaux d'un arbre.
  N = NTNODE(T) compte les feuilles. Pour un arbre complet de
  profondeur D et d'ordre ORD, c'est ORD^D ; un arbre élagué en compte
  moins.

  Exemple :
     ntnode(wpdec(1:64, 3, 'db2'))  % 8
     ntnode(wpdec2(magic(16), 2, 'haar'))   % 16

  Voir aussi LEAVES, TNODES, TREEDPTH, BESTTREE.
```

## `ordreDeNom`

```
ORDREDENOM Ordre lu dans le nom d'une ondelette.
  ORDRE = ORDREDENOM('db4','db') rend 4. 'haar' vaut 'db1'.
  Le nom est refusé s'il n'appartient pas à la famille demandée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `ordresBior`

```
ORDRESBIOR Les deux ordres lus dans un nom « biorNr.Nd ».
  [NR,ND] = ORDRESBIOR('bior2.4','bior') rend 2 et 4.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `orthfilt`

```
ORTHFILT Banc de filtres orthogonal à partir du filtre d'échelle.
  [LO_D,HI_D,LO_R,HI_R] = ORTHFILT(W) normalise W à une somme de racine
  de deux, puis applique les relations du banc à reconstruction
  parfaite : l'analyse est la synthèse renversée, et le passe-haut est
  le miroir en quadrature du passe-bas.

     Lo_R = sqrt(2) * W / sum(W)
     Lo_D[n] = Lo_R[N+1-n]
     Hi_D[n] = (-1)^n Lo_R[n]
     Hi_R[n] = Hi_D[N+1-n]

  Exemple :
     [lod, hid, lor, hir] = orthfilt([1 1]);   % Haar
     hid    % [-0.7071 0.7071]

  Voir aussi WFILTERS, QMF.
```

## `poserNoeud`

```
POSERNOEUD Range les coefficients d'un nœud dans l'arbre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `qmf`

```
QMF Miroir en quadrature d'un filtre.
  Y = QMF(X) rend le filtre renversé dont un échantillon sur deux
  change de signe. QMF(X,P) décale la parité du changement de signe.

  Exemple :
     qmf([1 2 3 4])   % [4 -3 2 -1]
```

## `rbiowavf`

```
RBIOWAVF Filtres d'une biorthogonale spline inversée.
  [RF,DF] = RBIOWAVF('rbioNd.Nr') est BIORWAVF('biorNr.Nd') avec les
  deux filtres échangés : ce qui servait à l'analyse sert à la
  synthèse. C'est utile quand on veut la régularité du côté de
  l'analyse plutôt que de la reconstruction.

  Les noms reconnus sont ceux de BIORWAVF, dans l'ordre inversé :
  rbio1.1, 1.3, 1.5, 2.2, 2.4, 2.6, 2.8, 3.1, 3.3, 3.5, 3.7, 3.9, 4.4.

  Exemple :
     [rf, df] = rbiowavf('rbio2.2');
     [rf2, df2] = biorwavf('bior2.2');
     max(abs(rf - df2))             % 0 : les rôles sont échangés

  Voir aussi BIORWAVF, BIORFILT, WFILTERS.
```

## `refuserHorsSpline`

```
REFUSERHORSSPLINE Écarte les biorthogonales qui ne sont pas des splines.
  MATLAB nomme « bior5.5 » et « bior6.8 » deux couples de Cohen et
  Daubechies ajustés au plus près de l'orthonormalité, non des splines :
  ils ne sortent pas de la construction de FILTRESSPLINES, et rendre
  autre chose sous leur nom tromperait l'appelant.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `scal2frq`

```
SCAL2FRQ Conversion des échelles en fréquences.
  F = SCAL2FRQ(A,NOM,DELTA) rend la fréquence associée à chaque
  échelle : F = Fc / (A * DELTA), où Fc est la fréquence centrale de
  l'ondelette et DELTA le pas d'échantillonnage.

  Exemple :
     scal2frq(1:8, 'db4', 0.001)
```

## `scinderNoeud`

```
SCINDERNOEUD Coupe un nœud d'un arbre de paquets en ses enfants.
  C'est le rouage commun de WPDEC et de WPSPLT. Le nœud est filtré par
  le banc — deux voies en une dimension, quatre en deux —, et les
  enfants prennent les indices que DEPO2IND leur donne.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `shanwavf`

```
SHANWAVF Ondelette de Shannon complexe.
  [PSI,X] = SHANWAVF(LB,UB,N,FB,FC) échantillonne sur N points de
  [LB,UB] l'ondelette

     psi(x) = sqrt(FB) sinc(FB x) exp(2 i pi FC x),

  où sinc(x) = sin(pi x) / (pi x). FB est la largeur de bande (un par
  défaut), FC la fréquence centrale (un par défaut).

  Sa transformée est une porte : le support en fréquence est exactement
  [FC - FB/2, FC + FB/2]. En échange elle décroît lentement en temps,
  comme 1/x — c'est l'exact opposé de la gaussienne.

  Exemple :
     [psi, x] = shanwavf(-20, 20, 1000, 1, 1.5);
     max(abs(imag(psi)))            % non nul : l'ondelette est complexe

  Voir aussi FBSPWAVF, CMORWAVF, CGAUWAVF, CWT.
```

## `supportOndeletteContinue`

```
SUPPORTONDELETTECONTINUE Support effectif d'une ondelette continue.
  [LB,UB,FAMILLE,ORDRE] = SUPPORTONDELETTECONTINUE(NOM) rend l'intervalle
  hors duquel l'ondelette est négligeable, le nom de sa famille et son
  ordre. FAMILLE est vide si NOM ne désigne pas une ondelette continue.

  Ces bornes ne sont pas décoratives : ce sont elles qui fixent la
  période de la transformée de Fourier discrète dont CENTFRQ tire la
  fréquence centrale, et donc les valeurs 0.25 pour le chapeau mexicain
  et 0.8125 pour Morlet.

  Exemple :
     [lb, ub] = supportOndeletteContinue('mexh')   % -8, 8
```

## `swt`

```
SWT Transformée en ondelettes stationnaire, sans sous-échantillonnage.
  [SWA,SWD] = SWT(X,N,NOM) rend N lignes d'approximations et N lignes
  de détails, toutes de la longueur du signal. À chaque niveau, ce sont
  les filtres qui sont dilatés — un zéro inséré entre deux
  coefficients — au lieu du signal qui est décimé.

  Le résultat est invariant par translation, ce que la transformée
  décimée n'est pas : c'est ce qui la rend meilleure pour le
  débruitage.

  Exemple :
     [a, d] = swt(1:8, 2, 'haar');

  Voir aussi ISWT, SWT2, MODWT, DWT.
```

## `swt2`

```
SWT2 Transformée stationnaire d'une image.
  [A,H,V,D] = SWT2(X,N,NOM) rend, pour chacun des N niveaux, une image
  de la taille de X : approximation, détails horizontal, vertical et
  diagonal. Le niveau K occupe A(:,:,K) et ses voisins.

  Comme en une dimension, rien n'est décimé : ce sont les filtres qui
  sont dilatés d'un niveau à l'autre. Le résultat est donc invariant
  par translation, ce qui vaut pour la détection de contours et le
  débruitage — au prix de quatre fois plus de coefficients par niveau.

  Les deux dimensions de X doivent être des multiples de 2^N.

  Exemple :
     [a, h, v, d] = swt2(magic(8), 2, 'haar');
     size(a)                        % 8x8x2

  Voir aussi ISWT2, SWT, WAVEDEC2, DWT2.
```

## `symaux`

```
SYMAUX Filtre d'échelle d'un symlet d'ordre N.
  W = SYMAUX(N) rend le filtre d'échelle de l'ondelette symN, de
  longueur 2N et de somme un.
  W = SYMAUX(N,SOMME) le normalise à la somme donnée ; SOMME nulle
  demande la normalisation en norme deux.

  Le symlet a les mêmes moments nuls que dbN : c'est l'autre
  factorisation spectrale du même polynôme, celle dont la phase
  s'écarte le moins de la linéarité — d'où un filtre presque
  symétrique.

  Exemple :
     w = symaux(4);
     sum(w)                         % 1
     numel(w)                       % 8

  Voir aussi SYMWAVF, DBAUX, WFILTERS, ORTHFILT.
```

## `symwavf`

```
SYMWAVF Filtre d'échelle d'un symlet.
  F = SYMWAVF('symN') rend le filtre d'échelle de symN, de longueur 2N
  et de somme un. C'est SYMAUX(N), pris par le nom de l'ondelette.

  Exemple :
     F = symwavf('sym4');
     numel(F)                       % 8
     sum(F)                         % 1

  Voir aussi SYMAUX, DBWAVF, WFILTERS, WAVEINFO.
```

## `thselect`

```
THSELECT Choix d'un seuil de débruitage.
  THR = THSELECT(X,METHODE) où METHODE vaut :
    'sqtwolog'  seuil universel racine de 2 log n
    'rigrsure'  minimise l'estimateur sans biais du risque de Stein
    'heursure'  mélange des deux, selon l'énergie du signal
    'minimaxi'  seuil minimax de Donoho et Johnstone

  X doit être normalisé : un bruit d'écart type 1.

  Exemple :
     thselect(randn(1, 1024), 'sqtwolog')   % environ 3.7
```

## `tnodes`

```
TNODES Nœuds terminaux d'un arbre — l'autre nom de LEAVES.
  N = TNODES(T) rend les nœuds que l'arbre ne scinde pas.
  N = TNODES(T,'deppos') les rend sous la forme [profondeur position].

  C'est le nom d'origine ; LEAVES est le nom récent. Les deux rendent
  la même chose.

  Exemple :
     t = wpdec(1:64, 2, 'haar');
     tnodes(t)'                     % 3 4 5 6

  Voir aussi LEAVES, NTNODE, TREEDPTH, WPDEC.
```

## `treedpth`

```
TREEDPTH Profondeur d'un arbre de paquets d'ondelettes.
  D = TREEDPTH(T) rend la profondeur du nœud le plus profond, c'est à
  dire le nombre de scissions du chemin le plus long.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     treedpth(t)                    % 3
     treedpth(wpjoin(t, 1))         % 3 : l'autre branche est intacte

  Voir aussi LEAVES, NTNODE, WPDEC, WPSPLT, WPJOIN.
```

## `upcoef`

```
UPCOEF Reconstruction directe de coefficients sur plusieurs niveaux.
  Y = UPCOEF('a',X,NOM,N) remonte X comme une approximation sur N
  niveaux, en mettant les détails à zéro ; 'd' fait l'inverse.

  Exemple :
     upcoef('a', 1, 'haar', 1)   % [0.7071 0.7071]
```

## `upcoef2`

```
UPCOEF2 Reconstruction directe de coefficients d'image.
  Y = UPCOEF2('a',X,NOM,N) remonte X comme une approximation sur N
  niveaux, les détails étant nuls ; 'h', 'v' et 'd' font de même pour
  les trois détails.
  Y = UPCOEF2(...,TAILLE) recadre le résultat au centre.

  C'est l'équivalent bidimensionnel d'UPCOEF : on voit ainsi la forme
  qu'un seul coefficient prend une fois remonté, c'est-à-dire
  l'ondelette elle-même à l'échelle voulue.

  Exemple :
     motif = upcoef2('h', 1, 'haar', 2);
     size(motif)                    % 4x4

  Voir aussi UPCOEF, IDWT2, WRCOEF2, WAVEDEC2.
```

## `upwlev`

```
UPWLEV Remonte d'un niveau une décomposition en ondelettes.
  [NC,NL,CA] = UPWLEV(C,L,NOM) fusionne l'approximation la plus
  grossière avec son détail : la décomposition perd un niveau, et CA
  rend l'approximation reconstruite.
```

## `upwlev2`

```
UPWLEV2 Remonte d'un niveau une décomposition d'image.
  [NC,NS,CA] = UPWLEV2(C,S,NOM) fusionne l'approximation la plus
  grossière avec ses trois détails : la décomposition perd un niveau,
  et CA rend l'approximation reconstruite.

  Exemple :
     [c, s] = wavedec2(magic(16), 3, 'haar');
     [nc, ns, ca] = upwlev2(c, s, 'haar');
     size(ns, 1) == size(s, 1) - 1  % 1 : un niveau de moins

  Voir aussi UPWLEV, WAVEDEC2, APPCOEF2, IDWT2.
```

## `wavedec`

```
WAVEDEC Décomposition multiniveaux en ondelettes.
  [C,L] = WAVEDEC(X,N,NOM) empile les coefficients : approximation de
  niveau N, puis détails du niveau N au niveau 1. L donne les longueurs.
```

## `wavedec2`

```
WAVEDEC2 Décomposition multiniveaux d'une image en ondelettes.
  [C,S] = WAVEDEC2(X,N,NOM) empile les coefficients en un vecteur
  ligne : approximation du niveau N, puis, du niveau N au niveau 1, les
  détails horizontal, vertical et diagonal. S donne les tailles, une
  ligne par niveau plus la taille de l'image.

  Exemple :
     [c, s] = wavedec2(magic(8), 2, 'haar');
     a = appcoef2(c, s, 'haar', 2);
```

## `wavefun`

```
WAVEFUN Fonctions d'échelle et d'ondelette, par l'algorithme en cascade.
  [PHI,PSI,XVAL] = WAVEFUN(NOM,ITER) approche la fonction d'échelle et
  la fonction d'ondelette de l'ondelette orthogonale NOM. On part d'une
  impulsion et on applique ITER fois l'équation à deux échelles

     phi(x) = sqrt(2) * somme_n Lo_R(n) phi(2x - n)
     psi(x) = sqrt(2) * somme_n Hi_R(n) phi(2x - n)

  chaque tour doublant la résolution. Les deux fonctions sont rendues
  sur la même grille XVAL, de pas 2^-ITER, qui couvre le support
  commun [0, L-1] où L est la longueur du filtre. Le vecteur compte
  donc 2^ITER*(L-1)+1 points et l'échelonnement est celui de MATLAB :
  l'intégrale de PHI vaut 1 et celle de PSI vaut 0.

  Exemple :
     [phi, psi, x] = wavefun('db2', 8);
     numel(x)                % 769
     sum(phi) * (x(2)-x(1))  % 1
     sum(psi) * (x(2)-x(1))  % 0

  Pour une ondelette continue — 'mexh', 'morl', 'gausP' — il n'y a pas
  de fonction d'échelle : l'appel prend alors la forme de MATLAB

     [PSI,XVAL] = WAVEFUN('mexh',ITER)

  et l'ondelette est échantillonnée sur 2^ITER points de son support
  effectif.

  Voir aussi WFILTERS, CENTFRQ, UPCOEF, MEXIHAT, MORLET, GAUSWAVF.
```

## `wavefun2`

```
WAVEFUN2 Fonctions d'échelle et d'ondelettes en deux dimensions.
  [PHI,PSIH,PSIV,PSID,XYVAL] = WAVEFUN2(NOM,ITER) approche les quatre
  fonctions de la base bidimensionnelle, obtenues par produit des
  fonctions à une dimension :

     phi(x,y)  = phi(x) phi(y)      approximation
     psiH(x,y) = phi(x) psi(y)      détail horizontal
     psiV(x,y) = psi(x) phi(y)      détail vertical
     psiD(x,y) = psi(x) psi(y)      détail diagonal

  La séparabilité est ce qui rend la transformée d'image aussi rapide
  que celle d'un signal : on filtre les lignes, puis les colonnes.

  XYVAL est la grille commune, celle que rend WAVEFUN.

  Exemple :
     [phi, ph, pv, pd, xy] = wavefun2('db2', 6);
     size(phi)
     abs(sum(pd(:)))                % nul : le détail est de moyenne nulle

  Voir aussi WAVEFUN, WFILTERS, DWT2, WAVEDEC2.
```

## `waveinfo`

```
WAVEINFO Renseignements sur une ondelette ou une famille d'ondelettes.
  WAVEINFO affiche la liste des familles disponibles.
  WAVEINFO(FAMILLE) décrit la famille : 'haar', 'db', 'sym', 'bior',
  'rbio', 'meyr', 'mexh', 'morl', 'gaus', 'cgau', 'cmor', 'shan',
  'fbsp'.
  WAVEINFO(NOM) décrit une ondelette précise : 'db4', 'sym8',
  'bior4.4'.
  T = WAVEINFO(...) rend le texte au lieu de l'afficher.

  Exemples :
     waveinfo
     waveinfo('db')
     waveinfo('db4')

  Voir aussi WFILTERS, WAVEFUN, CENTFRQ.
```

## `wavenames`

```
WAVENAMES Noms des ondelettes disponibles.
  NOMS = WAVENAMES rend, dans une cellule, le nom de toutes les
  ondelettes que MatLibre sait construire.
  NOMS = WAVENAMES('orthogonal') ne rend que les orthogonales,
  'biorthogonal' que les biorthogonales, 'continuous' que celles de la
  transformée continue, 'all' toutes.

  Les familles dbN et symN existent à tout ordre : la liste s'arrête à
  quarante-cinq, comme celle de MATLAB, mais WFILTERS accepte au-delà.

  Exemple :
     noms = wavenames('biorthogonal');
     numel(noms)
     any(strcmp(noms, 'bior4.4'))   % 1 : le 9/7 de JPEG 2000

  Voir aussi WFILTERS, WAVEINFO, BIORWAVF, DBWAVF.
```

## `waverec`

```
WAVEREC Reconstruction d'une décomposition multiniveaux.
```

## `waverec2`

```
WAVEREC2 Reconstruction d'une image à partir de sa décomposition.
  Réciproque de WAVEDEC2.
```

## `wcodemat`

```
WCODEMAT Met une matrice à l'échelle des indices de couleur.
  Y = WCODEMAT(X,NBCODES) ramène X dans 1..NBCODES.

  Exemple :  wcodemat([0 1], 4)   % [1 4]
```

## `wconv1`

```
WCONV1 Convolution monodimensionnelle, orientation conservée.
```

## `wconv2`

```
WCONV2 Convolution bidimensionnelle.
```

## `wden`

```
WDEN Débruitage automatique par seuillage des coefficients.
  XD = WDEN(X,TPTR,SORH,SCAL,N,NOM) décompose X sur N niveaux avec
  l'ondelette NOM, seuille les détails, puis reconstruit.
    TPTR   règle du seuil : 'rigrsure', 'heursure', 'sqtwolog',
           'minimaxi'
    SORH   's' pour un seuillage doux, 'h' pour un seuillage dur
    SCAL   'one'  le bruit est d'écart type un
           'sln'  écart type estimé une fois, sur le premier niveau
           'mln'  écart type estimé niveau par niveau

  [XD,C,L] = WDEN(...) rend aussi la décomposition débruitée.
  WDEN(C,L,TPTR,SORH,SCAL,N,NOM) part d'une décomposition déjà faite.

  C'est l'interface d'origine, celle de Donoho et Johnstone. WDENOISE
  est plus récente et offre davantage de règles ; WDEN reste là parce
  que beaucoup de code l'emploie.

  Exemple :
     [propre, bruite] = wnoise(3, 10, 7, 5);
     xd = wden(bruite, 'sqtwolog', 's', 'sln', 3, 'db4');
     norm(xd - propre) < norm(bruite - propre)   % vrai

  Voir aussi WDENOISE, WDENCMP, THSELECT, WNOISEST, WTHRESH.
```

## `wdencmp`

```
WDENCMP Débruitage ou compression par seuillage des coefficients.
  [XD,CXD,LXD,PERF0,PERFL2] = WDENCMP('gbl',X,NOM,N,THR,SORH,KEEPAPP)
  décompose X sur N niveaux, seuille, puis reconstruit. PERF0 est le
  pourcentage de coefficients annulés, PERFL2 la part d'énergie gardée.

  WDENCMP('gbl',C,L,NOM,N,THR,SORH,KEEPAPP) part d'une décomposition
  déjà faite.

  Exemple :
     x = wnoise(3, 10, 7);
     xd = wdencmp('gbl', x, 'db4', 3, 2, 's', 1);
```

## `wdenoise`

```
WDENOISE Débruitage d'un signal par seuillage des coefficients d'ondelettes.
  XD = WDENOISE(X) débruite X en le décomposant sur sym4, au niveau
  MIN(FLOOR(LOG2(N)), WMAXLEV(N,'sym4')), puis en atténuant les
  coefficients de détail par le seuillage par blocs de James et Stein.

  XD = WDENOISE(X,NIVEAU) impose le niveau de décomposition.

  XD = WDENOISE(...,'Wavelet',NOM) change d'ondelette.

  XD = WDENOISE(...,'DenoisingMethod',M) choisit la règle qui fixe le
  seuil :
    'BlockJS'            seuillage par blocs (défaut)
    'UniversalThreshold' seuil universel sqrt(2 log n) sigma
    'SURE'               minimisation de l'estimateur sans biais du
                         risque de Stein
    'Minimax'            seuil minimax de Donoho et Johnstone
    'Bayes'              seuil bayésien empirique (BayesShrink)
    'FDR'                contrôle du taux de fausses découvertes

  XD = WDENOISE(...,'ThresholdRule',R) choisit 'Soft' ou 'Hard'. La
  méthode 'BlockJS' n'accepte que 'James-Stein', 'FDR' que 'Hard' ; les
  autres méthodes prennent 'Soft' par défaut.

  XD = WDENOISE(...,'NoiseEstimate',E) estime l'écart type du bruit une
  fois pour toutes sur le premier niveau ('LevelIndependent', défaut)
  ou niveau par niveau ('LevelDependent').

  [XD,CD,CO] = WDENOISE(...) rend aussi les coefficients débruités et
  les coefficients d'origine, au format de WAVEDEC.

  Exemple :
     [propre, bruite] = wnoise(3, 10, 7, 5);
     xd = wdenoise(bruite, 'Wavelet', 'db4');
     norm(xd - propre) < norm(bruite - propre)   % vrai

  Voir aussi WDENCMP, THSELECT, WNOISEST, WTHRESH.
```

## `wdenoise2`

```
WDENOISE2 Débruitage d'une image par seuillage des coefficients.
  XD = WDENOISE2(X) débruite l'image X en la décomposant sur bior4.4,
  au niveau le plus profond que sa taille permette, puis en seuillant
  les détails par la règle bayésienne empirique.

  XD = WDENOISE2(X,NIVEAU) impose le niveau.

  XD = WDENOISE2(...,'Wavelet',NOM) change d'ondelette,
  'DenoisingMethod',M la règle du seuil — 'Bayes' (défaut),
  'UniversalThreshold', 'SURE' ou 'Minimax' —, 'ThresholdRule',R le
  seuillage — 'Soft' (défaut) ou 'Hard' —, 'NoiseEstimate',E
  l'estimation du bruit — 'LevelIndependent' (défaut) ou
  'LevelDependent'.

  [XD,CD,CO] = WDENOISE2(...) rend aussi les coefficients débruités et
  ceux d'origine, au format de WAVEDEC2.

  Une image couleur est traitée plan par plan.

  Exemple :
     propre = double(magic(64));
     bruite = propre + 3 * randn(64);
     xd = wdenoise2(bruite);
     norm(xd - propre, 'fro') < norm(bruite - propre, 'fro')   % vrai

  Voir aussi WDENOISE, WDENCMP, WTHCOEF2, WNOISEST, WTHRESH.
```

## `wenergy`

```
WENERGY Répartition de l'énergie entre approximation et détails.
```

## `wenergy2`

```
WENERGY2 Répartition de l'énergie d'une image décomposée.
  [EA,EH,EV,ED] = WENERGY2(C,S) rend le pourcentage d'énergie porté par
  l'approximation, puis, du niveau un au niveau le plus grossier, celui
  des détails horizontaux, verticaux et diagonaux.

  [EA,ED] = WENERGY2(C,S) range les trois familles de détails dans une
  matrice à trois colonnes, un niveau par ligne, comme MATLAB.

  L'énergie se conserve pour une ondelette orthogonale : les
  pourcentages somment alors exactement à cent. Pour une biorthogonale
  ils somment à peu près, le banc n'étant pas orthogonal.

  Exemple :
     [c, s] = wavedec2(magic(16), 2, 'haar');
     [ea, ed] = wenergy2(c, s);
     ea + sum(ed(:))                % 100

  Voir aussi WENERGY, WAVEDEC2, DETCOEF2, APPCOEF2.
```

## `wentropy`

```
WENTROPY Entropie d'un vecteur ou d'une matrice de coefficients.
  E = WENTROPY(X,T) mesure la concentration de X selon le critère T :
    'shannon'     - somme(-s log s), s = x^2 ; nulle si toute
                    l'énergie est sur un seul coefficient, maximale si
                    elle est répartie également
    'log energy'  - somme(log(x^2))
    'threshold'   - nombre de coefficients dépassant P en module
    'sure'        - estimateur sans biais du risque de Stein, seuil P
    'norm'        - somme(|x|^P)

  E = WENTROPY(X,T,P) donne le paramètre, obligatoire pour
  'threshold', 'sure' et 'norm'.

  Ces critères sont additifs : l'entropie d'un vecteur est la somme de
  celles de ses morceaux. C'est ce qui permet à BESTTREE de comparer un
  nœud à ses enfants et de choisir la meilleure base.

  Exemple :
     wentropy([1 0 0 0], 'shannon')   % 0 : toute l'énergie en un point
     wentropy([1 1 1 1] / 2, 'shannon')   % log(4) : elle est répartie
     wentropy([3 1 0.1], 'threshold', 0.5)  % 2

  Voir aussi BESTTREE, WPDEC, WPTHCOEF, WPDENCMP.
```

## `wextend`

```
WEXTEND Prolonge un signal ou une image aux bords.
  Y = WEXTEND(TYPE,MODE,X,L) où TYPE vaut 1 ou '1D' pour un signal,
  2 ou '2D' pour une image, et MODE l'un de :
    'zpd'            zéros
    'sp0'            répétition du bord (lissage d'ordre 0)
    'spd' ou 'sp1'   prolongement affine (lissage d'ordre 1)
    'sym' ou 'symh'  symétrie demi-point : le bord est répété
    'symw'           symétrie point entier : le bord n'est pas répété
    'asym', 'asymh'  antisymétrie demi-point
    'asymw'          antisymétrie point entier
    'ppd'            périodique
    'per'            périodique, la longueur étant d'abord rendue paire

  COTE vaut 'b' (des deux côtés, par défaut), 'l' ou 'r'.

  Exemples :
     wextend('1D', 'zpd',   [1 2 3], 2)   % [0 0 1 2 3 0 0]
     wextend('1D', 'sp0',   [1 2 3], 2)   % [1 1 1 2 3 3 3]
     wextend('1D', 'spd',   [1 2 3], 2)   % [-1 0 1 2 3 4 5]
     wextend('1D', 'sym',   [1 2 3], 2)   % [2 1 1 2 3 3 2]
     wextend('1D', 'symw',  [1 2 3], 2)   % [3 2 1 2 3 2 1]
     wextend('1D', 'asym',  [1 2 3], 2)   % [-2 -1 1 2 3 -3 -2]
     wextend('1D', 'ppd',   [1 2 3], 2)   % [2 3 1 2 3 1 2]

  Voir aussi WKEEP, DWT.
```

## `wfbm`

```
WFBM Mouvement brownien fractionnaire.
  FBM = WFBM(H,L) tire un mouvement brownien fractionnaire de L points,
  de paramètre de Hurst H compris strictement entre zéro et un.

  H = 0,5 donne le mouvement brownien ordinaire, à accroissements
  indépendants. Au-dessus, les accroissements sont corrélés
  positivement : la trajectoire persiste dans sa direction. En dessous,
  ils s'opposent : elle revient sans cesse sur ses pas.

  [FBM,BRUIT] = WFBM(H,L) rend en outre le bruit gaussien
  fractionnaire, dont FBM est la somme cumulée.

  La synthèse est celle de Davies et Harte : le bruit fractionnaire est
  engendré par plongement circulant de sa matrice de covariance, ce qui
  donne des échantillons de covariance exacte — et non approchée.
  MATLAB emploie une synthèse par ondelettes ; les deux tirent la même
  loi.

  Exemple :
     x = wfbm(0.7, 1024);
     wfbmesti(x)                    % trois estimations, voisines de 0,7

  Voir aussi WFBMESTI, WNOISE, RANDN, CUMSUM.
```

## `wfbmesti`

```
WFBMESTI Estimation du paramètre de Hurst d'un mouvement fractionnaire.
  H = WFBMESTI(X) rend trois estimations, dans un vecteur :
    H(1)  par la variance des différences secondes discrètes
    H(2)  par la pente du logarithme de la variance des détails
          d'ondelettes en fonction du niveau
    H(3)  par la même pente, pondérée par le nombre de coefficients
          de chaque niveau

  Les trois reposent sur la même propriété : le mouvement
  fractionnaire est auto-similaire, si bien que ce qu'on mesure à
  l'échelle 2^j croît comme 2^(j(2H+1)). Elles ne se trompent pas de la
  même façon, ce qui rend leur écart instructif.

  Sur quatre mille points, comptez quelques centièmes d'erreur au
  dessus de H = 0,5, davantage en dessous : les estimations par
  ondelettes sous-estiment alors d'environ cinq centièmes, la relation
  d'échelle ne s'établissant qu'aux niveaux assez grossiers.

  Exemple :
     x = wfbm(0.7, 4096);
     h = wfbmesti(x);
     abs(h - 0.7) < 0.1             % vrai, aux trois

  Voir aussi WFBM, MODWTVAR, WAVEDEC.
```

## `wfilters`

```
WFILTERS Bancs de filtres d'analyse et de synthèse.
  [LO_D,HI_D,LO_R,HI_R] = WFILTERS(NOM) où NOM vaut 'haar', 'dbN',
  'symN', 'biorNr.Nd' ou 'rbioNd.Nr'. Les coefficients ne sont pas
  recopiés d'une table : ils sont construits par factorisation
  spectrale du polynôme de Daubechies, ce qui les rend disponibles à
  n'importe quel ordre. L'orthogonalité du banc reste au niveau de la
  précision machine jusqu'à db20 environ, et meilleure que 1e-9 jusqu'à
  db45.

  Une biorthogonale n'est pas orthogonale : son banc vient de BIORFILT,
  et c'est la reconstruction qui est parfaite, non l'orthogonalité. En
  échange, les filtres sont symétriques — ce qu'aucune orthogonale à
  support compact n'est, sauf Haar.

  WFILTERS(NOM,'d') ne rend que les filtres d'analyse, 'r' que ceux de
  synthèse, 'l' les passe-bas, 'h' les passe-haut ; les deux sorties
  demandées sont alors les deux premières.

  Exemple :
     [lod, hid, lor, hir] = wfilters('db4');
     [lod, hid] = wfilters('db4', 'd');
     [lod, hid, lor, hir] = wfilters('bior2.2');

  Voir aussi DWT, WAVEDEC, ORTHFILT, BIORFILT, WAVENAMES.
```

## `wkeep`

```
WKEEP Garde la partie centrale d'un vecteur ou d'une image.
  Y = WKEEP(X,L) garde L éléments au centre.
  Y = WKEEP(X,L,'l') ou 'r' garde le début ou la fin.
  Y = WKEEP(X,L,DEBUT) part de l'indice donné.

  Exemple :
     wkeep([1 2 3 4 5], 3)   % [2 3 4]
```

## `wmaxlev`

```
WMAXLEV Niveau de décomposition maximal utile.
  N = WMAXLEV(L,ONDELETTE) rend le nombre de niveaux au-delà duquel le
  signal deviendrait plus court que le filtre.

  N = floor(log2(L / (Lf - 1))) où Lf est la longueur du filtre.

  Exemple :  wmaxlev(64, 'db2')   % 4
```

## `wnoise`

```
WNOISE Signaux d'essai de Donoho et Johnstone.
  [X,XN] = WNOISE(FUN,N) rend l'un des quatre signaux de référence sur
  2^N points, et sa version bruitée. FUN vaut 1 ou 'blocks', 2 ou
  'bumps', 3 ou 'heavysine', 4 ou 'doppler'.

  [X,XN] = WNOISE(FUN,N,RAPPORT) fixe le rapport signal sur bruit :
  le bruit a pour écart type l'écart type du signal divisé par
  RAPPORT.

  Ce sont les quatre signaux sur lesquels se comparent, depuis 1994,
  toutes les méthodes de débruitage par ondelettes : marches, pointes,
  sinusoïde à sauts, et chirp amorti.

  Exemple :
     [x, xn] = wnoise('doppler', 10, 7);
```

## `wnoisest`

```
WNOISEST Estimation de l'écart type du bruit par les détails.
  SIGMA = WNOISEST(C,L,NIVEAUX) estime le bruit à chaque niveau
  demandé, par la médiane des valeurs absolues divisée par 0,6745 —
  le rapport entre médiane et écart type d'une loi normale. La médiane
  résiste aux grands coefficients du signal, là où l'écart type
  empirique les compterait comme du bruit.

  Exemple :
     [c, l] = wavedec(randn(1, 1024), 3, 'db2');
     wnoisest(c, l, 1)   % proche de 1
```

## `wpcoef`

```
WPCOEF Coefficients d'un nœud d'un arbre de paquets.
  C = WPCOEF(T,N) rend les coefficients du nœud N, désigné par son
  indice ou par [profondeur position].
  C = WPCOEF(T) rend ceux de la racine, c'est-à-dire le signal.

  Exemple :
     t = wpdec(1:64, 2, 'db2');
     numel(wpcoef(t, 3))            % 16
     numel(wpcoef(t, [2 0]))        % 16 : le même nœud

  Voir aussi WPRCOEF, WPDEC, LEAVES, WPSPLT.
```

## `wpdec`

```
WPDEC Décomposition en paquets d'ondelettes.
  T = WPDEC(X,N,NOM) décompose le signal X sur N niveaux en paquets
  d'ondelettes : à la différence de WAVEDEC, qui ne redécompose que
  l'approximation, chaque nœud est scindé en deux — approximation et
  détail —, ce qui donne un arbre complet de 2^N feuilles.

  L'intérêt est la résolution en fréquence : un signal dont l'énergie
  est dans les hautes fréquences, qu'une décomposition en ondelettes
  laisserait dans un seul détail large, se trouve ici finement découpé.

  T = WPDEC(X,N,NOM,ENT,PAR) donne le critère d'entropie que BESTTREE
  emploiera : 'shannon' (défaut), 'threshold' avec son seuil, 'norm'
  avec sa puissance, 'log energy', 'sure' avec son seuil.

  L'arbre rendu est une structure : « type » vaut 'wptree', « donnees »
  porte un nœud par case — la racine à l'indice zéro, les enfants du
  nœud N aux indices 2N+1 et 2N+2 —, et « noeuds » la liste de ceux qui
  existent.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     numel(leaves(t))               % 8
     max(abs(wprec(t) - (1:64)))    % nul : la reconstruction est exacte

  Voir aussi WPREC, WPCOEF, WPRCOEF, WPSPLT, WPJOIN, BESTTREE, WPDEC2.
```

## `wpdec2`

```
WPDEC2 Décomposition d'une image en paquets d'ondelettes.
  T = WPDEC2(X,N,NOM) décompose l'image X sur N niveaux : chaque nœud
  est scindé en quatre — approximation et trois détails —, ce qui donne
  un arbre complet de 4^N feuilles.

  T = WPDEC2(X,N,NOM,ENT,PAR) donne le critère d'entropie que BESTTREE
  emploiera.

  L'arbre est de même forme qu'en une dimension, l'ordre valant quatre :
  les enfants du nœud N portent les indices 4N+1 à 4N+4.

  Exemple :
     t = wpdec2(magic(16), 2, 'haar');
     ntnode(t)                      % 16
     max(max(abs(wprec2(t) - magic(16))))   % nul

  Voir aussi WPREC2, WPDEC, WPCOEF, WPRCOEF, BESTTREE.
```

## `wpdencmp`

```
WPDENCMP Débruitage ou compression par paquets d'ondelettes.
  [XD,T,PERF0,PERFL2] = WPDENCMP(X,SORH,N,NOM,CRIT,PAR,KEEPAPP)
  décompose X en paquets sur N niveaux, cherche la meilleure base au
  sens du critère CRIT de paramètre PAR, seuille, puis reconstruit.
  PERF0 est le pourcentage de coefficients annulés, PERFL2 la part de
  l'énergie gardée.

  WPDENCMP(T,SORH,CRIT,PAR,KEEPAPP) part d'un arbre déjà construit.

  Le seuil est celui du critère : pour 'threshold' et 'sure', c'est PAR
  lui-même ; pour les autres, le seuil universel sigma racine de deux
  log n, sigma étant estimé sur les coefficients les plus fins.

  Chercher d'abord la meilleure base fait la différence avec WDENCMP :
  un signal dont l'énergie est en haute fréquence y est mieux
  concentré, donc mieux débruité.

  Exemple :
     [propre, bruite] = wnoise(3, 10, 7, 5);
     xd = wpdencmp(bruite, 's', 4, 'db4', 'shannon', 0, 1);
     norm(xd - propre) < norm(bruite - propre)   % vrai

  Voir aussi WDENCMP, WPTHCOEF, BESTTREE, WPDEC, WENTROPY.
```

## `wpfun`

```
WPFUN Fonctions de paquets d'ondelettes.
  [WPWS,X] = WPFUN(NOM,NUM,ITER) rend les fonctions W0 à WNUM de la
  famille de paquets de l'ondelette NOM, une par ligne, échantillonnées
  sur la grille X.

  Les fonctions se construisent par récurrence, en descendant l'arbre
  avec les deux filtres :

     W(2n)(x)   = sqrt(2) somme_k Lo_R(k) W(n)(2x - k)
     W(2n+1)(x) = sqrt(2) somme_k Hi_R(k) W(n)(2x - k)

  W0 est la fonction d'échelle, W1 l'ondelette ; les suivantes
  oscillent de plus en plus, chacune occupant sa propre bande.

  Exemple :
     [w, x] = wpfun('db2', 3, 7);
     size(w, 1)                     % 4 : W0 à W3
     trapz(x, w(1, :))              % 1 : W0 est la fonction d'échelle
     abs(trapz(x, w(2, :)))         % nul : W1 est l'ondelette

  Voir aussi WAVEFUN, WPDEC, WPCOEF, WFILTERS.
```

## `wpjoin`

```
WPJOIN Réunit les descendants d'un nœud d'un arbre de paquets.
  T = WPJOIN(T,N) supprime tout ce qui pend sous le nœud N : celui-ci
  redevient une feuille, et ses coefficients sont recalculés de ses
  descendants pour rester cohérents.

  [T,C] = WPJOIN(T,N) rend aussi ces coefficients.

  C'est l'opération inverse de WPSPLT : les deux servent à façonner un
  arbre à la main, ou à élaguer celui que BESTTREE a choisi.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     t = wpjoin(t, 1);              % la branche basse est refermée
     leaves(t)'                     % 1 11 12 13 14 : l'autre branche
                                    % garde sa profondeur

  Voir aussi WPSPLT, WPDEC, LEAVES, BESTTREE.
```

## `wprcoef`

```
WPRCOEF Reconstruction de la seule composante d'un nœud.
  X = WPRCOEF(T,N) reconstruit le signal en ne gardant que le nœud N :
  tous les autres sont mis à zéro. On voit ainsi ce que cette bande de
  fréquence apporte au signal.

  La somme des WPRCOEF de toutes les feuilles redonne le signal : c'est
  la décomposition que l'arbre représente.

  Exemple :
     t = wpdec(1:64, 2, 'db2');
     somme = zeros(1, 64);
     for n = leaves(t)', somme = somme + wprcoef(t, n); end
     max(abs(somme - (1:64)))       % nul

  Voir aussi WPREC, WPCOEF, WPDEC, LEAVES.
```

## `wprec`

```
WPREC Reconstruction à partir d'un arbre de paquets d'ondelettes.
  X = WPREC(T) recompose le signal en remontant l'arbre : chaque nœud
  scindé est refait de ses enfants, jusqu'à la racine.

  La reconstruction est exacte, aux erreurs d'arrondi près, quel que
  soit l'élagage de l'arbre : c'est ce qui permet d'annuler ou de
  seuiller quelques feuilles et de revenir au signal.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     max(abs(wprec(t) - (1:64)))    % nul

  Voir aussi WPDEC, WPRCOEF, WPREC2, WPTHCOEF.
```

## `wprec2`

```
WPREC2 Reconstruction d'une image à partir de son arbre de paquets.
  X = WPREC2(T) recompose l'image en remontant l'arbre : chaque nœud
  scindé est refait de ses quatre enfants, jusqu'à la racine.

  Exemple :
     t = wpdec2(magic(16), 2, 'db2');
     max(max(abs(wprec2(t) - magic(16))))   % nul

  Voir aussi WPDEC2, WPREC, WPRCOEF, WPTHCOEF.
```

## `wpsplt`

```
WPSPLT Scinde un nœud terminal d'un arbre de paquets.
  T = WPSPLT(T,N) coupe la feuille N en ses enfants : deux pour un
  signal, quatre pour une image. C'est ainsi qu'on affine un arbre là
  où le signal le demande, au lieu de le décomposer partout.

  [T,CA,CD] = WPSPLT(T,N) rend en outre les coefficients des enfants.

  Exemple :
     t = wpdec(1:64, 1, 'db2');
     t = wpsplt(t, 1);              % on affine la seule branche basse
     leaves(t)'                     % 2 3 4

  Voir aussi WPJOIN, WPDEC, LEAVES, BESTTREE.
```

## `wpthcoef`

```
WPTHCOEF Seuillage des coefficients d'un arbre de paquets.
  T = WPTHCOEF(T,KEEPAPP,SORH,THR) seuille les coefficients de toutes
  les feuilles au seuil THR, par seuillage doux ('s') ou dur ('h').
  KEEPAPP non nul laisse intacte la feuille d'approximation — celle
  qu'on atteint en ne prenant que des passe-bas —, dont les
  coefficients portent la forme générale du signal.

  Exemple :
     t = wpdec(1:64, 3, 'db2');
     ts = wpthcoef(t, 1, 's', 2);
     norm(wprec(ts) - (1:64)) > 0   % le signal a changé

  Voir aussi WTHRESH, WPDENCMP, BESTTREE, WPDEC.
```

## `wrcoef`

```
WRCOEF Reconstruit une composante d'une décomposition monodimensionnelle.
  Y = WRCOEF('a',C,L,NOM,N) reconstruit l'approximation du niveau N à
  la longueur du signal d'origine, les autres coefficients étant mis à
  zéro. 'd' reconstruit le détail.

  Exemple :
     [c, l] = wavedec(1:8, 2, 'haar');
     a2 = wrcoef('a', c, l, 'haar', 2);
```

## `wrcoef2`

```
WRCOEF2 Reconstruit une composante d'une décomposition d'image.
  Y = WRCOEF2('a',C,S,NOM,N) reconstruit l'approximation, 'h', 'v' ou
  'd' le détail correspondant, à la taille de l'image d'origine.
```

## `wrev`

```
WREV Renverse l'ordre des éléments d'un vecteur.
```

## `wthcoef`

```
WTHCOEF Annule, atténue ou seuille les coefficients d'une décomposition.
  NC = WTHCOEF('d',C,L) annule tous les coefficients de détail.
  NC = WTHCOEF('d',C,L,N) n'annule que les niveaux nommés par N.
  NC = WTHCOEF('d',C,L,N,P) multiplie le niveau N(i) par P(i), qui vaut
  entre zéro et un : c'est une compression par atténuation plutôt que
  par suppression.
  NC = WTHCOEF('a',C,L) annule l'approximation.
  NC = WTHCOEF('t',C,L,N,T,SORH) seuille le niveau N(i) au seuil T(i),
  par seuillage dur ('h', par défaut) ou doux ('s').

  Exemple :
     [c, l] = wavedec(1:64, 3, 'db2');
     nc = wthcoef('d', c, l, 1);          % le premier détail disparaît
     nc = wthcoef('d', c, l, 1:3, [0.5 1 1]);
     nc = wthcoef('t', c, l, 1:3, 2, 's');

  Voir aussi WTHRESH, WDENCMP, WAVEDEC.
```

## `wthcoef2`

```
WTHCOEF2 Annule, atténue ou seuille les coefficients d'une image.
  NC = WTHCOEF2('h',C,S) annule tous les détails horizontaux ; 'v' et
  'd' font de même pour les verticaux et les diagonaux, 'a' pour
  l'approximation.
  NC = WTHCOEF2(GENRE,C,S,N) n'agit que sur les niveaux nommés par N.
  NC = WTHCOEF2(GENRE,C,S,N,P) multiplie le niveau N(i) par P(i).
  NC = WTHCOEF2('t',C,S,N,T,SORH) seuille les trois détails du niveau
  N(i) au seuil T(i), par seuillage dur ('h', défaut) ou doux ('s').

  Exemple :
     [c, s] = wavedec2(magic(16), 2, 'db2');
     nc = wthcoef2('h', c, s, 1);         % le détail horizontal fin part
     nc = wthcoef2('t', c, s, 1:2, 5, 's');

  Voir aussi WTHCOEF, WTHRESH, WDENCMP, WAVEDEC2.
```

## `wthresh`

```
WTHRESH Seuillage des coefficients d'ondelettes.
  Y = WTHRESH(X,'s',T) applique le seuillage doux, 'h' le seuillage dur.
```

## `wvarchg`

```
WVARCHG Détection de ruptures de variance.
  [PTS,KOPT] = WVARCHG(Y,K,D) cherche jusqu'à K instants où la variance
  du signal Y change. D est le nombre minimal d'échantillons entre deux
  ruptures (dix par défaut) ; K vaut six par défaut.

  [PTS,KOPT,CONTRASTES] = WVARCHG(...) rend en outre, pour chaque
  nombre de ruptures de zéro à K, la valeur du contraste et les
  instants trouvés : CONTRASTES(J+1) va avec la ligne J+1 de la
  cellule PTS.

  La recherche est exacte, non gloutonne : une programmation dynamique
  parcourt toutes les découpes possibles et garde celle qui minimise

     somme_segments n_i log(variance_i),

  c'est-à-dire l'opposé de la vraisemblance gaussienne. Le nombre de
  ruptures est choisi par pénalisation : on retient le plus grand K
  dont l'ajout fait encore baisser le contraste d'au moins 4 log(n).
  Une rupture ajoute deux paramètres — sa position et une variance —,
  ce que le critère bayésien facturerait 2 log(n) ; sur du bruit pur ce
  seuil laisse encore passer une découpe de temps en temps, et le
  doubler l'écarte sans manquer les vraies ruptures, qui gagnent
  d'ordinaire cent fois plus.

  Appliquée aux détails d'ondelettes plutôt qu'au signal, elle détecte
  les changements de régime d'une série dont la moyenne bouge aussi :
  les détails effacent la tendance.

  Exemple :
     y = [randn(1, 200), 4 * randn(1, 200), randn(1, 200)];
     [pts, k] = wvarchg(y, 3);
     k                              % 2 : deux ruptures
     sort(pts)                      % voisins de 200 et 400

  Voir aussi WNOISEST, MODWTVAR, WDEN.
```

