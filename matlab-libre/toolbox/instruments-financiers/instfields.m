function champs = instfields(jeu, varargin)
%INSTFIELDS Noms des champs d'un jeu d'instruments.
%   C = INSTFIELDS(JEU) rend tous les noms de champs rencontrés.
%   INSTFIELDS(JEU,'Type',T) ne rend que ceux du type T.
%
%   Exemple :
%      jeu = instadd('Bond', 0.05, '01-Jan-2024', '01-Jan-2029');
%      jeu = instadd(jeu, 'Bond', 0.06, '01-Jan-2024', '01-Jan-2034');
%      instfields(jeu, 'Type', 'Bond')
%
%   Voir aussi INSTTYPES, INSTGET, INSTDISP.
    demande = '';
    k = 1;
    while k + 1 <= numel(varargin)
        if strcmpi(char(varargin{k}), 'type')
            demande = char(varargin{k+1});
        end
        k = k + 2;
    end
    champs = {};
    for j = 1:numel(jeu.Type)
        if ~isempty(demande) && ~strcmpi(jeu.Type{j}, demande)
            continue
        end
        for c = 1:numel(jeu.FieldName{j})
            nom = jeu.FieldName{j}{c};
            if ~any(strcmp(champs, nom))
                champs{end+1} = nom;   %#ok<AGROW>
            end
        end
    end
    champs = champs(:);
end
