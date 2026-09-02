function [gains, phases] = dmplot(marge)
%DMPLOT Trace ce qu'une marge de disque autorise.
%   DMPLOT(DM) trace, dans le plan gain-phase, la région des variations
%   simultanées que la marge de disque DM autorise sans déstabiliser la
%   boucle. On y lit d'un coup ce que la marge veut dire : jusqu'où le
%   gain peut varier si la phase ne bouge pas, jusqu'où la phase peut
%   varier si le gain ne bouge pas, et tous les compromis entre les deux.
%
%   [G,P] = DMPLOT(DM) rend les deux courbes sans rien tracer : G les
%   variations de gain, en décibels, P celles de phase, en degrés.
%
%   La frontière est celle du disque de rayon DM autour de un :
%   l'incertitude multiplicative (1 + DM*delta) avec delta de module au
%   plus un. Le gain va de (1-DM) à (1+DM), et la phase jusqu'à
%   2*asin(DM/2).
%
%   Exemples :
%      dmplot(0.5);
%      [g, p] = dmplot(0.3);
%      max(p)                          % la marge de phase pure, en degres
%      max(g)                          % la marge de gain pure, en dB
%
%   Voir aussi LOOPMARGIN, WCDISKMARGIN, NCFMARGIN, MARGIN, ALLMARGIN.
    if nargin < 1 || isempty(marge)
        marge = 0.5;
    end
    marge = min(max(marge, 0), 1 - 1e-9);
    theta = linspace(0, 2 * pi, 400);
    % Le bord du disque : 1 + marge*exp(i*theta).
    bord = 1 + marge * exp(1i * theta);
    gains = 20 * log10(abs(bord));
    phases = angle(bord) * 180 / pi;
    if nargout == 0
        plot(gains, phases, 'LineWidth', 1.5);
        hold('on');
        plot(0, 0, 'r+', 'LineWidth', 2);
        hold('off');
        xlabel('variation de gain (dB)');
        ylabel('variation de phase (deg)');
        title(sprintf('Ce que la marge de disque %.3g autorise', marge));
        grid('on');
        clear gains
    end
end
