function varargout = pararrayfun(fonction, varargin)
%PARARRAYFUN Équivalent parallèle d'ARRAYFUN.
%   V = PARARRAYFUN(F,A) applique F à chaque élément de A, chacun sur un
%   travailleur du pool, et rend les résultats dans l'ordre des indices.
%   PARARRAYFUN(F,A,B,...) apparie les tableaux élément par élément.
%
%   Options, comme ARRAYFUN :
%      'UniformOutput'  false pour rendre une cellule
%      'ErrorHandler'   une poignée appelée quand F échoue
%
%   [X,Y,...] = PARARRAYFUN(...) rend autant de sorties que F en donne.
%
%   Le résultat est exactement celui d'ARRAYFUN : c'est la garantie qui
%   fait tout l'intérêt de la fonction, et elle interdit à F de dépendre
%   de l'ordre d'exécution ou d'un état partagé. Une fonction qui
%   accumule dans une variable extérieure, ou qui tire au sort, ne se
%   parallélise pas ainsi.
%
%   Exemple :
%      pararrayfun(@(x) x^2, 1:4)                    % [1 4 9 16]
%      pararrayfun(@(n) ones(1,n), 1:3, 'UniformOutput', false)
%
%   Voir aussi PARCELLFUN, ARRAYFUN, PARFEVAL, DISTRIBUTED.
    [entrees, options] = matlibre_par_options(varargin, ...
                                              {'UniformOutput', 'ErrorHandler'});
    varargout = matlibre_par_appliquer(fonction, entrees, options, ...
                                       @(a, i) a(i), nargout);
end
