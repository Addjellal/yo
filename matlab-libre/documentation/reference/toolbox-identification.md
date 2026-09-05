# Toolbox `identification`

```
% System Identification Toolbox — identification de modèles.
%
% Identifier, c'est trouver le modèle qui rend l'erreur de prédiction la
% plus petite. Les estimateurs de cette boîte à outils ne diffèrent que par
% la famille où ils cherchent et par la façon dont ils démarrent.
%
% Jeux de données
%   iddata          - Jeu de données entrée/sortie échantillonné
%   detrend         - Retrait d'une constante ou d'une droite
%   retrend         - Remise des tendances retirées
%   resample        - Rééchantillonnage d'un jeu de données
%   misdata         - Reconstruction des échantillons manquants
%   nkshift         - Décalage des entrées d'un nombre de périodes
%   merge           - Réunion de plusieurs expériences
%   getexp          - Extraction d'une expérience d'un jeu multiple
%   idinput         - Signaux d'excitation (SBPA, sinus, bruit, échelons)
%
% Modèles
%   idpoly          - Modèle polynomial A y = (B/F) u + (C/D) e
%   idss            - Modèle d'état estimé
%   idtf            - Modèle de fonction de transfert estimé
%   idproc          - Modèle de procédé (gain, constantes de temps, retard)
%   idfrd           - Réponse fréquentielle estimée
%
% Estimation polynomiale
%   arx             - ARX, par moindres carrés
%   ar              - Modèle autorégressif d'un signal seul
%   armax           - ARMAX, par régression pseudo-linéaire
%   oe              - Erreur de sortie
%   bj              - Box-Jenkins
%   polyest         - Famille polynomiale complète [na nb nc nd nf nk]
%   iv4             - Variables instrumentales à quatre étapes
%   pem             - Minimisation de l'erreur de prédiction, toutes familles
%
% Estimation d'état, de transfert et de procédé
%   n4sid           - Identification par sous-espaces
%   ssest           - Modèle d'état affiné par erreur de prédiction
%   tfest           - Fonction de transfert, discrète ou continue
%   procest         - Modèle de procédé de forme imposée
%   impulseest      - Réponse impulsionnelle estimée
%
% Analyse spectrale
%   spa             - Analyse spectrale par lissage de Blackman-Tukey
%   etfe            - Estimation empirique de la fonction de transfert
%
% Ce qu'on demande à un modèle estimé
%   sim             - Simulation de la sortie
%   predict         - Prédiction à k pas
%   forecast        - Prolongement au-delà des données
%   compare         - Superposition mesure/modèle et pour cent d'ajustement
%   resid           - Résidus et leurs corrélations, avec seuil de confiance
%   polydata        - Polynômes A, B, C, D, F d'un modèle
%   getpvec         - Vecteur des paramètres libres
%   setpvec         - Remplacement des paramètres libres
%   fpe             - Erreur finale de prédiction d'Akaike
%   aic             - Critère d'Akaike, ses variantes normalisée et BIC
%   advice          - Conseils tirés des données avant d'estimer
%   compareFit      - Qualité d'ajustement en pour cent
%   predictArx      - Prédiction à un pas d'un modèle ARX
```

## `advice`

```
ADVICE Examine des données avant de les identifier.
  ADVICE(Z) affiche ce que les données disent d'elles-mêmes : leur
  nombre, la présence d'une composante continue ou d'une dérive, le
  retard apparent entre l'entrée et la sortie, le rapport signal sur
  bruit apparent, et un ordre de modèle à essayer.

  RAPPORT = ADVICE(Z) rend ces constats dans une structure au lieu de
  les afficher.

  Le conseil le plus utile est le premier : une composante continue non
  retirée oblige le modèle à la représenter par des paramètres qui ne
  décrivent aucune dynamique, et fausse tout le reste.

  Exemple :
     advice(z);

  Voir aussi IDDATA, DETREND, ARX, IMPULSEEST.
```

## `aic`

```
AIC Critère d'information d'Akaike.
  V = AIC(MODELE) rend N log(V) + 2p, où V est l'erreur quadratique, p
  le nombre de paramètres et N le nombre d'échantillons.

  V = AIC(MODELE,'nAIC') rend le critère normalisé par le nombre
  d'échantillons, et V = AIC(MODELE,'BIC') remplace la pénalité par
  p log(N), plus sévère : elle croît avec la taille des données, si bien
  que le critère finit par désigner le vrai modèle quand il est dans la
  liste, ce que le critère d'Akaike ne garantit pas.

  Exemple :
     aic(arx(z, [2 2 1]))

  Voir aussi FPE, ARX, POLYEST.
```

## `ar`

```
AR Estimation d'un modèle autorégressif.
  M = AR(Z,N) ajuste y(t) + a1 y(t-1) + ... + aN y(t-N) = e(t) à une
  série sans entrée. C'est le modèle des séries temporelles pures :
  chaque valeur s'explique par les précédentes et par un choc.

  Exemple :
     rng(1);
     y = filter(1, [1 -0.7 0.2], randn(500, 1));
     m = ar(iddata(y), 2);
     m.A      % environ 1 -0.7 0.2

  Voir aussi ARX, ARMAX, FORECAST, POLYEST.
```

## `armax`

```
ARMAX Estimation d'un modèle ARMAX.
  M = ARMAX(Z,[na nb nc nk]) ajuste

     A(q) y(t) = B(q) u(t-nk) + C(q) e(t)

  Le polynôme C décrit la couleur du bruit. C'est ce qui distingue
  ARMAX de ARX : ce dernier suppose que le bruit entre par le même
  dénominateur que l'entrée, ce qui est rarement vrai et biaise ses
  coefficients. ARMAX laisse au bruit son propre numérateur, au prix
  d'un critère qui n'est plus quadratique.

  Exemple :
     rng(1);
     u = sign(randn(600, 1));
     e = 0.1 * randn(600, 1);
     y = filter([0 0.5], [1 -0.8], u) + filter([1 0.6], [1 -0.8], e);
     m = armax(iddata(y, u), [1 1 1 1]);
     m.C      % environ 1 0.6

  Voir aussi ARX, OE, BJ, POLYEST, PEM.
```

## `arx`

```
ARX Estimation d'un modèle ARX par moindres carrés.
  M = ARX(Z,[na nb nk]) ajuste le modèle

     y(t) + a1 y(t-1) + ... + ana y(t-na)
         = b1 u(t-nk) + ... + bnb u(t-nk-nb+1) + e(t)

  où Z est un IDDATA. Le modèle est linéaire en ses coefficients : la
  solution est directe, c'est le minimum global, et il n'y a ni point de
  départ ni itération. C'est pourquoi ARX sert de départ aux autres
  estimateurs, dont aucun n'a cette propriété.

  Le prix de cette simplicité est que le bruit est supposé entrer par le
  même dénominateur que l'entrée : quand ce n'est pas le cas, ARX rend
  des coefficients biaisés, que ARMAX, OE ou BJ corrigent.

  M = ARX(Z,ORDRES,'na',...) accepte les réglages de POLYEST.

  Exemple :
     z = iddata(filter([0 0.5], [1 -0.8], ones(200, 1)), ones(200, 1));
     m = arx(z, [1 1 1]);
     m.A      % 1 -0.8

  Voir aussi ARMAX, OE, BJ, POLYEST, IV4, AR, COMPARE.
```

## `bj`

```
BJ Estimation d'un modèle de Box et Jenkins.
  M = BJ(Z,[nb nc nd nf nk]) ajuste

     y(t) = [B(q)/F(q)] u(t-nk) + [C(q)/D(q)] e(t)

  C'est le modèle le plus général de la famille : l'entrée et le bruit
  ont chacun leur dynamique propre, sans rien partager. Il faut donc
  estimer plus de paramètres, mais aucune hypothèse abusive n'est faite
  sur la façon dont le bruit entre.

  Exemple :
     m = bj(z, [1 1 1 1 1]);

  Voir aussi OE, ARMAX, ARX, POLYEST.
```

## `compareFit`

```
COMPAREFIT Qualité d'ajustement, en pour cent (critère de MathWorks).
  FIT = 100 (1 - ||y - yhat|| / ||y - moyenne(y)||)
```

## `etfe`

```
ETFE Estimation empirique de la réponse fréquentielle.
  G = ETFE(Z) rend le rapport des transformées de Fourier de la sortie
  et de l'entrée, fréquence par fréquence. C'est l'estimateur le plus
  direct qui soit : aucune structure n'est supposée, aucun paramètre
  n'est ajusté.

  Sa variance ne décroît pas quand les données s'accumulent — chaque
  fréquence n'est estimée que par un point de la transformée. C'est
  pourquoi G = ETFE(Z,M) lisse le résultat par une fenêtre de largeur M
  sur les décalages : on échange alors de la résolution fréquentielle
  contre de la précision, et c'est le seul moyen d'en gagner.

  G = ETFE(Z,M,N) impose le nombre de points de fréquence.

  Exemple :
     g = etfe(z, 30);
     bode(g);

  Voir aussi SPA, IDFRD, TFEST.
```

