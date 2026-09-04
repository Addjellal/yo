function points = matlibre_nuage_points(nuage)
%MATLIBRE_NUAGE_POINTS Coordonnées d'un nuage, ramenées en trois colonnes.
%   Un nuage organisé — un tableau M×N×3 — est déplié ligne à ligne ; un
%   nuage déjà rangé passe tel quel. Accepte aussi une matrice brute, ce
%   qui évite d'envelopper un nuage pour un seul appel.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isa(nuage, 'pointCloud')
        brut = nuage.Location;
    else
        brut = double(nuage);
    end
    if ndims(brut) == 3
        points = reshape(brut, [], 3);
    else
        points = brut;
    end
    if size(points, 2) ~= 3
        error('vision:nuage:Forme', ...
              'Un nuage de points a trois colonnes, ou trois plans.');
    end
end
