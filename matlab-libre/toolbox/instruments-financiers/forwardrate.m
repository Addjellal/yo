function f = forwardrate(taux1, t1, taux2, t2)
%FORWARDRATE Taux à terme implicite entre deux échéances.
    f = ((1 + taux2) ^ t2 / (1 + taux1) ^ t1) ^ (1 / (t2 - t1)) - 1;
end
