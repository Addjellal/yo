function p = dbm2w(dbm)
%DBM2W Conversion dBm vers watts.
%   P = DBM2W(DBM) rend la puissance en watts. Le dBm est une puissance
%   absolue rapportée au milliwatt : zéro dBm vaut un milliwatt, trente
%   dBm un watt.
%
%   Dix décibels de plus, c'est dix fois plus de puissance ; trois, c'est
%   le double. C'est toute l'échelle, et elle transforme les produits en
%   sommes — ce qui est la raison d'être des décibels dans un bilan de
%   liaison.
%
%   Exemple :
%      dbm2w(0)                        % 1e-3
%      dbm2w(30)                       % 1
%      dbm2w(3) / dbm2w(0)             % 2, a 0,2 %% pres
%
%   Voir aussi W2DBM, FRIIS, PATHLOSS.
    p = 10 .^ ((dbm - 30) / 10);
end
