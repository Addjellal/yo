function [suivant, lire, instantane] = compteurImbrique(depart)
%COMPTEURIMBRIQUE Rend des poignées qui partagent, ou non, un compteur.
%   C'est le cas d'école des fonctions imbriquées. « suivant » et « lire »
%   sont des poignées vers des fonctions imbriquées : elles partagent la
%   variable « valeur », même appelées longtemps après le retour.
%   « instantane » est une fonction anonyme : elle a capturé la valeur au
%   moment de sa création, et ne bougera plus. C'est la règle de MATLAB.
    valeur = depart;
    suivant = @incrementer;
    lire = @lireValeur;
    instantane = @() valeur;
    function v = incrementer(pas)
        if nargin < 1
            pas = 1;
        end
        valeur = valeur + pas;
        v = valeur;
    end
    function v = lireValeur()
        v = valeur;
    end
end
