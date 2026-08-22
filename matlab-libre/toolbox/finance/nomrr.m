function r = nomrr(effectif, periodes)
%NOMRR Taux nominal à partir du taux effectif.
    r = periodes * ((1 + effectif) ^ (1 / periodes) - 1);
end