## `fpe`

```
FPE Critère d'erreur finale de prédiction d'Akaike.
  V = FPE(MODELE) rend l'erreur quadratique corrigée du nombre de
  paramètres :

     FPE = V (1 + p/N) / (1 - p/N)

  où V est l'erreur quadratique, p le nombre de paramètres et N le
  nombre d'échantillons. Le facteur pénalise la richesse du modèle :
  sans lui, un modèle plus riche paraîtrait toujours meilleur, puisqu'il
  colle toujours mieux aux données dont il est tiré.

  On compare deux modèles en prenant celui dont le critère est le plus
  petit.

  Exemple :
     fpe(arx(z, [2 2 1])) < fpe(arx(z, [1 1 1]))

  Voir aussi AIC, ARX, POLYEST.
```

## `iddata`

```
IDDATA Jeu de données entrée-sortie pour l'identification.
  Z = IDDATA(Y,U,TS) range les mesures : une colonne par sortie dans Y,
  une par entrée dans U, et la période d'échantillonnage TS. C'est
  l'objet que prennent tous les estimateurs.

  Z = IDDATA(Y) décrit une série sans entrée, comme en attend AR.
  Z = IDDATA(Y,U,TS,'Name',VALEUR,...) nomme le jeu, ses voies ou son
  instant de départ ('Name', 'OutputName', 'InputName', 'Tstart',
  'TimeUnit', 'ExperimentName').

  Plusieurs expériences se rangent dans un même objet : MERGE les
  assemble, et les estimateurs les traitent ensemble — ce qui vaut mieux
  que d'estimer sur chacune et de moyenner, puisque le bruit ne se
  raccorde pas d'une expérience à l'autre.

  Propriétés : OutputData, InputData, Ts, Tstart, TimeUnit, Name,
  OutputName, InputName, ExperimentName ; et, en abrégé, y, u et N.

  Ce qu'on lui fait : DETREND retire la moyenne ou la tendance, RETREND
  la remet, RESAMPLE change la cadence, MISDATA remplace les données
  manquantes, NKSHIFT décale l'entrée, MERGE assemble des expériences,
  PLOT trace.

  Exemple :
     t = (0:0.1:20)';
     u = sign(sin(t));
     y = filter(0.2, [1 -0.8], u);
     z = iddata(y, u, 0.1);
     m = arx(z, [1 1 1]);

  Voir aussi ARX, ARMAX, OE, BJ, N4SID, COMPARE, RESID.
```

## `idfrd`

```
IDFRD Réponse fréquentielle mesurée.
  M = IDFRD(REPONSE,FREQUENCE,TS) range une réponse fréquentielle
  estimée : un nombre complexe par fréquence. C'est ce que rendent SPA
  et ETFE.

  Un modèle de réponse fréquentielle ne suppose aucune structure : il ne
  dit pas combien de pôles a le système, seulement ce qu'il fait à
  chaque fréquence. C'est ce qui en fait le premier regard qu'on porte
  sur des données, avant de choisir un ordre.

  Propriétés : ResponseData, Frequency, Ts, SpectrumData, CovarianceData.

  Exemple :
     g = spa(z);
     bode(g);

  Voir aussi SPA, ETFE, IDTF, IDPOLY.
```

## `idinput`

```
IDINPUT Fabrique un signal d'entrée pour l'identification.
  U = IDINPUT(N) rend N échantillons d'un signal binaire aléatoire.
  U = IDINPUT(N,TYPE) où TYPE vaut :
    'rbs'   binaire aléatoire — deux niveaux seulement, ce qui donne la
            plus grande puissance possible pour une amplitude donnée
    'rgs'   gaussien aléatoire
    'prbs'  binaire pseudo-aléatoire — une suite de longueur maximale,
            donc reproductible et de spectre presque plat
    'sine'  somme de sinusoïdes, une par fréquence de la bande
  U = IDINPUT(N,TYPE,BANDE) limite le contenu fréquentiel : BANDE vaut
  [bas haut] en fraction de la fréquence de Nyquist.
  U = IDINPUT(N,TYPE,BANDE,NIVEAUX) impose les niveaux [min max].

  Une entrée doit exciter le système dans toute la bande où l'on veut le
  connaître : ce qu'elle ne sollicite pas, aucune estimation ne pourra
  le retrouver.

  Exemple :
     u = idinput(500, 'prbs');
     z = iddata(filter([0 0.5], [1 -0.8], u), u);

  Voir aussi IDDATA, ARX, ADVICE.
```

## `idpoly`

```
IDPOLY Modèle polynomial à temps discret.
  M = IDPOLY(A,B,C,D,F,NOISEVARIANCE,TS) décrit le modèle

     A(q) y(t) = [B(q)/F(q)] u(t) + [C(q)/D(q)] e(t)

  où q est l'opérateur de décalage et e un bruit blanc. Les familles
  usuelles en sont des cas particuliers : ARX quand C, D et F valent un,
  ARMAX quand D et F valent un, sortie-erreur quand A, C et D valent un,
  Box-Jenkins quand A vaut un.

  M = IDPOLY(A) décrit un modèle autorégressif, sans entrée.

  Le retard se lit dans les zéros de tête de B : un modèle dont l'entrée
  agit au bout de deux périodes a B qui commence par deux zéros.

  Propriétés : A, B, C, D, F, Ts, NoiseVariance, Report,
  ParameterVector, CovarianceMatrix.

  Ce qu'on lui demande : POLYDATA rend ses polynômes, TFDATA sa fonction
  de transfert, SIM le simule, PREDICT le prédit, COMPARE le confronte
  aux mesures, RESID examine ses résidus, FORECAST le prolonge.

  Exemple :
     m = idpoly([1 -0.8], [0 0.2], 1, 1, 1, 0.01, 0.1);
     z = sim(m, iddata([], sign(sin((0:0.1:20)')), 0.1));

  Voir aussi ARX, ARMAX, OE, BJ, POLYEST, IDSS, IDTF, IDDATA.
```

## `idproc`

```
IDPROC Modèle de procédé, décrit par ses constantes de temps.
  M = IDPROC(TYPE) crée un modèle de la forme

     G(s) = K (1 + Tz s) / [(1 + Tp1 s)(1 + Tp2 s)] exp(-Td s)

  où le TYPE dit ce qui est présent : 'P1' pour un seul pôle, 'P2' pour
  deux, 'P0' pour aucun, la lettre 'D' pour un retard, 'Z' pour un zéro,
  'I' pour un intégrateur. Ainsi 'P1D' est un premier ordre retardé, et
  'P2ZD' un second ordre à zéro et retard.

  C'est la description qu'emploie l'automaticien : quatre nombres qui se
  lisent sur une réponse indicielle — un gain, une ou deux constantes de
  temps, un retard — plutôt que des coefficients de polynômes sans
  signification physique.

  Propriétés : Type, K, Tp1, Tp2, Tz, Td, Ts, NoiseVariance, Report.

  Exemple :
     m = procest(z, 'P1D');
     m.K, m.Tp1, m.Td

  Voir aussi PROCEST, IDTF, TFEST.
```

## `idss`

```
IDSS Modèle d'état estimé.
  M = IDSS(A,B,C,D) décrit x(t+1) = A x(t) + B u(t), y(t) = C x(t) + D u(t).
  M = IDSS(A,B,C,D,K,X0,TS) ajoute le gain de Kalman, l'état initial et
  la période d'échantillonnage.

  La forme d'état dit la même chose qu'un modèle polynomial, mais elle
  la dit avec un seul entier : l'ordre. C'est ce qui la rend commode
  quand on ne sait pas d'avance combien de retards il faut, et c'est la
  forme que rendent les méthodes par sous-espaces.

  Propriétés : A, B, C, D, K, x0, Ts, NoiseVariance, Report.

  Ce qu'on lui demande : SSDATA rend ses matrices, SIM le simule,
  PREDICT le prédit, COMPARE le confronte aux mesures, RESID examine ses
  résidus.

  Exemple :
     m = n4sid(z, 2);
     [A, B, C, D] = ssdata(m);

  Voir aussi N4SID, SSEST, IDPOLY, IDTF, IDDATA.
```

## `idtf`

```
IDTF Fonction de transfert estimée.
  M = IDTF(NUM,DEN) décrit la fonction de transfert de numérateur NUM et
  de dénominateur DEN. M = IDTF(NUM,DEN,TS) la rend à temps discret ;
  avec TS nul, elle est à temps continu.

  C'est la forme la plus lisible d'un modèle linéaire : ses pôles et ses
  zéros se lisent directement, et son gain statique aussi.

  Propriétés : Numerator, Denominator, IODelay, Ts, NoiseVariance,
  Report.

  Exemple :
     m = tfest(z, 2, 1);
     [num, den] = tfdata(m, 'v');

  Voir aussi TFEST, IDPOLY, IDSS, IDPROC.
```

## `impulseest`

```
IMPULSEEST Réponse impulsionnelle estimée par moindres carrés.
```

## `iv4`

