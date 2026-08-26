function modele = new_system(nom)
%NEW_SYSTEM Crée un modèle Simulink vide.
    modele = struct();
    modele.nom = nom;
    modele.blocs = {};
    modele.liens = [];
end
