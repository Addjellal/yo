function [dligne, dcolonne] = matlibre_sommet_quadratique(carte, ligne, colonne)
%MATLIBRE_SOMMET_QUADRATIQUE Position sous-pixel d'un maximum local.
%   [DL,DC] = MATLIBRE_SOMMET_QUADRATIQUE(CARTE,LIGNE,COLONNE) ajuste une
%   parabole sur les trois valeurs qui entourent le maximum dans chaque
%   direction et rend le décalage de son sommet, borné à un demi-pixel.
%   Un maximum trouvé sur une image réduite gagne ainsi la précision que
%   la réduction lui avait fait perdre.
%
%   Exemple :
%      c = [0 0 0; 1 2 1.5; 0 0 0];
%      [~, dc] = matlibre_sommet_quadratique(c, 2, 2);   % environ 0.1
%
%   Voir aussi DETECTBRISKFEATURES.
    [h, l] = size(carte);
    dligne = 0;
    dcolonne = 0;
    if ligne > 1 && ligne < h
        dligne = sommet(carte(ligne - 1, colonne), carte(ligne, colonne), ...
                        carte(ligne + 1, colonne));
    end
    if colonne > 1 && colonne < l
        dcolonne = sommet(carte(ligne, colonne - 1), carte(ligne, colonne), ...
                          carte(ligne, colonne + 1));
    end
end

function d = sommet(avant, milieu, apres)
    denominateur = avant - 2 * milieu + apres;
    if abs(denominateur) < eps
        d = 0;
        return
    end
    d = 0.5 * (avant - apres) / denominateur;
    d = min(max(d, -0.5), 0.5);
end
