function decalages = voisinageConnexite(connexite)
%VOISINAGECONNEXITE Décalages [di dj] d'une connexité 2-D.
%   Accepte 4, 8 ou un tableau logique 3 x 3.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if numel(connexite) == 1
        if connexite == 4
            decalages = [-1 0; 1 0; 0 -1; 0 1];
        else
            decalages = [-1 -1; -1 0; -1 1; 0 -1; 0 1; 1 -1; 1 0; 1 1];
        end
        return
    end
    masque = logical(connexite);
    decalages = zeros(0, 2);
    for a = 1:size(masque, 1)
        for b = 1:size(masque, 2)
            if masque(a, b) && ~(a == 2 && b == 2)
                decalages(end + 1, :) = [a - 2, b - 2];   %#ok<AGROW>
            end
        end
    end
end
