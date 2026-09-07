function c = sprintfc(format, valeurs)
%SPRINTFC Formate chaque valeur dans sa propre cellule.
%   C = SPRINTFC(FORMAT,VALEURS) applique le format à chaque élément de
%   VALEURS et rend un tableau de cellules de même taille, une chaîne par
%   élément.
%
%   SPRINTF, lui, recycle le format sur toutes les valeurs et rend une
%   seule chaîne : SPRINTF('%d ', 1:3) donne '1 2 3 ', là où SPRINTFC rend
%   trois cellules. C'est la différence entre concaténer et étiqueter.
%
%   La fonction n'est pas documentée par MathWorks, mais elle existe
%   depuis longtemps et sert à fabriquer des étiquettes d'axes ou de
%   légende, où l'on veut une chaîne par élément.
%
%   Exemple :
%      sprintfc('%d', [1 2 3])             % {'1'  '2'  '3'}
%      sprintfc('point %d', 1:2)           % {'point 1'  'point 2'}
%      numel(sprintfc('%.2f', rand(2, 3))) % 6 : la forme est gardee
%
%   Voir aussi SPRINTF, COMPOSE, NUM2STR, CELLSTR.
    format = char(format);
    if iscell(valeurs)
        c = cell(size(valeurs));
        for k = 1:numel(valeurs)
            c{k} = sprintf(format, valeurs{k});
        end
        return
    end
    c = cell(size(valeurs));
    for k = 1:numel(valeurs)
        c{k} = sprintf(format, valeurs(k));
    end
end
