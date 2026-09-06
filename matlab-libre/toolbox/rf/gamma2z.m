function Z = gamma2z(g, Z0)
%GAMMA2Z Impédance à partir du coefficient de réflexion.
%   Z = GAMMA2Z(G) rend Z0 (1 + G) / (1 - G), avec Z0 = 50 ohms ;
%   GAMMA2Z(G,Z0) impose une autre impédance caractéristique.
%
%   C'est la réciproque exacte de Z2GAMMA, y compris pour une charge
%   complexe. Un coefficient de module un — toute la puissance revient —
%   donne une impédance purement réactive, ou infinie.
%
%   Exemple :
%      gamma2z(0)                      % 50 : adaptee
%      gamma2z(z2gamma(37 + 12i))      % 37 + 12i
%
%   Voir aussi Z2GAMMA, VSWR.
    if nargin < 2
        Z0 = 50;
    end
    Z = Z0 * (1 + g) ./ (1 - g);
end
