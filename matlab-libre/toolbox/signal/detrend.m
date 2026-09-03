function y = detrend(x, ordre, points)
%DETREND Retire la tendance d'un signal.
%   Y = DETREND(X) retire la droite des moindres carrés.
%   Y = DETREND(X,'constant') ou DETREND(X,0) ne retire que la moyenne.
%   Y = DETREND(X,'linear') ou DETREND(X,1) retire la droite.
%   Y = DETREND(X,N) retire le polynôme de degré N.
%   Y = DETREND(X,1,POINTS) ajuste une droite par morceaux, les ruptures
%   étant aux indices POINTS : la tendance retirée est continue.
%
%   Une matrice est traitée colonne par colonne.
%
%   Exemple :
%      t = (0:99)';
%      y = detrend(3 + 0.5 * t + sin(t));   % il ne reste que le sinus
%
%   Voir aussi POLYFIT, FILTER, MOVMEAN.
    if nargin < 2 || isempty(ordre)
        ordre = 1;
    end
    if ischar(ordre) || isstring(ordre)
        switch lower(char(ordre))
            case 'constant', ordre = 0;
            case 'linear',   ordre = 1;
            otherwise
                error('signal:detrend:BadOrder', 'Tendance inconnue : %s.', char(ordre));
        end
    end
    ligne = isrow(x);
    if ligne
        x = x(:);
    end
    [nl, nc] = size(x);
    if nargin < 3 || isempty(points)
        base = matriceBase(nl, ordre);
    else
        base = matriceMorceaux(nl, double(points(:)'));
    end
    y = zeros(nl, nc);
    for j = 1:nc
        colonne = double(x(:, j));
        coefficients = base \ colonne;
        y(:, j) = colonne - base * coefficients;
    end
    if ligne
        y = y.';
    end
end

function base = matriceBase(n, ordre)
% Les puissances de l'indice, centrées pour rester conditionnées.
    t = ((1:n)' - 1) / max(n - 1, 1);
    base = ones(n, ordre + 1);
    for k = 1:ordre
        base(:, k + 1) = t .^ k;
    end
end

function base = matriceMorceaux(n, points)
% Une droite continue par morceaux : une constante, une pente, puis une
% pente supplémentaire à chaque rupture.
    t = (1:n)';
    base = [ones(n, 1), t];
    for k = 1:numel(points)
        base(:, end + 1) = max(t - points(k), 0);   %#ok<AGROW>
    end
end
