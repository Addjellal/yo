function varargout = matlibre_sl_schema(action, varargin)
%MATLIBRE_SL_SCHEMA Les opérations sur un schéma : vider, déplier, grouper.
%   S = MATLIBRE_SL_SCHEMA('vider',S) retire tous les blocs et les liens
%   du système S. S = MATLIBRE_SL_SCHEMA('remplir',S,SOURCE) y recopie
%   ceux du modèle SOURCE. P = MATLIBRE_SL_SCHEMA('deplier',P,NOM,CHEMIN)
%   remplace le sous-système NOM de P par son contenu. P =
%   MATLIBRE_SL_SCHEMA('grouper',P,NOMS,NOUVEAU,CHEMIN) réunit les blocs
%   NOMS de P dans un sous-système NOUVEAU. S = MATLIBRE_SL_SCHEMA(
%   'ranger',S) place chaque bloc, par couches. P = MATLIBRE_SL_SCHEMA(
%   'detacher',P,NOM) retire les liens de P qui touchent le bloc NOM.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      s = add_block(new_system('s'), 'gain', 'g');
%      s = matlibre_sl_schema('vider', s);
%      isempty(s.blocs)                         % vrai
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM,
%   SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM.
    switch action
        case 'vider'
            varargout{1} = vider(varargin{1});
        case 'remplir'
            varargout{1} = remplir(varargin{:});
        case 'deplier'
            varargout{1} = deplier(varargin{:});
        case 'grouper'
            varargout{1} = grouper(varargin{:});
        case 'ranger'
            varargout{1} = ranger(varargin{1});
        case 'detacher'
            varargout{1} = detacher(varargin{:});
        otherwise
            error('Simulink:Commands:InvalidAction', 'Action inconnue : %s.', char(action));
    end
end

function s = vider(s)
    s.blocs = {};
    s.liens = zeros(0, 4);
    if isfield(s, 'connexions')
        s.connexions = zeros(0, 4);
    end
end

function P = detacher(P, nom)
    k = matlibre_sl_indice(P, nom);
    L = matlibre_sl_liens(P);
    L(L(:, 1) == k | L(:, 2) == k, :) = [];
    P.liens = L;
    if isfield(P, 'connexions') && ~isempty(P.connexions)
        P.connexions(P.connexions(:, 1) == k | P.connexions(:, 3) == k, :) = [];
    end
end

function s = remplir(s, source)
    if ~isempty(s.blocs)
        error('Simulink:Commands:CopyContentsSubsystemNotEmpty', ...
              ['Le sous-systeme ''%s'' n''est pas vide : COPYCONTENTSTOSUBSYSTEM remplit ' ...
               'un sous-systeme vide ; SIMULINK.SUBSYSTEM.DELETECONTENTS le vide.'], ...
              char(s.nom));
    end
    s.blocs = source.blocs;
    s.liens = matlibre_sl_liens(source);
    if isfield(source, 'connexions') && ~isempty(source.connexions)
        s.connexions = source.connexions;
    end
end

% --- déplier un sous-système virtuel ------------------------------------------

