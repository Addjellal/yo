function Z = gamma2z(g, Z0)
%GAMMA2Z Impédance à partir du coefficient de réflexion.
    if nargin < 2
        Z0 = 50;
    end
    Z = Z0 * (1 + g) ./ (1 - g);
end
