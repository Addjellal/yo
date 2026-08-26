function [num, den, Ts] = tfdata(sys, forme)
%TFDATA Numérateur et dénominateur d'un modèle.
%   [NUM,DEN] = TFDATA(SYS) rend les deux polynômes, par puissances
%   décroissantes. Comme les modèles sont monovariables, NUM et DEN sont
%   des vecteurs ; TFDATA(SYS,'v') est accepté et rend la même chose.
%   [NUM,DEN,TS] = TFDATA(SYS) rend en plus la période d'échantillonnage.
%
%   Exemple :
%      [n, d] = tfdata(ss(-1, 1, 1, 0));   % n = [0 1], d = [1 1]
%
%   Voir aussi SSDATA, ZPKDATA, TF.
    g = tf(sys);
    num = g.num(:).';
    den = g.den(:).';
    Ts = g.Ts;
    if nargin >= 2 && ~isempty(forme) && ~any(strcmpi(char(forme), {'v', 'vector'}))
        error('control:tfdata:BadForm', 'La forme doit être ''v''.');
    end
end
