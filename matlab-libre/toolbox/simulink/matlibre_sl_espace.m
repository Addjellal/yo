function varargout = matlibre_sl_espace(action, varargin)
%MATLIBRE_SL_ESPACE Les espaces de travail des modèles de la session.
%   HWS = MATLIBRE_SL_ESPACE('lire',NOM) rend le Simulink.ModelWorkspace
%   du modèle NOM, créé vide la première fois ; OUI =
%   MATLIBRE_SL_ESPACE('existe',NOM) dit s'il y en a un ;
%   MATLIBRE_SL_ESPACE('oublier',NOM) le retire — un modèle neuf part
%   d'un espace vide.
%
%   [NOMS,VALEURS] = MATLIBRE_SL_ESPACE('variables',CHEMIN) rend les
%   variables de l'espace du modèle dont CHEMIN — « modele/bloc » — est
%   un bloc : ce que les paramètres de ses blocs lisent avant l'espace de
%   travail de base. Viennent ensuite celles de la section 'Design Data'
%   du dictionnaire de données du modèle (DataDictionary), qui ne
%   remplacent pas une variable de même nom de l'espace du modèle.
%   [NOMS,VALEURS,DICO] = MATLIBRE_SL_ESPACE('variables',CHEMIN) dit en
%   plus lesquelles viennent du dictionnaire.
%
%   OUI = MATLIBRE_SL_ESPACE('base',CHEMIN) dit si les blocs du modèle
%   lisent l'espace de travail de base : non quand le modèle a un
%   dictionnaire et EnableAccessToBaseWorkspace à 'off'.
%   MATLIBRE_SL_ESPACE('lier',NOM,DICTIONNAIRE,ACCES), que fait la
%   compilation, retient ces deux réglages pour un modèle qui n'est pas
%   chargé ; ceux d'un modèle chargé se lisent sur lui.
%
%   D = MATLIBRE_SL_ESPACE('executer',D,CODE,NOM) exécute CODE dans un
%   espace où les champs de la structure D sont des variables, et rend
%   les variables qu'il y laisse.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      hws = matlibre_sl_espace('lire', 'essaiEspace');
%      assignin(hws, 'K', 2);
%      [noms, valeurs] = matlibre_sl_espace('variables', 'essaiEspace/gain');
%      matlibre_sl_espace('oublier', 'essaiEspace');
%
%   Voir aussi SIMULINK.MODELWORKSPACE, GET_PARAM.
    persistent espaces liens
    if isempty(espaces)
        espaces = containers.Map('KeyType', 'char', 'ValueType', 'any');
        % le dictionnaire de chaque modèle compilé, et l'accès à l'espace
        % de base : ce que vaut un modèle simulé sans être chargé
        liens = containers.Map('KeyType', 'char', 'ValueType', 'any');
    end
    switch action
        case 'lire'
            nom = char(varargin{1});
            if ~isKey(espaces, nom)
                espaces(nom) = Simulink.ModelWorkspace(nom);
            end
            varargout{1} = espaces(nom);
        case 'existe'
            varargout{1} = isKey(espaces, char(varargin{1}));
        case 'oublier'
            nom = char(varargin{1});
            if isKey(espaces, nom)
                remove(espaces, nom);
            end
        case 'variables'
            chemin = char(varargin{1});
            barre = find(chemin == '/', 1);
            nom = chemin;
            if ~isempty(barre)
                nom = chemin(1:barre - 1);
            end
            noms = {};
            valeurs = {};
            if isKey(espaces, nom)
                donnees = espaces(nom).Donnees;
                noms = fieldnames(donnees).';
                valeurs = cellfun(@(n) donnees.(n), noms, 'UniformOutput', false);
            end
            dico = false(size(noms));
            dictionnaire = lien(liens, nom);
            if ~isempty(dictionnaire)
                [nomsD, valeursD] = matlibre_sl_dictionnaire('variables', dictionnaire);
                garder = ~ismember(nomsD, noms);
                noms = [noms, nomsD(garder)];
                valeurs = [valeurs, valeursD(garder)];
                dico = [dico, true(1, nnz(garder))];
            end
            varargout = {noms, valeurs, dico};
        case 'base'
            chemin = char(varargin{1});
            barre = find(chemin == '/', 1);
            nom = chemin;
            if ~isempty(barre)
                nom = chemin(1:barre - 1);
            end
            [dictionnaire, acces] = lien(liens, nom);
            varargout{1} = isempty(dictionnaire) || ~strcmpi(acces, 'off');
        case 'lier'
            [nom, dictionnaire, acces] = varargin{1:3};
            nom = char(nom);
            dictionnaire = char(dictionnaire);
            if isempty(dictionnaire)
                if isKey(liens, nom)
                    remove(liens, nom);
                end
                return
            end
            try
                matlibre_sl_dictionnaire('variables', dictionnaire);
            catch err
                error('SLDD:sldd:DictionaryNotFound', ...
                      ['Le modele ''%s'' a pour dictionnaire de donnees ''%s'' ' ...
                       '(DataDictionary) : %s'], nom, dictionnaire, err.message);
            end
            liens(nom) = struct('dictionnaire', dictionnaire, 'acces', char(acces));
        case 'executer'
            varargout{1} = executer(varargin{:});
        otherwise
            error('Simulink:Data:Action', 'Action inconnue : %s.', char(action));
    end
end

% Le dictionnaire d'un modèle et son accès à l'espace de base : ceux du
% modèle chargé, sinon ceux de sa dernière compilation.
function [dictionnaire, acces] = lien(liens, nom)
    dictionnaire = '';
    acces = 'on';
    if matlibre_sl_ouverts('connu', nom)
        t = matlibre_sl_ouverts('lire', nom);
        if isfield(t, 'parametres') && isstruct(t.parametres)
            if isfield(t.parametres, 'DataDictionary')
                dictionnaire = char(t.parametres.DataDictionary);
            end
            if isfield(t.parametres, 'EnableAccessToBaseWorkspace')
                acces = char(t.parametres.EnableAccessToBaseWorkspace);
            end
        end
    elseif isKey(liens, nom)
        l = liens(nom);
        dictionnaire = l.dictionnaire;
        acces = l.acces;
    end
end

% Le code s'exécute dans un espace à part : les noms propres à la
% fonction commencent par matlibre__, qu'une variable de l'espace ne
% heurte pas.
function matlibre__D = executer(matlibre__D, matlibre__code, matlibre__nom)
    for matlibre__champ = fieldnames(matlibre__D).'
        eval([matlibre__champ{1} ' = matlibre__D.(matlibre__champ{1});']);
    end
    try
        eval([matlibre__code ';']);
    catch matlibre__err
        error('Simulink:Data:WorkspaceEvalError', ...
              'Le code execute dans l''espace de travail du modele ''%s'' echoue : %s', ...
              matlibre__nom, matlibre__err.message);
    end
    matlibre__D = struct();
    for matlibre__v = who().'
        if strncmp(matlibre__v{1}, 'matlibre__', 10)
            continue
        end
        matlibre__D.(matlibre__v{1}) = eval(matlibre__v{1});
    end
end
