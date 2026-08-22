function c = circuit(nom)
%CIRCUIT Crée un circuit vide. Le nœud 0 est la masse.
    c = struct();
    c.nom = nom;
    c.composants = {};
    c.noeuds = 0;
end
