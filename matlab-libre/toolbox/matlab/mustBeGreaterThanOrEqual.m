function mustBeGreaterThanOrEqual(a, borne)
%MUSTBEGREATERTHANOREQUAL Exige une valeur supérieure ou égale à une borne.
%   MUSTBEGREATERTHANOREQUAL(A,BORNE) lève une erreur si un élément de A ne l'est pas.
%   La comparaison se fait terme à terme, et un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeGreaterThanOrEqual(1, 1);      % passe : l'egalite est admise
%      mustBeGreaterThanOrEqual([1 2], 1);
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) >= borne), 'MATLAB:validators:mustBeGreaterThanOrEqual', ...
                     'La valeur doit être supérieure ou égale à %g.', borne);
end
