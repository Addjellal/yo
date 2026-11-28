function p = fcdf(x, d1, d2, queue)
%FCDF Répartition de la loi de Fisher.
%   F(x) = I_{d1 x / (d1 x + d2)}(d1/2, d2/2).
%   X, D1 et D2 ont la même taille, ou sont scalaires.
%
%   P = FCDF(X,D1,D2,'upper') rend la queue supérieure P(F > x), calculée
%   directement par I_{d2/(d2 + d1 x)}(d2/2, d1/2) : c'est la p-valeur
%   d'un test F, juste même quand elle vaut 1e-12.
%
%   Exemple :
%      fcdf(1, 10, 10)             % 0.5 : a degres egaux, la mediane est en un
%      fcdf(330.285, 6, 9, 'upper')   % 4.98e-10 : la regression de Longley
%
%   Voir aussi FPDF, FINV, FRND, FSTAT, PDF, CDF.
    superieure = false;
    if nargin >= 4
        if ~(ischar(queue) || (isstring(queue) && isscalar(queue))) || ...
                ~any(strcmpi(char(queue), {'upper', 'lower'}))
            error('stats:fcdf:BadTail', 'Tail must be ''lower'' or ''upper''.');
        end
        superieure = strcmpi(char(queue), 'upper');
    end
    tailles = {size(x), size(d1), size(d2)};
    nonScalaires = tailles(~[isscalar(x), isscalar(d1), isscalar(d2)]);
    for k = 2:numel(nonScalaires)
        if ~isequal(nonScalaires{k}, nonScalaires{1})
            error('stats:fcdf:InputSizeMismatch', 'Non-scalar arguments must match in size.');
        end
    end
    zero = zeros(size(x)) + zeros(size(d1)) + zeros(size(d2));
    x = double(x) + zero;
    d1 = double(d1) + zero;
    d2 = double(d2) + zero;
    if superieure
        p = betainc(d2 ./ (d2 + d1 .* x), d2 / 2, d1 / 2);
        p(x <= 0) = 1;
        p(isinf(x) & x > 0) = 0;
    else
        p = betainc(d1 .* x ./ (d1 .* x + d2), d1 / 2, d2 / 2);
        p(x <= 0) = 0;
        p(isinf(x) & x > 0) = 1;
    end
    p(~(d1 > 0) | ~(d2 > 0) | isnan(x)) = NaN;
end
