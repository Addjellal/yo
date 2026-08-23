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
  Y = DCBLOCK(X,ALPHA) applique y[n] = x[n] - x[n-1] + alpha*y[n-1].
```

## `fftfilt`

```
FFTFILT Filtrage RIF par recouvrement-addition dans le domaine fréquentiel.
  Y = FFTFILT(B,X) donne le même résultat que FILTER(B,1,X), mais en
  passant par la transformée de Fourier : c'est plus rapide dès que le
  filtre est long.
```

## `firls`

```
FIRLS Filtre RIF à phase linéaire, au sens des moindres carrés.
  B = FIRLS(N,F,M) approche le gabarit défini par les couples (F,M),
  F étant normalisé entre 0 et 1.
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
  [A,E] = LPC(X,P) minimise l'erreur de prédiction d'ordre P.
```

## `upfirdn`

```
UPFIRDN Sur-échantillonne d'un facteur P, filtre par H, décime par Q.
```