function P = deplier(P, nom, chemin)
    k = matlibre_sl_indice(P, nom);
    bloc = P.blocs{k};
    if ~strcmp(typeDe(bloc.type), 'subsystem')
        error('Simulink:Commands:ExpandSubsystemNotSubsystem', ...
              'Le bloc ''%s'' n''est pas un sous-systeme : il n''a rien a deplier.', chemin);
    end
    if isfield(bloc, 'reference') && ~isempty(bloc.reference)
        error('Simulink:Commands:ExpandSubsystemLinked', ...
              ['Le sous-systeme ''%s'' est lie a une bibliotheque : rompez le lien avant de ' ...
               'le deplier.'], chemin);
    end
    if ~isempty(matlibre_sl_masque('variables', bloc)) || ...
       (isfield(bloc.parametres, 'Variant') && strcmpi(char(bloc.parametres.Variant), 'on')) || ...
       (isfield(bloc.parametres, 'TreatAsAtomicUnit') && ...
        strcmpi(char(bloc.parametres.TreatAsAtomicUnit), 'on'))
        error('Simulink:Commands:ExpandSubsystemNotVirtual', ...
              ['Le sous-systeme ''%s'' est masque, a variantes ou atomique : seul un ' ...
               'sous-systeme virtuel se deplie.'], chemin);
    end
    I = matlibre_sl_dedans(P, nom);
    types = cellfun(@(b) typeDe(b.type), I.blocs, 'UniformOutput', false);
    interdits = {'enableport', 'triggerport', 'actionport', 'resetport', 'foriterator', ...
                 'whileiterator', 'foreach', 'eventlistener'};
    if any(ismember(types, interdits))
        error('Simulink:Commands:ExpandSubsystemNotVirtual', ...
              ['Le sous-systeme ''%s'' est conditionnel, itere ou une fonction ' ...
               'd''evenement : seul un sous-systeme virtuel se deplie.'], chemin);
    end
    if (isfield(I, 'connexions') && ~isempty(I.connexions))
        error('Simulink:Commands:ExpandSubsystemPhysical', ...
              ['Le sous-systeme ''%s'' porte des connexions physiques : MatLibre ne le ' ...
               'deplie pas.'], chemin);
    end
    entrees = rangsParPort(I, types, 'inport');
    sorties = rangsParPort(I, types, 'outport');
    LI = matlibre_sl_liens(I);
    LP = matlibre_sl_liens(P);
    % les blocs du dedans, hors des ports, viennent au bout de P sous un
    % nom libre
    noms = cellfun(@(b) char(b.nom), P.blocs, 'UniformOutput', false);
    noms(k) = [];
    garde = find(~ismember(types, {'inport', 'outport'}));
    rang = zeros(1, numel(I.blocs));
    for j = garde
        b = I.blocs{j};
        b.nom = nomLibre(noms, char(b.nom));
        noms{end + 1} = b.nom; %#ok<AGROW>
        P.blocs{end + 1} = b;
        rang(j) = numel(P.blocs);
    end
    nouveaux = zeros(0, 4);
    % la source, dans P, de ce qui arrive au port d'entrée j du dedans
    sourceEntree = @(j) LP(LP(:, 2) == k & LP(:, 3) == j, [1 4]);
    % chaque lien du dedans, ses deux bouts ramenés dans P
    for l = 1:size(LI, 1)
        a = LI(l, 1);
        b = LI(l, 2);
        if strcmp(types{b}, 'outport')
            continue   % ce qui sort se relie plus bas
        end
        if strcmp(types{a}, 'inport')
            s = sourceEntree(find(entrees == a, 1));
            if isempty(s)
                continue   % une entrée que rien n'alimentait
            end
            nouveaux(end + 1, :) = [s(1), rang(b), LI(l, 3), s(2)]; %#ok<AGROW>
        else
            nouveaux(end + 1, :) = [rang(a), rang(b), LI(l, 3), LI(l, 4)]; %#ok<AGROW>
        end
    end
    % ce que chaque sortie du sous-système alimentait, relié à ce qui
    % nourrit son Outport
    for o = 1:numel(sorties)
        arrivee = LI(LI(:, 2) == sorties(o), :);
        if isempty(arrivee)
            continue
        end
        a = arrivee(1, 1);
        if strcmp(types{a}, 'inport')
            s = sourceEntree(find(entrees == a, 1));
            if isempty(s)
                continue
            end
            source = s;
        else
            source = [rang(a), arrivee(1, 4)];
        end
        for l = find(LP(:, 1) == k & LP(:, 4) == o).'
            nouveaux(end + 1, :) = [source(1), LP(l, 2), LP(l, 3), source(2)]; %#ok<AGROW>
        end
    end
    % le sous-système et ses liens s'en vont ; les rangs se resserrent
    LP(LP(:, 1) == k | LP(:, 2) == k, :) = [];
    L = [LP; nouveaux];
    P.blocs(k) = [];
    L(L(:, 1) > k, 1) = L(L(:, 1) > k, 1) - 1;
    L(L(:, 2) > k, 2) = L(L(:, 2) > k, 2) - 1;
    P.liens = L;
    if isfield(P, 'connexions') && ~isempty(P.connexions)
        C = P.connexions;
        C(C(:, 1) > k, 1) = C(C(:, 1) > k, 1) - 1;
        C(C(:, 3) > k, 3) = C(C(:, 3) > k, 3) - 1;
        P.connexions = C;
    end
