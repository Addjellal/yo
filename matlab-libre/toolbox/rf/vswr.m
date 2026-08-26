function s = vswr(g)
%VSWR Taux d'ondes stationnaires à partir du coefficient de réflexion.
    m = abs(g);
    s = (1 + m) ./ (1 - m);
end
