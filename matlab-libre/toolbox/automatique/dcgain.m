function k = dcgain(sys)
%DCGAIN Gain statique d'un modèle.
%   Pour un modèle continu, c'est H(0) ; en discret, H(1).
    if strcmp(sys.type, 'ss')
        [num, den] = ss2tf(sys.A, sys.B, sys.C, sys.D);
    else
        num = sys.num;
        den = sys.den;
    end
    if sys.Ts == 0
        k = polyval(num, 0) / polyval(den, 0);
    else
        k = polyval(num, 1) / polyval(den, 1);
    end
end
