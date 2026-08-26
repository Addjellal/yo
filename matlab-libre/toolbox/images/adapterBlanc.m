function sortie = adapterBlanc(xyz, blancSource, blancCible)
%ADAPTERBLANC Adaptation chromatique de von Kries, en coordonnées XYZ.
%   Chaque axe est mis à l'échelle du rapport des blancs. C'est la forme
%   la plus simple de l'adaptation, celle que MATLAB emploie par défaut
%   pour les conversions entre illuminants.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    facteurs = blancCible(:)' ./ blancSource(:)';
    sortie = appliquerMatriceCouleur(xyz, diag(facteurs));
end
