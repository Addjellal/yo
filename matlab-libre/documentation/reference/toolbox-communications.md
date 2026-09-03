# Toolbox `communications`

```
% Communications Toolbox — transmissions numériques et analogiques.
%
% Modulations numériques
%   pskmod, pskdemod    - Déplacement de phase
%   dpskmod, dpskdemod  - Déplacement de phase différentiel
%   qammod, qamdemod    - Amplitude en quadrature
%   pammod, pamdemod    - Amplitude d'impulsions
%   fskmod, fskdemod    - Déplacement de fréquence
%   mskmod, mskdemod    - Déplacement minimal, à phase continue
%   genqammod, genqamdemod - Constellation quelconque
%   modnorm             - Normalisation en puissance d'une constellation
%   bin2gray, gray2bin  - Numérotation de Gray
%
% Modulations analogiques
%   ammod, amdemod      - Amplitude
%   fmmod, fmdemod      - Fréquence
%   pmmod, pmdemod      - Phase
%
% Canaux et mesures
%   awgn                - Bruit blanc gaussien
%   bsc                 - Canal binaire symétrique
%   biterr, symerr      - Taux d'erreur binaire et symbole
%   berawgn, berfading  - Taux d'erreur théoriques, gaussien et Rayleigh
%   qfunc, qfuncinv     - Fonction Q et sa réciproque
%   convertSNR          - Conversions entre SNR, Eb/No et Es/No
%
% Codage convolutif
%   poly2trellis        - Treillis d'un codeur, depuis les polynômes
%   istrellis           - Vérification d'un treillis
%   convenc             - Codage
%   vitdec              - Décodage de Viterbi, décision dure ou souple
%
% Codes en blocs
%   hammgen             - Matrices d'un code de Hamming
%   cyclpoly, cyclgen   - Codes cycliques
%   gen2par             - Génératrice vers contrôle, et retour
%   syndtable           - Table de décodage par syndrome
%   encode, decode      - Codage et correction
%   bchgenpoly          - Générateur d'un code BCH
%   bchenc, bchdec      - Codage et décodage BCH
%   rsgenpoly           - Générateur d'un code de Reed-Solomon
%   rsenc, rsdec        - Codage et décodage de Reed-Solomon
%
% Corps de Galois
%   gf                  - Tableau d'éléments de GF(2^m), opérateurs compris
%   gfadd, gfsub        - Somme et différence de polynômes
%   gfmul, gfdiv        - Produit et quotient terme à terme
%   gfconv, gfdeconv    - Produit et division de polynômes
%   gftrunc             - Retrait des zéros de tête
%   gfprimck            - Irréductible ? primitif ?
%   gfprimdf, gfprimfd  - Polynôme primitif par défaut, recherche
%   gftable             - Table d'un corps d'extension
%   gfcosets, cosets    - Classes cyclotomiques
%   gfroots             - Racines dans une extension, polynômes minimaux
%   gfrank              - Rang d'une matrice sur un corps fini
%   gfweight            - Distance minimale d'un code linéaire
%   gffilter            - Filtrage dans un corps fini
%
% Entrelacement
%   intrlv, deintrlv    - Permutation donnée
%   randintrlv, randdeintrlv - Permutation pseudo-aléatoire reproductible
%   matintrlv, matdeintrlv   - Entrelacement matriciel
%
% Mise en forme et représentation
%   rcosdesign          - Racine de cosinus surélevé
%   eyediagram          - Diagramme de l'œil
%   scatterplot         - Constellation reçue
%
% Conversions de base
%   de2bi, bi2de        - Entiers et vecteurs de chiffres
%   dec2base, base2dec  - Changements de base
%   oct2dec, dec2oct    - Octal, pour les polynômes générateurs
%   vec2mat             - Découpage d'un vecteur en matrice
```

## `alignerPolynomes`

```
ALIGNERPOLYNOMES Complète de zéros le plus court de deux polynômes.
  Les coefficients étant rangés par puissances croissantes, compléter
  se fait à droite : on ajoute des termes de plus haut degré, nuls.

  Un scalaire est ici le polynôme constant, non un terme à répandre sur
  tous les autres : sans cela l'identité de la division euclidienne ne
  tiendrait pas, le reste étant souvent de degré zéro.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `alignerTermes`

```
ALIGNERTERMES Met deux tableaux à la même taille, terme à terme.
  À la différence d'ALIGNERPOLYNOMES, un scalaire se répand ici sur
  tout le tableau : c'est ce qu'attendent les opérations terme à terme,
  GFMUL et GFDIV, où l'on multiplie souvent tout un vecteur par une
  même valeur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `amdemod`

```
AMDEMOD Démodulation d'amplitude cohérente.
  X = AMDEMOD(Y,FC,FS) multiplie le signal reçu par la porteuse locale
  puis filtre : le produit de deux cosinus donne la somme cherchée et
  une composante au double de la fréquence, que le passe-bas retire.

  X = AMDEMOD(Y,FC,FS,PHI,A) retranche ensuite la porteuse d'amplitude A.
  X = AMDEMOD(Y,FC,FS,PHI,A,NUM,DEN) impose le filtre passe-bas ; par
  défaut c'est un Butterworth d'ordre cinq coupant à FC.

  Exemple :
     t = (0:999)' / 8000;
     m = sin(2*pi*50*t);
     max(abs(amdemod(ammod(m, 1000, 8000), 1000, 8000) - m))   % petit

  Voir aussi AMMOD, FMDEMOD, PMDEMOD.
```

## `ammod`

```
AMMOD Modulation d'amplitude.
  Y = AMMOD(X,FC,FS) module le signal X, échantillonné à FS, sur une
  porteuse de fréquence FC :

     y(t) = x(t) * cos(2 pi FC t)

  Y = AMMOD(X,FC,FS,PHI) décale la phase de la porteuse.
  Y = AMMOD(X,FC,FS,PHI,A) ajoute A au signal avant modulation : c'est
  la modulation avec porteuse, celle qu'un détecteur d'enveloppe sait
  démoduler sans référence de phase. A doit dépasser le maximum de |X|
  pour que l'enveloppe ne s'inverse pas.

  FS doit valoir au moins deux fois FC, sinon la porteuse se replie.

  Exemple :
     t = (0:999)' / 8000;
     y = ammod(sin(2*pi*50*t), 1000, 8000);

  Voir aussi AMDEMOD, FMMOD, PMMOD.
```

## `awgn`

```
AWGN Ajoute un bruit blanc gaussien pour atteindre un rapport donné.
  Y = AWGN(X,SNR) ajoute du bruit tel que le rapport signal sur bruit
  vaille SNR décibels, la puissance du signal étant mesurée sur X.
```

## `base2dec`

```
BASE2DEC Chaîne dans une base quelconque vers entier.
```

## `bchdec`

```
BCHDEC Décodage BCH.
  MSG = BCHDEC(CODE,N,K) décode le tableau CODE, de N colonnes, en
  messages de K colonnes. Les erreurs, jusqu'à la capacité du code,
  sont corrigées.

  [MSG,NERR] = BCHDEC(...) rend le nombre d'erreurs corrigées par mot ;
  il vaut -1 quand le décodage a échoué, le mot reçu étant trop loin de
  tout mot de code.
  [MSG,NERR,CODECORRIGE] = BCHDEC(...) rend aussi le mot corrigé.
  BCHDEC(...,'end'|'beg'|'none') dit où le message se trouve dans le
  mot, comme pour BCHENC.

  Le décodage suit les trois étapes classiques : les syndromes, que le
  mot reçu donne en l'évaluant aux racines du générateur ; le polynôme
  localisateur d'erreurs, trouvé par l'algorithme de Berlekamp et
  Massey ; et la recherche de Chien, qui essaie toutes les positions.

  Exemple :
     msg = gf([1 0 1 1 0 0 1], 1);
     code = bchenc(msg, 15, 7);
     recu = code;
     recu(3) = recu(3) + 1;         % une erreur
     [sortie, nerr] = bchdec(recu, 15, 7);
     nerr                           % 1
     isequal(double(sortie), double(msg))   % vrai

  Voir aussi BCHENC, BCHGENPOLY, RSDEC, DECODE.
```

## `bchenc`

