function r = effrr(nominal, periodes)
%EFFRR Taux effectif annuel à partir du taux nominal.
    r = (1 + nominal / periodes) ^ periodes - 1;
end
