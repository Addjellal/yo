function fis = newfis(nom)
%NEWFIS Crée un système d'inférence floue de Mamdani.
    fis = struct();
    fis.nom = nom;
    fis.entrees = {};
    fis.sorties = {};
    fis.regles = [];
end
