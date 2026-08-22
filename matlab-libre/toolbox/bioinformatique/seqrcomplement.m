function c = seqrcomplement(s)
%SEQRCOMPLEMENT Brin complémentaire inverse.
    c = seqcomplement(s);
    c = c(end:-1:1);
end