```
IV4 Estimation ARX par variables instrumentales, en quatre passes.
  M = IV4(Z,[na nb nk]) estime un modèle ARX sans le biais que l'ARX
  ordinaire subit quand le bruit n'est pas blanc.

  Le biais de l'ARX vient de ce que ses régresseurs — les sorties
  passées — sont corrélés au bruit. La méthode des variables
  instrumentales les remplace, dans les équations normales, par des
  grandeurs qui expliquent la sortie sans dépendre du bruit : la sortie
  simulée par un premier modèle. Quatre passes suffisent, la dernière
  filtrant les signaux par le modèle du bruit pour approcher la
  précision optimale.

  Exemple :
     rng(1);
     u = sign(randn(1000, 1));
     y = filter([0 0.5], [1 -0.8], u) + 0.3 * randn(1000, 1);
     m = iv4(iddata(y, u), [1 1 1]);
     m.A      % plus proche de 1 -0.8 que ne l'est arx

  Voir aussi ARX, ARMAX, OE, POLYEST.
```

## `matlibre_id_aplatir_etat`

```
MATLIBRE_ID_APLATIR_ETAT Matrices d'un modèle d'état, mises à la file.
  P = MATLIBRE_ID_APLATIR_ETAT(MODELE) empile A, B, C, D et l'état
  initial en un seul vecteur, celui que l'optimiseur fait varier.

  Exemple :
     p = matlibre_id_aplatir_etat(n4sid(z, 2));

  Voir aussi SSEST, MATLIBRE_ID_REPLIER_ETAT.
```

## `matlibre_id_base_tendance`

```
MATLIBRE_ID_BASE_TENDANCE Base des tendances polynomiales.
  A = MATLIBRE_ID_BASE_TENDANCE(T,ORDRE) rend la matrice des puissances
  de T jusqu'à ORDRE : une colonne de uns pour la moyenne, plus le temps
  lui-même pour une dérive.

  Exemple :
     matlibre_id_base_tendance([1; 2], 1)      % [1 1; 1 2]

  Voir aussi DETREND, RETREND.
```

## `matlibre_id_bloc`

```
MATLIBRE_ID_BLOC Données d'une expérience donnée.
  B = MATLIBRE_ID_BLOC(D,INDICE) rend la matrice de l'expérience, que
  les données soient une matrice unique ou un tableau de cellules.

  Exemple :
     matlibre_id_bloc({[1;2], [3;4]}, 2)      % 3; 4

  Voir aussi IDDATA.
```

## `matlibre_id_colonnes`

```
MATLIBRE_ID_COLONNES Données rangées en colonnes, une par voie.
  D = MATLIBRE_ID_COLONNES(BRUT) accepte un vecteur, une matrice ou un
  tableau de cellules — une case par expérience — et rend la même chose
  avec les voies en colonnes.

  Exemple :
     size(matlibre_id_colonnes([1 2 3]))      % 3 1

  Voir aussi IDDATA.
```

## `matlibre_id_comparer`

```
MATLIBRE_ID_COMPARER Confronte un modèle aux mesures.
  [Y,AJUSTEMENT] = MATLIBRE_ID_COMPARER(MODELE,DONNEES,ARGUMENTS) rend
  la sortie prédite et l'ajustement en pour cent.

  L'ajustement vaut cent fois un moins le rapport de la norme de
  l'erreur à celle de l'écart des mesures à leur moyenne : cent pour
  cent est une reproduction exacte, zéro vaut la moyenne constante, et
  un nombre négatif est pire que de ne rien prédire du tout.

  Sans horizon donné, la comparaison est faite en simulation — le
  modèle n'utilise alors que l'entrée, jamais la sortie mesurée.

  Exemple :
     [y, ajustement] = compare(m, z);

  Voir aussi PREDICT, RESID, GOODNESSOFFIT.
```

## `matlibre_id_comparer_etat`

```
MATLIBRE_ID_COMPARER_ETAT Confronte un modèle d'état aux mesures.
  [Y,AJUSTEMENT] = MATLIBRE_ID_COMPARER_ETAT(MODELE,DONNEES,ARGUMENTS)
  rend la sortie prédite et l'ajustement en pour cent.

  Exemple :
     [y, ajustement] = compare(n4sid(z, 2), z);

  Voir aussi COMPARE, IDSS.
```

## `matlibre_id_completer`

```
MATLIBRE_ID_COMPLETER Remplace les données manquantes d'un jeu.
  Z = MATLIBRE_ID_COMPLETER(OBJ) reconstruit les valeurs NaN par
  interpolation linéaire entre les instants connus, et par prolongement
  de la valeur la plus proche aux bords.

  Un estimateur ne sait pas quoi faire d'un trou, et l'écarter romprait
  la suite temporelle dont il tire justement la dynamique : il faut donc
  le boucher.

  Exemple :
     z = misdata(iddata([1; NaN; 3]));
     z.y(2)      % 2

  Voir aussi IDDATA, MISDATA.
```

## `matlibre_id_correlation`

```
MATLIBRE_ID_CORRELATION Corrélation normalisée, décalage par décalage.
  R = MATLIBRE_ID_CORRELATION(A,B,DECALAGE) rend les corrélations de
  moins DECALAGE à plus DECALAGE, normalisées par les écarts types :
  elles valent alors entre moins un et un, et le seuil de confiance
  s'écrit sans référence à l'échelle des signaux.

  Exemple :
     r = matlibre_id_correlation(randn(100, 1), randn(100, 1), 5);
     numel(r)      % 11

  Voir aussi RESID.
```

## `matlibre_id_covariance`

```
MATLIBRE_ID_COVARIANCE Covariance croisée, décalage par décalage.
  R = MATLIBRE_ID_COVARIANCE(A,B,M) rend les covariances des décalages
  de moins M à plus M, divisées par le nombre de points — l'estimateur
  biaisé, dont la transformée est toujours un spectre positif, ce que
  l'estimateur non biaisé ne garantit pas.

  Exemple :
     r = matlibre_id_covariance(randn(100,1), randn(100,1), 5);
     numel(r)      % 11

  Voir aussi SPA, RESID.
```

## `matlibre_id_critere`

```
MATLIBRE_ID_CRITERE Une mesure du compte rendu d'estimation.
  V = MATLIBRE_ID_CRITERE(MODELE,NOM) lit le champ demandé dans le
  rapport laissé par l'estimation.

  Exemple :
     matlibre_id_critere(arx(z, [1 1 1]), 'MSE')

  Voir aussi FPE, AIC.
```

## `matlibre_id_decaler`

```
MATLIBRE_ID_DECALER Décale l'entrée par rapport à la sortie.
  Z = MATLIBRE_ID_DECALER(OBJ,NK) avance l'entrée de NK échantillons.
  Retirer ainsi un retard connu épargne à l'estimateur d'avoir à le
  représenter par des coefficients nuls, qu'il devrait pourtant estimer.

  Exemple :
     z = nkshift(iddata((1:5)', (1:5)'), 1);
     z.u(1)      % 2

  Voir aussi IDDATA, NKSHIFT.
```

## `matlibre_id_decouper_inconnues`

```
MATLIBRE_ID_DECOUPER_INCONNUES Redécoupe le vecteur des inconnues.
  [X0,B,D] = MATLIBRE_ID_DECOUPER_INCONNUES(V,ORDRE,ENTREES,SORTIES)
  sépare l'état initial, la matrice d'entrée et la transmission directe.

  Exemple :
     [x0, B, D] = matlibre_id_decouper_inconnues((1:4)', 2, 1, 1);

  Voir aussi MATLIBRE_ID_ENTREE_SORTIE.
```

## `matlibre_id_depart`

```
MATLIBRE_ID_DEPART Point de départ d'une estimation non linéaire.
  D = MATLIBRE_ID_DEPART(Z,ORDRES) tire le point de départ d'une
  estimation ARX, qui, elle, est exacte et sans départ.

  Quand le modèle a un dénominateur propre à l'entrée — sortie-erreur,
  Box-Jenkins —, c'est le dénominateur de l'ARX qui l'initialise ; les
  polynômes du bruit partent de un, c'est-à-dire d'un bruit blanc.

  Exemple :
     d = matlibre_id_depart(z, [2 2 1 0 0 1]);

  Voir aussi MATLIBRE_ID_ESTIMER, ARX.
```

## `matlibre_id_detendre`

```
MATLIBRE_ID_DETENDRE Retire la moyenne ou la tendance d'un jeu.
  [Z,T] = MATLIBRE_ID_DETENDRE(OBJ,ORDRE) retire de chaque voie sa
  moyenne — ordre zéro — ou la droite qui l'ajuste au mieux — ordre un.
  T retient ce qui a été retiré, de quoi le remettre par RETREND.

  Un modèle linéaire décrit des écarts autour d'un point de
  fonctionnement : lui laisser une composante continue, ou une dérive,
  l'oblige à la représenter avec des paramètres qui ne servent qu'à
  cela.

  Exemple :
     z = iddata((1:10)' + 100, (1:10)');
     max(abs(mean(detrend(z).y)))      % zero

  Voir aussi IDDATA, RETREND.
```

## `matlibre_id_ecrire_polynome`

