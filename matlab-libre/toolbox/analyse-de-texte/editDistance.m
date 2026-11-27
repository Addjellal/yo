function d = editDistance(a, b, varargin)
%EDITDISTANCE Distance d'édition (Levenshtein, et Damerau en option), comme MATLAB.
%   D = EDITDISTANCE(A,B) rend le coût minimal des insertions,
%   suppressions et substitutions qui transforment A en B (Levenshtein,
%   1966). A et B sont des textes, comparés caractère par caractère, ou
%   des cellules de mots (celles de TOKENIZEDDOCUMENT), comparées mot par
%   mot.
%   D = EDITDISTANCE(...,NOM,VALEUR) règle les coûts, comme MATLAB :
%      'InsertCost', 'DeleteCost'  1 par défaut, un nombre ou une fonction
%                                  d'un élément
%      'SubstituteCost'            1 par défaut, un nombre ou une fonction
%                                  de deux éléments
%      'SwapCost'                  Inf par défaut : l'échange de deux
%                                  éléments voisins ne compte pas ; une
%                                  valeur finie donne la distance de
%                                  Damerau (alignement optimal)
%
%   Avec les coûts unitaires, c'est une vraie distance : nulle si et
%   seulement si les chaînes sont égales, symétrique, et vérifiant
%   l'inégalité triangulaire. Le calcul, par programmation dynamique
%   (Wagner et Fischer, 1974), est en O(n m).
%
%   Exemples :
%      % Les cas de la documentation de MATLAB.
%      editDistance("Text analytics", "Text analysis")   % 2
%      editDistance("MATALB", "MATLAB")                   % 2
%      editDistance("MATALB", "MATLAB", 'SwapCost', 1)    % 1
%      editDistance("MATLAB", "MathWorks")                % 8
%
%   Voir aussi NWALIGN, SWALIGN, STRCMP.
    o = struct('InsertCost', 1, 'DeleteCost', 1, 'SubstituteCost', 1, 'SwapCost', inf);
    noms = fieldnames(o);
    if mod(numel(varargin), 2) ~= 0
        error('textanalytics:editDistance:Options', 'Options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        trouve = find(strcmpi(varargin{k}, noms), 1);
        if isempty(trouve)
            error('textanalytics:editDistance:Option', 'Option inconnue : %s.', char(varargin{k}));
        end
        o.(noms{trouve}) = varargin{k + 1};
    end
    a = elements(a);
    b = elements(b);
    n = numel(a);
    m = numel(b);
    D = zeros(n + 1, m + 1);
    for i = 1:n
        D(i + 1, 1) = D(i, 1) + cout(o.DeleteCost, a{i});
    end
    for j = 1:m
        D(1, j + 1) = D(1, j) + cout(o.InsertCost, b{j});
    end
    for i = 1:n
        for j = 1:m
            if isequal(a{i}, b{j})
                substitution = 0;
            else
                substitution = cout(o.SubstituteCost, a{i}, b{j});
            end
            D(i + 1, j + 1) = min([D(i, j + 1) + cout(o.DeleteCost, a{i}), ...
                                   D(i + 1, j) + cout(o.InsertCost, b{j}), ...
                                   D(i, j) + substitution]);
            if isfinite(o.SwapCost) && i > 1 && j > 1 && isequal(a{i}, b{j - 1}) ...
                    && isequal(a{i - 1}, b{j})
                D(i + 1, j + 1) = min(D(i + 1, j + 1), D(i - 1, j - 1) + o.SwapCost);
            end
        end
    end
    d = D(n + 1, m + 1);
end

function e = elements(x)
%ELEMENTS Les éléments comparés : les caractères d'un texte, ou les mots d'une cellule.
    if iscell(x)
        e = cellfun(@char, x, 'UniformOutput', false);
    else
        c = char(x);
        e = num2cell(c);
    end
end

function c = cout(regle, varargin)
    if isa(regle, 'function_handle')
        c = regle(varargin{:});
    else
        c = regle;
    end
end
