# Toolbox `bioinformatique`

```
% Bioinformatics Toolbox — séquences d'acides nucléiques et de protéines.
%
% Séquences
%   randseq         - Séquence aléatoire, pour servir de référence
%   gcContent       - Taux de G et C, qui fixe la température de fusion
%   seqcomplement   - Brin complémentaire, base par base
%   seqrcomplement  - Brin complémentaire inverse : celui d'en face
%   nt2aa           - Traduction en acides aminés, code standard
%
% Comparaison
%   seqdist         - Distance de Hamming normalisée, sans décalage
%   nwalign         - Alignement global, par Needleman-Wunsch
%   swalign         - Alignement local, par Smith-Waterman
```

## `gcContent`

```
GCCONTENT Proportion de bases G et C.
  TAUX = GCCONTENT(SEQUENCE) rend la proportion de guanines et de
  cytosines, entre zéro et un.

  G et C sont appariées par trois liaisons hydrogène, A et T par deux :
  un ADN riche en GC fond donc plus haut. C'est ce qui fait de ce taux
  une grandeur physique, et non une simple statistique — il sert à
  calculer la température d'hybridation d'une amorce de PCR.

  Il varie fortement d'un organisme à l'autre, et à l'intérieur d'un
  même génome : les régions codantes en sont souvent plus riches.

  Exemple :
     gcContent('GCGC')               % 1
     gcContent('ATAT')               % 0
     gcContent('ACGT')               % 0.5

  Voir aussi SEQCOMPLEMENT, NT2AA, RANDSEQ.
```

## `nt2aa`

```
NT2AA Traduction d'une séquence de nucléotides en acides aminés.
  Le code génétique standard est utilisé ; « * » marque un codon stop.

  PROTEINE = NT2AA(SEQUENCE) lit la séquence par groupes de trois — les
  codons — depuis le début, et rend la chaîne d'acides aminés à une
  lettre.

  Le code est dégénéré : soixante-quatre codons pour vingt acides aminés
  et un signal d'arrêt. La plupart des synonymes ne diffèrent que par la
  troisième base, ce qui rend les mutations à cette position souvent
  silencieuses.

  Le cadre de lecture décide de tout : décaler d'une base donne une
  protéine sans rapport. C'est pourquoi une insertion d'une seule base
  dans une région codante est bien plus grave qu'une substitution.

  Exemple :
     nt2aa('ATGGCCTAA')              % 'MA*' : depart, alanine, arret
     nt2aa('TGGCCTAA')               % tout autre chose : cadre decale

  Voir aussi SEQCOMPLEMENT, RANDSEQ.
```

## `nwalign`

```
NWALIGN Alignement global par l'algorithme de Needleman-Wunsch.
  [SCORE,ALIGNEMENT] = NWALIGN(A,B) rend le score optimal et les deux
  séquences alignées, empilées sur deux lignes.

  [SCORE,ALIGNEMENT] = NWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU)
  impose les trois coûts : le gain d'une correspondance, la pénalité
  d'une différence, celle d'un trou.

  Needleman-Wunsch est un alignement *global* : il aligne les séquences
  sur toute leur longueur, quitte à ouvrir des trous aux extrémités.
  C'est ce qu'on veut pour comparer deux gènes homologues de longueur
  voisine, et ce qu'on ne veut pas pour chercher un motif court dans une
  longue séquence — Smith-Waterman est fait pour cela.

  La programmation dynamique le rend exact : contrairement à une
  heuristique, il trouve l'alignement optimal, pas seulement un bon.
  Le prix en est un coût en O(n m), en temps comme en mémoire.

  Contrairement à la distance de Hamming, l'alignement sait traiter les
  insertions et les suppressions : deux séquences identiques à une
  insertion près lui paraissent proches, alors que SEQDIST les dit
  totalement différentes.

  Exemple :
     [score, alignement] = nwalign('ACGTACGT', 'ACGACGT');
     disp(alignement)                % le trou apparait

  Voir aussi SWALIGN, SEQDIST, EDITDISTANCE.
```

## `randseq`

```
RANDSEQ Séquence aléatoire.
  S = RANDSEQ(N) rend une séquence d'ADN de N bases tirées uniformément
  dans 'ACGT' ; RANDSEQ(N,ALPHABET) emploie un autre alphabet — 'ACDEFG
  HIKLMNPQRSTVWY' pour des acides aminés.

  Une séquence aléatoire sert de référence : elle dit ce qu'un score
  d'alignement vaut par hasard. Sans cette référence, un score de
  trente ne veut rien dire — c'est en le comparant à la distribution
  des scores aléatoires qu'on sait s'il est significatif.

  Exemple :
     s = randseq(1000);
     gcContent(s)                    % environ 0.5
     scores = arrayfun(@(k) nwalign(randseq(50), randseq(50)), 1:100);

  Voir aussi NWALIGN, SWALIGN, GCCONTENT.
```

## `seqcomplement`

```
SEQCOMPLEMENT Brin complémentaire d'une séquence d'ADN.
  C = SEQCOMPLEMENT(S) échange A avec T et G avec C, base par base, sans
  changer l'ordre.

  Ce n'est pas le brin qu'on lirait en face dans la double hélice : les
  deux brins sont antiparallèles, si bien que le brin opposé se lit à
  l'envers. C'est SEQRCOMPLEMENT qui le donne, et c'est presque toujours
  celui-là qu'on veut.

  Le complément du complément rend la séquence de départ.

  Exemple :
     seqcomplement('ACGT')           % 'TGCA'
     seqrcomplement('ACGT')          % 'ACGT' : palindrome

  Voir aussi SEQRCOMPLEMENT, GCCONTENT, NT2AA.
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
  C = SEQRCOMPLEMENT(S) rend le complément lu à l'envers : c'est le brin
  qui fait face dans la double hélice, les deux brins étant
  antiparallèles.

  Une séquence égale à son complément inverse est un palindrome
  biologique. Ce n'est pas une curiosité : les enzymes de restriction
  reconnaissent presque toutes des sites palindromiques, parce qu'elles
  agissent en dimère symétrique.

  Exemple :
     seqrcomplement('GAATTC')        % 'GAATTC' : le site d'EcoRI
     seqrcomplement(seqrcomplement('ACGTTG'))    % la sequence de depart

  Voir aussi SEQCOMPLEMENT, GCCONTENT.
```

## `swalign`

```
SWALIGN Alignement local par l'algorithme de Smith-Waterman.
  [SCORE,ALIGNEMENT] = SWALIGN(A,B) trouve le meilleur segment commun
  aux deux séquences, sans chercher à les aligner sur toute leur
  longueur. SWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU) impose les coûts.

  La seule différence avec Needleman-Wunsch tient en deux règles : la
  matrice ne descend jamais sous zéro, et la remontée part du maximum
  au lieu du coin. Cela suffit à changer complètement ce qui est
  trouvé : un motif court enfoui dans une longue séquence, plutôt qu'un
  alignement de bout en bout.

  Le score local est donc toujours positif ou nul, et jamais inférieur
  à ce qu'un alignement global obtiendrait sur le même segment.

  Exemple :
     swalign('AAAACGTAAAA', 'TTTACGTTTT')     % trouve ACGT

  Voir aussi NWALIGN, SEQDIST.
```

