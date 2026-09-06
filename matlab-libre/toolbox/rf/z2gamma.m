function g = z2gamma(Z, Z0)
%Z2GAMMA Coefficient de réflexion d'une impédance.
%   G = Z2GAMMA(Z) rend (Z - 50) / (Z + 50) ; Z2GAMMA(Z,Z0) impose une
%   autre impédance caractéristique.
%
%   Le coefficient de réflexion dit quelle part de l'onde incidente
%   revient, en amplitude et en phase. Une charge adaptée ne renvoie rien ;
%   un court-circuit renvoie tout en opposition de phase, un circuit
%   ouvert tout en phase. Une réactance pure renvoie tout, avec une phase
%   quelconque.
%
%   La fraction de puissance réfléchie est le carré de son module ; le
%   reste passe dans la charge.
%
%   Une impédance infinie rend NaN : la formule y est indéterminée, comme
%   dans MATLAB. Sa limite, elle, vaut bien +1.
%
%   Exemple :
%      z2gamma(50)                     % 0 : adaptee
%      z2gamma(100)                    % 1/3
%      abs(z2gamma(100))^2             % 1/9 de la puissance revient
%
%   Voir aussi GAMMA2Z, VSWR, SPARAM2ZPARAM.
    if nargin < 2
        Z0 = 50;
    end
    g = (Z - Z0) ./ (Z + Z0);
end
