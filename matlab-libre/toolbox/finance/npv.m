function v = npv(taux, flux)
%NPV Valeur actuelle nette : le premier flux est à la date zéro.
    v = flux(1);
    for k = 2:numel(flux)
        v = v + flux(k) / (1 + taux) ^ (k - 1);
    end
end
