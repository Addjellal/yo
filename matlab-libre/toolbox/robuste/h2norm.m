function n = h2norm(sys)
%H2NORM Norme H2, par intégration du carré du module.
    w = logspace(-4, 4, 20000).';
    m = bode(sys, w);
    n = sqrt(trapz(w, m .^ 2) / pi);
end
