function [x, reussi] = matlibre_lp_exact(f, A, b, Aeq, beq)
%MATLIBRE_LP_EXACT Programme linéaire résolu par régularisation quadratique.
%   Un programme linéaire atteint son optimum sur un sommet du polyèdre,
%   où une méthode de point intérieur ne se rend jamais tout à fait :
%   elle en approche sans l'atteindre. En ajoutant un terme quadratique
%   minuscule au critère, le problème devient un programme quadratique
%   strictement convexe, que la méthode des contraintes actives résout
%   exactement. Le terme est ensuite réduit tant que le critère linéaire
%   continue de s'améliorer : à la limite, la solution est le sommet.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    f = f(:);
    n = numel(f);
    echelle = max(norm(f), 1);
    x = [];
    reussi = false;
    for exposant = [-3 -5 -7 -9 -11]
        epsilon = echelle * 10 ^ exposant;
        [candidat, bon] = matlibre_qp_actif(2 * epsilon * eye(n), f, A, b, Aeq, beq);
        if ~bon
            break
        end
        x = candidat;
        reussi = true;
    end
end