```
MATLIBRE_ID_ECRIRE_POLYNOME Écriture lisible d'un polynôme en q moins un.
  T = MATLIBRE_ID_ECRIRE_POLYNOME(P) rend la formule, les coefficients
  nuls omis.

  Exemple :
     matlibre_id_ecrire_polynome([1 -0.8])      % 1 - 0.8 q^-1

  Voir aussi IDPOLY.
```

## `matlibre_id_entree_sortie`

```
MATLIBRE_ID_ENTREE_SORTIE Matrices B et D, et état initial, par moindres carrés.
  [B,D,X0] = MATLIBRE_ID_ENTREE_SORTIE(A,C,Y,U) résout le problème
  linéaire qui reste une fois A et C connus : la sortie s'écrit

     y(t) = C A^t x0 + somme des C A^(t-k-1) B u(k) + D u(t)

  ce qui est linéaire en x0, en B et en D. La solution est donc directe,
  et c'est le minimum global.

  Exemple :
     [B, D, x0] = matlibre_id_entree_sortie(A, C, y, u);

  Voir aussi N4SID, SSEST.
```

## `matlibre_id_erreurs`

```
MATLIBRE_ID_ERREURS Erreurs de prédiction à un pas d'un modèle.
  E = MATLIBRE_ID_ERREURS(MODELE,Y,U) rend le bruit blanc que le modèle
  impute aux données :

     e = (D/C) [ A y - (B/F) u ]

  C'est cette suite dont l'estimation minimise la somme des carrés :
  ajuster un modèle, c'est chercher les polynômes qui rendent l'erreur
  de prédiction aussi petite — et aussi blanche — que possible.

  Exemple :
     m = idpoly([1 -0.8], [0 0.2]);
     e = matlibre_id_erreurs(m, [0; 1; 2], [0; 1; 1]);

  Voir aussi PREDICT, RESID, POLYEST.
```

## `matlibre_id_estimer`

```
MATLIBRE_ID_ESTIMER Minimisation de l'erreur de prédiction.
  M = MATLIBRE_ID_ESTIMER(Z,ORDRES,METHODE,ARGUMENTS) cherche les
  polynômes qui rendent l'erreur de prédiction la plus petite au sens
  des moindres carrés, en partant d'une estimation ARX.

  Toutes les expériences contribuent : leurs erreurs sont empilées, et
  c'est leur somme des carrés qu'on minimise.

  Exemple :
     m = matlibre_id_estimer(z, [2 2 1 0 0 1], 'armax', {});

  Voir aussi POLYEST, ARMAX, OE, BJ.
```

## `matlibre_id_experience`

```
MATLIBRE_ID_EXPERIENCE Une expérience d'un jeu qui en porte plusieurs.
  Z = MATLIBRE_ID_EXPERIENCE(OBJ,INDICE) rend le jeu réduit à cette
  seule expérience.

  Exemple :
     z = merge(iddata((1:5)'), iddata((6:10)'));
     getexp(z, 2).N      % 5

  Voir aussi IDDATA, MERGE.
```

## `matlibre_id_extraire`

```
MATLIBRE_ID_EXTRAIRE Sous-ensemble d'un jeu de données.
  Z = MATLIBRE_ID_EXTRAIRE(OBJ,INDICES) découpe le jeu. Le premier
  indice choisit les échantillons, le deuxième les sorties, le
  troisième les entrées : Z(1:100) garde les cent premiers instants,
  Z(:,1,:) la première sortie.

  Exemple :
     z = iddata((1:10)', (1:10)');
     z(1:5).N      % 5

  Voir aussi IDDATA.
```

## `matlibre_id_extraire_voies`

```
MATLIBRE_ID_EXTRAIRE_VOIES Sortie, entrée et jeu d'origine.
  [Y,U,JEU] = MATLIBRE_ID_EXTRAIRE_VOIES(DONNEES) accepte un IDDATA ou
  une matrice dont la première colonne est la sortie et la seconde
  l'entrée, et rend les deux voies ainsi qu'un IDDATA pour porter le
  résultat.

  Exemple :
     [y, u] = matlibre_id_extraire_voies(iddata([1;2], [3;4]));

  Voir aussi PREDICT, COMPARE, RESID.
```

## `matlibre_id_fenetre_hann`

```
MATLIBRE_ID_FENETRE_HANN Fenêtre de Hann sur les décalages.
  W = MATLIBRE_ID_FENETRE_HANN(M) rend les poids des décalages de moins
  M à plus M : un au décalage nul, zéro aux extrémités, en cosinus
  surélevé.

  Pondérer ainsi les covariances avant de les transformer, plutôt que de
  les tronquer net, évite les oscillations qu'une troncature brutale
  introduit dans le spectre.

  Exemple :
     w = matlibre_id_fenetre_hann(2);
     w(3)      % 1, au decalage nul

  Voir aussi SPA.
```

## `matlibre_id_filtrer_etat`

```
MATLIBRE_ID_FILTRER_ETAT Prédiction à K pas d'un modèle d'état bruité.
  P = MATLIBRE_ID_FILTRER_ETAT(MODELE,Y,U,HORIZON) corrige l'état par
  l'innovation à chaque instant — c'est le gain de Kalman qui pèse cette
  correction —, puis fait avancer le modèle HORIZON pas sans correction.

  Exemple :
     p = matlibre_id_filtrer_etat(m, y, u, 1);

  Voir aussi IDSS, PREDICT.
```

## `matlibre_id_fusionner`

```
MATLIBRE_ID_FUSIONNER Assemble des jeux en autant d'expériences.
  Z = MATLIBRE_ID_FUSIONNER(JEUX) range les jeux donnés dans un même
  objet, chacun restant une expérience distincte.

  Estimer sur plusieurs expériences à la fois vaut mieux que d'estimer
  sur chacune puis de moyenner : les données se joignent, mais pas les
  suites temporelles — le bruit d'une expérience ne prédit rien de la
  suivante, et les concaténer bout à bout fabriquerait une transition
  qui n'a pas eu lieu.

  Exemple :
     z = merge(iddata((1:5)'), iddata((6:10)'));
     nexp(z)      % 2

  Voir aussi IDDATA, GETEXP.
```

## `matlibre_id_hankel`

```
MATLIBRE_ID_HANKEL Matrice de Hankel par blocs d'un signal.
  H = MATLIBRE_ID_HANKEL(SIGNAL,DEPART,BLOCS,COLONNES) empile BLOCS
  fenêtres décalées d'un échantillon, chacune de COLONNES points, à
  partir de DEPART.

  C'est la mise en forme dont vivent les méthodes par sous-espaces : les
  colonnes y sont autant de trajectoires courtes du même système, et
  l'espace qu'elles engendrent est celui de l'état.

  Exemple :
     matlibre_id_hankel((1:5)', 1, 2, 3)      % [1 2 3; 2 3 4]

  Voir aussi N4SID, MATLIBRE_ID_SOUS_ESPACES.
```

## `matlibre_id_limiter_bande`

```
MATLIBRE_ID_LIMITER_BANDE Restreint le contenu fréquentiel d'un signal.
  U = MATLIBRE_ID_LIMITER_BANDE(U,BANDE) annule, dans la transformée de
  Fourier, ce qui sort de la bande donnée en fraction de la fréquence de
  Nyquist, puis revient au temps.

  Exemple :
     u = matlibre_id_limiter_bande(randn(100, 1), [0 0.5]);

  Voir aussi IDINPUT.
```

## `matlibre_id_longueurs`

```
MATLIBRE_ID_LONGUEURS Nombre d'échantillons de chaque expérience.
  L = MATLIBRE_ID_LONGUEURS(D) rend un nombre par expérience.

  Exemple :
     matlibre_id_longueurs(zeros(10, 2))      % 10

  Voir aussi IDDATA.
```

## `matlibre_id_meilleur_ordre`

```
MATLIBRE_ID_MEILLEUR_ORDRE Ordre qui minimise le critère de prédiction.
  M = MATLIBRE_ID_MEILLEUR_ORDRE(DONNEES,FABRIQUE) essaie les ordres de
  un à dix et garde celui dont le critère d'erreur finale de prédiction
  est le plus petit — critère qui pénalise le nombre de paramètres, sans
  quoi le plus grand ordre gagnerait toujours.

  Exemple :
     m = n4sid(z, 'best');

  Voir aussi N4SID, SSEST, FPE.
```

## `matlibre_id_mettre_niveaux`

```
MATLIBRE_ID_METTRE_NIVEAUX Ramène un signal aux niveaux demandés.
  U = MATLIBRE_ID_METTRE_NIVEAUX(U,NIVEAUX,BINAIRE) met le signal entre
  les deux niveaux. Un signal binaire n'y prend que les deux valeurs
  extrêmes ; un signal continu est mis à l'échelle et centré.

  Exemple :
     matlibre_id_mettre_niveaux([-1; 1], [0 10], true)      % 0 ; 10

  Voir aussi IDINPUT.
```

## `matlibre_id_moindres_carres`

