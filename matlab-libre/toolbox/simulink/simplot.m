function simplot(resultat, noms)
%SIMPLOT Trace les signaux relevés par SIM.
%   SIMPLOT(RESULTAT) trace tous les signaux du résultat sur le même axe,
%   en fonction du temps. SIMPLOT(RESULTAT,NOMS) n'en trace que
%   quelques-uns, désignés par leur nom de bloc.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'consigne', 'Value', 1);
%      m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
%      m = add_block(m, 'gain', 'gain', 'Gain', 2);
%      m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);
%      m = add_line(m, 'erreur', 'gain');
%      m = add_line(m, 'gain', 'sortie');
%      r = sim(m, 5, 0.01);
%      simplot(r, {'consigne', 'sortie'});
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
