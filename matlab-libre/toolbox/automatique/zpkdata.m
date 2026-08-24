function [z, p, k, Ts] = zpkdata(sys, forme)
%ZPKDATA Zéros, pôles et gain d'un modèle.
%   [Z,P,K] = ZPKDATA(SYS) rend les zéros et les pôles en colonnes, et le
%   gain. ZPKDATA(SYS,'v') est accepté et rend la même chose.
%   [Z,P,K,TS] = ZPKDATA(SYS) rend en plus la période d'échantillonnage.
%
%   Exemple :
%      [z, p, k] = zpkdata(tf([2 2], [1 3 2]));   % z = -1, p = [-2;-1], k = 2
%
%   Voir aussi SSDATA, TFDATA, ZPK.
    [num, den, Ts] = tfdata(sys);
    if nargin >= 2 && ~isempty(forme) && ~any(strcmpi(char(forme), {'v', 'vector'}))
        error('control:zpkdata:BadForm', 'La forme doit être ''v''.');
    end
    [z, p, k] = tf2zp(num, den);
    z = z(:);
    p = p(:);
end
