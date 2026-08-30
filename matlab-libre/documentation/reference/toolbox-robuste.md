# Toolbox `robuste`

```
% Robust Control Toolbox — analyse de robustesse.
%
%   hinfnorm     - Norme H-infini d'un modèle
%   hinfsyn      - Correcteur H-infini d'un modèle augmenté
%   mixsyn       - Synthèse H-infini par sensibilité mixte
%   augw         - Modèle augmenté d'un problème de sensibilité mixte
%   h2norm       - Norme H2
%   sigmaValues  - Valeurs singulières en fréquence
%   stabilityMargin - Marges de module et de retard
%   uncertainGain   - Balayage d'un gain incertain
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

## `h2norm`

```
H2NORM Norme H2 d'un modèle stable.
  N = H2NORM(SYS) rend la racine de l'intégrale du carré du module de
  la réponse fréquentielle, divisée par pi : c'est l'énergie de la
  réponse impulsionnelle, et l'écart-type de la sortie quand l'entrée
  est un bruit blanc de variance unité.

  Un modèle instable, ou dont la transmittance ne tend pas vers zéro,
  n'a pas de norme H2 finie.

  Exemples :
     abs(h2norm(tf(1, [1 1])) - sqrt(0.5)) < 1e-3    % la valeur exacte
     h2norm(tf(1, [1 0.1 1])) > h2norm(tf(1, [1 2 1]))   % le peu amorti en a plus

  Voir aussi HINFNORM, SIGMA, COVAR, GRAM.
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
  suite converge par le haut, en quelques tours.

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
  rang plein en lignes. D22 non nul est ramené à zéro par décalage de
  boucle, puis rendu au correcteur. D11 non nul n'est pas traité : les
  pondérations d'un problème bien posé le laissent nul.

  Exemple :
     G = tf(200, [10 1]) * tf(1, [0.05 1])^2;
     P = augw(G, tf(10, [1 0.1]), 0.1, []);
     [K, CL, gam] = hinfsyn(P, 1, 1);

  Voir aussi AUGW, MIXSYN, LFT, HINFNORM, H2SYN.
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

