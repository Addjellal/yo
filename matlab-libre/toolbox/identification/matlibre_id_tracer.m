function h = matlibre_id_tracer(obj, arguments)
%MATLIBRE_ID_TRACER Trace les sorties puis les entrées d'un jeu.
%   H = MATLIBRE_ID_TRACER(OBJ,ARGUMENTS) empile les voies : les sorties
%   au-dessus, les entrées au-dessous, sur le même axe des temps.
%
%   Exemple :
%      plot(iddata((1:10)', (1:10)'));
%
%   Voir aussi IDDATA.
    z = matlibre_id_experience(obj, 1);
    sortie = z.OutputData;
    entree = z.InputData;
    n = size(sortie, 1);
    t = z.Tstart + (0:(n - 1)).' * z.Ts;
    voies = size(sortie, 2) + matlibre_id_voies(entree);
    h = [];
    rang = 0;
    for k = 1:size(sortie, 2)
        rang = rang + 1;
        subplot(voies, 1, rang);
        h = plot(t, sortie(:, k), arguments{:});
        ylabel(z.OutputName{k});
    end
    for k = 1:matlibre_id_voies(entree)
        rang = rang + 1;
        subplot(voies, 1, rang);
        plot(t, entree(:, k), arguments{:});
        ylabel(z.InputName{k});
    end
    xlabel('temps');
end
