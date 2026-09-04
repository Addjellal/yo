function [colonnes, symboles] = pointfig(actif, boite)
%POINTFIG Graphique en points et figures.
%   [C,S] = POINTFIG(COURS,BOITE) découpe la série en colonnes de hausse
%   et de baisse. Chaque colonne est un intervalle de cours, exprimé en
%   nombre de boîtes ; SYMBOLES vaut 'X' pour une colonne de hausse et
%   'O' pour une colonne de baisse.
%
%   Le graphique en points et figures ignore le temps : il ne retient
%   qu'une chose, le sens dans lequel le cours a franchi une boîte. Une
%   longue période sans mouvement n'y laisse aucune trace.
%
%   Le renversement se fait à trois boîtes, comme le veut l'usage.
%
%   Exemple :
%      [c, s] = pointfig(clotures, 1);
%
%   Voir aussi HIGHLOW, CANDLE, MOVAVG.
    series = matlibre_colonnes_marche(actif, {}, {'cloture'});
    x = series{1};
    if nargin < 2 || isempty(boite)
        boite = max(range(x) / 20, eps);
    end
    niveaux = floor(x / boite);
    colonnes = [];
    symboles = '';
    if isempty(niveaux)
        return
    end
    sens = 0;
    debut = niveaux(1);
    extreme = niveaux(1);
    for k = 2:numel(niveaux)
        courant = niveaux(k);
        if sens == 0
            if courant > extreme
                sens = 1; extreme = courant;
            elseif courant < extreme
                sens = -1; extreme = courant;
            end
        elseif sens > 0
            if courant > extreme
                extreme = courant;
            elseif courant <= extreme - 3
                colonnes(end+1, :) = [debut, extreme];   %#ok<AGROW>
                symboles(end+1) = 'X';                   %#ok<AGROW>
                debut = extreme;
                sens = -1;
                extreme = courant;
            end
        else
            if courant < extreme
                extreme = courant;
            elseif courant >= extreme + 3
                colonnes(end+1, :) = [debut, extreme];   %#ok<AGROW>
                symboles(end+1) = 'O';                   %#ok<AGROW>
                debut = extreme;
                sens = 1;
                extreme = courant;
            end
        end
    end
    if sens ~= 0
        colonnes(end+1, :) = [debut, extreme];
        if sens > 0
            symboles(end+1) = 'X';
        else
            symboles(end+1) = 'O';
        end
    end
end
