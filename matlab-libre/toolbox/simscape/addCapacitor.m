function c = addCapacitor(c, n1, n2, C)
%ADDCAPACITOR Condensateur de C farads.
    c = addComponent(c, 'c', n1, n2, C);
end
