function extrait = matlibre_jeu_extraire(jeu, indices)
%MATLIBRE_JEU_EXTRAIRE Sous-jeu portant les instruments demandés.
%   Les numéros sont renumérotés de un à N, dans l'ordre d'origine.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    indices = sort(double(indices(:)));
    extrait = matlibre_jeu_vide();
    for j = 1:numel(jeu.Type)
        garde = ismember(jeu.Index{j}, indices);
        if ~any(garde)
            continue
        end
        extrait.Type{end+1} = jeu.Type{j};
        extrait.FieldName{end+1} = jeu.FieldName{j};
        extrait.FieldClass{end+1} = jeu.FieldClass{j};
        valeurs = cell(1, numel(jeu.FieldName{j}));
        for c = 1:numel(valeurs)
            donnee = jeu.FieldData{j}{c};
            if iscell(donnee)
                valeurs{c} = donnee(garde);
            else
                valeurs{c} = donnee(garde, :);
            end
        end
        extrait.FieldData{end+1} = valeurs;
        anciens = jeu.Index{j}(garde);
        nouveaux = zeros(numel(anciens), 1);
        for k = 1:numel(anciens)
            nouveaux(k) = find(indices == anciens(k), 1);
        end
        extrait.Index{end+1} = nouveaux;
    end
    extrait.Nombre = numel(indices);
end
