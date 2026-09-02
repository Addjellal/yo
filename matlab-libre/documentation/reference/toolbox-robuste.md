# Toolbox `robuste`

```
% Robust Control Toolbox — analyse et synthèse robustes.
%
% Objets incertains
%   ureal        - Paramètre réel incertain
%   ucomplex     - Paramètre complexe incertain
%   ucomplexm    - Matrice complexe incertaine
%   ultidyn      - Bloc dynamique incertain
%   udyn         - Bloc incertain non modélisé
%   umat         - Matrice incertaine
%   uss          - Modèle d'état incertain
%   genmat, genss - Les mêmes, vus comme réglables
%   complexify   - Ajoute une pincée d'incertitude complexe
%   usubs, usample, getNominal, uncertain, ussdata
%   actual2normalized, normalized2actual
%   randatom, randumat, randuss - Objets tirés au hasard
%   ltiarray2uss - Enveloppe incertaine d'une famille mesurée
%
% Analyse de robustesse
%   robstab, robuststab - Marge de stabilité robuste
%   robgain      - Marge de performance robuste
%   wcgain       - Pire gain
%   wcnorm       - Pire norme d'une matrice
%   wcsens       - Pires sensibilités d'une boucle
%   wcdiskmargin - Pires marges de disque
%   wcunc, wcgopt - Valeurs du pire cas, options de la recherche
%   dmplot       - Ce qu'une marge de disque autorise
%   sisobnds     - Bornes de robustesse dans le plan du correcteur
%
% Synthèse mu
%   dksyn, musyn - Itération D-K
%   hinfstruct   - Synthèse à correcteur structuré
%   cmsclsyn     - Mise à l'échelle constante optimale
%
% Réponses mesurées
%   frd          - Modèle de réponse fréquentielle
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
%   icsignal, iconnect - Assemblage par équations (forme ancienne)
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
%   matlibre_incertitudes      - Paramètres et fonction d'évaluation
%   matlibre_balayer_incertitude - Recherche du pire cas sur le pavé
%   matlibre_point_vers_valeurs  - Coordonnées vers structure nommée
%   matlibre_tirer_atome         - Un tirage, selon le genre du paramètre
%   matlibre_bornes_atome        - Nominal et bornes d'un paramètre
%   matlibre_pire_pole           - Stabilité en un seul nombre
%   matlibre_gain_ou_zero        - La norme, l'infini rendu comparable
%   matlibre_pic_sensibilite     - Le pic d'une transmittance de boucle
%   matlibre_marge_disque        - La marge de disque d'une boucle
%   matlibre_mettre_a_echelle    - Le modèle augmenté, mis à l'échelle
%   matlibre_mu_boucle           - La borne de mu d'une boucle
%   matlibre_cout_structure      - Le critère de HINFSTRUCT
%   matlibre_atome               - Un paramètre d'un genre quelconque
```

## `actual2normalized`

```
ACTUAL2NORMALIZED Passe de la valeur réelle d'un paramètre à sa valeur normalisée.
  N = ACTUAL2NORMALIZED(P,V) rend la valeur normalisée qui correspond à
  la valeur réelle V du paramètre incertain P. La normalisation envoie
  la valeur nominale sur zéro, la borne haute sur un et la borne basse
  sur moins un :

     N = (V - nominal) / (haut - nominal)     si V dépasse le nominal
     N = (V - nominal) / (nominal - bas)      sinon

  C'est la coordonnée dans laquelle l'analyse de robustesse travaille :
  un rayon de robustesse de 1.4 veut dire que la boucle tient jusqu'à
  1.4 fois l'écart déclaré, quel que soit le paramètre.

  V peut être un tableau ; N a la même taille.

  Exemples :
     p = ureal('p', 10, 'Range', [8 15]);
     actual2normalized(p, 10)           % 0 : le nominal
     actual2normalized(p, 15)           % 1 : la borne haute
     actual2normalized(p, 8)            % -1 : la borne basse
     actual2normalized(p, 20)           % 2 : deux fois l'ecart

  Voir aussi NORMALIZED2ACTUAL, UREAL, ROBSTAB, WCGAIN.
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

## `cmsclsyn`

```
CMSCLSYN Mise à l'échelle constante qui minimise une norme.
  [D,GAMMA] = CMSCLSYN(R) cherche la matrice diagonale D, à termes
  positifs, qui minimise la plus grande valeur singulière de D*R*inv(D)
  sur toutes les tranches de R.

  C'est l'étape D de l'itération D-K, isolée : quand on a la boucle
  fermée, cette mise à l'échelle donne la meilleure borne haute de mu
  qu'une mise à l'échelle constante permette.

  R est une matrice, ou un tableau à trois dimensions dont chaque
  tranche est une matrice — la réponse à une fréquence, par exemple.

  [D,GAMMA,INFO] = CMSCLSYN(R) rend en outre la valeur avant mise à
  l'échelle, pour mesurer ce qu'elle a gagné.

  La recherche est celle d'Osborne : on équilibre les normes de chaque
  ligne et de la colonne correspondante, ce qui converge en quelques
  tours et donne l'optimum pour une matrice à structure scalaire.

  Exemples :
     R = [1 100; 0.01 1];
     [D, g] = cmsclsyn(R);
     g                               % bien plus petit que max(svd(R))
     max(svd(R))

  Voir aussi MUSSV, DKSYN, MUSYN, SVD.
```

## `complexify`

```
COMPLEXIFY Ajoute une petite incertitude complexe à un paramètre réel.
  U = COMPLEXIFY(P,R) rend le paramètre P entouré d'une incertitude
  complexe de rayon R : U = P + R*delta, où delta est complexe de
  module au plus un.

  U = COMPLEXIFY(P,R,'nom') nomme le bloc complexe ajouté.

  À quoi cela sert : le mu réel est discontinu — une perturbation
  infinitésimale des données peut faire sauter sa valeur — et l'analyse
  d'un modèle purement réel est donc numériquement fragile. Ajouter une
  pincée de complexe régularise le problème, au prix d'un léger
  pessimisme. C'est le remède classique, et R vaut d'ordinaire quelques
  centièmes.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     kc = complexify(k, 0.05);
     usample(kc, 3)

  Voir aussi UREAL, UCOMPLEX, MUSSV, ROBSTAB, WCGAIN.
