function g = matlibre_gain_ou_zero(modele)
%MATLIBRE_GAIN_OU_ZERO La norme H-infini, l'infini devenant un grand nombre.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   La recherche du pire cas compare des gains ; un modèle instable en a
%   un infini, et l'infini ne se compare pas à l'infini. On le remplace
%   par un très grand nombre fini, ce qui laisse la comparaison décider
%   et fait ressortir l'instabilité comme le pire des cas.
    g = hinfnorm(ss(modele));
    if ~isfinite(g)
        g = 1e12;
    end
end
