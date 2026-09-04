function [coefficients, residus, jacobienne, iterations] = ...
        matlibre_ajuster_nonlineaire(modele, x, y, poids, options, imposees)
%MATLIBRE_AJUSTER_NONLINEAIRE Moindres carrés non linéaires.
%   [C,R,J,N] = MATLIBRE_AJUSTER_NONLINEAIRE(MODELE,X,Y,POIDS,OPTIONS,
%   IMPOSEES) minimise la somme pondérée des carrés des écarts, depuis le
%   point de départ donné ou déduit des données.
%
%   Le point de départ décide de tout : un modèle non linéaire a
%   plusieurs minimums, et la descente trouve celui dont elle est partie.
%   Chaque modèle de la bibliothèque a donc son heuristique — une droite
%   sur les logarithmes pour une exponentielle, la raie spectrale
%   dominante pour une sinusoïde.
%
%   Exemple :
%      % appelée par FIT
%
%   Voir aussi FIT, LSQCURVEFIT.
    depart = options.StartPoint;
    if isempty(depart)
        if ~isempty(modele.Depart)
            depart = modele.Depart(x, y);
        else
            depart = ones(1, numel(modele.Coefficients));
        end
    end
    depart = double(depart(:)).';
    racine = sqrt(poids(:));
    fonction = @(c, xx) matlibre_evaluer_modele(modele, [{c}, imposees, {xx}]) .* racine;
    cible = y(:) .* racine;
    reglages = optimset('MaxIter', options.MaxIter, 'TolFun', options.TolFun, ...
                        'TolX', options.TolX, 'Display', 'off');
    borneBasse = matlibre_bornes_completes(options.Lower, numel(depart), -inf);
    borneHaute = matlibre_bornes_completes(options.Upper, numel(depart), inf);
    depart = min(max(depart, borneBasse), borneHaute);
    [coefficients, ~, ~, ~, details] = ...
        lsqcurvefit(fonction, depart, x, cible, borneBasse, borneHaute, reglages);
    coefficients = coefficients(:).';
    if ~isempty(options.Robust) && ~strcmpi(options.Robust, 'off')
        reglage = matlibre_reglage_robuste(options.Robust);
        for tour = 1:10
            ecarts = y(:) - matlibre_evaluer_modele(modele, [{coefficients}, imposees, {x}]);
            robustes = poids(:) .* matlibre_poids_robustes(ecarts, numel(coefficients), reglage);
            racine = sqrt(robustes);
            fonction = @(c, xx) matlibre_evaluer_modele(modele, [{c}, imposees, {xx}]) .* racine;
            nouveaux = lsqcurvefit(fonction, coefficients, x, y(:) .* racine, ...
                                   borneBasse, borneHaute, reglages);
            nouveaux = nouveaux(:).';
            if max(abs(nouveaux - coefficients)) < 1e-10 * max(1, max(abs(nouveaux)))
                coefficients = nouveaux;
                break
            end
            coefficients = nouveaux;
        end
    end
    residus = y(:) - matlibre_evaluer_modele(modele, [{coefficients}, imposees, {x}]);
    jacobienne = matlibre_jacobienne_modele(modele, coefficients, imposees, x);
    iterations = 0;
    if isstruct(details) && isfield(details, 'iterations')
        iterations = details.iterations;
    end
end
