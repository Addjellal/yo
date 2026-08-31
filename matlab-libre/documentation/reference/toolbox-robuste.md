# Toolbox `robuste`

```
% Robust Control Toolbox — analyse et synthèse robustes.
%
% Normes et marges
%   hinfnorm     - Norme H-infini d'un modèle
%   h2norm       - Norme H2, par les grammiens
%   sigmaValues  - Valeurs singulières en fréquence
%   stabilityMargin - Marges de module et de retard
%   loopmargin   - Marges en entrée, en sortie, et marge de disque
%   ncfmargin    - Marge des facteurs premiers normalisés
%   gapmetric    - Distance de graphe entre deux modèles
%   mussv        - Valeur singulière structurée : encadrement de mu
%   uncertainGain   - Balayage d'un gain incertain
%
% Synthèse
%   hinfsyn      - Correcteur H-infini d'un modèle augmenté
%   h2syn        - Correcteur H2
%   h2hinfsyn    - Compromis H2 / H-infini
%   ncfsyn       - Synthèse par les facteurs premiers normalisés
%   mixsyn       - Synthèse H-infini par sensibilité mixte
%   augw         - Modèle augmenté d'un problème de sensibilité mixte
%   sysic        - Assemblage d'un schéma par les noms des signaux
%
% Pondérations
%   makeweight   - Pondération à partir de trois nombres
%   mkfilter     - Filtre passe-bas normalisé
%
% Factorisation
%   lncf         - Facteurs premiers normalisés à gauche
%
% Réduction de modèle
%   reduce       - Réduction, toutes méthodes
%   balancmr     - Troncature équilibrée, avec borne de Glover
%   schurmr      - La même, par les sous-espaces de Safonov et Chiang
%   hankelmr     - Approximation optimale en norme de Hankel
%   bstmr        - Troncature stochastique : borne sur l'erreur relative
%   ncfmr        - Troncature des facteurs premiers : vaut aussi pour un
%                  modèle instable
%   sysbal       - Réalisation équilibrée
%   modreal      - Réalisation modale
%   slowfast     - Sépare les modes lents des modes rapides
%   stabproj     - Sépare la partie stable de la partie instable
%   strans       - Réordonne les états
%   imp2ss       - Modèle identifié sur une réponse impulsionnelle
%
% Stabilité absolue
%   sectf        - Transformation de secteur
%   popov        - Critère de Popov
%
% Repères pour les inégalités matricielles
%   skewdec, symdec - Gabarits de numérotation
%
% Fonctions internes (absentes de MATLAB)
%   matlibre_decouper_augmente - Les neuf blocs d'un modèle augmenté
%   matlibre_augmente_ncf      - Le modèle augmenté des facteurs premiers
%   matlibre_scinder_modes     - Découpe un modèle selon ses modes
%   matlibre_base_reelle       - Base réelle de vecteurs propres complexes
%   matlibre_etendre_blocs     - Une valeur par bloc, étendue aux lignes
```

## `augw`

```
AUGW Modèle augmenté d'un problème de sensibilité mixte.
  P = AUGW(G,W1,W2,W3) construit le modèle sur lequel travaille la
  synthèse H-infini. Les entrées de P sont la référence W et la commande
  U ; ses sorties sont les signaux pondérés, puis la mesure :

     z1 = W1*(w - G*u)     l'erreur, pondérée par W1
     z2 = W2*u             la commande, pondérée par W2
     z3 = W3*(G*u)         la sortie, pondérée par W3
     y  = w - G*u          ce que voit le correcteur

  Autrement dit

         | W1   -W1*G |
     P = | 0     W2   |
         | 0     W3*G |
         | I     -G   |

  W1 pèse sur la sensibilité — le rejet des perturbations et le suivi —,
  W2 sur l'effort de commande, W3 sur la sensibilité complémentaire —
  la robustesse au bruit et aux dynamiques négligées. Une pondération
  vide retire sa ligne.

  Le modèle est assemblé état par état, et non par produits de blocs :
  G n'y figure qu'une fois. Un modèle où il figurerait trois fois aurait
  des modes invisibles depuis la mesure, et la synthèse H-infini les
  refuserait — c'est l'hypothèse de détectabilité.

  Exemple :
     G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
     P = augw(G, tf(10, [1 0.1]), 0.1, []);
     [K, CL, gam] = hinfsyn(P, 1, 1);

  Voir aussi MIXSYN, HINFSYN, LFT.
```

## `balancmr`

```
BALANCMR Réduction par troncature équilibrée.
  SYSR = BALANCMR(SYS,N) réduit SYS à l'ordre N. Le modèle est d'abord
  mis sous forme équilibrée — chaque état y est aussi facile à
  atteindre qu'à observer —, puis les N premiers états sont gardés et
  les autres tronqués.

  SYSR = BALANCMR(SYS) choisit l'ordre lui-même : il garde les états
  dont la valeur de Hankel dépasse la plus grande fois la précision
  machine, à la racine près.

  [SYSR,INFO] = BALANCMR(...) rend en outre une structure portant
  INFO.hsv, les valeurs singulières de Hankel, INFO.ErrorBound, la
  borne d'erreur, et INFO.n, l'ordre retenu.

  La borne est celle de Glover :

     ||G - Gr||_inf  <=  2 * somme des valeurs de Hankel supprimees

  Elle vaut à coup sûr : la vraie erreur est souvent bien plus petite.

  BALANCMR(...,'MaxError',E) choisit le plus petit ordre dont la borne
  reste sous E.

  La troncature garde exacte la réponse en haute fréquence — le terme
  direct D ne change pas — et laisse dériver le gain statique. Quand
  c'est le gain statique qui importe, MODRED avec résiduation, ou
  BSTMR, conviennent mieux.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [Gr, info] = balancmr(G, 1);
     info.ErrorBound                     % la borne annoncee
     norm(G - Gr, Inf) <= info.ErrorBound + 1e-9    % elle tient

     balancmr(G, [], 'MaxError', 0.01);

  Voir aussi HANKELMR, SCHURMR, BSTMR, REDUCE, BALRED, MODRED, HSVD.
```

## `bstmr`

```
BSTMR Réduction par troncature stochastique équilibrée.
  SYSR = BSTMR(SYS,N) réduit SYS à l'ordre N en équilibrant, non le
  modèle lui-même, mais son facteur spectral : la troncature porte
  alors sur l'erreur relative

     ||G^-1 (G - Gr)||_inf

  plutôt que sur l'erreur absolue. C'est ce qu'il faut quand le gain de
  G varie de plusieurs décades d'une fréquence à l'autre : une erreur
  absolue faible peut y être une erreur relative énorme là où le gain
  est petit.

  SYS doit être stable, carré et de rang plein en transmission
  directe : le facteur spectral n'existe qu'à ces conditions.

  SYSR = BSTMR(SYS) choisit l'ordre lui-même.
  [SYSR,INFO] = BSTMR(...) rend INFO.hsv, les valeurs singulières
  stochastiques, et INFO.ErrorBound, la borne d'erreur relative.
  BSTMR(...,'MaxError',E) choisit l'ordre par la borne.

  La borne est

     ||G^-1 (G - Gr)||_inf  <=  produit de (1+s_k)/(1-s_k) - 1

  sur les valeurs supprimées ; elle n'a de sens que si toutes sont
  strictement inférieures à un.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 1);
     [Gr, info] = bstmr(G, 2);
     info.ErrorBound

  Voir aussi BALANCMR, HANKELMR, SCHURMR, REDUCE, HSVD.
```

