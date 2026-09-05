function z = matlibre_id_extraire(obj, indices)
%MATLIBRE_ID_EXTRAIRE Sous-ensemble d'un jeu de données.
%   Z = MATLIBRE_ID_EXTRAIRE(OBJ,INDICES) découpe le jeu. Le premier
%   indice choisit les échantillons, le deuxième les sorties, le
%   troisième les entrées : Z(1:100) garde les cent premiers instants,
%   Z(:,1,:) la première sortie.
%
%   Exemple :
%      z = iddata((1:10)', (1:10)');
%      z(1:5).N      % 5
%
%   Voir aussi IDDATA.
    z = obj;
    if isempty(indices)
        return
    end
    if iscell(z.OutputData)
        for k = 1:numel(z.OutputData)
            z.OutputData{k} = matlibre_id_decouper(z.OutputData{k}, indices, 1);
            if ~isempty(z.InputData)
                z.InputData{k} = matlibre_id_decouper(z.InputData{k}, indices, 2);
            end
        end
    else
        z.OutputData = matlibre_id_decouper(z.OutputData, indices, 1);
        if ~isempty(z.InputData)
            z.InputData = matlibre_id_decouper(z.InputData, indices, 2);
        end
    end
    if numel(indices) >= 2 && ~ischar(indices{2})
        z.OutputName = z.OutputName(indices{2});
    end
    if numel(indices) >= 3 && ~ischar(indices{3})
        z.InputName = z.InputName(indices{3});
    end
end

function bloc = matlibre_id_decouper(bloc, indices, voie)
    if isempty(bloc)
        return
    end
    lignes = ':';
    if numel(indices) >= 1 && ~(ischar(indices{1}) && strcmp(indices{1}, ':'))
        lignes = indices{1};
    end
    colonnes = ':';
    if numel(indices) >= voie + 1 && ...
       ~(ischar(indices{voie + 1}) && strcmp(indices{voie + 1}, ':'))
        colonnes = indices{voie + 1};
    end
    if ischar(lignes)
        lignes = 1:size(bloc, 1);
    end
    if ischar(colonnes)
        colonnes = 1:size(bloc, 2);
    end
    bloc = bloc(lignes, colonnes);
end
