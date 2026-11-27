function M = tfidf(effectifs, varargin)
%TFIDF Pondération terme-fréquence / fréquence inverse de document, comme MATLAB.
%   M = TFIDF(C) où C est la matrice rendue par BAGOFWORDS : une ligne par
%   document, une colonne par mot du vocabulaire. Par défaut, comme
%   MATLAB, le poids d'un mot dans un document est son effectif brut
%   multiplié par log(N/NT), N étant le nombre de documents et NT celui
%   des documents qui contiennent le mot. Un mot présent dans tous les
%   documents reçoit donc un poids nul : il ne distingue rien.
%
%   Options, comme MATLAB :
%      'TFWeight'       'raw' (défaut, l'effectif), 'binary' (présence) ou
%                       'log' (1 + log de l'effectif, zéro où il est nul)
%      'IDFWeight'      'normal' (défaut, log(N/NT)), 'unary' (un),
%                       'smooth' (log(1 + N/NT)), 'max' (log(1 + max(NT)/NT)),
%                       'probabilistic' (log((N - NT)/NT)), 'classic-bm25'
%                       (log((N - NT + 0.5)/(NT + 0.5))) ou 'textrank' (le
%                       même pour les mots d'au plus la moitié des
%                       documents, IDFCorrection fois la moyenne des IDF
%                       sinon)
%      'IDFCorrection'  0.25 par défaut, pour 'textrank'
%      'Normalized'     true norme chaque document (chaque ligne) à un, au
%                       sens euclidien (défaut false)
%
%   C'est ce qui fait la valeur de la pondération : elle décide de ce qui
%   est spécifique d'après le corpus lui-même, sans liste de mots vides
%   décidée à l'avance. Un terme technique rare dans le corpus général
%   mais fréquent dans un document le caractérise ; un article, non.
%
%   Exemple :
%      [c, v] = bagOfWords({{'chat','chien','chien'}, {'chat','oiseau'}});
%      m = tfidf(c);
%      m(:, strcmp(v, 'chat'))         % 0 : present partout
%      m(1, strcmp(v, 'chien'))        % 2 log(2) : deux occurrences, un document sur deux
%
%   Voir aussi BAGOFWORDS, WORDFREQUENCY.
    o = struct('TFWeight', 'raw', 'IDFWeight', 'normal', 'IDFCorrection', 0.25, ...
               'Normalized', false);
    noms = fieldnames(o);
    if mod(numel(varargin), 2) ~= 0
        error('textanalytics:tfidf:Options', 'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        trouve = find(strcmpi(varargin{k}, noms), 1);
        if isempty(trouve)
            error('textanalytics:tfidf:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        o.(noms{trouve}) = varargin{k + 1};
    end
    C = double(full(effectifs));
    N = size(C, 1);
    NT = sum(C > 0, 1);
    switch lower(char(o.TFWeight))
        case 'raw',    tf = C;
        case 'binary', tf = double(C > 0);
        case 'log'
            tf = zeros(size(C));
            tf(C > 0) = 1 + log(C(C > 0));
        otherwise
            error('textanalytics:tfidf:TFWeight', ['TFWeight must be ''raw'', ''binary'', or ' ...
                                                   '''log''.']);
    end
    NTp = max(NT, 1);
    switch lower(char(o.IDFWeight))
        case 'normal',        idf = log(N ./ NTp);
        case 'unary',         idf = ones(size(NT));
        case 'smooth',        idf = log(1 + N ./ NTp);
        case 'max',           idf = log(1 + max(NT) ./ NTp);
        case 'probabilistic', idf = log((N - NT) ./ NTp);
        case 'classic-bm25',  idf = log((N - NT + 0.5) ./ (NT + 0.5));
        case 'textrank'
            idf = log((N - NT + 0.5) ./ (NT + 0.5));
            idf(NT > N / 2) = o.IDFCorrection * mean(idf);
        otherwise
            error('textanalytics:tfidf:IDFWeight', 'IDFWeight inconnu : %s.', char(o.IDFWeight));
    end
    M = tf .* idf;
    if o.Normalized
        normes = sqrt(sum(M .^ 2, 2));
        normes(normes == 0) = 1;
        M = M ./ normes;
    end
end
