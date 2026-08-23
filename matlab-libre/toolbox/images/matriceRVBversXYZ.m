function M = matriceRVBversXYZ()
%MATRICERVBVERSXYZ Matrice sRGB linéaire vers XYZ, blanc D65.
%   Les coefficients sont ceux de la recommandation UIT-R BT.709, celle
%   que sRGB reprend : ils envoient le blanc [1 1 1] sur le blanc D65.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    M = [0.4124564 0.3575761 0.1804375
         0.2126729 0.7151522 0.0721750
         0.0193339 0.1191920 0.9503041];
end