```

## `dksyn`

```
DKSYN Synthèse mu par itération D-K.
  [K,CL,MU] = DKSYN(P,NMES,NCOM) cherche un correcteur qui minimise la
  valeur singulière structurée de la boucle fermée, c'est-à-dire qui
  rend la boucle robuste à l'incertitude que P décrit.

  L'itération alterne deux étapes qu'on sait chacune résoudre :
    D : à correcteur figé, chercher la mise à l'échelle qui minimise
        la borne haute de mu — c'est ce que fait MUSSV ;
    K : à mise à l'échelle figée, chercher le correcteur H-infini du
        problème mis à l'échelle — c'est HINFSYN.
  Chaque étape fait décroître le critère, mais l'alternance n'a pas de
  garantie de converger vers l'optimum : c'est la limite bien connue de
  la méthode, et non un défaut de cette implémentation.

  [K,CL,MU,INFO] = DKSYN(...) rend le détail de chaque tour.

  DKSYN(...,OPTIONS) accepte une structure portant Tours, le nombre
  d'itérations — quatre par défaut.

  MatLibre emploie une mise à l'échelle constante en fréquence, non un
  ajustement de D par une fonction rationnelle : c'est la variante dite
  « D constant », qui suffit quand l'incertitude est peu dispersée en
  fréquence et qui reste sensiblement plus simple. Une mise à l'échelle
  variable donnerait un correcteur un peu meilleur, et d'ordre plus
  élevé.

  Exemples :
     G = ss(tf(1, [1 1]));
     P = augw(G, tf(1, [1 0.1]), 0.1, []);
     [K, CL, mu] = dksyn(P, 1, 1);
     mu                              % la valeur atteinte

  Voir aussi MUSSV, HINFSYN, MUSYN, ROBSTAB, WCGAIN, MIXSYN.
```

## `dmplot`

```
DMPLOT Trace ce qu'une marge de disque autorise.
  DMPLOT(DM) trace, dans le plan gain-phase, la région des variations
  simultanées que la marge de disque DM autorise sans déstabiliser la
  boucle. On y lit d'un coup ce que la marge veut dire : jusqu'où le
  gain peut varier si la phase ne bouge pas, jusqu'où la phase peut
  varier si le gain ne bouge pas, et tous les compromis entre les deux.

  [G,P] = DMPLOT(DM) rend les deux courbes sans rien tracer : G les
  variations de gain, en décibels, P celles de phase, en degrés.

  La frontière est celle du disque de rayon DM autour de un :
  l'incertitude multiplicative (1 + DM*delta) avec delta de module au
  plus un. Le gain va de (1-DM) à (1+DM), et la phase jusqu'à
  2*asin(DM/2).

  Exemples :
     dmplot(0.5);
     [g, p] = dmplot(0.3);
     max(p)                          % la marge de phase pure, en degres
     max(g)                          % la marge de gain pure, en dB

  Voir aussi LOOPMARGIN, WCDISKMARGIN, NCFMARGIN, MARGIN, ALLMARGIN.
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

## `genmat`

```
GENMAT Matrice généralisée : une matrice à paramètres.
  M = GENMAT(X) fait d'une matrice ordinaire une matrice généralisée.

  Dans MATLAB, une matrice généralisée est celle qui dépend de blocs
  réglables — des REALP — plutôt que de blocs incertains. La différence
  est d'intention : un paramètre incertain est ce qu'on subit, un
  paramètre réglable est ce qu'on choisit. La représentation est la
  même.

  MatLibre n'a qu'une représentation, celle d'UMAT : GENMAT rend donc
  un UMAT, et l'arithmétique est celle d'UMAT. Ce qui manque est la
  synthèse structurée — HINFSTRUCT —, qui réglerait ces paramètres.

  Exemples :
     k = ureal('k', 1, 'Range', [0 10]);
     M = genmat([1 k; 0 1]);
     getNominal(M)
     usubs(M, 'k', 5)

  Voir aussi UMAT, UREAL, GENSS, HINFSTRUCT, USUBS.
```

## `genss`

```
GENSS Modèle d'état généralisé : un modèle à paramètres.
  SYS = GENSS(A,B,C,D) crée un modèle dont les matrices peuvent
  dépendre de paramètres réglables.
  SYS = GENSS(SYS) fait d'un modèle ordinaire un modèle généralisé.

  Comme pour GENMAT, la différence avec un modèle incertain est
  d'intention et non de représentation : MatLibre rend un USS, dont
  l'arithmétique et la substitution valent aussi bien.

  Ce qui manque est la synthèse structurée — HINFSTRUCT —, qui
  règlerait les paramètres pour minimiser une norme.

  Exemples :
     kp = ureal('kp', 1, 'Range', [0 10]);
     C = genss(ss(0, 1, kp, 0));
     pole(usubs(C, 'kp', 5))

  Voir aussi USS, GENMAT, UREAL, HINFSTRUCT, USUBS.
```

## `getNominal`

```
GETNOMINAL Valeur nominale d'un objet incertain.
  N = GETNOMINAL(U) rend ce que U vaut quand chaque paramètre prend sa
  valeur nominale : une matrice pour un UMAT, un modèle SS pour un USS,
  un nombre pour un UREAL.

  C'est la même chose que la propriété NominalValue ; GETNOMINAL existe
  pour qu'on puisse l'écrire en fonction, ce qui se compose mieux.

  Exemples :
     k = ureal('k', 10, 'Range', [8 12]);
     getNominal(k)                       % 10
     getNominal([1 k; 0 2])              % [1 10; 0 2]

     G = uss([0 1; -k -2], [0; 1], [1 0], 0);
     pole(getNominal(G))'

  Voir aussi UREAL, UMAT, USS, USUBS, USAMPLE, UNCERTAIN.
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

## `hinfstruct`

```
HINFSTRUCT Synthèse H-infini à correcteur structuré.
  [K,GAMMA] = HINFSTRUCT(P,K0) règle les paramètres libres du
  correcteur structuré K0 — un PID, un correcteur d'ordre fixé, un
  correcteur à gains partagés — pour minimiser la norme H-infini de la
  boucle fermée avec le modèle augmenté P.

  K0 décrit la structure et donne le point de départ. MatLibre
  l'accepte sous la forme d'un USS dont les paramètres incertains
  tiennent lieu de paramètres réglables : chacun est cherché dans son
  intervalle.

  [K,GAMMA,INFO] = HINFSTRUCT(...) rend en outre les valeurs trouvées.

  La recherche est celle du simplexe de Nelder et Mead sur les
  paramètres, la boucle étant évaluée à chaque essai. C'est plus lent
  que la méthode non lisse de MATLAB, et cela ne garantit pas
  l'optimum ; c'est en revanche exact sur ce qu'on mesure, et cela
  accepte n'importe quelle structure.

  L'intérêt de la synthèse structurée est qu'elle rend un correcteur
  qu'on peut mettre en œuvre : un PID à trois nombres plutôt qu'un
  correcteur d'ordre huit qu'il faudra réduire.

  Exemples :
     G = ss(tf(1, [1 1]));
     P = augw(G, tf(1, [1 0.1]), 0.1, []);
     kp = ureal('kp', 1, 'Range', [0 20]);
     ki = ureal('ki', 1, 'Range', [0 20]);
     K0 = uss(0, 1, ki, kp);            % un PI : kp + ki/s
     [K, gamma] = hinfstruct(P, K0);
     gamma

  Voir aussi HINFSYN, MIXSYN, DKSYN, PIDTUNE, USS, UREAL.
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

