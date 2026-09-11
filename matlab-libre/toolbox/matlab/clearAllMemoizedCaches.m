function clearAllMemoizedCaches()
%CLEARALLMEMOIZEDCACHES Vide les caches de toutes les fonctions mémoïsées.
%   Une fonction mémoïsée retient ses résultats. Si ce dont elle dépend
%   change sans que ses arguments changent — un fichier relu, une
%   variable globale —, ce qu'elle retient devient faux : c'est le seul
%   défaut de la mémoïsation, et vider le cache est le remède.
%
%   Vider le cache d'un seul objet se fait par CLEARCACHE.
%
%   Exemple :
%      f = memoize(@(x) x + 1);
%      f(1); f(1);
%      clearAllMemoizedCaches();
%      f(1);
%      s = stats(f);
%      s.CacheOccupancyPercent         % le cache s'est rempli a nouveau
%
%   Voir aussi MEMOIZE, CLEARCACHE, STATS.
    matlibre_memoire_globale('vider');
end
