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
%   travail de base.
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
    persistent espaces
    if isempty(espaces)
        espaces = containers.Map('KeyType', 'char', 'ValueType', 'any');
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
            varargout = {noms, valeurs};
        case 'executer'
            varargout{1} = executer(varargin{:});
        otherwise
            error('Simulink:Data:Action', 'Action inconnue : %s.', char(action));
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
