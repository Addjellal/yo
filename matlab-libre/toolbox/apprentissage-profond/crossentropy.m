function c = crossentropy(predit, cible)
%CROSSENTROPY Entropie croisée moyenne par observation.
    p = max(min(predit, 1 - 1e-12), 1e-12);
    c = -sum(sum(cible .* log(p))) / size(cible, 2);
end