## `iconnect`

```
ICONNECT Assemblage d'un schéma par des équations (forme ancienne).
  M = ICONNECT crée un objet d'assemblage vide. On lui donne ensuite
  ses entrées, ses sorties et ses équations, puis M.System rend le
  modèle assemblé.

  Cette forme est celle des versions anciennes de la boîte à outils.
  MatLibre assemble les schémas par SYSIC — la forme que les scripts de
  synthèse H-infini emploient, où l'on nomme les blocs et l'on écrit
  les entrées de chacun — et par CONNECT, qui relie par les noms des
  voies. Ce sont ces deux-là qu'il faut employer ; ICONNECT existe pour
  que l'appel ne casse pas, et dit ce qu'il faut faire à la place.

  Exemples :
     % Ce qu'il faut ecrire a la place : CONNECT relie par les noms
     G = ss(tf(1, [1 1]));  G.InputName = 'u';  G.OutputName = 'y';
     K = ss(tf(2, 1));      K.InputName = 'e';  K.OutputName = 'u';
     S = sumblk('e = r - y');
     boucle = connect(G, K, S, 'r', 'y');
     abs(dcgain(boucle) - 2/3) < 1e-9

  Voir aussi SYSIC, CONNECT, SUMBLK, APPEND, ICSIGNAL.
```

## `icsignal`

```
ICSIGNAL Signal nommé pour l'assemblage d'un schéma.
  S = ICSIGNAL(N) crée un signal de N voies, nommé automatiquement.
  S = ICSIGNAL(N,'nom') le nomme.

  Les signaux d'ICSIGNAL servaient, dans les versions anciennes de la
  boîte à outils, à décrire un schéma-blocs par des équations, à l'aide
  d'ICONNECT. MatLibre assemble les schémas par SYSIC — la forme que le
  H-infini emploie — et par CONNECT, qui relie par les noms des voies.

  S porte les champs Name et Size ; on l'emploie avec ICONNECT.

  Exemples :
     e = icsignal(1, 'e');
     u = icsignal(1, 'u');
     e.Name

  Voir aussi ICONNECT, SYSIC, CONNECT, SUMBLK, APPEND.
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

## `ltiarray2uss`

```
LTIARRAY2USS Fait un modèle incertain d'une famille de modèles mesurés.
  [SYS,INFO] = LTIARRAY2USS(G0,MODELES) construit un modèle incertain
  qui couvre tous les modèles de la cellule MODELES, autour du modèle
  nominal G0 :

     SYS = G0 * (1 + W * delta)

  où delta est un bloc dynamique de norme au plus un et W une
  pondération dont le module majore, à chaque fréquence, l'erreur
  relative de tous les modèles.

  [SYS,INFO] = LTIARRAY2USS(G0,MODELES,N) donne à W l'ordre N ; le
  défaut est deux.

  INFO porte W, la pondération trouvée, et Bound, l'erreur relative
  mesurée à chaque fréquence.

  C'est ainsi qu'on passe de mesures à un modèle incertain : on
  identifie plusieurs modèles dans plusieurs conditions, on en choisit
  un pour nominal, et cette fonction dit ce que l'incertitude doit
  couvrir.

  Exemples :
     G0 = ss(tf(1, [1 1]));
     famille = {ss(tf(1, [1 0.8])), ss(tf(1.2, [1 1.3])), ss(tf(0.9, [1 1]))};
     [Gi, info] = ltiarray2uss(G0, famille);
     bodemag(info.W);

  Voir aussi ULTIDYN, MAKEWEIGHT, USS, WCGAIN, UCOMPLEX.
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

## `matlibre_atome`

```
MATLIBRE_ATOME Un paramètre incertain d'un genre quelconque, en UMAT.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  UCOMPLEX, ULTIDYN et UDYN s'en servent : leurs paramètres ne sont pas
  des réels, mais ils vivent dans le même UMAT, avec un champ « Kind »
  qui dit comment les tirer et comment les borner.
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

## `matlibre_balayer_incertitude`

```
MATLIBRE_BALAYER_INCERTITUDE Cherche le pire cas dans le domaine des paramètres.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  WCGAIN, ROBSTAB et leurs voisines s'en servent. La recherche se fait
  en trois temps :

    1. les sommets du pavé — pour une dépendance monotone, le pire cas
       y est, et c'est le cas le plus fréquent ;
    2. des tirages au hasard, qui attrapent ce qui n'est pas monotone ;
    3. une descente locale coordonnée par coordonnée depuis le meilleur
       point trouvé, qui affine.

  Le résultat est donc une borne inférieure du pire cas, exacte pour
  une dépendance monotone. MATLAB, qui garde la forme LFT, calcule à la
  place une borne supérieure par mu ; les deux encadrent la vérité par
  des côtés opposés.

  OPTIONS.Tirages fixe le nombre de tirages, OPTIONS.Rayon multiplie
  l'étendue de chaque paramètre — c'est ce dont ROBSTAB se sert pour
  chercher le rayon de robustesse.
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

## `matlibre_bornes_atome`

```
MATLIBRE_BORNES_ATOME La valeur nominale et les deux bornes d'un paramètre.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Elle accepte un UREAL, la structure interne d'un paramètre d'UMAT, ou
  un UMAT qui n'a qu'un paramètre — ce que rend une expression comme
  « k » passée telle quelle.
```

## `matlibre_cout_structure`