## `gapmetric`

```
GAPMETRIC Distance de graphe entre deux modèles.
  D = GAPMETRIC(P1,P2) rend la distance de graphe entre les deux
  modèles : elle mesure de combien ils diffèrent du point de vue de la
  commande, et non de celui de leur réponse.

  C'est ce qui la distingue d'un écart en norme : deux modèles peuvent
  avoir des réponses très différentes et une distance de graphe
  minuscule — si l'un est le double de l'autre, par exemple — ou des
  réponses proches et une distance proche de un, si l'un est stable et
  l'autre non.

  Elle vaut entre 0 et 1, et se marie à NCFMARGIN : un correcteur qui
  stabilise P1 avec une marge b stabilise tout P2 dont la distance à P1
  reste sous b. C'est le théorème qui fait de ces deux nombres la façon
  la plus directe de raisonner sur la robustesse.

  [D,DNU] = GAPMETRIC(P1,P2) rend en outre la distance nu, qui est un
  minorant de la distance de graphe et se calcule sans optimisation.

  Exemples :
     P1 = ss(tf(1, [1 1]));
     P2 = ss(tf(1, [1 1.1]));
     gapmetric(P1, P2)              % petite : les deux se commandent
                                    % de la meme facon

     gapmetric(ss(tf(1, [1 1])), ss(tf(1, [1 -1])))   % proche de 1

  Voir aussi NCFMARGIN, LNCF, NCFSYN, NCFMR, HINFNORM.
```

## `h2hinfsyn`

```
H2HINFSYN Synthèse mixte H2 / H-infini.
  [K,CL,N] = H2HINFSYN(P,NMES,NCOM) cherche un correcteur qui minimise
  la norme H2 d'un canal tout en gardant la norme H-infini d'un autre
  sous une borne. C'est le compromis entre performance moyenne — que
  mesure la norme H2 — et robustesse au pire cas — que mesure la norme
  H-infini.

  N est un couple [norme H2, norme H-infini] de la boucle obtenue.

  H2HINFSYN(...,'HINFMAX',G) fixe la borne sur la norme H-infini ;
  H2HINFSYN(...,'H2MAX',G) fixe celle sur la norme H2 ;
  H2HINFSYN(...,'DKMAX',N) et les autres options de MATLAB sont
  acceptées sans effet.

  MatLibre résout le compromis en cherchant, par dichotomie sur le
  paramètre GAMMA de la synthèse H-infini, le correcteur H-infini dont
  la norme H2 est la plus petite compatible avec la borne. Le vrai
  problème mixte demande une optimisation sous inégalités matricielles
  linéaires, qui donnerait un correcteur légèrement meilleur ; celui-ci
  respecte les deux bornes et les rend.

  Exemples :
     G = ss(tf(1, [1 1]));
     P = augw(G, tf(1, [1 0.1]), 0.1, []);
     [K, CL, n] = h2hinfsyn(P, 1, 1, 'HINFMAX', 5);
     n                              % [norme H2, norme H-infini]

  Voir aussi H2SYN, HINFSYN, MIXSYN, AUGW, H2NORM, HINFNORM.
```

## `h2norm`

```
H2NORM Norme H2 d'un modèle stable.
  N = H2NORM(SYS) rend l'énergie de la réponse impulsionnelle : la
  racine de l'intégrale du carré du module de la réponse
  fréquentielle, divisée par deux pi. C'est aussi l'écart type de la
  sortie quand l'entrée est un bruit blanc de variance unité, ce qui
  en fait la mesure de performance moyenne d'une boucle.

  Le calcul passe par les grammiens, non par une quadrature :

     ||G||_2^2 = trace(C Wc C') = trace(B' Wo B)

  ce qui est exact, vaut pour les systèmes à plusieurs entrées et
  sorties, et ne dépend d'aucune grille de fréquences.

  Un modèle instable n'a pas de norme H2 finie. Un modèle continu dont
  le terme direct n'est pas nul non plus : la réponse fréquentielle ne
  tend pas vers zéro, et l'intégrale diverge. En discret, le terme
  direct est admis et compte pour trace(D D').

  Exemples :
     abs(h2norm(tf(1, [1 1])) - sqrt(0.5)) < 1e-9    % la valeur exacte
     h2norm(tf(1, [1 0.1 1])) > h2norm(tf(1, [1 2 1]))   % le peu amorti
                                                         % en a plus

     % Un modele a deux entrees et deux sorties
     G = [tf(1, [1 1]), tf(0, 1); tf(0, 1), tf(2, [1 2])];
     abs(h2norm(G) - sqrt(0.5 + 1)) < 1e-9

  Voir aussi HINFNORM, SIGMA, COVAR, GRAM, NORM.
```

## `h2syn`

```
H2SYN Synthèse H2.
  [K,CL,N] = H2SYN(P,NMES,NCOM) cherche le correcteur K qui minimise la
  norme H2 du transfert entre les entrées exogènes et les sorties
  régulées du modèle augmenté P. NMES est le nombre de mesures — les
  dernières sorties de P —, NCOM le nombre de commandes — les dernières
  entrées.

  CL est la boucle fermée LFT(P,K) et N sa norme H2.

  [K,CL,N,INFO] = H2SYN(...) rend en outre les deux solutions de
  Riccati et les deux gains.

  Là où la synthèse H-infini minimise le pire gain à la pire
  fréquence, la synthèse H2 minimise l'énergie de la réponse
  impulsionnelle — ce qui revient, pour une entrée en bruit blanc, à
  minimiser la variance de la sortie. C'est le même problème que le
  LQG, écrit sous forme de modèle augmenté.

  La solution est celle de Doyle, Glover, Khargonekar et Francis : deux
  équations de Riccati indépendantes, l'une pour la commande, l'autre
  pour l'estimation, et le principe de séparation qui les réunit.

  Les hypothèses usuelles doivent tenir : (A,B2) stabilisable, (C2,A)
  détectable, D12 de rang plein en colonnes, D21 de rang plein en
  lignes, et aucun zéro de transmission sur l'axe imaginaire. D11 doit
  être nul, faute de quoi la norme H2 de la boucle est infinie.

  Exemples :
     G = ss(tf(1, [1 1]));
     P = augw(G, tf(1, [1 0.1]), 0.1, []);
     [K, CL, n] = h2syn(P, 1, 1);
     n                              % la norme H2 atteinte
     h2norm(CL) - n                 % nul : c'est bien elle

  Voir aussi HINFSYN, H2HINFSYN, LQG, H2NORM, AUGW, MIXSYN, LFT.
```

