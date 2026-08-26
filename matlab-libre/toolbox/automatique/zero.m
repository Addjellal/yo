function z = zero(sys)
%ZERO Zéros d'un modèle linéaire.
    if strcmp(sys.type, 'ss')
        [num, ~] = ss2tf(sys.A, sys.B, sys.C, sys.D);
        z = roots(num);
    else
        z = roots(sys.num);
    end
end
