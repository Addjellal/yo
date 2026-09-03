function arbre = scinderNoeud(arbre, indice)
%SCINDERNOEUD Coupe un nœud d'un arbre de paquets en ses enfants.
%   C'est le rouage commun de WPDEC et de WPSPLT. Le nœud est filtré par
%   le banc — deux voies en une dimension, quatre en deux —, et les
%   enfants prennent les indices que DEPO2IND leur donne.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    ordre = arbre.ordre;
    donnees = lireNoeud(arbre, indice);
    if isempty(donnees)
        error('wavelet:scinderNoeud:Absent', ...
              'Le nœud %d n''est pas dans l''arbre.', indice);
    end
    if arbre.dimension == 1
        [a, d] = dwt(donnees, arbre.nom);
        enfants = {a, d};
    else
        [a, h, v, dd] = dwt2(donnees, arbre.nom);
        enfants = {a, h, v, dd};
    end
    for k = 1:ordre
        fils = ordre * indice + k;
        arbre = poserNoeud(arbre, fils, enfants{k});
    end
end
