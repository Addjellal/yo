function sortie = adapterBlanc(xyz, blancSource, blancCible)
%ADAPTERBLANC Adaptation chromatique de von Kries, en coordonnées XYZ.
%   Chaque axe est mis à l'échelle du rapport des blancs. C'est la forme
%   la plus simple de l'adaptation, celle que MATLAB emploie par défaut
%   pour les conversions entre illuminants.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      D65 = [0.95047 1 1.08883];
%      A = [1.0985 1 0.3558];
%      max(abs(adapterBlanc(D65, D65, A) - A)) < 1e-9   % le blanc source devient le blanc cible
    facteurs = blancCible(:)' ./ blancSource(:)';
    sortie = appliquerMatriceCouleur(xyz, diag(facteurs));
end
