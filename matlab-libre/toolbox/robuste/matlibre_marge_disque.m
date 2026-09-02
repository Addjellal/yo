function marge = matlibre_marge_disque(G, K)
%MATLIBRE_MARGE_DISQUE La marge de disque d'une boucle.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   WCDISKMARGIN s'en sert. Une boucle instable donne une marge nulle,
%   ce qui la désigne comme le pire des cas.
    L = loopsens(ss(G), ss(K));
    if ~L.Stable
        marge = 0;
        return
    end
    pic = max(hinfnorm(L.Si), hinfnorm(L.So));
    if ~isfinite(pic) || pic <= 0
        marge = 0;
    else
        marge = 1 / pic;
    end
end
