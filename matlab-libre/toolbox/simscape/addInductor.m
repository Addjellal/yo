function c = addInductor(c, n1, n2, L)
%ADDINDUCTOR Bobine de L henrys.
    c = addComponent(c, 'l', n1, n2, L);
end