```
MATLIBRE_COUT_STRUCTURE La norme de la boucle pour un jeu de paramètres.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  HINFSTRUCT s'en sert. Un point hors des bornes est ramené dedans et
  pénalisé, ce qui laisse le simplexe travailler sans contrainte
  explicite ; une boucle instable rend un très grand nombre fini, pour
  que la comparaison reste possible.
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

## `matlibre_gain_ou_zero`

```
MATLIBRE_GAIN_OU_ZERO La norme H-infini, l'infini devenant un grand nombre.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  La recherche du pire cas compare des gains ; un modèle instable en a
  un infini, et l'infini ne se compare pas à l'infini. On le remplace
  par un très grand nombre fini, ce qui laisse la comparaison décider
  et fait ressortir l'instabilité comme le pire des cas.
```

## `matlibre_incertitudes`

```
MATLIBRE_INCERTITUDES La liste des paramètres et la fonction d'évaluation.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  USUBS, USAMPLE, WCGAIN et ROBSTAB acceptent indifféremment un UREAL,
  un UMAT, un USS ou un objet certain ; cette fonction ramène les
  quatre cas à la même paire.
```

## `matlibre_marge_disque`

```
MATLIBRE_MARGE_DISQUE La marge de disque d'une boucle.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  WCDISKMARGIN s'en sert. Une boucle instable donne une marge nulle,
  ce qui la désigne comme le pire des cas.
```

## `matlibre_mettre_a_echelle`

```
MATLIBRE_METTRE_A_ECHELLE Le modèle augmenté, mis à l'échelle par D.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  DKSYN s'en sert à l'étape K : on multiplie les sorties régulées par D
  et les entrées exogènes par son inverse, ce qui laisse la boucle
  inchangée et change le critère que HINFSYN minimise.
```

## `matlibre_mu_boucle`

```
MATLIBRE_MU_BOUCLE La borne haute de mu d'une boucle, et sa mise à l'échelle.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  DKSYN s'en sert à l'étape D. La borne est cherchée sur une grille de
  fréquences ; c'est le maximum sur cette grille qu'on rend, avec la
  mise à l'échelle du point le pire.
```

## `matlibre_pic_sensibilite`

```
MATLIBRE_PIC_SENSIBILITE Le pic d'une des transmittances d'une boucle.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  WCSENS s'en sert. Une boucle instable rend un très grand nombre fini
  plutôt que l'infini, pour que la recherche du pire cas puisse
  comparer.
```

## `matlibre_pire_gain_sur_pave`

```
MATLIBRE_PIRE_GAIN_SUR_PAVE Le pire gain sur le pavé dilaté d'un rayon donné.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  ROBGAIN s'en sert à chaque essai de sa dichotomie.
```

## `matlibre_pire_pole`

```
MATLIBRE_PIRE_POLE La plus grande partie réelle des pôles, ou son équivalent discret.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  ROBSTAB s'en sert : la stabilité se lit sur ce seul nombre, négatif
  pour un modèle stable, quelle que soit sa taille. En discret, on rend
  le logarithme du plus grand module, qui a le même signe.
```

## `matlibre_pire_pole_sur_pave`

```
MATLIBRE_PIRE_POLE_SUR_PAVE Le pire pôle sur le pavé dilaté d'un rayon donné.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  ROBSTAB s'en sert à chaque essai de sa dichotomie.
```

## `matlibre_point_vers_valeurs`

```
MATLIBRE_POINT_VERS_VALEURS Un vecteur de coordonnées, en structure nommée.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  Le balayage travaille sur des vecteurs, l'évaluation sur des noms ;
  cette fonction fait le passage.
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

## `matlibre_tirer_atome`

```
MATLIBRE_TIRER_ATOME Une valeur au hasard d'un paramètre incertain.
  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
  USAMPLE, WCGAIN et ROBSTAB s'en servent ; chaque genre de paramètre a
  sa loi de tirage.
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

## `musyn`

```
MUSYN Synthèse mu.
  [K,CL,MU] = MUSYN(P,NMES,NCOM) fait ce que fait DKSYN : il cherche le
  correcteur qui minimise la valeur singulière structurée de la boucle.
  C'est le nom que MATLAB donne à cette synthèse depuis R2018b ;
  MatLibre garde les deux.

  MUSYN(...,OPTIONS) accepte les mêmes options que DKSYN.

  Exemples :
     G = ss(tf(1, [1 1]));
     P = augw(G, tf(1, [1 0.1]), 0.1, []);
     [K, CL, mu] = musyn(P, 1, 1);

  Voir aussi DKSYN, MUSSV, HINFSYN, ROBSTAB, WCGAIN.
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

## `normalized2actual`

```
NORMALIZED2ACTUAL Passe de la valeur normalisée d'un paramètre à sa valeur réelle.
  V = NORMALIZED2ACTUAL(P,N) fait l'inverse d'ACTUAL2NORMALIZED : elle
  rend la valeur réelle du paramètre P qui correspond à la valeur
  normalisée N. Zéro donne le nominal, un la borne haute, moins un la
  borne basse.

  N peut être un tableau ; V a la même taille.

  Exemples :
     p = ureal('p', 10, 'Range', [8 15]);
     normalized2actual(p, 0)            % 10
     normalized2actual(p, 1)            % 15
     normalized2actual(p, -1)           % 8
     normalized2actual(p, actual2normalized(p, 12))    % 12

  Voir aussi ACTUAL2NORMALIZED, UREAL, ROBSTAB, WCGAIN.
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

## `randatom`

```
RANDATOM Paramètre incertain tiré au hasard.
  A = RANDATOM crée un paramètre réel incertain de nom, de valeur
  nominale et de bornes tirés au hasard. C'est ce qui sert à éprouver
  une fonction d'analyse : on lui donne des objets qu'on n'a pas
  choisis.

  A = RANDATOM('ureal'), RANDATOM('ucomplex') et RANDATOM('ultidyn')
  choisissent le genre.
  A = RANDATOM(GENRE,[N M]) fixe la taille, pour les genres qui en ont
  une.

  Exemples :
     a = randatom
     b = randatom('ucomplex')
     c = randatom('ultidyn', [2 2]);

  Voir aussi RANDUMAT, RANDUSS, UREAL, UCOMPLEX, ULTIDYN, RSS.
```

## `randumat`

```
RANDUMAT Matrice incertaine tirée au hasard.
  M = RANDUMAT(N) crée une matrice incertaine N x N.
  M = RANDUMAT(N,M) la crée N x M.
  M = RANDUMAT(N,M,P) emploie P paramètres incertains ; deux par
  défaut.

  Chaque entrée est une combinaison affine des paramètres, à
  coefficients tirés au hasard. C'est de quoi éprouver WCNORM ou MUSSV
  sur des objets qu'on n'a pas choisis.

  Exemples :
     M = randumat(2)
     wcnorm(M)
     usample(M)

  Voir aussi RANDATOM, RANDUSS, UMAT, WCNORM, UREAL.
