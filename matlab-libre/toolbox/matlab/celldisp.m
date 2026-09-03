function celldisp(c, nom)
%CELLDISP Affiche le contenu d'un tableau de cellules.
%   CELLDISP(C) affiche chaque élément de C précédé de son indice.
%   CELLDISP(C,NOM) emploie NOM au lieu du nom de la variable.
%
%   Exemple :
%      celldisp({1, 'deux'})
%
%   Voir aussi DISP, CELL.
    if ~iscell(c)
        error('celldisp:Cellule', 'celldisp attend un tableau de cellules.');
    end
    if nargin < 2
        nom = inputname(1);
        if isempty(nom)
            nom = 'ans';
        end
    end
    nom = char(nom);
    [nl, nc] = size(c);
    for j = 1:nc
        for i = 1:nl
            if nl == 1 || nc == 1
                etiquette = sprintf('%s{%d}', nom, i + (j - 1) * nl);
            else
                etiquette = sprintf('%s{%d,%d}', nom, i, j);
            end
            v = c{i, j};
            if iscell(v)
                celldisp(v, etiquette);
            else
                fprintf('%s =\n\n', etiquette);
                disp(v);
                fprintf('\n');
            end
        end
    end
end
