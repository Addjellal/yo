# Toolbox `dsp`

```
% DSP System Toolbox — traitement du signal en temps réel.
%
%   fftfilt   - Filtrage RIF par blocs (recouvrement-addition)
%   upfirdn   - Sur-échantillonnage, filtrage, décimation
%   firls     - Filtre RIF par moindres carrés
%   levinson  - Récursion de Levinson-Durbin
%   lpc       - Prédiction linéaire
%   dcblock   - Suppression de la composante continue
```

## `dcblock`

```
DCBLOCK Filtre coupe-continu du premier ordre.
  Y = DCBLOCK(X) ôte la composante continue de X.
  Y = DCBLOCK(X,ALPHA) règle le pôle, 0.995 par défaut.

  Le filtre est y[n] = x[n] - x[n-1] + alpha y[n-1] : un zéro exactement
  à la fréquence nulle, et un pôle juste à côté. Le zéro annule le
  continu, le pôle rend tout le reste presque intact.

  ALPHA décide de l'arbitrage, et il n'y en a qu'un : plus il approche
  de un, plus l'encoche est étroite — donc moins le signal utile est
  touché — mais plus le régime transitoire est long. Sa durée vaut
  environ 1/(1-ALPHA) échantillons : 200 pour 0.995, 1000 pour 0.999.
  Mesurer la moyenne avant que ce transitoire soit éteint donne un
  résultat qui n'a rien à voir avec le régime établi.

  Exemple :
     x = 5 + sin(2 * pi * 0.05 * (0:999)');
     y = dcblock(x, 0.99);
     mean(y(500:end))                % voisin de zero
     std(y(500:end)) / std(x)        % voisin de un : l'alternatif reste

  Voir aussi FILTER, DETREND, HIGHPASS, BUTTER.
```

## `fftfilt`

```
FFTFILT Filtrage RIF par recouvrement-addition dans le domaine fréquentiel.
  Y = FFTFILT(B,X) donne le même résultat que FILTER(B,1,X), mais en
  passant par la transformée de Fourier : c'est plus rapide dès que le
  filtre est long.
  Y = FFTFILT(B,X,NFFT) impose la taille des blocs.

  La méthode est celle du recouvrement et de l'addition : le signal est
  découpé, chaque bloc est convolué par transformée, et les morceaux se
  recouvrent de la longueur du filtre moins un. C'est ce recouvrement
  qui rend le résultat exactement égal à celui de FILTER, et non
  seulement voisin.

  L'orientation de X est préservée, comme dans MATLAB : un vecteur
  colonne rend un vecteur colonne.

  Exemple :
     x = randn(4096, 1);
     b = fir1(64, 0.3);
     max(abs(fftfilt(b, x) - filter(b, 1, x)))     % de l'ordre de 1e-15

  Voir aussi FILTER, CONV, UPFIRDN, FIR1.
```

## `firls`

```
FIRLS Filtre RIF à phase linéaire, au sens des moindres carrés.
  B = FIRLS(N,F,A) rend les N+1 coefficients du filtre d'ordre N dont la
  réponse en amplitude approche le gabarit (F,A) au sens des moindres
  carrés intégrés. F est normalisé entre 0 et 1, un pour Nyquist, et se
  donne par paires : chaque paire ouvre et ferme une bande, où le
  gabarit est le segment qui joint les amplitudes A des deux bords.
  B = FIRLS(N,F,A,W) pondère les bandes, un poids par bande.
  B = FIRLS(N,F,A,'hilbert') ou FIRLS(N,F,A,W,'hilbert') conçoit un
  filtre antisymétrique (types III et IV) : B(k) = -B(N+2-k), et la
  réponse vaut j A(w) exp(-j w N/2), comme celle de FIRPM.

  L'erreur minimisée est l'intégrale, sur les bandes seulement, du
  carré de l'écart pondéré : les intégrales des produits de cosinus (ou
  de sinus) sont calculées en forme fermée, comme MATLAB, puis le
  système normal est résolu. Ce qui sépare deux bandes n'est pas
  contraint : ce sont les bandes de transition, où le filtre fait ce
  qu'il veut.

  Le filtre est symétrique (ou antisymétrique), donc à phase linéaire :
  toutes les fréquences subissent le même retard de N/2 échantillons.
  À ordre impair (type II), la réponse s'annule forcément à Nyquist ; à
  ordre pair antisymétrique (type III), à zéro et à Nyquist.

  L'option 'differentiator' de MATLAB, qui pondère l'erreur en 1/f²,
  n'est pas encore là : FIRLS la refuse en le disant ; FIRPM la connaît.

  Exemple :
     b = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
     max(abs(b - fliplr(b)))         % nul : le filtre est symetrique
     [h, w] = freqz(b, 1, 512);
     max(abs(h(w / pi > 0.4)))       % petit : la bande est bien coupee
     bh = firls(30, [0.1 0.9], [1 1], 'hilbert');   % transformateur de Hilbert

  Voir aussi FIRPM, FIR1, FIR2, FREQZ.
```

