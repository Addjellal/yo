function varargout = matlibre_sl_fiche(action, varargin)
%MATLIBRE_SL_FICHE La fiche d'un modèle : ses dates, ses auteurs, sa version.
%   Un modèle porte, comme dans Simulink, sa fiche : Created et Creator,
%   posés quand NEW_SYSTEM le crée ; LastModifiedDate et LastModifiedBy,
%   et ModelVersion qui avance d'un cran, posés par SAVE_SYSTEM ;
%   ModelVersionFormat, ModifiedByFormat, ModifiedDateFormat,
%   ModifiedComment, ModifiedHistory et ConfigurationManager ; FileName,
%   le fichier d'où il vient ou où il a été écrit ; Dirty, 'on' quand un
%   modèle chargé a changé depuis qu'on l'a chargé, créé ou écrit.
%   GET_PARAM et SET_PARAM la lisent et la règlent ; FileName ne se règle
%   pas.
%
%   N = MATLIBRE_SL_FICHE('noms') nomme ses réglages ; F =
%   MATLIBRE_SL_FICHE('nouvelle') en rend une neuve ; V =
%   MATLIBRE_SL_FICHE('lire',MODELE,NOM) en lit un ; M =
%   MATLIBRE_SL_FICHE('poser',MODELE,NOM,VALEUR) en pose un ; M =
%   MATLIBRE_SL_FICHE('enregistrer',MODELE,FICHIER) la met à jour pour un
%   enregistrement, M = MATLIBRE_SL_FICHE('charger',MODELE,FICHIER) pour
%   un chargement.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      f = matlibre_sl_fiche('nouvelle');
%      f.ModelVersion                           % '1.0'
%      matlibre_sl_fiche('version', '1.4')      % '1.5'
%
%   Voir aussi GET_PARAM, SET_PARAM, SAVE_SYSTEM, LOAD_SYSTEM.
    switch lower(char(action))
        case 'noms'
            varargout{1} = noms();
        case 'nouvelle'
            varargout{1} = nouvelle();
        case 'lire'
            varargout{1} = lire(varargin{:});
        case 'poser'
            varargout{1} = poser(varargin{:});
        case 'enregistrer'
            varargout{1} = enregistrer(varargin{:});
        case 'charger'
            m = varargin{1};
            f = ficheDe(m);
            f.FileName = absolu(char(varargin{2}));
            m.fiche = f;
            varargout{1} = m;
        case 'version'
            varargout{1} = versionSuivante(char(varargin{1}));
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

function n = noms()
    n = {'Created', 'Creator', 'LastModifiedBy', 'LastModifiedDate', 'ModelVersion', ...
         'ModelVersionFormat', 'ModifiedByFormat', 'ModifiedDateFormat', 'ModifiedComment', ...
         'ModifiedHistory', 'ConfigurationManager', 'FileName', 'Dirty'};
end

function f = nouvelle()
    maintenant = horodatage();
    qui = utilisateur();
    f = struct('Created', maintenant, 'Creator', qui, 'LastModifiedBy', qui, ...
               'LastModifiedDate', maintenant, 'ModelVersion', '1.0', ...
               'ModelVersionFormat', '1.%<AutoIncrement:0>', 'ModifiedByFormat', '%<Auto>', ...
               'ModifiedDateFormat', '%<Auto>', 'ModifiedComment', '', 'ModifiedHistory', '', ...
               'ConfigurationManager', 'None', 'FileName', '');
end

% La fiche d'un modèle ; celle d'un modèle bâti avant qu'il n'en porte
% est vide, ses dates et ses auteurs inconnus.
function f = ficheDe(m)
    f = nouvelle();
    for champ = {'Created', 'Creator', 'LastModifiedBy', 'LastModifiedDate'}
        f.(champ{1}) = '';
    end
    if isfield(m, 'fiche') && isstruct(m.fiche)
        for champ = fieldnames(m.fiche).'
            f.(champ{1}) = m.fiche.(champ{1});
        end
    end
end

