function H = boxchart(varargin)
%BOXCHART Boîtes à moustaches (forme moderne).
%   BOXCHART(Y) dessine une boîte à moustaches par colonne de Y.
%   BOXCHART(GROUPE,Y) dessine une boîte par groupe, GROUPE prenant la
%   forme qu'accepte GRP2IDX.
%
%   BOXCHART(...,'BoxFaceColor',C) et les autres propriétés de MATLAB
%   sont acceptées ; MatLibre n'emploie pas encore la couleur.
%
%   H = BOXCHART(...) rend les poignées.
%
%   BOXCHART a remplacé BOXPLOT depuis R2020a. Les deux dessinent la même
%   chose ; BOXCHART se distingue par une syntaxe où le groupe vient en
%   premier, et par sa place dans la boîte à outils de base plutôt que
%   dans celle des statistiques.
%
%   Exemples :
%      boxchart(randn(100, 3));
%      boxchart([1 1 1 2 2 2]', [1 2 3 10 11 12]');
%
%   Voir aussi BOXPLOT, HISTOGRAM, PRCTILE, GRPSTATS.
    entrees = varargin;
    % Les paires nom-valeur, ignorees.
    while numel(entrees) >= 3 && (ischar(entrees{end - 1}) || isstring(entrees{end - 1}))
        entrees = entrees(1:end - 2);
    end
    if numel(entrees) >= 2
        H = boxplot(entrees{2}, entrees{1});
    elseif numel(entrees) == 1
        H = boxplot(entrees{1});
    else
        error('MATLAB:boxchart:NotEnoughInputs', 'Not enough input arguments.');
    end
    if nargout == 0
        clear H;
    end
end
