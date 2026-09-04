function v = matlibre_essai_pool_nu(X, genre, fenetre, options)
%MATLIBRE_ESSAI_POOL_NU Valeur nue de la perte d'une agrégation.
    v = matlibre_essai_pool(dlarray(X, 'SSCB'), genre, fenetre, options);
    if isa(v, 'dlarray')
        v = extractdata(v);
    end
end
