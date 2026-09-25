function varargout = matlibre_sl_masque(action, varargin)
%MATLIBRE_SL_MASQUE Les masques des sous-systèmes : leurs paramètres, leur espace.
%   Un sous-système masqué montre des paramètres à lui, comme un bloc de
%   la bibliothèque : ses variables de masque. Les blocs qu'il contient
%   les nomment dans leurs propres paramètres — un gain réglé sur 'K' —,
%   et c'est la valeur du masque qui vaut, avant l'espace de travail.
%
%   Le masque se décrit comme dans Simulink, par les paramètres du bloc :
%   Mask ('on'), MaskVariables ('K=@1;nom=&2;' : la variable K prend la
%   première valeur, évaluée ; nom la deuxième, telle quelle),
%   MaskValueString (les valeurs, séparées par « | ») et MaskPrompts
%   (les libellés que la boîte de dialogue montre).
%
%   NOMS = MATLIBRE_SL_MASQUE('variables',BLOC) rend les noms des
%   variables du masque, cellule vide si le bloc n'est pas masqué.
%   V = MATLIBRE_SL_MASQUE('lire',BLOC,NOM) rend la valeur, en texte, de
%   la variable NOM ; BLOC = MATLIBRE_SL_MASQUE('poser',BLOC,NOM,V) la
%   change.
%   W = MATLIBRE_SL_MASQUE('espace',BLOC,PARENT,CHEMIN) évalue les
%   variables du masque dans l'espace PARENT — celui du masque qui
%   l'englobe, ou l'espace de travail — et rend la structure qui les
%   porte.
%   V = MATLIBRE_SL_MASQUE('evaluer',TEXTE,ESPACE,CHEMIN,NOM) évalue une
%   expression : les variables du masque d'abord, puis celles de l'espace
%   de travail.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      b = struct('type', 'subsystem', 'nom', 's', 'parametres', ...
%                 struct('Mask', 'on', 'MaskVariables', 'K=@1;tau=@2;', ...
%                        'MaskValueString', '2|0.5'));
%      matlibre_sl_masque('lire', b, 'tau')                  % '0.5'
%      W = matlibre_sl_masque('espace', b, struct(), 's');
%      matlibre_sl_masque('evaluer', 'K / tau', W, 's/g', 'Gain')   % 4
%
%   Voir aussi SET_PARAM, GET_PARAM, ADD_BLOCK.
    switch lower(char(action))
        case 'variables'
            [varargout{1}, varargout{2}] = variables(varargin{1});
        case 'lire'
            varargout{1} = lire(varargin{:});
        case 'poser'
            varargout{1} = poser(varargin{:});
        case 'espace'
            varargout{1} = espace(varargin{:});
        case 'evaluer'
            varargout{1} = evaluer(varargin{:});
        otherwise
            error('Simulink:Masque:Action', 'Action inconnue : %s.', char(action));
    end
end

function oui = masque(bloc)
    oui = isfield(bloc, 'parametres') && isfield(bloc.parametres, 'Mask') && ...
          strcmpi(char(bloc.parametres.Mask), 'on');
end

% Les noms, le rang de la valeur de chacun, et s'il s'évalue (@) ou se
% prend tel quel (&).
function [noms, details] = variables(bloc)
    noms = {};
    details = struct('rang', {}, 'evalue', {});
    if ~masque(bloc) || ~isfield(bloc.parametres, 'MaskVariables')
        return
    end
    for morceau = strsplit(char(bloc.parametres.MaskVariables), ';')
        texte = strtrim(morceau{1});
        if isempty(texte)
            continue
        end
        jetons = regexp(texte, '^([A-Za-z]\w*)\s*=\s*([@&])\s*(\d+)$', 'tokens', 'once');
        if isempty(jetons)
            error('Simulink:Masks:InvalidMaskVariables', ...
                  ['La variable de masque ''%s'' du bloc ''%s'' ne se lit pas : on ' ...
                   'ecrit « nom=@1; » pour une valeur evaluee, « nom=&1; » pour un ' ...
                   'texte.'], texte, bloc.nom);
        end
        noms{end + 1} = jetons{1}; %#ok<AGROW>
        details(end + 1) = struct('rang', str2double(jetons{3}), ...
                                  'evalue', jetons{2} == '@'); %#ok<AGROW>
    end
end

