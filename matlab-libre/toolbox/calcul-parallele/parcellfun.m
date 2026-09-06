function varargout = parcellfun(fonction, varargin)
%PARCELLFUN Équivalent parallèle de CELLFUN.
%   V = PARCELLFUN(F,C) applique F au contenu de chaque case de C, chacune
%   sur un travailleur du pool.
%   PARCELLFUN(F,C,D,...) apparie les cellules case par case.
%
%   Options, comme CELLFUN :
%      'UniformOutput'  false pour rendre une cellule
%      'ErrorHandler'   une poignée appelée quand F échoue
%
%   [X,Y,...] = PARCELLFUN(...) rend autant de sorties que F en donne.
%
%   Exemple :
%      parcellfun(@numel, {'a', 'bb', 'ccc'})        % [1 2 3]
%      parcellfun(@upper, {'a','b'}, 'UniformOutput', false)
%
%   Voir aussi PARARRAYFUN, CELLFUN, PARFEVAL.
    [entrees, options] = matlibre_par_options(varargin, ...
                                              {'UniformOutput', 'ErrorHandler'});
    varargout = matlibre_par_appliquer(fonction, entrees, options, ...
                                       @(c, i) c{i}, nargout);
end
