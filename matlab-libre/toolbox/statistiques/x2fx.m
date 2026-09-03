function X = x2fx(D, modele)
%X2FX Matrice du modèle à partir d'une matrice de plan.
%   X = X2FX(D,MODELE) construit la matrice de régression : une colonne
%   de uns, puis les facteurs, puis ce que le modèle demande de plus.
%   MODELE vaut 'linear' (défaut), 'interaction', 'quadratic',
%   'purequadratic', ou une matrice d'exposants — une ligne par terme,
%   une colonne par facteur.
%
%   Exemple :
%      x2fx([1 2; 3 4], 'interaction')     % [1 1 2 2; 1 3 4 12]
%
%   Voir aussi ROWEXCH, REGRESS, REGSTATS, FITLM.
    D = double(D);
    [n, k] = size(D);
    if nargin < 2 || isempty(modele)
        modele = 'linear';
    end
    if isnumeric(modele)
        exposants = double(modele);
        X = ones(n, size(exposants, 1));
        for t = 1:size(exposants, 1)
            for f = 1:min(k, size(exposants, 2))
                X(:, t) = X(:, t) .* D(:, f) .^ exposants(t, f);
            end
        end
        return;
    end
    X = [ones(n, 1), D];
    switch lower(char(modele))
        case 'linear'
            % Rien de plus.
        case 'interaction'
            X = [X, croisements(D)];
        case 'purequadratic'
            X = [X, D .^ 2];
        case 'quadratic'
            X = [X, croisements(D), D .^ 2];
        otherwise
            error('stats:x2fx:Modele', 'Modèle inconnu : %s.', char(modele));
    end
end

function P = croisements(D)
    k = size(D, 2);
    P = zeros(size(D, 1), 0);
    for a = 1:(k - 1)
        for b = (a + 1):k
            P(:, end + 1) = D(:, a) .* D(:, b);   %#ok<AGROW>
        end
    end
end
