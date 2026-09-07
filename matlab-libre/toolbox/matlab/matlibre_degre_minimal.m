function p = matlibre_degre_minimal(A)
%MATLIBRE_DEGRE_MINIMAL Ordre d'élimination par degré minimal exact.
%   À chaque pas on élimine le nœud de plus petit degré et l'on relie
%   entre eux ses voisins : c'est exactement ce que fait un pas de
%   factorisation, et le graphe suffit à prévoir le remplissage.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      p = matlibre_degre_minimal(ones(3));
%      isequal(sort(p), 1:3)          % 1
%
%   Voir aussi SYMAMD, COLAMD, SYMRCM.
    G = full(double(A ~= 0));
    n = size(G, 1);
    G = logical(G | G');
    G(1:n+1:end) = false;
    vivant = true(n, 1);
    p = zeros(1, n);
    for pas = 1:n
        degres = sum(G(:, vivant), 2);
        degres(~vivant) = inf;
        [~, choisi] = min(degres);
        p(pas) = choisi;
        voisins = find(G(choisi, :) & vivant');
        % L'elimination relie entre eux tous les voisins : c'est le
        % remplissage, et le simuler suffit a le prevoir.
        for a = voisins
            for b = voisins
                if a ~= b
                    G(a, b) = true;
                end
            end
        end
        vivant(choisi) = false;
        G(choisi, :) = false;
        G(:, choisi) = false;
    end
end
