function c = addCurrentSource(c, n1, n2, I)
%ADDCURRENTSOURCE Source de courant idéale, de n1 vers n2.
    c = addComponent(c, 'i', n1, n2, I);
end
