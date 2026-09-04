function statistique = matlibre_rapport_independance(echecs)
%MATLIBRE_RAPPORT_INDEPENDANCE Test d'indépendance de Christoffersen.
%   Compte les quatre transitions de la suite des dépassements, et compare
%   une chaîne de Markov à deux paramètres à une suite indépendante.
%   Grouper les dépassements est le défaut qu'aucun décompte global ne
%   voit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    echecs = double(echecs(:));
    if numel(echecs) < 2
        statistique = 0;
        return
    end
    avant = echecs(1:end-1);
    apres = echecs(2:end);
    n00 = sum(avant == 0 & apres == 0);
    n01 = sum(avant == 0 & apres == 1);
    n10 = sum(avant == 1 & apres == 0);
    n11 = sum(avant == 1 & apres == 1);
    total = n00 + n01 + n10 + n11;
    pi01 = matlibre_part(n01, n00 + n01);
    pi11 = matlibre_part(n11, n10 + n11);
    pi = matlibre_part(n01 + n11, total);
    if pi <= 0 || pi >= 1
        statistique = 0;
        return
    end
    sousNulle = (n00 + n10) * log(1 - pi) + (n01 + n11) * log(pi);
    sousLibre = terme(n00, 1 - pi01) + terme(n01, pi01) + ...
                terme(n10, 1 - pi11) + terme(n11, pi11);
    statistique = max(-2 * (sousNulle - sousLibre), 0);
end

function v = terme(compte, probabilite)
    if compte == 0
        v = 0;
    else
        v = compte * log(max(probabilite, realmin));
    end
end
