function valeur = matlibre_integrer_ajustement(ajustement, x, depart)
%MATLIBRE_INTEGRER_AJUSTEMENT Primitive d'une courbe ajustée.
%   V = MATLIBRE_INTEGRER_AJUSTEMENT(FO,X,X0) rend l'intégrale de la
%   courbe entre X0 et chaque X. Une spline est intégrée exactement ; un
%   modèle écrit en formule l'est par la méthode de Simpson sur une grille
%   fine, exacte pour tout polynôme de degré trois.
%
%   Exemple :
%      fo = fit((0:0.1:2)', (0:0.1:2)'.^2, 'poly2');
%      matlibre_integrer_ajustement(fo, 3, 0)      % environ 9
%
%   Voir aussi INTEGRATE, DIFFERENTIATE.
    x = double(x);
    forme = size(x);
    colonne = x(:);
    if ~isempty(ajustement.Interpolant) && strcmp(ajustement.Interpolant.genre, 'pp')
        xa = (colonne - ajustement.Normalisation(1)) / ajustement.Normalisation(2);
        departA = (depart - ajustement.Normalisation(1)) / ajustement.Normalisation(2);
        primitive = fnint(ajustement.Interpolant.pp);
        valeur = (ppval(primitive, xa) - ppval(primitive, departA)) * ...
                 ajustement.Normalisation(2);
        valeur = reshape(valeur, forme);
        return
    end
    valeur = zeros(numel(colonne), 1);
    for k = 1:numel(colonne)
        valeur(k) = matlibre_simpson(@(t) feval(ajustement, t), depart, colonne(k), 400);
    end
    valeur = reshape(valeur, forme);
end
