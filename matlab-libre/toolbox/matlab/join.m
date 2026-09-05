function sortie = join(texte, separateur, dimension)
%JOIN Réunit des éléments de texte en une seule chaîne.
%   S = JOIN(TEXTE) réunit les éléments de TEXTE — un tableau de chaînes
%   ou une cellule de textes — en les séparant par une espace.
%   S = JOIN(TEXTE,SEPARATEUR) emploie le séparateur donné.
%   S = JOIN(TEXTE,SEPARATEUR,DIM) réunit suivant la dimension DIM.
%
%   La réunion se fait suivant la dernière dimension non singleton : un
%   vecteur donne une chaîne unique, une matrice donne une colonne de
%   chaînes, une par ligne.
%
%   Le séparateur peut être unique, ou en compter un de moins que les
%   éléments à réunir — un séparateur différent entre chaque paire.
%
%   JOIN est l'inverse de SPLIT : réunir puis découper avec le même
%   séparateur rend le tableau de départ, tant que le séparateur
%   n'apparaît pas dans les éléments.
%
%   Sur des tables, JOIN désigne tout autre chose — la jointure de deux
%   tables par une clé — et c'est la méthode de la classe qui s'applique.
%
%   Exemple :
%      join(["a" "b" "c"])                 % "a b c"
%      join(["a"; "b"], "-")               % "a-b"
%      join(["x" "y"; "z" "w"], ", ")      % ["x, y"; "z, w"]
%      split(join(["a" "b" "c"], "-"), "-")
%
%   Voir aussi SPLIT, STRJOIN, STRSPLIT, PLUS.
    if nargin < 2 || isempty(separateur)
        separateur = " ";
    end
    enCellule = iscell(texte);
    if ischar(texte)
        texte = string(texte);
    end
    texte = string(texte);
    if nargin < 3 || isempty(dimension)
        % La dernière dimension non singleton, comme dans MATLAB : un
        % vecteur ligne comme un vecteur colonne donnent une seule chaîne.
        dimension = find(size(texte) ~= 1, 1, 'last');
        if isempty(dimension)
            dimension = 2;
        end
    end
    if dimension == 1
        texte = texte.';
        transposer = true;
    else
        transposer = false;
    end
    [lignes, colonnes] = size(texte);
    separateurs = normaliserSeparateur(separateur, colonnes);
    resultat = repmat(string(''), lignes, 1);
    for i = 1:lignes
        morceau = texte(i, 1);
        for j = 2:colonnes
            morceau = morceau + separateurs(min(j - 1, numel(separateurs))) ...
                      + texte(i, j);
        end
        resultat(i) = morceau;
    end
    if transposer
        resultat = resultat.';
    end
    if enCellule
        sortie = cellstr(resultat);
    else
        sortie = resultat;
    end
end

function separateurs = normaliserSeparateur(separateur, colonnes)
    separateurs = string(separateur);
    separateurs = separateurs(:).';
    if numel(separateurs) == 1
        return
    end
    if numel(separateurs) ~= max(colonnes - 1, 0)
        error('MATLAB:join:Separateur', ...
              ['Le séparateur doit être unique, ou en compter un de moins ' ...
               'que les éléments à réunir.']);
    end
end
