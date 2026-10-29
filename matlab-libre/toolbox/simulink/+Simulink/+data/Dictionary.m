classdef Dictionary < handle
%DICTIONARY Un dictionnaire de données ouvert.
%   DD = SIMULINK.DATA.DICTIONARY.OPEN('donnees.sldd') le rend ;
%   SIMULINK.DATA.DICTIONARY.CREATE en crée un. Ses variables vivent par
%   sections : GETSECTION(DD,'Design Data') rend celle que lisent les
%   modèles liés au dictionnaire (réglage DataDictionary), 'Configurations'
%   et 'Other Data' les deux autres.
%
%   Propriétés, en lecture seule : Filepath, le chemin du fichier ;
%   DataSources, les dictionnaires qu'il référence, dont il voit les
%   entrées ; HasUnsavedChanges, vrai quand lui ou l'un d'eux porte des
%   changements non écrits ; NumberOfEntries, ses entrées et les leurs.
%
%   Méthodes : SAVECHANGES écrit les changements, DISCARDCHANGES les
%   défait ; CLOSE(DD) le ferme, refusé s'il porte des changements, que
%   CLOSE(DD,'-save') écrit et CLOSE(DD,'-discard') défait ;
%   ADDDATASOURCE et REMOVEDATASOURCE ajoutent et retirent une référence ;
%   IMPORTFROMBASEWORKSPACE y range des variables de l'espace de base ;
%   LISTENTRY en dresse la liste.
%
%   Le fichier est un fichier MAT propre à MatLibre : un .sldd de
%   Simulink ne s'y lit pas.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      dd.NumberOfEntries                    % 0
%      addEntry(getSection(dd, 'Design Data'), 'K', 2);
%      dd.HasUnsavedChanges                  % true
%      saveChanges(dd);
%      dd.HasUnsavedChanges                  % false
%      close(dd);
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY.OPEN, SIMULINK.DATA.DICTIONARY.SECTION,
%   SIMULINK.DATA.DICTIONARY.ENTRY.
    properties (SetAccess = private)
        Filepath = ''
    end
    properties (Dependent)
        DataSources
        HasUnsavedChanges
        NumberOfEntries
    end
    methods
        function dd = Dictionary(fichier)
            if nargin > 0
                dd.Filepath = matlibre_sl_dictionnaire('chemin', fichier);
            end
        end
        function v = get.DataSources(dd)
            v = matlibre_sl_dictionnaire('sources', dd.Filepath);
            v = v(:);
        end
        function v = get.HasUnsavedChanges(dd)
            v = matlibre_sl_dictionnaire('modifie', dd.Filepath);
        end
        function v = get.NumberOfEntries(dd)
            v = matlibre_sl_dictionnaire('nombre', dd.Filepath);
        end
        function s = getSection(dd, nom)
            if nargin < 2
                error('SLDD:sldd:InvalidSection', ...
                      ['GETSECTION(DD,NOM) : la section se nomme ''Design Data'', ' ...
                       '''Configurations'' ou ''Other Data''.']);
            end
            s = Simulink.data.dictionary.Section(dd.Filepath, nom);
        end
        function saveChanges(dd)
            matlibre_sl_dictionnaire('enregistrer', dd.Filepath);
        end
        function discardChanges(dd)
            matlibre_sl_dictionnaire('abandonner', dd.Filepath);
        end
        function close(dd, mode)
            if nargin < 2
                mode = '';
            end
            if ~isempty(mode) && ~any(strcmpi(char(mode), {'-save', '-discard'}))
                error('SLDD:sldd:InvalidCloseOption', ...
                      'CLOSE(DD,MODE) : MODE vaut ''-save'' ou ''-discard'' ; pas ''%s''.', ...
                      char(mode));
            end
            matlibre_sl_dictionnaire('fermer', dd.Filepath, mode);
        end
        function addDataSource(dd, source)
            matlibre_sl_dictionnaire('ajoutersource', dd.Filepath, source);
        end
        function removeDataSource(dd, source)
            matlibre_sl_dictionnaire('retirersource', dd.Filepath, source);
        end
        function [succes, echecs] = importFromBaseWorkspace(dd, varargin)
            % les variables nommées par 'varList', toutes sinon ; une
            % variable qui existe déjà se garde ('existingVarsAction'
            % 'none'), se remplace ('overwrite') ou fait l'erreur
            % ('error') ; 'clearWorkspaceVars' les retire de l'espace
            [liste, action, effacer] = optionsImport(varargin);
            if isempty(liste)
                liste = evalin('base', 'who').';
            end
            succes = {};
            echecs = struct('name', {}, 'message', {});
            for k = 1:numel(liste)
                nom = char(liste{k});
                if evalin('base', sprintf('exist(''%s'', ''var'')', nom)) ~= 1
                    echecs(end + 1) = struct('name', nom, 'message', ...
                        sprintf('L''espace de travail de base n''a pas de variable ''%s''.', ...
                                nom)); %#ok<AGROW>
                    continue
                end
                valeur = evalin('base', nom);
                section = 'Design Data';
                if isa(valeur, 'Simulink.ConfigSet')
                    section = 'Configurations';
                end
                if matlibre_sl_dictionnaire('existe', dd.Filepath, section, nom)
                    switch action
                        case 'none'
                            echecs(end + 1) = struct('name', nom, 'message', ...
                                sprintf(['Le dictionnaire porte deja une entree ''%s'' : ' ...
                                         'elle est gardee.'], nom)); %#ok<AGROW>
                            continue
                        case 'error'
                            error('SLDD:sldd:DuplicateEntry', ...
                                  ['Le dictionnaire ''%s'' porte deja une entree ''%s'' ' ...
                                   '(existingVarsAction vaut ''error'').'], dd.Filepath, nom);
                    end
                end
                matlibre_sl_dictionnaire('ecrire', dd.Filepath, section, nom, valeur);
                succes{end + 1} = nom; %#ok<AGROW>
                if effacer
                    evalin('base', sprintf('clear(''%s'')', nom));
                end
            end
            succes = succes(:);
            echecs = echecs(:);
        end
        function listEntry(dd)
            fprintf('  %-16s %-20s %-10s %s\n', 'Section', 'Name', 'Status', 'DataSource');
            for s = {'Design Data', 'Configurations', 'Other Data'}
                noms = matlibre_sl_dictionnaire('entrees', dd.Filepath, s{1});
                for k = 1:numel(noms)
                    [~, origine] = matlibre_sl_dictionnaire('lire', dd.Filepath, s{1}, noms{k});
                    [~, base, ext] = fileparts(origine);
                    fprintf('  %-16s %-20s %-10s %s\n', s{1}, noms{k}, ...
                            matlibre_sl_dictionnaire('statut', dd.Filepath, s{1}, noms{k}), ...
                            [base ext]);
                end
            end
        end
        function disp(dd)
            [~, base, ext] = fileparts(dd.Filepath);
            fprintf('  Simulink.data.Dictionary ''%s''\n', [base ext]);
            fprintf('    Filepath : %s\n', dd.Filepath);
            try
                sources = dd.DataSources;
                fprintf('    DataSources : {%s}\n', strjoin(sources.', ', '));
                fprintf('    HasUnsavedChanges : %d\n', dd.HasUnsavedChanges);
                fprintf('    NumberOfEntries : %d\n\n', dd.NumberOfEntries);
            catch
                fprintf('    (ferme)\n\n');
            end
        end
    end
end

function [liste, action, effacer] = optionsImport(args)
    liste = {};
    action = 'none';
    effacer = false;
    if mod(numel(args), 2) ~= 0
        error('SLDD:sldd:InvalidArguments', ...
              ['IMPORTFROMBASEWORKSPACE(DD,''varList'',{...},''existingVarsAction'',...) : ' ...
               'les options vont par paires.']);
    end
    for k = 1:2:numel(args)
        switch lower(char(args{k}))
            case 'varlist'
                liste = cellstr(args{k + 1});
            case 'existingvarsaction'
                action = lower(char(args{k + 1}));
                if ~any(strcmp(action, {'none', 'overwrite', 'error'}))
                    error('SLDD:sldd:InvalidArguments', ...
                          ['L''option existingVarsAction vaut ''none'', ''overwrite'' ou ' ...
                           '''error'' ; pas ''%s''.'], char(args{k + 1}));
                end
            case 'clearworkspacevars'
                effacer = logical(args{k + 1});
            otherwise
                error('SLDD:sldd:InvalidArguments', ...
                      ['IMPORTFROMBASEWORKSPACE ne connait pas l''option ''%s'' : varList, ' ...
                       'existingVarsAction, clearWorkspaceVars.'], char(args{k}));
        end
    end
end
