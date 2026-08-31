function Z = matlibre_evaluer_grille(fonction, X, Y)
%MATLIBRE_EVALUER_GRILLE Évalue une fonction de deux variables sur une grille.
%   Fonction interne : elle n'existe pas dans MATLAB. FSURF, FMESH et
%   FCONTOUR s'en servent ; comme pour une variable, une poignée non
%   vectorisée est appelée point par point plutôt que de faire échouer le
%   tracé.
    try
        Z = fonction(X, Y);
        if isequal(size(Z), size(X))
            return;
        end
        if isscalar(Z)
            Z = repmat(Z, size(X));
            return;
        end
    catch
        % on passe a l'appel point par point
    end
    Z = zeros(size(X));
    for i = 1:size(X, 1)
        for j = 1:size(X, 2)
            v = fonction(X(i, j), Y(i, j));
            Z(i, j) = v(1);
        end
    end
end