```

## `randuss`

```
RANDUSS Modèle d'état incertain tiré au hasard.
  SYS = RANDUSS(N) crée un modèle incertain stable d'ordre N, à une
  entrée et une sortie.
  SYS = RANDUSS(N,P,M) lui donne P sorties et M entrées.
  SYS = RANDUSS(N,P,M,Q) emploie Q paramètres incertains ; un par
  défaut.

  Le modèle nominal est celui que rend RSS : stable, d'ordre N.
  L'incertitude porte sur la matrice d'état, ce qui déplace les pôles
  sans changer la structure.

  Exemples :
     G = randuss(3);
     pole(getNominal(G))'
     robstab(G)
     usample(G, 5);

  Voir aussi RANDATOM, RANDUMAT, RSS, USS, ROBSTAB, WCGAIN.
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

## `robgain`

```
ROBGAIN Marge de performance robuste.
  [R,V] = ROBGAIN(SYS,GMAX) cherche de combien on peut dilater le
  domaine des paramètres avant que la norme H-infini de SYS ne dépasse
  GMAX. R porte LowerBound et UpperBound ; V donne les valeurs qui
  font franchir la borne.

  Là où ROBSTAB demande que la boucle reste stable, ROBGAIN demande
  qu'elle reste performante : c'est la question qu'on se pose quand la
  stabilité ne fait pas de doute mais que le gain, lui, peut se
  dégrader.

  Un rayon supérieur à un dit que la performance tient sur tout le
  domaine déclaré.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     z = ureal('z', 0.2, 'Range', [0.05 0.4]);
     G = uss([0 1; -k -z], [0; 1], [1 0], 0);
     wcgain(G).LowerBound              % le pire gain sur le domaine
     robgain(G, 15)                    % tient-il sous 15 ?

  Voir aussi ROBSTAB, WCGAIN, WCSENS, MUSSV.
```

## `robstab`

```
ROBSTAB Marge de stabilité robuste d'un modèle incertain.
  [R,V] = ROBSTAB(SYS) cherche de combien on peut dilater le domaine
  des paramètres avant que SYS cesse d'être stable. R porte :
     LowerBound   le rayon de robustesse trouvé ;
     UpperBound   le même ;
     DestabilizingFrequency  la pulsation du mode qui devient instable.
  V est la structure des valeurs de paramètres qui déstabilisent, quand
  il y en a.

  Un rayon supérieur à un veut dire que le modèle reste stable sur tout
  le domaine déclaré, avec de la marge : R = 2.3 dit qu'il faudrait
  2.3 fois l'écart déclaré pour le mettre en défaut. Un rayon inférieur
  à un dit qu'une combinaison du domaine déstabilise déjà.

  [R,V,INFO] = ROBSTAB(SYS) rend en outre le pire pôle rencontré.

  Le rayon est cherché par dichotomie : à chaque essai, on dilate le
  pavé des paramètres et l'on cherche, par la méthode de WCGAIN, s'il
  contient un point instable. Voir WCGAIN pour ce que cette recherche
  garantit.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     z = ureal('z', 0.2, 'Range', [0.05 0.4]);
     G = uss([0 1; -k -z], [0; 1], [1 0], 0);
     r = robstab(G);
     r.LowerBound                   % grand : rien ne destabilise

     % Un amortissement qui peut devenir negatif
     z2 = ureal('z', 0.2, 'Range', [-0.1 0.5]);
     robstab(uss([0 1; -4 -z2], [0; 1], [1 0], 0))

  Voir aussi WCGAIN, ROBGAIN, USAMPLE, MUSSV, LOOPMARGIN, USS.
```

## `robuststab`

```
ROBUSTSTAB Marge de stabilité robuste (nom historique).
  [R,V] = ROBUSTSTAB(SYS) fait ce que fait ROBSTAB. C'est le nom que la
  fonction portait avant R2016a ; MATLAB le garde pour les programmes
  anciens, et MatLibre aussi.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     robuststab(G)

  Voir aussi ROBSTAB, WCGAIN, ROBGAIN, MUSSV.
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

## `sisobnds`

```
SISOBNDS Bornes de robustesse dans le plan du correcteur.
  B = SISOBNDS(TYPE,G,SPEC,W) rend, pour chaque pulsation de W, la
  contrainte que le correcteur doit respecter pour tenir la
  spécification SPEC sur le procédé G. C'est l'outil du réglage
  quantitatif : on trace ces bornes dans le plan de Nichols, puis on
  façonne la boucle pour passer au-dessus.

  TYPE choisit la spécification :
     1  stabilité robuste : |T| sous SPEC ;
     2  performance : |S| sous SPEC ;
     3  rejet de perturbation en entrée : |G*S| sous SPEC ;
     7  suivi de consigne : |T| entre deux bornes.

  B porte, par pulsation, le gain de boucle minimal qui satisfait la
  contrainte : |L| >= B, ce qui se lit directement sur un diagramme de
  Bode.

  MatLibre rend la borne sur le module de la boucle ouverte, non le
  contour complet dans le plan de Nichols que trace la boîte à outils
  QFT de MATLAB : c'est ce qui suffit à façonner une boucle, et cela ne
  demande pas le balayage en phase.

  Exemples :
     G = ss(tf(1, [1 1]));
     w = logspace(-1, 2, 20);
     b = sisobnds(2, G, 0.1, w);       % erreur sous 10 %
     loglog(w, b);                      % le gain de boucle minimal

  Voir aussi LOOPSYN, MIXSYN, MAKEWEIGHT, NICHOLS, LOOPMARGIN.
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

## `ucomplex`

```
UCOMPLEX Paramètre complexe incertain.
  P = UCOMPLEX('nom',NOMINAL) crée un paramètre complexe qui peut
  s'écarter de NOMINAL d'un rayon égal au dixième de son module.

  P = UCOMPLEX('nom',NOMINAL,'Radius',R) donne le rayon en clair.
  P = UCOMPLEX('nom',NOMINAL,'Percentage',P) le donne en pour cent du
  module de la valeur nominale.

  Un paramètre complexe couvre à la fois une erreur de gain et une
  erreur de phase : c'est la façon la plus économique de représenter ce
  qu'on ne connaît pas d'un transfert à une fréquence donnée. Il est
  moins fidèle qu'un paramètre réel — il autorise des combinaisons que
  la physique n'autorise pas — mais l'analyse en est bien plus simple,
  et c'est cette simplicité qui a fait la théorie du mu.

  USAMPLE le tire uniformément dans son disque.

  Exemples :
     d = ucomplex('d', 1, 'Radius', 0.3);
     abs(usample(d) - 1) <= 0.3         % le tirage reste dans le disque
     getNominal(d)                      % 1

     % Une incertitude multiplicative sur un gain
     gainIncertain = d * 2;
     getNominal(gainIncertain)

  Voir aussi UREAL, UCOMPLEXM, ULTIDYN, UMAT, USS, USAMPLE.
```

