function z = matlibre_id_completer(obj)
%MATLIBRE_ID_COMPLETER Remplace les données manquantes d'un jeu.
%   Z = MATLIBRE_ID_COMPLETER(OBJ) reconstruit les valeurs NaN par
%   interpolation linéaire entre les instants connus, et par prolongement
%   de la valeur la plus proche aux bords.
%
%   Un estimateur ne sait pas quoi faire d'un trou, et l'écarter romprait
%   la suite temporelle dont il tire justement la dynamique : il faut donc
%   le boucher.
%
%   Exemple :
%      z = misdata(iddata([1; NaN; 3]));
%      z.y(2)      % 2
%
%   Voir aussi IDDATA, MISDATA.
    z = obj;
    experiences = matlibre_id_nombre_experiences(obj);
    for k = 1:experiences
        z = matlibre_id_poser_bloc(z, 'OutputData', k, ...
                                   matlibre_id_boucher(matlibre_id_bloc(obj.OutputData, k)));
        if ~isempty(obj.InputData)
            z = matlibre_id_poser_bloc(z, 'InputData', k, ...
                                       matlibre_id_boucher(matlibre_id_bloc(obj.InputData, k)));
        end
    end
end

function bloc = matlibre_id_boucher(bloc)
    for c = 1:size(bloc, 2)
        colonne = bloc(:, c);
        connus = find(~isnan(colonne));
        if isempty(connus)
            colonne(:) = 0;
        elseif numel(connus) < numel(colonne)
            colonne = interp1(connus, colonne(connus), (1:numel(colonne)).', ...
                              'linear', 'extrap');
            % Le prolongement lineaire au-dela des donnees connues peut
            % s'emballer ; on le retient a la derniere valeur vue.
            colonne(1:(connus(1) - 1)) = colonne(connus(1));
            colonne((connus(end) + 1):end) = colonne(connus(end));
        end
        bloc(:, c) = colonne;
    end
end