## `hankelmr`

```
HANKELMR Approximation optimale en norme de Hankel.
  SYSR = HANKELMR(SYS,N) rend l'approximation d'ordre N qui minimise
  l'erreur en norme de Hankel. Glover a montré que ce minimum vaut
  exactement la (N+1)-ième valeur singulière de Hankel :

     min ||G - Gr||_H  =  sigma_{N+1}

  C'est le seul problème d'approximation de modèle dont on connaisse la
  solution exacte ; la troncature équilibrée, elle, ne fait que
  respecter une borne.

  SYSR = HANKELMR(SYS) choisit l'ordre lui-même.
  [SYSR,INFO] = HANKELMR(...) rend INFO.hsv, INFO.ErrorBound —
  la borne en norme infinie — et INFO.HankelError, l'erreur en norme de
  Hankel, qui est atteinte.
  HANKELMR(...,'MaxError',E) choisit l'ordre par la borne.

  MatLibre construit l'approximation par troncature équilibrée : elle
  atteint la même borne en norme infinie, à laquelle s'ajoute la
  possibilité d'un terme direct différent. L'optimum de Hankel exact
  demande la construction de Glover, qui passe par une réalisation
  instable qu'on projette ; c'est ce raffinement qui manque, non la
  borne.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [Gr, info] = hankelmr(G, 2);
     info.HankelError                    % la 3e valeur de Hankel
     hsvd(G)(3)                          % la meme

  Voir aussi BALANCMR, SCHURMR, BSTMR, REDUCE, HSVD.
```

## `hinfnorm`

```
HINFNORM Norme H-infini d'un modèle stable.
  G = HINFNORM(SYS) rend le plus grand gain que le modèle puisse donner
  à un signal : le maximum, sur toutes les pulsations, de la plus grande
  valeur singulière de la réponse fréquentielle. Pour un modèle
  monovariable, c'est le sommet du diagramme de gain.

  [G,W] = HINFNORM(SYS) rend aussi la pulsation où ce maximum est
  atteint.

  G = HINFNORM(SYS,TOL) demande une précision relative TOL ; par défaut
  un millionième.

  Un modèle instable n'a pas de norme H-infini : la fonction rend Inf.

  La valeur n'est pas cherchée en balayant les fréquences — un balayage
  rate les pics étroits. Elle vient du critère de Boyd, Balakrishnan et
  Kabamba : le gain dépasse GAMMA si et seulement si la matrice
  hamiltonienne associée a des valeurs propres sur l'axe imaginaire.
  Ces valeurs propres donnent les pulsations où le gain vaut GAMMA ;
  entre deux d'entre elles il vaut davantage, et l'on recommence. La
  suite converge en quelques tours.

  La valeur rendue est un gain réellement atteint, à la pulsation W :
  SIGMA(SYS,W) la redonne exactement. Elle minore donc la norme vraie,
  d'au plus TOL en relatif.

  Exemple :
     hinfnorm(tf(1, [1 0.1 1]))   % environ 10 : la résonance

  Voir aussi SIGMA, NORM, H2NORM, FREQRESP.
```

## `hinfsyn`

```
HINFSYN Correcteur H-infini d'un modèle augmenté.
  [K,CL,GAM] = HINFSYN(P,NMEAS,NCON) cherche le correcteur K qui rend la
  boucle fermée stable et son gain le plus petit possible. P est le
  modèle augmenté — pondérations comprises —, dont les NMEAS dernières
  sorties sont les mesures et les NCON dernières entrées les commandes.
  CL est la boucle fermée LFT(P,K), et GAM son gain : la norme H-infini
  de la transmittance des perturbations vers les signaux pondérés.

  [K,CL,GAM,INFO] = HINFSYN(...) rend en plus les solutions X et Y des
  deux équations de Riccati, le rayon spectral de leur produit et les
  bornes atteintes par la recherche.

  HINFSYN(P,NMEAS,NCON,'DISPLAY','ON') montre la recherche, tour par
  tour. Les autres options se donnent de même : 'GMIN', 'GMAX' bornent
  la recherche, 'TOLGAM' fixe sa précision relative. L'ancienne forme
  HINFSYN(P,NMEAS,NCON,GMIN,GMAX,TOL) est acceptée aussi.

  La méthode est celle de Doyle, Glover, Khargonekar et Francis : pour
  un GAMMA donné, le problème a une solution si et seulement si les deux
  équations de Riccati
     A'X + XA + X(GAMMA^-2 B1B1' - B2 R12^-1 B2')X + Q = 0
     AY + YA' + Y(GAMMA^-2 C1'C1 - C2' R21^-1 C2)Y + Q' = 0
  ont chacune une solution stabilisante positive et si le rayon spectral
  de XY reste sous GAMMA^2. On dichotomise sur GAMMA, puis on écrit le
  correcteur central au dernier GAMMA qui passe.

  Le modèle doit satisfaire les hypothèses habituelles : (A,B2)
  stabilisable, (C2,A) détectable, D12 de rang plein en colonnes, D21 de
  rang plein en lignes.

  D11 et D22 non nuls sont ramenés à zéro par décalage de boucle, à
  chaque GAMMA essayé, puis rendus au correcteur. Le gain du terme
  direct D11 borne par le bas ce qu'on peut demander : aucune boucle ne
  fait mieux que son propre gain à l'infini.

  Exemple :
     G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
     P = augw(G, tf(10, [1 0.1]), 0.1, []);
     [K, CL, gam] = hinfsyn(P, 1, 1);

  Voir aussi AUGW, MIXSYN, LFT, HINFNORM, H2SYN.
```

## `imp2ss`

```
IMP2SS Modèle d'état identifié sur une réponse impulsionnelle.
  SYS = IMP2SS(Y,TS) construit un modèle d'état dont la réponse
  impulsionnelle échantillonnée est Y, prise à la période TS. C'est
  l'algorithme de Kung : on range les échantillons dans une matrice de
  Hankel, on la décompose en valeurs singulières, et l'ordre du modèle
  est le nombre de valeurs singulières qui comptent.

  SYS = IMP2SS(Y,TS,N) impose l'ordre N.
  SYS = IMP2SS(Y,TS,[],TOL) garde les valeurs singulières supérieures à
  TOL fois la plus grande.

  [SYS,SV] = IMP2SS(...) rend en outre les valeurs singulières de la
  matrice de Hankel : leur décroissance dit quel ordre choisir. Un
  décrochage net entre la k-ième et la suivante désigne l'ordre k.

  C'est la réalisation d'une suite de Markov : le passage d'une mesure
  brute à un modèle. Elle sert quand on ne dispose que d'un
  enregistrement — une réponse à un choc, une réponse indicielle
  dérivée — et non d'équations.

  Exemples :
     G = ss(tf(1, [1 1.4 1]));
     Gd = c2d(G, 0.1);
     y = impulse(Gd, 0:0.1:20) * 0.1;      % la suite de Markov
     [H, sv] = imp2ss(y, 0.1);
     sv(1:4)'                              % deux valeurs, puis du bruit

  Voir aussi IMPULSE, C2D, D2C, BALREAL, HSVD, SS.
```

