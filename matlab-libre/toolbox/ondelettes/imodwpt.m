function x = imodwpt(w, nom)
%IMODWPT Paquets d'ondelettes à chevauchement maximal, inverse.
%   X = IMODWPT(W) reconstruit le signal à partir des paquets que rend
%   MODWPT. X = IMODWPT(W,NOM) nomme l'ondelette ('sym4' par défaut).
%
%   La reconstruction est exacte : la transformée est un cadre ajusté de
%   constante un, comme la MODWT dont elle sort.
%
%   Exemple :
%      x = cos((1:256) / 7);
%      max(abs(imodwpt(modwpt(x, 3), 'sym4') - x))   % nul
%
%   Voir aussi MODWPT, IMODWT, WPREC.
    if nargin < 2 || isempty(nom), nom = 'sym4'; end
    [bas, haut] = wfilters(nom, 'r');
    bas = bas / sqrt(2);
    haut = haut / sqrt(2);
    lignes = size(w, 1);
    niveaux = round(log2(lignes));
    if 2 ^ niveaux ~= lignes
        error('wavelet:imodwpt:Lignes', ...
              'Le nombre de bandes doit être une puissance de deux.');
    end
    courant = w;
    for niveau = niveaux:-1:1
        [basK, hautK] = dilaterFiltres(bas, haut, niveau - 1);
        precedent = zeros(size(courant, 1) / 2, size(courant, 2));
        for noeud = 0:(size(precedent, 1) - 1)
            premiere = courant(2 * noeud + 1, :);
            seconde = courant(2 * noeud + 2, :);
            if mod(noeud, 2) == 0
                precedent(noeud + 1, :) = adjointModwpt(premiere, basK) + ...
                                          adjointModwpt(seconde, hautK);
            else
                precedent(noeud + 1, :) = adjointModwpt(premiere, hautK) + ...
                                          adjointModwpt(seconde, basK);
            end
        end
        courant = precedent;
    end
    x = courant(1, :);
end

function y = adjointModwpt(x, h)
%ADJOINTMODWPT Adjoint de la corrélation circulaire.
    n = numel(x);
    m = numel(h);
    y = zeros(1, n);
    for k = 1:n
        valeur = x(k);
        if valeur == 0, continue; end
        for j = 1:m
            if h(j) == 0, continue; end
            indice = mod(k - 1 + j - 1, n) + 1;
            y(indice) = y(indice) + h(j) * valeur;
        end
    end
end
