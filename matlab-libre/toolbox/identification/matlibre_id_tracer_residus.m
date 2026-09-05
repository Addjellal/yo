function matlibre_id_tracer_residus(auto, croisee, seuil, decalage)
%MATLIBRE_ID_TRACER_RESIDUS Trace l'analyse des résidus.
%   MATLIBRE_ID_TRACER_RESIDUS(AUTO,CROISEE,SEUIL,DECALAGE) montre
%   l'autocorrélation puis la corrélation croisée, avec le seuil de
%   confiance : ce qui en sort n'est pas du hasard.
%
%   Exemple :
%      resid(m, z);
%
%   Voir aussi RESID.
    k = (-decalage:decalage).';
    subplot(2, 1, 1);
    plot(k, auto, 'b-', k, seuil * ones(size(k)), 'r--', ...
         k, -seuil * ones(size(k)), 'r--');
    title('autocorrelation des residus');
    subplot(2, 1, 2);
    plot(k, croisee, 'b-', k, seuil * ones(size(k)), 'r--', ...
         k, -seuil * ones(size(k)), 'r--');
    title('correlation croisee avec l''entree');
    xlabel('decalage');
end
