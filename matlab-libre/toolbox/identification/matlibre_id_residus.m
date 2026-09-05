function varargout = matlibre_id_residus(modele, donnees, arguments)
%MATLIBRE_ID_RESIDUS Examine les résidus d'un modèle estimé.
%   [E,AUTO,CROISEE,SEUIL] = MATLIBRE_ID_RESIDUS(MODELE,DONNEES,ARGUMENTS)
%   rend les résidus, leur autocorrélation, leur corrélation croisée avec
%   l'entrée, et le seuil de confiance à quatre-vingt-dix-neuf pour cent.
%
%   Deux choses se lisent dans ces courbes. Une autocorrélation qui sort
%   du seuil dit que le modèle du bruit est insuffisant : il reste de la
%   structure que le modèle n'a pas prise. Une corrélation croisée qui en
%   sort dit que l'entrée explique encore une part du résidu : c'est la
%   partie déterministe qui est mal décrite.
%
%   Exemple :
%      [e, auto, croisee, seuil] = resid(m, z);
%
%   Voir aussi COMPARE, PREDICT.
    decalage = 25;
    for k = 1:numel(arguments)
        if isnumeric(arguments{k}) && isscalar(arguments{k})
            decalage = round(arguments{k});
        end
    end
    jeu = matlibre_id_experience(iddata(donnees), 1);
    y = jeu.OutputData;
    u = jeu.InputData;
    if isempty(u)
        u = zeros(size(y));
    end
    e = matlibre_id_erreurs(modele, y, u);
    n = numel(e);
    auto = matlibre_id_correlation(e, e, decalage);
    croisee = matlibre_id_correlation(e, u, decalage);
    % Sous l'hypothèse d'un résidu blanc, la corrélation estimée est
    % approximativement normale d'écart type l'inverse de la racine du
    % nombre de points : le seuil est le quantile correspondant.
    seuil = 2.58 / sqrt(n);
    if nargout == 0
        matlibre_id_tracer_residus(auto, croisee, seuil, decalage);
        varargout = {};
        return
    end
    varargout = {e, auto, croisee, seuil};
    varargout = varargout(1:min(max(nargout, 1), 4));
end
