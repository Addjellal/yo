function varargout = matlibre_id_residus_bruts(e, u, arguments, sorties)
%MATLIBRE_ID_RESIDUS_BRUTS Analyse d'une suite de résidus déjà calculée.
%   [E,AUTO,CROISEE,SEUIL] = MATLIBRE_ID_RESIDUS_BRUTS(E,U,ARGUMENTS,N)
%   rend les corrélations et le seuil de confiance.
%
%   Exemple :
%      [e, auto] = matlibre_id_residus_bruts(randn(100,1), zeros(100,1), {}, 2);
%
%   Voir aussi RESID.
    decalage = 25;
    for k = 1:numel(arguments)
        if isnumeric(arguments{k}) && isscalar(arguments{k})
            decalage = round(arguments{k});
        end
    end
    if isempty(u)
        u = zeros(size(e));
    end
    auto = matlibre_id_correlation(e, e, decalage);
    croisee = matlibre_id_correlation(e, u, decalage);
    seuil = 2.58 / sqrt(numel(e));
    if sorties == 0
        matlibre_id_tracer_residus(auto, croisee, seuil, decalage);
        varargout = {};
        return
    end
    varargout = {e, auto, croisee, seuil};
    varargout = varargout(1:min(max(sorties, 1), 4));
end