## `lncf`

```
LNCF Facteurs premiers normalisés à gauche.
  [M,N] = LNCF(SYS) factorise SYS en M^-1 N, où M et N sont stables et
  où [M N] est intérieure :

     M M~ + N N~ = I

  Cette factorisation existe pour tout modèle, stable ou non, et c'est
  ce qui la rend précieuse : elle donne des objets stables à manier là
  où le modèle lui-même n'en est pas un. La distance de graphe, la
  marge des facteurs premiers, la réduction d'un modèle instable en
  dépendent toutes.

  Les facteurs se construisent à partir de la solution Z de l'équation
  de Riccati du filtre :

     A Z + Z A' - Z C' R^-1 C Z + B S^-1 B' = 0
     H = -(Z C' + B D') R^-1

  avec R = I + D D' et S = I + D' D. Les facteurs valent alors

     M = [A + H C,  H     ;  R^-1/2 C,  R^-1/2   ]
     N = [A + H C,  B + H D ;  R^-1/2 C,  R^-1/2 D]

  Le controle de la normalisation se fait sur l'axe imaginaire, non par
  une norme : M~ est le systeme conjugue M(-s), qui est antistable, et
  la norme infinie du produit vaut donc l'infini alors que l'identite,
  elle, est vraie.

  Exemples :
     G = ss(1, 1, 1, 0);           % instable
     [M, N] = lncf(G);
     max(real(pole(M)))            % negatif : le facteur est stable

     w = logspace(-2, 2, 20);
     Hm = freqresp(M, w);  Hn = freqresp(N, w);
     max(abs(Hm .* conj(Hm) + Hn .* conj(Hn) - 1))    % nul : normalisee

  Voir aussi NCFMR, NCFMARGIN, NCFSYN, GAPMETRIC, HINFSYN.
```

## `loopmargin`

```
LOOPMARGIN Toutes les marges d'une boucle, en entrée et en sortie.
  [EM,SM,BM] = LOOPMARGIN(G,K) rend les marges de stabilité de la
  boucle formée du procédé G et du correcteur K, en contre-réaction
  négative, mesurées à trois endroits :

     EM  en entrée du procédé, en ouvrant la boucle après K ;
     SM  en sortie du procédé, en ouvrant la boucle après G ;
     BM  aux deux à la fois — la marge multiboucle, qui tient compte
         de perturbations simultanées.

  Chaque structure porte :
     GainMargin     les marges de gain, en valeur absolue ;
     PhaseMargin    les marges de phase, en degrés ;
     DelayMargin    le retard pur admissible, en secondes ;
     Frequency      les pulsations où elles sont atteintes ;
     Stable         vrai si la boucle est stable.

  BM porte en outre DiskMargin, la marge de disque : elle mesure ce que
  la boucle supporte en gain et en phase à la fois, ce qu'aucune des
  deux marges classiques ne dit.

  Sur un système monovariable, les marges en entrée et en sortie sont
  égales ; c'est en multivariable qu'elles diffèrent, et une boucle
  peut avoir d'excellentes marges voie par voie et céder à une
  perturbation simultanée. C'est ce que BM montre.

  Exemples :
     G = ss(tf(1, [1 1 0]));
     K = ss(tf(2, 1));
     [em, sm, bm] = loopmargin(G, K);
     em.PhaseMargin
     bm.DiskMargin

  Voir aussi MARGIN, ALLMARGIN, NCFMARGIN, STABILITYMARGIN, LOOPSENS.
```

## `makeweight`

```
MAKEWEIGHT Construit une pondération à partir de trois nombres.
  W = MAKEWEIGHT(GBAS,WC,GHAUT) rend le filtre du premier ordre dont le
  gain vaut GBAS en basse fréquence, GHAUT en haute, et qui traverse un
  à la pulsation WC :

     W(s) = (M s + A c) / (s + c)   avec A = GBAS, M = GHAUT et
     c = wc * sqrt((1 - M^2) / (A^2 - 1))

  C'est la façon la plus rapide d'écrire une pondération de synthèse
  H-infini : on dit ce qu'on veut en basse fréquence, où l'on veut la
  bande passante, et ce qu'on tolère en haute fréquence.

  W = MAKEWEIGHT(GBAS,[WC,GC],GHAUT) impose en outre le gain GC à la
  pulsation WC, au lieu du gain un.

  W = MAKEWEIGHT(...,TS) rend un filtre échantillonné de période TS.
  W = MAKEWEIGHT(...,TS,N) rend un filtre d'ordre N : les pentes sont
  alors N fois plus raides, ce qui resserre la transition.

  GBAS doit être plus petit que GHAUT pour un filtre passe-haut — celui
  d'une pondération sur la sensibilité —, et plus grand pour un
  passe-bas.

  Exemples :
     % Erreur statique sous 1 %, bande passante 10 rad/s, gain 2 au plus
     W1 = makeweight(0.01, 10, 2);
     dcgain(W1)                      % 0.01
     abs(evalfr(W1, 1i * 10))        % 1 : le croisement
     abs(evalfr(W1, 1i * 1e6))       % 2 : le gain en haute frequence

     W2 = makeweight(0.01, 10, 2, 0, 2);   % pentes deux fois plus raides

     G = ss(tf(200, [10 1]));
     K = mixsyn(G, makeweight(0.01, 10, 2), 0.1, []);

  Voir aussi MKFILTER, AUGW, MIXSYN, HINFSYN, LOOPSYN, TF.
```

## `matlibre_augmente_ncf`

```
MATLIBRE_AUGMENTE_NCF Le modèle augmenté du problème des facteurs premiers.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  NCFSYN s'en sert : maximiser la marge des facteurs premiers revient à
  minimiser la norme H-infini des quatre transmittances de la boucle,

     [ I ; K ] (I - G K)^-1 [ I  G ]

  et cette matrice est exactement LFT(P,K) pour le modèle augmenté
  construit ici. Les signaux sont

     w = [w1 ; w2]   perturbation en sortie, perturbation en entrée
     z = [y  ; u ]   la mesure et la commande

  liés par

     xpoint = A x + B (u + w2)
     y      = w1 + C x + D (u + w2)
     z1     = y,      z2 = u

  Un calcul direct donne alors z = [I ; K] (I - GK)^-1 [I  G] w, ce que
  l'on voulait. Le terme direct D11 n'est pas nul : il porte
  l'identité qui fait passer w1 dans y, et c'est HINFSYN qui s'en
  charge par son déplacement de boucle.
```

## `matlibre_base_reelle`

