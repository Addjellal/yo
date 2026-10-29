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
%   Chaque paramètre a aussi son genre (MaskStyles : 'edit',
%   'checkbox', 'popup(a|b|c)', 'radiobutton(...)', 'combobox(...)'), sa
%   visibilité (MaskVisibilities), son activation (MaskEnables), son
%   réglage en cours de simulation (MaskTunableValues) et son rappel
%   (MaskCallbacks). Une case à cocher évaluée vaut 1 ou 0, un menu évalué
%   le rang du choix — tel quel, le texte du choix. Le code
%   d'initialisation (MaskInitialization) s'exécute dans l'espace du
%   masque, après ses variables : ce qu'il pose sert aux blocs du dedans.
%   S = MATLIBRE_SL_MASQUE('parametres',BLOC) rend les paramètres, un
%   élément par variable — Name, Prompt, Type, TypeOptions, Value,
%   Evaluate, Tunable, Visible, Enabled, Callback — ; BLOC =
%   MATLIBRE_SL_MASQUE('ecrire',BLOC,S) les écrit ;
%   MATLIBRE_SL_MASQUE('modifier',CHEMIN,F) applique F au bloc d'un modèle
%   chargé.
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
        case 'parametres'
            varargout{1} = parametres(varargin{1});
        case 'ecrire'
            varargout{1} = ecrire(varargin{:});
        case 'modifier'
            [chemin, f] = varargin{:};
            [parent, feuille] = matlibre_sl_memoire('decouper', chemin);
            matlibre_sl_memoire('appliquer', parent, @(s) modifierBloc(s, feuille, f));
        case 'estmasque'
            varargout{1} = masque(varargin{1});
        case 'ouvreespace'
            % un masque ouvre un espace s'il a des variables ou un code
            % d'initialisation
            b = varargin{1};
            varargout{1} = ~isempty(variables(b)) || ...
                (masque(b) && isfield(b.parametres, 'MaskInitialization') && ...
                 ~isempty(strtrim(char(b.parametres.MaskInitialization))));
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
    S = parametres(bloc);
    verifierValeur(S(rang), v, bloc.nom);
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
    S = parametres(bloc);
    for k = 1:numel(noms)
        texte = '';
        if details(k).rang <= numel(valeurs)
            texte = strtrim(valeurs{details(k).rang});
        end
        if ~details(k).evalue
            W.(noms{k}) = texte;
            continue
        end
        % une case évaluée vaut 1 ou 0, un menu évalué le rang de son choix
        switch S(k).Type
            case 'checkbox'
                W.(noms{k}) = double(strcmp(texte, 'on'));
                continue
            case {'popup', 'radiobutton'}
                rang = find(strcmp(S(k).TypeOptions, texte), 1);
                if isempty(rang)
                    error('Simulink:Masks:InvalidPopupValue', ...
                          ['Le parametre de masque ''%s'' du bloc ''%s'' vaut ''%s'', qui ' ...
                           'n''est aucun de ses choix : %s.'], noms{k}, chemin, texte, ...
                          strjoin(S(k).TypeOptions, ', '));
                end
                W.(noms{k}) = rang;
                continue
        end
        if isempty(texte)
            error('Simulink:Masks:EmptyValue', ...
                  'La variable de masque ''%s'' du bloc ''%s'' n''a pas de valeur.', ...
                  noms{k}, chemin);
        end
        W.(noms{k}) = evaluerBrut(texte, parent, chemin, noms{k});
    end
    code = '';
    if isfield(bloc.parametres, 'MaskInitialization')
        code = char(bloc.parametres.MaskInitialization);
    end
    if ~isempty(strtrim(code))
        W = initialiser(W, code, chemin);
    end
end

