# Toolbox `analyse-de-texte`

```
% Text Analytics Toolbox — analyse de texte.
%
% Découpage
%   tokenizedDocument - Texte vers mots, en minuscules
%   splitSentences    - Texte vers phrases
%
% Nettoyage
%   removeStopWords   - Retire les mots qui ne distinguent rien
%   normalizeWords    - Racinisation par suffixes
%
% Représentation
%   bagOfWords        - Matrice d'effectifs mot par document
%   tfidf             - Pondération par la spécificité au corpus
%   wordFrequency     - Fréquences, du plus fréquent au moins
%
% Comparaison
%   editDistance      - Distance de Levenshtein entre deux chaînes
```

## `bagOfWords`

```
BAGOFWORDS Matrice d'effectifs mot par document.
  [C,V] = BAGOFWORDS(DOCS) où DOCS est une cellule de cellules de mots.
  C(i,j) compte les occurrences du mot V{j} dans le document i.

  Le sac de mots jette l'ordre : « le chien mord l'homme » et « l'homme
  mord le chien » y sont indistinguables. C'est une perte considérable,
  assumée parce qu'elle ramène un texte à un vecteur — et qu'à partir de
  là toute la statistique s'applique.

  La matrice est très creuse : chaque document n'emploie qu'une petite
  part du vocabulaire. Sur un vrai corpus, elle se range en creux.

  La somme d'une ligne est le nombre de mots du document ; la somme
  d'une colonne, le nombre total d'occurrences du mot.

  Exemple :
     [c, v] = bagOfWords({{'chat','chien','chat'}, {'chat','oiseau'}});
     sum(c, 2)                       % [3; 2] : la longueur des documents

  Voir aussi TFIDF, TOKENIZEDDOCUMENT, WORDFREQUENCY.
```

## `editDistance`

```
EDITDISTANCE Distance de Levenshtein entre deux chaînes.
  D = EDITDISTANCE(A,B) rend le nombre minimal d'insertions,
  suppressions et substitutions qui transforment A en B.

  C'est une vraie distance : nulle si et seulement si les chaînes sont
  égales, symétrique, et vérifiant l'inégalité triangulaire. C'est ce
  qui permet de s'en servir pour regrouper ou pour chercher le plus
  proche voisin.

  Elle est bornée par la longueur de la plus longue chaîne, et minorée
  par la différence de leurs longueurs.

  Le calcul est en O(n m) : sur de longues chaînes, il faut lui préférer
  un filtre préalable qui écarte les paires trop éloignées en longueur.

  Exemple :
     editDistance('chat', 'chats')   % 1 : une insertion
     editDistance('chat', 'chien')   % 3
     editDistance('abc', 'abc')      % 0

  Voir aussi NWALIGN, SWALIGN, STRCMP.
```

## `normalizeWords`

```
NORMALIZEWORDS Racinisation : retire les suffixes les plus courants.
  SORTIE = NORMALIZEWORDS(MOTS) ramène chaque mot à une racine
  approchée, en retirant les suffixes usuels.

  Le but est de reconnaître « chante », « chantes » et « chantant »
  comme un même terme, pour ne pas les compter séparément. La racine
  obtenue n'est pas un mot : c'est une clé de regroupement, et il ne
  faut pas l'afficher à un lecteur.

  La racinisation par suffixes se trompe : elle rapproche des mots sans
  rapport et sépare des formes irrégulières. La lemmatisation, qui
  consulte un dictionnaire, fait mieux mais demande ce dictionnaire.

  Exemple :
     normalizeWords({'chantes', 'chantant', 'chante'})

  Voir aussi TOKENIZEDDOCUMENT, REMOVESTOPWORDS.
```

## `removeStopWords`

