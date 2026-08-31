function C = nancov(x, y, mode)
%NANCOV Covariance en écartant les valeurs manquantes.
%   C = NANCOV(X) rend la matrice de covariance des colonnes de X après
%   avoir supprimé toute ligne portant au moins un NaN. C'est la
%   suppression « par liste » : elle garde une matrice cohérente, au prix
%   des lignes incomplètes.
%
%   C = NANCOV(X,Y) traite X et Y comme deux variables et rend la
%   matrice 2 x 2 de leurs covariances.
%
%   C = NANCOV(...,'pairwise') calcule chaque terme sur les lignes où les
%   deux variables concernées sont présentes. On garde ainsi plus de
%   données, mais la matrice obtenue n'est pas nécessairement définie
%   positive : chaque terme repose sur un sous-ensemble différent.
%
%   Exemples :
%      X = [1 2; 3 5; NaN 9; 4 8];
%      nancov(X)                       % les lignes 1, 2 et 4
%      nancov(X, 'pairwise')           % la variance de la 2e colonne
%                                      % emploie ses quatre valeurs
%
%   Voir aussi COV, NANVAR, NANMEAN, CORRCOEF, RMMISSING.
    mode_ = 'complete';
    if nargin >= 2
        if ischar(y) || isstring(y)
            mode_ = lower(char(y));
            y = [];
        elseif nargin >= 3
            mode_ = lower(char(mode));
        end
    end
    if nargin >= 2 && ~isempty(y)
        x = [x(:), y(:)];
    end
    if isvector(x)
        x = x(:);
    end
    if strcmp(mode_, 'pairwise')
        p = size(x, 2);
        C = zeros(p, p);
        for i = 1:p
            for j = 1:p
                garde = ~isnan(x(:, i)) & ~isnan(x(:, j));
                if sum(garde) < 2
                    C(i, j) = NaN;
                else
                    a = x(garde, i);
                    b = x(garde, j);
                    C(i, j) = sum((a - mean(a)) .* (b - mean(b))) / (numel(a) - 1);
                end
            end
        end
        return;
    end
    if ~strcmp(mode_, 'complete')
        error('stats:nancov:BadMode', ...
              'The option must be ''complete'' or ''pairwise''.');
    end
    garde = ~any(isnan(x), 2);
    C = cov(x(garde, :));
end
