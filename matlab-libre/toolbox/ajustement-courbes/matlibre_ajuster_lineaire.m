function [coefficients, jacobienne] = matlibre_ajuster_lineaire(A, y, poids, options)
%MATLIBRE_AJUSTER_LINEAIRE Moindres carrés, éventuellement robustes.
%   [C,J] = MATLIBRE_AJUSTER_LINEAIRE(A,Y,POIDS,OPTIONS) résout le système
%   pondéré au sens des moindres carrés. Le modèle étant linéaire, la
%   solution est directe et c'est le minimum global : ni point de départ,
%   ni itération.
%
%   Avec l'option Robust, les poids sont recalculés à chaque tour d'après
%   les résidus : un point très éloigné voit son poids tomber, et cesse
%   d'emporter l'ajustement. C'est la moindre carrée itérativement
%   repondérée.
%
%   Exemple :
%      c = matlibre_ajuster_lineaire([1 1; 2 1], [3; 5], [1; 1], fitoptions());
%      c      % 2 et 1
%
%   Voir aussi FIT, ROBUSTFIT.
    racine = sqrt(poids(:));
    coefficients = ((A .* racine) \ (y(:) .* racine)).';
    jacobienne = A;
    if isempty(options.Robust) || strcmpi(options.Robust, 'off')
        return
    end
    reglage = matlibre_reglage_robuste(options.Robust);
    for tour = 1:20
        residus = y(:) - A * coefficients(:);
        poidsRobustes = poids(:) .* matlibre_poids_robustes(residus, size(A, 2), reglage);
        racine = sqrt(poidsRobustes);
        nouveaux = ((A .* racine) \ (y(:) .* racine)).';
        if max(abs(nouveaux - coefficients)) < 1e-10 * max(1, max(abs(nouveaux)))
            coefficients = nouveaux;
            break
        end
        coefficients = nouveaux;
    end
end
