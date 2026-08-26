function facteur = modnorm(constellation, type, puissance)
%MODNORM Facteur de normalisation d'une constellation.
%   F = MODNORM(CONST,'avpow',P) rend le facteur par lequel multiplier les
%   symboles pour que leur puissance moyenne vaille P.
%   F = MODNORM(CONST,'peakpow',P) fait de même pour la puissance crête.
%
%   Sans normalisation, deux constellations d'ordres différents n'ont pas
%   la même puissance : comparer leurs taux d'erreur n'aurait pas de sens.
%
%   Exemple :
%      c = qammod(0:15, 16);
%      f = modnorm(c, 'avpow', 1);
%      mean(abs(f * c) .^ 2)   % 1
%
%   Voir aussi QAMMOD, GENQAMMOD, AWGN.
    if nargin < 2 || isempty(type), type = 'avpow'; end
    if nargin < 3 || isempty(puissance), puissance = 1; end
    v = double(constellation(:));
    switch lower(char(type))
        case {'avpow', 'avgpow'}
            reference = mean(abs(v) .^ 2);
        case 'peakpow'
            reference = max(abs(v) .^ 2);
        otherwise
            error('comm:modnorm:BadType', ...
                  'Le type doit être ''avpow'' ou ''peakpow''.');
    end
    if reference <= 0
        error('comm:modnorm:ZeroPower', 'La constellation est de puissance nulle.');
    end
    facteur = sqrt(puissance / reference);
end
