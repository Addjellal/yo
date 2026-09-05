function modele = bj(donnees, ordres, varargin)
%BJ Estimation d'un modèle de Box et Jenkins.
%   M = BJ(Z,[nb nc nd nf nk]) ajuste
%
%      y(t) = [B(q)/F(q)] u(t-nk) + [C(q)/D(q)] e(t)
%
%   C'est le modèle le plus général de la famille : l'entrée et le bruit
%   ont chacun leur dynamique propre, sans rien partager. Il faut donc
%   estimer plus de paramètres, mais aucune hypothèse abusive n'est faite
%   sur la façon dont le bruit entre.
%
%   Exemple :
%      m = bj(z, [1 1 1 1 1]);
%
%   Voir aussi OE, ARMAX, ARX, POLYEST.
    ordres = matlibre_id_ordres_famille(ordres, 'bj');
    modele = matlibre_id_estimer(donnees, ordres, 'bj', varargin);
end
