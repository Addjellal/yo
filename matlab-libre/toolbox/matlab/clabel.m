function H = clabel(C, varargin)
%CLABEL Étiquette les lignes de niveau.
%   CLABEL(C) écrit la valeur du niveau sur chaque ligne de la matrice de
%   contours C — celle que rendent CONTOUR et CONTOURC.
%
%   CLABEL(C,H) accepte aussi les poignées que rend CONTOUR ; elles ne
%   servent pas au placement, mais la forme est celle de MATLAB.
%
%   CLABEL(C,NIVEAUX) n'étiquette que les niveaux donnés.
%
%   CLABEL(...,'FontSize',N) change la taille des étiquettes.
%   CLABEL(...,'manual') attend un clic dans MATLAB ; MatLibre place les
%   étiquettes automatiquement et accepte l'option sans effet.
%
%   H = CLABEL(...) rend les poignées des textes.
%
%   L'étiquette est posée au milieu de chaque courbe : c'est là qu'elle a
%   le plus de chances de tomber sur une portion droite et lisible.
%
%   Exemples :
%      [X, Y] = meshgrid(-2:0.1:2);
%      Z = X.^2 + Y.^2;
%      C = contour(X, Y, Z, [0.5 1 2 3]);
%      clabel(C);
%
%      [C, h] = contour(peaks(40));
%      clabel(C, h, 'FontSize', 8);
%
%   Voir aussi CONTOUR, CONTOURF, CONTOURC, TEXT.
    taille = [];
    niveaux = [];
    k = 1;
    while k <= numel(varargin)
        argument = varargin{k};
        if (ischar(argument) || isstring(argument))
            nom = lower(char(argument));
            if strcmp(nom, 'fontsize') && k + 1 <= numel(varargin)
                taille = varargin{k + 1};
                k = k + 2;
                continue;
            elseif any(strcmp(nom, {'manual', 'labelspacing', 'color', ...
                                    'rotation', 'backgroundcolor'}))
                if any(strcmp(nom, {'labelspacing', 'color', 'rotation', ...
                                    'backgroundcolor'}))
                    k = k + 2;
                else
                    k = k + 1;
                end
                continue;
            end
        elseif isnumeric(argument) && ~isempty(argument) && numel(argument) < 100
            niveaux = argument;
        end
        k = k + 1;
    end

    aEffacer = ishold();
    hold('on');
    H = [];
    colonne = 1;
    while colonne <= size(C, 2)
        niveau = C(1, colonne);
        n = C(2, colonne);
        if n < 1 || colonne + n > size(C, 2)
            break;
        end
        x = C(1, colonne + 1:colonne + n);
        y = C(2, colonne + 1:colonne + n);
        colonne = colonne + n + 1;
        if ~isempty(niveaux) && ~any(abs(niveaux - niveau) < eps(max(1, abs(niveau))))
            continue;
        end
        milieu = max(1, round(n / 2));
        options = {'HorizontalAlignment', 'center'};
        if ~isempty(taille)
            options = [options, {'FontSize', taille}];    %#ok<AGROW>
        end
        H(end + 1) = text(x(milieu), y(milieu), sprintf('%g', niveau), ...
                          options{:});                    %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
