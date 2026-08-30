function ngrid(varargin)
%NGRID Abaque de Nichols : les courbes de gain en boucle fermée.
%   NGRID trace, sur un diagramme de Nichols, les courbes le long
%   desquelles le gain en boucle fermée est constant. Là où la courbe de
%   la boucle ouverte frôle celle de +3 dB, la boucle fermée résonne ;
%   celle de 0 dB passe par le point critique.
%
%   Les courbes viennent de l'équation |L/(1+L)| = M : à phase donnée, le
%   module |L| est racine d'un trinôme, et l'on trace la solution.
%
%   Exemples :
%      figure
%      nichols(tf(1, [1 1 1]));
%      ngrid
%      close
%
%   Voir aussi NICHOLS, SGRID, ZGRID, MARGIN.
    decibels = [-20 -12 -6 -3 -1 0 1 3 6 12 20];
    bornesX = xlim();
    bornesY = ylim();
    tenu = ishold();
    hold on;
    phases = linspace(-359, -1, 300);
    for k = 1:numel(decibels)
        M = 10 ^ (decibels(k) / 20);
        r = zeros(size(phases));
        for j = 1:numel(phases)
            c = cosd(phases(j));
            % r^2 (M^2 - 1) + 2 M^2 r c + M^2 = 0
            a = M^2 - 1;
            b = 2 * M^2 * c;
            cc = M^2;
            if abs(a) < 1e-12
                r(j) = -cc / b;
            else
                delta = b^2 - 4 * a * cc;
                if delta < 0
                    r(j) = NaN;
                else
                    r1 = (-b + sqrt(delta)) / (2 * a);
                    r2 = (-b - sqrt(delta)) / (2 * a);
                    candidats = [r1 r2];
                    candidats = candidats(candidats > 0);
                    if isempty(candidats)
                        r(j) = NaN;
                    else
                        r(j) = max(candidats);
                    end
                end
            end
        end
        garde = isfinite(r) & r > 0;
        if any(garde)
            plot(phases(garde), 20 * log10(r(garde)), ':', 'Color', '#B0B0B0');
        end
    end
    xlim(bornesX);
    ylim(bornesY);
    if ~tenu
        hold off;
    end
end
