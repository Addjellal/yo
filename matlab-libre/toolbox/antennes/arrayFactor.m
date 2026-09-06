function AF = arrayFactor(n, d, theta, phase)
%ARRAYFACTOR Facteur d'un réseau linéaire uniforme.
%   AF = ARRAYFACTOR(N,D,THETA,PHASE) pour N éléments espacés de D
%   longueurs d'onde, THETA en radians depuis l'axe du réseau, PHASE le
%   déphasage progressif d'un élément au suivant.
%
%   Le facteur de réseau vaut N quand tous les éléments s'additionnent en
%   phase, et s'annule N-1 fois par période du déphasage psi = 2 pi d
%   cos(theta) + phase. Entre deux zéros il y a un lobe : N-1 en tout, un
%   principal et N-2 secondaires.
%
%   Le premier lobe secondaire d'un réseau uniforme tend vers -13,26 dB du
%   principal quand N croît, et ne descend jamais plus bas : c'est le prix
%   d'une alimentation uniforme, et la raison pour laquelle on pondère les
%   amplitudes quand on veut mieux.
%
%   Le déphasage progressif dépointe le faisceau sans rien bouger : c'est
%   tout le principe du balayage électronique. Il suffit de poser
%   PHASE = -2 pi d cos(visée).
%
%   Espacer de plus d'une demi-longueur d'onde fait apparaître des lobes
%   de réseau : un second maximum aussi fort que le principal, dans une
%   direction parasite. C'est la limite qui fixe le pas d'un réseau.
%
%   Exemple :
%      theta = linspace(1e-6, pi - 1e-6, 4001);
%      AF = arrayFactor(8, 0.5, theta);
%      max(AF)                         % 8 : les huit en phase
%      AF = arrayFactor(8, 0.5, theta, -2*pi*0.5*cosd(60));   % vise a 60
%
%   Voir aussi DIRECTIVITY, BEAMWIDTH, DIPOLEPATTERN, STEERINGVECTOR.
    if nargin < 4
        phase = 0;
    end
    psi = 2 * pi * d * cos(theta) + phase;
    AF = zeros(size(theta));
    for k = 1:numel(psi)
        if abs(sin(psi(k) / 2)) < 1e-12
            AF(k) = n;
        else
            AF(k) = abs(sin(n * psi(k) / 2) / sin(psi(k) / 2));
        end
    end
end
