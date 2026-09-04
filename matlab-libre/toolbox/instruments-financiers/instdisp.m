function instdisp(jeu)
%INSTDISP Écrit le contenu d'un jeu d'instruments.
%   Une table par type, une ligne par instrument, précédée de son numéro
%   dans le jeu.
%
%   Exemple :
%      instdisp(instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029'))
%
%   Voir aussi INSTADD, INSTGET, INSTLENGTH.
    if jeu.Nombre == 0
        fprintf('  jeu d''instruments vide\n');
        return
    end
    for j = 1:numel(jeu.Type)
        fprintf('\n  %s\n', jeu.Type{j});
        noms = jeu.FieldName{j};
        fprintf('  %-6s', 'Index');
        for c = 1:numel(noms)
            fprintf(' %14s', noms{c});
        end
        fprintf('\n');
        for k = 1:numel(jeu.Index{j})
            fprintf('  %-6d', jeu.Index{j}(k));
            for c = 1:numel(noms)
                valeur = jeu.FieldData{j}{c};
                if iscell(valeur)
                    fprintf(' %14s', valeur{k});
                else
                    fprintf(' %14.6g', valeur(k, 1));
                end
            end
            fprintf('\n');
        end
    end
    fprintf('\n');
end
