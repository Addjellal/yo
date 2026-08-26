function c = addResistor(c, n1, n2, R)
%ADDRESISTOR Résistance de R ohms entre deux nœuds.
    c = addComponent(c, 'r', n1, n2, R);
end
