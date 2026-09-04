function [gx, gw, gb] = matlibre_essai_conv(x, w, b, options)
%MATLIBRE_ESSAI_CONV Dérivées d'une convolution, pour les vérifications.
    y = dlconv(x, w, b, options{:});
    v = sum(sum(sum(sum(y .^ 2 + sin(y)))));
    [gx, gw, gb] = dlgradient(v, x, w, b);
end
