function p = pole(sys)
%POLE Pôles d'un modèle linéaire.
    if strcmp(sys.type, 'ss')
        p = eig(sys.A);
    else
        p = roots(sys.den);
    end
end
