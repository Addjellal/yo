function simplot(resultat, noms)
%SIMPLOT Trace les signaux relevés par SIM.
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
