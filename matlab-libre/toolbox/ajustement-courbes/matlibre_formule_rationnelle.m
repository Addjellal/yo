function texte = matlibre_formule_rationnelle(haut, bas)
%MATLIBRE_FORMULE_RATIONNELLE Écriture d'une fraction de polynômes.
%   T = MATLIBRE_FORMULE_RATIONNELLE(HAUT,BAS) rend la formule du quotient
%   d'un polynôme de degré HAUT par un polynôme de degré BAS dont le
%   coefficient dominant vaut un — sans quoi numérateur et dénominateur
%   pourraient être multipliés par une même constante, et les
%   coefficients ne seraient pas déterminés.
%
%   Exemple :
%      matlibre_formule_rationnelle(1, 1)      % (p1*x + p2) / (x + q1)
%
%   Voir aussi FITTYPE, FIT.
    numerateur = matlibre_formule_polynome(haut);
    if bas == 0
        texte = sprintf('(%s)', numerateur);
        return
    end
    morceaux = cell(1, bas + 1);
    if bas == 1
        morceaux{1} = 'x';
    else
        morceaux{1} = sprintf('x^%d', bas);
    end
    for k = 1:bas
        puissance = bas - k;
        if puissance == 0
            morceaux{k + 1} = sprintf('q%d', k);
        elseif puissance == 1
            morceaux{k + 1} = sprintf('q%d*x', k);
        else
            morceaux{k + 1} = sprintf('q%d*x^%d', k, puissance);
        end
    end
    texte = sprintf('(%s) / (%s)', numerateur, strjoin(morceaux, ' + '));
end
