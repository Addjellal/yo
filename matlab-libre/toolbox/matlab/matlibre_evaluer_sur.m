function y = matlibre_evaluer_sur(fonction, x)
%MATLIBRE_EVALUER_SUR Évalue une fonction sur un vecteur, vectorisée ou non.
%   Fonction interne : elle n'existe pas dans MATLAB. FPLOT, FSURF,
%   EZPLOT et FCONTOUR s'en servent : une poignée écrite avec « * » au
%   lieu de « .* » ne se vectorise pas, et il faut alors l'appeler point
%   par point plutôt que d'echouer.
    try
        y = fonction(x);
        y = y(:);
        if numel(y) == numel(x)
            return;
        end
        if isscalar(y)
            y = repmat(y, numel(x), 1);
            return;
        end
    catch
        % on passe a l'appel point par point
    end
    y = zeros(numel(x), 1);
    for k = 1:numel(x)
        v = fonction(x(k));
        y(k) = v(1);
    end
end
