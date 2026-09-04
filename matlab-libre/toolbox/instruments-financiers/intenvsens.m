function [delta, gamma, prix] = intenvsens(courbe, jeu)
%INTENVSENS Sensibilités d'un jeu d'instruments à un déplacement de courbe.
%   [D,G,P] = INTENVSENS(COURBE,JEU) rend la dérivée première et la
%   dérivée seconde du prix par rapport à un déplacement parallèle de la
%   courbe, ainsi que le prix lui-même.
%
%   Un déplacement parallèle n'est pas le seul mouvement possible, mais
%   c'est celui qui explique la plus grande part des variations d'une
%   courbe : la sensibilité qu'on en tire suffit à couvrir un
%   portefeuille au premier ordre.
%
%   Les dérivées sont calculées par différences finies centrées sur la
%   courbe déplacée.
%
%   Exemple :
%      [d, g, p] = intenvsens(courbe, jeu)
%
%   Voir aussi INTENVPRICE, BNDDURP, INSTADD.
    pas = 1e-5;
    prix = intenvprice(courbe, jeu);
    haute = intenvprice(matlibre_courbe_deplacer(courbe, pas), jeu);
    basse = intenvprice(matlibre_courbe_deplacer(courbe, -pas), jeu);
    delta = (haute - basse) / (2 * pas);
    gamma = (haute - 2 * prix + basse) / pas ^ 2;
end
