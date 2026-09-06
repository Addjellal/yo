function r = rms(x, dim)
%RMS Valeur efficace (racine de la moyenne des carrés).
%   R = RMS(X) rend la racine de la moyenne des carrés de tous les
%   éléments de X. R = RMS(X,DIM) opère le long de la dimension DIM.
%
%   C'est la valeur d'un continu qui dissiperait la même puissance : le
%   carré de la valeur efficace est la puissance moyenne, et c'est à ce
%   titre qu'elle mesure un signal quelconque. Pour une sinusoïde
%   d'amplitude A elle vaut A/sqrt(2), pour un carré d'amplitude A elle
%   vaut A — deux signaux de même crête n'ont pas la même valeur efficace.
%
%   Elle ne se confond pas avec l'écart type : celui-ci retranche d'abord
%   la moyenne. Les deux coïncident sur un signal centré, et diffèrent dès
%   qu'une composante continue s'ajoute.
%
%   Exemple :
%      rms(sin(2*pi*(0:999)/1000))
%
%   Voir aussi STD, PEAK2RMS, BANDPOWER, MEAN.
    if nargin < 2
        x = x(:);
        r = sqrt(mean(x .^ 2));
    else
        r = sqrt(mean(x .^ 2, dim));
    end
end
