# Toolbox `communications-sans-fil`

```
% Wireless (5G / LTE / WLAN) — couche physique.
%
%   ofdmMod, ofdmDemod - Modulation OFDM
%   pathLoss           - Affaiblissement de parcours
%   rayleighChannel    - Canal de Rayleigh
%   evm                - Amplitude du vecteur d'erreur
%   throughputShannon  - Débit théorique de Shannon
```

## `evm`

```
EVM Amplitude du vecteur d'erreur, en pour cent.
```

## `ofdmDemod`

```
OFDMDEMOD Démodulation OFDM.
```

## `ofdmMod`

```
OFDMMOD Modulation OFDM avec préfixe cyclique.
  SIGNAL = OFDMMOD(SYMBOLES,NFFT,PREFIXE) où SYMBOLES est une matrice
  dont chaque colonne est un symbole OFDM.
```

## `pathLoss`

```
PATHLOSS Affaiblissement de parcours en décibels.
  L = PATHLOSS(D,F) applique le modèle en espace libre ; l'exposant
  permet de rendre compte d'un environnement plus difficile.
```

## `rayleighChannel`

```
RAYLEIGHCHANNEL Canal à évanouissements de Rayleigh.
```

## `throughputShannon`

```
THROUGHPUTSHANNON Capacité de Shannon, en bits par seconde.
```