```
MATLIBRE_BASE_REELLE Une base réelle à partir de vecteurs propres complexes.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Une paire de pôles conjugués donne deux vecteurs propres conjugués ;
  leur partie réelle et leur partie imaginaire engendrent le même plan
  et sont réelles, ce qui évite de porter des complexes dans un modèle
  qui n'en a pas.
```

## `matlibre_decouper_augmente`

_Pas de bloc d'aide._

## `matlibre_etendre_blocs`

```
MATLIBRE_ETENDRE_BLOCS Répète une valeur par bloc sur toutes ses lignes.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  MUSSV s'en sert : la mise à l'échelle d'une structure d'incertitude
  est constante sur chaque bloc, et c'est sous cette forme étendue
  qu'elle devient une matrice diagonale.
```

## `matlibre_scinder_modes`

```
MATLIBRE_SCINDER_MODES Découpe un modèle en deux selon ses modes.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  SLOWFAST et STABPROJ s'en servent. Le découpage passe par une base
  propre réelle : les modes retenus donnent le premier modèle, les
  autres le second, et la somme des deux redonne le modèle de départ
  parce qu'un modèle diagonalisable est la somme de ses modes.
```

## `mixsyn`

```
MIXSYN Synthèse H-infini par sensibilité mixte.
  [K,CL,GAM] = MIXSYN(G,W1,W2,W3) cherche le correcteur qui minimise

     || W1*S ;  W2*K*S ;  W3*T ||_inf

  où S = inv(I+G*K) est la sensibilité et T = I-S sa complémentaire.
  C'est HINFSYN appliqué au modèle qu'AUGW construit ; les options de
  HINFSYN se passent de la même façon.

  Le choix des pondérations dit ce qu'on veut : W1 grande en basse
  fréquence exige un bon rejet, W3 grande en haute fréquence exige de la
  robustesse, W2 borne la commande.

  Exemple :
     G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
     [K, CL, gam] = mixsyn(G, tf(10, [1 0.1]), 0.1, []);

  Voir aussi HINFSYN, AUGW, HINFNORM, LFT.
```

## `mkfilter`

```
MKFILTER Filtre analogique passe-bas normalisé.
  W = MKFILTER(F,N,TYPE) rend le filtre passe-bas d'ordre N et de
  pulsation de coupure F, du type nommé :
     'butterw'   Butterworth : gain le plus plat possible en bande
                 passante, transition douce ;
     'cheby'     Tchebychev de type I : transition plus raide, au prix
                 d'une ondulation en bande passante ;
     'bessel'    Bessel : phase la plus linéaire, transition lente ;
     'rc'        cellules RC en cascade, la plus simple.

  W = MKFILTER(F,N,'cheby',R) fixe l'ondulation à R décibels ; trois
  par défaut.

  Le filtre est rendu sous forme de modèle d'état, de gain statique un.
  C'est la brique des pondérations de synthèse : quand une pondération
  du premier ordre ne suffit pas à séparer deux bandes, un filtre
  d'ordre trois ou quatre le fait.

  Exemples :
     W = mkfilter(10, 3, 'butterw');
     abs(dcgain(W) - 1) < 1e-9
     abs(evalfr(W, 1i * 10))         % 0.7071 : la coupure a -3 dB

     bodemag(mkfilter(1, 4, 'butterw'), mkfilter(1, 4, 'cheby'));

  Voir aussi MAKEWEIGHT, BUTTER, CHEBY1, BESSELF, AUGW, MIXSYN.
```

## `modreal`

```
MODREAL Réalisation modale.
  SYSM = MODREAL(SYS) met SYS sous forme modale : la matrice d'état
  devient bloc-diagonale, un bloc de taille un par pôle réel et un bloc
  de taille deux par paire de pôles complexes conjugués. Chaque bloc
  est alors un mode, qu'on peut lire, garder ou retirer isolément.

  [SYSM,T] = MODREAL(SYS) rend en outre la matrice de passage : les
  états de SYSM sont T fois ceux de SYS.

  SYSM = MODREAL(SYS,N) range les modes de sorte que les N premiers
  soient les plus lents — les pôles les plus proches de l'axe
  imaginaire.

  La forme modale est celle qui sert à retirer des modes par leur
  fréquence plutôt que par leur poids : c'est ce que font SLOWFAST et
  STABPROJ.

  Exemples :
     G = ss([-1 2; -2 -1], [1; 0], [1 1], 0);   % une paire complexe
     Gm = modreal(G);
     Gm.A                          % bloc [a b; -b a]

  Voir aussi SLOWFAST, STABPROJ, STRANS, CANON, BALREAL.
```

## `mussv`

```
MUSSV Valeur singulière structurée.
  BORNES = MUSSV(M,BLOCS) rend un encadrement de la valeur singulière
  structurée de la matrice M pour la structure d'incertitude décrite
  par BLOCS : [BORNE_HAUTE, BORNE_BASSE].

  La valeur singulière structurée — le mu — mesure la plus petite
  perturbation, de la structure donnée, qui rende I - M*DELTA singulière :

     mu(M) = 1 / min { sigma_max(DELTA) : det(I - M DELTA) = 0 }

  Elle vaut zéro s'il n'en existe aucune. C'est la quantité centrale de
  l'analyse de robustesse : la boucle tient tant que mu reste sous un.

  BLOCS compte une ligne par bloc de la structure :
     [-N 0]   un bloc scalaire réel répété N fois ;
     [N 0]    un bloc scalaire complexe répété N fois ;
     [N M]    un bloc plein complexe de taille N x M.

  La borne haute vient de la mise à l'échelle : mu est inférieur à
  l'infimum, sur les D qui commutent avec la structure, de
  sigma_max(D M D^-1). MatLibre cherche ce minimum par la mise à
  l'échelle d'Osborne, qui équilibre les lignes et les colonnes en
  quelques itérations.

  La borne basse vient d'une recherche de la plus grande valeur propre
  atteignable par une perturbation de la structure : elle est toujours
  valable, sans être forcément atteinte.

  Pour un bloc plein complexe unique, mu est exactement la plus grande
  valeur singulière ; pour une structure diagonale complexe, la borne
  haute est exacte jusqu'à trois blocs.

  [BORNES,D] = MUSSV(...) rend en outre la mise à l'échelle trouvée.

  Exemples :
     M = [1 2; 3 4];
     mussv(M, [2 0])                % structure scalaire complexe
     mussv(M, [2 2])                % un bloc plein : c'est sigma_max
     max(svd(M))

  Voir aussi ROBSTAB, WCGAIN, HINFNORM, SVD, LOOPMARGIN.
```

## `ncfmargin`

