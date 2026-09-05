function matlibre_id_tracer_comparaison(jeu, prediction, ajustement)
%MATLIBRE_ID_TRACER_COMPARAISON Superpose mesures et sortie du modèle.
%   MATLIBRE_ID_TRACER_COMPARAISON(JEU,PREDICTION,AJUSTEMENT) trace les
%   deux courbes et annonce l'ajustement dans le titre.
%
%   Exemple :
%      compare(m, z);
%
%   Voir aussi COMPARE.
    n = size(jeu.OutputData, 1);
    t = jeu.Tstart + (0:(n - 1)).' * jeu.Ts;
    plot(t, jeu.OutputData, 'k-');
    etat = ishold();
    hold('on');
    plot(t, prediction.OutputData, 'b--');
    if ~etat
        hold('off');
    end
    xlabel('temps');
    ylabel(jeu.OutputName{1});
    title(sprintf('ajustement : %.2f %%', ajustement));
    legend('mesure', 'modele');
end