## `ucomplexm`

```
UCOMPLEXM Matrice complexe incertaine.
  M = UCOMPLEXM('nom',NOMINAL) crée une matrice complexe incertaine
  dont la valeur nominale est NOMINAL et qui peut s'en écarter, en
  norme, du dixième de la norme de NOMINAL.

  M = UCOMPLEXM('nom',NOMINAL,'Radius',R) donne le rayon en clair.

  C'est l'équivalent matriciel d'UCOMPLEX : une matrice pleine dont on
  ne connaît que l'ordre de grandeur de l'erreur. Elle correspond au
  bloc plein complexe de l'analyse mu, celui pour lequel mu vaut
  exactement la plus grande valeur singulière.

  Exemples :
     D = ucomplexm('D', eye(2), 'Radius', 0.2);
     size(D)
     usample(D)

  Voir aussi UCOMPLEX, UREAL, ULTIDYN, UMAT, MUSSV.
```

## `udyn`

```
UDYN Bloc incertain non modélisé.
  D = UDYN('nom',[N M]) crée un bloc incertain de taille N x M dont on
  ne dit rien : ni réel, ni complexe, ni borné. Il sert de repère dans
  un schéma que l'on veut analyser sans avoir encore décidé ce que le
  bloc représente.

  MatLibre le traite comme un ULTIDYN de borne un, ce qui lui donne un
  comportement défini quand on l'échantillonne ou qu'on l'analyse.
  MATLAB, lui, refuse toute analyse tant que le bloc n'est pas remplacé.

  Exemples :
     d = udyn('d', [1 1]);
     usample(d)

  Voir aussi ULTIDYN, UREAL, UCOMPLEX, USS.
```

## `ultidyn`

```
ULTIDYN Bloc dynamique incertain.
  D = ULTIDYN('nom',[N M]) crée un bloc dynamique incertain de taille
  N x M et de norme H-infini au plus égale à un : n'importe quel
  modèle stable de ce gain.

  D = ULTIDYN('nom',[N M],'Bound',B) fixe la borne à B.
  D = ULTIDYN('nom',[N M],'Type','GainBounded') est le défaut ;
  'PositiveReal' demande un bloc à partie réelle positive.

  C'est la façon de dire « je ne connais pas la dynamique au-delà de
  telle fréquence, mais je sais qu'elle ne dépasse pas tel gain ». Un
  modèle réduit s'écrit ainsi : le vrai procédé est le modèle réduit
  plus un bloc dynamique pondéré par la borne d'erreur que la
  réduction garantit.

  USAMPLE le tire comme un modèle du premier ordre de gain au plus égal
  à sa borne, de pôle réparti sur quelques décades.

  Exemples :
     d = ultidyn('d', [1 1], 'Bound', 0.3);
     hinfnorm(usample(d)) <= 0.3

     % Un procede connu a 30 % pres en haute frequence. Le bloc vient
     % en premier : c'est lui qui porte l'incertitude, et c'est son
     % arithmetique qu'il faut.
     G = ss(tf(1, [1 1]));
     W = makeweight(0.05, 10, 2);
     Gi = (d * ss(W) + 1) * G;
     hinfnorm(getNominal(Gi) - G) < 1e-9

  Voir aussi UREAL, UCOMPLEX, UDYN, USAMPLE, BALANCMR, MAKEWEIGHT.
```

## `umat`

```
UMAT Matrice incertaine.
  Un UMAT est une matrice dont les entrées dépendent de paramètres
  incertains. On ne le construit presque jamais à la main : il naît de
  l'arithmétique sur des UREAL, des UCOMPLEX ou des UMAT.

     m = ureal('m', 1200, 'Percentage', 10);
     c = ureal('c', 4000, 'Percentage', 20);
     M = [0 1; -1/m -c/m]          % un umat 2 x 2

  M = UMAT(X) fait d'une matrice ordinaire un UMAT sans paramètre ; il
  se comporte alors comme la matrice elle-même.

  Les propriétés :
     NominalValue   la valeur quand chaque paramètre vaut son nominal ;
     Uncertainty    la liste des paramètres dont il dépend ;
     Names          leurs noms.

  Les opérations + - * / ^ sont définies, ainsi que la concaténation
  entre crochets, la transposition, INV, SQRT et ABS. Le résultat garde
  la trace de tous les paramètres en jeu.

  USUBS fixe un paramètre, USAMPLE en tire au hasard, GETNOMINAL rend
  la valeur nominale.

  MatLibre garde la dépendance sous forme de fonction des paramètres,
  non sous forme de transformation fractionnaire linéaire : c'est ce
  qui lui permet d'accepter une division ou une racine, que la forme
  LFT ne représente qu'au prix d'un développement. Voir UREAL pour ce
  que cela coûte et ce que cela rapporte.

  Exemples :
     k = ureal('k', 10, 'Range', [8 12]);
     A = [0 1; -k -2];
     A.NominalValue
     usubs(A, 'k', 12)
     usample(A, 3)

  Voir aussi UREAL, USS, USUBS, USAMPLE, GETNOMINAL, WCGAIN, ROBSTAB.
```

## `uncertain`

