function y = medfilt1(x, n, blocs, dimension, remplissage)
%MEDFILT1 Filtre médian glissant d'ordre N.
%   Y = MEDFILT1(X,N) remplace chaque échantillon par la médiane de la
%   fenêtre de N points centrée dessus. N vaut 3 par défaut.
%
%   Y = MEDFILT1(X,N,[],DIM) filtre suivant la dimension DIM.
%   Y = MEDFILT1(...,'zeropad') complète la fenêtre par des zéros aux
%   bords, ce qui est le comportement par défaut ; Y =
%   MEDFILT1(...,'truncate') la raccourcit au lieu de la compléter.
%
%   Les deux traitements des bords donnent des résultats différents, et
%   il faut choisir : compléter par des zéros tire le signal vers zéro
%   aux extrémités, raccourcir prend la médiane d'un échantillon plus
%   petit, donc plus bruité. MATLAB complète par défaut, et c'est aussi
%   ce qui rend le filtre invariant par décalage.
%
%   La médiane, contrairement à la moyenne, n'est pas déplacée par une
%   valeur aberrante : c'est tout l'intérêt de ce filtre, et ce qui le
%   distingue d'un lissage.
%
%   Exemple :
%      medfilt1([1 100 2 3], 3)    % la valeur aberrante disparait
%      medfilt1([1 100 1], 3)      % [1 1 1] : les bords sont completes
%
%   Voir aussi SGOLAYFILT, MEDFILT2, MOVMEDIAN.
    if nargin < 2 || isempty(n)
        n = 3;
    end
    if nargin < 3
        blocs = [];
    end
    if nargin < 4
        dimension = [];
    end
    if nargin < 5
        remplissage = '';
    end
    % Les arguments de bord peuvent arriver à la place des deux
    % précédents : « medfilt1(x, 3, 'truncate') » s'écrit couramment.
    for candidat = {blocs, dimension}
        if ischar(candidat{1}) || isstring(candidat{1})
            remplissage = char(candidat{1});
        end
    end
    if ischar(blocs) || isstring(blocs), blocs = []; end
    if ischar(dimension) || isstring(dimension), dimension = []; end
    if isempty(remplissage)
        remplissage = 'zeropad';
    end
    remplissage = lower(char(remplissage));
    if ~any(strcmp(remplissage, {'zeropad', 'truncate'}))
        error('signal:medfilt1:Remplissage', ...
              'Le traitement des bords est « zeropad » ou « truncate ».');
    end

    if isempty(dimension)
        if isvector(x)
            dimension = find(size(x) > 1, 1);
            if isempty(dimension), dimension = 1; end
        else
            dimension = 1;
        end
    end

    y = x;
    if dimension == 2
        for ligne = 1:size(x, 1)
            y(ligne, :) = filtrerUnVecteur(x(ligne, :), n, remplissage);
        end
    else
        for colonne = 1:size(x, 2)
            y(:, colonne) = filtrerUnVecteur(x(:, colonne).', n, remplissage).';
        end
    end
end

function y = filtrerUnVecteur(x, n, remplissage)
    x = x(:).';
    m = numel(x);
    y = zeros(1, m);
    demi = floor(n / 2);
    for k = 1:m
        if strcmp(remplissage, 'truncate')
            a = max(1, k - demi);
            b = min(m, k + demi);
            y(k) = median(x(a:b));
        else
            % La fenêtre garde sa longueur : ce qui déborde vaut zéro.
            fenetre = zeros(1, 2 * demi + 1);
            for j = -demi:demi
                position = k + j;
                if position >= 1 && position <= m
                    fenetre(j + demi + 1) = x(position);
                end
            end
            y(k) = median(fenetre);
        end
    end
end
