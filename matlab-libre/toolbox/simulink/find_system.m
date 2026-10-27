function noms = find_system(modele, varargin)
%FIND_SYSTEM Les blocs d'un modèle, éventuellement filtrés.
%   NOMS = FIND_SYSTEM(MODELE) rend le nom de tous les blocs.
%   NOMS = FIND_SYSTEM(MODELE,'BlockType',TYPE) ne garde que ceux du type
%   donné. D'autres couples nom-valeur filtrent sur les paramètres.
%
%   Le filtre est conjonctif : un bloc n'est gardé que s'il répond à tous
%   les critères. Sans critère, tous les blocs sortent.
%
%   La comparaison est textuelle, y compris sur les valeurs numériques :
%   un gain de 2 se retrouve aussi bien par 2 que par '2', puisque c'est
%   ainsi qu'ADD_BLOCK accepte de l'écrire.
%
%   CHEMINS = FIND_SYSTEM(SYSTEME,'Option',VALEUR,...,'Param',VALEUR,...)
%   est la forme de Simulink, sur les modèles chargés : SYSTEME est le
%   chemin d'un modèle ou d'un sous-système, une poignée, une cellule de
%   chemins, ou rien — tous les modèles chargés. Elle rend la colonne des
%   chemins complets — le système lui-même d'abord, puis chaque bloc et,
%   aussitôt après un sous-système, ce qu'il contient — qui répondent à
%   tous les critères. Les critères portent sur les paramètres des blocs,
%   leurs valeurs par défaut comprises, et sur Name, Parent, Type
%   ('block', 'block_diagram') et BlockType (le type de Simulink, 'Gain',
%   ou celui de MatLibre). Les options :
%      SearchDepth      la profondeur, 0 pour le système seul (toutes)
%      LookUnderMasks   'graphical' (sous un masque sans paramètre),
%                       'none', 'functional' ou 'all'
%      FollowLinks      'off' : ne descend pas dans un bloc lié à une
%                       bibliothèque ; 'on' : y descend
%      FindAll          'on' : rend les poignées au lieu des chemins
%      CaseSensitive    'on' ; 'off' compare sans égard à la casse
%      RegExp           'on' : chaque valeur cherchée est une expression
%                       régulière
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'gain', 'g1', 'Gain', 2);
%      m = add_block(m, 'gain', 'g2', 'Gain', 3);
%      m = add_block(m, 'constant', 'c', 'Value', 1);
%      numel(find_system(m))                        % 3
%      numel(find_system(m, 'BlockType', 'gain'))   % 2
%      find_system(m, 'Gain', 3)                    % {'g2'}
%
%   Voir aussi GET_PARAM, SET_PARAM, ADD_BLOCK, NEW_SYSTEM.
    if nargin == 0 || ~isstruct(modele)
        arguments_ = varargin;
        if nargin > 0
            arguments_ = [{modele}, varargin];
        end
        noms = chercherParNom(arguments_);
        return
    end
    noms = {};
    for i = 1:numel(modele.blocs)
        bloc = modele.blocs{i};
        garde = true;
        for k = 1:2:numel(varargin) - 1
            critere = char(varargin{k});
            attendu = varargin{k + 1};
            if strcmpi(critere, 'BlockType') || strcmpi(critere, 'Type')
                obtenu = bloc.type;
            elseif strcmpi(critere, 'Name')
                obtenu = bloc.nom;
            elseif isfield(bloc.parametres, critere)
                obtenu = bloc.parametres.(critere);
            else
                garde = false;
                break
            end
            if ~matlibre_meme_valeur(obtenu, attendu)
                garde = false;
                break
            end
        end
        if garde
            noms{end + 1} = bloc.nom;   %#ok<AGROW>
        end
    end
end

% --- la forme de Simulink --------------------------------------------------------