```
UNCERTAIN L'objet porte-t-il de l'incertitude ?
  B = UNCERTAIN(U) rend vrai si U dépend d'au moins un paramètre
  incertain, faux sinon. Un UMAT ou un USS bâti sur des nombres
  ordinaires est certain, quoique de classe incertaine : c'est ce que
  cette fonction permet de distinguer.

  Exemples :
     k = ureal('k', 4);
     uncertain(k)                       % vrai
     uncertain(umat([1 2; 3 4]))        % faux
     uncertain(ss(-1, 1, 1, 0))         % faux

  Voir aussi UREAL, UMAT, USS, GETNOMINAL, USUBS.
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

## `ureal`

```
UREAL Paramètre réel incertain.
  P = UREAL('nom',NOMINAL) crée un paramètre réel dont la valeur
  nominale est NOMINAL et qui peut s'en écarter de 10 pour cent.

  P = UREAL('nom',NOMINAL,'Range',[BAS HAUT]) donne les bornes en
  clair.
  P = UREAL('nom',NOMINAL,'Percentage',[-A B]) les donne en pour cent
  de la valeur nominale ; un seul nombre vaut pour les deux côtés.
  P = UREAL('nom',NOMINAL,'PlusMinus',[-A B]) les donne en écart
  absolu.

  Un paramètre incertain s'emploie comme un nombre : il s'ajoute, se
  multiplie, se divise. Le résultat est un UMAT — une matrice
  incertaine — qui garde la trace de ce dont il dépend.

     m = ureal('m', 1200, 'Percentage', 10);
     k = ureal('k', 5e4, 'Range', [4e4 6e4]);
     pulsation = sqrt(k / m);          % un umat, fonction de m et de k
     pulsation.NominalValue            % 6.455

  Les propriétés :
     Name           le nom, par lequel USUBS le retrouve ;
     NominalValue   la valeur nominale ;
     Range          les deux bornes ;
     Mode           'Range', 'Percentage' ou 'PlusMinus'.

  MATLAB représente une incertitude par une transformation
  fractionnaire linéaire, ce qui permet une analyse mu exacte. MatLibre
  la représente par la dépendance elle-même — la fonction des
  paramètres —, ce qui vaut pour n'importe quelle dépendance, y
  compris une division, et ce que les fonctions d'analyse exploitent
  en balayant le domaine des paramètres. Ce qui manque est l'analyse mu
  exacte ; ce qu'on gagne est de pouvoir écrire le modèle tel qu'il
  vient.

  Exemples :
     p = ureal('p', 2)
     p.Range                            % [1.8 2.2]
     usample(p, 5)                      % cinq tirages dans l'intervalle
     usubs(p, 'p', 2.1)                 % 2.1

  Voir aussi UMAT, USS, USAMPLE, USUBS, UCOMPLEX, ULTIDYN, WCGAIN.
```

## `usample`

```
USAMPLE Tire au hasard des valeurs des paramètres incertains.
  [S,V] = USAMPLE(U) tire une valeur de chaque paramètre, uniformément
  dans son intervalle, et rend l'objet obtenu ainsi que la structure
  des valeurs tirées.

  [S,V] = USAMPLE(U,N) fait N tirages. S est alors un tableau de
  cellules de N objets, V un tableau de structures de N éléments.

  C'est le moyen le plus direct de voir ce que l'incertitude fait : on
  trace vingt réponses tirées au hasard, et l'on voit d'un coup si le
  nuage reste acceptable.

  Un paramètre complexe — UCOMPLEX — est tiré uniformément dans son
  disque ; un bloc dynamique — ULTIDYN — est tiré comme un modèle du
  premier ordre de gain au plus égal à sa borne.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     [modeles, tirages] = usample(G, 20);
     hold on
     for j = 1:20, bode(modeles{j}); end
     hold off

     usample(k, 5)

  Voir aussi USUBS, GETNOMINAL, WCGAIN, ROBSTAB, UREAL, USS.
```

## `uss`

```
USS Modèle d'état incertain.
  SYS = USS(A,B,C,D) crée un modèle d'état dont les matrices peuvent
  dépendre de paramètres incertains — des UREAL, ou des UMAT bâtis sur
  eux.

  SYS = USS(A,B,C,D,TS) crée un modèle échantillonné.
  SYS = USS(SYS) fait d'un modèle certain un modèle incertain sans
  paramètre.

  Les propriétés :
     NominalValue   le modèle SS obtenu en donnant à chaque paramètre
                    sa valeur nominale ;
     Uncertainty    la liste des paramètres ;
     Names          leurs noms ;
     A, B, C, D     les quatre matrices, incertaines.

  Les opérations + - * , la concaténation, INV, FEEDBACK et LFT sont
  définies : on assemble une boucle incertaine comme on assemble une
  boucle ordinaire.

  USUBS fixe des paramètres et rend un SS ; USAMPLE en tire au hasard ;
  les fonctions WCGAIN, ROBSTAB et WCSENS balaient le domaine.

  Exemples :
     m = ureal('m', 1, 'Percentage', 20);
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k/m -0.2/m], [0; 1/m], [1 0], 0);
     pole(G.NominalValue)'
     bode(usubs(G, 'm', 1.2, 'k', 5));
     wcgain(G)

  Voir aussi UREAL, UMAT, USUBS, USAMPLE, WCGAIN, ROBSTAB, USSDATA.
```

## `ussdata`

```
USSDATA Les matrices d'un modèle incertain.
  [A,B,C,D] = USSDATA(SYS) rend les quatre matrices du modèle, sous
  forme d'UMAT : chacune garde la trace des paramètres dont elle
  dépend.

  [A,B,C,D,TS] = USSDATA(SYS) rend en outre la période
  d'échantillonnage.
  [A,B,C,D,TS,P] = USSDATA(SYS) rend la liste des paramètres.

  C'est le pendant de SSDATA pour un modèle incertain.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     [A, B, C, D] = ussdata(G);
     getNominal(A)
     usubs(A, 'k', 5)

  Voir aussi SSDATA, USS, UMAT, GETNOMINAL, USUBS.
```

## `usubs`

```
USUBS Fixe des paramètres incertains.
  R = USUBS(U,'nom',VALEUR,...) remplace les paramètres nommés par les
  valeurs données. Les paramètres non nommés gardent leur valeur
  nominale, si bien que le résultat est toujours un objet certain :
  une matrice pour un UMAT, un modèle SS pour un USS.

  R = USUBS(U,STRUCTURE) prend les valeurs dans les champs d'une
  structure — celle que rend USAMPLE, par exemple.

  R = USUBS(U,'nominal') donne à tous leur valeur nominale, comme
  GETNOMINAL.

  Une valeur hors des bornes du paramètre est acceptée : USUBS ne
  juge pas, il substitue. C'est ce qui permet de regarder ce que
  deviendrait le modèle un peu au-delà de ce qu'on a déclaré.

  Exemples :
     m = ureal('m', 1, 'Percentage', 20);
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k/m -0.2/m], [0; 1/m], [1 0], 0);
     pole(usubs(G, 'k', 5, 'm', 0.8))'
     bode(usubs(G, 'k', 3));

     [~, tirage] = usample(G);
     usubs(G, tirage)

  Voir aussi USAMPLE, GETNOMINAL, UREAL, UMAT, USS, WCGAIN.
