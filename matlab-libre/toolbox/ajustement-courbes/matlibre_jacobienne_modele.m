function J = matlibre_jacobienne_modele(modele, coefficients, imposees, x)
%MATLIBRE_JACOBIENNE_MODELE Dérivées du modèle par rapport aux coefficients.
%   J = MATLIBRE_JACOBIENNE_MODELE(MODELE,COEFFICIENTS,IMPOSEES,X) rend la
%   matrice dont la colonne k est la dérivée du modèle par rapport au
%   coefficient k, par différence centrée. C'est elle qui donne la
%   covariance des coefficients, donc leurs intervalles de confiance.
%
%   Le pas est proportionnel à l'ordre de grandeur du coefficient, avec un
%   plancher : un pas fixe serait trop grand pour un coefficient minuscule
%   et perdu dans l'arrondi pour un grand.
%
%   Exemple :
%      J = matlibre_jacobienne_modele(fittype('poly1'), [2 1], {}, [1; 2]);
%      J      % [1 1; 2 1]
%
%   Voir aussi FIT, CONFINT, PREDINT.
    coefficients = double(coefficients(:)).';
    n = numel(coefficients);
    x = x(:);
    J = zeros(numel(x), n);
    for k = 1:n
        pas = max(abs(coefficients(k)), 1) * 1e-6;
        avant = coefficients; avant(k) = avant(k) + pas;
        apres = coefficients; apres(k) = apres(k) - pas;
        haut = matlibre_evaluer_modele(modele, [{avant}, imposees, {x}]);
        bas = matlibre_evaluer_modele(modele, [{apres}, imposees, {x}]);
        J(:, k) = (haut - bas) / (2 * pas);
    end
end