function valeurs = valeursDe(bloc)
    valeurs = {};
    if isfield(bloc.parametres, 'MaskValueString')
        valeurs = strsplit(char(bloc.parametres.MaskValueString), '|');
    end
end

function v = lire(bloc, nom)
    [noms, details] = variables(bloc);
    rang = find(strcmp(noms, nom), 1);
    if isempty(rang)
        error('Simulink:Masks:UnknownParameter', ...
              'Le masque du bloc ''%s'' n''a pas de variable ''%s''.', bloc.nom, nom);
    end
    valeurs = valeursDe(bloc);
    v = '';
    if details(rang).rang <= numel(valeurs)
        v = valeurs{details(rang).rang};
    end
end

function bloc = poser(bloc, nom, v)
    [noms, details] = variables(bloc);
    rang = find(strcmp(noms, nom), 1);
    if isempty(rang)
        error('Simulink:Masks:UnknownParameter', ...
              'Le masque du bloc ''%s'' n''a pas de variable ''%s''.', bloc.nom, nom);
    end
    if isnumeric(v) || islogical(v)
        if isscalar(v)
            v = num2str(double(v), 17);
        else
            v = mat2str(double(v), 17);
        end
    end
    v = char(v);
    if any(v == '|')
        error('Simulink:Masks:InvalidValue', ...
              'La valeur d''une variable de masque ne porte pas de « | », qui les separe.');
    end
    valeurs = valeursDe(bloc);
    valeurs(end + 1:details(rang).rang) = {''};
    valeurs{details(rang).rang} = v;
    bloc.parametres.MaskValueString = strjoin(valeurs, '|');
end

function W = espace(bloc, parent, chemin)
    if nargin < 2 || isempty(parent)
        parent = struct();
    end
    if nargin < 3
        chemin = bloc.nom;
    end
    W = parent;
    [noms, details] = variables(bloc);
    valeurs = valeursDe(bloc);
    for k = 1:numel(noms)
        texte = '';
        if details(k).rang <= numel(valeurs)
            texte = strtrim(valeurs{details(k).rang});
        end
        if ~details(k).evalue
            W.(noms{k}) = texte;
            continue
        end
        if isempty(texte)
            error('Simulink:Masks:EmptyValue', ...
                  'La variable de masque ''%s'' du bloc ''%s'' n''a pas de valeur.', ...
                  noms{k}, chemin);
        end
        W.(noms{k}) = evaluerBrut(texte, parent, chemin, noms{k});
    end
end

function v = evaluer(texte, W, chemin, nom)
    v = evaluerBrut(char(texte), W, chemin, nom);
    if ~isnumeric(v) && ~islogical(v)
        error('Simulink:Commands:ParametreNonNumerique', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', qui rend un %s : il ' ...
               'faut un nombre.'], nom, chemin, texte, class(v));
    end
    v = double(v);
end

% L'évaluation se fait ici, dans un espace à part : les variables du
% masque y sont posées, et celles de l'espace de travail qu'on nomme sans
% qu'un masque les porte y sont copiées. Les noms propres à la fonction
% commencent par matlibre__ : une variable de masque ne les heurte pas.
function matlibre__v = evaluerBrut(matlibre__texte, matlibre__W, matlibre__chemin, ...
                                   matlibre__nom)
    matlibre__noms = fieldnames(matlibre__W);
    for matlibre__k = 1:numel(matlibre__noms)
        eval([matlibre__noms{matlibre__k} ' = matlibre__W.(matlibre__noms{matlibre__k});']);
    end
    matlibre__ids = unique(regexp(matlibre__texte, '[A-Za-z]\w*', 'match'));
    for matlibre__k = 1:numel(matlibre__ids)
        matlibre__id = matlibre__ids{matlibre__k};
        if any(strcmp(matlibre__noms, matlibre__id)) || strncmp(matlibre__id, 'matlibre__', 10)
            continue
        end
        if evalin('base', sprintf('exist(''%s'', ''var'')', matlibre__id)) == 1
            eval([matlibre__id ' = evalin(''base'', matlibre__id);']);
        end
    end
    try
        matlibre__v = eval(matlibre__texte);
    catch matlibre__err
        error('Simulink:Commands:ParametreNonEvalue', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', et cette expression ne ' ...
               's''evalue ni dans l''espace du masque ni dans l''espace de travail : %s'], ...
              matlibre__nom, matlibre__chemin, matlibre__texte, matlibre__err.message);
    end
end