```
BCHENC Codage BCH.
  CODE = BCHENC(MSG,N,K) code le message MSG, tableau de corps GF(2) à
  K colonnes, en un code BCH de longueur N. Chaque ligne est un mot :
  CODE a N colonnes.

  Le codage est systématique : le message se retrouve tel quel dans les
  K dernières colonnes, précédé des N-K bits de contrôle. C'est ce qui
  permet de lire le message sans décoder quand la transmission s'est
  bien passée.

  CODE = BCHENC(MSG,N,K,'end') est cette forme ; 'beg' met le message
  en tête, 'none' ne le sépare pas — le mot est alors le produit du
  message par le générateur.

  Exemple :
     msg = gf([1 0 1 1 0 0 1], 1);
     code = bchenc(msg, 15, 7);
     isequal(double(code(9:15)), double(msg))   % vrai : systématique

  Voir aussi BCHDEC, BCHGENPOLY, RSENC, ENCODE.
```

## `bchgenpoly`

```
BCHGENPOLY Polynôme générateur d'un code BCH.
  GENPOLY = BCHGENPOLY(N,K) rend le polynôme générateur du code BCH de
  longueur N et de dimension K, sous forme d'un tableau GF(2) dont les
  coefficients vont par puissances décroissantes — la convention de
  MATLAB pour cette fonction.

  N doit valoir 2^M - 1 pour un M entre 3 et 16, et K être une
  dimension admissible pour cette longueur.

  GENPOLY = BCHGENPOLY(N,K,PRIM) emploie le polynôme primitif PRIM.
  [GENPOLY,T] = BCHGENPOLY(...) rend en outre la capacité de
  correction : le code corrige T erreurs.
  BCHGENPOLY(...,'double') rend les coefficients en nombres ordinaires
  plutôt qu'en tableau de corps.

  Le générateur est le plus petit commun multiple des polynômes
  minimaux de alpha, alpha^2, ..., alpha^(2T) : annuler ces racines
  force la distance minimale à 2T+1.

  Exemple :
     [g, t] = bchgenpoly(15, 5);
     t                              % 3 : le code corrige trois erreurs
     numel(g.x) - 1                 % 10 = 15 - 5

  Voir aussi BCHENC, BCHDEC, RSGENPOLY, GFPRIMDF, GFROOTS.
```

## `berawgn`

```
BERAWGN Taux d'erreur binaire théorique sur canal gaussien.
  BER = BERAWGN(EBNO,'psk',M) ou BERAWGN(EBNO,'qam',M).
```

## `berfading`

```
BERFADING Taux d'erreur binaire théorique sur canal de Rayleigh.
  BER = BERFADING(EBNO,'psk',M,L) rend le taux d'erreur binaire d'une
  modulation de phase à M états sur un canal à évanouissements de
  Rayleigh, avec une diversité d'ordre L combinée à gain maximal. EBNO
  est le rapport moyen par branche, en décibels.

  Pour la modulation à deux états, la formule est close :

     p  = (1 - sqrt(g/(1+g))) / 2,   g = 10^(EBNO/10)
     Pb = p^L * somme_{k=0}^{L-1} C(L-1+k,k) (1-p)^k

  Pour les autres ordres, le taux gaussien est moyenné sur la loi du
  rapport signal sur bruit combiné, qui suit une loi gamma de forme L
  et d'échelle g.

  La différence avec le canal gaussien est spectaculaire : là où
  BERAWGN décroît exponentiellement, BERFADING décroît en 1/EbNo à la
  puissance L. C'est tout l'intérêt de la diversité.

  Exemple :
     berfading(10, 'psk', 2, 1)   % 0.0233
     berfading(10, 'psk', 2, 2)   % 0.0016

  Voir aussi BERAWGN, AWGN.
```

## `bi2de`

```
BI2DE Vecteurs de chiffres vers entiers.
  D = BI2DE(B) lit chaque ligne de B comme un nombre binaire, poids
  faible en tête. D = BI2DE(B,BASE) change de base.
  D = BI2DE(B,BASE,'left-msb') lit le poids fort en tête.

  Exemple :
     bi2de([0 1 1 0])                 % 6
     bi2de([1 0 0 0], 2, 'left-msb')  % 8

  Voir aussi DE2BI, BIN2DEC.
```

## `bin2gray`

```
BIN2GRAY Numérotation binaire vers numérotation de Gray.
  Y = BIN2GRAY(X,MODULATION,M) renumérote les symboles pour que deux
  points voisins de la constellation ne diffèrent que d'un bit.
  MODULATION vaut 'psk', 'dpsk', 'pam', 'fsk' ou 'qam'.

  Pour les constellations à une dimension, la transformation est
  Y = bitxor(X, floor(X/2)). Pour 'qam', elle s'applique séparément aux
  deux coordonnées de la constellation carrée.

  [Y,MAP] = BIN2GRAY(...) rend aussi la table complète.

  Exemple :
     bin2gray(0:7, 'psk', 8)   % [0 1 3 2 6 7 5 4]

  Voir aussi GRAY2BIN, PAMMOD, QAMMOD.
```

## `biterr`

```
BITERR Nombre et taux d'erreurs binaires entre deux suites d'entiers.
```

## `bsc`

```
BSC Canal binaire symétrique.
  Y = BSC(DONNEES,P) inverse chaque bit avec la probabilité P,
  indépendamment des autres. C'est le canal le plus simple qui soit, et
  le modèle sur lequel se calculent les capacités des codes en blocs.

  [Y,ERREURS] = BSC(...) rend aussi le motif d'erreur, qui vaut un aux
  positions inversées.

  Exemple :
     rng(1); [y, e] = bsc(zeros(1, 1000), 0.1);
     sum(e) / 1000   % voisin de 0.1

  Voir aussi AWGN, BITERR.
```

## `completerLongueur`

```
COMPLETERLONGUEUR Complète un polynôme de zéros, ou le tronque.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `convenc`

```
CONVENC Codage convolutif.
  CODE = CONVENC(MESSAGE,TRELLIS) code MESSAGE, vecteur de bits, avec le
  treillis rendu par POLY2TRELLIS. Le message est lu par groupes de K
  bits et chaque groupe produit N bits de sortie.

  [CODE,ETATFINAL] = CONVENC(MESSAGE,TRELLIS,ETATINITIAL) part d'un état
  donné et rend l'état atteint : c'est ce qu'il faut pour coder un long
  message par morceaux.

  CODE = CONVENC(MESSAGE,GENERATEURS,CONTRAINTE) accepte aussi la forme
  directe, GENERATEURS étant un vecteur de polynômes en octal, par
  exemple [7 5] pour le rendement 1/2 de longueur de contrainte 3.

  Exemple :
     convenc([1 0 1 1], poly2trellis(3, [7 5]))
     % [1 1 1 0 0 0 0 1]

  Voir aussi VITDEC, POLY2TRELLIS, ISTRELLIS.
```

## `convertSNR`

```
CONVERTSNR Conversion entre les trois mesures de rapport signal sur bruit.
  Y = CONVERTSNR(X,DEPUIS,VERS) convertit entre 'snr', 'ebno' et
  'esno', tous en décibels. Les relations sont

     EsNo = EbNo + 10 log10(k R)
     SNR  = EsNo - 10 log10(NSAMP)

  où k est le nombre de bits par symbole, R le rendement du codage et
  NSAMP le nombre d'échantillons par symbole.

  Y = CONVERTSNR(...,'BitsPerSymbol',K,'SamplesPerSymbol',NSAMP,
  'CodingRate',R) fixe ces trois paramètres, qui valent par défaut 1, 1
  et 1.

  Exemple :
     convertSNR(10, 'ebno', 'snr', 'BitsPerSymbol', 4)   % 16.0206

  Voir aussi AWGN, BERAWGN.
```

## `cosets`

```
COSETS Classes cyclotomiques de GF(2^M), rangées par classe.
  C = COSETS(M) rend une cellule : chaque case porte les exposants
  d'une classe cyclotomique de GF(2^M), la première étant celle de
  l'élément un.

  MATLAB rend les éléments eux-mêmes, sous forme d'un tableau de corps
  de Galois ; MatLibre rend leurs exposants, la table du corps se
  lisant par GFTABLE.

  Exemple :
     c = cosets(3);
     numel(c)                       % 3 classes
     c{2}                           % [1 2 4]

  Voir aussi GFCOSETS, GFTABLE, GFPRIMDF, GFROOTS.
