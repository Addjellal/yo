function jeu = instsetfield(jeu, varargin)
%INSTSETFIELD Change la valeur d'un champ dans un jeu d'instruments.
%   J = INSTSETFIELD(JEU,'Index',I,'FieldName',N,'Data',D) écrit D dans
%   le champ N des instruments de numéros I. 'Type' désigne les
%   instruments par leur type.
%
%   Exemple :
%      jeu = instsetfield(jeu, 'Index', 1, 'FieldName', 'CouponRate', ...
%                         'Data', 0.06);
%
%   Voir aussi INSTADDFIELD, INSTGET, INSTADD.
    indices = [];
    type = '';
    noms = {};
    donnees = {};
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'index',     indices = double(varargin{k+1}(:));
            case 'type',      type = char(varargin{k+1});
            case 'fieldname'
                valeur = varargin{k+1};
                if ischar(valeur) || isstring(valeur)
                    noms = {char(valeur)};
                else
                    noms = valeur(:).';
                end
            case 'data'
                valeur = varargin{k+1};
                if iscell(valeur) && numel(noms) > 1
                    donnees = valeur(:).';
                else
                    donnees = {valeur};
                end
            otherwise
                error('finstr:instsetfield:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(indices)
        if isempty(type)
            indices = (1:jeu.Nombre).';
        else
            rang = find(strcmpi(jeu.Type, type), 1);
            indices = jeu.Index{rang};
        end
    end
    for c = 1:numel(noms)
        valeur = donnees{min(c, numel(donnees))};
        for k = 1:numel(indices)
            [j, rangLocal] = matlibre_jeu_situer(jeu, indices(k));
            if isempty(j)
                continue
            end
            rang = find(strcmpi(jeu.FieldName{j}, noms{c}), 1);
            if isempty(rang)
                error('finstr:instsetfield:Champ', ...
                      'Le type %s n''a pas de champ %s.', jeu.Type{j}, noms{c});
            end
            if iscell(jeu.FieldData{j}{rang})
                if iscell(valeur)
                    jeu.FieldData{j}{rang}{rangLocal} = char(valeur{min(k, numel(valeur))});
                else
                    jeu.FieldData{j}{rang}{rangLocal} = char(valeur);
                end
            else
                brut = double(valeur);
                if size(brut, 1) >= k
                    ligne = brut(k, :);
                else
                    ligne = brut(1, :);
                end
                jeu.FieldData{j}{rang} = matlibre_elargir(jeu.FieldData{j}{rang}, ...
                                                          numel(ligne));
                jeu.FieldData{j}{rang}(rangLocal, 1:numel(ligne)) = ligne;
            end
        end
    end
end
