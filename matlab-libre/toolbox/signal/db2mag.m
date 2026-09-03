function y = db2mag(x)
%DB2MAG Décibels en amplitude.
%   Y = DB2MAG(X) rend 10^(X/20).
%
%   Exemple :
%      db2mag(20)      % 10
%
%   Voir aussi MAG2DB, DB2POW, POW2DB.
    y = 10 .^ (double(x) / 20);
end
