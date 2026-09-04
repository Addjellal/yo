function J = matlibre_jacobienne_residu(fonction, p, residu)
%MATLIBRE_JACOBIENNE_RESIDU Jacobienne d'un vecteur de résidus.
%   J = MATLIBRE_JACOBIENNE_RESIDU(FONCTION,P,RESIDU) rend la matrice des
%   dérivées de chaque résidu par rapport à chaque paramètre, par
%   différence centrée. C'est elle qui donne la covariance des paramètres
%   ajustés, donc leurs intervalles de confiance.
%
%   Exemple :
%      J = matlibre_jacobienne_residu(@(p) p(1) * [1; 2], 1, [1; 2]);
%      J      % [1; 2]
%
%   Voir aussi LSQCURVEFIT, LSQNONLIN, NLPARCI.
    p = p(:);
    n = numel(p);
    J = zeros(numel(residu), n);
    for k = 1:n
        pas = max(abs(p(k)), 1) * 1e-7;
        avant = p; avant(k) = avant(k) + pas;
        apres = p; apres(k) = apres(k) - pas;
        haut = fonction(avant);
        bas = fonction(apres);
        J(:, k) = (haut(:) - bas(:)) / (2 * pas);
    end
end
