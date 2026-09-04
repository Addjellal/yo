function S = matlibre_somme_boite(integrale, marge, taille, boite)
%MATLIBRE_SOMME_BOITE Somme d'un rectangle décalé, en chaque pixel.
%   S = MATLIBRE_SOMME_BOITE(INTEGRALE,MARGE,TAILLE,BOITE) rend, pour
%   chaque pixel (y,x) d'une image de taille TAILLE, la somme des pixels du
%   rectangle allant de (y+BOITE(1), x+BOITE(3)) à (y+BOITE(2), x+BOITE(4)).
%   INTEGRALE est l'image intégrale de l'image élargie de MARGE de chaque
%   côté, ce qui permet aux rectangles de déborder sans cas particulier.
%
%   Quatre accès suffisent quelle que soit la taille du rectangle : c'est
%   ce qui rend le détecteur de Hessienne approchée indépendant de
%   l'échelle.
%
%   Exemple :
%      P = padarray(ones(4), [2 2], 'replicate');
%      S = matlibre_somme_boite(integralImage(P), 2, [4 4], [-1 1 -1 1]);
%      S(2, 2)     % 9
%
%   Voir aussi DETECTSURFFEATURES, INTEGRALIMAGE, INTEGRALFILTER.
    h = taille(1);
    l = taille(2);
    lignes = (1:h) + marge;
    colonnes = (1:l) + marge;
    r1 = lignes + boite(1);
    r2 = lignes + boite(2) + 1;
    c1 = colonnes + boite(3);
    c2 = colonnes + boite(4) + 1;
    S = integrale(r2, c2) - integrale(r1, c2) - integrale(r2, c1) + integrale(r1, c1);
end
