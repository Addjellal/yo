function L = fspl(R, lambda)
%FSPL Affaiblissement de propagation en espace libre, en décibels.
%   L = FSPL(R,LAMBDA) = 20 log10(4 pi R / LAMBDA) pour une distance R et
%   une longueur d'onde LAMBDA en mètres, comme MATLAB. Pour M distances
%   et N longueurs d'onde, L est M x N ; avec une seule longueur d'onde,
%   L a la forme de R.
%
%   La formule suppose le champ lointain ; plus près, elle rendrait un
%   gain. L'affaiblissement est donc borné à 0 dB pour R <= LAMBDA/(4 pi).
%
%   Exemple :
%      % Documentation de MATLAB.
%      L = fspl(10e3, physconst('LightSpeed') / 10e9)    % 132.4478 dB
%
%   Voir aussi FRIIS, PATHLOSS, RADAREQRNG.
    if any(R(:) < 0) || any(lambda(:) <= 0)
        error('phased:fspl:Arguments', ...
              'R must be nonnegative and LAMBDA strictly positive.');
    end
    if isscalar(lambda)
        L = 20 * log10(4 * pi * R / lambda);
    else
        L = 20 * log10(4 * pi * R(:) ./ lambda(:).');
    end
    L = max(L, 0);
end