```
MATLIBRE_ID_MOINDRES_CARRES Estimation ARX, sur une ou plusieurs expériences.
  M = MATLIBRE_ID_MOINDRES_CARRES(Z,ORDRES,METHODE) résout le système
  des moindres carrés, en empilant les régressions de toutes les
  expériences : c'est ainsi qu'elles contribuent ensemble sans qu'on
  fabrique une transition entre elles.

  Exemple :
     m = matlibre_id_moindres_carres(z, [1 1 0 0 0 1], 'arx');

  Voir aussi ARX, AR, POLYEST.
```

## `matlibre_id_nombre_experiences`

```
MATLIBRE_ID_NOMBRE_EXPERIENCES Combien d'expériences porte un jeu.
  N = MATLIBRE_ID_NOMBRE_EXPERIENCES(OBJ) rend un si les données sont
  une seule matrice, et le nombre de cases si elles sont en cellules.

  Exemple :
     matlibre_id_nombre_experiences(iddata((1:5)'))      % 1

  Voir aussi IDDATA, MERGE.
```

## `matlibre_id_nommer`

```
MATLIBRE_ID_NOMMER Donne un nom aux voies qui n'en ont pas.
  OBJ = MATLIBRE_ID_NOMMER(OBJ) numérote les sorties « y1 », « y2 »… et
  les entrées « u1 », « u2 »…, comme le fait MATLAB.

  Exemple :
     z = iddata([1;2], [3;4]);
     z.OutputName{1}      % y1

  Voir aussi IDDATA.
```

## `matlibre_id_ordre_conseille`

```
MATLIBRE_ID_ORDRE_CONSEILLE Ordre que les données semblent demander.
  N = MATLIBRE_ID_ORDRE_CONSEILLE(JEU) essaie les ordres de un à cinq et
  rend celui dont le critère d'erreur finale de prédiction est le plus
  petit.

  Exemple :
     matlibre_id_ordre_conseille(jeu)

  Voir aussi ADVICE, FPE, ARX.
```

## `matlibre_id_ordres`

```
MATLIBRE_ID_ORDRES Ordres d'un modèle polynomial, complétés.
  O = MATLIBRE_ID_ORDRES(DONNES,DEFAUT) rend [na nb nc nd nf nk] en
  complétant ce qui manque par les valeurs par défaut de la famille.

  Exemple :
     matlibre_id_ordres([2 2 1], [0 0 0 0 0 1])      % 2 2 1 0 0 1

  Voir aussi POLYEST, ARX, ARMAX, OE, BJ.
```

## `matlibre_id_ordres_famille`

```
MATLIBRE_ID_ORDRES_FAMILLE Ordres complets d'une famille de modèles.
  O = MATLIBRE_ID_ORDRES_FAMILLE(DONNES,FAMILLE) traduit les ordres
  abrégés de chaque famille en la liste complète
  [na nb nc nd nf nk] que POLYEST attend.

  Exemple :
     matlibre_id_ordres_famille([1 1 1 1], 'armax')      % 1 1 1 0 0 1

  Voir aussi ARMAX, OE, BJ, AR, POLYEST.
```

## `matlibre_id_parametres`

```
MATLIBRE_ID_PARAMETRES Paramètres libres d'un modèle polynomial.
  P = MATLIBRE_ID_PARAMETRES(MODELE) rend, à la file, les coefficients
  de A, B, C, D et F qui ne sont pas fixés : le terme constant de A, C,
  D et F vaut un par construction, et les zéros de tête de B portent le
  retard.

  Exemple :
     getpvec(idpoly([1 -0.8], [0 0.2]))      % -0.8  0.2

  Voir aussi SETPVEC, POLYEST.
```

## `matlibre_id_parcourir_etat`

```
MATLIBRE_ID_PARCOURIR_ETAT Sortie et états d'un modèle d'état.
  [Y,X] = MATLIBRE_ID_PARCOURIR_ETAT(MODELE,U,X0) fait avancer la
  récurrence x(t+1) = A x(t) + B u(t) et rend la sortie C x + D u ainsi
  que la suite des états.

  Exemple :
     [y, X] = matlibre_id_parcourir_etat(m, ones(10, 1), zeros(2, 1));

  Voir aussi IDSS, SIM.
```

## `matlibre_id_polynome`

```
MATLIBRE_ID_POLYNOME Polynôme en l'opérateur de décalage, en ligne.
  P = MATLIBRE_ID_POLYNOME(BRUT) rend un vecteur ligne. Un polynôme vide
  vaut un : c'est la convention des modèles, où un polynôme absent ne
  filtre rien.

  Exemple :
     matlibre_id_polynome([1; -0.8])      % 1 -0.8

  Voir aussi IDPOLY.
```

## `matlibre_id_poser_bloc`

```
MATLIBRE_ID_POSER_BLOC Range les données d'une expérience.
  OBJ = MATLIBRE_ID_POSER_BLOC(OBJ,CHAMP,INDICE,BLOC) écrit dans la
  propriété nommée, à la bonne place selon que le jeu porte une ou
  plusieurs expériences.

  Exemple :
     z = matlibre_id_poser_bloc(iddata((1:3)'), 'OutputData', 1, (4:6)');

  Voir aussi IDDATA.
```

## `matlibre_id_poser_parametres`

```
MATLIBRE_ID_POSER_PARAMETRES Remplace les paramètres libres d'un modèle.
  MODELE = MATLIBRE_ID_POSER_PARAMETRES(MODELE,P) redistribue le vecteur
  dans A, B, C, D et F, en respectant la longueur de chacun et le retard
  que porte B.

  Exemple :
     m = setpvec(idpoly([1 0], [0 0]), [-0.5; 0.3]);
     m.A      % 1 -0.5

  Voir aussi GETPVEC, POLYEST.
```

## `matlibre_id_prbs`

```
MATLIBRE_ID_PRBS Suite binaire pseudo-aléatoire de longueur maximale.
  U = MATLIBRE_ID_PRBS(N) rend N valeurs valant moins un ou un,
  engendrées par un registre à décalage bouclé sur lui-même.

  Une telle suite parcourt tous les états non nuls du registre avant de
  se répéter : son autocorrélation vaut un au décalage nul et presque
  zéro partout ailleurs, ce qui en fait un bruit blanc reproductible.

  Exemple :
     u = matlibre_id_prbs(31);
     all(abs(u) == 1)      % vrai

  Voir aussi IDINPUT.
```

## `matlibre_id_predire`

```
MATLIBRE_ID_PREDIRE Prédiction à K pas d'un modèle polynomial.
  Z = MATLIBRE_ID_PREDIRE(MODELE,DONNEES,HORIZON) rend la prédiction de
  la sortie connaissant le passé jusqu'à HORIZON pas en arrière.

  Le prédicteur s'écrit ŷ = y - W(q) e, où e est l'erreur à un pas et W
  les HORIZON premiers termes de la réponse du filtre de bruit. À un
  pas, W vaut un et l'on retrouve ŷ = y - e ; à l'infini, W est le
  filtre entier et la prédiction devient la simulation, qui n'utilise
  plus la sortie mesurée du tout.

  Exemple :
     m = arx(z, [2 2 1]);
     zp = predict(m, z, 1);

  Voir aussi SIM, COMPARE, FORECAST.
```

## `matlibre_id_predire_etat`

```
MATLIBRE_ID_PREDIRE_ETAT Prédiction d'un modèle d'état.
  Z = MATLIBRE_ID_PREDIRE_ETAT(MODELE,DONNEES,HORIZON) rend la sortie
  prédite. Avec un gain de Kalman nul, la prédiction est la simulation,
  quel que soit l'horizon : le modèle n'a alors aucun moyen de corriger
  son état par la sortie mesurée.

  Exemple :
     zp = predict(m, z, 1);

  Voir aussi IDSS, PREDICT, N4SID.
```

## `matlibre_id_prises_registre`

```
MATLIBRE_ID_PRISES_REGISTRE Positions bouclées d'un registre à décalage.
  P = MATLIBRE_ID_PRISES_REGISTRE(ORDRE) rend les positions dont la
  somme, modulo deux, alimente l'entrée du registre. Ces positions sont
  celles d'un polynôme primitif : c'est ce qui garantit que la suite
  parcourt tous les états avant de se répéter.

  Exemple :
     matlibre_id_prises_registre(9)      % 5 9

  Voir aussi MATLIBRE_ID_PRBS.
```

## `matlibre_id_proc_compte`

```
MATLIBRE_ID_PROC_COMPTE Nombre de pôles que déclare un type de procédé.
  N = MATLIBRE_ID_PROC_COMPTE(TYPE) lit le chiffre qui suit la lettre P.

  Exemple :
     matlibre_id_proc_compte('P2ZD')      % 2

  Voir aussi IDPROC, PROCEST.
```

## `matlibre_id_proc_depart`

```
MATLIBRE_ID_PROC_DEPART Départ et bornes d'un ajustement de procédé.
  [D,LB,UB,POSER] = MATLIBRE_ID_PROC_DEPART(JEU,TYPE) tire le point de
  départ d'une estimation par fonction de transfert : gain statique et
  constantes de temps s'y lisent, alors que partir de valeurs
  arbitraires ferait échouer la descente.

  POSER est la fonction qui reconstruit un IDPROC depuis le vecteur de
  paramètres.

  Exemple :
     [d, lb, ub, poser] = matlibre_id_proc_depart(jeu, 'P1D');

  Voir aussi PROCEST, IDPROC.
```

