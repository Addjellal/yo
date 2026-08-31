function k = dcgain(sys)
%DCGAIN Gain statique d'un modèle.
%   K = DCGAIN(SYS) rend le gain que le modèle applique à une entrée
%   constante : H(0) en temps continu, H(1) en discret. C'est le rapport
%   entre la sortie et l'entrée une fois le régime établi.
%
%   Un intégrateur donne un gain infini ; un dérivateur, un gain nul.
%
%   Exemples :
%      dcgain(tf(10, [1 2]))                % 5
%      dcgain(tf(1, [1 0]))                 % Inf : un integrateur
%      dcgain(ss(-1, 1, 1, 0))              % 1
%
%      % Une matrice de transferts : le gain est une matrice
%      G = [tf(1, [1 1]), tf(2, [1 2]); tf(3, [1 3]), tf(4, [1 4])];
%      dcgain(G)                            % [1 1; 1 1]
%
%   Voir aussi BANDWIDTH, STEPINFO, EVALFR, FREQRESP.
    if strcmp(sys.type, 'ss')
        % Le gain statique d'un modele d'etat se lit dans les matrices :
        % D - C A^-1 B en continu, C (I-A)^-1 B + D en discret. On ne
        % passe plus par SS2TF, qui ne sait traiter qu'une seule voie et
        % refusait donc toute matrice de transferts.
        A = sys.A;
        B = sys.B;
        C = sys.C;
        D = sys.D;
        if isempty(A)
            k = D;
            return;
        end
        if sys.Ts == 0
            M = A;
        else
            M = A - eye(size(A, 1));
        end
        if rcond(M) < eps
            % Un pole en zero — un integrateur : le gain est infini, avec
            % le signe de la direction ou il l'est.
            k = D - C * pinv(M) * B;
            k(:) = Inf * sign(k(:) + (k(:) == 0));
            return;
        end
        k = D - C * (M \ B);
        return;
    end
    num = sys.num;
    den = sys.den;
    if sys.Ts == 0
        k = polyval(num, 0) / polyval(den, 0);
    else
        k = polyval(num, 1) / polyval(den, 1);
    end
end
