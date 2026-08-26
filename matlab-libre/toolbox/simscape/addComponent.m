function c = addComponent(c, type, n1, n2, valeur)
%ADDCOMPONENT Ajoute un composant entre deux nœuds.
    comp = struct();
    comp.type = lower(char(type));
    comp.n1 = n1;
    comp.n2 = n2;
    comp.valeur = valeur;
    c.composants{end+1} = comp;
    c.noeuds = max([c.noeuds, n1, n2]);
end
