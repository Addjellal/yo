function texte = matlibre_formule_surface(puissances, noms)
%MATLIBRE_FORMULE_SURFACE Écriture d'un polynôme à deux variables.
%   T = MATLIBRE_FORMULE_SURFACE(PUISSANCES,NOMS) rend la formule telle
%   que l'affiche un objet d'ajustement de surface.
%
%   Exemple :
%      [p, n] = matlibre_termes_surface(1, 1);
%      matlibre_formule_surface(p, n)      % p00 + p10*x + p01*y
%
%   Voir aussi MATLIBRE_MODELE_SURFACE.
    morceaux = cell(1, numel(noms));
    for k = 1:numel(noms)
        a = puissances(k, 1);
        b = puissances(k, 2);
        facteurs = {noms{k}};
        if a == 1
            facteurs{end + 1} = 'x';                    %#ok<AGROW>
        elseif a > 1
            facteurs{end + 1} = sprintf('x^%d', a);     %#ok<AGROW>
        end
        if b == 1
            facteurs{end + 1} = 'y';                    %#ok<AGROW>
        elseif b > 1
            facteurs{end + 1} = sprintf('y^%d', b);     %#ok<AGROW>
        end
        morceaux{k} = strjoin(facteurs, '*');
    end
    texte = strjoin(morceaux, ' + ');
end
