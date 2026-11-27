function sv = steervec(pos, ang, nqbits)
%STEERVEC Vecteurs de pointage d'un réseau de capteurs isotropes.
%   SV = STEERVEC(POS,ANG) rend la matrice N x M des déphasages que subit
%   chacun des N capteurs pour chacune des M ondes planes, comme MATLAB :
%      SV = exp(1i * 2 * pi * POS.' * u),
%   où u est le vecteur unitaire de la direction d'arrivée.
%
%   POS donne les positions en longueurs d'onde :
%      1 x N  réseau linéaire le long de l'axe y ;
%      2 x N  réseau plan dans le plan yz, lignes (y ; z) ;
%      3 x N  forme quelconque, lignes (x ; y ; z).
%   ANG donne les directions en degrés : 1 x M azimuts (élévation nulle),
%   ou 2 x M colonnes [az ; el]. L'azimut se compte de l'axe x vers l'axe
%   y, l'élévation depuis le plan xy vers l'axe z.
%
%   SV = STEERVEC(POS,ANG,NQBITS) quantifie les phases sur NQBITS bits,
%   comme un déphaseur numérique : la phase est arrondie au multiple de
%   2 pi / 2^NQBITS le plus proche. NQBITS = 0, la valeur par défaut, ne
%   quantifie pas.
%
%   Exemple :
%      % Documentation de MATLAB.
%      sv = steervec((0:0.1:0.4) / (physconst('LightSpeed') / 1e9), [45; 0])
%      % 1, 0.0887 + 0.9961i, -0.9843 + 0.1767i, -0.2633 - 0.9647i, ...
%      sv3 = steervec((0:0.1:0.4) / 0.2998, [45; 0], 3)   % 1, i, -1, -i, 1
%
%   Voir aussi SENSORCOV, ROOTMUSICDOA, ESPRITDOA, MUSICDOA.
    if nargin < 3
        nqbits = 0;
    end
    P = matlibre_positions_capteurs(pos);
    if size(ang, 1) == 1
        az = ang; el = zeros(size(ang));
    elseif size(ang, 1) == 2
        az = ang(1, :); el = ang(2, :);
    else
        error('phased:steervec:Angles', ...
              'ANG must be 1-by-M (azimuth) or 2-by-M ([az; el]), in degrees.');
    end
    u = [cosd(el) .* cosd(az); cosd(el) .* sind(az); sind(el)];
    phase = 2 * pi * (P.' * u);
    if ~isscalar(nqbits) || nqbits < 0 || nqbits ~= fix(nqbits)
        error('phased:steervec:Bits', 'NQBITS must be a nonnegative integer.');
    end
    if nqbits > 0
        pas = 2 * pi / 2 ^ nqbits;
        phase = round(phase / pas) * pas;
    end
    sv = exp(1i * phase);
end
