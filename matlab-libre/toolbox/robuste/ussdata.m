function [A, B, C, D, Ts, parametres] = ussdata(sys)
%USSDATA Les matrices d'un modèle incertain.
%   [A,B,C,D] = USSDATA(SYS) rend les quatre matrices du modèle, sous
%   forme d'UMAT : chacune garde la trace des paramètres dont elle
%   dépend.
%
%   [A,B,C,D,TS] = USSDATA(SYS) rend en outre la période
%   d'échantillonnage.
%   [A,B,C,D,TS,P] = USSDATA(SYS) rend la liste des paramètres.
%
%   C'est le pendant de SSDATA pour un modèle incertain.
%
%   Exemples :
%      k = ureal('k', 4, 'Range', [3 5]);
%      G = uss([0 1; -k -0.2], [0; 1], [1 0], 0);
%      [A, B, C, D] = ussdata(G);
%      getNominal(A)
%      usubs(A, 'k', 5)
%
%   Voir aussi SSDATA, USS, UMAT, GETNOMINAL, USUBS.
    sys = uss(sys);
    A = matriceDe(sys, 'A');
    B = matriceDe(sys, 'B');
    C = matriceDe(sys, 'C');
    D = matriceDe(sys, 'D');
    Ts = sys.Ts;
    parametres = sys.Uncertainty;
end