## `matlibre_id_proc_polynomes`

```
MATLIBRE_ID_PROC_POLYNOMES Fonction de transfert d'un modèle de procédé.
  [NUM,DEN] = MATLIBRE_ID_PROC_POLYNOMES(MODELE) développe les
  constantes de temps en polynômes en s. Le retard n'y figure pas : il
  s'applique à part, sur le signal.

  Exemple :
     [n, d] = matlibre_id_proc_polynomes(idproc('P1', 'K', 2, 'Tp1', 3));
     d      % 3 1

  Voir aussi IDPROC, PROCEST.
```

## `matlibre_id_proc_poser`

```
MATLIBRE_ID_PROC_POSER Reconstruit un modèle de procédé depuis ses paramètres.
  M = MATLIBRE_ID_PROC_POSER(P,TYPE,POLES,AVECZERO,AVECRETARD) range le
  vecteur dans les champs du modèle, dans l'ordre où l'estimation les a
  mis : gain, constantes de temps, zéro, retard.

  Exemple :
     m = matlibre_id_proc_poser([2; 4; 1], 'P1D', 1, false, true);

  Voir aussi PROCEST, IDPROC.
```

## `matlibre_id_proc_residu`

```
MATLIBRE_ID_PROC_RESIDU Erreur de simulation d'un modèle de procédé.
  E = MATLIBRE_ID_PROC_RESIDU(P,POSER,JEU) reconstruit le modèle depuis
  ses paramètres et rend l'écart à la sortie mesurée.

  Exemple :
     % appelée par l'optimiseur, jamais directement

  Voir aussi PROCEST.
```

## `matlibre_id_prolonger`

```
MATLIBRE_ID_PROLONGER Prolonge des données au-delà de leur fin.
  Z = MATLIBRE_ID_PROLONGER(MODELE,DONNEES,HORIZON) rend les HORIZON
  valeurs à venir. Le passé mesuré sert d'état initial ; l'avenir est
  calculé en supposant le bruit nul, ce qui est son espérance — la
  prévision est donc la moyenne conditionnelle, pas une trajectoire
  possible.

  Exemple :
     m = ar(iddata(y), 2);
     zf = forecast(m, iddata(y), 10);

  Voir aussi PREDICT, SIM, AR.
```

## `matlibre_id_propriete`

```
MATLIBRE_ID_PROPRIETE Nom exact d'une propriété de IDDATA.
  N = MATLIBRE_ID_PROPRIETE(DONNE) rapproche le nom donné, quelle qu'en
  soit la casse, de celui de la propriété.

  Exemple :
     matlibre_id_propriete('outputname')      % OutputName

  Voir aussi IDDATA.
```

## `matlibre_id_rapport`

```
MATLIBRE_ID_RAPPORT Renseigne le compte rendu d'une estimation.
  MODELE = MATLIBRE_ID_RAPPORT(MODELE,DONNEES,METHODE,N,P) remplit le
  champ Report : la méthode employée, l'ajustement en pour cent, l'erreur
  quadratique, le critère d'erreur finale de prédiction et le critère
  d'Akaike.

  Ces deux critères pénalisent le nombre de paramètres : sans eux, un
  modèle plus riche paraîtrait toujours meilleur, puisqu'il peut
  toujours coller de plus près aux données dont il est tiré.

  Exemple :
     m = arx(z, [2 2 1]);
     m.Report.Fit.FPE

  Voir aussi ARX, POLYEST, FPE, AIC.
```

## `matlibre_id_rapport_etat`

```
MATLIBRE_ID_RAPPORT_ETAT Compte rendu d'estimation d'un modèle d'état.
  MODELE = MATLIBRE_ID_RAPPORT_ETAT(MODELE,DONNEES,METHODE,N,P) remplit
  le champ Report comme le fait son homologue polynomial.

  Exemple :
     m = n4sid(z, 2);
     m.Report.Fit.FitPercent

  Voir aussi N4SID, SSEST, MATLIBRE_ID_RAPPORT.
```

## `matlibre_id_reechantillonner`

```
MATLIBRE_ID_REECHANTILLONNER Change la cadence d'un jeu de données.
  Z = MATLIBRE_ID_REECHANTILLONNER(OBJ,P,Q) rééchantillonne dans le
  rapport P sur Q, et met à jour la période. Le signal est interpolé sur
  la nouvelle grille de temps.

  Exemple :
     z = resample(iddata((1:10)', (1:10)'), 1, 2);
     z.N      % 5

  Voir aussi IDDATA, RESAMPLE.
```

## `matlibre_id_regression`

```
MATLIBRE_ID_REGRESSION Matrice de régression d'un modèle ARX.
  [PHI,Y,DEBUT] = MATLIBRE_ID_REGRESSION(Y,U,ORDRES) construit la
  matrice dont chaque ligne porte les sorties et les entrées passées qui
  expliquent un échantillon.

  Le modèle ARX est linéaire en ses coefficients : cette matrice suffit
  à les obtenir par moindres carrés, sans itération et sans point de
  départ. C'est ce qui en fait le point de départ de tous les autres.

  Exemple :
     [Phi, Y] = matlibre_id_regression((1:5)', (1:5)', [1 1 0 0 0 1]);
     size(Phi)      % 4 2

  Voir aussi ARX, POLYEST.
```

## `matlibre_id_replier_etat`

```
MATLIBRE_ID_REPLIER_ETAT Reconstruit un modèle d'état depuis un vecteur.
  MODELE = MATLIBRE_ID_REPLIER_ETAT(P,FORME) redécoupe le vecteur selon
  les tailles du modèle donné pour modèle.

  Exemple :
     m = matlibre_id_replier_etat(p, depart);

  Voir aussi SSEST, MATLIBRE_ID_APLATIR_ETAT.
```

## `matlibre_id_reponse_bruit`

```
MATLIBRE_ID_REPONSE_BRUIT Réponse impulsionnelle du filtre de bruit.
  H = MATLIBRE_ID_REPONSE_BRUIT(MODELE,LONGUEUR) rend les premiers
  termes de la réponse de C/(A D), le filtre qui mène le bruit blanc à
  la sortie. Ce sont eux qui construisent le prédicteur à plusieurs pas.

  Exemple :
     matlibre_id_reponse_bruit(idpoly([1 -0.5]), 3)      % 1 0.5 0.25

  Voir aussi PREDICT, FORECAST.
```

## `matlibre_id_residu_etat`

```
MATLIBRE_ID_RESIDU_ETAT Erreur de simulation d'un modèle d'état.
  E = MATLIBRE_ID_RESIDU_ETAT(P,FORME,Y,U) reconstruit le modèle depuis
  le vecteur de paramètres et rend l'écart entre la sortie mesurée et la
  sortie simulée.

  Exemple :
     % appelée par l'optimiseur, jamais directement

  Voir aussi SSEST.
```

## `matlibre_id_residu_global`

```
MATLIBRE_ID_RESIDU_GLOBAL Erreurs de prédiction, toutes expériences.
  E = MATLIBRE_ID_RESIDU_GLOBAL(P,SQUELETTE,DONNEES) pose les paramètres
  dans le modèle et empile les erreurs de chaque expérience.

  Exemple :
     % appelée par l'optimiseur, jamais directement

  Voir aussi MATLIBRE_ID_ESTIMER.
```

## `matlibre_id_residus`

```
MATLIBRE_ID_RESIDUS Examine les résidus d'un modèle estimé.
  [E,AUTO,CROISEE,SEUIL] = MATLIBRE_ID_RESIDUS(MODELE,DONNEES,ARGUMENTS)
  rend les résidus, leur autocorrélation, leur corrélation croisée avec
  l'entrée, et le seuil de confiance à quatre-vingt-dix-neuf pour cent.

  Deux choses se lisent dans ces courbes. Une autocorrélation qui sort
  du seuil dit que le modèle du bruit est insuffisant : il reste de la
  structure que le modèle n'a pas prise. Une corrélation croisée qui en
  sort dit que l'entrée explique encore une part du résidu : c'est la
  partie déterministe qui est mal décrite.

  Exemple :
     [e, auto, croisee, seuil] = resid(m, z);

  Voir aussi COMPARE, PREDICT.
```

## `matlibre_id_residus_bruts`

```
MATLIBRE_ID_RESIDUS_BRUTS Analyse d'une suite de résidus déjà calculée.
  [E,AUTO,CROISEE,SEUIL] = MATLIBRE_ID_RESIDUS_BRUTS(E,U,ARGUMENTS,N)
  rend les corrélations et le seuil de confiance.

  Exemple :
     [e, auto] = matlibre_id_residus_bruts(randn(100,1), zeros(100,1), {}, 2);

  Voir aussi RESID.
```

## `matlibre_id_retard`