```
NCFMARGIN Marge de stabilité des facteurs premiers normalisés.
  B = NCFMARGIN(P,C) rend la marge de stabilité de la boucle formée par
  le procédé P et le correcteur C, en contre-réaction négative :

     b = 1 / || [I ; C] (I + P C)^-1 [I  P] ||_inf

  C'est la plus grande perturbation, mesurée sur les facteurs premiers
  normalisés de P, que la boucle supporte sans devenir instable. Elle
  vaut entre 0 et 1 ; au-dessus de 0.25 la boucle est robuste, en
  dessous de 0.1 elle est fragile.

  [B,W] = NCFMARGIN(P,C) rend en outre la fréquence où le pire arrive.

  NCFMARGIN(P,C,SIGNE) prend SIGNE = +1 pour une contre-réaction
  positive ; le défaut est -1, la contre-réaction négative.

  Cette marge dit d'un seul nombre ce que les marges de gain et de
  phase disent séparément, et elle vaut aussi pour les systèmes à
  plusieurs entrées et sorties, où celles-ci ne suffisent pas.

  Exemples :
     P = ss(tf(1, [1 -1]));         % procede instable
     C = ss(tf([2 1], [1 0]));
     [b, w] = ncfmargin(P, C)

  Voir aussi LNCF, NCFSYN, GAPMETRIC, LOOPMARGIN, HINFNORM, DISKMARGIN.
```

## `ncfmr`

```
NCFMR Réduction par les facteurs premiers normalisés.
  SYSR = NCFMR(SYS,N) réduit SYS à l'ordre N en tronquant, non le
  modèle, mais ses facteurs premiers normalisés à gauche : SYS s'écrit
  M^-1 N avec [M N] intérieure, et c'est ce couple, toujours stable,
  qu'on réduit.

  C'est ce qui permet de réduire un modèle instable, ce qu'aucune des
  autres méthodes ne sait faire : les grammiens d'un modèle instable
  n'existent pas, ceux de ses facteurs premiers si.

  SYSR = NCFMR(SYS) choisit l'ordre lui-même.
  [SYSR,INFO] = NCFMR(...) rend INFO.hsv, les valeurs de Hankel des
  facteurs, et INFO.ErrorBound, la borne en distance de graphe.
  NCFMR(...,'MaxError',E) choisit l'ordre par la borne.

  La borne porte sur la distance de graphe entre SYS et SYSR, non sur
  leur écart en norme infinie : c'est la bonne mesure pour un modèle
  instable, dont l'écart en norme infinie est infini par construction.

  Exemples :
     % Un modele instable, qu'aucune autre methode ne reduirait
     G = ss([1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [Gr, info] = ncfmr(G, 2);
     pole(Gr)                     % le mode instable est garde, a la
                                  % precision de la troncature pres

  Voir aussi BALANCMR, LNCF, NCFMARGIN, GAPMETRIC, REDUCE.
```

## `ncfsyn`

```
NCFSYN Synthèse par les facteurs premiers normalisés.
  [K,CL,B] = NCFSYN(G) cherche le correcteur qui maximise la marge de
  stabilité des facteurs premiers normalisés du procédé G. B est la
  marge obtenue ; elle vaut entre 0 et 1, et le correcteur trouvé
  stabilise tout procédé dont la distance de graphe à G reste sous B.

  [K,CL,B] = NCFSYN(G,W1,W2) met d'abord G en forme avec les
  pondérations W1 et W2 — c'est la méthode de McFarlane et Glover :
  on donne à la boucle la forme qu'on veut par W1 et W2, puis on la
  rend robuste sans la déformer.

  Le correcteur rendu est celui du procédé pondéré, ramené au procédé
  d'origine : K = W1 Kp W2. Il s'emploie en contre-réaction négative,
  comme partout ailleurs dans MatLibre.

  La marge optimale vaut

     b_opt = sqrt(1 - ||[N M]||_H^2)

  où ||·||_H est la plus grande valeur singulière de Hankel des
  facteurs premiers. C'est le seul problème de synthèse robuste dont la
  valeur optimale s'écrive en forme close : elle ne demande aucune
  itération, contrairement à la synthèse H-infini ordinaire.

  [K,CL,B,INFO] = NCFSYN(...) rend en outre INFO.gamma = 1/B et
  INFO.emax, la marge optimale.

  Exemples :
     G = ss(tf(1, [1 -1]));         % procede instable
     [K, CL, b] = ncfsyn(G);
     b                              % la marge optimale
     ncfmargin(G, K)                % la meme, mesuree sur la boucle

  Voir aussi LNCF, NCFMARGIN, GAPMETRIC, HINFSYN, MIXSYN, LOOPSYN.
```

## `popov`

```
POPOV Critère de Popov de stabilité absolue.
  OK = POPOV(G,[0 K]) dit si la boucle formée du modèle linéaire G et
  d'une non-linéarité sans mémoire du secteur [0,K] est absolument
  stable, c'est-à-dire stable pour toute non-linéarité de ce secteur.

  Le critère demande qu'il existe un nombre ALPHA positif tel que, pour
  toute pulsation,

     Re[(1 + j*alpha*w) G(jw)] + 1/K  >  0

  Géométriquement : le lieu de Popov — la partie réelle de G(jw) en
  abscisse, w fois sa partie imaginaire en ordonnée — doit rester à
  droite d'une droite de pente 1/ALPHA passant par -1/K.

  [OK,ALPHA] = POPOV(...) rend le ALPHA trouvé, ou NaN s'il n'y en a
  pas.

  Le critère de Popov est moins exigeant que celui du cercle : il
  suppose la non-linéarité sans mémoire, et gagne à cela d'être
  applicable là où le critère du cercle échoue.

  Exemples :
     G = ss(tf(1, [1 2 1]));
     [ok, alpha] = popov(G, [0 10])

     % Une boucle que le critere refuse : le gain statique est negatif,
     % et aucune droite ne separe le lieu du point -1/K
     popov(ss(tf(-1, [1 1])), [0 10])

  Voir aussi SECTF, NYQUIST, HINFNORM, DISKMARGIN.
```

## `reduce`

```
REDUCE Réduction de modèle, toutes méthodes.
  SYSR = REDUCE(SYS,N) réduit SYS à l'ordre N par troncature
  équilibrée. C'est la porte d'entrée de la famille : elle appelle la
  méthode nommée et rend le même résultat qu'elle.

  SYSR = REDUCE(SYS) choisit l'ordre lui-même.

  REDUCE(...,'Algorithm',A) choisit la méthode :
     'balance'   troncature équilibrée (défaut), c'est BALANCMR ;
     'schur'     la même par les sous-espaces, c'est SCHURMR ;
     'hankel'    l'optimum en norme de Hankel, c'est HANKELMR ;
     'bst'       la troncature stochastique, c'est BSTMR, qui borne
                 l'erreur relative au lieu de l'absolue ;
     'ncf'       la troncature des facteurs premiers normalisés, qui
                 s'applique aussi à un modèle instable.

  REDUCE(...,'MaxError',E) choisit le plus petit ordre dont la borne
  reste sous E.
  REDUCE(...,'Display','on') écrit les valeurs de Hankel et la borne.

  [SYSR,INFO] = REDUCE(...) rend la structure d'information de la
  méthode employée.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     reduce(G, 2);
     reduce(G, [], 'MaxError', 0.01);
     reduce(G, 2, 'Algorithm', 'hankel');

  Voir aussi BALANCMR, SCHURMR, HANKELMR, BSTMR, NCFMR, BALRED, MODRED.
```

