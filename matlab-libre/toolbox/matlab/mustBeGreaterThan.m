function mustBeGreaterThan(a, borne)
%MUSTBEGREATERTHAN Exige une valeur strictement supérieure à une borne.
%   MUSTBEGREATERTHAN(A,BORNE) lève une erreur si un élément de A ne l'est pas.
%   La comparaison se fait terme à terme, et un tableau ne passe que s'il
%   passe entièrement.
%
%   Exemple :
%      mustBeGreaterThan(3, 1);       % passe
%      mustBeGreaterThan([2 5], 1);   % passe
%
%   Voir aussi MUSTBEPOSITIVE, MUSTBEMEMBER, VALIDATEATTRIBUTES.
    matlibre_valider(all(a(:) > borne), 'MATLAB:validators:mustBeGreaterThan', ...
                     'La valeur doit être strictement supérieure à %g.', borne);
end
