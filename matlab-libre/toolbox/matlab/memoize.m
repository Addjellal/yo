function mf = memoize(f)
%MEMOIZE Garde les résultats d'une fonction.
%   MF = MEMOIZE(F) rend un objet qui s'appelle comme F mais retient ce
%   qu'il a déjà calculé : le même jeu d'arguments n'est calculé qu'une
%   fois. C'est utile pour une fonction lente et pure — dont le résultat
%   ne dépend que de ses arguments.
%
%   Sur l'objet rendu :
%      MF.Enabled     mettre à false pour recalculer chaque fois
%      MF.CacheSize   nombre de jeux d'arguments retenus (10 par défaut)
%      clearCache(MF) vide le cache
%      stats(MF)      compte les appels, les trouvailles et les calculs
%
%   Exemple :
%      lent = @(n) sum(primes(n));
%      rapide = memoize(lent);
%      rapide(100000);      % calculé
%      rapide(100000);      % retrouvé
%
%   Voir aussi FUNCTION_HANDLE, CONTAINERS.MAP, TIC, TOC.
    if ~isa(f, 'function_handle')
        error('MATLAB:memoize:NotAFunctionHandle', ...
              'memoize attend une poignée de fonction.');
    end
    mf = MemoizedFunction(f);
end
