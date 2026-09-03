function y = db2pow(x)
%DB2POW Décibels en puissance.
%   Y = DB2POW(X) rend 10^(X/10).
%
%   Exemple :
%      db2pow(20)      % 100
%
%   Voir aussi POW2DB, MAG2DB, DB2MAG.
    y = 10 .^ (double(x) / 10);
end
