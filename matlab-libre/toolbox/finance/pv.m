function v = pv(taux, flux)
%PV Valeur actuelle d'une suite de flux, le premier à la période 1.
    v = 0;
    for k = 1:numel(flux)
        v = v + flux(k) / (1 + taux) ^ k;
    end
end
