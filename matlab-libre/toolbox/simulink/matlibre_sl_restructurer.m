function varargout = matlibre_sl_restructurer(action, varargin)
%MATLIBRE_SL_RESTRUCTURER Regroupe, déplie, vide ou range un système.
%   Les opérations sur la valeur d'un système — un modèle, ou le contenu
%   d'un sous-système —, que SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM,
%   EXPANDSUBSYSTEM, ARRANGESYSTEM, DELETECONTENTS et leurs voisines
%   appliquent au modèle de la session :
%
%   S = MATLIBRE_SL_RESTRUCTURER('arranger',S)  retire la Position de
%       chaque bloc du système : la mise en place automatique les range.
%   S = MATLIBRE_SL_RESTRUCTURER('vider',S)  retire ses blocs et ses liens.
%   [S,NOM] = MATLIBRE_SL_RESTRUCTURER('regrouper',S,BLOCS,NOM,UNIQUE,OU)
%       range les blocs nommés dans un sous-système neuf, et rend son nom.
%   [S,NOMS] = MATLIBRE_SL_RESTRUCTURER('deplier',S,BLOC,OU)  remplace le
%       sous-système BLOC par son contenu, et rend les noms des blocs posés.
%   C = MATLIBRE_SL_RESTRUCTURER('contenu',S,BLOC,OU)  le contenu du
%       sous-système BLOC.
%   S = MATLIBRE_SL_RESTRUCTURER('viderSousSysteme',S,BLOC,OU)
%   S = MATLIBRE_SL_RESTRUCTURER('remplir',S,BLOC,C,OU)  pose le contenu C
%       dans le sous-système vide BLOC.
%   OU est le chemin du système, pour que les erreurs nomment les blocs
%   comme Simulink.
%
%   Et pour un modèle de la session :
%   CTX = MATLIBRE_SL_RESTRUCTURER('ouvrir',RACINE,CHEMIN)  le système au
%       chemin CHEMIN du modèle RACINE ('' : le modèle) : CTX.systeme ;
%   MATLIBRE_SL_RESTRUCTURER('fermer',CTX,S)  le remet à sa place.
%
%   Les liens se rebranchent comme dans Simulink. Regrouper : un signal
%   qui entre dans le groupe devient une entrée du sous-système, une
%   seule par signal ; un signal qui en sort, une sortie ; un port resté
%   libre reçoit son Inport ou son Outport ; un bloc Inport ou Outport du
%   groupe part dedans, et un bloc de même nom et de même rang le
%   remplace dehors. Déplier : chaque signal qui arrivait sur une entrée
%   du sous-système va droit aux blocs que son Inport alimentait, et ce
%   qui alimentait un Outport va droit aux blocs que la sortie
%   alimentait ; les Inport et les Outport disparaissent.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 2);
%      m = add_block(m, 'gain', 'g', 'Gain', 3);
%      m = add_block(m, 'outport', 'y');
%      m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
%      [m, nom] = matlibre_sl_restructurer('regrouper', m, {'g'}, '', true, 'essai');
%      nom                                      % 'Subsystem'
%      m = matlibre_sl_restructurer('deplier', m, nom, 'essai');
%      numel(m.blocs)                           % 3, comme avant
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM,
%   SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM, SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM.
    switch action
        case 'arranger'
            varargout{1} = arranger(varargin{1});
        case 'vider'
            varargout{1} = vider(varargin{1});
        case 'regrouper'
            [varargout{1}, varargout{2}] = regrouper(varargin{:});
        case 'deplier'
            [varargout{1}, varargout{2}] = deplier(varargin{:});
        case 'contenu'
            varargout{1} = contenu(varargin{:});
        case 'viderSousSysteme'
            varargout{1} = viderSousSysteme(varargin{:});
        case 'remplir'
            varargout{1} = remplir(varargin{:});
        case 'ouvrir'
            varargout{1} = ouvrir(varargin{:});
        case 'fermer'
            fermer(varargin{:});
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

% --- la session ---------------------------------------------------------------

