function y = pow2(f, e)
%POW2 Puissance de deux, ou mantisse mise à l'échelle.
%   Y = POW2(X) rend 2.^X.
%   Y = POW2(F,E) rend F .* 2.^E.
%
%   Exemple :
%      pow2(3)                     % 8
%      pow2(0.5, 4)                % 8 : mantisse et exposant
    if nargin == 1
        y = 2 .^ f;
    else
        y = f .* 2 .^ e;
    end
end
