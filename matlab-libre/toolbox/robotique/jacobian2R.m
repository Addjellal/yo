function J = jacobian2R(q, l1, l2)
%JACOBIAN2R Jacobienne d'un bras plan à deux segments.
    if nargin < 2, l1 = 1; end
    if nargin < 3, l2 = 1; end
    s1 = sin(q(1)); c1 = cos(q(1));
    s12 = sin(q(1) + q(2)); c12 = cos(q(1) + q(2));
    J = [-l1*s1 - l2*s12, -l2*s12;
          l1*c1 + l2*c12,  l2*c12];
end
