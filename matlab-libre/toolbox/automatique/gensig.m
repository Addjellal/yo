function [u, t] = gensig(type, tau, Tf, Ts)
%GENSIG Signaux d'essai périodiques.
%   [U,T] = GENSIG(TYPE,TAU) engendre un signal de période TAU :
%     'sin'      sinusoïde
%     'square'   créneau, un pendant la première demi-période, zéro ensuite
%     'pulse'    impulsion d'un échantillon au début de chaque période
%
%   [U,T] = GENSIG(TYPE,TAU,TF) fixe la durée totale, cinq périodes par
%   défaut ; [U,T] = GENSIG(TYPE,TAU,TF,TS) fixe le pas d'échantillonnage,
%   TAU/64 par défaut.
%
%   Le signal se donne directement à LSIM.
%
%   Exemple :
%      [u, t] = gensig('square', 4, 12, 0.1);
%      y = lsim(tf(1, [1 1]), u, t);
%
%   Voir aussi LSIM, STEP, IMPULSE.
    if nargin < 2 || isempty(tau), tau = 1; end
    if nargin < 3 || isempty(Tf), Tf = 5 * tau; end
    if nargin < 4 || isempty(Ts), Ts = tau / 64; end
    t = (0:Ts:Tf)';
    phase = mod(t, tau);
    switch lower(char(type))
        case {'sin', 'sine'}
            u = sin(2 * pi * t / tau);
        case {'square', 'sq'}
            u = double(phase < tau / 2);
        case {'pulse', 'p'}
            u = double(phase < Ts / 2 | abs(phase - tau) < Ts / 2);
        otherwise
            error('control:gensig:BadType', ...
                  'Le type doit être ''sin'', ''square'' ou ''pulse''.');
    end
end