## `levinson`

```
LEVINSON Récursion de Levinson-Durbin.
  A = LEVINSON(R,P) résout le système de Toeplitz hermitien
     toeplitz(R(1:P)) * A(2:P+1).' = -R(2:P+1).'
  en O(P²) opérations, et rend le polynôme de prédiction
  A = [1 A(2) ... A(P+1)] d'ordre P, R étant une autocorrélation
  (réelle ou complexe). P vaut par défaut numel(R) - 1.
  [A,E] = LEVINSON(R,P) rend aussi la variance de l'erreur de
  prédiction d'ordre P, et [A,E,K] les P coefficients de réflexion, en
  colonne.
  Si R est une matrice, chacune de ses colonnes est une autocorrélation :
  A a alors une ligne par colonne, E et K une colonne par colonne.

  La récursion monte d'un ordre à la fois : le coefficient de réflexion
  K(m) mesure ce que l'ordre m apporte, et l'erreur se multiplie à
  chaque pas par 1 - |K(m)|². Tant que |K(m)| < 1, le filtre 1/A est
  stable : c'est la garantie de la méthode d'autocorrélation.

  Exemple :
     % AR(2) de coefficients 0.75 et -0.5, autocorrélation exacte.
     r = [16 8 -2] / 9;              % gamma(0), gamma(1), gamma(2)
     [a, e] = levinson(r, 2)          % a = [1 -0.75 0.5], e = 1

  Voir aussi LPC, RLEVINSON, TOEPLITZ, ARYULE.
```

## `lpc`

```
LPC Coefficients de prédiction linéaire.
  [A,E] = LPC(X,P) rend le prédicteur d'ordre P qui minimise l'erreur
  quadratique, et E la variance de cette erreur. P vaut par défaut
  numel(X) - 1, comme dans MATLAB.

  A est le polynôme du filtre inverse : FILTER(A,1,X) rend l'erreur de
  prédiction, et FILTER(1,A,E) reconstruit le signal à partir d'elle.
  A(1) vaut toujours un.

  Le prédicteur se lit sur l'autocorrélation seule : c'est ce qui rend
  la méthode utilisable en temps réel, et ce qui explique qu'elle soit
  au cœur du codage de la parole. Au lieu de transmettre le signal, on
  transmet P coefficients et une erreur bien plus petite.

  L'autocorrélation est estimée par la moyenne, non par la somme : sans
  cela E serait proportionnelle à la longueur du signal au lieu d'en
  être la variance. Les coefficients, eux, ne changent pas — un facteur
  commun sur l'autocorrélation ne les déplace pas.

  Exemple :
     x = filter(1, [1 -1.6 0.9], randn(2000, 1));
     [a, e] = lpc(x, 2);
     a                               % voisin de [1 -1.6 0.9]
     abs(e - var(filter(a, 1, x)))   % petit : E est bien la variance

  Voir aussi LEVINSON, XCORR, FILTER, ARBURG.
```

## `upfirdn`

```
UPFIRDN Sur-échantillonne, filtre, puis décime.
  Y = UPFIRDN(X,H,P,Q) insère P-1 zéros entre les échantillons de X,
  filtre par le RIF H, puis garde un échantillon sur Q, en une seule
  opération polyphase dans MATLAB. P et Q valent un par défaut.
  La sortie a ceil(((numel(X) - 1) * P + numel(H)) / Q) échantillons,
  comme dans MATLAB : les zéros insérés après le dernier échantillon
  ne sont pas filtrés. Une matrice X est traitée colonne par colonne ;
  un vecteur garde son orientation.

  C'est l'opération de base du changement de cadence : RESAMPLE
  l'emploie avec un filtre passe-bas conçu pour P/Q.

  Exemple :
     y = upfirdn([1 2 3], [1 1 1], 2)     % 1 1 3 2 5 3 3 : 7 échantillons

  Voir aussi RESAMPLE, INTERP, DECIMATE, FILTER.
```

