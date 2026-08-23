function [sos, g] = ss2sos(A, B, C, D, iu)
%SS2SOS Sections du second ordre d'une représentation d'état.
    if nargin < 5, iu = 1; end
    [num, den] = ss2tf(A, B, C, D, iu);
    [sos, g] = tf2sos(num, den);
end