function ctx = ouvrir(racine, chemin)
    ctx.racine = char(racine);
    ctx.chemin = char(chemin);
    ctx.modele = matlibre_sl_nomme('modele', ctx.racine);
    ctx.systeme = ctx.modele;
    if ~isempty(ctx.chemin)
        ctx.systeme = matlibre_sl_dedans(ctx.modele, ctx.chemin);
    end
end

function fermer(ctx, systeme)
    modele = systeme;
    if ~isempty(ctx.chemin)
        modele = matlibre_sl_remplacer(ctx.modele, ctx.chemin, systeme);
    end
    matlibre_sl_nomme('ranger', ctx.racine, modele);
end

% --- ranger, vider ------------------------------------------------------------

function systeme = arranger(systeme)
    for k = 1:numel(systeme.blocs)
        if isfield(systeme.blocs{k}.parametres, 'Position')
            systeme.blocs{k}.parametres = rmfield(systeme.blocs{k}.parametres, 'Position');
        end
    end
end

function systeme = vider(systeme)
    systeme.blocs = {};
    systeme.liens = [];
    if isfield(systeme, 'connexions')
        systeme.connexions = zeros(0, 4);
    end
end

% --- regrouper ----------------------------------------------------------------

function [systeme, nom] = regrouper(systeme, choisis, nom, unique, ou)
    tous = nomsDe(systeme);
    n = numel(tous);
    dedans = false(1, n);
    for k = 1:numel(choisis)
        i = find(strcmp(tous, char(choisis{k})), 1);
        if isempty(i)
            error('Simulink:Commands:InvSimulinkObjectName', ...
                  'Le systeme ''%s'' n''a pas de bloc ''%s''.', ou, char(choisis{k}));
        end
        dedans(i) = true;
    end
    types = cellfun(@typeDe, systeme.blocs, 'UniformOutput', false);
    for i = find(dedans)
        if any(strcmp(types{i}, portsDeControle()))
            error('Simulink:BlockDiagram:CreateSubsystemControlPort', ...
                  ['Le bloc ''%s/%s'' est un port de controle de son systeme : il ne part ' ...
                   'pas dans un sous-systeme neuf, qui changerait la facon dont le systeme ' ...
                   's''execute.'], ou, tous{i});
        end
    end
    % le nom du sous-système, parmi les blocs qui restent
    restants = tous(~dedans);
    if isempty(nom)
        nom = libre(restants, 'Subsystem');
    else
        nom = char(nom);
        if isempty(nom) || any(nom == '/')
            error('Simulink:BlockDiagram:CreateSubsystemInvalidName', ...
                  'Le nom d''un sous-systeme est un texte non vide, sans barre oblique.');
        end
        if any(strcmp(restants, nom))
            if ~unique
                error('Simulink:Commands:AddBlockCantAdd', ...
                      ['Le systeme ''%s'' porte deja un bloc nomme ''%s'' ; ' ...
                       'MakeNameUnique ''on'' en choisit un libre.'], ou, nom);
            end
            nom = libre(restants, nom);
        end
    end
    liens = matlibre_sl_liens(systeme);
    connexions = zeros(0, 4);
    if isfield(systeme, 'connexions') && ~isempty(systeme.connexions)
        connexions = systeme.connexions;
    end
    for r = 1:size(connexions, 1)
        if dedans(connexions(r, 1)) ~= dedans(connexions(r, 3))
            error('Simulink:BlockDiagram:CreateSubsystemPhysical', ...
                  ['Une connexion physique relie ''%s/%s'' a ''%s/%s'', l''un dans le groupe, ' ...
                   'l''autre dehors : un sous-systeme ne porte pas ici de port physique.'], ...
                  ou, tous{connexions(r, 1)}, ou, tous{connexions(r, 3)});
        end
    end

    % Les entrées et les sorties du sous-système, dans l'ordre des blocs :
    % un bloc Inport du groupe ; un signal du dehors, une fois ; un port
    % resté libre. Un Inport ou un Outport du groupe est lui-même un port :
    % son côté libre n'en appelle pas un autre, et ce qu'un Inport
    % alimentait dehors, son remplaçant l'alimente.
    entrees = struct('genre', {}, 'bloc', {}, 'port', {});
    sorties = struct('genre', {}, 'bloc', {}, 'port', {});
    for i = find(dedans)
        [ne, ns] = matlibre_sl_ports(systeme.blocs{i});
        estPort = any(strcmp(types{i}, {'inport', 'outport'}));
        if strcmp(types{i}, 'inport')
            entrees(end + 1) = struct('genre', 'port', 'bloc', i, 'port', 1); %#ok<AGROW>
            ns = 0;
        end
        for pe = portsDe(ne, liens(liens(:, 2) == i, 3))
            r = find(liens(:, 2) == i & liens(:, 3) == pe, 1);
            if isempty(r)
                if ~estPort
                    entrees(end + 1) = struct('genre', 'libre', 'bloc', i, 'port', pe); %#ok<AGROW>
                end
            elseif ~dedans(liens(r, 1)) && ...
                   ~any(strcmp({entrees.genre}, 'signal') & [entrees.bloc] == liens(r, 1) & ...
                        [entrees.port] == liens(r, 4))
                entrees(end + 1) = struct('genre', 'signal', 'bloc', liens(r, 1), ...
                                          'port', liens(r, 4)); %#ok<AGROW>
            end
        end
        if strcmp(types{i}, 'outport')
            sorties(end + 1) = struct('genre', 'port', 'bloc', i, 'port', 1); %#ok<AGROW>
        end
        if strcmp(types{i}, 'inport')
            continue
        end
        for ps = portsDe(ns, liens(liens(:, 1) == i, 4))
            vers = find(liens(:, 1) == i & liens(:, 4) == ps);
            if isempty(vers)
                if ~estPort
                    sorties(end + 1) = struct('genre', 'libre', 'bloc', i, 'port', ps); %#ok<AGROW>
                end
            elseif any(~dedans(liens(vers, 2)))
                sorties(end + 1) = struct('genre', 'signal', 'bloc', i, 'port', ps); %#ok<AGROW>
            end
        end
    end

    % le dedans : les blocs du groupe, puis les Inport et les Outport neufs
    dans = find(dedans);
    hors = find(~dedans);
    versDans = zeros(1, n);
    versDans(dans) = 1:numel(dans);
    versHors = zeros(1, n);
    versHors(hors) = 1:numel(hors);
    interieur = systemeVide(nom);
    interieur.blocs = systeme.blocs(dans);
    rangEntree = zeros(1, numel(entrees));
    for r = 1:numel(entrees)
        if strcmp(entrees(r).genre, 'port')
            j = versDans(entrees(r).bloc);
            interieur.blocs{j}.parametres.Port = r;
            rangEntree(r) = j;
        else
            interieur = add_block(interieur, 'inport', libre(nomsDe(interieur), ...
                                  sprintf('In%d', r)), 'Port', r);
            rangEntree(r) = numel(interieur.blocs);
        end
    end
    rangSortie = zeros(1, numel(sorties));
    for r = 1:numel(sorties)
        if strcmp(sorties(r).genre, 'port')
            j = versDans(sorties(r).bloc);
            interieur.blocs{j}.parametres.Port = r;
            rangSortie(r) = j;
        else
            interieur = add_block(interieur, 'outport', libre(nomsDe(interieur), ...
                                  sprintf('Out%d', r)), 'Port', r);
            rangSortie(r) = numel(interieur.blocs);
        end
    end

    % le dehors : les blocs qui restent, le sous-système, et un port neuf
    % pour chaque Inport ou Outport parti dedans
    parent = systeme;
    parent.blocs = systeme.blocs(hors);
    porteur = systemeVide(ou);
    porteur = add_block(porteur, 'subsystem', nom, 'Model', interieur);
    parent.blocs{end + 1} = porteur.blocs{1};
    ss = numel(parent.blocs);
    nouveauPort = zeros(1, n);   % le port neuf, dehors, d'un Inport parti
    for r = 1:numel(entrees)
        if strcmp(entrees(r).genre, 'port')
            parent.blocs{end + 1} = portRemplacant(systeme.blocs{entrees(r).bloc}); %#ok<AGROW>
            nouveauPort(entrees(r).bloc) = numel(parent.blocs);
        end
    end
    for r = 1:numel(sorties)
        if strcmp(sorties(r).genre, 'port')
            parent.blocs{end + 1} = portRemplacant(systeme.blocs{sorties(r).bloc}); %#ok<AGROW>
            nouveauPort(sorties(r).bloc) = numel(parent.blocs);
        end
    end

    liensDans = zeros(0, 4);
    liensHors = zeros(0, 4);
    for k = 1:size(liens, 1)
        a = liens(k, 1);
        b = liens(k, 2);
        pe = liens(k, 3);
        ps = liens(k, 4);
        if dedans(a) && dedans(b)
            liensDans(end + 1, :) = [versDans(a), versDans(b), pe, ps]; %#ok<AGROW>
        elseif ~dedans(a) && ~dedans(b)
            liensHors(end + 1, :) = [versHors(a), versHors(b), pe, ps]; %#ok<AGROW>
        elseif ~dedans(a)
            % un signal du dehors : par l'entrée qui lui revient
            r = find(strcmp({entrees.genre}, 'signal') & [entrees.bloc] == a & ...
                     [entrees.port] == ps, 1);
            liensDans(end + 1, :) = [rangEntree(r), versDans(b), pe, 1]; %#ok<AGROW>
        elseif strcmp(types{a}, 'inport')
            % un Inport parti dedans alimentait aussi le dehors : son
            % remplaçant le fait
            liensHors(end + 1, :) = [nouveauPort(a), versHors(b), pe, 1]; %#ok<AGROW>
        else
            % vers le dehors : par la sortie qui lui revient
            r = find(strcmp({sorties.genre}, 'signal') & [sorties.bloc] == a & ...
                     [sorties.port] == ps, 1);
            liensHors(end + 1, :) = [ss, versHors(b), pe, r]; %#ok<AGROW>
        end
    end
    for r = 1:numel(entrees)
        switch entrees(r).genre
            case 'signal'
                liensHors(end + 1, :) = [versHors(entrees(r).bloc), ss, r, entrees(r).port]; %#ok<AGROW>
            case 'libre'
                liensDans(end + 1, :) = [rangEntree(r), versDans(entrees(r).bloc), ...
                                         entrees(r).port, 1]; %#ok<AGROW>
            case 'port'
                liensHors(end + 1, :) = [nouveauPort(entrees(r).bloc), ss, r, 1]; %#ok<AGROW>
        end
    end
    for r = 1:numel(sorties)
        switch sorties(r).genre
            case {'signal', 'libre'}
                liensDans(end + 1, :) = [versDans(sorties(r).bloc), rangSortie(r), 1, ...
                                         sorties(r).port]; %#ok<AGROW>
            case 'port'
                liensHors(end + 1, :) = [ss, nouveauPort(sorties(r).bloc), 1, r]; %#ok<AGROW>
        end
    end
    % la table des liens du dedans, rangée dans le bloc du sous-système
    interieur.liens = liensDans;
    if ~isempty(connexions)
        garde = dedans(connexions(:, 1));
        if any(garde)
            c = connexions(garde, :);
            interieur.connexions = [versDans(c(:, 1)).', c(:, 2), versDans(c(:, 3)).', c(:, 4)];
        end
        c = connexions(~garde, :);
        parent.connexions = [versHors(c(:, 1)).', c(:, 2), versHors(c(:, 3)).', c(:, 4)];
    end
    parent.blocs{ss}.parametres.Model = interieur;
    parent.liens = liensHors;
    systeme = parent;
