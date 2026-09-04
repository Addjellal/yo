function c = nominal(a, noms, ensemble)
%NOMINAL Tableau de catégories non ordonnées.
%   C = NOMINAL(A) transforme un tableau en catégories sans ordre : deux
%   catégories peuvent être égales ou différentes, jamais l'une avant
%   l'autre. C = NOMINAL(A,NOMS) leur donne d'autres noms,
%   NOMINAL(A,NOMS,ENSEMBLE) impose la liste et l'ordre de lecture.
%
%   C'est l'ancien type de MATLAB, remplacé par CATEGORICAL ; il en est
%   ici un synonyme, la propriété d'ordre étant simplement laissée à
%   faux.
%
%   Exemple :
%      couleurs = nominal({'rouge','vert','rouge'})
%      categories(couleurs)
%
%   Voir aussi ORDINAL, CATEGORICAL, CATEGORIES, ISCATEGORICAL.
    if nargin < 1
        c = categorical();
        return
    end
    if nargin < 3, ensemble = []; end
    if nargin < 2, noms = []; end
    c = categorical(a, ensemble, noms, 'Ordinal', false);
end
