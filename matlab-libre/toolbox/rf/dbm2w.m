function p = dbm2w(dbm)
%DBM2W Conversion dBm vers watts.
    p = 10 .^ ((dbm - 30) / 10);
end