function trouves = chercherParNom(args)
    if ~isempty(args) && (mod(numel(args), 2) == 1 || iscell(args{1}) || isnumeric(args{1}) || ...
                          estCharge(args{1}))
        x = args{1};
        args = args(2:end);
        if iscell(x)
            departs = x(:).';
        elseif isnumeric(x)
            departs = num2cell(x(:).');
        else
            departs = {x};
        end
    else
        departs = matlibre_sl_ouverts('noms');
    end
    if mod(numel(args), 2) ~= 0
        error('Simulink:Commands:FindSystemArguments', ...
              'Les options et les criteres de FIND_SYSTEM vont par paires : un nom, une valeur.');
    end
    o = struct('profondeur', Inf, 'masques', 'graphical', 'liens', false, 'tous', false, ...
               'casse', true, 'expression', false);
    criteres = {};
    for k = 1:2:numel(args)
        nom = char(args{k});
        v = args{k + 1};
        switch lower(nom)
            case 'searchdepth'
                if ischar(v) || isstring(v)
                    v = str2double(v);
                end
                if ~(isnumeric(v) && isscalar(v) && v >= 0 && v == round(v))
                    error('Simulink:Commands:FindSystemInvalidOption', ...
                          'SearchDepth est un entier positif ou nul.');
                end
                o.profondeur = double(v);
            case 'lookundermasks'
                o.masques = choix(v, nom, {'none', 'graphical', 'functional', 'all'});
            case 'followlinks'
                o.liens = strcmp(choix(v, nom, {'on', 'off'}), 'on');
            case 'findall'
                o.tous = strcmp(choix(v, nom, {'on', 'off'}), 'on');
            case 'casesensitive'
                o.casse = strcmp(choix(v, nom, {'on', 'off'}), 'on');
            case 'regexp'
                o.expression = strcmp(choix(v, nom, {'on', 'off'}), 'on');
            case {'includecommented', 'loadfullyifneeded', 'variants', 'matchfilter'}
            otherwise
                criteres(end + 1:end + 2) = {nom, v}; %#ok<AGROW>
        end
    end
    trouves = {};
    for d = 1:numel(departs)
        chemin = matlibre_sl_memoire('chemin', departs{d});
        bloc = [];
        if strcmp(matlibre_sl_memoire('genre', chemin), 'bloc')
            bloc = matlibre_sl_memoire('bloc', chemin);
        end
        trouves = visiter(trouves, chemin, bloc, 0, o, criteres);
    end
    trouves = trouves(:);
    if o.tous
        h = zeros(numel(trouves), 1);
        for k = 1:numel(trouves)
            h(k) = matlibre_sl_memoire('poignee', trouves{k});
        end
        trouves = h;
    end
end

function trouves = visiter(trouves, chemin, bloc, profondeur, o, criteres)
    if repond(chemin, bloc, o, criteres)
        trouves{end + 1} = chemin;
    end
    if profondeur >= o.profondeur
        return
    end
    if isempty(bloc)
        systeme = matlibre_sl_memoire('systeme', chemin);
    else
        if ~strcmp(bloc.type, 'subsystem') || ~descendre(bloc, o)
            return
        end
        systeme = matlibre_sl_memoire('systeme', chemin);
    end
    for k = 1:numel(systeme.blocs)
        enfant = systeme.blocs{k};
        trouves = visiter(trouves, matlibre_sl_memoire('joindre', chemin, char(enfant.nom)), ...
                          enfant, profondeur + 1, o, criteres);
    end
end

% Un sous-système masqué ou lié ne s'ouvre qu'avec les options qui le
% permettent.
function oui = descendre(bloc, o)
    oui = true;
    if isfield(bloc, 'reference') && ~isempty(bloc.reference) && ~o.liens
        oui = false;
        return
    end
    masque = isfield(bloc.parametres, 'Mask') && strcmpi(char(bloc.parametres.Mask), 'on');
    variables = ~isempty(matlibre_sl_masque('variables', bloc));
    switch o.masques
        case 'none'
            oui = ~(masque || variables);
        case 'graphical'
            oui = ~variables;
    end
end

function oui = repond(chemin, bloc, o, criteres)
    oui = true;
    for k = 1:2:numel(criteres)
        nom = criteres{k};
        attendu = criteres{k + 1};
        if strcmpi(nom, 'BlockType')
            if isempty(bloc)
                oui = false;
                return
            end
            entree = matlibre_sl_catalogue('type', bloc.type);
            oui = egal(entree.simulink, attendu, o) || egal(entree.type, attendu, setfield(o, 'casse', false)); %#ok<SFLD>
        else
            try
                obtenu = get_param(chemin, nom);
            catch
                oui = false;
                return
            end
            oui = egal(obtenu, attendu, o);
        end
        if ~oui
            return
        end
    end
end

function oui = egal(obtenu, attendu, o)
    if o.expression
        texte = enTexte(obtenu);
        motif = enTexte(attendu);
        if o.casse
            oui = ~isempty(regexp(texte, motif, 'once'));
        else
            oui = ~isempty(regexpi(texte, motif, 'once'));
        end
        return
    end
    if ~o.casse && (ischar(obtenu) || isstring(obtenu)) && (ischar(attendu) || isstring(attendu))
        oui = strcmpi(char(obtenu), char(attendu));
        return
    end
    oui = matlibre_meme_valeur(obtenu, attendu);
end

function t = enTexte(v)
    if ischar(v)
        t = v;
    elseif isstring(v) && isscalar(v)
        t = char(v);
    elseif isnumeric(v) || islogical(v)
        t = mat2str(double(v));
    else
        t = '';
    end
end

function v = choix(v, nom, admis)
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v) || ~any(strcmpi(v, admis))
        error('Simulink:Commands:FindSystemInvalidOption', ...
              'L''option %s de FIND_SYSTEM vaut %s.', nom, strjoin(strcat('''', admis, ''''), ', '));
    end
    v = lower(v);
end

% Un texte qui désigne un modèle chargé est le système où chercher, et non
% le nom d'un critère.
function oui = estCharge(x)
    oui = false;
    if isstring(x) && isscalar(x)
        x = char(x);
    end
    if ischar(x) && ~isempty(x)
        morceaux = matlibre_sl_memoire('morceaux', x);
        oui = matlibre_sl_ouverts('connu', morceaux{1});
    end
end