end

% --- grouper des blocs en un sous-système ---------------------------------------

function P = grouper(P, choisis, nouveau, chemin)
    n = numel(P.blocs);
    sel = false(1, n);
    for i = 1:numel(choisis)
        sel(matlibre_sl_indice(P, choisis{i})) = true;
    end
    if isfield(P, 'connexions') && ~isempty(P.connexions)
        C = P.connexions;
        if any(xor(sel(C(:, 1)), sel(C(:, 3))))
            error('Simulink:Commands:CreateSubsystemPhysical', ...
                  ['Une connexion physique de ''%s'' traverse le bord des blocs choisis : ' ...
                   'MatLibre ne les groupe pas.'], chemin);
        end
    end
    L = matlibre_sl_liens(P);
    % un vecteur ligne indexé par une colonne reste une ligne : les
    % drapeaux des deux bouts de chaque lien, en colonnes
    sa = reshape(sel(L(:, 1)), [], 1);
    sb = reshape(sel(L(:, 2)), [], 1);
    I = new_system(regexprep(nouveau, '[^A-Za-z0-9_]', '_'));
    idx = find(sel);
    rangI = zeros(1, n);
    for j = idx
        I.blocs{end + 1} = P.blocs{j};
        rangI(j) = numel(I.blocs);
    end
    LI = zeros(0, 4);
    for l = find(sa & sb).'
        LI(end + 1, :) = [rangI(L(l, 1)), rangI(L(l, 2)), L(l, 3), L(l, 4)]; %#ok<AGROW>
    end
    % une entrée par source extérieure distincte, une sortie par source
    % intérieure qui sort
    entrants = find(~sa & sb).';
    sortants = find(sa & ~sb).';
    sourcesE = unique(L(entrants, [1 4]), 'rows', 'stable');
    sourcesS = unique(L(sortants, [1 4]), 'rows', 'stable');
    nomsI = cellfun(@(b) char(b.nom), I.blocs, 'UniformOutput', false);
    for e = 1:size(sourcesE, 1)
        nomPort = nomLibre(nomsI, sprintf('In%d', e));
        nomsI{end + 1} = nomPort; %#ok<AGROW>
        I = add_block(I, 'inport', nomPort, 'Port', e);
        r = numel(I.blocs);
        for l = entrants
            if isequal(L(l, [1 4]), sourcesE(e, :))
                LI(end + 1, :) = [r, rangI(L(l, 2)), L(l, 3), 1]; %#ok<AGROW>
            end
        end
    end
    for s = 1:size(sourcesS, 1)
        nomPort = nomLibre(nomsI, sprintf('Out%d', s));
        nomsI{end + 1} = nomPort; %#ok<AGROW>
        I = add_block(I, 'outport', nomPort, 'Port', s);
        LI(end + 1, :) = [rangI(sourcesS(s, 1)), numel(I.blocs), 1, sourcesS(s, 2)]; %#ok<AGROW>
    end
    I.liens = LI;
    if isfield(P, 'connexions') && ~isempty(P.connexions)
        C = P.connexions;
        dedans = sel(C(:, 1)) & sel(C(:, 3));
        if any(dedans)
            I.connexions = [rangI(C(dedans, 1)).', C(dedans, 2), rangI(C(dedans, 3)).', ...
                            C(dedans, 4)];
        end
    end
    % le schéma : les blocs choisis s'en vont, le sous-système vient au bout
    noms = cellfun(@(b) char(b.nom), P.blocs(~sel), 'UniformOutput', false);
    nomBloc = nomLibre(noms, nouveau);
    reste = find(~sel);
    rangP = zeros(1, n);
    rangP(reste) = 1:numel(reste);
    P.blocs = P.blocs(reste);
    P.blocs{end + 1} = struct('type', 'subsystem', 'nom', nomBloc, ...
                              'parametres', struct('Model', I));
    k = numel(P.blocs);
    NL = zeros(0, 4);
    for l = find(~sa & ~sb).'
        NL(end + 1, :) = [rangP(L(l, 1)), rangP(L(l, 2)), L(l, 3), L(l, 4)]; %#ok<AGROW>
    end
    for e = 1:size(sourcesE, 1)
        NL(end + 1, :) = [rangP(sourcesE(e, 1)), k, e, sourcesE(e, 2)]; %#ok<AGROW>
    end
    for s = 1:size(sourcesS, 1)
        for l = sortants
            if isequal(L(l, [1 4]), sourcesS(s, :))
                NL(end + 1, :) = [k, rangP(L(l, 2)), L(l, 3), s]; %#ok<AGROW>
            end
        end
    end
    P.liens = NL;
    if isfield(P, 'connexions') && ~isempty(P.connexions)
        C = P.connexions;
        dehors = ~sel(C(:, 1)) & ~sel(C(:, 3));
        P.connexions = [rangP(C(dehors, 1)).', C(dehors, 2), rangP(C(dehors, 3)).', ...
                        C(dehors, 4)];
    end
