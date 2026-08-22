function r = irr(flux)
%IRR Taux de rendement interne : le taux qui annule la valeur nette.
    f = @(t) npv(t, flux);
    r = fzero(f, [-0.9999, 10]);
end
