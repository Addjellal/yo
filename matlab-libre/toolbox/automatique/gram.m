function W = gram(systeme, type)
%GRAM Grammiens de commandabilité et d'observabilité.
%   W = GRAM(SYS,'c') résout A*W + W*A' + B*B' = 0 ;
%   W = GRAM(SYS,'o') résout A'*W + W*A + C'*C = 0.
%
%   Exemple :
%      gram(ss(-1, 1, 1, 0), 'c')   % 0.5
    if nargin < 2, type = 'c'; end
    a = systeme.A;
    if strncmpi(type, 'c', 1)
        Q = systeme.B * systeme.B';
        W = lyap(a, Q);
    else
        Q = systeme.C' * systeme.C;
        W = lyap(a', Q);
    end
end
