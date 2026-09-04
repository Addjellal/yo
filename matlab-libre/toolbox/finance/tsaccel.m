function acceleration = tsaccel(serie, periode)
%TSACCEL Accélération d'une série.
%   A = TSACCEL(SERIE,N) rend la variation de l'élan : la dérivée seconde
%   du cours, mesurée à la grosse. N vaut 12 par défaut.
%
%   Exemple :
%      tsaccel(clotures, 12)
%
%   Voir aussi TSMOM, PRCROC, MACD.
    if nargin < 2 || isempty(periode), periode = 12; end
    moment = tsmom(serie, periode);
    acceleration = zeros(size(moment));
    for k = (periode + 1):numel(moment)
        acceleration(k) = moment(k) - moment(k - periode);
    end
end
