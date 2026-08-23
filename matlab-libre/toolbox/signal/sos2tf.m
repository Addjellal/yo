function [b, a] = sos2tf(sos, g)
%SOS2TF Sections du second ordre vers fonction de transfert.
    if nargin < 2, g = 1; end
    b = g;
    a = 1;
    for k = 1:size(sos, 1)
        b = conv(b, sos(k, 1:3));
        a = conv(a, sos(k, 4:6));
    end
    % Les zéros de tête n'ont pas de sens dans une fonction de transfert.
    while numel(b) > 1 && b(1) == 0, b(1) = []; end
    while numel(a) > 1 && a(1) == 0, a(1) = []; end
end
