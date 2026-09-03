function y = pow2db(x)
%POW2DB Puissance en décibels.
%   Y = POW2DB(X) rend 10*log10(X). Une puissance nulle donne −Inf, une
%   puissance négative n'a pas de sens et donne NaN.
%
%   Exemple :
%      pow2db(100)     % 20
%
%   Voir aussi DB2POW, MAG2DB, DB2MAG, BANDPOWER.
    x = double(x);
    y = 10 * log10(x);
    y(x < 0) = NaN;
end
