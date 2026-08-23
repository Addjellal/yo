function [n, Wn] = ellipord(Wp, Ws, Rp, Rs, domaine)
%ELLIPORD Ordre minimal d'un filtre elliptique.
%   [N,WN] = ELLIPORD(WP,WS,RP,RS) rend le plus petit ordre qui laisse
%   passer la bande WP avec au plus RP décibels d'ondulation et atténue
%   la bande WS d'au moins RS décibels. Les fréquences sont normalisées,
%   1 valant la moitié de la fréquence d'échantillonnage.
%
%   ELLIPORD(...,'s') travaille en radians par seconde, sans
%   pré-distorsion.
%
%   L'ordre vient de l'équation du degré des fonctions elliptiques :
%
%      N = ceil( K(k) K'(k1) / (K'(k) K(k1)) )
%
%   avec k le rapport des fréquences et k1 celui des ondulations.
%
%   Exemple :
%      [n, Wn] = ellipord(0.2, 0.3, 1, 40)   % n = 5
    if nargin < 5, domaine = 'z'; end
    analogique = strncmpi(char(domaine), 's', 1);
    Wp = double(Wp);
    Ws = double(Ws);
    if analogique
        wp = Wp;
        ws = Ws;
    else
        % Pré-distorsion : la bilinéaire comprime l'axe des fréquences.
        wp = tan(pi * Wp / 2);
        ws = tan(pi * Ws / 2);
    end
    if numel(wp) == 1
        if wp < ws
            k = wp / ws;                      % passe-bas
        else
            k = ws / wp;                      % passe-haut
        end
    else
        % Passe-bande ou coupe-bande : on ramène au passe-bas équivalent.
        if wp(1) > ws(1)
            % Passe-bande.
            candidats = abs((ws .^ 2 - wp(1) * wp(2)) ./ (ws * (wp(2) - wp(1))));
        else
            candidats = abs((ws * (wp(2) - wp(1))) ./ (ws .^ 2 - wp(1) * wp(2)));
        end
        k = 1 / min(candidats);
    end
    epsilonP = sqrt(10 ^ (Rp / 10) - 1);
    epsilonS = sqrt(10 ^ (Rs / 10) - 1);
    k1 = epsilonP / epsilonS;
    n = ceil(ellipke(k ^ 2) * ellipke(1 - k1 ^ 2) / ...
             (ellipke(1 - k ^ 2) * ellipke(k1 ^ 2)));
    Wn = Wp;
end