% Le code d'initialisation du masque, dans l'espace du masque : ce qu'il
% pose y reste.
function matlibre__W = initialiser(matlibre__W, matlibre__code, matlibre__chemin)
    matlibre__noms = fieldnames(matlibre__W);
    for matlibre__k = 1:numel(matlibre__noms)
        eval([matlibre__noms{matlibre__k} ' = matlibre__W.(matlibre__noms{matlibre__k});']);
    end
    try
        eval(matlibre__code);
    catch matlibre__err
        error('Simulink:Masks:InitializationError', ...
              'Erreur dans l''initialisation du masque de ''%s'' : %s', matlibre__chemin, ...
              matlibre__err.message);
    end
    for matlibre__v = who().'
        if ~strncmp(matlibre__v{1}, 'matlibre__', 10)
            matlibre__W.(matlibre__v{1}) = eval(matlibre__v{1});
        end
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
    % l'espace de travail du modèle passe avant celui de base
    % dans un modèle référencé, c'est son espace de travail qui compte, non
    % celui du modèle qui le référence
    matlibre__source = matlibre__chemin;
    if isfield(matlibre__W, 'matlibre__modele')
        matlibre__source = matlibre__W.matlibre__modele;
    end
    [matlibre__nomsM, matlibre__valeursM, matlibre__dico] = ...
        matlibre_sl_espace('variables', matlibre__source);
    matlibre__base = matlibre_sl_espace('base', matlibre__source);
    for matlibre__k = 1:numel(matlibre__ids)
        matlibre__id = matlibre__ids{matlibre__k};
        if any(strcmp(matlibre__noms, matlibre__id)) || strncmp(matlibre__id, 'matlibre__', 10)
            continue
        end
        matlibre__j = find(strcmp(matlibre__nomsM, matlibre__id), 1);
        if ~isempty(matlibre__j) && matlibre__dico(matlibre__j) && matlibre__base && ...
           evalin('base', sprintf('exist(''%s'', ''var'')', matlibre__id)) == 1
            error('Simulink:Data:DuplicateDefinition', ...
                  ['La variable ''%s'', que lit le parametre ''%s'' du bloc ''%s'', est definie ' ...
                   'a la fois dans le dictionnaire de donnees du modele et dans l''espace de ' ...
                   'travail de base : retirez-la de l''un des deux, ou posez ' ...
                   'EnableAccessToBaseWorkspace a ''off''.'], matlibre__id, matlibre__nom, ...
                  matlibre__chemin);
        end
        if ~isempty(matlibre__j)
            matlibre__x = matlibre__valeursM{matlibre__j};
            if isa(matlibre__x, 'Simulink.Parameter')
                matlibre__x = matlibre_sl_parametre('valeur', matlibre__x, matlibre__id, ...
                                                    matlibre__chemin, matlibre__nom);
            end
            eval([matlibre__id ' = matlibre__x;']);
        elseif matlibre__base && evalin('base', sprintf('exist(''%s'', ''var'')', matlibre__id)) == 1
            matlibre__x = evalin('base', matlibre__id);
            % un Simulink.Parameter y vaut sa valeur, comme hors masque
            if isa(matlibre__x, 'Simulink.Parameter')
                matlibre__x = matlibre_sl_parametre('valeur', matlibre__x, matlibre__id, ...
                                                    matlibre__chemin, matlibre__nom);
            end
            eval([matlibre__id ' = matlibre__x;']);
        end
    end
    try
        matlibre__v = eval(matlibre__texte);
    catch matlibre__err
        if ~matlibre__base
            error('Simulink:Data:BaseWorkspaceAccessDisabled', ...
                  ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', et cette expression ne ' ...
                   's''evalue ni dans l''espace du masque, ni dans celui du modele, ni dans son ' ...
                   'dictionnaire de donnees ; l''espace de travail de base lui est ferme ' ...
                   '(EnableAccessToBaseWorkspace vaut ''off'') : %s'], matlibre__nom, ...
                  matlibre__chemin, matlibre__texte, matlibre__err.message);
        end
        error('Simulink:Commands:ParametreNonEvalue', ...
              ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'', et cette expression ne ' ...
               's''evalue ni dans l''espace du masque ni dans l''espace de travail : %s'], ...
              matlibre__nom, matlibre__chemin, matlibre__texte, matlibre__err.message);
    end
end

% --- les paramètres du masque, un par variable ----------------------------------------

