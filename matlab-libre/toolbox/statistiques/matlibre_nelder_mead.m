function meilleur = matlibre_nelder_mead(objectif, depart, maximum, tolerance)
%MATLIBRE_NELDER_MEAD Minimisation par simplexe, sans dérivée.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   qui emploie FMINSEARCH. MLE s'en sert pour ne pas dépendre de la
%   boîte à outils d'optimisation.
%
%   MEILLEUR = MATLIBRE_NELDER_MEAD(F,P0,MAXITER,TOL) minimise F à partir
%   de P0. La méthode déforme un simplexe de N+1 points : elle réfléchit
%   le plus mauvais sommet à travers le centre des autres, l'étend si
%   cela va mieux encore, le contracte sinon, et rétrécit tout le
%   simplexe quand rien ne marche.
    p = numel(depart);
    simplexe = zeros(p + 1, p);
    valeurs = zeros(p + 1, 1);
    simplexe(1, :) = depart;
    for i = 1:p
        sommet = depart;
        if sommet(i) ~= 0
            sommet(i) = sommet(i) * 1.05;
        else
            sommet(i) = 0.00025;
        end
        simplexe(i + 1, :) = sommet;
    end
    for i = 1:p + 1
        valeurs(i) = objectif(simplexe(i, :));
    end
    for iteration = 1:maximum * (p + 1)
        [valeurs, ordre] = sort(valeurs);
        simplexe = simplexe(ordre, :);
        if max(max(abs(simplexe(2:end, :) - repmat(simplexe(1, :), p, 1)))) <= ...
           tolerance * (1 + max(abs(simplexe(1, :)))) && ...
           abs(valeurs(end) - valeurs(1)) <= tolerance * (1 + abs(valeurs(1)))
            break;
        end
        centre = mean(simplexe(1:p, :), 1);
        reflechi = centre + (centre - simplexe(end, :));
        valeurReflechie = objectif(reflechi);
        if valeurReflechie < valeurs(1)
            etendu = centre + 2 * (centre - simplexe(end, :));
            valeurEtendue = objectif(etendu);
            if valeurEtendue < valeurReflechie
                simplexe(end, :) = etendu;
                valeurs(end) = valeurEtendue;
            else
                simplexe(end, :) = reflechi;
                valeurs(end) = valeurReflechie;
            end
        elseif valeurReflechie < valeurs(p)
            simplexe(end, :) = reflechi;
            valeurs(end) = valeurReflechie;
        else
            if valeurReflechie < valeurs(end)
                contracte = centre + 0.5 * (reflechi - centre);
            else
                contracte = centre + 0.5 * (simplexe(end, :) - centre);
            end
            valeurContractee = objectif(contracte);
            if valeurContractee < min(valeurReflechie, valeurs(end))
                simplexe(end, :) = contracte;
                valeurs(end) = valeurContractee;
            else
                % Rien n'a marché : on rétrécit tout vers le meilleur.
                for i = 2:p + 1
                    simplexe(i, :) = simplexe(1, :) + ...
                                     0.5 * (simplexe(i, :) - simplexe(1, :));
                    valeurs(i) = objectif(simplexe(i, :));
                end
            end
        end
    end
    [~, meilleurRang] = min(valeurs);
    meilleur = simplexe(meilleurRang, :);
end