```

## `wcdiskmargin`

```
WCDISKMARGIN Pires marges de disque d'une boucle incertaine.
  [EM,SM,BM] = WCDISKMARGIN(G,K) cherche, dans le domaine des
  paramètres du procédé incertain G, la combinaison qui dégrade le plus
  les marges de la boucle. Les trois structures ont la même forme que
  celles de LOOPMARGIN, avec en plus le champ Values, qui donne les
  valeurs de paramètres du pire cas.

  La marge de disque mesure ce que la boucle supporte en gain et en
  phase à la fois. Sa version pire cas répond à la question qui compte
  vraiment : combien de marge reste-t-il quand le procédé n'est pas
  celui qu'on croit ?

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     C = ss(tf([10 10], [1 0]));
     [em, sm, bm] = wcdiskmargin(G, C);
     bm.DiskMargin
     bm.Values.k

  Voir aussi LOOPMARGIN, WCSENS, WCGAIN, ROBSTAB, NCFMARGIN.
```

## `wcgain`

```
WCGAIN Pire gain d'un modèle incertain.
  [G,V] = WCGAIN(SYS) cherche, dans le domaine des paramètres, la
  combinaison qui donne à SYS la plus grande norme H-infini. G porte
  trois champs :
     LowerBound   le pire gain trouvé ;
     UpperBound   le même, MatLibre ne calculant pas de majorant ;
     CriticalFrequency  la pulsation où il est atteint.
  V est la structure des valeurs de paramètres qui le donnent.

  [G,V,INFO] = WCGAIN(SYS) rend en outre le gain nominal et le rapport
  entre le pire et le nominal — la dégradation que l'incertitude
  coûte.

  WCGAIN(SYS,OPTIONS) accepte une structure portant Tirages, le nombre
  de tirages au hasard.

  La recherche essaie tous les sommets du pavé des paramètres, puis des
  tirages, puis affine par une descente locale. Pour une dépendance
  monotone — le cas ordinaire —, le pire cas est à un sommet et la
  valeur rendue est exacte. Sinon, elle minore le pire cas : MatLibre
  le dit plutôt que d'annoncer une garantie qu'il n'a pas. MATLAB, qui
  garde la forme LFT, calcule au contraire un majorant par mu.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     z = ureal('z', 0.2, 'Range', [0.05 0.4]);
     G = uss([0 1; -k -z], [0; 1], [1 0], 0);
     [g, v] = wcgain(G);
     g.LowerBound                   % le pire gain
     v.z                            % 0.05 : le moins amorti

  Voir aussi ROBSTAB, WCNORM, WCSENS, USAMPLE, HINFNORM, USS.
```

## `wcgopt`

```
WCGOPT Options des fonctions de pire cas.
  O = WCGOPT crée la structure d'options que prennent WCGAIN, ROBSTAB,
  ROBGAIN et leurs voisines, avec les valeurs par défaut.

  O = WCGOPT('nom',valeur,...) fixe les options nommées :
     Tirages       le nombre de tirages au hasard, 200 par défaut ;
     Rayon         le facteur de dilatation du domaine, un par défaut ;
     VaryFrequency accepté et sans effet.

  Augmenter le nombre de tirages coûte du temps et resserre la borne
  quand la dépendance n'est pas monotone. Pour une dépendance monotone,
  les sommets suffisent et les tirages n'apportent rien.

  Exemples :
     options = wcgopt('Tirages', 2000);
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     wcgain(G, options)

  Voir aussi WCGAIN, ROBSTAB, ROBGAIN, WCSENS, WCDISKMARGIN.
```

## `wcnorm`

```
WCNORM Pire norme d'une matrice incertaine.
  [N,V] = WCNORM(M) cherche, dans le domaine des paramètres, la
  combinaison qui donne à la matrice incertaine M la plus grande norme
  spectrale. N porte LowerBound et UpperBound ; V est la structure des
  valeurs qui la donnent.

  Pour un modèle, c'est WCGAIN qu'il faut : il cherche la norme
  H-infini, non la norme d'une matrice constante.

  La recherche est celle de WCGAIN : sommets, tirages, puis descente
  locale. Voir WCGAIN pour ce que cela garantit.

  Exemples :
     a = ureal('a', 1, 'Range', [0 2]);
     b = ureal('b', 1, 'Range', [-1 1]);
     M = [a b; 0 a];
     [n, v] = wcnorm(M);
     n.LowerBound
     [v.a, v.b]

  Voir aussi WCGAIN, ROBSTAB, USAMPLE, NORM, UMAT.
```

## `wcsens`

```
WCSENS Pires sensibilités d'une boucle incertaine.
  [S,V] = WCSENS(G,K) cherche, dans le domaine des paramètres, ce qui
  dégrade le plus chacune des sensibilités de la boucle formée du
  procédé incertain G et du correcteur K. S porte un champ par
  transmittance — So, Si, To, Ti, PSi, CSo —, chacun donnant le pire
  pic et les valeurs de paramètres qui le donnent, plus un champ
  Stable qui dit si la boucle tient sur tout le domaine.

  C'est le tableau de bord de la robustesse : un pic de sensibilité qui
  double sur le domaine des paramètres se voit d'un coup d'œil, et l'on
  sait quel paramètre le cause.

  [S,V,INFO] = WCSENS(G,K) rend en outre les pics nominaux, pour
  comparer.

  La recherche est celle de WCGAIN ; voir cette fonction pour ce
  qu'elle garantit.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     C = ss(tf([10 10], [1 0]));
     s = wcsens(G, C);
     s.So.PeakGain
     s.Stable

  Voir aussi WCGAIN, ROBSTAB, LOOPSENS, WCDISKMARGIN, USS.
```

## `wcunc`

```
WCUNC Les valeurs de paramètres du pire cas.
  V = WCUNC(INFO) extrait, du rapport que rend WCGAIN, ROBSTAB ou
  ROBGAIN, la structure des valeurs de paramètres qui donnent le pire
  cas. Elle se passe ensuite à USUBS pour construire le modèle
  correspondant.

  Exemples :
     k = ureal('k', 4, 'Range', [3 5]);
     G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
     [~, ~, info] = wcgain(G);
     % le second argument de WCGAIN donne deja ces valeurs :
     [g, v] = wcgain(G);
     bode(usubs(G, v));

  Voir aussi WCGAIN, ROBSTAB, ROBGAIN, USUBS, USAMPLE.
```

