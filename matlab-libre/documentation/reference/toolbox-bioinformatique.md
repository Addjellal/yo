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
  D = SEQDIST(A,B) rend la proportion de positions où A et B diffèrent,
  entre zéro et un. Les séquences sont comparées sur la longueur de la
  plus courte.

  La normalisation permet de comparer des paires de longueurs
  différentes : une différence sur dix bases et dix sur cent n'ont pas
  la même portée, et le compte brut ne le dirait pas.

  La distance de Hamming compare position par position : elle ne sait
  rien des insertions ni des suppressions, qui décalent tout ce qui
  suit. Deux séquences identiques à une insertion près lui paraissent
  totalement différentes. C'est pour cela qu'on aligne — NWALIGN et
  SWALIGN — plutôt que de compter les écarts.

  Exemple :
     seqdist('ATGGCCATT', 'ATGGCCATA')     % 1/9
     seqdist('ACGT', 'ACGT')               % 0
     seqdist('ACGT', 'CGTA')               % 1 : un decalage suffit

  Voir aussi NWALIGN, SWALIGN, SEQCOMPLEMENT.
```

## `seqrcomplement`

```
SEQRCOMPLEMENT Brin complémentaire inverse.
```

## `swalign`

```
SWALIGN Alignement local par l'algorithme de Smith-Waterman.
```

