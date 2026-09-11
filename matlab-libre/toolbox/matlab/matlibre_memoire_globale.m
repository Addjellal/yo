function sortie = matlibre_memoire_globale(action, objet)
%MATLIBRE_MEMOIRE_GLOBALE Registre des fonctions mémoïsées vivantes.
%   Chaque MEMOIZEDFUNCTION s'y inscrit à sa construction, ce qui permet
%   à CLEARALLMEMOIZEDCACHES de toutes les vider d'un coup. C'est
%   possible parce que MEMOIZEDFUNCTION est une classe à poignée : le
%   registre garde la même chose que l'appelant, non une copie.
%
%   Le registre retient donc ses objets aussi longtemps que la session
%   dure. C'est le prix à payer pour pouvoir les atteindre, et MATLAB
%   fait de même.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      avant = matlibre_memoire_globale('compter');
%      f = memoize(@(x) x);
%      matlibre_memoire_globale('compter') > avant
%
%   Voir aussi MEMOIZE, CLEARALLMEMOIZEDCACHES, MEMOIZEDFUNCTION.
    persistent liste
    if isempty(liste)
        liste = {};
    end
    sortie = [];
    switch lower(char(action))
        case 'inscrire'
            liste{end + 1} = objet;
        case 'vider'
            for k = 1:numel(liste)
                clearCache(liste{k});
            end
        case 'compter'
            sortie = numel(liste);
        case 'oublier'
            liste = {};
        otherwise
            error('MATLAB:memoire:action', 'Action inconnue : %s.', char(action));
    end
end
