function y = matlibre_sl_tableps(grilles, valeurs, entrees, lisse, extrapolation, chemin)
%MATLIBRE_SL_TABLEPS Les tables des signaux physiques de Simscape.
%   Y = MATLIBRE_SL_TABLEPS(GRILLES,VALEURS,ENTREES,LISSE,EXTRAPOLATION,
%   CHEMIN) lit la table d'un PS Lookup Table (1D) ou (2D) : GRILLES est
%   une cellule d'une ou de deux grilles croissantes, VALEURS le vecteur ou
%   la matrice des valeurs, ENTREES une cellule d'autant de signaux. LISSE
%   interpole par la méthode d'Akima modifiée, sinon linéairement ; hors de
%   la grille, EXTRAPOLATION vaut 'Linear' (le prolongement des deux points
%   extrêmes), 'Nearest' (la valeur du bord) ou 'Error'.
%
%   En deux dimensions, la table s'interpole le long de la première grille,
%   puis de la seconde.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi MATLIBRE_SL_PHYSIQUE.
    u1 = double(entrees{1});
    y = zeros(size(u1));
    for k = 1:numel(u1)
        if numel(grilles) == 1
            y(k) = uneDimension(grilles{1}, valeurs(:).', u1(k), lisse, extrapolation, chemin);
        else
            u2 = double(entrees{2});
            v2 = u2(min(k, numel(u2)));
            colonnes = zeros(1, size(valeurs, 2));
            for j = 1:size(valeurs, 2)
                colonnes(j) = uneDimension(grilles{1}, valeurs(:, j).', u1(k), lisse, ...
                                           extrapolation, chemin);
            end
            y(k) = uneDimension(grilles{2}, colonnes, v2, lisse, extrapolation, chemin);
        end
    end
end

function y = uneDimension(x, f, u, lisse, extrapolation, chemin)
    if u < x(1) || u > x(end)
        switch extrapolation
            case 'Error'
                error('Simscape:Lookup:OutOfRange', ...
                      ['L''entree de ''%s'' vaut %g, hors de la grille [%g, %g] : son ' ...
                       'extrapolation est ''Error''.'], chemin, u, x(1), x(end));
            case 'Nearest'
                u = min(max(u, x(1)), x(end));
            otherwise
                if u < x(1)
                    y = f(1) + (u - x(1)) * (f(2) - f(1)) / (x(2) - x(1));
                else
                    y = f(end) + (u - x(end)) * (f(end) - f(end - 1)) / (x(end) - x(end - 1));
                end
                return
        end
    end
    if lisse && numel(x) > 2
        y = interp1(x, f, u, 'makima');
    else
        y = interp1(x, f, u, 'linear');
    end
end
