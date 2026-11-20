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
EDITDISTANCE Distance d'édition (Levenshtein, et Damerau en option), comme MATLAB.
  D = EDITDISTANCE(A,B) rend le coût minimal des insertions,
  suppressions et substitutions qui transforment A en B (Levenshtein,
  1966). A et B sont des textes, comparés caractère par caractère, ou
  des cellules de mots (celles de TOKENIZEDDOCUMENT), comparées mot par
  mot.
  D = EDITDISTANCE(...,NOM,VALEUR) règle les coûts, comme MATLAB :
     'InsertCost', 'DeleteCost'  1 par défaut, un nombre ou une fonction
                                 d'un élément
     'SubstituteCost'            1 par défaut, un nombre ou une fonction
                                 de deux éléments
     'SwapCost'                  Inf par défaut : l'échange de deux
                                 éléments voisins ne compte pas ; une
                                 valeur finie donne la distance de
                                 Damerau (alignement optimal)

  Avec les coûts unitaires, c'est une vraie distance : nulle si et
  seulement si les chaînes sont égales, symétrique, et vérifiant
  l'inégalité triangulaire. Le calcul, par programmation dynamique
  (Wagner et Fischer, 1974), est en O(n m).

  Exemples :
     % Les cas de la documentation de MATLAB.
     editDistance("Text analytics", "Text analysis")   % 2
     editDistance("MATALB", "MATLAB")                   % 2
     editDistance("MATALB", "MATLAB", 'SwapCost', 1)    % 1
     editDistance("MATLAB", "MathWorks")                % 8

  Voir aussi NWALIGN, SWALIGN, STRCMP.
```

## `matlibre_porter`

```
MATLIBRE_PORTER Racine d'un mot anglais par l'algorithme de Porter (1980).
  R = MATLIBRE_PORTER(MOT) suit l'implémentation de référence de Martin
  Porter (porter.c), avec ses deux écarts au papier : « bli » devient
  « ble » à l'étape 2 (au lieu de « abli » en « able »), et « logi »
  devient « log ». Elle reproduit les 23 531 racines du jeu d'essai de
  l'auteur (voc.txt, output.txt). Les mots de deux lettres ou moins ne
  changent pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_porter('generalizations')      % 'gener'

  Voir aussi NORMALIZEWORDS.
```

## `normalizeWords`

```
NORMALIZEWORDS Racinisation des mots anglais (Porter), comme MATLAB.
  SORTIE = NORMALIZEWORDS(MOTS) ramène chaque mot à sa racine par
  l'algorithme de Porter (1980), celui qu'emploie MATLAB pour l'anglais,
  après passage en minuscules. MOTS est une cellule de mots (celle de
  TOKENIZEDDOCUMENT), un tableau de chaînes ou un texte ; SORTIE a la
  même forme.

  Le but est de reconnaître « connect », « connected », « connecting »
  et « connection » comme un même terme, pour ne pas les compter
  séparément. La racine obtenue n'est pas toujours un mot (« poni »
  pour « ponies ») : c'est une clé de regroupement.

  L'implémentation suit celle de référence de Martin Porter, et
  reproduit les 23 531 racines du jeu d'essai de l'auteur. Les options
  'Style','lemma' (lemmatisation, qui demande un dictionnaire) et
  'Language' autre que 'en' ne sont pas encore là : elles sont refusées
  en le disant.

  Exemple :
     normalizeWords({'connected', 'connecting', 'connection', 'connections'})
     normalizeWords(["caresses" "ponies" "relational" "generalizations"])
     % caress, poni, relat, gener

  Voir aussi TOKENIZEDDOCUMENT, REMOVESTOPWORDS, BAGOFWORDS.
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
TFIDF Pondération terme-fréquence / fréquence inverse de document, comme MATLAB.
  M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS : une ligne par
  document, une colonne par mot du vocabulaire. Par défaut, comme
  MATLAB, le poids d'un mot dans un document est son effectif brut
  multiplié par log(N/NT), N étant le nombre de documents et NT celui
  des documents qui contiennent le mot. Un mot présent dans tous les
  documents reçoit donc un poids nul : il ne distingue rien.

  Options, comme MATLAB :
     'TFWeight'       'raw' (défaut, l'effectif), 'binary' (présence) ou
                      'log' (1 + log de l'effectif, zéro où il est nul)
     'IDFWeight'      'normal' (défaut, log(N/NT)), 'unary' (un),
                      'smooth' (log(1 + N/NT)), 'max' (log(1 + max(NT)/NT)),
                      'probabilistic' (log((N - NT)/NT)), 'classic-bm25'
                      (log((N - NT + 0.5)/(NT + 0.5))) ou 'textrank' (le
                      même pour les mots d'au plus la moitié des
                      documents, IDFCorrection fois la moyenne des IDF
                      sinon)
     'IDFCorrection'  0.25 par défaut, pour 'textrank'
     'Normalized'     true norme chaque document (chaque ligne) à un, au
                      sens euclidien (défaut false)

  C'est ce qui fait la valeur de la pondération : elle décide de ce qui
  est spécifique d'après le corpus lui-même, sans liste de mots vides
  décidée à l'avance. Un terme technique rare dans le corpus général
  mais fréquent dans un document le caractérise ; un article, non.

  Exemple :
     [c, v] = bagOfWords({{'chat','chien','chien'}, {'chat','oiseau'}});
     m = tfidf(c);
     m(:, strcmp(v, 'chat'))         % 0 : present partout
     m(1, strcmp(v, 'chien'))        % 2 log(2) : deux occurrences, un document sur deux

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

  DOCS = TOKENIZEDDOCUMENT(TEXTES), où TEXTES est un tableau de chaînes
  ou une cellule de textes, rend, comme MATLAB, un document par texte :
  une cellule de même taille dont chaque case est la cellule des mots
  d'un texte, celle que prend BAGOFWORDS.

  Exemples :
     tokenizedDocument('Le chat, le chien !')   % {'le','chat','le','chien'}
     docs = tokenizedDocument(["Le chat dort.", "Le chien court."]);
     [c, v] = bagOfWords(docs)                  % deux lignes, une par texte

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