end

% Le port qui remplace, dehors, un Inport ou un Outport parti dans le
% sous-système : même nom, même rang, mêmes réglages.
function bloc = portRemplacant(parti)
    bloc = struct('type', parti.type, 'nom', parti.nom, 'parametres', parti.parametres);
end

% Les ports d'un côté d'un bloc : ceux que son type lui donne, et ceux où
% tiennent des liens. Un nombre inconnu (NaN) ne compte que les liens.
function ports = portsDe(nombre, lies)
    lies = unique(lies(:).');
    if isnan(nombre)
        ports = lies;
    else
        ports = union(1:nombre, lies);
    end
    ports = reshape(ports, 1, []);
end

% --- déplier ------------------------------------------------------------------

function [systeme, poses] = deplier(systeme, nomBloc, ou)
    i = rangDe(systeme, nomBloc, ou);
    b = systeme.blocs{i};
    complet = [ou '/' char(nomBloc)];
    if ~strcmp(typeDe(b), 'subsystem')
        error('Simulink:BlockDiagram:ExpandSubsystemNotSubsystem', ...
              'Le bloc ''%s'' n''est pas un sous-systeme : il n''a rien a deplier.', complet);
    end
    raison = '';
    if ~isempty(matlibre_sl_masque('variables', b)) || ...
       (isfield(b.parametres, 'Mask') && strcmpi(char(b.parametres.Mask), 'on'))
        raison = 'masque';
    elseif isfield(b, 'reference') && ~isempty(b.reference)
        raison = 'lie a une bibliotheque';
    elseif estCommente(b)
        raison = 'mis en commentaire';
    elseif reglage(b, 'TreatAsAtomicUnit', 'off', 'on')
        raison = 'atomique';
    elseif reglage(b, 'Variant', 'off', 'on')
        raison = 'a variantes';
    end
    c = contenuDe(b, complet);
    typesDedans = cellfun(@typeDe, c.blocs, 'UniformOutput', false);
    if isempty(raison) && any(ismember(typesDedans, portsDeControle()))
        raison = 'conditionnel';
    end
    if ~isempty(raison)
        error('Simulink:BlockDiagram:ExpandSubsystemNotAllowed', ...
              ['Le sous-systeme ''%s'' est %s : il ne se deplie pas. Se deplie un ' ...
               'sous-systeme virtuel ni masque, ni lie, ni commente ; ni atomique, ni ' ...
               'conditionnel, ni a variantes.'], complet, raison);
    end
    entrees = rangsDePorts(c, typesDedans, 'inport');
    sorties = rangsDePorts(c, typesDedans, 'outport');
    normaux = find(~ismember(typesDedans, {'inport', 'outport'}));

    liens = matlibre_sl_liens(systeme);
    n = numel(systeme.blocs);
    versHors = zeros(1, n);
    versHors([1:i - 1, i + 1:n]) = 1:n - 1;
    % ce qui arrivait au sous-système, et ce qu'il alimentait
    source = zeros(0, 3);     % [rang de l'entrée, bloc, port]
    cible = zeros(0, 3);      % [rang de la sortie, bloc, port]
    reste = zeros(0, 4);
    for k = 1:size(liens, 1)
        if liens(k, 2) == i
            source(end + 1, :) = [liens(k, 3), versHors(liens(k, 1)), liens(k, 4)]; %#ok<AGROW>
        elseif liens(k, 1) == i
            cible(end + 1, :) = [liens(k, 4), versHors(liens(k, 2)), liens(k, 3)]; %#ok<AGROW>
        else
            reste(end + 1, :) = [versHors(liens(k, 1)), versHors(liens(k, 2)), ...
                                 liens(k, 3), liens(k, 4)]; %#ok<AGROW>
        end
    end
    connexions = zeros(0, 4);
    if isfield(systeme, 'connexions') && ~isempty(systeme.connexions)
        connexions = systeme.connexions;
        if any(connexions(:, 1) == i | connexions(:, 3) == i)
            error('Simulink:BlockDiagram:ExpandSubsystemPhysical', ...
                  'Le sous-systeme ''%s'' porte une connexion physique : il ne se deplie pas.', ...
                  complet);
        end
        connexions = [versHors(connexions(:, 1)).', connexions(:, 2), ...
                      versHors(connexions(:, 3)).', connexions(:, 4)];
    end

    % les blocs du dedans, sous un nom libre, sans priorité ni place
    pris = nomsDe(systeme);
    pris(i) = [];
    parent = systeme;
    parent.blocs(i) = [];
    versParent = zeros(1, numel(c.blocs));
    poses = cell(1, numel(normaux));
    for k = 1:numel(normaux)
        bloc = c.blocs{normaux(k)};
        bloc.nom = libre(pris, char(bloc.nom));
        pris{end + 1} = bloc.nom; %#ok<AGROW>
        for champ = {'Priority', 'Position'}
            if isfield(bloc.parametres, champ{1})
                bloc.parametres = rmfield(bloc.parametres, champ{1});
            end
        end
        parent.blocs{end + 1} = bloc;
        versParent(normaux(k)) = numel(parent.blocs);
        poses{k} = bloc.nom;
    end

    % chaque lien du dedans, rebranché à travers les ports qui disparaissent
    nouveaux = zeros(0, 4);
    for lien = matlibre_sl_liens(c).'
        a = lien(1);
        b2 = lien(2);
        k = find(entrees(:, 1) == a, 1);
        if ~isempty(k)
            depart = source(source(:, 1) == entrees(k, 2), 2:3);
        else
            depart = [versParent(a), lien(4)];
        end
        k = find(sorties(:, 1) == b2, 1);
        if ~isempty(k)
            arrivees = cible(cible(:, 1) == sorties(k, 2), 2:3);
        else
            arrivees = [versParent(b2), lien(3)];
        end
        for d = 1:size(depart, 1)
            for a2 = 1:size(arrivees, 1)
                nouveaux(end + 1, :) = [depart(d, 1), arrivees(a2, 1), arrivees(a2, 2), ...
                                        depart(d, 2)]; %#ok<AGROW>
            end
        end
    end
    parent.liens = [reste; nouveaux];
    if isfield(c, 'connexions') && ~isempty(c.connexions)
        connexions = [connexions; versParent(c.connexions(:, 1)).', c.connexions(:, 2), ...
                      versParent(c.connexions(:, 3)).', c.connexions(:, 4)];
    end
    if ~isempty(connexions) || isfield(parent, 'connexions')
        parent.connexions = connexions;
    end
    systeme = parent;
end

% Les Inport — ou les Outport — d'un système et leur rang : leur place
% quand on les range par leur paramètre Port, comme au dépliage.
function rangs = rangsDePorts(c, types, type)
    indices = find(strcmp(types, type));
    valeurs = zeros(size(indices));
    for k = 1:numel(indices)
        p = c.blocs{indices(k)}.parametres;
        v = k;
        if isfield(p, 'Port')
            v = p.Port;
            if ischar(v) || isstring(v)
                v = str2double(v);
            end
        end
        valeurs(k) = double(v);
    end
    [~, ordre] = sort(valeurs);
    rangs = [indices(ordre).', (1:numel(indices)).'];
end

% --- le contenu d'un sous-système ---------------------------------------------

function c = contenu(systeme, nomBloc, ou)
    i = rangDe(systeme, nomBloc, ou);
    b = systeme.blocs{i};
    complet = [ou '/' char(nomBloc)];
    if ~strcmp(typeDe(b), 'subsystem')
        error('Simulink:SubSystem:NotASubsystem', ...
              'Le bloc ''%s'' n''est pas un sous-systeme.', complet);
    end
    c = contenuDe(b, complet);
end

function systeme = viderSousSysteme(systeme, nomBloc, ou)
    i = rangDe(systeme, nomBloc, ou);
    b = systeme.blocs{i};
    complet = [ou '/' char(nomBloc)];
    exigerModifiable(b, complet);
    systeme.blocs{i} = poserContenu(b, systemeVide(nomBloc));
    % ses ports disparaissent, et les liens qui y tenaient avec eux
    liens = matlibre_sl_liens(systeme);
    systeme.liens = liens(liens(:, 1) ~= i & liens(:, 2) ~= i, :);
    if isfield(systeme, 'connexions') && ~isempty(systeme.connexions)
        systeme.connexions = systeme.connexions(systeme.connexions(:, 1) ~= i & ...
                                                systeme.connexions(:, 3) ~= i, :);
    end
end

function systeme = remplir(systeme, nomBloc, c, ou)
    i = rangDe(systeme, nomBloc, ou);
    b = systeme.blocs{i};
    complet = [ou '/' char(nomBloc)];
    exigerModifiable(b, complet);
    actuel = contenuDe(b, complet);
    if ~isempty(actuel.blocs)
        error('Simulink:SubSystem:SubsystemNotEmpty', ...
              ['Le sous-systeme ''%s'' contient deja des blocs : on n''y copie qu''un ' ...
               'contenu vide. Simulink.SubSystem.deleteContents le vide.'], complet);
    end
    plein = systemeVide(nomBloc);
    plein.blocs = c.blocs;
    plein.liens = matlibre_sl_liens(c);
    if isfield(c, 'connexions') && ~isempty(c.connexions)
        plein.connexions = c.connexions;
    end
    systeme.blocs{i} = poserContenu(b, plein);
end

function exigerModifiable(b, complet)
    if ~strcmp(typeDe(b), 'subsystem')
        error('Simulink:SubSystem:NotASubsystem', ...
              'Le bloc ''%s'' n''est pas un sous-systeme.', complet);
    end
    if isfield(b, 'reference') && ~isempty(b.reference)
        error('Simulink:SubSystem:LinkedSubsystem', ...
              ['Le sous-systeme ''%s'' est lie a la bibliotheque ''%s'' : son contenu ' ...
               'est celui de la bibliotheque, et ne se change pas ici.'], complet, ...
              char(b.reference));
    end
end

function c = contenuDe(b, complet)
    c = [];
    for champ = {'Model', 'Modele'}
        if isfield(b.parametres, champ{1})
            c = b.parametres.(champ{1});
        end
    end
    if isempty(c)
        c = systemeVide(b.nom);
    elseif ~(isstruct(c) && isfield(c, 'blocs'))
        error('Simulink:SubSystem:NotASubsystem', ...
              'Le sous-systeme ''%s'' ne porte pas son contenu : il designe un autre modele.', ...
              complet);
    end
end

function b = poserContenu(b, c)
    if isfield(b.parametres, 'Modele') && ~isfield(b.parametres, 'Model')
        b.parametres.Modele = c;
    else
        b.parametres.Model = c;
    end
end

% --- petits outils ------------------------------------------------------------

function noms = nomsDe(systeme)
    noms = cellfun(@(b) char(b.nom), systeme.blocs, 'UniformOutput', false);
end

function i = rangDe(systeme, nom, ou)
    i = find(strcmp(nomsDe(systeme), char(nom)), 1);
    if isempty(i)
        error('Simulink:Commands:InvSimulinkObjectName', ...
              'Le systeme ''%s'' n''a pas de bloc ''%s''.', ou, char(nom));
    end
end

function t = typeDe(b)
    t = char(b.type);
    try
        e = matlibre_sl_catalogue('type', t);
        t = e.type;
    catch
    end
end

function noms = portsDeControle()
    noms = {'enableport', 'triggerport', 'actionport', 'resetport', 'foreach', ...
            'foriterator', 'whileiterator', 'inbuselement', 'outbuselement'};
end

function oui = estCommente(b)
    oui = isfield(b.parametres, 'Commented') && ~strcmpi(char(b.parametres.Commented), 'off');
end

% Vrai si le réglage NOM du bloc vaut OUI ; DEFAUT s'il n'est pas posé.
function oui = reglage(b, nom, defaut, valeurOui)
    v = defaut;
    if isfield(b.parametres, nom)
        v = b.parametres.(nom);
    end
    oui = (ischar(v) || isstring(v)) && strcmpi(char(v), valeurOui);
end

% Un nom libre parmi PRIS : NOM lui-même, ou sa racine suivie du premier
% rang libre — 'Subsystem', 'Subsystem1', 'Subsystem2'…
function nom = libre(pris, nom)
    nom = char(nom);
    if ~any(strcmp(pris, nom))
        return
    end
    racine = regexprep(nom, '\d+$', '');
    rang = 1;
    while any(strcmp(pris, sprintf('%s%d', racine, rang)))
        rang = rang + 1;
    end
    nom = sprintf('%s%d', racine, rang);
end

% Le contenu vide d'un sous-système, sans passer par NEW_SYSTEM, qui
% oublierait l'espace de travail du modèle de ce nom.
function systeme = systemeVide(nom)
    systeme = struct('nom', char(nom), 'blocs', {{}}, 'liens', [], 'parametres', struct());
end
