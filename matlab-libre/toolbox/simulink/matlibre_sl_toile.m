function [largeur, hauteur] = matlibre_sl_toile(unitesX, unitesY)
%MATLIBRE_SL_TOILE Taille de figure qui convient à un schéma.
%   [L,H] = MATLIBRE_SL_TOILE(UX,UY) rend la largeur et la hauteur en
%   pixels d'une figure où un schéma de UX sur UY unités se lise : assez
%   grande pour qu'un nom de bloc tienne sous son bloc, assez petite pour
%   tenir sur un écran.
%
%   La toile garde les proportions du schéma. Sans cela, « axis equal »
%   ajuste l'échelle au côté le plus contraint et laisse le reste en
%   blanc : un schéma en long se retrouvait en bandeau au milieu d'une
%   toile carrée, ses étiquettes serrées à l'illisible.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [l, h] = matlibre_sl_toile(20, 5);
%      abs(l / h - 4) < 0.05            % la toile suit les proportions
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
    if ~(unitesX > 0) || ~(unitesY > 0)
        largeur = 800;
        hauteur = 600;
        return
    end
    % Quarante-cinq pixels par unité : les axes occupent environ les
    % quatre cinquièmes de la toile, ce qui laisse trente-six pixels par
    % unité au tracé — de quoi écrire un nom de dix lettres sous un bloc
    % large de 1,7 unité sans mordre sur son voisin.
    parUnite = min([45, 2000 / unitesX, 1400 / unitesY]);
    largeur = round(unitesX * parUnite);
    hauteur = round(unitesY * parUnite);
    % Un petit schéma retrouve au moins la toile par défaut : à cette
    % échelle il tiendrait dans une vignette.
    if largeur < 800 && hauteur < 600
        facteur = min(800 / largeur, 600 / hauteur);
        largeur = round(largeur * facteur);
        hauteur = round(hauteur * facteur);
    end
end
