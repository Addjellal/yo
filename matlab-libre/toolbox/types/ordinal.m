function c = ordinal(a, noms, ensemble)
%ORDINAL Tableau de catégories ordonnées.
%   C = ORDINAL(A) transforme un tableau en catégories rangées : les
%   comparaisons < <= > >= deviennent licites, l'ordre étant celui de la
%   liste des catégories. C = ORDINAL(A,NOMS) leur donne d'autres noms,
%   ORDINAL(A,NOMS,ENSEMBLE) impose la liste, donc l'ordre.
%
%   La différence avec NOMINAL n'est pas de forme mais de sens : dire
%   qu'une taille est « petite », « moyenne » ou « grande » autorise à
%   les comparer, dire qu'une couleur est « rouge » ou « verte » ne
%   l'autorise pas.
%
%   C'est l'ancien type de MATLAB, remplacé par CATEGORICAL avec
%   l'option 'Ordinal'.
%
%   Exemple :
%      tailles = ordinal({'moyen','petit','grand'}, [], {'petit','moyen','grand'});
%      tailles > 'petit'
%
%   Voir aussi NOMINAL, CATEGORICAL, CATEGORIES, ISORDINAL.
    if nargin < 1
        c = categorical([], [], [], 'Ordinal', true);
        return
    end
    if nargin < 3, ensemble = []; end
    if nargin < 2, noms = []; end
    c = categorical(a, ensemble, noms, 'Ordinal', true);
end
