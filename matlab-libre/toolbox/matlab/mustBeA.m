function mustBeA(a, classes)
%MUSTBEA Exige une valeur d'une classe donnée.
%   MUSTBEA(A,CLASSE) lève une erreur si A n'est pas de la classe nommée,
%   ni d'une classe qui en dérive. CLASSE peut être une cellule de
%   plusieurs, et il suffit alors d'en satisfaire une.
%
%   Le contrôle passe par ISA, donc l'héritage compte : une sous-classe
%   satisfait le validateur de sa classe mère. C'est ce qu'on veut d'un
%   contrôle de type, et ce qui le sépare d'une comparaison de CLASS.
%
%   Exemple :
%      mustBeA(3, 'double');                    % passe
%      mustBeA(int8(3), {'int8', 'int16'});     % passe
%
%   Voir aussi ISA, CLASS, MUSTBENUMERIC, VALIDATEATTRIBUTES.
    liste = cellstr(classes);
    ok = false;
    for k = 1:numel(liste)
        if isa(a, liste{k})
            ok = true;
        end
    end
    matlibre_valider(ok, 'MATLAB:validators:mustBeA', ...
                     'La valeur doit être de classe %s.', strjoin(liste, ' ou '));
end
