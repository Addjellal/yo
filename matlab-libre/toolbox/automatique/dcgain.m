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
%   Voir aussi BANDWIDTH, STEPINFO, EVALFR, FREQRESP.
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
