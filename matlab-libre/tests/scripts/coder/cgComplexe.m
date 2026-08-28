function z = cgComplexe(a, b)
%CGCOMPLEXE Arithmetique complexe : les quatre operations et la puissance.
    z = (a + b) * (a - b) / (a + 2i) + a ^ 2;
end
