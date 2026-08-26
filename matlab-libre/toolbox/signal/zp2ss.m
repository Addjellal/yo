function [A, B, C, D] = zp2ss(z, p, k)
%ZP2SS Représentation d'état à partir des zéros, pôles et gain.
    [b, a] = zp2tf(z, p, k);
    [A, B, C, D] = tf2ss(b, a);
end
