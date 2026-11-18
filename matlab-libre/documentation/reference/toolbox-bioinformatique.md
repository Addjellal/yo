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

## `blosum`

```
BLOSUM Matrice de substitution BLOSUM des acides aminés.
  M = BLOSUM(N) rend la matrice BLOSUM N (Henikoff et Henikoff, 1992),
  construite sur les blocs de séquences identiques à N % au plus :
  N vaut 45, 50, 62, 80 ou 90. L'ordre des acides aminés est celui de
  MATLAB : ARNDCQEGHILKMFPSTWYVBZX*.
  [M,INFO] = BLOSUM(N) rend aussi la fiche de la matrice : Name, Scale
  (l'échelle en bits : 1/3 pour BLOSUM50, 1/2 pour BLOSUM62), Entropy,
  ExpectedScore, HighestScore, LowestScore, Order.
  BLOSUM(N,'Extended',false) ne garde que les vingt acides aminés ;
  BLOSUM(N,'Order',ORDRE) range les lignes et colonnes dans ORDRE.

  Les autres pourcentages de MATLAB (30 à 100) ne sont pas fournis :
  BLOSUM le dit au lieu de rendre une matrice voisine.

  Exemple :
     [M, info] = blosum(62);
     M(1, 1)              % 4 : A contre A
     info.Scale           % 0.5

  Voir aussi PAM, NUC44, NWALIGN, SWALIGN.
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

## `matlibre_aligner`

```
MATLIBRE_ALIGNER Alignement de deux séquences, global ou local.
  [SCORE,ALIGNEMENT,DEBUT] = MATLIBRE_ALIGNER(A,B,MODE,ARGUMENTS,NOM)
  fait le travail de NWALIGN (MODE 'global') et de SWALIGN ('local').

  La programmation dynamique est celle de Gotoh (1982) : trois tableaux,
  selon que la case termine par une paire de résidus, un trou dans la
  seconde séquence ou un trou dans la première. Un trou de longueur k
  coûte GapOpen + (k-1)*ExtendGap ; sans ExtendGap, chaque position coûte
  GapOpen, comme dans MATLAB. Le trou de la première séquence se calcule
  ligne par ligne d'un seul coup, par un maximum cumulé : le coût est en
  O(n m) mais l'interpréteur ne fait que O(n) tours de boucle.

  Le score brut est converti en bits par l'échelle de la matrice — 1/3
  pour BLOSUM50 —, puis multiplié par Scale.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     s = matlibre_aligner('VSPAGMASGYD', 'IPGKASYD', 'global', {}, 'nwalign')
     % 7.3333, l'exemple de la documentation de MATLAB

  Voir aussi NWALIGN, SWALIGN, MATLIBRE_MATRICE_SUBSTITUTION.
```

## `matlibre_info_matrice`

```
MATLIBRE_INFO_MATRICE Matrice de substitution et sa fiche, comme BLOSUM la rend.
  [M,INFO] = MATLIBRE_INFO_MATRICE(NOM,ARGUMENTS,FONCTION) lit les options
  'Extended' (true : 24 symboles, B Z X * compris ; false : les 20 acides
  aminés) et 'Order' (un ordre de symboles imposé), et rend la fiche :
  Name, Scale, Entropy, ExpectedScore, HighestScore, LowestScore, Order.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [M, info] = matlibre_info_matrice('BLOSUM62', {}, 'blosum');
     info.Scale                 % 1/2

  Voir aussi BLOSUM, PAM, NUC44.
```

## `matlibre_matrice_substitution`

```
MATLIBRE_MATRICE_SUBSTITUTION Matrices de substitution des alignements.
  [M,ORDRE,ECHELLE] = MATLIBRE_MATRICE_SUBSTITUTION(NOM) rend la matrice
  NOM — 'BLOSUM45', 'BLOSUM50', 'BLOSUM62', 'BLOSUM80', 'BLOSUM90',
  'PAM250' ou 'NUC44' —, l'ordre de ses symboles et l'échelle qui
  convertit un score en bits : 1/3 pour BLOSUM50 (« in 1/3 Bit Units »),
  1/2 pour BLOSUM62, ln(2)/3 nats soit 1/3 de bit pour PAM250, 0.277316
  pour NUC44.

  Les valeurs sont celles des fichiers du NCBI (Henikoff et Henikoff,
  1992, pour BLOSUM ; Dayhoff, 1978, pour PAM ; NUC.4.4 pour les
  nucléotides), recopiées depuis la distribution de Biopython. L'ordre
  des acides aminés est celui de MATLAB : ARNDCQEGHILKMFPSTWYVBZX*, et
  celui des nucléotides ACGTRYKMSWBDHVN.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [M, ordre, echelle] = matlibre_matrice_substitution('BLOSUM50');
     M(ordre == 'W', ordre == 'W')     % 15
     echelle                           % 1/3

  Voir aussi BLOSUM, PAM, NUC44, NWALIGN, SWALIGN.
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

## `nuc44`

