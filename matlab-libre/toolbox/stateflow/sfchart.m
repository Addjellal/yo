function machine = sfchart(nom)
%SFCHART Crée une machine à états vide.
    machine = struct();
    machine.nom = nom;
    machine.etats = {};
    machine.transitions = {};
    machine.initial = '';
end
