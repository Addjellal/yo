function positions = matlibre_chien(localisateur, n, m, prim, journal, exponentielle)
%MATLIBRE_CHIEN Recherche de Chien : les positions en erreur.
%   On évalue le localisateur en chaque alpha^(-i) : une racine désigne
%   la position i. C'est un parcours exhaustif, mais la seule façon sûre
%   de trouver toutes les racines dans un corps fini.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 5
        [journal, exponentielle] = matlibre_gf_journal(m, prim);
    end
    ordre = 2 ^ m - 1;
    positions = [];
    for i = 0:(n - 1)
        valeur = 0;
        for j = 1:numel(localisateur)
            if localisateur(j) == 0
                continue
            end
            exposant = mod(journal(localisateur(j) + 1) - (j - 1) * i, ordre);
            valeur = bitxor(valeur, exponentielle(exposant + 1));
        end
        if valeur == 0
            positions(end + 1) = i;   %#ok<AGROW>
        end
    end
end
