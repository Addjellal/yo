function [r, i, m, p] = cgComplexeParties(z)
%CGCOMPLEXEPARTIES Parties reelle et imaginaire, module et argument.
    r = real(z);
    i = imag(z);
    m = abs(z);
    p = angle(z);
end
