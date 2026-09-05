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
  B = FIRLS(N,F,M) rend un filtre d'ordre N approchant le gabarit
  défini par les couples (F,M). F est normalisé entre 0 et 1, un pour
  Nyquist, et se donne par paires : chaque paire ouvre et ferme une
  bande. M donne l'amplitude voulue aux deux bouts de chaque bande.
  B = FIRLS(N,F,M,POIDS) pondère les bandes, un poids par bande.

  Ce qui sépare deux bandes n'est pas contraint : ce sont les bandes de
  transition, et c'est là que le filtre fait ce qu'il veut. Les inclure
  dans l'ajustement forcerait un compromis inutile — un filtre ne peut
  pas passer de un à zéro instantanément, et lui demander de le faire
  dégrade les deux bandes utiles.

  Le filtre est symétrique, donc à phase linéaire : toutes les
  fréquences subissent le même retard, de N/2 échantillons. C'est ce
  qu'on ne peut pas obtenir d'un filtre récursif, et la raison
  principale de préférer un filtre à réponse finie.

  Exemple :
     b = firls(40, [0 0.3 0.4 1], [1 1 0 0]);
     max(abs(b - fliplr(b)))         % nul : le filtre est symetrique
     [h, w] = freqz(b, 1, 512);
     max(abs(h(w / pi > 0.4)))       % petit : la bande est bien coupee

  Voir aussi FIR1, FIR2, FIRPM, FREQZ.
```

## `levinson`

```
LEVINSON Récursion de Levinson-Durbin.
  [A,E] = LEVINSON(R,P) résout les équations de Yule-Walker pour la
  suite d'autocorrélation R et l'ordre P. A(1) vaut toujours 1 et E est
  la puissance de l'erreur de prédiction.
```

## `lpc`

```
LPC Coefficients de prédiction linéaire.
  [A,E] = LPC(X,P) rend le prédicteur d'ordre P qui minimise l'erreur
  quadratique, et E la variance de cette erreur.

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
UPFIRDN Sur-échantillonne d'un facteur P, filtre par H, décime par Q.
```