```
MATLIBRE_ID_RETARD Retard lu dans les zéros de tête du numérateur.
  NK = MATLIBRE_ID_RETARD(B) compte les zéros qui précèdent le premier
  coefficient non nul. Un modèle dont l'entrée n'agit qu'au bout de deux
  périodes a donc un B commençant par deux zéros.

  Exemple :
     matlibre_id_retard([0 0 0.2])      % 2

  Voir aussi IDPOLY, POLYEST.
```

## `matlibre_id_retard_apparent`

```
MATLIBRE_ID_RETARD_APPARENT Retard lu dans la corrélation croisée.
  R = MATLIBRE_ID_RETARD_APPARENT(Y,U) rend le décalage positif où la
  corrélation entre l'entrée et la sortie est la plus forte : c'est le
  temps que met l'entrée à se faire sentir.

  Exemple :
     matlibre_id_retard_apparent(filter([0 0 1], 1, u), u)      % 2

  Voir aussi ADVICE, NKSHIFT.
```

## `matlibre_id_retard_modele`

```
MATLIBRE_ID_RETARD_MODELE Retard d'entrée d'un modèle polynomial.
  NK = MATLIBRE_ID_RETARD_MODELE(MODELE) rend le retard que le modèle
  déclare dans ses ordres, ou, à défaut, celui que trahissent les zéros
  de tête de son numérateur.

  Le déclarer vaut mieux que le lire : un coefficient estimé peut
  tomber exactement à zéro, et le retard apparent changerait alors sans
  que le modèle ait changé.

  Exemple :
     matlibre_id_retard_modele(idpoly(1, [0 0.2]))      % 1

  Voir aussi IDPOLY, GETPVEC.
```

## `matlibre_id_retarder`

```
MATLIBRE_ID_RETARDER Retarde un signal d'un nombre non entier d'échantillons.
  D = MATLIBRE_ID_RETARDER(U,ECHANTILLONS) décale le signal en
  interpolant linéairement entre les points : le retard peut ainsi
  valoir une fraction de période, ce qu'un décalage d'indices ne permet
  pas — et ce dont l'estimation d'un retard a besoin pour être dérivable.

  Avant le début du signal, la première valeur est prolongée.

  Exemple :
     matlibre_id_retarder([0; 1; 2; 3], 0.5)      % 0 0.5 1.5 2.5

  Voir aussi PROCEST, IDTF.
```

## `matlibre_id_retendre`

```
MATLIBRE_ID_RETENDRE Remet une tendance retirée par DETREND.
  Z = MATLIBRE_ID_RETENDRE(OBJ,TENDANCE) rajoute ce que DETREND avait
  ôté. C'est ce qu'il faut pour ramener une simulation dans les unités
  des mesures d'origine.

  Exemple :
     z = iddata((1:10)' + 100, (1:10)');
     [d, t] = detrend(z);
     max(abs(retrend(d, t).y - z.y))      % zero

  Voir aussi DETREND, IDDATA.
```

## `matlibre_id_simuler`

```
MATLIBRE_ID_SIMULER Simule la réponse d'un modèle polynomial.
  Z = MATLIBRE_ID_SIMULER(MODELE,ENTREE,ARGUMENTS) applique le modèle à
  l'entrée donnée — un IDDATA ou une matrice — et rend un IDDATA
  portant la sortie simulée.

  La sortie est y = (B/(A F)) u, à quoi s'ajoute (C/(A D)) e si un bruit
  est fourni en argument.

  Exemple :
     m = idpoly([1 -0.8], [0 0.2], 1, 1, 1, 0, 0.1);
     z = sim(m, iddata([], ones(20, 1), 0.1));

  Voir aussi PREDICT, COMPARE, IDPOLY.
```

## `matlibre_id_simuler_etat`

```
MATLIBRE_ID_SIMULER_ETAT Simule un modèle d'état.
  Z = MATLIBRE_ID_SIMULER_ETAT(MODELE,ENTREE,ARGUMENTS) fait avancer
  l'état pas à pas et rend la sortie.

  Exemple :
     z = sim(n4sid(donnees, 2), iddata([], u, Ts));

  Voir aussi IDSS, N4SID.
```

## `matlibre_id_simuler_proc`

```
MATLIBRE_ID_SIMULER_PROC Simule un modèle de procédé.
  Z = MATLIBRE_ID_SIMULER_PROC(MODELE,ENTREE) discrétise le modèle à la
  période des données, applique le retard et filtre l'entrée.

  Exemple :
     z = sim(idproc('P1D', 'K', 2, 'Tp1', 3, 'Td', 1), donnees);

  Voir aussi IDPROC, PROCEST.
```

## `matlibre_id_simuler_tf`

```
MATLIBRE_ID_SIMULER_TF Simule une fonction de transfert estimée.
  Z = MATLIBRE_ID_SIMULER_TF(MODELE,ENTREE) applique le modèle à
  l'entrée. Un modèle continu est d'abord discrétisé à la période des
  données, par blocage d'ordre zéro — l'entrée d'un enregistrement étant
  constante entre deux mesures, c'est la discrétisation exacte.

  Exemple :
     z = sim(tfest(donnees, 2, 1), donnees);

  Voir aussi IDTF, TFEST.
```

## `matlibre_id_somme_sinus`

```
MATLIBRE_ID_SOMME_SINUS Somme de sinusoïdes couvrant une bande.
  U = MATLIBRE_ID_SOMME_SINUS(N,BANDE) additionne des sinusoïdes de
  fréquences réparties dans la bande, de phases tirées au hasard.

  Répartir la puissance sur quelques fréquences plutôt que sur tout le
  spectre donne, à amplitude égale, bien plus d'énergie là où l'on veut
  connaître le système — c'est l'intérêt d'une entrée sinusoïdale.

  Exemple :
     u = matlibre_id_somme_sinus(200, [0.1 0.5]);

  Voir aussi IDINPUT.
```

## `matlibre_id_sous_espaces`

```
MATLIBRE_ID_SOUS_ESPACES Matrices A et C par projection de sous-espaces.
  [A,C] = MATLIBRE_ID_SOUS_ESPACES(Y,U,ORDRE,HORIZON) construit les
  matrices de Hankel du passé et de l'avenir, projette l'avenir des
  sorties sur le passé le long de l'avenir des entrées, et lit A et C
  dans la décomposition en valeurs singulières du résultat.

  La projection le long des entrées futures est ce qui isole la part de
  l'avenir qui vient de l'état — c'est-à-dire du passé — de celle qui
  vient de l'entrée à venir. Sans elle, les deux se confondraient.

  C se lit dans le premier bloc de la matrice d'observabilité, et A dans
  le fait que cette matrice se répète décalée d'un bloc : c'est
  l'invariance par décalage.

  Exemple :
     [A, C] = matlibre_id_sous_espaces(y, u, 2, 6);

  Voir aussi N4SID, SSEST.
```

## `matlibre_id_squelette`

```
MATLIBRE_ID_SQUELETTE Modèle vide aux ordres donnés.
  M = MATLIBRE_ID_SQUELETTE([na nb nc nd nf nk],TS) rend un IDPOLY dont
  les polynômes ont la bonne longueur et des coefficients nuls : c'est
  la forme que l'estimation viendra remplir.

  Exemple :
     m = matlibre_id_squelette([1 1 0 0 0 1], 0.1);
     numel(m.B)      % 2

  Voir aussi POLYEST, MATLIBRE_ID_POSER_PARAMETRES.
```

## `matlibre_id_tracer`

```
MATLIBRE_ID_TRACER Trace les sorties puis les entrées d'un jeu.
  H = MATLIBRE_ID_TRACER(OBJ,ARGUMENTS) empile les voies : les sorties
  au-dessus, les entrées au-dessous, sur le même axe des temps.

  Exemple :
     plot(iddata((1:10)', (1:10)'));

  Voir aussi IDDATA.
```

## `matlibre_id_tracer_comparaison`

```
MATLIBRE_ID_TRACER_COMPARAISON Superpose mesures et sortie du modèle.
  MATLIBRE_ID_TRACER_COMPARAISON(JEU,PREDICTION,AJUSTEMENT) trace les
  deux courbes et annonce l'ajustement dans le titre.

  Exemple :
     compare(m, z);

  Voir aussi COMPARE.
```

## `matlibre_id_tracer_frequentiel`

```
MATLIBRE_ID_TRACER_FREQUENTIEL Diagramme de Bode d'une réponse mesurée.
  MATLIBRE_ID_TRACER_FREQUENTIEL(F,A,P) trace l'amplitude en décibels et
  la phase en degrés, sur une échelle logarithmique des fréquences.

  Exemple :
     bode(spa(z));

  Voir aussi IDFRD, SPA, ETFE.
```

## `matlibre_id_tracer_residus`

```
MATLIBRE_ID_TRACER_RESIDUS Trace l'analyse des résidus.
  MATLIBRE_ID_TRACER_RESIDUS(AUTO,CROISEE,SEUIL,DECALAGE) montre
  l'autocorrélation puis la corrélation croisée, avec le seuil de
  confiance : ce qui en sort n'est pas du hasard.

  Exemple :
     resid(m, z);

  Voir aussi RESID.
```

