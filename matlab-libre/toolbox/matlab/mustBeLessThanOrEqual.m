function mustBeLessThanOrEqual(a, borne)
%MUSTBELESSTHANOREQUAL Exige une valeur inférieure ou égale à une borne.
%   MUSTBELESSTHANOREQUAL(A,BORNE) lève une erreur si un élément de A ne l'est pas.
%   La comparaison se fait terme à terme, et un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeLessThanOrEqual(1, 1);         % passe : l'egalite est admise
%      mustBeLessThanOrEqual([0 1], 1);
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) <= borne), 'MATLAB:validators:mustBeLessThanOrEqual', ...
                     'La valeur doit être inférieure ou égale à %g.', borne);
end
