function v = matlibre_essai_pool(x, genre, fenetre, options)
%MATLIBRE_ESSAI_POOL Perte appliquée à une agrégation.
    if strcmp(genre, 'max')
        y = maxpool(x, fenetre, options{:});
    else
        y = avgpool(x, fenetre, options{:});
    end
    v = sum(sum(sum(sum(y .^ 3 + 2 * y))));
end
