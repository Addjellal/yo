classdef Entry < handle
%ENTRY Une entrée d'un dictionnaire de données.
%   E = GETENTRY(SECTION,NOM) la rend. GETVALUE(E) rend sa valeur,
%   SETVALUE(E,V) la change — comme E.Value —, DELETEENTRY(E) la retire,
%   DISCARDCHANGES(E) lui rend sa valeur écrite.
%
%   Propriétés : Name, son nom, que l'on peut changer ; Value ; et, en
%   lecture seule, DataSource, le fichier du dictionnaire qui la définit ;
%   Status, 'New', 'Modified' ou 'Unchanged' au regard de ce fichier ;
%   LastModified, l'instant du dernier changement.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      e = addEntry(getSection(dd, 'Design Data'), 'K', 1);
%      e.Status                              % 'New'
%      saveChanges(dd);
%      setValue(e, 7);
%      e.Status                              % 'Modified'
%      e.Value                               % 7
%      close(dd, '-discard');
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.SECTION, SIMULINK.DATA.DICTIONARY.
    properties (Dependent)
        Name
        Value
    end
    properties (Dependent, SetAccess = private)
        DataSource
        Status
        LastModified
    end
    properties (Hidden, SetAccess = private)
        Fichier = ''
        Section = ''
        Nom = ''
    end
    methods
        function e = Entry(fichier, section, nom)
            if nargin > 0
                e.Fichier = fichier;
                e.Section = section;
                e.Nom = nom;
            end
        end
        function v = get.Name(e)
            v = e.Nom;
        end
        function set.Name(e, nom)
            nom = char(nom);
            if strcmp(nom, e.Nom)
                return
            end
            if matlibre_sl_dictionnaire('existe', e.Fichier, e.Section, nom)
                error('SLDD:sldd:DuplicateEntry', ...
                      'La section ''%s'' porte deja une entree ''%s''.', e.Section, nom);
            end
            v = getValue(e);
            matlibre_sl_dictionnaire('ecrire', e.Fichier, e.Section, nom, v, true);
            matlibre_sl_dictionnaire('retirer', e.Fichier, e.Section, e.Nom);
            e.Nom = nom;
        end
        function v = get.Value(e)
            v = getValue(e);
        end
        function set.Value(e, v)
            setValue(e, v);
        end
        function v = get.DataSource(e)
            [~, base, ext] = fileparts(e.Fichier);
            v = [base ext];
        end
        function v = get.Status(e)
            v = matlibre_sl_dictionnaire('statut', e.Fichier, e.Section, e.Nom);
        end
        function v = get.LastModified(e)
            v = matlibre_sl_dictionnaire('date', e.Fichier, e.Section, e.Nom);
        end
        function v = getValue(e)
            v = matlibre_sl_dictionnaire('lire', e.Fichier, e.Section, e.Nom);
        end
        function setValue(e, v)
            if strcmp(e.Section, 'Configurations') && ~isa(v, 'Simulink.ConfigSet')
                error('SLDD:sldd:InvalidConfigurationEntry', ...
                      ['La section Configurations ne range que des jeux de configuration ' ...
                       '(Simulink.ConfigSet) ; pas %s.'], class(v));
            end
            if ~matlibre_sl_dictionnaire('existe', e.Fichier, e.Section, e.Nom)
                error('SLDD:sldd:EntryNotFound', ...
                      'L''entree ''%s'' a ete retiree de la section ''%s''.', e.Nom, e.Section);
            end
            matlibre_sl_dictionnaire('ecrire', e.Fichier, e.Section, e.Nom, v);
        end
        function deleteEntry(e)
            matlibre_sl_dictionnaire('retirer', e.Fichier, e.Section, e.Nom);
        end
        function discardChanges(e)
            matlibre_sl_dictionnaire('rendre', e.Fichier, e.Section, e.Nom);
        end
        function disp(e)
            for k = 1:numel(e)
                x = e(k);
                fprintf('  Simulink.data.dictionary.Entry ''%s''\n', x.Name);
                v = x.Value;
                if isnumeric(v) && numel(v) <= 6
                    texte = mat2str(v);
                else
                    texte = sprintf('[%s %s]', strjoin(arrayfun(@num2str, size(v), ...
                                    'UniformOutput', false), 'x'), class(v));
                end
                fprintf('    Value : %s\n    DataSource : %s\n    Status : %s\n', ...
                        texte, x.DataSource, x.Status);
                fprintf('    LastModified : %s\n\n', x.LastModified);
            end
        end
    end
end
