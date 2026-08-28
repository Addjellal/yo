function [z, w] = cgComplexeRacine(x)
%CGCOMPLEXERACINE Racine et logarithme d'un complexe, et un test d'egalite.
    z = sqrt(complex(x, -1));
    if z == 0
        w = complex(0, 0);
    else
        w = log(z) - conj(z);
    end
end
