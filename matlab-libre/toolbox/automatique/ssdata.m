function [A, B, C, D, Ts] = ssdata(sys)
%SSDATA Matrices d'état d'un modèle.
%   [A,B,C,D] = SSDATA(SYS) rend les quatre matrices, quelle que soit la
%   forme sous laquelle le modèle a été construit : une fonction de
%   transfert est d'abord réalisée sous forme compagne de commande.
%   [A,B,C,D,TS] = SSDATA(SYS) rend en plus la période d'échantillonnage.
%
%   Exemple :
%      [a, b, c, d] = ssdata(tf(1, [1 1]));   % a = -1, b = 1, c = 1, d = 0
%
%   Voir aussi TFDATA, ZPKDATA, SS.
    s = ss(sys);
    A = s.A;
    B = s.B;
    C = s.C;
    D = s.D;
    Ts = s.Ts;
end
