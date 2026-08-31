function H = stackedplot(varargin)
%STACKEDPLOT Plusieurs signaux empilés, une échelle chacun.
%   STACKEDPLOT(Y) trace chaque colonne de Y dans son propre cadre, les
%   uns au-dessus des autres, avec un axe des abscisses commun. Chaque
%   signal garde son échelle : c'est ce qui distingue STACKEDPLOT d'un
%   PLOT de toutes les colonnes, où le plus grand écrase les autres.
%
%   STACKEDPLOT(X,Y) place les points aux abscisses X.
%
%   STACKEDPLOT(...,'DisplayLabels',L) nomme les cadres avec les chaînes
%   de L.
%
%   H = STACKEDPLOT(...) rend les poignées des courbes.
%
%   Exemples :
%      t = linspace(0, 10, 200)';
%      Y = [sin(t), 1000 * exp(-t), t.^2];
%      stackedplot(t, Y, 'DisplayLabels', {'sin', 'exp', 'carre'});
%
%   Voir aussi PLOT, SUBPLOT, TILEDLAYOUT, PLOTYY, YYAXIS.
    etiquettes = {};
    entrees = varargin;
    while numel(entrees) >= 3 && (ischar(entrees{end - 1}) || isstring(entrees{end - 1}))
        nom = lower(char(entrees{end - 1}));
        if strcmp(nom, 'displaylabels')
            etiquettes = entrees{end};
        elseif ~any(strcmp(nom, {'title', 'xlabel', 'linewidth', 'color'}))
            break;
        end
        entrees = entrees(1:end - 2);
    end
    if numel(entrees) >= 2
        x = entrees{1}(:);
        Y = entrees{2};
    elseif numel(entrees) == 1
        Y = entrees{1};
        x = (1:size(Y, 1))';
    else
        error('MATLAB:stackedplot:NotEnoughInputs', 'Not enough input arguments.');
    end
    if isvector(Y)
        Y = Y(:);
    end
    n = size(Y, 2);
    clf;
    H = [];
    for k = 1:n
        subplot(n, 1, k);
        H(end + 1) = plot(x, Y(:, k));      %#ok<AGROW>
        if k <= numel(etiquettes)
            ylabel(char(etiquettes{k}));
        else
            ylabel(sprintf('y%d', k));
        end
        if k < n
            xticklabels({});
        end
    end
    if nargout == 0
        clear H;
    end
end
