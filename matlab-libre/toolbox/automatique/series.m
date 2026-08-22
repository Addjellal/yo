function sys = series(sys1, sys2)
%SERIES Mise en série de deux modèles.
%   SYS = SERIES(SYS1,SYS2) équivaut à SYS2 * SYS1.
    a = tf(sys1);
    b = tf(sys2);
    sys = tf(conv(a.num, b.num), conv(a.den, b.den), max(a.Ts, b.Ts));
end
