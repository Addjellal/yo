function v = nthargout(n, varargin)
%NTHARGOUT Ne garder qu'une sortie d'une fonction.
%   V = NTHARGOUT(N,F,ARG1,...) appelle F avec les arguments donnés en
%   demandant N sorties, et ne rend que la N-ième.
%
%   V = NTHARGOUT([N1 N2 ...],F,...) rend, dans un tableau de cellules,
%   les sorties demandées.
%
%   Exemple :
%      nthargout(2, @max, [3 9 4])   % 2, la position du maximum
%
%   Voir aussi FEVAL, DEAL, NARGOUT.
    if isempty(varargin)
        error('nthargout:Arguments', 'nthargout attend une fonction à appeler.');
    end
    f = varargin{1};
    entrees = varargin(2:end);
    n = double(n(:))';
    if any(n < 1) || any(n ~= fix(n))
        error('nthargout:Rang', 'Les rangs demandés doivent être des entiers positifs.');
    end
    demandees = max(n);
    sorties = cell(1, demandees);
    [sorties{1:demandees}] = feval(f, entrees{:});
    if isscalar(n)
        v = sorties{n};
    else
        v = sorties(n);
    end
end
