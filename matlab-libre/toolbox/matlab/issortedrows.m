function tf = issortedrows(a, colonnes, varargin)
%ISSORTEDROWS Vrai si les lignes sont triées.
%   TF = ISSORTEDROWS(A) est vrai si les lignes de A sont classées par
%   ordre croissant, la première colonne d'abord.
%   ISSORTEDROWS(A,COL) ne regarde que les colonnes COL, dans l'ordre
%   donné ; une colonne négative se lit en ordre décroissant.
%   ISSORTEDROWS(A,COL,SENS) impose 'ascend' ou 'descend'.
%
%   Exemple :
%      issortedrows([1 2; 1 3; 2 0])   % true
%
%   Voir aussi SORTROWS, ISSORTED.
    if nargin < 2 || isempty(colonnes)
        colonnes = 1:size(a, 2);
    end
    colonnes = double(colonnes(:))';
    for k = 1:numel(varargin)
        o = lower(char(varargin{k}));
        switch o
            case 'ascend'
                % Ordre déjà voulu.
            case 'descend'
                colonnes = -colonnes;
            otherwise
                error('issortedrows:Sens', 'Sens de tri inconnu : %s.', o);
        end
    end
    [~, ordre] = sortrows(a, colonnes);
    tf = isequal(ordre(:)', 1:size(a, 1));
end
