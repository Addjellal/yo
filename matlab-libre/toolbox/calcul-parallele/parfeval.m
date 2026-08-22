function futur = parfeval(fonction, nSorties, varargin)
%PARFEVAL Exécute une fonction et mémorise son résultat.
%   Comme il n'y a qu'un fil, l'exécution est immédiate ; FETCHOUTPUTS
%   rend le résultat déjà calculé.
    if isstruct(fonction) && isfield(fonction, 'NumWorkers')
        fonction = nSorties;
        nSorties = varargin{1};
        varargin = varargin(2:end);
    end
    sorties = cell(1, nSorties);
    [sorties{1:nSorties}] = fonction(varargin{:});
    futur = struct('resultats', {sorties}, 'State', 'finished');
end