```

## `cyclgen`

```
CYCLGEN Matrices d'un code cyclique.
  [PARMAT,GENMAT,K] = CYCLGEN(N,POL) rend la matrice de contrôle et la
  matrice génératrice, sous forme systématique, du code cyclique de
  longueur N engendré par POL, donné par puissances croissantes.

  La construction est directe : la ligne i de la génératrice code le
  mot x^(N-i), corrigé de son reste modulo POL pour que le résultat soit
  divisible. Les K premières colonnes forment donc l'identité, et le
  message se lit tel quel dans le mot de code.

  Exemple :
     [h, g, k] = cyclgen(7, cyclpoly(7, 4));
     k                                  % 4
     max(max(mod(g * h', 2)))           % nul

  Voir aussi CYCLPOLY, HAMMGEN, GEN2PAR.
```

## `cyclpoly`

```
CYCLPOLY Polynômes générateurs des codes cycliques.
  POL = CYCLPOLY(N,K) rend un polynôme générateur d'un code cyclique
  [N,K] : un diviseur de x^N - 1 sur GF(2), de degré N-K, écrit par
  puissances croissantes. Par défaut c'est celui qui a le moins de
  termes non nuls, donc le codeur le plus simple.

  CYCLPOLY(N,K,'max') rend celui qui en a le plus, CYCLPOLY(N,K,'all')
  les rend tous, une ligne par polynôme, et CYCLPOLY(N,K,W) ceux qui
  ont exactement W termes non nuls.

  Exemple :
     cyclpoly(7, 4)   % [1 1 0 1] : 1 + x + x^3

  Voir aussi CYCLGEN, HAMMGEN, GEN2PAR.
```

## `de2bi`

```
DE2BI Entiers vers vecteurs de chiffres.
  B = DE2BI(D) rend, une ligne par élément de D, les chiffres binaires
  avec le poids faible en tête. B = DE2BI(D,N) fixe le nombre de
  colonnes, B = DE2BI(D,N,BASE) change de base.

  B = DE2BI(D,N,BASE,'left-msb') met le poids fort en tête ;
  'right-msb' est le comportement par défaut. Les deux conventions
  coexistent parce que les codes correcteurs écrivent les polynômes par
  puissances croissantes, et les modulateurs les symboles par poids
  décroissants.

  Exemple :
     de2bi(5, 4)                 % [1 0 1 0]
     de2bi(5, 4, 2, 'left-msb')  % [0 1 0 1]

  Voir aussi BI2DE, DEC2BIN.
```

## `dec2base`

```
DEC2BASE Entier vers chaîne dans une base quelconque.
```

## `dec2oct`

```
DEC2OCT Écriture octale d'un nombre décimal, rendue comme un nombre.
  O = DEC2OCT(D) rend le nombre dont les chiffres décimaux sont les
  chiffres octaux de D : 15 devient 17.

  Exemple :
     dec2oct([121 91])   % [171 133]

  Voir aussi OCT2DEC, POLY2TRELLIS.
```

## `decode`

```
DECODE Décodage en blocs linéaires, avec correction d'une erreur.
  [MSG,ERR] = DECODE(CODE,N,K,'hamming/fmt') corrige une erreur par
  bloc grâce au syndrome, puis extrait les K bits d'information.

  Exemple :
     c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
     c(3) = 1 - c(3);
     isequal(decode(c, 7, 4, 'hamming/fmt'), [1 0 1 1])   % vrai
```

## `deintrlv`

```
DEINTRLV Désentrelacement, réciproque de INTRLV.
  Y = DEINTRLV(DONNEES,PERMUTATION) remet chaque élément à sa place :
  Y(PERMUTATION(k)) = DONNEES(k).

  Exemple :
     deintrlv(intrlv([10 20 30 40], [3 1 4 2]), [3 1 4 2])   % inchangé

  Voir aussi INTRLV, RANDDEINTRLV, MATDEINTRLV.
```

## `dpskdemod`

```
DPSKDEMOD Démodulation par déplacement de phase différentiel.
```

## `dpskmod`

```
DPSKMOD Modulation par déplacement de phase différentiel.
  Y = DPSKMOD(X,M) code l'information dans la différence de phase entre
  deux symboles consécutifs : le récepteur n'a pas besoin de connaître
  la phase absolue.

  Exemple :
     y = dpskmod([0 1 0], 2);   % [1 -1 -1] : la phase bascule au 1
```

## `encode`

```
ENCODE Codage en blocs linéaires.
  CODE = ENCODE(MSG,N,K,'linear/fmt',G) multiplie chaque bloc de K bits
  par la matrice génératrice, modulo 2.
  CODE = ENCODE(MSG,N,K,'hamming/fmt') utilise le code de Hamming.

  Exemple :
     c = encode([1 0 1 1], 7, 4, 'hamming/fmt');
```

## `exigerPremier`

```
EXIGERPREMIER Refuse un ordre de corps qui n'est pas premier.
  Les corps de Galois d'ordre non premier se construisent par extension
  et ne se réduisent pas à l'arithmétique modulaire : accepter un p
  composé donnerait des résultats faux sans le dire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `eyediagram`

```
EYEDIAGRAM Découpe un signal en segments de N échantillons.
  SEGMENTS = EYEDIAGRAM(X,N) rend une matrice dont chaque ligne est une
  trace ; sans sortie, la fonction les trace superposées.
```

## `fmdemod`

```
FMDEMOD Démodulation de fréquence.
  X = FMDEMOD(Y,FC,FS,DEV) retrouve le signal modulant en dérivant la
  phase instantanée. Celle-ci s'obtient par le signal analytique que
  rend HILBERT : on retire la rampe de la porteuse, on déroule la
  phase, puis on dérive.

  Exemple :
     t = (0:1999)' / 10000;
     m = sin(2*pi*30*t);
     max(abs(fmdemod(fmmod(m, 1000, 10000, 200), 1000, 10000, 200) - m))

  Voir aussi FMMOD, AMDEMOD, PMDEMOD.
```

## `fmmod`

```
FMMOD Modulation de fréquence.
  Y = FMMOD(X,FC,FS,DEV) fait varier la fréquence instantanée de la
  porteuse proportionnellement au signal :

     y(t) = cos(2 pi FC t + 2 pi DEV integrale de x)

  DEV est l'excursion en hertz par unité d'amplitude de X.
  Y = FMMOD(X,FC,FS,DEV,PHI) décale la phase initiale.

  Exemple :
     t = (0:1999)' / 10000;
     y = fmmod(sin(2*pi*30*t), 1000, 10000, 200);

  Voir aussi FMDEMOD, AMMOD, PMMOD.
```

## `fskdemod`

```
FSKDEMOD Démodulation par déplacement de fréquence, par corrélation.
```

## `fskmod`

```
FSKMOD Modulation par déplacement de fréquence.
  Y = FSKMOD(X,M,ECART,NECH,FS) : chaque symbole devient NECH
  échantillons d'une sinusoïde dont la fréquence dépend du symbole.

  Exemple :
     y = fskmod([0 1], 2, 100, 8, 1000);   % 16 échantillons
```

## `gen2par`

```
GEN2PAR Passage entre matrice génératrice et matrice de contrôle.
  PAR = GEN2PAR(GEN) où GEN = [I_k P] rend PAR = [P' I_(n-k)].
  GEN = GEN2PAR(PAR) fait le chemin inverse.

  La relation vient de ce que GEN*PAR' doit être nulle modulo deux :
  tout mot de code est orthogonal à toutes les lignes de contrôle.

  Exemple :
     [h, g] = hammgen(3);
     max(max(mod(gen2par(g) - h, 2)))   % nul

  Voir aussi HAMMGEN, CYCLGEN, SYNDTABLE.
```

## `genqamdemod`

```
GENQAMDEMOD Démodulation sur une constellation quelconque.
  X = GENQAMDEMOD(Y,CONST) rend, pour chaque échantillon, l'indice du
  point de CONST le plus proche au sens de la distance euclidienne.
  C'est le décodage à maximum de vraisemblance sur canal gaussien.

  Exemple :
     c = [1, 1i, -1, -1i];
     genqamdemod([0.9+0.1i, -0.2+1.1i], c)   % [0 1]

  Voir aussi GENQAMMOD, QAMDEMOD.
```

## `genqammod`

```
GENQAMMOD Modulation sur une constellation quelconque.
  Y = GENQAMMOD(X,CONST) rend CONST(X+1) : X porte les indices, à partir
  de zéro, des points de la constellation. C'est la forme générale dont
  QAMMOD, PSKMOD et PAMMOD sont des cas particuliers, et elle permet les
  constellations irrégulières — APSK, en croix, ou optimisées.

  Exemple :
     c = [1, 1i, -1, -1i];
     genqammod([0 1 2 3], c)   % [1 1i -1 -1i]

  Voir aussi GENQAMDEMOD, QAMMOD, MODNORM.
```

## `gf`

```
GF Tableau d'éléments d'un corps de Galois.
  X = GF(V) range les valeurs V dans GF(2) : chacune vaut zéro ou un.
  X = GF(V,M) les range dans GF(2^M), les valeurs allant de 0 à 2^M-1.
  X = GF(V,M,PRIM) emploie le polynôme primitif PRIM, donné comme
  entier — sa forme binaire, poids fort en tête —, au lieu du défaut
  de GFPRIMDF.

  Les opérations ordinaires s'appliquent : +, -, .*, ./, .^, * et ^ y
  travaillent dans le corps. L'addition y est le ou exclusif, si bien
  qu'ajouter deux fois la même chose ne change rien ; la
  multiplication passe par les logarithmes discrets.

  Un tableau de corps ne se mélange pas à un autre d'ordre différent :
  l'opération est refusée plutôt que faite dans le mauvais corps.

  Exemple :
     a = gf([1 2 3], 3);
     a + a                          % tous nuls : la caractéristique
                                    % vaut deux
     a .* a                         % les carrés dans GF(8)
     a ./ a                         % que des uns

  Voir aussi GFTABLE, GFPRIMDF, BCHENC, RSENC, GFADD.
```

## `gfadd`

```
GFADD Somme dans un corps de Galois.
  C = GFADD(A,B) additionne dans GF(2) : c'est le ou exclusif.
  C = GFADD(A,B,P) additionne dans GF(P), P premier : chaque terme est
  la somme modulo P.
  C = GFADD(A,B,P,LEN) complète le résultat de zéros jusqu'à LEN.

  Employée sur des vecteurs, elle additionne des polynômes écrits par
  puissances croissantes ; le plus court est complété de zéros.

  Dans un corps de Galois, l'addition est sa propre inverse quand P
  vaut deux : ajouter deux fois la même chose ne change rien.

  Exemple :
     gfadd([1 1 0 1], [1 0 1])      % [0 1 1 1] : dans GF(2)
     gfadd([2 3], [4 4], 5)         % [1 2]

  Voir aussi GFSUB, GFMUL, GFCONV, GFTRUNC.
```

## `gfconv`

```
GFCONV Produit de deux polynômes dans un corps de Galois.
  C = GFCONV(A,B,P) multiplie les polynômes A et B dans GF(P), P
  premier. Les coefficients sont rangés par puissances croissantes :
  A(1) est le terme constant.
  C = GFCONV(A,B) le fait dans GF(2).

  Le produit se calcule comme la convolution ordinaire, puis se réduit
  modulo P : c'est ce qui distingue le corps fini des réels.

  Exemple :
     gfconv([1 1], [1 1])           % [1 0 1] : (1+x)^2 = 1+x^2 dans GF(2)
     gfconv([1 1], [1 1], 3)        % [1 2 1]

  Voir aussi GFDECONV, GFMUL, GFADD, GFTRUNC.
```

## `gfcosets`

```
GFCOSETS Classes cyclotomiques d'un corps de Galois.
  C = GFCOSETS(M) rend les classes cyclotomiques de GF(2^M) : une ligne
  par classe, complétée de NaN. La classe d'un exposant K est
  l'ensemble des K*P^J modulo P^M - 1, c'est-à-dire les exposants dont
  les éléments partagent le même polynôme minimal.

  C = GFCOSETS(M,P) le fait pour GF(P^M).

  Ces classes commandent la construction des codes cycliques : le
  polynôme générateur d'un BCH est le produit des polynômes minimaux
  des classes qu'on veut annuler.

  Exemple :
     gfcosets(3)
     % [0 NaN NaN; 1 2 4; 3 6 5]

  Voir aussi COSETS, GFPRIMDF, GFTABLE, GFROOTS.
```

## `gfdeconv`

```
GFDECONV Division de deux polynômes dans un corps de Galois.
  [Q,R] = GFDECONV(A,B,P) divise le polynôme A par B dans GF(P), P
  premier : A = GFADD(GFCONV(Q,B,P),R,P), le degré de R étant plus
  petit que celui de B. Les coefficients vont par puissances
  croissantes.
  [Q,R] = GFDECONV(A,B) le fait dans GF(2).

  La division est possible parce que tout coefficient non nul d'un
  corps a un inverse : c'est lui qui sert de pivot à chaque étape.

  Exemple :
     [q, r] = gfdeconv([1 0 1], [1 1]);   % q = [1 1], r = 0
     gfconv(q, [1 1])                     % [1 0 1] : on retombe sur A

  Voir aussi GFCONV, GFDIV, GFADD, GFTRUNC.
```

## `gfdiv`

```
GFDIV Quotient terme à terme dans un corps de Galois.
  C = GFDIV(A,B,P) divise élément par élément dans GF(P), P premier :
  chaque terme est multiplié par l'inverse modulaire du diviseur.
  [C,VALIDE] = GFDIV(...) rend un booléen par terme, faux là où le
  diviseur est nul ; C y vaut -1, comme dans MATLAB.

  Tout élément non nul d'un corps a un inverse : c'est ce qui
  distingue un corps d'un anneau, et ce qui rend la division possible.

  Exemple :
     gfdiv([1 4 2], [3 3 3], 5)     % [2 3 4]
     gfdiv(1, 0, 5)                 % -1 : pas d'inverse de zéro

  Voir aussi GFMUL, GFDECONV, GFADD, GFSUB.
```

## `gffilter`

```
GFFILTER Filtrage dans un corps de Galois.
  Y = GFFILTER(B,A,X,P) filtre le signal X par le filtre de
  coefficients B et A dans GF(P), P premier :

     A(1) Y(n) = B(1)X(n) + ... + B(k)X(n-k+1)
                 - A(2)Y(n-1) - ... - A(m)Y(n-m+1),

  toutes les opérations se faisant modulo P. Les coefficients vont par
  puissances croissantes, comme partout dans la famille GF.
  Y = GFFILTER(B,A,X) travaille dans GF(2).

  C'est le rouage des registres à décalage bouclés : un filtre à
  réaction dans GF(2) engendre une suite pseudo-aléatoire, de période
  maximale quand A est primitif.

  Exemple :
     % Registre de trois cellules, bouclé par 1+x+x^3 : la suite
     % engendrée est de période sept.
     y = gffilter(1, [1 1 0 1], [1 zeros(1, 13)]);
     isequal(y(1:7), y(8:14))       % vrai

  Voir aussi GFCONV, GFDECONV, GFPRIMDF, FILTER.
```

## `gfmul`

```
GFMUL Produit terme à terme dans un corps de Galois.
  C = GFMUL(A,B,P) multiplie élément par élément dans GF(P), P premier.
  C = GFMUL(A,B) le fait dans GF(2), où c'est le et logique.

  Ce n'est pas le produit de polynômes : celui-là est GFCONV.

  Exemple :
     gfmul([2 3 4], [3 3 3], 5)     % [1 4 2]
     gfmul([1 0 1], [1 1 0])        % [1 0 0]

  Voir aussi GFDIV, GFCONV, GFADD, GFDECONV.
```

## `gfprimck`

```
GFPRIMCK Nature d'un polynôme sur un corps de Galois.
  CK = GFPRIMCK(A) examine le polynôme A, écrit par puissances
  croissantes, sur GF(2) ; GFPRIMCK(A,P) le fait sur GF(P).

  CK vaut :
    -1  A n'est pas irréductible
     0  A est irréductible, mais pas primitif
     1  A est primitif

  Un polynôme de degré M est primitif quand x engendre, par ses
  puissances, tous les P^M - 1 éléments non nuls du corps qu'il
  définit : c'est ce qui permet d'indexer le corps par un exposant.
  Tout primitif est irréductible, la réciproque étant fausse.

  Exemple :
     gfprimck([1 1 0 0 1])          % 1 : 1 + x + x^4 est primitif
     gfprimck([1 1 1 1 1])          % 0 : irréductible, non primitif
     gfprimck([1 0 1])              % -1 : (1+x)^2 dans GF(2)

  Voir aussi GFPRIMDF, GFPRIMFD, GFCONV, GFDECONV.
```

## `gfprimdf`

```
GFPRIMDF Polynôme primitif par défaut d'un corps de Galois.
  POL = GFPRIMDF(M) rend le polynôme primitif de degré M que MatLibre
  emploie par défaut pour GF(2^M) ; GFPRIMDF(M,P) le fait pour GF(P^M).
  Les coefficients vont par puissances croissantes.

  C'est le premier primitif dans l'ordre des codes croissants : 1+x
  pour M = 1, puis 1+x+x^2, 1+x+x^3, 1+x+x^4, 1+x^2+x^5, 1+x+x^6,
  1+x+x^7, 1+x^2+x^3+x^4+x^8.

  MATLAB lit les siens dans une table, qui coïncide avec cette
  recherche partout sauf au degré sept, où il retient 1+x^3+x^7 quand
  celle-ci trouve d'abord 1+x+x^7 — les deux étant primitifs. Le choix
  du polynôme change la représentation du corps : pour que deux calculs
  se comparent, donnez-le explicitement plutôt que de vous fier au
  défaut.

  Exemple :
     gfprimdf(3)                    % [1 1 0 1]
     gfprimck(gfprimdf(8))          % 1

  Voir aussi GFPRIMFD, GFPRIMCK, GFCOSETS.
```

## `gfprimfd`

```
GFPRIMFD Recherche de polynômes primitifs.
  POL = GFPRIMFD(M) rend le premier polynôme primitif de degré M sur
  GF(2), coefficients par puissances croissantes.
  POL = GFPRIMFD(M,OPT,P) cherche sur GF(P). OPT vaut :
    'min'  le premier trouvé, dans l'ordre des codes croissants (défaut)
    'max'  le dernier
    'all'  tous, une ligne par polynôme
    un entier N : le N-ième

  La recherche est exhaustive : on parcourt les polynômes unitaires de
  degré M et l'on garde ceux que GFPRIMCK déclare primitifs. Le nombre
  de primitifs de degré M sur GF(P) vaut phi(P^M - 1) / M.

  Exemple :
     gfprimfd(4)                    % [1 1 0 0 1]
     size(gfprimfd(5, 'all'), 1)    % 6

  Voir aussi GFPRIMDF, GFPRIMCK, GFCOSETS, GFROOTS.
```

## `gfrank`

```
GFRANK Rang d'une matrice sur un corps de Galois.
  R = GFRANK(A,P) rend le rang de A sur GF(P), P premier, par
  élimination de Gauss avec pivots dans le corps.
  R = GFRANK(A) le fait sur GF(2).

  Le rang d'un corps fini n'est pas celui des réels : une matrice
  inversible sur les réels peut être singulière modulo P, et
  réciproquement.

  Exemple :
     gfrank([1 1; 1 1])             % 1
     gfrank([1 0; 0 1])             % 2
     gfrank([2 4; 1 2], 5)          % 1 : la seconde ligne est la
                                    % première divisée par deux

  Voir aussi GFDIV, GFADD, GFWEIGHT, RANK.
```

## `gfroots`

```
GFROOTS Racines d'un polynôme dans un corps de Galois d'extension.
  R = GFROOTS(F,M,P) cherche les racines du polynôme F — coefficients
  par puissances croissantes, à valeurs dans GF(P) — parmi les éléments
  de GF(P^M). Les racines sont rendues sous forme d'exposants : la
  valeur K désigne l'élément x^K, et -Inf l'élément nul.

  R = GFROOTS(F,M) travaille sur GF(2^M) ; GFROOTS(F,PRIM,P) emploie le
  polynôme primitif PRIM au lieu du polynôme par défaut.

  [R,MIN] = GFROOTS(...) rend en outre, pour chaque racine, le polynôme
  minimal de la classe cyclotomique à laquelle elle appartient.

  Un polynôme de degré D a au plus D racines dans une extension ; il
  les a toutes dès que l'extension est assez grande.

  Exemple :
     gfroots([1 1 1], 2)            % [1; 2] : les deux éléments
                                    % d'ordre trois de GF(4)

  Voir aussi GFPRIMDF, GFTABLE, GFCOSETS, GFDECONV.
```

## `gfsub`

```
GFSUB Différence dans un corps de Galois.
  C = GFSUB(A,B) soustrait dans GF(2), où c'est la même chose
  qu'additionner.
  C = GFSUB(A,B,P) soustrait dans GF(P), P premier.
  C = GFSUB(A,B,P,LEN) complète le résultat de zéros jusqu'à LEN.

  Exemple :
     gfsub([1 1 0 1], [1 0 1])      % [0 1 1 1]
     gfsub([1 2], [4 4], 5)         % [2 3]

  Voir aussi GFADD, GFMUL, GFDIV, GFCONV.
```

## `gftable`

```
GFTABLE Table d'un corps de Galois d'extension.
  T = GFTABLE(M) rend la table de GF(2^M) : une ligne par élément, dans
  l'ordre des exposants. La ligne K donne les coefficients du polynôme
  qui représente x^(K-2), par puissances croissantes ; la première
  ligne est l'élément nul.

  T = GFTABLE(M,PRIM) emploie le polynôme primitif donné,
  GFTABLE(M,PRIM,P) travaille sur GF(P^M).

  C'est la table qui rend l'arithmétique du corps praticable :
  multiplier revient à additionner des exposants, et additionner à
  ajouter les polynômes lus dans la table. MATLAB range la sienne dans
  un fichier ; MatLibre la rend, ce qui évite un état caché.

  Exemple :
     t = gftable(3);
     size(t)                        % 8x3 : huit éléments de GF(8)
     t(2, :)                        % [1 0 0] : l'élément un

  Voir aussi GFPRIMDF, GFCOSETS, GFROOTS, GFADD.
```

## `gftrunc`

```
GFTRUNC Retire les zéros de tête d'un polynôme de corps de Galois.
  B = GFTRUNC(A) où A porte les coefficients par puissances
  croissantes : A(1) est le terme constant. Les zéros qui suivent le
  coefficient de plus haut degré non nul sont retirés, ce qui donne le
  degré réel du polynôme.

  Un polynôme entièrement nul est rendu comme le seul coefficient zéro.

  Exemple :
     gftrunc([1 0 1 0 0])           % [1 0 1]
     gftrunc([0 0 0])               % 0

  Voir aussi GFADD, GFCONV, GFDECONV, GFPRIMCK.
```

## `gfweight`

```
GFWEIGHT Distance minimale d'un code linéaire en bloc.
  D = GFWEIGHT(GEN) où GEN est la matrice génératrice d'un code
  binaire : D est le plus petit poids de Hamming d'un mot de code non
  nul. C'est aussi la distance minimale du code, celui-ci étant
  linéaire : la différence de deux mots est un mot.

  D = GFWEIGHT(GEN,'gen') dit explicitement que GEN est génératrice ;
  GFWEIGHT(PAR,'par') qu'il s'agit d'une matrice de contrôle ;
  GFWEIGHT(POL,N) que POL est le polynôme générateur d'un code cyclique
  de longueur N.

  La distance minimale dit tout du pouvoir du code : il corrige
  FLOOR((D-1)/2) erreurs et en détecte D-1.

  Exemple :
     gfweight(hammgen(3))           % 3 : le code de Hamming corrige
                                    % une erreur
     gfweight([1 1 0 1], 7)         % 3 : par le polynôme générateur
                                    % du même code

  Voir aussi HAMMGEN, CYCLPOLY, GEN2PAR, BITERR.
```

## `gray2bin`

```
GRAY2BIN Numérotation de Gray vers numérotation binaire.
  Y = GRAY2BIN(X,MODULATION,M) est la réciproque de BIN2GRAY.

  [Y,MAP] = GRAY2BIN(...) rend aussi la table complète.

  Exemple :
     gray2bin(bin2gray(0:7, 'psk', 8), 'psk', 8)   % 0:7

  Voir aussi BIN2GRAY.
```

## `hammgen`

```
HAMMGEN Matrices d'un code de Hamming.
  [H,G,N,K] = HAMMGEN(M) rend la matrice de contrôle H (M x N), la
  matrice génératrice G (K x N), avec N = 2^M-1 et K = N-M.

  Les colonnes de H sont toutes les combinaisons binaires non nulles :
  c'est ce qui permet de localiser une erreur simple par son syndrome.

  Exemple :
     [H, G, n, k] = hammgen(3);   % n = 7, k = 4
```

## `instants`

```
INSTANTS Vecteur des instants d'échantillonnage, à la forme de X.
  T = INSTANTS(X,FS) rend (0:n-1)'/FS répété autant de fois que X a de
  colonnes. Les fonctions de modulation analogique s'en servent toutes.
```

## `intrlv`

```
INTRLV Entrelacement par une permutation donnée.
  Y = INTRLV(DONNEES,PERMUTATION) range les éléments dans l'ordre
  indiqué : Y(k) = DONNEES(PERMUTATION(k)). Entrelacer sert à répartir
  les erreurs en rafale sur plusieurs mots de code, là où un code
  correcteur sait les traiter.

  Si DONNEES est une matrice, chaque colonne est entrelacée séparément.

  Exemple :
     intrlv([10 20 30 40], [3 1 4 2])   % [30 10 40 20]

  Voir aussi DEINTRLV, RANDINTRLV, MATINTRLV.
```

## `istrellis`

```
ISTRELLIS Vérification d'une structure de treillis.
  OK = ISTRELLIS(T) est vrai quand T porte les cinq champs attendus,
  des tailles cohérentes, et des états et sorties dans les bornes.
  [OK,MESSAGE] = ISTRELLIS(T) rend en plus la raison du refus.

  Exemple :
     istrellis(poly2trellis(3, [7 5]))   % vrai

  Voir aussi POLY2TRELLIS, CONVENC, VITDEC.
```

## `matdeintrlv`

```
MATDEINTRLV Désentrelacement matriciel, réciproque de MATINTRLV.

  Exemple :
     isequal(matdeintrlv(matintrlv(1:6, 2, 3), 2, 3), 1:6)   % vrai

  Voir aussi MATINTRLV, DEINTRLV.
```

## `matintrlv`

```
MATINTRLV Entrelacement matriciel.
  Y = MATINTRLV(DONNEES,NLIGNES,NCOLONNES) remplit une matrice ligne par
  ligne avec les données, puis la lit colonne par colonne. Une rafale de
  NLIGNES erreurs consécutives se retrouve ainsi répartie sur NLIGNES
  mots distincts.

  Le nombre d'éléments doit valoir NLIGNES*NCOLONNES.

  Exemple :
     matintrlv(1:6, 2, 3)   % [1 4 2 5 3 6]

  Voir aussi MATDEINTRLV, INTRLV.
```

## `matlibre_bch_coder`

```
MATLIBRE_BCH_CODER Un mot de code, systématique ou non.
  Le reste de la division de x^(n-k) fois le message par le générateur
  donne les bits de contrôle : le mot obtenu est bien multiple du
  générateur, ce qui est la définition d'un mot de code.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bch_corriger`

```
MATLIBRE_BCH_CORRIGER Corrige un mot BCH reçu.
  Syndromes, puis Berlekamp-Massey, puis recherche de Chien.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bch_extraire`

```
MATLIBRE_BCH_EXTRAIRE Le message contenu dans des mots systématiques.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bch_generateur`

```
MATLIBRE_BCH_GENERATEUR Générateur d'un code BCH, par puissances
  décroissantes.
  On accumule les polynômes minimaux de alpha, alpha^2, ... jusqu'à ce
  que le degré du produit atteigne n-k. La capacité de correction est
  le nombre de racines consécutives ainsi annulées, divisé par deux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_bch_message`

```
MATLIBRE_BCH_MESSAGE Ramène un message à une matrice de lignes de K bits.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_berlekamp`

```
MATLIBRE_BERLEKAMP Polynôme localisateur d'erreurs, par Berlekamp-Massey.
  Le polynôme rendu est à coefficients dans GF(2^m), par puissances
  croissantes, de terme constant un. Ses racines inverses désignent les
  positions en erreur.

  L'algorithme construit le plus court registre à décalage qui engendre
  la suite des syndromes : c'est cette longueur minimale qui garantit
  qu'on ne corrige pas plus d'erreurs qu'il n'y en a.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_chien`

```
MATLIBRE_CHIEN Recherche de Chien : les positions en erreur.
  On évalue le localisateur en chaque alpha^(-i) : une racine désigne
  la position i. C'est un parcours exhaustif, mais la seule façon sûre
  de trouver toutes les racines dans un corps fini.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_derivee_formelle`

```
MATLIBRE_DERIVEE_FORMELLE Dérivée d'un polynôme de caractéristique deux.
  Les coefficients vont par puissances croissantes. Dans un corps de
  caractéristique deux, dériver garde un terme sur deux : les termes de
  degré pair disparaissent, deux fois quoi que ce soit valant zéro.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf2_conv`

```
MATLIBRE_GF2_CONV Produit de deux polynômes binaires.
  Les coefficients vont par puissances croissantes ; l'addition étant
  le ou exclusif, le produit se calcule sans retenue.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_concat`

```
MATLIBRE_GF_CONCAT Concatène des tableaux de corps de Galois.
  Tous doivent appartenir au même corps ; un tableau ordinaire est
  admis et pris dans le corps des autres.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_convolution`

```
MATLIBRE_GF_CONVOLUTION Produit de deux polynômes de GF(2^M).
  Coefficients par puissances croissantes ; l'addition étant le ou
  exclusif, il n'y a pas de retenue.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_div`

```
MATLIBRE_GF_DIV Quotient terme à terme dans GF(2^M).
  La division par zéro n'a pas de sens dans un corps : elle est
  refusée, non rendue comme l'infini.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_etendre`

```
MATLIBRE_GF_ETENDRE Répand un scalaire sur la taille de l'autre tableau.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_evaluer`

```
MATLIBRE_GF_EVALUER Valeur d'un polynôme en alpha^exposant.
  Le polynôme est donné par puissances croissantes, à coefficients dans
  GF(2^M).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_journal`

```
MATLIBRE_GF_JOURNAL Tables du logarithme discret d'un corps de Galois.
  [LOG,EXP] = MATLIBRE_GF_JOURNAL(M,PRIM) rend deux tables de GF(2^M) :
  LOG(V+1) est l'exposant de la valeur V — non défini pour zéro, où il
  vaut -Inf —, et EXP(K+1) la valeur de alpha^K.

  Multiplier revient alors à additionner des exposants modulo 2^M-1 :
  c'est ce qui rend l'arithmétique du corps rapide.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_minimal`

```
MATLIBRE_GF_MINIMAL Polynôme minimal d'une classe cyclotomique.
  Le produit des (x - alpha^k) sur toute la classe est à coefficients
  dans GF(2) : c'est le polynôme minimal, rendu par puissances
  croissantes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_mul`

```
MATLIBRE_GF_MUL Produit terme à terme dans GF(2^M).
  Le produit passe par les logarithmes discrets : leur somme modulo
  2^M-1 donne l'exposant du résultat. Un facteur nul donne zéro.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_paire`

```
MATLIBRE_GF_PAIRE Ramène deux opérandes au même corps et à la même taille.
  Un nombre ordinaire est admis comme élément du corps de l'autre ;
  deux tableaux de corps différents sont refusés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_pow`

```
MATLIBRE_GF_POW Puissance terme à terme dans GF(2^M).
  Un exposant négatif prend l'inverse, ce qui a un sens dans un corps
  tant que la base n'est pas nulle. Zéro puissance zéro vaut un, comme
  partout dans MATLAB.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_primitif`

```
MATLIBRE_GF_PRIMITIF Polynôme primitif par défaut, sous forme d'entier.
  L'entier porte les coefficients en binaire, poids fort en tête : le
  polynôme 1+x+x^3 vaut donc 11.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_gf_valeurs`

```
MATLIBRE_GF_VALEURS Les valeurs entières d'un tableau de corps.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rs_coder`

```
MATLIBRE_RS_CODER Un mot de Reed-Solomon systématique.
  Le reste de la division de x^(n-k) fois le message par le générateur
  donne les symboles de contrôle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rs_corriger`

```
MATLIBRE_RS_CORRIGER Corrige un mot de Reed-Solomon reçu.
  Syndromes, Berlekamp-Massey, recherche de Chien pour les positions,
  puis formule de Forney pour la valeur de chaque erreur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `matlibre_rs_generateur`

```
MATLIBRE_RS_GENERATEUR Générateur d'un code de Reed-Solomon.
  Produit des (x - alpha^(b+i)) pour i de zéro à n-k-1, rendu par
  puissances décroissantes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
```

## `modnorm`

```
MODNORM Facteur de normalisation d'une constellation.
  F = MODNORM(CONST,'avpow',P) rend le facteur par lequel multiplier les
  symboles pour que leur puissance moyenne vaille P.
  F = MODNORM(CONST,'peakpow',P) fait de même pour la puissance crête.

  Sans normalisation, deux constellations d'ordres différents n'ont pas
  la même puissance : comparer leurs taux d'erreur n'aurait pas de sens.

  Exemple :
     c = qammod(0:15, 16);
     f = modnorm(c, 'avpow', 1);
     mean(abs(f * c) .^ 2)   % 1

  Voir aussi QAMMOD, GENQAMMOD, AWGN.
```

## `mskdemod`

```
MSKDEMOD Démodulation par déplacement minimal.
  X = MSKDEMOD(Y,NSAMP) retrouve les bits en mesurant, sur chaque temps
  symbole, le sens dans lequel la phase a tourné : plus de pi/2 pour un
  un, moins pour un zéro.

  X = MSKDEMOD(Y,NSAMP,CODAGE,PHI) reprend les mêmes options que MSKMOD.

  Exemple :
     b = [1 0 1 1 0 0 1];
     isequal(mskdemod(mskmod(b, 8), 8), b)   % vrai

  Voir aussi MSKMOD, FSKDEMOD.
```

## `mskmod`

```
MSKMOD Modulation par déplacement minimal.
  Y = MSKMOD(X,NSAMP) module les bits X en bande de base, avec NSAMP
  échantillons par symbole. La MSK est une modulation de fréquence à
  phase continue d'indice un demi : sur chaque temps symbole, la phase
  avance ou recule exactement de pi/2.

     y(t) = exp(j theta(t)),   theta affine par morceaux

  Comme la phase ne saute jamais, le spectre décroît en f^-4 hors bande,
  là où une MDP-4 décroît en f^-2 : c'est ce qui a fait retenir la MSK,
  sous sa forme gaussienne, pour le GSM.

  Y = MSKMOD(X,NSAMP,CODAGE) vaut 'diff' pour un codage différentiel
  préalable, 'nondiff' pour attaquer directement la fréquence.
  Y = MSKMOD(X,NSAMP,CODAGE,PHI) fixe la phase de départ.

  Exemple :
     y = mskmod([1 0 1 1 0], 8);
     max(abs(abs(y) - 1))   % nul : l'enveloppe est constante

  Voir aussi MSKDEMOD, FSKMOD, PSKMOD.
```

## `oct2dec`

```
OCT2DEC Conversion d'un nombre écrit en octal vers le décimal.
  D = OCT2DEC(O) interprète les chiffres décimaux de O comme des
  chiffres octaux : 17 devient 15, 7 reste 7. C'est la convention des
  polynômes générateurs, qu'on écrit toujours en octal.

  Exemple :
     oct2dec([7 5])    % [7 5]
     oct2dec([171 133])   % [121 91]

  Voir aussi DEC2OCT, POLY2TRELLIS.
```

## `optionsChiffres`

```
OPTIONSCHIFFRES Démêle la base et le sens de lecture de DE2BI et BI2DE.
  Les deux fonctions acceptent la base et le mot-clé 'left-msb' ou
  'right-msb' dans un ordre indifférent ; cette fonction range les deux
  et donne leurs valeurs par défaut, la base deux et le poids faible en
  tête.

  Exemple :
     [b, s] = optionsChiffres({8, 'left-msb'})   % 8, 'left-msb'
```

## `pamdemod`

```
PAMDEMOD Démodulation d'amplitude d'impulsions.
  X = PAMDEMOD(Y,M) rend l'entier dont le point de constellation est le
  plus proche de Y : la décision est un simple arrondi, la
  constellation étant régulière de pas deux.

  X = PAMDEMOD(Y,M,PHI) annule d'abord la rotation PHI.
  X = PAMDEMOD(Y,M,PHI,'gray') rend l'indice de Gray.

  Exemple :
     pamdemod([-3 -0.9 1.2 3], 4)   % [0 1 2 3]

  Voir aussi PAMMOD, QAMDEMOD, PSKDEMOD, BIN2GRAY.
```

## `pammod`

```
PAMMOD Modulation d'amplitude d'impulsions.
  Y = PAMMOD(X,M) place l'entier X, compris entre 0 et M-1, sur la
  constellation régulière {-(M-1), ..., -1, 1, ..., M-1} :

     y = 2 x - M + 1

  Y = PAMMOD(X,M,PHI) fait tourner la constellation de PHI radians.
  Y = PAMMOD(X,M,PHI,'gray') interprète X comme un indice de Gray :
  deux points voisins ne diffèrent alors que d'un bit, ce qui divise
  par log2(M) le taux d'erreur binaire à taux d'erreur symbole égal.

  Exemple :
     pammod(0:3, 4)   % [-3 -1 1 3]

  Voir aussi PAMDEMOD, QAMMOD, PSKMOD, BIN2GRAY.
```

## `permutationAleatoire`

```
PERMUTATIONALEATOIRE Permutation reproductible de 1 à N.
  L'état du générateur est sauvegardé puis restauré : appeler un
  entrelaceur ne doit pas déranger le reste du programme.
```

## `permutationMatricielle`

```
PERMUTATIONMATRICIELLE Ordre de lecture colonne par colonne d'une
  matrice remplie ligne par ligne.
```

## `pmdemod`

```
PMDEMOD Démodulation de phase.
  X = PMDEMOD(Y,FC,FS,DEV) retire la rampe de la porteuse à la phase du
  signal analytique, déroule ce qui reste, et divise par l'excursion.

  Exemple :
     t = (0:1999)' / 10000;
     m = sin(2*pi*30*t);
     max(abs(pmdemod(pmmod(m, 1000, 10000, 1), 1000, 10000, 1) - m))

  Voir aussi PMMOD, FMDEMOD, AMDEMOD.
```

## `pmmod`

```
PMMOD Modulation de phase.
  Y = PMMOD(X,FC,FS,DEV) écrit le signal dans la phase de la porteuse :

     y(t) = cos(2 pi FC t + DEV * x(t))

  DEV est l'excursion de phase en radians par unité d'amplitude de X.

  Exemple :
     t = (0:1999)' / 10000;
     y = pmmod(sin(2*pi*30*t), 1000, 10000, pi/4);

  Voir aussi PMDEMOD, FMMOD, AMMOD.
```

## `poly2trellis`

```
POLY2TRELLIS Treillis d'un codeur convolutif.
  TRELLIS = POLY2TRELLIS(CONTRAINTE,GENERATEURS) décrit le codeur de
  longueur de contrainte CONTRAINTE et de polynômes GENERATEURS, écrits
  en octal. Pour un rendement k/n, CONTRAINTE est un vecteur de k
  longueurs et GENERATEURS une matrice k x n.

  La structure rendue porte les champs de MATLAB :
    numInputSymbols   2^k
    numOutputSymbols  2^n
    numStates         2^(somme des CONTRAINTE - k)
    nextStates        état suivant, indexé (état+1, symbole d'entrée+1)
    outputs           symbole de sortie, en octal, même indexation

  L'état numérote le contenu des registres : le registre de la première
  entrée est le plus significatif, et dans chaque registre le bit entré
  le plus récemment est le plus significatif.

  TRELLIS = POLY2TRELLIS(CONTRAINTE,GENERATEURS,RETOUR) décrit un codeur
  récursif, RETOUR donnant les polynômes de rebouclage en octal.

  Exemple :
     t = poly2trellis(3, [7 5]);
     t.nextStates   % [0 2; 0 2; 1 3; 1 3]
     t.outputs      % [0 3; 3 0; 2 1; 1 2]

  Voir aussi ISTRELLIS, CONVENC, VITDEC.
```

## `pskdemod`

```
PSKDEMOD Démodulation de phase à M états, par décision du plus proche.
```

## `pskmod`

```
PSKMOD Modulation de phase à M états.
  Y = PSKMOD(X,M) associe au symbole k le point exp(2i pi k / M).
```

## `qamdemod`

```
QAMDEMOD Démodulation QAM par décision sur la grille.
```

## `qammod`

```
QAMMOD Modulation d'amplitude en quadrature à M états (M carré).
  La constellation est celle de la documentation : grille carrée
  centrée, d'espacement 2.
```

## `qfunc`

```
QFUNC Fonction Q : probabilité qu'une normale centrée réduite dépasse X.
  Q(X) = 0.5*erfc(X/sqrt(2)).

  Exemple :  qfunc(0)   % 0.5
```

## `qfuncinv`

```
QFUNCINV Réciproque de la fonction Q.
  Q(x) = 0.5*erfc(x/sqrt(2)), donc x = sqrt(2)*erfcinv(2*q).

  Exemple :
     qfuncinv(0.5)              % 0
     qfuncinv(qfunc(1.3))       % 1.3
```

## `randdeintrlv`

```
RANDDEINTRLV Désentrelacement pseudo-aléatoire, réciproque de RANDINTRLV.

  Exemple :
     isequal(randdeintrlv(randintrlv(1:8, 42), 42), 1:8)   % vrai

  Voir aussi RANDINTRLV, DEINTRLV.
```

## `randintrlv`

```
RANDINTRLV Entrelacement par une permutation pseudo-aléatoire.
  Y = RANDINTRLV(DONNEES,GERME) entrelace avec la permutation que
  produit le générateur initialisé par GERME. Le même germe redonne la
  même permutation : c'est ce qui permet au récepteur de désentrelacer
  sans transmettre la table.

  Exemple :
     y = randintrlv(1:8, 42);
     isequal(randdeintrlv(y, 42), 1:8)   % vrai

  Voir aussi RANDDEINTRLV, INTRLV.
```

## `rcosdesign`

```
RCOSDESIGN Filtre en cosinus surélevé, ou sa racine.
  H = RCOSDESIGN(BETA,SPAN,SPS,'sqrt') rend la racine du cosinus
  surélevé, normalisée en énergie.
```

## `rsdec`

```
RSDEC Décodage de Reed-Solomon.
  MSG = RSDEC(CODE,N,K) décode le tableau CODE, de N colonnes et à
  valeurs dans GF(2^M), en messages de K colonnes.

  [MSG,NERR] = RSDEC(...) rend le nombre de symboles corrigés par mot ;
  il vaut -1 quand le décodage a échoué.
  [MSG,NERR,CODECORRIGE] = RSDEC(...) rend aussi le mot corrigé.
  RSDEC(CODE,N,K,GENPOLY) emploie un générateur donné,
  RSDEC(...,GENPOLY,PARPOS) dit où sont les symboles de contrôle.

  Le décodage ajoute une étape à celui d'un code binaire : trouver les
  positions ne suffit pas, il faut aussi la valeur de chaque erreur.
  Elle vient de la formule de Forney, qui la tire du polynôme
  d'évaluation et de la dérivée du localisateur.

  Exemple :
     msg = gf([1 2 3 4 5 6 7 8 9 10 11], 4);
     code = rsenc(msg, 15, 11);
     recu = code;
     recu(3) = recu(3) + 7;         % un symbole abîmé
     [sortie, nerr] = rsdec(recu, 15, 11);
     nerr                           % 1
     isequal(double(sortie), double(msg))   % vrai

  Voir aussi RSENC, RSGENPOLY, BCHDEC, GF.
```

## `rsenc`

```
RSENC Codage de Reed-Solomon.
  CODE = RSENC(MSG,N,K) code le message MSG, tableau de corps GF(2^M)
  à K colonnes, en un code RS de longueur N. Le codage est
  systématique : le message se retrouve dans les K premières colonnes,
  suivi des N-K symboles de contrôle.

  CODE = RSENC(MSG,N,K,GENPOLY) emploie un générateur donné,
  RSENC(MSG,N,K,GENPOLY,PARPOS) place les symboles de contrôle en tête
  si PARPOS vaut 'beg'.

  Un symbole vaut M bits : le code corrige (N-K)/2 symboles, donc
  jusqu'à M fois plus de bits s'ils sont groupés. C'est ce qui le rend
  bon contre les rafales d'erreurs — une rayure sur un disque, un
  évanouissement radio.

  Exemple :
     msg = gf([1 2 3 4 5 6 7 8 9 10 11], 4);
     code = rsenc(msg, 15, 11);
     isequal(double(code(1:11)), double(msg))   % vrai

  Voir aussi RSDEC, RSGENPOLY, BCHENC, GF.
```

## `rsgenpoly`

```
RSGENPOLY Polynôme générateur d'un code de Reed-Solomon.
  GENPOLY = RSGENPOLY(N,K) rend le générateur du code RS(N,K), tableau
  de corps GF(2^M) dont les coefficients vont par puissances
  décroissantes. N doit valoir 2^M - 1.

  GENPOLY = RSGENPOLY(N,K,PRIM) emploie le polynôme primitif PRIM,
  RSGENPOLY(N,K,PRIM,B) part de alpha^B au lieu d'alpha.
  [GENPOLY,T] = RSGENPOLY(...) rend la capacité de correction,
  (N-K)/2 arrondi vers le bas.
  RSGENPOLY(...,'double') rend des nombres ordinaires.

  Le générateur est le produit des (x - alpha^(B+i)) pour i allant de
  zéro à N-K-1. Un code de Reed-Solomon corrige des symboles entiers,
  non des bits : c'est ce qui le rend bon contre les rafales.

  Exemple :
     [g, t] = rsgenpoly(15, 11);
     t                              % 2
     numel(g.x) - 1                 % 4 = 15 - 11

  Voir aussi RSENC, RSDEC, BCHGENPOLY, GF.
```

## `scatterplot`

```
SCATTERPLOT Tracé de la constellation reçue.
  SCATTERPLOT(Y) place chaque échantillon complexe dans le plan, partie
  réelle en abscisse et imaginaire en ordonnée. C'est le diagramme qui
  montre d'un coup le bruit, la rotation de phase et le déséquilibre
  des voies.

  SCATTERPLOT(Y,N) ne garde qu'un échantillon sur N, ce qu'il faut
  quand le signal est suréchantillonné : seuls les instants de décision
  ont un sens.
  SCATTERPLOT(Y,N,DECALAGE) choisit lequel des N échantillons garder.

  Exemple :
     scatterplot(awgn(qammod(randi([0 15], 1, 500), 16), 20))

  Voir aussi EYEDIAGRAM, QAMMOD.
```

## `symerr`

```
SYMERR Nombre et taux d'erreurs symbole.
```

## `syndtable`

```
SYNDTABLE Table de décodage par syndrome.
  T = SYNDTABLE(H) rend, pour chaque syndrome possible, le motif
  d'erreur de poids minimal qui le produit : c'est le représentant de
  la classe latérale, et le décodage à maximum de vraisemblance consiste
  à le retrancher du mot reçu.

  H est la matrice de contrôle, M lignes et N colonnes. La table compte
  2^M lignes et N colonnes ; la ligne S+1 correspond au syndrome dont
  l'écriture binaire, bit de poids fort à gauche, vaut S.

  La construction énumère les motifs d'erreur par poids croissant et
  s'arrête dès que tous les syndromes ont un représentant : le premier
  trouvé est donc bien de poids minimal.

  Exemple :
     t = syndtable(hammgen(3));
     sum(t, 2)'   % 0 puis sept motifs de poids un

  Voir aussi HAMMGEN, DECODE, GEN2PAR.
```

## `tableGray`

```
TABLEGRAY Table de renumérotation de Gray d'une constellation.
  CORRESPONDANCE(k+1) est le numéro de Gray du symbole binaire k. Pour
  les constellations à une dimension c'est le code de Gray usuel ; pour
  'qam' carrée, le code s'applique à chacune des deux coordonnées.
```

## `tailleEntrelacement`

```
TAILLEENTRELACEMENT Nombre d'éléments qu'un entrelaceur doit permuter.
  Pour un vecteur c'est sa longueur, pour une matrice son nombre de
  lignes : les colonnes sont entrelacées de la même façon.
```

## `vec2mat`

```
VEC2MAT Découpage d'un vecteur en matrice, ligne par ligne.
  M = VEC2MAT(V,NCOL) range V dans une matrice de NCOL colonnes,
  remplie ligne par ligne. La dernière ligne est complétée par des
  zéros si le compte ne tombe pas juste.
  M = VEC2MAT(V,NCOL,REMPLISSAGE) choisit de quoi la compléter.
  [M,RESTE] = VEC2MAT(...) rend aussi le nombre d'éléments ajoutés.

  Exemple :
     vec2mat(1:5, 3)   % [1 2 3; 4 5 0]

  Voir aussi RESHAPE, MATINTRLV.
```

## `verifierFrequences`

```
VERIFIERFREQUENCES Contrôle du critère de Shannon pour la porteuse.
  La porteuse doit tenir sous la moitié de la fréquence
  d'échantillonnage, sinon elle se replie et la modulation n'a plus de
  sens.
```

## `verifierPermutation`

```
VERIFIERPERMUTATION Contrôle qu'un vecteur est bien une permutation.
```

## `vitdec`

```
VITDEC Décodage de Viterbi.
  MESSAGE = VITDEC(CODE,TRELLIS,TBLEN,OPMODE,DECTYPE) décode CODE.

  OPMODE vaut 'trunc' — le décodeur part de l'état zéro et remonte
  depuis le meilleur état final — ou 'term', qui suppose que le codeur a
  été ramené à l'état zéro par des bits de queue.

  DECTYPE vaut 'hard', CODE étant alors des bits et la métrique la
  distance de Hamming, ou 'unquant', CODE étant des réels où le positif
  représente le zéro logique et la métrique la distance euclidienne.

  TBLEN, la profondeur de remontée, n'agit pas sur le résultat ici : le
  décodage se fait sur le bloc entier, ce qui est optimal. L'argument
  est accepté pour la compatibilité.

  MESSAGE = VITDEC(CODE,GENERATEURS,CONTRAINTE) accepte aussi la forme
  directe avec les polynômes en octal.

  Exemple :
     t = poly2trellis(3, [7 5]);
     m = [1 0 1 1 0 0];
     isequal(vitdec(convenc(m, t), t, 5, 'term', 'hard'), m)   % vrai

  Voir aussi CONVENC, POLY2TRELLIS.
```

