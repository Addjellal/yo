function H = heatmap(varargin)
%HEATMAP Carte de chaleur d'une matrice.
%   HEATMAP(M) dessine la matrice M en couleurs, une case par élément, et
%   écrit la valeur dans chaque case.
%
%   HEATMAP(NOMSX,NOMSY,M) nomme les colonnes et les lignes.
%
%   HEATMAP(...,'ColorbarVisible','off') n'affiche pas l'échelle de
%   couleurs.
%   HEATMAP(...,'CellLabelFormat',F) change le format des nombres écrits
%   dans les cases ; '%.2f' par exemple. La chaîne vide n'écrit rien.
%
%   H = HEATMAP(...) rend la poignée de l'image.
%
%   C'est la façon de montrer une matrice de corrélation, une table de
%   contingence, une matrice de confusion : l'œil y voit les blocs et les
%   valeurs fortes bien avant de lire les nombres.
%
%   Exemples :
%      heatmap(magic(5));
%
%      X = randn(100, 4);
%      heatmap({'a','b','c','d'}, {'a','b','c','d'}, corr(X));
%
%   Voir aussi IMAGESC, PCOLOR, COLORMAP, COLORBAR, CONFUSIONMAT, CORR.
    nomsX = {};
    nomsY = {};
    format_ = '%.3g';
    barreVisible = true;
    entrees = varargin;
    % Les paires nom-valeur, a la fin.
    while numel(entrees) >= 3 && (ischar(entrees{end - 1}) || isstring(entrees{end - 1}))
        nom = lower(char(entrees{end - 1}));
        valeur = entrees{end};
        if strcmp(nom, 'celllabelformat')
            format_ = char(valeur);
        elseif strcmp(nom, 'colorbarvisible')
            barreVisible = strcmpi(char(valeur), 'on');
        elseif any(strcmp(nom, {'title', 'xlabel', 'ylabel', 'colormap', ...
                                'missingdatacolor', 'gridvisible'}))
            % acceptes ; le titre et les etiquettes sont poses plus bas
        else
            break;
        end
        entrees = entrees(1:end - 2);
        if strcmp(nom, 'title')
            titreDemande = valeur;      %#ok<NASGU>
        end
    end
    if numel(entrees) >= 3
        nomsX = entrees{1};
        nomsY = entrees{2};
        M = entrees{3};
    elseif numel(entrees) == 1
        M = entrees{1};
    else
        error('MATLAB:heatmap:NotEnoughInputs', 'Not enough input arguments.');
    end
    M = double(M);
    [lignes, colonnes] = size(M);

    cla;
    H = imagesc(M);
    hold('on');
    if barreVisible
        colorbar();
    end
    % La valeur ecrite dans chaque case, en clair sur fond sombre.
    if ~isempty(format_)
        bas = min(M(:));
        haut = max(M(:));
        for i = 1:lignes
            for j = 1:colonnes
                if haut > bas
                    relative = (M(i, j) - bas) / (haut - bas);
                else
                    relative = 0.5;
                end
                if relative > 0.55
                    couleur = [0 0 0];
                else
                    couleur = [1 1 1];
                end
                text(j, i, sprintf(format_, M(i, j)), ...
                     'HorizontalAlignment', 'center', 'Color', couleur);
            end
        end
    end
    hold('off');
    xticks(1:colonnes);
    yticks(1:lignes);
    if ~isempty(nomsX)
        xticklabels(nomsX);
    end
    if ~isempty(nomsY)
        yticklabels(nomsY);
    end
    if nargout == 0
        clear H;
    end
end
