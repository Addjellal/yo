function c = matlibre_gf2_conv(a, b)
%MATLIBRE_GF2_CONV Produit de deux polynômes binaires.
%   Les coefficients vont par puissances croissantes ; l'addition étant
%   le ou exclusif, le produit se calcule sans retenue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    a = double(a(:)).';
    b = double(b(:)).';
    c = mod(conv(a, b), 2);
end
