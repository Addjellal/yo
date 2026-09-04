function [ajustement, qualite, sortie] = matlibre_ajuster_surface(xy, z, modele, arguments)
%MATLIBRE_AJUSTER_SURFACE Ajuste un modèle à deux variables.
%   [SO,QUALITE,SORTIE] = MATLIBRE_AJUSTER_SURFACE(XY,Z,MODELE,ARGUMENTS)
%   ajuste la surface aux triplets donnés. XY a deux colonnes.
%
%   Les modèles polynomiaux sont linéaires en leurs coefficients : la
%   résolution est directe. Les interpolants passent par une
%   triangulation, ou par une régression locale pour 'lowess' et 'loess'.
%
%   Exemple :
%      [x, y] = meshgrid(0:0.2:1, 0:0.2:1);
%      z = 1 + 2*x - 3*y + x.*y;
%      so = fit([x(:) y(:)], z(:), 'poly22');
%
%   Voir aussi FIT, SFIT, PREPARESURFACEDATA.
    if ~isa(modele, 'fittype')
        nom = modele;
        modele = fittype(nom);
        if isempty(modele.Coefficients) || numel(modele.Independent) < 2
            surface = matlibre_modele_surface(nom);
            if isempty(surface)
                error('curvefit:fit:Surface', ...
                      'Modèle de surface inconnu : %s.', char(nom));
            end
            modele = matlibre_fittype_surface(surface);
        end
    end
    [options, imposees] = matlibre_fit_options(modele, arguments);
    garde = isfinite(xy(:, 1)) & isfinite(xy(:, 2)) & isfinite(z);
    if ~isempty(options.Exclude)
        exclus = options.Exclude;
        if islogical(exclus)
            garde = garde & ~exclus(:);
        else
            masque = false(numel(z), 1);
            masque(exclus) = true;
            garde = garde & ~masque;
        end
    end
    xy = xy(garde, :);
    z = z(garde);
    if isempty(options.Weights)
        poids = ones(numel(z), 1);
    else
        poids = double(options.Weights(:));
        poids = poids(garde);
    end
    if strcmp(modele.Categorie, 'interpolant')
        interpolant = struct('genre', 'surface', 'methode', modele.Type, ...
                             'xy', xy, 'z', z, 'span', options.Span);
        coefficients = [];
        valeurs = matlibre_evaluer_surface(interpolant, xy);
        jacobienne = [];
        nombreParametres = numel(z);
    else
        A = modele.Base(xy);
        [coefficients, jacobienne] = matlibre_ajuster_lineaire(A, z, poids, options);
        interpolant = [];
        valeurs = A * coefficients(:);
        nombreParametres = numel(coefficients);
    end
    residus = z - valeurs;
    ajustement = sfit(modele, coefficients, imposees, interpolant, residus, ...
                      jacobienne, poids, numel(z) - nombreParametres);
    qualite = matlibre_qualite_ajustement(z, residus, poids, nombreParametres);
    if nargout > 2
        sortie = struct('numobs', numel(z), 'numparam', nombreParametres, ...
                        'residuals', residus, 'Jacobian', jacobienne, ...
                        'exitflag', 1, 'algorithm', options.Method, 'iterations', 0);
    end
end
