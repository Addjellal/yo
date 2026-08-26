# Toolbox `bioinformatique`

```
% Bioinformatics Toolbox — séquences biologiques.
%
%   nwalign        - Alignement global de Needleman-Wunsch
%   swalign        - Alignement local de Smith-Waterman
%   seqcomplement  - Brin complémentaire
%   seqrcomplement - Brin complémentaire inverse
%   nt2aa          - Traduction en acides aminés
%   gcContent      - Taux de G et C
%   randseq        - Séquence aléatoire
%   seqdist        - Distance entre deux séquences
```

## `gcContent`

```
GCCONTENT Proportion de bases G et C.
```

## `nt2aa`

```
NT2AA Traduction d'une séquence de nucléotides en acides aminés.
  Le code génétique standard est utilisé ; « * » marque un codon stop.
```

## `nwalign`

```
NWALIGN Alignement global par l'algorithme de Needleman-Wunsch.
  [SCORE,ALIGNEMENT] = NWALIGN(A,B) rend le score optimal et les deux
  séquences alignées, empilées sur deux lignes.
```

## `randseq`

```
RANDSEQ Séquence aléatoire.
```

## `seqcomplement`

```
SEQCOMPLEMENT Brin complémentaire d'une séquence d'ADN.
```

## `seqdist`

```
SEQDIST Distance de Hamming normalisée entre deux séquences.
```

## `seqrcomplement`

```
SEQRCOMPLEMENT Brin complémentaire inverse.
```

## `swalign`

```
SWALIGN Alignement local par l'algorithme de Smith-Waterman.
```

