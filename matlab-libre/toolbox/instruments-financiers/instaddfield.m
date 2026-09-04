function jeu = instaddfield(varargin)
%INSTADDFIELD Ajoute des instruments d'un type quelconque.
%   JEU = INSTADDFIELD('FieldName',N,'Data',D,'Type',T) crée un type
%   d'instrument défini par ses seuls champs, sans que la boîte à outils
%   ait à le connaître. 'FieldClass' précise 'dble' ou 'char' par champ.
%
%   Exemple :
%      jeu = instaddfield('FieldName', {'Nominal','Echeance'}, ...
%                         'Data', {100, datenum('01-Jan-2030')}, ...
%                         'Type', 'Maison');
%
%   Voir aussi INSTADD, INSTSETFIELD, INSTGET.
    debut = 1;
    if ~isempty(varargin) && isstruct(varargin{1})
        jeu = varargin{1};
        debut = 2;
    else
        jeu = matlibre_jeu_vide();
    end
    noms = {};
    donnees = {};
    classes = {};
    type = 'Custom';
    k = debut;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        valeur = varargin{k+1};
        switch nom
            case 'fieldname'
                if ischar(valeur) || isstring(valeur)
                    noms = {char(valeur)};
                else
                    noms = valeur(:).';
                end
            case 'data'
                if iscell(valeur)
                    donnees = valeur(:).';
                else
                    donnees = {valeur};
                end
            case 'fieldclass'
                if ischar(valeur) || isstring(valeur)
                    classes = {char(valeur)};
                else
                    classes = valeur(:).';
                end
            case 'type'
                type = char(valeur);
            otherwise
                error('finstr:instaddfield:Option', ...
                      'Option inconnue : %s.', char(varargin{k}));
        end
        k = k + 2;
    end
    if isempty(noms)
        error('finstr:instaddfield:Champs', 'Il faut des noms de champs.');
    end
    if isempty(classes)
        classes = cell(1, numel(noms));
        for c = 1:numel(noms)
            valeur = donnees{min(c, numel(donnees))};
            if ischar(valeur) || (iscell(valeur) && ~isempty(valeur) && ischar(valeur{1}))
                classes{c} = 'char';
            else
                classes{c} = 'dble';
            end
        end
    elseif numel(classes) == 1
        classes = repmat(classes, 1, numel(noms));
    end
    jeu = matlibre_jeu_ajouter(jeu, type, noms, classes, donnees);
end