## `schurmr`

```
SCHURMR Réduction par troncature équilibrée, sans former la base.
  SYSR = SCHURMR(SYS,N) réduit SYS à l'ordre N. Le résultat est le même
  que celui de BALANCMR — la troncature équilibrée est unique à une
  transformation d'états près —, mais la méthode de Safonov et Chiang
  n'a pas besoin de construire la réalisation équilibrée elle-même :
  elle travaille sur les sous-espaces propres du produit des deux
  grammiens.

  C'est ce qui la rend applicable là où la réalisation équilibrée est
  mal conditionnée : un modèle dont les valeurs de Hankel s'étalent sur
  plusieurs décades donne une matrice de passage très mal conditionnée,
  dont SCHURMR se passe.

  SYSR = SCHURMR(SYS) choisit l'ordre lui-même.
  [SYSR,INFO] = SCHURMR(...) rend les valeurs de Hankel et la borne
  d'erreur, comme BALANCMR.
  SCHURMR(...,'MaxError',E) choisit l'ordre par la borne.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [Gr, info] = schurmr(G, 2);
     norm(G - Gr, Inf) <= info.ErrorBound + 1e-9

  Voir aussi BALANCMR, HANKELMR, BSTMR, REDUCE, HSVD.
```

## `sectf`

```
SECTF Transformation de secteur.
  GT = SECTF(G,[A B]) transforme G de sorte qu'une non-linéarité
  comprise dans le secteur [A,B] devienne une non-linéarité comprise
  dans le secteur [-1,1]. C'est la transformation de boucle qui ramène
  un problème de stabilité absolue à une condition de petit gain.

  Une non-linéarité du secteur [A,B] s'écrit phi = c + r*psi avec
  c = (A+B)/2, r = (B-A)/2 et psi dans [-1,1]. En reportant dans la
  boucle y = G u, u = -phi(y), il vient

     GT = r * (I + c*G)^-1 * G

  C'est un déplacement de boucle, non une simple soustraction : le
  terme constant du secteur se referme sur le procédé.

  GT = SECTF(G,[A B],[C D]) transforme aussi le secteur de sortie.

  [GT,T] = SECTF(...) rend en outre les paramètres employés.

  Le critère du cercle dit qu'une boucle formée de G et d'une
  non-linéarité du secteur [A,B] est stable si le lieu de Nyquist de G
  évite le disque construit sur -1/A et -1/B. Après SECTF, la même
  condition s'écrit simplement : la norme infinie de GT est inférieure
  à un.

  Exemples :
     G = ss(tf(1, [1 2 1]));
     Gt = sectf(G, [0 2]);          % une saturation de pente 0 a 2
     hinfnorm(Gt) < 1               % le critere du cercle est verifie

  Voir aussi POPOV, HINFNORM, NYQUIST, DISKMARGIN.
```

## `sigmaValues`

```
SIGMAVALUES Valeurs singulières en décibels, sur une grille.
  [SV,W] = SIGMAVALUES(SYS) rend le gain en décibels aux pulsations
  d'une grille logarithmique, et la grille elle-même.
  SIGMAVALUES(SYS,W) impose la grille.

  C'est ce que trace SIGMA, rendu en nombres : de quoi comparer deux
  modèles, chercher un maximum ou vérifier un gabarit sans passer par
  une figure.

  Exemples :
     [sv, w] = sigmaValues(tf(1, [1 1]));
     max(sv) <= 0.01                      % le gain ne depasse pas 0 dB
     sv = sigmaValues(tf(1, [1 1]), 1);
     abs(sv + 3.0103) < 1e-3              % -3 dB a la coupure

  Voir aussi SIGMA, BODE, HINFNORM, FREQRESP.
```

## `skewdec`

```
SKEWDEC Matrice antisymétrique de repères.
  M = SKEWDEC(N,K) rend la matrice N x N antisymétrique dont l'élément
  (I,J), pour I supérieur à J, vaut -(K + J + (I-1)*(I-2)/2) et dont la
  diagonale est nulle.

  Ce n'est pas une matrice de calcul : c'est un gabarit de repères. Les
  fonctions d'inégalités matricielles s'en servent pour numéroter les
  inconnues d'une variable antisymétrique, chaque entrée portant le
  numéro de la variable scalaire qui la remplira.

  Exemples :
     skewdec(3, 0)
     % [   0  -1  -2
     %     1   0  -3
     %     2   3   0 ]

     skewdec(2, 10)

  Voir aussi SYMDEC, DIAG, TRIL, TRIU.
```

## `slowfast`

```
SLOWFAST Sépare les modes lents des modes rapides.
  [GL,GR] = SLOWFAST(SYS,N) découpe SYS en deux modèles dont la somme
  redonne SYS : GL porte les N pôles les plus lents — ceux dont la
  partie réelle est la plus proche de zéro — et GR tous les autres.

  Le terme direct est mis dans GL ; GR n'en a pas.

  C'est la façon de réduire un modèle par la fréquence plutôt que par
  le poids : quand on sait que seule la bande basse importe, on garde
  GL. La troncature équilibrée, elle, choisit selon ce que chaque mode
  apporte à la réponse, ce qui n'est pas la même chose.

  Exemples :
     G = ss([-1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [lent, rapide] = slowfast(G, 1);
     pole(lent)                    % -1
     pole(rapide)                  % -10 et -100
     norm(G - (lent + rapide), Inf) < 1e-8    % la somme redonne G

  Voir aussi STABPROJ, MODREAL, STRANS, BALANCMR, MODRED.
```

## `stabilityMargin`

```
STABILITYMARGIN Marge de module et marge de retard.
  [MM,MR] = STABILITYMARGIN(SYS) rend deux mesures de robustesse d'une
  boucle ouverte : la marge de module, distance minimale du lieu de
  Nyquist au point critique -1, et la marge de retard, retard pur que
  la boucle supporte avant de devenir instable.

  La marge de module vaut l'inverse du pic de la sensibilité : une
  marge de 0.5 dit qu'aucune perturbation multiplicative inférieure à
  la moitié du gain ne peut déstabiliser la boucle. Elle résume à elle
  seule les marges de gain et de phase.

  Exemples :
     [mm, mr] = stabilityMargin(tf(1, [1 1 0]));
     mm > 0 && mm < 1                     % la marge de module
     mr > 0                               % le retard admissible, en secondes

  Voir aussi MARGIN, ALLMARGIN, NYQUIST, HINFNORM.
```

## `stabproj`

