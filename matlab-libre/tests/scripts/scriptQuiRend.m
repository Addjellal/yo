% scriptQuiRend.m — un script qui s'arrete au milieu, sur « return ».
%
% Sert a verifier que « return » arrete le script sans remonter plus haut :
% ni la fonction qui l'a lance, ni — dans une interface — la boucle
% d'evenements, ou une exception qui passe abat le programme.
marqueRetour = 1;
if marqueRetour == 1
    return
end
marqueRetour = 2;
