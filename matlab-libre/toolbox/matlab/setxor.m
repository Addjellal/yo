function [c, ia, ib] = setxor(a, b, varargin)
%SETXOR Différence symétrique de deux ensembles.
%   C = SETXOR(A,B) rend, triées et sans répétition, les valeurs qui
%   figurent dans A ou dans B mais pas dans les deux.
%
%   [C,IA,IB] = SETXOR(A,B) rend en outre les positions telles que la
%   part de C venue de A soit A(IA) et celle venue de B soit B(IB).
%
%   SETXOR(A,B,'stable') garde l'ordre de première apparition : d'abord
%   ce qui vient de A, puis ce qui vient de B.
%
%   Exemple :
%      setxor([1 2 3 4], [3 4 5])   % [1 2 5]
%
%   Voir aussi UNION, INTERSECT, SETDIFF, ISMEMBER.
    stable = false;
    for k = 1:numel(varargin)
        o = lower(char(varargin{k}));
        if strcmp(o, 'stable')
            stable = true;
        elseif ~strcmp(o, 'sorted')
            error('setxor:Option', 'Option inconnue : %s.', o);
        end
    end
    [seulA, ia] = setdiff(a, b);
    [seulB, ib] = setdiff(b, a);
    if stable
        [~, ordre] = sort(ia);
        ia = ia(ordre);
        seulA = seulA(ordre);
        [~, ordre] = sort(ib);
        ib = ib(ordre);
        seulB = seulB(ordre);
    end
    if iscell(a) || iscell(b)
        c = [seulA(:); seulB(:)]';
        if ~stable
            [c, ordre] = sort(c);
            indices = [ia(:); ib(:)];
            nA = numel(ia);
            ia = indices(ordre(ordre <= nA));
            ib = indices(ordre(ordre > nA));
        end
        return;
    end
    ligne = (isrow(a) && isrow(b));
    c = [seulA(:); seulB(:)];
    if ~stable
        c = sort(c);
    end
    if ligne
        c = c(:)';
    end
end
