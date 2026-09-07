function mustBeLessThan(a, borne)
%MUSTBELESSTHAN Exige une valeur strictement inférieure à une borne.
%   MUSTBELESSTHAN(A,BORNE) lève une erreur si un élément de A ne l'est pas.
%   La comparaison se fait terme à terme, et un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeLessThan(0, 1);          % passe
%      mustBeLessThan([-1 0], 1);     % passe
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) < borne), 'MATLAB:validators:mustBeLessThan', ...
                     'La valeur doit être strictement inférieure à %g.', borne);
end
