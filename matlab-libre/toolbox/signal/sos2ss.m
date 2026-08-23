function [A, B, C, D] = sos2ss(sos, g)
%SOS2SS Représentation d'état d'un enchaînement de sections du second ordre.
    if nargin < 2, g = 1; end
    [b, a] = sos2tf(sos, g);
    [A, B, C, D] = tf2ss(b, a);
end