```
REMOVESTOPWORDS Retire les mots vides d'une liste de mots.
  SORTIE = REMOVESTOPWORDS(MOTS) retire les articles, prépositions et
  auxiliaires les plus courants, en français et en anglais.
  REMOVESTOPWORDS(MOTS,LISTE) emploie une autre liste.

  Les mots vides sont ceux qui apparaissent partout et ne distinguent
  donc rien : les garder gonfle le vocabulaire et noie le signal. Les
  retirer n'est pourtant pas toujours bon — « ne » et « pas » sont des
  mots vides et portent la négation, ce qui compte beaucoup pour une
  analyse de sentiment.

  La pondération TF-IDF fait un travail voisin, en donnant de fait un
  poids nul à ce qui apparaît dans tous les documents. Elle a
  l'avantage de le faire d'après le corpus, non d'après une liste
  décidée à l'avance.

  Exemple :
     removeStopWords({'le','chat','et','le','chien'})   % {'chat','chien'}

  Voir aussi TOKENIZEDDOCUMENT, TFIDF, WORDFREQUENCY.
```

## `splitSentences`

```
SPLITSENTENCES Découpe un texte en phrases.
  PHRASES = SPLITSENTENCES(TEXTE) rend une cellule de phrases, coupées
  sur les points, points d'interrogation et points d'exclamation.

  Le découpage est syntaxique, non sémantique : un point d'abréviation
  — « M. Dupont », « etc. » — coupe une phrase en deux, et aucune règle
  simple ne distingue les deux emplois du point. Les découpeurs sérieux
  emploient une liste d'abréviations, voire un modèle appris.

  Exemple :
     splitSentences('Bonjour. Ça va ? Oui !')   % trois phrases

  Voir aussi TOKENIZEDDOCUMENT, WORDFREQUENCY.
```

## `tfidf`

```
TFIDF Pondération terme-fréquence / fréquence inverse de document.
  M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS : une ligne par
  document, une colonne par mot du vocabulaire.

  Le poids d'un mot dans un document est son effectif multiplié par le
  logarithme de l'inverse de la proportion de documents qui le
  contiennent. Un mot présent dans tous les documents reçoit donc un
  poids nul : il ne distingue rien.

  C'est ce qui fait la valeur de la pondération : elle décide de ce qui
  est spécifique d'après le corpus lui-même, sans liste de mots vides
  décidée à l'avance. Un terme technique rare dans le corpus général
  mais fréquent dans un document le caractérise ; un article, non.

  Exemple :
     [c, v] = bagOfWords({{'chat','chien'}, {'chat','oiseau'}});
     m = tfidf(c);
     m(:, strcmp(v, 'chat'))         % 0 : present partout

  Voir aussi BAGOFWORDS, WORDFREQUENCY.
```

## `tokenizedDocument`

```
TOKENIZEDDOCUMENT Découpe un texte en mots, en minuscules.
  MOTS = TOKENIZEDDOCUMENT(TEXTE) rend une cellule de mots : la
  ponctuation est retirée, la casse normalisée.

  Découper un texte en mots paraît trivial et ne l'est pas : les
  apostrophes, les traits d'union et les abréviations font des cas
  particuliers dans toutes les langues. Le découpage employé ici est
  simple — tout ce qui n'est pas alphanumérique sépare — ce qui suffit
  pour compter des mots mais coupe « aujourd'hui » en deux.

  Normaliser la casse est ce qui permet de reconnaître « Le » et « le »
  comme le même mot. C'est presque toujours souhaitable, sauf quand la
  majuscule porte une information — un nom propre.

  Exemple :
     tokenizedDocument('Le chat, le chien !')   % {'le','chat','le','chien'}

  Voir aussi BAGOFWORDS, REMOVESTOPWORDS, NORMALIZEWORDS, SPLITSENTENCES.
```

## `wordFrequency`

```
WORDFREQUENCY Fréquences des mots, par ordre décroissant.
  [MOTS,EFFECTIFS] = WORDFREQUENCY(LISTE) compte les occurrences et rend
  les mots du plus fréquent au moins fréquent.

  La distribution des fréquences suit à peu près la loi de Zipf : le
  k-ième mot le plus fréquent apparaît environ n/k fois. C'est pourquoi
  les tout premiers mots — les mots vides — écrasent tous les autres, et
  pourquoi une longue queue de mots n'apparaît qu'une seule fois.

  Exemple :
     [mots, n] = wordFrequency({'a','b','a','c','a','b'});
     mots{1}                         % 'a', trois fois

  Voir aussi BAGOFWORDS, TFIDF, REMOVESTOPWORDS.
```