## `matlibre_id_variables_instrumentales`

```
MATLIBRE_ID_VARIABLES_INSTRUMENTALES Une passe de variables instrumentales.
  THETA = MATLIBRE_ID_VARIABLES_INSTRUMENTALES(Y,U,INSTRUMENT,ORDRES)
  résout Z'Phi theta = Z'Y, où Phi porte les régresseurs et Z les
  instruments — les mêmes régresseurs, mais construits sur une sortie
  simulée, donc sans bruit.

  Exemple :
     theta = matlibre_id_variables_instrumentales(y, u, x, [1 1 0 0 0 1]);

  Voir aussi IV4, ARX.
```

## `matlibre_id_voies`

```
MATLIBRE_ID_VOIES Nombre de voies d'un jeu de données.
  N = MATLIBRE_ID_VOIES(D) rend le nombre de colonnes, zéro si le jeu
  est vide.

  Exemple :
     matlibre_id_voies(zeros(10, 2))      % 2

  Voir aussi IDDATA.
```

## `n4sid`

```
N4SID Identification d'un modèle d'état par sous-espaces.
  M = N4SID(Z,N) estime un modèle d'état d'ordre N sans itération ni
  point de départ : la structure du modèle se lit dans la géométrie des
  données.

  Le principe : ranger les mesures en matrices de Hankel — le passé
  d'un côté, l'avenir de l'autre —, projeter l'avenir sur le passé le
  long des entrées futures, et décomposer le résultat en valeurs
  singulières. Le rang de cette projection est l'ordre du système, et
  ses vecteurs propres portent la matrice d'observabilité, d'où A et C
  se lisent par décalage. B, D et l'état initial s'obtiennent ensuite
  par moindres carrés, le problème étant linéaire en eux.

  M = N4SID(Z,'best') essaie les ordres de un à dix et garde celui dont
  le critère d'erreur finale de prédiction est le plus petit.

  Options : 'Horizon' (le nombre de blocs de Hankel, par défaut deux
  fois l'ordre plus deux).

  Exemple :
     rng(1);
     u = sign(randn(400, 1));
     y = filter([0 0.5 0.2], [1 -1.2 0.4], u);
     m = n4sid(iddata(y, u), 2);
     sort(abs(eig(m.A)))      % les modules des poles vrais

  Voir aussi SSEST, IDSS, ARX, TFEST.
```

## `oe`

```
OE Estimation d'un modèle sortie-erreur.
  M = OE(Z,[nb nf nk]) ajuste

     y(t) = [B(q)/F(q)] u(t-nk) + e(t)

  Le bruit s'ajoute à la sortie sans passer par la dynamique : le modèle
  ne décrit donc que la relation de l'entrée à la sortie, et il la décrit
  sans biais quel que soit le bruit — c'est sa vertu. En revanche il ne
  dit rien de la couleur de ce bruit, et sa prédiction à un pas n'utilise
  pas les sorties passées.

  Exemple :
     rng(2);
     u = sign(randn(600, 1));
     y = filter([0 0.5], [1 -0.8], u) + 0.1 * randn(600, 1);
     m = oe(iddata(y, u), [1 1 1]);
     m.F      % environ 1 -0.8

  Voir aussi ARX, ARMAX, BJ, POLYEST, TFEST.
```

## `pem`

```
PEM Estimation par minimisation de l'erreur de prédiction.
  M = PEM(Z,M0) affine le modèle M0 sur les données Z, quelle que soit
  sa famille : polynomiale ou d'état.
  M = PEM(Z,[na nb nc nd nf nk]) estime un modèle polynomial de ces
  ordres, comme POLYEST.
  M = PEM(Z,N) estime un modèle d'état d'ordre N, comme SSEST.

  Toutes les méthodes d'estimation de cette boîte à outils reviennent à
  la même idée : chercher le modèle qui rend l'erreur de prédiction la
  plus petite. Elles ne diffèrent que par la famille où l'on cherche et
  par la façon de démarrer.

  Exemple :
     m = pem(z, [2 2 2 0 0 1]);

  Voir aussi POLYEST, SSEST, ARX, ARMAX, OE, BJ.
```

## `polyest`

```
POLYEST Estimation d'un modèle polynomial quelconque.
  M = POLYEST(Z,[na nb nc nd nf nk]) ajuste

     A(q) y(t) = [B(q)/F(q)] u(t-nk) + [C(q)/D(q)] e(t)

  en minimisant la somme des carrés de l'erreur de prédiction à un pas.
  Toutes les familles usuelles en sont des cas particuliers, et ARX,
  ARMAX, OE et BJ ne font qu'appeler POLYEST avec les ordres qui les
  définissent.

  Sauf pour ARX, le critère n'est pas quadratique en les paramètres : il
  a plusieurs minimums, et la descente trouve celui dont elle part. Le
  point de départ est donc tiré d'une estimation ARX préalable, qui, elle,
  est exacte — et non d'un tirage au sort.

  Options : 'MaxIter' (200) et 'Tolerance' (1e-10).

  Exemple :
     m = polyest(z, [2 2 1 0 0 1]);      % un ARMAX

  Voir aussi ARX, ARMAX, OE, BJ, PEM, IDPOLY.
```

## `predictArx`

```
PREDICTARX Prédiction à un pas d'un modèle ARX.
```

## `procest`

```
PROCEST Estimation d'un modèle de procédé.
  M = PROCEST(Z,TYPE) ajuste un modèle décrit par ses constantes de
  temps : 'P1' un premier ordre, 'P2' un second, la lettre 'D' ajoutant
  un retard, 'Z' un zéro, 'I' un intégrateur.

  L'ajustement minimise l'erreur de simulation. Le point de départ vient
  d'une estimation par fonction de transfert, dont on lit le gain
  statique et les constantes de temps : partir de valeurs quelconques
  ferait tomber la descente dans un minimum local, le retard étant
  particulièrement mal conditionné.

  Exemple :
     rng(1);
     t = (0:0.2:60)';
     u = double(t > 5);
     vrai = idproc('P1D', 'K', 2, 'Tp1', 4, 'Td', 1);
     z = sim(vrai, iddata([], u, 0.2));
     m = procest(iddata(z.y, u, 0.2), 'P1D');
     [m.K, m.Tp1, m.Td]      % environ 2, 4, 1

  Voir aussi IDPROC, TFEST, SSEST.
```

## `spa`

```
SPA Analyse spectrale de la réponse fréquentielle.
  G = SPA(Z) estime la réponse fréquentielle par le rapport du
  spectre croisé entrée-sortie au spectre de l'entrée :

     G(w) = Phi_yu(w) / Phi_u(w)

  Les spectres sont obtenus en pondérant les covariances par une fenêtre
  de Hann avant de les transformer. C'est la méthode de Blackman et
  Tukey : tronquer les covariances aux petits décalages écarte le bruit,
  qui s'y accumule faute de moyenne, au prix d'une résolution
  fréquentielle limitée par la largeur de la fenêtre.

  G = SPA(Z,M) impose cette largeur ; G = SPA(Z,M,W) les pulsations.

  Exemple :
     g = spa(z, 40);
     bode(g);

  Voir aussi ETFE, IDFRD, TFEST.
```

## `ssest`

```
SSEST Estimation d'un modèle d'état par erreur de prédiction.
  M = SSEST(Z,N) estime un modèle d'état d'ordre N. Le point de départ
  vient de N4SID — qui, lui, n'a besoin d'aucun départ —, puis les
  matrices sont affinées en minimisant l'erreur de simulation.

  Cette seconde étape vaut la peine quand le bruit n'est pas blanc en
  sortie : les méthodes par sous-espaces sont alors légèrement biaisées,
  là où la minimisation de l'erreur ne l'est pas.

  M = SSEST(Z,'best') choisit l'ordre par le critère d'erreur finale de
  prédiction.

  Options : 'MaxIter' (100).

  Exemple :
     m = ssest(z, 2);
     compare(m, z);

  Voir aussi N4SID, IDSS, POLYEST, TFEST.
```

## `tfest`

```
TFEST Estimation d'une fonction de transfert.
  M = TFEST(Z,NP) estime une fonction de transfert à NP pôles.
  M = TFEST(Z,NP,NZ) fixe aussi le nombre de zéros.
  M = TFEST(Z,NP,NZ,RETARD) impose le retard, en échantillons.

  L'estimation passe par un modèle sortie-erreur : c'est le même
  problème, écrit autrement, et il a l'avantage de ne pas biaiser le
  résultat quel que soit le bruit sur la sortie.

  TFEST(...,'Ts',0) rend un modèle à temps continu, obtenu du modèle
  discret par correspondance exacte du blocage d'ordre zéro.

  Exemple :
     rng(1);
     u = sign(randn(600, 1));
     y = filter([0 0.5], [1 -0.8], u) + 0.05 * randn(600, 1);
     m = tfest(iddata(y, u, 1), 1, 0);
     [num, den] = tfdata(m, 'v');

  Voir aussi OE, IDTF, SSEST, PROCEST.
```

