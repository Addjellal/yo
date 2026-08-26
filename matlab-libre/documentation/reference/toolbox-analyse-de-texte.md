# Toolbox `analyse-de-texte`

```
% Text Analytics Toolbox — analyse de textes.
%
%   tokenizedDocument - Découpe un texte en mots
%   removeStopWords   - Retire les mots vides
%   normalizeWords    - Racinisation simple
%   bagOfWords        - Sac de mots (matrice d'effectifs)
%   tfidf             - Pondération TF-IDF
%   splitSentences    - Découpe en phrases
%   wordFrequency     - Fréquences triées
%   editDistance      - Distance de Levenshtein
```

## `bagOfWords`

```
BAGOFWORDS Matrice d'effectifs mot par document.
  [C,V] = BAGOFWORDS(DOCS) où DOCS est une cellule de cellules de mots.
  C(i,j) compte les occurrences du mot V{j} dans le document i.
```

## `editDistance`

```
EDITDISTANCE Distance de Levenshtein entre deux chaînes.
```

## `normalizeWords`

```
NORMALIZEWORDS Racinisation : retire les suffixes les plus courants.
```

## `removeStopWords`

```
REMOVESTOPWORDS Retire les mots vides d'une liste de mots.
```

## `splitSentences`

```
SPLITSENTENCES Découpe un texte en phrases.
```

## `tfidf`

```
TFIDF Pondération terme-fréquence / fréquence inverse de document.
  M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS.
```

## `tokenizedDocument`

```
TOKENIZEDDOCUMENT Découpe un texte en mots, en minuscules.
  MOTS = TOKENIZEDDOCUMENT(TEXTE) rend une cellule de mots : la
  ponctuation est retirée, la casse normalisée.
```

## `wordFrequency`

```
WORDFREQUENCY Fréquences des mots, par ordre décroissant.
```

