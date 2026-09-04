function texte = matlibre_formule_polynome(ordre)
%MATLIBRE_FORMULE_POLYNOME Écriture d'un polynôme, en toutes lettres.
%   T = MATLIBRE_FORMULE_POLYNOME(ORDRE) rend la formule du modèle
%   polynomial de cet ordre, telle que l'affiche un objet d'ajustement.
%
%   Exemple :
%      matlibre_formule_polynome(2)      % p1*x^2 + p2*x + p3
%
%   Voir aussi FITTYPE, FORMULA.
    morceaux = cell(1, ordre + 1);
    for k = 1:(ordre + 1)
        puissance = ordre + 1 - k;
        if puissance == 0
            morceaux{k} = sprintf('p%d', k);
        elseif puissance == 1
            morceaux{k} = sprintf('p%d*x', k);
        else
            morceaux{k} = sprintf('p%d*x^%d', k, puissance);
        end
    end
    texte = strjoin(morceaux, ' + ');
end
