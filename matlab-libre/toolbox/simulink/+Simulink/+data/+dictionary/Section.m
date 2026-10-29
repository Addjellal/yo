classdef Section < handle
%SECTION Une section d'un dictionnaire de données.
%   S = GETSECTION(DD,'Design Data') la rend. Ses entrées, celles des
%   dictionnaires que DD référence comprises :
%      E = ADDENTRY(S,NOM,VALEUR)   en ajoute une, refusée si elle existe
%      E = GETENTRY(S,NOM)          la rend, un Simulink.data.dictionary.Entry
%      DELETEENTRY(S,NOM)           la retire
%      OUI = EXIST(S,NOM)           dit si elle existe
%      V = EVALIN(S,EXPRESSION)     évalue avec ses entrées pour variables ;
%                                   EVALIN(S,'K = 5') change ou crée K
%      ASSIGNIN(S,NOM,VALEUR)       la change, ou la crée
%      E = FIND(S,'Name',NOM,...)   les entrées dont les propriétés valent
%                                   ces valeurs ; '-regexp' fait des
%                                   valeurs des motifs
%      IMPORTFROMFILE(S,FICHIER)    y range les variables d'un fichier MAT
%      EXPORTTOFILE(S,FICHIER)      écrit ses entrées dans un fichier MAT
%
%   Propriétés : Name, le nom de la section, en lecture seule.
%
%   Exemple :
%      f = [tempname() '.sldd'];
%      dd = Simulink.data.dictionary.create(f);
%      s = getSection(dd, 'Design Data');
%      addEntry(s, 'K', 4);
%      evalin(s, 'K * 2')                    % 8
%      assignin(s, 'K', 5);
%      getValue(getEntry(s, 'K'))            % 5
%      close(dd, '-discard');
%      delete(f);
%
%   Voir aussi SIMULINK.DATA.DICTIONARY, SIMULINK.DATA.DICTIONARY.ENTRY.
    properties (SetAccess = private)
        Name = ''
    end
    properties (Hidden, SetAccess = private)
        Fichier = ''
    end
    methods
        function s = Section(fichier, nom)
            if nargin > 0
                nom = char(nom);
                if ~any(strcmp(nom, {'Design Data', 'Configurations', 'Other Data'}))
                    error('SLDD:sldd:InvalidSection', ...
                          ['''%s'' n''est pas une section de dictionnaire : ''Design Data'', ' ...
                           '''Configurations'' ou ''Other Data''.'], nom);
                end
                % un dictionnaire fermé ne rend pas de section
                matlibre_sl_dictionnaire('modifie', fichier);
                s.Fichier = fichier;
                s.Name = nom;
            end
        end
        function e = addEntry(s, nom, valeur)
            if nargin < 3
                error('SLDD:sldd:InvalidArguments', 'ADDENTRY(S,NOM,VALEUR) : il faut une valeur.');
            end
            if strcmp(s.Name, 'Configurations') && ~isa(valeur, 'Simulink.ConfigSet')
                error('SLDD:sldd:InvalidConfigurationEntry', ...
                      ['La section Configurations ne range que des jeux de configuration ' ...
                       '(Simulink.ConfigSet) ; pas %s.'], class(valeur));
            end
            matlibre_sl_dictionnaire('ecrire', s.Fichier, s.Name, nom, valeur, true);
            e = Simulink.data.dictionary.Entry(s.Fichier, s.Name, char(nom));
        end
        function e = getEntry(s, nom)
            nom = char(nom);
            [~, origine] = matlibre_sl_dictionnaire('lire', s.Fichier, s.Name, nom);
            e = Simulink.data.dictionary.Entry(origine, s.Name, nom);
        end
        function deleteEntry(s, nom)
            matlibre_sl_dictionnaire('retirer', s.Fichier, s.Name, nom);
        end
        function oui = exist(s, nom)
            oui = matlibre_sl_dictionnaire('existe', s.Fichier, s.Name, nom);
        end
        function assignin(s, nom, valeur)
            matlibre_sl_dictionnaire('ecrire', s.Fichier, s.Name, nom, valeur);
        end
        function varargout = evalin(s, expression)
            expression = char(expression);
            noms = matlibre_sl_dictionnaire('entrees', s.Fichier, s.Name);
            D = struct();
            for k = 1:numel(noms)
                D.(noms{k}) = matlibre_sl_dictionnaire('lire', s.Fichier, s.Name, noms{k});
            end
            if nargout > 0
                try
                    apres = matlibre_sl_espace('executer', D, ...
                                               ['matlibreResultat__ = ' expression], s.Name);
                    varargout{1} = apres.matlibreResultat__;
                catch err
                    error('SLDD:sldd:EvalError', ...
                          ['L''expression ''%s'' ne s''evalue pas dans la section ''%s'' du ' ...
                           'dictionnaire : %s'], expression, s.Name, err.message);
                end
                return
            end
            try
                apres = matlibre_sl_espace('executer', D, expression, s.Name);
            catch err
                error('SLDD:sldd:EvalError', ...
                      ['Le code ''%s'' ne s''execute pas dans la section ''%s'' du ' ...
                       'dictionnaire : %s'], expression, s.Name, err.message);
            end
            for champ = fieldnames(apres).'
                n = champ{1};
                if ~isfield(D, n) || ~isequal(D.(n), apres.(n))
                    matlibre_sl_dictionnaire('ecrire', s.Fichier, s.Name, n, apres.(n));
                end
            end
            for k = 1:numel(noms)
                if ~isfield(apres, noms{k})
                    matlibre_sl_dictionnaire('retirer', s.Fichier, s.Name, noms{k});
                end
            end
        end
        function trouvees = find(s, varargin)
            motif = false;
            if ~isempty(varargin) && strcmpi(char(varargin{1}), '-regexp')
                motif = true;
                varargin(1) = [];
            end
            if mod(numel(varargin), 2) ~= 0
                error('SLDD:sldd:InvalidArguments', ...
                      'FIND(S,''Propriete'',VALEUR,...) : les criteres vont par paires.');
            end
            trouvees = Simulink.data.dictionary.Entry.empty(1, 0);
            noms = matlibre_sl_dictionnaire('entrees', s.Fichier, s.Name);
            for k = 1:numel(noms)
                e = getEntry(s, noms{k});
                garder = true;
                for q = 1:2:numel(varargin)
                    propriete = char(varargin{q});
                    if ~any(strcmp(propriete, {'Name', 'Value', 'DataSource', 'Status', ...
                                               'LastModified'}))
                        error('SLDD:sldd:InvalidArguments', ...
                              ['Une entree n''a pas de propriete ''%s'' : Name, Value, ' ...
                               'DataSource, Status, LastModified.'], propriete);
                    end
                    v = e.(propriete);
                    attendu = varargin{q + 1};
                    if motif && ischar(v)
                        garder = garder && ~isempty(regexp(v, char(attendu), 'once'));
                    else
                        garder = garder && isequal(v, attendu);
                    end
                end
                if garder
                    trouvees(end + 1) = e; %#ok<AGROW>
                end
            end
        end
        function importFromFile(s, fichier, varargin)
            action = 'none';
            for k = 1:2:numel(varargin)
                if strcmpi(char(varargin{k}), 'existingVarsAction')
                    action = lower(char(varargin{k + 1}));
                end
            end
            try
                contenu = load(char(fichier));
            catch err
                error('SLDD:sldd:ImportFailed', ...
                      'Le fichier ''%s'' ne se lit pas : %s', char(fichier), err.message);
            end
            for champ = fieldnames(contenu).'
                n = champ{1};
                if exist(s, n)
                    switch action
                        case 'none'
                            continue
                        case 'error'
                            error('SLDD:sldd:DuplicateEntry', ...
                                  ['La section ''%s'' porte deja une entree ''%s'' ' ...
                                   '(existingVarsAction vaut ''error'').'], s.Name, n);
                    end
                end
                matlibre_sl_dictionnaire('ecrire', s.Fichier, s.Name, n, contenu.(n));
            end
        end
        function exportToFile(s, fichier)
            noms = matlibre_sl_dictionnaire('entrees', s.Fichier, s.Name);
            contenu = struct();
            for k = 1:numel(noms)
                contenu.(noms{k}) = matlibre_sl_dictionnaire('lire', s.Fichier, s.Name, noms{k});
            end
            save(char(fichier), '-struct', 'contenu');
        end
        function disp(s)
            [~, base, ext] = fileparts(s.Fichier);
            fprintf('  Simulink.data.dictionary.Section ''%s'' de %s\n', s.Name, [base ext]);
            try
                noms = matlibre_sl_dictionnaire('entrees', s.Fichier, s.Name);
                fprintf('    %d entrees : %s\n\n', numel(noms), strjoin(noms, ', '));
            catch
                fprintf('    (dictionnaire ferme)\n\n');
            end
        end
    end
end
