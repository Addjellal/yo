function [marque, seuilBas, seuilHaut, centre] = matlibre_aberrantes(v, methode, ...
                                                                     facteur, centiles)
%MATLIBRE_ABERRANTES Seuils d'un vecteur, selon le critère demandé.
%   Rend le masque des valeurs aberrantes et les seuils employés. Les
%   valeurs manquantes ne sont jamais marquées : elles relèvent
%   d'ISMISSING, non d'ISOUTLIER.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi ISOUTLIER, FILLOUTLIERS, RMOUTLIERS.
    v = v(:);
    connus = v(~isnan(v));
    if isempty(connus)
        marque = false(size(v));
        seuilBas = NaN;
        seuilHaut = NaN;
        centre = NaN;
        return
    end
    switch methode
        case 'median'
            if isempty(facteur), facteur = 3; end
            centre = median(connus);
            % 1.4826 rend l'écart absolu médian comparable à l'écart type
            % sous hypothèse gaussienne.
            dispersion = 1.4826 * median(abs(connus - centre));
            seuilBas = centre - facteur * dispersion;
            seuilHaut = centre + facteur * dispersion;
        case 'mean'
            if isempty(facteur), facteur = 3; end
            centre = mean(connus);
            dispersion = std(connus);
            seuilBas = centre - facteur * dispersion;
            seuilHaut = centre + facteur * dispersion;
        case 'quartiles'
            if isempty(facteur), facteur = 1.5; end
            q = prctile(connus, [25 50 75]);
            centre = q(2);
            interquartile = q(3) - q(1);
            seuilBas = q(1) - facteur * interquartile;
            seuilHaut = q(3) + facteur * interquartile;
        case 'grubbs'
            [marque, seuilBas, seuilHaut, centre] = grubbs(v, facteur);
            return
        case 'percentiles'
            bornes = prctile(connus, centiles);
            centre = median(connus);
            seuilBas = bornes(1);
            seuilHaut = bornes(2);
        otherwise
            error('MATLAB:isoutlier:Methode', 'Méthode inconnue : %s.', methode);
    end
    marque = v < seuilBas | v > seuilHaut;
    marque(isnan(v)) = false;
end

function [marque, seuilBas, seuilHaut, centre] = grubbs(v, alpha)
%GRUBBS Test de Grubbs, appliqué une valeur à la fois.
%   Le test compare le plus grand écart réduit à un seuil tiré de la loi
%   de Student. Retirer la valeur trouvée puis recommencer est nécessaire :
%   une seconde aberrante masque la première en gonflant l'écart type.
    if isempty(alpha), alpha = 0.05; end
    marque = false(size(v));
    restants = ~isnan(v);
    while true
        echantillon = v(restants);
        n = numel(echantillon);
        if n < 3
            break
        end
        centreCourant = mean(echantillon);
        dispersion = std(echantillon);
        if dispersion == 0
            break
        end
        ecarts = abs(echantillon - centreCourant) / dispersion;
        [maximum, position] = max(ecarts);
        t = tinv(alpha / (2 * n), n - 2);
        critique = (n - 1) / sqrt(n) * sqrt(t ^ 2 / (n - 2 + t ^ 2));
        if maximum <= critique
            break
        end
        indices = find(restants);
        marque(indices(position)) = true;
        restants(indices(position)) = false;
    end
    connus = v(~isnan(v) & ~marque);
    centre = mean(connus);
    dispersion = std(connus);
    seuilBas = centre - 3 * dispersion;
    seuilHaut = centre + 3 * dispersion;
end