function S = parametres(bloc)
    S = struct('Name', {}, 'Prompt', {}, 'Type', {}, 'TypeOptions', {}, 'Value', {}, ...
               'Evaluate', {}, 'Tunable', {}, 'Visible', {}, 'Enabled', {}, 'Callback', {});
    [noms, details] = variables(bloc);
    valeurs = valeursDe(bloc);
    n = numel(noms);
    p = bloc.parametres;
    invites = liste(p, 'MaskPrompts', n, '');
    styles = liste(p, 'MaskStyles', n, 'edit');
    visibles = liste(p, 'MaskVisibilities', n, 'on');
    actifs = liste(p, 'MaskEnables', n, 'on');
    reglables = liste(p, 'MaskTunableValues', n, 'on');
    rappels = liste(p, 'MaskCallbacks', n, '');
    oui = {'off', 'on'};
    for k = 1:n
        [genre, choix] = lireStyle(styles{k});
        v = '';
        if details(k).rang <= numel(valeurs)
            v = valeurs{details(k).rang};
        end
        S(k) = struct('Name', noms{k}, 'Prompt', invites{k}, 'Type', genre, ...
                      'TypeOptions', {choix}, 'Value', v, ...
                      'Evaluate', oui{details(k).evalue + 1}, 'Tunable', reglables{k}, ...
                      'Visible', visibles{k}, 'Enabled', actifs{k}, 'Callback', rappels{k});
    end
end

% Un réglage du masque, une cellule par paramètre ; un texte « a|b » vaut
% aussi.
function c = liste(p, nom, n, defaut)
    c = repmat({defaut}, 1, n);
    if ~isfield(p, nom)
        return
    end
    v = p.(nom);
    if ischar(v) || isstring(v)
        v = strsplit(char(v), '|');
        if isempty(p.(nom))
            v = {};
        end
    end
    for k = 1:min(n, numel(v))
        c{k} = char(v{k});
    end
end

function [genre, choix] = lireStyle(style)
    choix = {};
    jetons = regexp(char(style), '^(\w+)\((.*)\)$', 'tokens', 'once');
    if isempty(jetons)
        genre = lower(strtrim(char(style)));
    else
        genre = lower(jetons{1});
        choix = strsplit(jetons{2}, '|');
    end
end

function bloc = ecrire(bloc, S)
    vars = '';
    valeurs = cell(1, numel(S));
    for k = 1:numel(S)
        signe = '@';
        if strcmp(S(k).Evaluate, 'off')
            signe = '&';
        end
        vars = [vars sprintf('%s=%s%d;', S(k).Name, signe, k)]; %#ok<AGROW>
        valeurs{k} = char(S(k).Value);
    end
    styles = cell(1, numel(S));
    for k = 1:numel(S)
        styles{k} = S(k).Type;
        if any(strcmp(S(k).Type, {'popup', 'radiobutton', 'combobox'}))
            styles{k} = sprintf('%s(%s)', S(k).Type, strjoin(S(k).TypeOptions, '|'));
        end
    end
    bloc.parametres.Mask = 'on';
    bloc.parametres.MaskVariables = vars;
    bloc.parametres.MaskValueString = strjoin(valeurs, '|');
    bloc.parametres.MaskPrompts = {S.Prompt};
    bloc.parametres.MaskStyles = styles;
    bloc.parametres.MaskVisibilities = {S.Visible};
    bloc.parametres.MaskEnables = {S.Enabled};
    bloc.parametres.MaskTunableValues = {S.Tunable};
    bloc.parametres.MaskCallbacks = {S.Callback};
end

% La valeur d'une case vaut 'on' ou 'off', celle d'un menu l'un de ses
% choix.
function verifierValeur(P, v, nomBloc)
    switch P.Type
        case 'checkbox'
            if ~any(strcmp(v, {'on', 'off'}))
                error('Simulink:Masks:InvalidCheckboxValue', ...
                      ['Le parametre de masque ''%s'' du bloc ''%s'' est une case a cocher : ' ...
                       'il vaut ''on'' ou ''off'', non ''%s''.'], P.Name, nomBloc, v);
            end
        case {'popup', 'radiobutton'}
            if ~any(strcmp(P.TypeOptions, v))
                error('Simulink:Masks:InvalidPopupValue', ...
                      ['Le parametre de masque ''%s'' du bloc ''%s'' vaut l''un de ses choix ' ...
                       '(%s), non ''%s''.'], P.Name, nomBloc, strjoin(P.TypeOptions, ', '), v);
            end
    end
end

function s = modifierBloc(s, nom, f)
    k = matlibre_sl_indice(s, nom);
    s.blocs{k} = f(s.blocs{k});
end
