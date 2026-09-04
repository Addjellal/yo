function tendance = pvtrend(cloture, volume)
%PVTREND Tendance du couple cours-volume.
%   T = PVTREND(CLOTURE,VOLUME) cumule le volume multiplié par la
%   variation relative du cours. C'est le volume sur solde, pondéré par
%   l'ampleur du mouvement plutôt que par son seul signe.
%
%   Exemple :
%      pvtrend(clotures, volumes)
%
%   Voir aussi ONBALVOL, NEGVOLIDX, POSVOLIDX, ADLINE.
    if nargin < 2
        series = matlibre_colonnes_marche(cloture, {}, {'cloture', 'volume'});
    else
        series = matlibre_colonnes_marche(cloture, {volume}, {'cloture', 'volume'});
    end
    C = series{1}; V = series{2};
    variations = [0; diff(C) ./ C(1:end-1)];
    tendance = cumsum(variations .* V);
end
