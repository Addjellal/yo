function p = tcdf(x, nu, queue)
%TCDF Fonction de répartition de la loi de Student.
%   P = TCDF(T,NU) utilise la relation avec la fonction beta incomplète :
%      P(T <= t) = 1 - I_{nu/(nu+t^2)}(nu/2, 1/2) / 2   pour t >= 0
%   ce qui est exact et rapide, contrairement à une intégration numérique.
%   T et NU ont la même taille, ou l'un est scalaire. NU infini donne la
%   loi normale.
%
%   P = TCDF(T,NU,'upper') rend la queue supérieure P(T > t), calculée
%   directement : une p-valeur de 1e-12 garde ses chiffres, ce que
%   1 - TCDF(T,NU) ne peut pas faire.
%
%   Exemple :
%      tcdf(0, 10)                 % 0.5 : la loi de Student est symetrique
%      tcdf(8, 10, 'upper')        % 5.9e-06
%
%   Voir aussi TINV, TRND, TSTAT, PDF, CDF, ICDF.
    superieure = false;
    if nargin >= 3
        superieure = lireQueue(true, queue);
    end
    if ~isequal(size(x), size(nu)) && ~isscalar(x) && ~isscalar(nu)
        error('stats:tcdf:InputSizeMismatch', 'Non-scalar arguments must match in size.');
    end
    x = double(x) + zeros(size(nu));
    nu = double(nu) + zeros(size(x));
    % La queue au-delà de |x| : P(T > |x|) = I_{nu/(nu+x^2)}(nu/2,1/2)/2.
    au_dela = 0.5 * betainc(nu ./ (nu + x .^ 2), nu / 2, 0.5);
    positif = x >= 0;
    p = au_dela;
    if superieure
        p(~positif) = 1 - au_dela(~positif);
    else
        p(positif) = 1 - au_dela(positif);
    end
    infini = isinf(nu) & nu > 0;
    if any(infini(:))
        if superieure
            p(infini) = normcdf(x(infini), 0, 1, 'upper');
        else
            p(infini) = normcdf(x(infini));
        end
    end
    p(~(nu > 0) | isnan(x)) = NaN;
end

function superieure = lireQueue(donnee, queue)
    superieure = false;
    if ~donnee
        return
    end
    if ~(ischar(queue) || (isstring(queue) && isscalar(queue))) || ...
            ~any(strcmpi(char(queue), {'upper', 'lower'}))
        error('stats:tcdf:BadTail', 'Tail must be ''lower'' or ''upper''.');
    end
    superieure = strcmpi(char(queue), 'upper');
end
