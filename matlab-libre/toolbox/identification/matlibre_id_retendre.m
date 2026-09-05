function z = matlibre_id_retendre(obj, tendance)
%MATLIBRE_ID_RETENDRE Remet une tendance retirée par DETREND.
%   Z = MATLIBRE_ID_RETENDRE(OBJ,TENDANCE) rajoute ce que DETREND avait
%   ôté. C'est ce qu'il faut pour ramener une simulation dans les unités
%   des mesures d'origine.
%
%   Exemple :
%      z = iddata((1:10)' + 100, (1:10)');
%      [d, t] = detrend(z);
%      max(abs(retrend(d, t).y - z.y))      % zero
%
%   Voir aussi DETREND, IDDATA.
    z = obj;
    experiences = matlibre_id_nombre_experiences(obj);
    for k = 1:experiences
        courant = matlibre_id_bloc(obj.OutputData, k);
        if numel(tendance.sortie) >= k && ~isempty(tendance.sortie{k})
            t = (1:size(courant, 1)).';
            A = matlibre_id_base_tendance(t, tendance.ordre);
            courant = courant + A * tendance.sortie{k};
            z = matlibre_id_poser_bloc(z, 'OutputData', k, courant);
        end
        if ~isempty(obj.InputData) && numel(tendance.entree) >= k && ...
           ~isempty(tendance.entree{k})
            entree = matlibre_id_bloc(obj.InputData, k);
            t = (1:size(entree, 1)).';
            A = matlibre_id_base_tendance(t, tendance.ordre);
            entree = entree + A * tendance.entree{k};
            z = matlibre_id_poser_bloc(z, 'InputData', k, entree);
        end
    end
end
