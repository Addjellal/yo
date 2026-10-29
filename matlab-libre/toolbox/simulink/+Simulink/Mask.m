classdef Mask < handle
%MASK Le masque d'un sous-système, manipulé par programme.
%   M = SIMULINK.MASK.CREATE(BLOC) masque le sous-système BLOC d'un modèle
%   chargé — son chemin ou sa poignée — et rend son masque ;
%   M = SIMULINK.MASK.GET(BLOC) rend celui qu'il porte, [] s'il n'en porte
%   pas. Le masque se lit et se règle sur le bloc lui-même : ce qu'on y
%   change vaut aussitôt.
%
%   Ses propriétés : Type (MaskType), Description, Help, Initialization
%   — le code qui s'exécute dans l'espace du masque avant la
%   simulation —, Display, SelfModifiable, BlockHandle, et Parameters, ses
%   paramètres, des SIMULINK.MASKPARAMETER.
%
%   Ses méthodes : P = ADDPARAMETER(M,'Name',N,'Prompt',T,'Type',G,
%   'Value',V,'Evaluate','on','TypeOptions',{...},'Visible','on',
%   'Enabled','on','Tunable','on','Callback','') ajoute un paramètre —
%   Type 'edit', 'checkbox', 'popup', 'radiobutton' ou 'combobox' — ;
%   GETPARAMETER(M,NOM), REMOVEPARAMETER(M,NOM), REMOVEALLPARAMETERS(M) ;
%   GETWORKSPACEVARIABLES(M), l'espace du masque, une structure Name,
%   Value par variable ; DELETE(M) démasque le bloc.
%
%   Exemple :
%      new_system('masque');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'masque/s');
%      m = Simulink.Mask.create('masque/s');
%      p = m.addParameter('Name', 'K', 'Prompt', 'Gain', 'Value', '3');
%      get_param('masque/s', 'K')               % '3'
%      p.Value = '5';
%      get_param('masque/s', 'MaskValues')      % {'5'}
%      bdclose('masque');
%
%   Voir aussi SIMULINK.MASKPARAMETER, SET_PARAM, GET_PARAM.
    properties (SetAccess = private)
        BlockHandle = -1
    end
    properties (Dependent)
        Type
        Description
        Help
        Initialization
        Display
        SelfModifiable
        Parameters
    end
    methods (Static)
        function m = create(bloc)
            chemin = matlibre_sl_memoire('chemin', bloc);
            b = blocMasquable(chemin);
            if matlibre_sl_masque('estmasque', b)
                error('Simulink:Masking:MaskAlreadyExists', ...
                      ['Le bloc ''%s'' porte deja un masque : SIMULINK.MASK.GET le rend, et ' ...
                       'DELETE(M) le retire.'], chemin);
            end
            matlibre_sl_masque('modifier', chemin, @(b) masquer(b));
            m = Simulink.Mask(chemin);
        end
        function m = get(bloc)
            chemin = matlibre_sl_memoire('chemin', bloc);
            b = matlibre_sl_memoire('bloc', chemin);
            m = [];
            if matlibre_sl_masque('estmasque', b)
                m = Simulink.Mask(chemin);
            end
        end
    end
    methods
        function m = Mask(chemin)
            m.BlockHandle = matlibre_sl_memoire('poignee', chemin);
        end
        function v = get.Type(m)
            v = lireReglage(m, 'MaskType');
        end
        function set.Type(m, v)
            poserReglage(m, 'MaskType', v);
        end
        function v = get.Description(m)
            v = lireReglage(m, 'MaskDescription');
        end
        function set.Description(m, v)
            poserReglage(m, 'MaskDescription', v);
        end
        function v = get.Help(m)
            v = lireReglage(m, 'MaskHelp');
        end
        function set.Help(m, v)
            poserReglage(m, 'MaskHelp', v);
        end
        function v = get.Initialization(m)
            v = lireReglage(m, 'MaskInitialization');
        end
        function set.Initialization(m, v)
            poserReglage(m, 'MaskInitialization', v);
        end
        function v = get.Display(m)
            v = lireReglage(m, 'MaskDisplay');
        end
        function set.Display(m, v)
            poserReglage(m, 'MaskDisplay', v);
        end
        function v = get.SelfModifiable(m)
            v = lireReglage(m, 'MaskSelfModifiable');
            if isempty(v)
                v = 'off';
            end
        end
        function set.SelfModifiable(m, v)
            if ~(ischar(v) || isstring(v)) || ~any(strcmpi(char(v), {'on', 'off'}))
                error('Simulink:Masking:InvalidPropertyValue', ...
                      'SelfModifiable vaut ''on'' ou ''off''.');
            end
            poserReglage(m, 'MaskSelfModifiable', lower(char(v)));
        end
        function P = get.Parameters(m)
            S = matlibre_sl_masque('parametres', blocDe(m));
            P = Simulink.MaskParameter.empty(1, 0);
            for k = 1:numel(S)
                P(k) = Simulink.MaskParameter(m.BlockHandle, S(k).Name);
            end
        end
        function p = addParameter(m, varargin)
            if mod(numel(varargin), 2) ~= 0
                error('Simulink:Masking:InvalidArguments', ...
                      'ADDPARAMETER prend des couples : ''Name'', N, ''Prompt'', T...');
            end
            nouveau = struct('Name', '', 'Prompt', '', 'Type', 'edit', 'TypeOptions', {{}}, ...
                             'Value', '', 'Evaluate', 'on', 'Tunable', 'on', ...
                             'Visible', 'on', 'Enabled', 'on', 'Callback', '');
            for k = 1:2:numel(varargin)
                champ = champCanonique(char(varargin{k}), fieldnames(nouveau));
                nouveau.(champ) = varargin{k + 1};
            end
            nouveau = verifierParametre(nouveau);
            S = matlibre_sl_masque('parametres', blocDe(m));
            if any(strcmp({S.Name}, nouveau.Name))
                error('Simulink:Masking:DuplicateParameterName', ...
                      'Le masque de ''%s'' porte deja un parametre nomme ''%s''.', ...
                      getfullname(m.BlockHandle), nouveau.Name);
            end
            if isempty(nouveau.Value)
                nouveau.Value = valeurParDefaut(nouveau);
            end
            S(end + 1) = nouveau;
            ecrireParametres(m, S);
            p = Simulink.MaskParameter(m.BlockHandle, nouveau.Name);
        end
        function p = getParameter(m, nom)
            S = matlibre_sl_masque('parametres', blocDe(m));
            p = [];
            if any(strcmp({S.Name}, char(nom)))
                p = Simulink.MaskParameter(m.BlockHandle, char(nom));
            end
        end
        function removeParameter(m, nom)
            S = matlibre_sl_masque('parametres', blocDe(m));
            k = find(strcmp({S.Name}, char(nom)), 1);
            if isempty(k)
                error('Simulink:Masking:ParameterNotFound', ...
                      'Le masque de ''%s'' n''a pas de parametre nomme ''%s''.', ...
                      getfullname(m.BlockHandle), char(nom));
            end
            S(k) = [];
            ecrireParametres(m, S);
        end
        function removeAllParameters(m)
            S = matlibre_sl_masque('parametres', blocDe(m));
            ecrireParametres(m, S([]));
        end
        function W = getWorkspaceVariables(m)
            chemin = getfullname(m.BlockHandle);
            espace = matlibre_sl_masque('espace', blocDe(m), struct(), chemin);
            noms = fieldnames(espace);
            W = struct('Name', noms(:).', 'Value', cell(1, numel(noms)));
            for k = 1:numel(noms)
                W(k).Value = espace.(noms{k});
            end
        end
        function delete(m)
            if isempty(m.BlockHandle) || m.BlockHandle == -1 || ...
               ~matlibre_sl_memoire('estpoignee', m.BlockHandle)
                return
            end
            try
                chemin = getfullname(m.BlockHandle);
            catch
                return
            end
            matlibre_sl_masque('modifier', chemin, @(b) demasquer(b));
        end
        function disp(m)
            S = matlibre_sl_masque('parametres', blocDe(m));
            fprintf('  Simulink.Mask de ''%s'' : %d parametre(s)', getfullname(m.BlockHandle), ...
                    numel(S));
            if ~isempty(S)
                fprintf(' — %s', strjoin({S.Name}, ', '));
            end
            fprintf('\n\n');
        end
    end
end

function b = blocMasquable(chemin)
    if ~strcmp(matlibre_sl_memoire('genre', chemin), 'bloc')
        error('Simulink:Masking:CannotMaskBlockDiagram', ...
              '''%s'' est un modele : on masque un sous-systeme.', chemin);
    end
    b = matlibre_sl_memoire('bloc', chemin);
    if ~strcmp(b.type, 'subsystem')
        error('Simulink:Masking:CannotMaskBlock', ...
              ['Le bloc ''%s'' (%s) n''est pas un sous-systeme : MatLibre ne masque que ' ...
               'les sous-systemes, dont les blocs lisent les parametres du masque.'], ...
              chemin, b.type);
    end
end

function b = masquer(b)
    b.parametres.Mask = 'on';
    b.parametres.MaskVariables = '';
    b.parametres.MaskValueString = '';
end

function b = demasquer(b)
    for nom = {'Mask', 'MaskVariables', 'MaskValueString', 'MaskPrompts', 'MaskStyles', ...
               'MaskVisibilities', 'MaskEnables', 'MaskTunableValues', 'MaskCallbacks', ...
               'MaskInitialization', 'MaskType', 'MaskDescription', 'MaskHelp', 'MaskDisplay', ...
               'MaskSelfModifiable'}
        if isfield(b.parametres, nom{1})
            b.parametres = rmfield(b.parametres, nom{1});
        end
    end
end

function b = blocDe(m)
    chemin = getfullname(m.BlockHandle);
    b = matlibre_sl_memoire('bloc', chemin);
    if ~matlibre_sl_masque('estmasque', b)
        error('Simulink:Masking:NoMask', 'Le bloc ''%s'' ne porte plus de masque.', chemin);
    end
end

function v = lireReglage(m, nom)
    b = blocDe(m);
    v = '';
    if isfield(b.parametres, nom)
        v = char(b.parametres.(nom));
    end
end

function poserReglage(m, nom, v)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v)
        error('Simulink:Masking:InvalidPropertyValue', 'Le reglage %s d''un masque est un texte.', ...
              nom);
    end
    blocDe(m);
    matlibre_sl_masque('modifier', getfullname(m.BlockHandle), @(b) poserChamp(b, nom, v));
end

function b = poserChamp(b, nom, v)
    b.parametres.(nom) = v;
end

function ecrireParametres(m, S)
    matlibre_sl_masque('modifier', getfullname(m.BlockHandle), ...
                       @(b) matlibre_sl_masque('ecrire', b, S));
end

function c = champCanonique(nom, champs)
    c = champs(strcmpi(champs, nom));
    if isempty(c)
        error('Simulink:Masking:InvalidArguments', ...
              'Un parametre de masque n''a pas de propriete ''%s'' ; il a %s.', nom, ...
              strjoin(champs.', ', '));
    end
    c = c{1};
end

function P = verifierParametre(P)
    for champ = {'Name', 'Prompt', 'Type', 'Value', 'Evaluate', 'Tunable', 'Visible', ...
                 'Enabled', 'Callback'}
        v = P.(champ{1});
        if isstring(v) && isscalar(v)
            v = char(v);
        end
        if ~ischar(v)
            error('Simulink:Masking:InvalidPropertyValue', ...
                  'La propriete %s d''un parametre de masque est un texte.', champ{1});
        end
        P.(champ{1}) = v;
    end
    if ~isvarname(P.Name) || strncmp(P.Name, 'matlibre__', 10)
        error('Simulink:Masking:InvalidParameterName', ...
              ['''%s'' n''est pas un nom de parametre de masque : c''est un identificateur ' ...
               'de MATLAB, une variable de l''espace du masque.'], P.Name);
    end
    P.Type = lower(P.Type);
    if ~any(strcmp(P.Type, {'edit', 'checkbox', 'popup', 'radiobutton', 'combobox'}))
        error('Simulink:Masking:InvalidParameterType', ...
              ['Le genre d''un parametre de masque est ''edit'', ''checkbox'', ''popup'', ' ...
               '''radiobutton'' ou ''combobox'' ; pas ''%s''.'], P.Type);
    end
    for champ = {'Evaluate', 'Tunable', 'Visible', 'Enabled'}
        if ~any(strcmpi(P.(champ{1}), {'on', 'off'}))
            error('Simulink:Masking:InvalidPropertyValue', ...
                  'La propriete %s d''un parametre de masque vaut ''on'' ou ''off''.', champ{1});
        end
        P.(champ{1}) = lower(P.(champ{1}));
    end
    if isstring(P.TypeOptions)
        P.TypeOptions = cellstr(P.TypeOptions);
    end
    if ~iscell(P.TypeOptions)
        error('Simulink:Masking:InvalidPropertyValue', ...
              'Les TypeOptions d''un parametre de masque sont une cellule de textes.');
    end
    P.TypeOptions = cellfun(@char, P.TypeOptions(:).', 'UniformOutput', false);
    if any(strcmp(P.Type, {'popup', 'radiobutton', 'combobox'})) && isempty(P.TypeOptions)
        error('Simulink:Masking:MissingTypeOptions', ...
              'Le parametre de masque ''%s'' est un menu : TypeOptions donne ses choix.', P.Name);
    end
    if ~isempty(P.Value) && strcmp(P.Type, 'checkbox') && ~any(strcmp(P.Value, {'on', 'off'}))
        error('Simulink:Masks:InvalidCheckboxValue', ...
              'Le parametre de masque ''%s'' est une case a cocher : il vaut ''on'' ou ''off''.', ...
              P.Name);
    end
    if ~isempty(P.Value) && any(strcmp(P.Type, {'popup', 'radiobutton'})) && ...
       ~any(strcmp(P.TypeOptions, P.Value))
        error('Simulink:Masks:InvalidPopupValue', ...
              'Le parametre de masque ''%s'' vaut l''un de ses choix : %s.', P.Name, ...
              strjoin(P.TypeOptions, ', '));
    end
end

function v = valeurParDefaut(P)
    switch P.Type
        case 'checkbox'
            v = 'off';
        case {'popup', 'radiobutton', 'combobox'}
            v = P.TypeOptions{1};
        otherwise
            v = '0';
    end
end
