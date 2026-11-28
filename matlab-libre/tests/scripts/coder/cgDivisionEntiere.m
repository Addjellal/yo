function [y, z] = cgDivisionEntiere(a, b, c, d)
%CGDIVISIONENTIERE Division et produit entiers : arrondis et saturés comme MATLAB.
%   La division entière de MATLAB arrondit au plus proche (7/2 vaut 4, -7/2
%   vaut -4), là où le C tronque ; un produit int32 qui déborde sature au
%   lieu de faire un comportement indéfini.
    y = [a / b, -a / b, a / int16(0)];
    z = c * d;
end
