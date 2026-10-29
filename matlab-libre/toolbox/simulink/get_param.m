function valeur = get_param(modele, nom, parametre)
%GET_PARAM Lit un paramètre d'un bloc, ou un réglage du modèle.
%   V = GET_PARAM(MODELE,BLOC,'Param') rend la valeur du paramètre du bloc
%   nommé — celle qu'on lui a donnée, ou, à défaut, sa valeur par défaut,
%   comme dans Simulink. BLOC est le nom du bloc, ou son chemin
%   « modele/bloc » ; « sousSysteme/bloc » descend dans un sous-système.
%   GET_PARAM(MODELE,BLOC) rend la structure entière du bloc : son type,
%   son nom et les paramètres qu'on lui a donnés.
%
%   Quelques paramètres se lisent sans avoir été posés :
%     BlockType     le type MatLibre du bloc (« gain », « integrator »)
%     Name, Parent  son nom, et le système qui le contient
%     Ports         [entrées sorties 0 0 0 0 0 0], comme Simulink
%     PortHandles   les poignées de ses ports : Inport, Outport...
%     DialogParameters  la liste de ses paramètres, avec leurs valeurs
%                   admises quand ce sont des choix
%     ObjectParameters  tous ses paramètres — ceux du dialogue, et Name,
%                   Parent, BlockType, Ports... —, leur type, leurs valeurs
%                   admises et s'ils se règlent (Attributes)
%     Mask, MaskType  'off' et '' pour un bloc sans masque
%     CompiledSampleTime  sa période, [période décalage], une fois le
%                   modèle compilé : [0 0] continue, [0 1] continue fixée
%                   aux pas mineurs, [Inf 0] constante
%     CompiledPortWidths, CompiledPortDimensions, CompiledPortDataTypes,
%     CompiledPortComplexSignals  la largeur, les dimensions ([nombre de
%                   dimensions, dimensions...] par port), le type et la
%                   complexité de ses ports, Inport et Outport
%
%   GET_PARAM(MODELE,'ModelWorkspace') rend l'espace de travail du modèle,
%   un Simulink.ModelWorkspace, dont les variables passent avant celles de
%   l'espace de base.
%
%   GET_PARAM(MODELE,'Reglage') rend un réglage du modèle : Name, Blocks,
%   et ceux de la boîte « Paramètres de configuration » — StopTime,
%   Solver, FixedStep... —, avec leur valeur par défaut quand on ne les a
%   pas posés. Un réglage posé par ADD_PARAM se lit de même, comme la
%   fiche du modèle : Created, Creator, LastModifiedDate, LastModifiedBy,
%   ModelVersion, ModelVersionFormat, ModifiedComment, FileName — le
%   fichier d'où il vient — et Dirty, 'on' quand un modèle chargé a changé
%   depuis qu'on l'a chargé, créé ou écrit.
%
%   GET_PARAM(MODELE,H,'Reglage'), H une poignée de port, rend un réglage
%   du signal qui part de ce port — Name, DataLogging... — ou PortType,
%   PortNumber, Parent.
%
%   V = GET_PARAM(OBJET,'Param') est la forme de Simulink, sur un modèle
%   chargé : OBJET est le chemin d'un bloc ('modele/sousSysteme/bloc'),
%   celui du modèle, ou une poignée de bloc, de modèle, de port ou de
%   ligne — plusieurs dans une cellule ou un vecteur, et V est une
%   cellule. Chaque objet a en plus Handle, sa poignée ; Name ; Parent,
%   le chemin du système qui le contient ; Type, 'block' ou
%   'block_diagram'. Un bloc a BlockType, son type dans Simulink
%   ('Gain'), PortHandles et LineHandles ; une ligne SrcBlockHandle,
%   DstBlockHandle, SrcPortHandle, DstPortHandle et Name.
%
%   C'est le pendant de SET_PARAM. Un paramètre que le bloc n'a pas lève
%   une erreur qui le nomme, plutôt que de rendre une valeur vide dont on
%   ne saurait pas si elle est le réglage ou son absence.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'gain', 'g', 'Gain', 2);
%      get_param(m, 'g', 'Gain')            % 2
%      m = set_param(m, 'g', 'Gain', 5);
%      get_param(m, 'g', 'Gain')            % 5
%      get_param(m, 'g').type               % 'gain'
%      get_param(m, 'g', 'Multiplication')  % 'Element-wise(K.*u)', le défaut
%      get_param(m, 'essai/g', 'Ports')     % [1 1 0 0 0 0 0 0]
%      get_param(m, 'Solver')               % 'ode1'
%
%   Voir aussi SET_PARAM, ADD_PARAM, ADD_BLOCK, FIND_SYSTEM, NEW_SYSTEM.
    % Une poignée de port : les réglages du signal qui en part.
    if ~isstruct(modele)
        % GET_PARAM(OBJET,'Param') : la forme de Simulink, sur un modèle chargé
        if nargin ~= 2
            error('Simulink:Commands:GetParamArguments', ...
                  'GET_PARAM(OBJET,''Param'') : un objet, et le nom d''un reglage.');
        end
        valeur = lireParNom(modele, nom);
        return
    end
    if isnumeric(nom)
        if nargin < 3
            error('Simulink:Commands:GetParamArguments', ...
                  'GET_PARAM(MODELE,PORT,NOM) : il faut nommer le reglage du port.');
        end
        valeur = matlibre_sl_signaux('lire', modele, nom, parametre);
        return
    end
    if nargin == 3 && strcmpi(char(parametre), 'PortHandles')
        valeur = matlibre_sl_signaux('poignees', modele, char(nom));
        return
    end
    if nargin == 3 && strncmpi(char(parametre), 'Compiled', 8)
        valeur = compile(modele, char(nom), char(parametre));
        return
    end
    nom = char(nom);
    if nargin == 2
        [trouve, valeur] = reglageModele(modele, nom);
        if trouve
            return
        end
    end
    [parent, feuille] = decouper(modele, nom);
    if ~isempty(parent)
        interieur = matlibre_sl_dedans(modele, parent);
        if nargin < 3
            valeur = get_param(interieur, feuille);
        else
            valeur = get_param(interieur, feuille, parametre);
            if strcmpi(char(parametre), 'Parent')
                valeur = [char(modele.nom) '/' parent];
            end
        end
        return
    end
    i = 0;
    for k = 1:numel(modele.blocs)
        if strcmp(modele.blocs{k}.nom, feuille)
            i = k;
            break
        end
    end
    if i == 0
        error('Simulink:Commands:InvSimulinkObjectName', ['Nom d''objet Simulink invalide : ' ...
               'aucun bloc ne s''appelle ''%s''.'], nom);
    end
    bloc = modele.blocs{i};
    if nargin < 3
        valeur = bloc;
        return
    end
    champ = char(parametre);
    switch lower(champ)
        case {'blocktype', 'type'}
            valeur = bloc.type;
            return
        case 'name'
            valeur = bloc.nom;
            return
        case 'parent'
            valeur = char(modele.nom);
            return
        case 'ports'
            [ne, ns] = matlibre_sl_ports(bloc);
            valeur = [ne, ns, 0, 0, 0, 0, 0, 0];
            return
    end
    if any(strcmp(matlibre_sl_masque('variables', bloc), champ))
        valeur = matlibre_sl_masque('lire', bloc, champ);
        return
    end
    % ce que le masque dit de ses paramètres : leurs noms, leurs valeurs,
    % et l'espace qu'ils font
    switch lower(champ)
        case 'masknames'
            valeur = matlibre_sl_masque('variables', bloc);
            return
        case 'maskvalues'
            S = matlibre_sl_masque('parametres', bloc);
            valeur = {S.Value};
            return
        case 'maskwsvariables'
            W = matlibre_sl_masque('espace', bloc, struct(), char(bloc.nom));
            noms = fieldnames(W);
            valeur = struct('Name', noms(:).', 'Value', cell(1, numel(noms)));
            for k = 1:numel(noms)
                valeur(k).Value = W.(noms{k});
            end
            return
    end
    switch lower(champ)
        case 'referenceblock'
            valeur = '';
            if isfield(bloc, 'reference')
                valeur = bloc.reference;
            end
            return
        case 'linkstatus'
            valeur = 'none';
            if isfield(bloc, 'reference')
                valeur = 'resolved';
            end
            return
    end
    entree = matlibre_sl_catalogue('type', bloc.type);
    if strcmpi(champ, 'ObjectParameters')
        valeur = parametresObjet(entree);
        return
    end
    if strcmpi(champ, 'DialogParameters')
        valeur = struct();
        for k = 1:size(entree.params, 1)
            nature = entree.params{k, 3};
            if iscell(nature)
                description = struct('Type', 'enum', 'Enum', {nature});
            else
                description = struct('Type', 'string', 'Enum', {{}});
            end
            valeur.(entree.params{k, 1}) = description;
        end
        return
    end
    canon = matlibre_sl_catalogue('parametre', entree, champ);
    if isempty(canon) && any(strcmpi(champ, {'Mask', 'MaskType'}))
        % un bloc sans masque : Mask vaut 'off', MaskType est vide
        valeur = '';
        if strcmpi(champ, 'Mask')
            valeur = 'off';
        end
        for nomMasque = fieldnames(bloc.parametres).'
            if strcmpi(nomMasque{1}, champ)
                valeur = bloc.parametres.(nomMasque{1});
            end
        end
        return
    end
    if isempty(canon)
        error('Simulink:Commands:ParamUnknown', ...
              'Le bloc ''%s'' n''a pas de paramètre ''%s''.', feuille, champ);
    end
    if isfield(bloc.parametres, canon)
        valeur = bloc.parametres.(canon);
        return
    end
    if any(strcmp(canon, matlibre_sl_rappel('noms')))
        valeur = '';   % un rappel qu'on n'a pas posé
        return
    end
    for k = 1:size(entree.params, 1)
        if strcmp(entree.params{k, 1}, canon)
            valeur = entree.params{k, 2};
            return
        end
    end
    error('Simulink:Commands:ParamUnknown', ...
          'Le bloc ''%s'' n''a pas de paramètre ''%s''.', feuille, champ);
end

% Tous les paramètres d'un bloc, comme les décrit ObjectParameters : ceux
% de son dialogue, réglables, ceux que tout bloc porte, et ceux qui se
% lisent sans se régler.
function valeur = parametresObjet(entree)
    valeur = struct();
    for k = 1:size(entree.params, 1)
        nature = entree.params{k, 3};
        if iscell(nature)
            valeur.(entree.params{k, 1}) = struct('Type', 'enum', 'Enum', {nature}, ...
                                                  'Attributes', {{'read-write'}});
        else
            valeur.(entree.params{k, 1}) = struct('Type', 'string', 'Enum', {{}}, ...
                                                  'Attributes', {{'read-write'}});
        end
    end
    for nom = [{'Name', 'Mask', 'MaskType'}, matlibre_sl_catalogue('communs')]
        if ~isfield(valeur, nom{1})
            valeur.(nom{1}) = struct('Type', 'string', 'Enum', {{}}, 'Attributes', {{'read-write'}});
        end
    end
    for nom = {'Parent', 'BlockType', 'Ports', 'PortHandles', 'LinkStatus', 'ReferenceBlock', ...
               'DialogParameters', 'ObjectParameters', 'CompiledSampleTime', ...
               'CompiledPortWidths', 'CompiledPortDimensions', 'CompiledPortDataTypes', ...
               'CompiledPortComplexSignals'}
        valeur.(nom{1}) = struct('Type', 'string', 'Enum', {{}}, 'Attributes', {{'read-only'}});
    end
end

% Ce que la compilation sait d'un bloc : sa période, la largeur, les
% dimensions, le type et la complexité de ses ports. Le modèle se compile
% le temps de la lecture, comme sous model([], [], [], 'compile').
function valeur = compile(modele, nom, champ)
    modele = matlibre_sl_modele(modele);
    prefixe = [char(modele.nom) '/'];
    if strncmp(nom, prefixe, numel(prefixe))
        nom = nom(numel(prefixe) + 1:end);
    end
    c = matlibre_sl_compiler(modele, struct('silencieux', true, 'tFinal', 0));
    k = find(strcmp(c.chemins, [prefixe nom]), 1);
    if isempty(k)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              ['Nom d''objet Simulink invalide : aucun bloc compile de ''%s'' ne s''appelle ' ...
               '''%s''.'], char(modele.nom), nom);
    end
    entrees = c.entrees{k};
    sorties = c.portDebut(k) + (0:c.nOut(k) - 1);
    switch lower(champ)
        case 'compiledsampletime'
            t = c.cadence(k);
            if t == 0 && c.majeurSeul(k)
                valeur = [0 1];
            elseif isinf(t)
                valeur = [Inf 0];
            else
                valeur = [t c.decalage(k)];
            end
        case 'compiledportwidths'
            valeur = struct('Inport', largeurs(c, entrees), 'Outport', largeurs(c, sorties));
        case 'compiledportdimensions'
            valeur = struct('Inport', dimensions(c, entrees), 'Outport', dimensions(c, sorties));
        case 'compiledportdatatypes'
            valeur = struct('Inport', {typesDesPorts(c, entrees)}, ...
                            'Outport', {typesDesPorts(c, sorties)});
        case 'compiledportcomplexsignals'
            valeur = struct('Inport', complexes(c, entrees), 'Outport', complexes(c, sorties));
        otherwise
            error('Simulink:Commands:ParamUnknown', ...
                  'Le bloc ''%s'' n''a pas de parametre ''%s''.', nom, champ);
    end
end

function w = largeurs(c, ports)
    w = ones(1, numel(ports));
    for i = 1:numel(ports)
        if ports(i) > 0
            w(i) = prod(c.dims{ports(i)});
        end
    end
end

% Les dimensions de chaque port, à la suite : [1 n] pour un vecteur, [2 l c]
% pour une matrice, comme Simulink les range.
function d = dimensions(c, ports)
    d = zeros(1, 0);
    for i = 1:numel(ports)
        taille = [1 1];
        if ports(i) > 0
            taille = c.dims{ports(i)};
        end
        if any(taille == 1)
            d = [d, 1, prod(taille)]; %#ok<AGROW>
        else
            d = [d, numel(taille), taille]; %#ok<AGROW>
        end
    end
end

function t = typesDesPorts(c, ports)
    t = cell(1, numel(ports));
    for i = 1:numel(ports)
        t{i} = 'double';
        if ports(i) > 0
            t{i} = matlibre_sl_types('nom', c.typePort(ports(i)));
        end
    end
end

function x = complexes(c, ports)
    x = false(1, numel(ports));
    for i = 1:numel(ports)
        if ports(i) > 0
            x(i) = logical(c.complexePort(ports(i)));
        end
    end
end

% Un réglage du modèle : Name, Blocks, un réglage de configuration — avec
% son défaut —, ou un réglage posé par ADD_PARAM. Un bloc qui porte le
% même nom l'emporte, pour qu'aucun bloc ne devienne illisible.
function [trouve, valeur] = reglageModele(modele, nom)
    trouve = true;
    valeur = [];
    for k = 1:numel(modele.blocs)
        if strcmp(modele.blocs{k}.nom, nom)
            trouve = false;
            return
        end
    end
    if strcmpi(nom, 'Name')
        valeur = modele.nom;
        return
    end
    if strcmpi(nom, 'ModelWorkspace')
        valeur = matlibre_sl_espace('lire', char(modele.nom));
        return
    end
    if any(strcmpi(nom, matlibre_sl_fiche('noms')))
        valeur = matlibre_sl_fiche('lire', modele, nom);   % la fiche du modèle
        return
    end
    switch lower(nom)
        case 'simulationstatus'
            valeur = 'stopped';   % aucune simulation ne tourne quand on la lit
            return
        case 'simulationtime'
            valeur = 0;
            return
        case 'blockdiagramtype'
            valeur = 'model';
            if isfield(modele, 'parametres') && isfield(modele.parametres, 'BlockDiagramType')
                valeur = lower(char(modele.parametres.BlockDiagramType));
            end
            return
    end
    if strcmpi(nom, 'Blocks')
        valeur = cell(1, numel(modele.blocs));
        for i = 1:numel(modele.blocs)
            valeur{i} = modele.blocs{i}.nom;
        end
        return
    end
    canon = matlibre_sl_config('nom', nom);
    if ~isempty(canon)
        config = matlibre_sl_config('lire', modele);
        valeur = config.(canon);
        return
    end
    if isfield(modele, 'parametres') && isfield(modele.parametres, nom)
        valeur = modele.parametres.(nom);
        return
    end
    trouve = false;
end

function [parent, feuille] = decouper(modele, nom)
    parent = '';
    feuille = nom;
    for k = 1:numel(modele.blocs)
        if strcmp(modele.blocs{k}.nom, nom)
            return
        end
    end
    if ~any(nom == '/')
        return
    end
    prefixe = [char(modele.nom) '/'];
    if strncmp(nom, prefixe, numel(prefixe))
        [parent, feuille] = decouper(modele, nom(numel(prefixe) + 1:end));
        return
    end
    barre = find(nom == '/', 1, 'last');
    parent = nom(1:barre - 1);
    feuille = nom(barre + 1:end);
end

% GET_PARAM sur un modèle chargé : l'objet désigné par son chemin ou sa
% poignée — plusieurs dans une cellule ou un vecteur, et la réponse est une
% cellule.
function valeur = lireParNom(cible, parametre)
    if iscell(cible) || (isnumeric(cible) && numel(cible) > 1)
        valeur = cell(size(cible));
        for k = 1:numel(cible)
            if iscell(cible)
                valeur{k} = lireParNom(cible{k}, parametre);
            else
                valeur{k} = lireParNom(cible(k), parametre);
            end
        end
        return
    end
    if isstring(parametre) && isscalar(parametre)
        parametre = char(parametre);
    end
    if ~ischar(parametre)
        error('Simulink:Commands:GetParamArguments', 'Un reglage se designe par son nom.');
    end
    if isnumeric(cible)
        [chemin, genre] = matlibre_sl_memoire('objet', cible);
        if strcmp(genre, 'ligne')
            valeur = lireLigne(cible, parametre);
            return
        end
        if ~any(strcmp(genre, {'bloc', 'modele'}))
            morceaux = matlibre_sl_memoire('morceaux', chemin);
            valeur = matlibre_sl_signaux('lire', matlibre_sl_ouverts('lire', morceaux{1}), ...
                                         cible, parametre);
            return
        end
    end
    chemin = matlibre_sl_memoire('chemin', cible);
    genre = matlibre_sl_memoire('genre', chemin);
    [parent, nomObjet] = matlibre_sl_memoire('decouper', chemin);
    morceaux = matlibre_sl_memoire('morceaux', chemin);
    racine = matlibre_sl_ouverts('lire', morceaux{1});
    switch lower(parametre)
        case 'handle'
            valeur = matlibre_sl_memoire('poignee', chemin);
            return
        case 'type'
            valeur = 'block';
            if strcmp(genre, 'modele')
                valeur = 'block_diagram';
            end
            return
        case 'name'
            valeur = nomObjet;
            return
        case {'parent', 'path'}
            valeur = parent;
            return
    end
    if strcmp(genre, 'modele')
        valeur = get_param(racine, parametre);
        return
    end
    relatif = strjoin(cellfun(@(n) strrep(n, '/', '//'), morceaux(2:end), ...
                              'UniformOutput', false), '/');
    bloc = matlibre_sl_memoire('bloc', chemin);
    switch lower(parametre)
        case 'blocktype'
            entree = matlibre_sl_catalogue('type', bloc.type);
            valeur = entree.simulink;
            return
        case 'porthandles'
            valeur = matlibre_sl_signaux('poignees', racine, relatif);
            return
        case 'linehandles'
            valeur = poigneesLignes(parent, nomObjet, bloc);
            return
    end
    if numel(morceaux) == 2
        valeur = get_param(racine, nomObjet, parametre);
    elseif strncmpi(parametre, 'Compiled', 8)
        valeur = get_param(racine, relatif, parametre);
    else
        valeur = get_param(matlibre_sl_memoire('systeme', parent), nomObjet, parametre);
    end
end

% Les lignes d'un bloc : une poignée par entrée reliée, et par sortie d'où
% part une ligne ; -1 pour un port libre.
function L = poigneesLignes(parent, nomBloc, bloc)
    s = matlibre_sl_memoire('systeme', parent);
    b = matlibre_sl_indice(s, nomBloc);
    liens = matlibre_sl_liens(s);
    [ne, ns] = matlibre_sl_ports(bloc);
    ne(isnan(ne)) = 0;
    ns(isnan(ns)) = 0;
    L = struct('Inport', -ones(1, ne), 'Outport', -ones(1, ns));
    for k = 1:ne
        if any(liens(:, 2) == b & liens(:, 3) == k)
            L.Inport(k) = matlibre_sl_memoire('poigneeligne', parent, nomBloc, k);
        end
    end
    for q = 1:ns
        r = find(liens(:, 1) == b & liens(:, 4) == q, 1);
        if ~isempty(r)
            L.Outport(q) = matlibre_sl_memoire('poigneeligne', parent, ...
                                               s.blocs{liens(r, 2)}.nom, liens(r, 3));
        end
    end
end

% Ce qu'on lit d'une ligne : ses deux bouts, ses ports, son signal.
function valeur = lireLigne(h, parametre)
    L = matlibre_sl_memoire('ligne', h);
    source = matlibre_sl_memoire('joindre', L.systeme, L.source);
    destination = matlibre_sl_memoire('joindre', L.systeme, L.destination);
    switch lower(parametre)
        case 'handle'
            valeur = h;
        case 'type'
            valeur = 'line';
        case 'parent'
            valeur = L.systeme;
        case 'srcblockhandle'
            valeur = matlibre_sl_memoire('poignee', source);
        case 'dstblockhandle'
            valeur = matlibre_sl_memoire('poignee', destination);
        case 'srcporthandle'
            ph = lireParNom(source, 'PortHandles');
            valeur = ph.Outport(L.portSource);
        case 'dstporthandle'
            ph = lireParNom(destination, 'PortHandles');
            valeur = ph.Inport(L.portDestination);
        case 'name'
            ph = lireParNom(source, 'PortHandles');
            valeur = lireParNom(ph.Outport(L.portSource), 'Name');
        otherwise
            error('Simulink:Commands:ParamUnknown', ...
                  ['Une ligne n''a pas de reglage ''%s'' ; elle a Name, Type, Parent, ' ...
                   'Handle, SrcBlockHandle, DstBlockHandle, SrcPortHandle et ' ...
                   'DstPortHandle.'], parametre);
    end
end
