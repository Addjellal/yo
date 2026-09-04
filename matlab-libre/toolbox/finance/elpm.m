function moment = elpm(moyenne, ecartType, seuil, ordre)
%ELPM Moment partiel inférieur attendu, sous hypothèse gaussienne.
%   M = ELPM(MOYENNE,ECART,SEUIL,ORDRE) rend la valeur théorique du
%   moment partiel inférieur pour des rendements gaussiens. Comparée au
%   moment observé, elle dit si la série perd plus souvent, ou plus
%   fort, que la loi normale ne le prévoit.
%
%   Les ordres 0, 1 et 2 ont une forme fermée ; au-delà, l'intégrale est
%   calculée numériquement.
%
%   Exemple :
%      elpm(0.01, 0.05, 0, 2)
%
%   Voir aussi LPM, PORTVRISK, NORMCDF.
    if nargin < 3 || isempty(seuil), seuil = 0; end
    if nargin < 4 || isempty(ordre), ordre = 0; end
    moyenne = double(moyenne);
    ecartType = double(ecartType);
    reduit = (seuil - moyenne) ./ ecartType;
    repartition = normcdf(reduit);
    densite = exp(-reduit .^ 2 / 2) / sqrt(2 * pi);
    switch ordre
        case 0
            moment = repartition;
        case 1
            moment = (seuil - moyenne) .* repartition + ecartType .* densite;
        case 2
            moment = ((seuil - moyenne) .^ 2 + ecartType .^ 2) .* repartition + ...
                     ecartType .* (seuil - moyenne) .* densite;
        otherwise
            moment = zeros(size(reduit));
            for k = 1:numel(reduit)
                integrande = @(z) (seuil - (moyenne(k) + ecartType(k) * z)) .^ ordre ...
                                  .* exp(-z .^ 2 / 2) / sqrt(2 * pi);
                moment(k) = integral(integrande, -12, reduit(k));
            end
    end
end
