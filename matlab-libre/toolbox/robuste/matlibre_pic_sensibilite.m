function pic = matlibre_pic_sensibilite(G, K, nom)
%MATLIBRE_PIC_SENSIBILITE Le pic d'une des transmittances d'une boucle.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   WCSENS s'en sert. Une boucle instable rend un très grand nombre fini
%   plutôt que l'infini, pour que la recherche du pire cas puisse
%   comparer.
    L = loopsens(ss(G), ss(K));
    pic = hinfnorm(L.(nom));
    if ~isfinite(pic)
        pic = 1e12;
    end
end
