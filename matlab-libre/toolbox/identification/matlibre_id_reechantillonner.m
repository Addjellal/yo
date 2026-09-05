function z = matlibre_id_reechantillonner(obj, p, q)
%MATLIBRE_ID_REECHANTILLONNER Change la cadence d'un jeu de données.
%   Z = MATLIBRE_ID_REECHANTILLONNER(OBJ,P,Q) rééchantillonne dans le
%   rapport P sur Q, et met à jour la période. Le signal est interpolé sur
%   la nouvelle grille de temps.
%
%   Exemple :
%      z = resample(iddata((1:10)', (1:10)'), 1, 2);
%      z.N      % 5
%
%   Voir aussi IDDATA, RESAMPLE.
    z = obj;
    experiences = matlibre_id_nombre_experiences(obj);
    for k = 1:experiences
        sortie = matlibre_id_bloc(obj.OutputData, k);
        n = size(sortie, 1);
        nouveau = max(1, round(n * p / q));
        ancienne = (0:(n - 1)).';
        nouvelle = linspace(0, n - 1, nouveau).';
        z = matlibre_id_poser_bloc(z, 'OutputData', k, ...
                                   interp1(ancienne, sortie, nouvelle, 'linear'));
        if ~isempty(obj.InputData)
            entree = matlibre_id_bloc(obj.InputData, k);
            z = matlibre_id_poser_bloc(z, 'InputData', k, ...
                                       interp1(ancienne, entree, nouvelle, 'linear'));
        end
    end
    z.Ts = obj.Ts * q / p;
end