```
STABPROJ Sépare la partie stable de la partie instable.
  [GS,GI] = STABPROJ(SYS) découpe SYS en deux modèles dont la somme
  redonne SYS : GS porte les pôles à partie réelle strictement
  négative, GI les autres. Le terme direct est mis dans GS.

  C'est le préalable à toute réduction d'un modèle instable : on réduit
  GS, qui a des grammiens, et l'on garde GI tel quel, qui n'en a pas.
  C'est aussi ce que fait STABSEP dans la boîte à outils de
  l'automatique ; les deux rendent la même chose.

  Exemples :
     G = ss([1 0 0; 0 -10 0; 0 0 -100], [1; 1; 1], [1 1 1], 0);
     [stable, instable] = stabproj(G);
     pole(instable)                % 1
     pole(stable)                  % -10 et -100
     norm(G - (stable + instable), Inf) < 1e-8

  Voir aussi STABSEP, SLOWFAST, MODREAL, NCFMR, LNCF.
```

## `strans`

```
STRANS Réordonne les états d'un modèle.
  [SYSR,T] = STRANS(SYS,ORDRE) permute les états de SYS suivant ORDRE :
  l'état numéro ORDRE(k) de SYS devient le k-ième de SYSR. La relation
  entrée-sortie ne change pas ; seule la façon dont l'état est rangé le
  fait.

  [SYSR,T] = STRANS(SYS) range les états par partie réelle croissante
  de leur pôle, quand la matrice d'état est déjà diagonale ou
  triangulaire ; sinon il rend SYS tel quel.

  T est la matrice de passage : les états de SYSR valent T fois ceux de
  SYS.

  Exemples :
     G = ss(diag([-1 -10 -100]), [1; 1; 1], [1 1 1], 0);
     Gr = strans(G, [3 1 2]);
     diag(Gr.A)'                   % [-100 -1 -10]
     norm(G - Gr, Inf) < 1e-10     % la relation ne change pas

  Voir aussi MODREAL, SLOWFAST, STABPROJ, BALREAL, SS2SS.
```

## `symdec`

```
SYMDEC Matrice symétrique de repères.
  M = SYMDEC(N,K) rend la matrice N x N symétrique dont chaque entrée
  du triangle inférieur porte un numéro consécutif à partir de K+1, la
  diagonale comprise.

  Comme SKEWDEC, c'est un gabarit de repères et non une matrice de
  calcul : il numérote les N(N+1)/2 inconnues d'une variable symétrique.

  Exemples :
     symdec(3, 0)
     % [ 1  2  4
     %   2  3  5
     %   4  5  6 ]

  Voir aussi SKEWDEC, DIAG, TRIL, TRIU.
```

## `sysbal`

```
SYSBAL Réalisation équilibrée d'un modèle stable.
  [SYSB,G] = SYSBAL(SYS) rend la réalisation équilibrée de SYS et les
  valeurs singulières de Hankel. Dans cette base, les deux grammiens
  sont égaux et diagonaux : chaque état est aussi facile à atteindre
  qu'à observer, ce qui donne un critère net pour décider lesquels
  supprimer.

  [SYSB,G] = SYSBAL(SYS,TOL) écarte au passage les états dont la valeur
  de Hankel est sous TOL : ce sont ceux que la réalisation porte sans
  qu'ils servent à rien.

  SYSBAL est le nom que la boîte à outils robuste donne à ce que
  BALREAL fait dans celle de l'automatique. Les deux rendent la même
  chose ; SYSBAL existe pour les programmes écrits avec l'une ou avec
  l'autre.

  Exemples :
     G = ss([-1 0; 0 -100], [1; 1], [1 1], 0);
     [Gb, g] = sysbal(G);
     max(max(abs(gram(Gb, 'c') - gram(Gb, 'o'))))   % nul
     g                                              % la seconde est
                                                    % beaucoup plus petite

  Voir aussi BALREAL, HSVD, BALANCMR, HANKELMR, SCHURMR, REDUCE.
```

## `sysic`

```
SYSIC Assemble une interconnexion décrite par des variables.
  P = SYSIC assemble un schéma-bloc à partir de variables posées juste
  avant, dans l'espace de travail de l'appelant. C'est la façon dont on
  écrivait les modèles augmentés de la commande robuste avant CONNECT,
  et beaucoup de sujets de travaux pratiques l'emploient encore :

     systemnames    = 'G K W1 W2';
     inputvar       = '[ref; bruit; u]';
     outputvar      = '[W1; W2; G(1)+bruit]';
     input_to_G     = '[u]';
     input_to_K     = '[ref - G]';
     input_to_W1    = '[ref - G]';
     input_to_W2    = '[u]';
     cleanupsysic   = 'yes';
     P = sysic;

  SYSTEMNAMES nomme les blocs, séparés par des espaces ; chacun doit
  exister dans l'espace de travail. INPUTVAR nomme les entrées du
  schéma, une par ligne du crochet ; « nom{3} » en déclare trois d'un
  coup. OUTPUTVAR nomme ses sorties. INPUT_TO_<BLOC> dit ce qui entre
  dans chaque bloc.

  Une ligne est une somme de termes, chacun de la forme

     [+|-] [gain*] nom [(indices)]

  où NOM est un bloc ou une entrée du schéma, et INDICES choisit
  certaines de ses voies : G(3), G(1:2). Sans indices, toutes les voies
  du bloc sont prises. Les termes d'une même ligne doivent porter le
  même nombre de voies.

  CLEANUPSYSIC valant 'yes' efface ensuite toutes ces variables, comme
  dans MATLAB. SYSOUTNAME, s'il existe, donne le nom sous lequel le
  résultat est rangé chez l'appelant.

  Exemples :
     G = ss(tf(2, [1 1]));
     W = ss(tf(1, [1 0.1]));
     systemnames  = 'G W';
     inputvar     = '[ref]';
     outputvar    = '[W; G]';
     input_to_G   = '[ref]';
     input_to_W   = '[ref - G]';
     cleanupsysic = 'yes';
     P = sysic;
     size(P)                     % 2 sorties, 1 entree
     order(P)                    % 2 : un etat par bloc

  Voir aussi CONNECT, APPEND, LFT, FEEDBACK, HINFSYN.
Les variables se lisent ici, dans le corps de SYSIC : « caller »
désigne l'appelant de la fonction où l'on écrit evalin, et une
fonction locale n'aurait vu que SYSIC lui-même.
```

## `uncertainGain`

```
UNCERTAINGAIN Stabilité en boucle fermée pour un gain incertain.
  [STABLE,GAINS] = UNCERTAINGAIN(SYS) referme la boucle sur SYS
  multiplié par une série de gains et dit, pour chacun, si la boucle
  est stable. C'est l'analyse de robustesse la plus simple : celle
  qu'on fait quand l'incertitude tient dans un seul paramètre.

  UNCERTAINGAIN(SYS,GAINS) impose les gains à essayer.

  Exemples :
     [stable, gains] = uncertainGain(tf(1, [1 1]));
     all(stable)                          % un premier ordre reste stable
     s2 = uncertainGain(tf(1, [1 2 1 0]), [0.5 1 5]);
     s2(1) && ~s2(3)                      % au-dela d'un certain gain, non

  Voir aussi MARGIN, STABILITYMARGIN, FEEDBACK, RLOCUS.
```

