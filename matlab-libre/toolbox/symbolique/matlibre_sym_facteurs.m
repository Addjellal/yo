function [contenu, facteurs, reste] = matlibre_sym_facteurs(coefficients)
%MATLIBRE_SYM_FACTEURS Décomposition d'un polynôme entier sur les rationnels.
%   Rend le contenu — le PGCD des coefficients, signe du dominant
%   compris —, la liste des racines rationnelles avec leur multiplicité,
%   et le facteur qui reste après les avoir divisées.
%
%   Ce qui est garanti : le produit du contenu, des (x - r) et du reste
%   redonne exactement le polynôme de départ. Ce qui ne l'est pas : que
%   le reste soit irréductible. Un polynôme comme x^4 + 1 n'a aucune
%   racine rationnelle et se factorise pourtant sur les rationnels ; le
%   trouver demanderait autre chose que le théorème des racines
%   rationnelles, et FACTOR le dit dans son aide plutôt que de le taire.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [c, r, q] = matlibre_sym_facteurs([2 -6 4]);   % 2x^2 - 6x + 4
%      c                               % 2
%      isequal(r, [1 2])               % les deux racines
%      isequal(q, 1)                   % il ne reste rien
%
%   Voir aussi FACTOR, MATLIBRE_SYM_RACINES_RATIONNELLES.
    coefficients = double(coefficients(:)).';
    contenu = 1;
    facteurs = [];
    reste = coefficients;
    if isempty(coefficients) || all(coefficients == 0)
        reste = 0;
        return
    end
    if all(coefficients == round(coefficients))
        contenu = abs(coefficients(1));
        for k = 2:numel(coefficients)
            contenu = gcd(contenu, abs(coefficients(k)));
        end
        if contenu == 0
            contenu = 1;
        end
        if coefficients(1) < 0
            contenu = -contenu;
        end
        reste = coefficients / contenu;
    end
    facteurs = matlibre_sym_racines_rationnelles(reste);
    for r = facteurs
        reste = deconv(reste, [1 -r]);
    end
    reste = round(reste * 1e9) / 1e9;
end
