function [lignes, colonnes] = matlibre_extrema_echelle(reponses, niveau, seuil, bord)
%MATLIBRE_EXTREMA_ECHELLE Maxima locaux dans le plan et dans l'échelle.
%   [L,C] = MATLIBRE_EXTREMA_ECHELLE(REPONSES,NIVEAU,SEUIL,BORD) rend les
%   pixels du plan NIVEAU dont la réponse dépasse SEUIL et domine ses
%   vingt-six voisins — les huit de son plan, et les neuf de chacun des
%   plans voisins. Les pixels à moins de BORD du cadre sont écartés : leur
%   filtre déborde de l'image.
%
%   Exemple :
%      r = zeros(5, 5, 3); r(3, 3, 2) = 1;
%      [l, c] = matlibre_extrema_echelle(r, 2, 0.5, 1);   % 3 3
%
%   Voir aussi DETECTSURFFEATURES.
    plan = reponses(:, :, niveau);
    [h, l] = size(plan);
    candidat = plan > seuil;
    candidat([1:bord, max(1, h - bord + 1):h], :) = false;
    candidat(:, [1:bord, max(1, l - bord + 1):l]) = false;
    if ~any(candidat(:))
        lignes = [];
        colonnes = [];
        return
    end
    voisinage = -inf(h, l);
    for k = (niveau - 1):(niveau + 1)
        courant = reponses(:, :, k);
        for di = -1:1
            for dj = -1:1
                if k == niveau && di == 0 && dj == 0
                    continue
                end
                decale = -inf(h, l);
                lignesSource = (1:h) + di;
                colonnesSource = (1:l) + dj;
                valides = lignesSource >= 1 & lignesSource <= h;
                valideColonnes = colonnesSource >= 1 & colonnesSource <= l;
                decale(valides, valideColonnes) = ...
                    courant(lignesSource(valides), colonnesSource(valideColonnes));
                voisinage = max(voisinage, decale);
            end
        end
    end
    retenus = candidat & plan > voisinage;
    [lignes, colonnes] = find(retenus);
end
