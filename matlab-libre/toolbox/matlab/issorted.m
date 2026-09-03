function tf = issorted(a, varargin)
%ISSORTED Vrai si le tableau est trié.
%   TF = ISSORTED(A) est vrai si A est trié par ordre croissant.
%   ISSORTED(A,SENS) teste 'ascend', 'descend', 'monotonic',
%   'strictascend', 'strictdescend' ou 'strictmonotonic'.
%   ISSORTED(A,'rows') teste les lignes d'une matrice ; voir ISSORTEDROWS.
%
%   Exemples :
%      issorted([1 2 2 5])                  % true
%      issorted([1 2 2 5], 'strictascend')  % false
%
%   Voir aussi SORT, ISSORTEDROWS, SORTROWS.
    sens = 'ascend';
    for k = 1:numel(varargin)
        o = lower(char(varargin{k}));
        if strcmp(o, 'rows')
            tf = issortedrows(a);
            return;
        end
        sens = o;
    end
    if iscell(a) || ischar(a) || isstring(a)
        [~, ordre] = sort(a(:));
        croissant = isequal(ordre(:)', 1:numel(ordre));
        [~, ordre] = sort(a(:), 'descend');
        decroissant = isequal(ordre(:)', 1:numel(ordre));
        d = [];
    else
        d = diff(double(a(:)));
        croissant = all(d >= 0);
        decroissant = all(d <= 0);
    end
    switch sens
        case 'ascend'
            tf = croissant;
        case 'descend'
            tf = decroissant;
        case 'monotonic'
            tf = croissant || decroissant;
        case 'strictascend'
            tf = ~isempty(d) && all(d > 0) || numel(a) < 2;
        case 'strictdescend'
            tf = ~isempty(d) && all(d < 0) || numel(a) < 2;
        case 'strictmonotonic'
            tf = issorted(a, 'strictascend') || issorted(a, 'strictdescend');
        otherwise
            error('issorted:Sens', 'Sens de tri inconnu : %s.', sens);
    end
    tf = logical(tf);
end