end

% --- ranger -------------------------------------------------------------------

% Chaque bloc prend une place, par couches : une source à gauche, un bloc
% une couche après la plus lointaine de celles qui l'alimentent — une
% boucle ne fait pas avancer —, les blocs d'une couche les uns sous les
% autres.
function s = ranger(s)
    n = numel(s.blocs);
    if n == 0
        return
    end
    L = matlibre_sl_liens(s);
    couche = zeros(1, n);
    for tour = 1:n
        change = false;
        for l = 1:size(L, 1)
            a = L(l, 1);
            b = L(l, 2);
            if a ~= b && couche(b) < couche(a) + 1 && couche(a) + 1 < n
                couche(b) = couche(a) + 1;
                change = true;
            end
        end
        if ~change
            break
        end
    end
    ligne = zeros(1, max(couche) + 1);
    for k = 1:n
        c = couche(k) + 1;
        x = 40 + 140 * couche(k);
        y = 40 + 90 * ligne(c);
        ligne(c) = ligne(c) + 1;
        s.blocs{k}.parametres.Position = [x, y, x + 60, y + 40];
    end
end

% Les blocs d'un type — Inport, Outport — dans l'ordre de leur paramètre
% Port.
function rangs = rangsParPort(I, types, type)
    rangs = find(strcmp(types, type));
    ports = zeros(size(rangs));
    for i = 1:numel(rangs)
        p = I.blocs{rangs(i)}.parametres;
        ports(i) = i;
        if isfield(p, 'Port')
            ports(i) = double(p.Port);
        end
    end
    [~, ordre] = sort(ports);
    rangs = rangs(ordre);
end

function t = typeDe(type)
    try
        entree = matlibre_sl_catalogue('type', type);
        t = entree.type;
    catch
        t = char(type);
    end
end

% Un nom que le système ne porte pas encore : BASE, sinon BASE1, BASE2...
function nom = nomLibre(noms, base)
    nom = base;
    if ~any(strcmp(noms, nom))
        return
    end
    racine = regexprep(base, '\d+$', '');
    k = 1;
    while any(strcmp(noms, sprintf('%s%d', racine, k)))
        k = k + 1;
    end
    nom = sprintf('%s%d', racine, k);
end