function n = canonique(nom)
    tous = noms();
    n = tous(strcmpi(tous, char(nom)));
    if isempty(n)
        n = '';
    else
        n = n{1};
    end
end

function v = lire(m, nom)
    nom = canonique(nom);
    if strcmp(nom, 'Dirty')
        v = 'off';
        if isfield(m, 'nom') && matlibre_sl_ouverts('connu', char(m.nom)) && ...
           ~isequal(matlibre_sl_ouverts('lire', char(m.nom)), ...
                    matlibre_sl_ouverts('reference', char(m.nom)))
            v = 'on';
        end
        return
    end
    f = ficheDe(m);
    v = f.(nom);
end

function m = poser(m, nom, valeur)
    nom = canonique(nom);
    if strcmp(nom, 'FileName')
        error('Simulink:Commands:SetParamReadOnly', ...
              ['FileName dit le fichier d''ou vient le modele ''%s'' : il se lit, et ' ...
               'SAVE_SYSTEM le change en ecrivant ailleurs.'], char(m.nom));
    end
    if strcmp(nom, 'Dirty')
        valeur = choixOuiNon(valeur);
        % 'off' : le modèle chargé tel qu'il est devient la référence
        if isfield(m, 'nom') && matlibre_sl_ouverts('connu', char(m.nom)) && strcmp(valeur, 'off')
            matlibre_sl_ouverts('poserreference', char(m.nom), m);
        elseif isfield(m, 'nom') && matlibre_sl_ouverts('connu', char(m.nom))
            matlibre_sl_ouverts('poserreference', char(m.nom), []);
        end
        return
    end
    if isstring(valeur) && isscalar(valeur)
        valeur = char(valeur);
    end
    if ~ischar(valeur)
        error('Simulink:Commands:SetParamInvalidArgumentType', ...
              'Le reglage %s du modele ''%s'' est un texte.', nom, char(m.nom));
    end
    f = ficheDe(m);
    f.(nom) = valeur;
    m.fiche = f;
end

function v = choixOuiNon(v)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v) || ~any(strcmpi(v, {'on', 'off'}))
        error('Simulink:Commands:SetParamInvalidArgumentValue', 'Dirty vaut ''on'' ou ''off''.');
    end
    v = lower(v);
end

% Un enregistrement : la version avance d'un cran, la date et l'auteur
% de la modification se posent, et le fichier devient celui du modèle.
function m = enregistrer(m, fichier)
    f = ficheDe(m);
    f.ModelVersion = versionSuivante(f.ModelVersion);
    jetons = regexp(f.ModelVersionFormat, '%<AutoIncrement:(\d+)>', 'tokens', 'once');
    if ~isempty(jetons)
        f.ModelVersionFormat = regexprep(f.ModelVersionFormat, '%<AutoIncrement:\d+>', ...
                                         sprintf('%%<AutoIncrement:%d>', ...
                                                 str2double(jetons{1}) + 1));
    end
    f.LastModifiedDate = horodatage();
    f.LastModifiedBy = utilisateur();
    f.FileName = absolu(fichier);
    m.fiche = f;
end

% '1.4' devient '1.5' ; une version qui ne finit pas par un nombre en
% gagne un.
function v = versionSuivante(v)
    jetons = regexp(v, '^(.*?)(\d+)$', 'tokens', 'once');
    if isempty(jetons)
        v = [v '.1'];
    else
        v = sprintf('%s%d', jetons{1}, str2double(jetons{2}) + 1);
    end
end

function t = horodatage()
    t = datestr(now, 'ddd mmm dd HH:MM:SS yyyy');
end

function qui = utilisateur()
    qui = getenv('USER');
    if isempty(qui)
        qui = getenv('USERNAME');
    end
    if isempty(qui)
        qui = 'matlibre';
    end
end

function c = absolu(fichier)
    c = fichier;
    if isempty(c)
        return
    end
    if ~(c(1) == '/' || (numel(c) > 1 && c(2) == ':'))
        c = fullfile(pwd(), c);
    end
end
