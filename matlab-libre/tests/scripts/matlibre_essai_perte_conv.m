function v = matlibre_essai_perte_conv(X, W, B, options)
%MATLIBRE_ESSAI_PERTE_CONV Valeur nue de la perte d'une convolution.
    y = extractdata(dlconv(dlarray(X, 'SSCB'), W, B, options{:}));
    v = sum(sum(sum(sum(y .^ 2 + sin(y)))));
end
