function moment = tsmom(serie, periode)
%TSMOM Élan d'une série.
%   M = TSMOM(SERIE,N) rend l'écart entre la valeur du jour et celle de N
%   séances plus tôt. N vaut 12 par défaut.
%
%   L'élan est la dérivée première du cours, mesurée à la grosse : il
%   change de signe avant le cours lui-même, ce qui explique qu'on
%   l'emploie comme signal avancé.
%
%   Exemple :
%      tsmom([100 102 105 103], 1)    % [0 2 3 -2]
%
%   Voir aussi TSACCEL, PRCROC, MACD.
    if nargin < 2 || isempty(periode), periode = 12; end
    serie = double(serie(:));
    moment = zeros(size(serie));
    for k = (periode + 1):numel(serie)
        moment(k) = serie(k) - serie(k - periode);
    end
end
