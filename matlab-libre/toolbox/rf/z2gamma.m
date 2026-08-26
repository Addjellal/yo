function g = z2gamma(Z, Z0)
%Z2GAMMA Coefficient de réflexion d'une impédance.
    if nargin < 2
        Z0 = 50;
    end
    g = (Z - Z0) ./ (Z + Z0);
end
