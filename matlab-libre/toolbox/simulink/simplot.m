function simplot(resultat, noms)
%SIMPLOT Trace les signaux relevés par SIM.
%   SIMPLOT(RESULTAT) trace tous les signaux du résultat sur le même axe,
%   en fonction du temps. SIMPLOT(RESULTAT,NOMS) n'en trace que
%   quelques-uns, désignés par leur nom de bloc.
%
%   Exemple :
%      r = sim(modele, 5, 0.001);
%      simplot(r, {'consigne', 'sortie'});
%      legend('consigne', 'sortie');
%
%   Voir aussi SIM, PLOT, LEGEND.
    if nargin < 2
        noms = fieldnames(resultat.signaux);
    end
    hold on;
    for k = 1:numel(noms)
        plot(resultat.temps, resultat.signaux.(noms{k}));
    end
    hold off;
    grid on;
    xlabel('Temps (s)');
    legend(noms);
end
