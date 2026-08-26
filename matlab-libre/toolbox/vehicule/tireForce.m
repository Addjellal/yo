function F = tireForce(glissement, chargeVerticale, B, C, D, E)
%TIREFORCE Force du pneu par la formule magique de Pacejka.
    if nargin < 3, B = 10; end
    if nargin < 4, C = 1.9; end
    if nargin < 5, D = 1.0; end
    if nargin < 6, E = 0.97; end
    F = chargeVerticale * D * sin(C * atan(B * glissement - ...
        E * (B * glissement - atan(B * glissement))));
end
