function p = tcdf(t, nu)
%TCDF Fonction de répartition de la loi de Student.
%   P = TCDF(T,NU) utilise la relation avec la fonction beta incomplète :
%      P(T <= t) = 1 - I_{nu/(nu+t^2)}(nu/2, 1/2) / 2   pour t >= 0
%   ce qui est exact et rapide, contrairement à une intégration numérique.
    p = zeros(size(t));
    for k = 1:numel(t)
        x = t(k);
        z = nu / (nu + x ^ 2);
        moitie = betainc(z, nu / 2, 0.5) / 2;
        if x >= 0
            p(k) = 1 - moitie;
        else
            p(k) = moitie;
        end
    end
end