```
NUC44 Matrice de substitution des nucléotides NUC44 (NUC.4.4 du NCBI).
  M = NUC44 rend la matrice 15 x 15 dans l'ordre ACGTRYKMSWBDHVN : +5
  pour deux bases identiques, -4 pour deux différentes, et des valeurs
  intermédiaires pour les codes ambigus (R = A ou G...).
  [M,INFO] = NUC44 rend aussi sa fiche : Scale = 0.277316, l'échelle
  qui convertit un score en bits.

  Exemple :
     M = nuc44();
     M(1, 1) - M(1, 2)    % 9 : correspondance contre différence

  Voir aussi BLOSUM, PAM, NWALIGN.
```

## `nwalign`

```
NWALIGN Alignement global par l'algorithme de Needleman-Wunsch.
  SCORE = NWALIGN(A,B) rend le score, en bits, de l'alignement global
  optimal des séquences A et B — des acides aminés, avec la matrice
  BLOSUM50 et une pénalité de 8 par position de trou, comme MATLAB.
  [SCORE,ALIGNEMENT] = NWALIGN(A,B) rend aussi l'alignement, sur trois
  lignes : A avec ses trous, une ligne de symboles — '|' pour deux
  résidus identiques, ':' pour deux résidus apparentés (score de la
  matrice positif ou nul) —, puis B avec ses trous.
  [SCORE,ALIGNEMENT,DEBUT] = NWALIGN(A,B) rend le point de départ dans
  chaque séquence, [1;1] pour un alignement global.

  Options, par paires nom-valeur :
     'Alphabet'       'AA' (acides aminés, par défaut) ou 'NT' (nucléotides)
     'ScoringMatrix'  'BLOSUM50' (défaut AA), 'BLOSUM45', 'BLOSUM62',
                      'BLOSUM80', 'BLOSUM90', 'PAM250', 'NUC44' (défaut NT),
                      ou une matrice, sans échelle, dans l'ordre de MATLAB
     'Scale'          facteur du score : log(2) le rend en nats
     'GapOpen'        pénalité d'ouverture d'un trou (8)
     'ExtendGap'      pénalité de prolongement : trous affines (Gotoh) ;
                      sans elle, chaque position coûte GapOpen
     'Glocal'         true : alignement semi-global, trous d'extrémité gratuits
  Le score brut est converti en bits par l'échelle de la matrice : un
  tiers de bit par unité pour BLOSUM50.

  NWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU), trois nombres, est la forme
  ancienne de MatLibre : score d'identité et trou linéaire, sans échelle.

  Needleman-Wunsch est un alignement *global* : il aligne les séquences
  sur toute leur longueur, quitte à ouvrir des trous aux extrémités. La
  programmation dynamique le rend exact : il trouve l'alignement optimal,
  en O(n m).

  Exemple :
     % L'exemple de la documentation de MATLAB :
     [score, alignement] = nwalign('VSPAGMASGYD', 'IPGKASYD')
     % score = 7.3333 (22 unités de BLOSUM50), 'I-P-GKAS-YD'
     % Durbin et al. (1998), figure 2.5 : un score brut de 1.
     nwalign('HEAGAWGHEE', 'PAWHEAE') * 3

  Voir aussi SWALIGN, BLOSUM, PAM, NUC44, SEQDIST.
```

## `pam`

```
PAM Matrice de substitution PAM des acides aminés (Dayhoff, 1978).
  M = PAM(250) rend la matrice PAM 250, en tiers de bit, dans l'ordre
  ARNDCQEGHILKMFPSTWYVBZX*. [M,INFO] = PAM(250) rend aussi sa fiche.
  Les options 'Extended' et 'Order' sont celles de BLOSUM.

  Seule PAM 250, la plus employée, est fournie ; une autre distance
  évolutive est refusée plutôt qu'approchée.

  Exemple :
     M = pam(250);
     M(19, 19)            % 10 : Y contre Y

  Voir aussi BLOSUM, NUC44, NWALIGN.
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
  SCORE = SWALIGN(A,B) rend le score, en bits, du meilleur alignement
  local des séquences A et B — le couple de segments qui s'alignent le
  mieux —, avec la matrice BLOSUM50 et une pénalité de 8 par position de
  trou, comme MATLAB.
  [SCORE,ALIGNEMENT,DEBUT] = SWALIGN(A,B) rend aussi l'alignement sur
  trois lignes (A, symboles '|' et ':', B) et les positions où il
  commence dans A et dans B.

  Les options sont celles de NWALIGN — 'Alphabet', 'ScoringMatrix',
  'Scale', 'GapOpen', 'ExtendGap' —, sauf 'Glocal'.

  SWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU), trois nombres, est la forme
  ancienne de MatLibre : score d'identité et trou linéaire, sans échelle.

  Smith-Waterman (1981) diffère de Needleman-Wunsch par un seul point :
  un score qui deviendrait négatif repart de zéro. L'alignement peut
  donc commencer et finir n'importe où, et c'est ce qui permet de
  trouver un domaine commun à deux protéines par ailleurs différentes.

  Exemple :
     % Durbin et al. (1998), figure 2.6 : AWGHE contre AW-HE, 28 unités.
     [score, alignement, debut] = swalign('HEAGAWGHEE', 'PAWHEAE')
     score * 3      % 28

  Voir aussi NWALIGN, BLOSUM, PAM, NUC44.
```

