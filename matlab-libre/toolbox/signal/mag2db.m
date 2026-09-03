function y = mag2db(x)
%MAG2DB Amplitude en décibels.
%   Y = MAG2DB(X) rend 20*log10(X) : c'est la conversion d'une amplitude,
%   non d'une puissance.
%
%   Exemple :
%      mag2db(10)      % 20
%
%   Voir aussi DB2MAG, POW2DB, DB2POW.
    x = double(x);
    y = 20 * log10(x);
    y(x < 0) = NaN;
end
