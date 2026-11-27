function modele = add_line(modele, source, destination, entree, sortie)
%ADD_LINE Relie une sortie d'un bloc à une entrée d'un autre.
%   MODELE = ADD_LINE(MODELE,'source','destination') relie la première
%   sortie du premier bloc à la première entrée du second.
%   ADD_LINE(MODELE,'source','destination',E) choisit l'entrée, ce qui
%   importe pour une sommation dont les signes diffèrent.
%   ADD_LINE(MODELE,'source','destination',E,S) choisit en plus la sortie
%   de la source : un Demux, un sous-système ou un sinus-cosinus en ont
%   plusieurs.
%
%   La syntaxe de Simulink est acceptée : ADD_LINE(MODELE,'demux/2',
%   'scope/1') relie la deuxième sortie du Demux à la première entrée du
%   Scope. Un bloc dont le nom lui-même se termine par « /n » l'emporte
%   sur cette lecture. Les ports de contrôle d'un sous-système
%   conditionnel se désignent par leur nom : 'sous/Enable',
%   'sous/Trigger', 'sous/Ifaction', 'sous/Reset' ; ce sont ses entrées
%   qui suivent celles de ses blocs INPORT. Le port d'état d'un intégrateur
%   (ShowStatePort à 'on') se désigne de même, 'integrateur/State' : c'est
%   sa dernière sortie.
%
%   Une sortie peut alimenter plusieurs entrées : il suffit de plusieurs
%   liens. Une entrée, non : un second lien vers une entrée déjà reliée
%   est refusé, comme dans Simulink. Un port qui n'existe pas l'est aussi.
%
%   Les ports physiques d'un réseau Simscape se désignent par leur nom,
%   LConn1, LConn2… à gauche et RConn1… à droite : ADD_LINE(MODELE,
%   'R1/RConn1','C1/LConn1') les relie. Une connexion physique n'a pas de
%   sens : les deux ports, et tous ceux qu'on relie à eux, font un même
%   nœud. Un port physique ne se relie qu'à un port physique.
%
%   Une boucle peut passer par un bloc à état — intégrateur, retard —, qui
%   la coupe. Une boucle qui n'en contient pas est algébrique : SIM la
%   résout à chaque pas, et le signale selon le réglage AlgebraicLoopMsg
%   du modèle.
%
%   La forme de MATLAB : H = ADD_LINE(SYSTEME,SORTIE,ENTREE), SYSTEME le nom
%   d'un modèle de la session ou le chemin d'un de ses sous-systèmes,
%   SORTIE et ENTREE des 'bloc/port', des poignées de port, ou des
%   cellules de l'un ou de l'autre ; elle rend la poignée de chaque ligne.
%   'autorouting' est accepté : le tracé se calcule de toute façon.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'consigne', 'Value', 1);
%      m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
%      m = add_block(m, 'gain', 'gain', 'Gain', 2);
%      m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);   % le retour
%      m = add_line(m, 'erreur', 'gain');
%      m = add_line(m, 'gain', 'sortie');
%
%   Voir aussi ADD_BLOCK, DELETE_LINE, NEW_SYSTEM, SIM.
    % La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
    if ~isstruct(modele)
        arguments = {modele};
        if nargin >= 2, arguments{end + 1} = source; end
        if nargin >= 3, arguments{end + 1} = destination; end
        if nargin >= 4, arguments{end + 1} = entree; end
        if nargin >= 5, arguments{end + 1} = sortie; end
        ligne = matlibre_sl_nomme('add_line', nargout, arguments{:});
        clear modele
        if nargout > 0
            modele = ligne;
        end
        return
    end
    if estPhysique(source) || estPhysique(destination)
        modele = lienPhysique(modele, source, destination);
        return
    end
    [a, portSortie] = designer(modele, source, 'source');
    [b, portEntree] = designer(modele, destination, 'destination');
    if nargin >= 4 && ~isempty(entree)
        portEntree = entree;
    end
    if nargin >= 5 && ~isempty(sortie)
        portSortie = sortie;
    end
    portEntree = numeroDePort(portEntree, 'input');
    portSortie = numeroDePort(portSortie, 'output');

    nomModele = '';
    if isfield(modele, 'nom'), nomModele = char(modele.nom); end
    chemin = @(k) cheminBloc(nomModele, modele.blocs{k}.nom);

    % Le port doit exister, quand les parametres du bloc le disent deja.
    % Pour un sous-systeme, ce sont ses blocs INPORT et OUTPORT qui font ses
    % ports : l'erreur le dit.
    [~, nsA] = matlibre_sl_ports(modele.blocs{a});
    if ~isnan(nsA) && portSortie > nsA && estSousSysteme(modele.blocs{a})
        error('Simulink:Commands:SousSystemeSortieAbsente', ...
              ['A line starts at output %d of subsystem ''%s'', which has only %d ' ...
               'Outport block(s).'], portSortie, chemin(a), nsA);
    end
    if ~isnan(nsA) && portSortie > nsA
        if nsA == 0
            error('Simulink:Commands:AddLineInvalidPort', ...
                  'Block ''%s'' has no output port: no line can start from it.', ...
                  chemin(a));
        end
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Block ''%s'' has only %d output port(s); the line starts at port %d.', ...
              chemin(a), nsA, portSortie);
    end
    [neB, ~] = matlibre_sl_ports(modele.blocs{b});
    if ~isnan(neB) && portEntree > neB && estSousSysteme(modele.blocs{b})
        error('Simulink:Commands:SousSystemeEntreeAbsente', ...
              ['Subsystem ''%s'' receives a line on input %d, but it has only ' ...
               '%d Inport block(s).'], chemin(b), portEntree, neB);
    end
    if ~isnan(neB) && portEntree > neB
        if neB == 0
            error('Simulink:Commands:AddLineInvalidPort', ...
                  'Block ''%s'' has no input port: it is a source.', chemin(b));
        end
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Block ''%s'' has only %d input port(s); the line ends at port %d.', ...
              chemin(b), neB, portEntree);
    end

    % Une entree ne recoit qu'un signal : le second lien aurait ecrase le
    % premier en silence.
    liens = matlibre_sl_liens(modele);
    if any(liens(:, 2) == b & liens(:, 3) == portEntree)
        error('Simulink:Commands:AddLineDestConnected', ...
              ['Input port %d of ''%s'' is already connected: an input port ' ...
               'receives only one signal. DELETE_LINE removes the existing line.'], ...
              portEntree, chemin(b));
    end
    modele.liens = [liens; a, b, portEntree, portSortie];
end

% Un port physique : « bloc/LConn1 », « bloc/RConn2 ».
function oui = estPhysique(texte)
    oui = (ischar(texte) || isstring(texte)) && ...
          ~isempty(regexp(char(texte), '/(LConn|RConn)\d+$', 'once', 'ignorecase'));
end

function modele = lienPhysique(modele, source, destination)
    [a, pa] = portPhysique(modele, source, destination);
    [b, pb] = portPhysique(modele, destination, source);
    nomModele = '';
    if isfield(modele, 'nom'), nomModele = char(modele.nom); end
    if a == b && pa == pb
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Port ''%s'' cannot be connected to itself.', char(source));
    end
    % deux ports d'un même domaine : un courant ne pousse pas une masse
    domaineA = matlibre_sl_physique('domaine', typeCanonique(modele.blocs{a}.type), pa);
    domaineB = matlibre_sl_physique('domaine', typeCanonique(modele.blocs{b}.type), pb);
    if ~isempty(domaineA) && ~isempty(domaineB) && ~strcmp(domaineA, domaineB)
        error('Simulink:Commands:AddLinePhysicalDomain', ...
              ['Port ''%s'' is in the %s domain, and ''%s'' in the %s domain: only ports ' ...
               'of the same domain can be connected. A converter (Rotational ' ...
               'Electromechanical Converter) bridges them.'], char(source), ...
              domaineA, char(destination), domaineB);
    end
    connexions = zeros(0, 4);
    if isfield(modele, 'connexions') && ~isempty(modele.connexions)
        connexions = modele.connexions;
    end
    deja = (connexions(:, 1) == a & connexions(:, 2) == pa & connexions(:, 3) == b & ...
            connexions(:, 4) == pb) | (connexions(:, 1) == b & connexions(:, 2) == pb & ...
            connexions(:, 3) == a & connexions(:, 4) == pa);
    if any(deja)
        error('Simulink:Commands:AddLineDestConnected', ...
              'Ports ''%s'' and ''%s'' of ''%s'' are already connected.', char(source), ...
              char(destination), nomModele);
    end
    modele.connexions = [connexions; a, pa, b, pb];
end

function type = typeCanonique(type)
    entree = matlibre_sl_catalogue('type', type);
    if ~isempty(entree)
        type = entree.type;
    end
end

% Le bloc et le port physique que désigne « bloc/LConn1 » : +1, ou -1 pour
% RConn1. Un port de signal en face d'un port physique est refusé.
function [k, port] = portPhysique(modele, texte, autre)
    texte = char(texte);
    jetons = regexp(texte, '^(.*)/(LConn|RConn)(\d+)$', 'tokens', 'once', 'ignorecase');
    if isempty(jetons)
        error('Simulink:Commands:AddLinePhysicalPort', ...
              ['''%s'' is a signal port, and ''%s'' a physical port: a physical port ' ...
               '(LConn, RConn) connects only to a physical port. Use a ' ...
               'Simulink-PS Converter or a PS-Simulink Converter.'], texte, char(autre));
    end
    k = chercher(modele, jetons{1});
    if k == 0
        error('Simulink:Commands:InvSimulinkObjectName', ['Invalid Simulink object name: ' ...
              'no block is named ''%s''.'], jetons{1});
    end
    cheminBloc = jetons{1};
    if isfield(modele, 'nom') && ~isempty(modele.nom)
        cheminBloc = [char(modele.nom) '/' jetons{1}];
    end
    type = modele.blocs{k}.type;
    entree = matlibre_sl_catalogue('type', type);
    if ~isempty(entree)
        type = entree.type;
    end
    [g, d] = matlibre_sl_physique('ports', type);
    numero = str2double(jetons{3});
    gauche = strcmpi(jetons{2}, 'LConn');
    disponibles = d;
    cote = 'a droite (RConn)';
    if gauche
        disponibles = g;
        cote = 'a gauche (LConn)';
    end
    if numero < 1 || numero > disponibles
        if g + d == 0
            error('Simulink:Commands:AddLineInvalidPort', ...
                  ['Block ''%s'' has no physical port: it is not a ' ...
                   'Simscape block.'], cheminBloc);
        end
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Block ''%s'' has %d %s physical port(s); the line targets port %d.', ...
              cheminBloc, disponibles, cote, numero);
    end
    port = numero;
    if ~gauche
        port = -numero;
    end
end

% « nom » ou « nom/port ». Le nom exact d'un bloc l'emporte : un bloc peut
% s'appeler « a/2 ».
function [k, port] = designer(modele, texte, role)
    texte = char(texte);
    port = 1;
    k = chercher(modele, texte);
    if k > 0
        return
    end
    jetons = regexp(texte, '^(.*)/(\d+)$', 'tokens', 'once');
    if ~isempty(jetons)
        k = chercher(modele, jetons{1});
        if k > 0
            port = str2double(jetons{2});
            return
        end
    end
    jetons = regexp(texte, '^(.*)/State$', 'tokens', 'once', 'ignorecase');
    if ~isempty(jetons) && strcmp(role, 'source')
        k = chercher(modele, jetons{1});
        if k > 0
            port = portEtat(modele.blocs{k});
            return
        end
    end
    jetons = regexp(texte, '^(.*)/(Enable|Trigger|Ifaction|Reset)$', 'tokens', 'once', ...
                    'ignorecase');
    if ~isempty(jetons) && strcmp(role, 'destination')
        k = chercher(modele, jetons{1});
        if k > 0
            port = portDeControle(modele.blocs{k}, jetons{2}, texte);
            return
        end
    end
    error('Simulink:Commands:InvSimulinkObjectName', ['Invalid Simulink object name: ' ...
           'no block is named ''%s'' (%s of the line).'], ...
          texte, role);
end

function k = chercher(modele, nom)
    k = 0;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            k = i;
            return
        end
    end
end

function p = numeroDePort(p, quoi)
    if ~(isnumeric(p) && isscalar(p) && p >= 1 && p == round(p))
        error('Simulink:Commands:AddLineInvalidPort', ...
              'A %s port number must be a positive integer.', quoi);
    end
    p = double(p);
end

function c = cheminBloc(modele, bloc)
    if isempty(modele)
        c = char(bloc);
    else
        c = [modele '/' char(bloc)];
    end
end

% Le rang d'un port de contrôle parmi les entrées d'un sous-système : après
% ses INPORT, Enable puis Trigger, ou Action Port.
function port = portDeControle(bloc, nom, texte)
    if ~estSousSysteme(bloc)
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Block ''%s'' is not a subsystem: it has no %s port.', ...
              char(bloc.nom), nom);
    end
    interne = [];
    if isfield(bloc.parametres, 'Model')
        interne = matlibre_sl_modele(bloc.parametres.Model);
    elseif isfield(bloc.parametres, 'Modele')
        interne = matlibre_sl_modele(bloc.parametres.Modele);
    end
    types = {};
    if ~isempty(interne)
        types = cellfun(@(b) typeCanonique(b.type), interne.blocs, 'UniformOutput', false);
    end
    ordre = {};
    for candidat = {'enableport', 'triggerport', 'actionport', 'resetport'}
        if any(strcmp(types, candidat{1}))
            ordre{end + 1} = candidat{1}; %#ok<AGROW>
        end
    end
    voulu = struct('enable', 'enableport', 'trigger', 'triggerport', 'ifaction', 'actionport', ...
                   'reset', 'resetport');
    rang = find(strcmp(ordre, voulu.(lower(nom))), 1);
    if isempty(rang)
        error('Simulink:Commands:AddLineInvalidPort', ...
              ['Subsystem ''%s'' has no %s port: add a %s block ' ...
               '(''%s'') to it.'], char(bloc.nom), nom, ...
              strrep(voulu.(lower(nom)), 'port', ' port'), texte);
    end
    port = sum(strcmp(types, 'inport')) + rang;
end

% Le port d'état d'un intégrateur est sa dernière sortie, s'il le montre.
function port = portEtat(bloc)
    montre = false;
    if strcmp(typeCanonique(bloc.type), 'integrator')
        for champ = fieldnames(bloc.parametres).'
            if strcmpi(champ{1}, 'ShowStatePort')
                montre = strcmpi(char(bloc.parametres.(champ{1})), 'on');
            end
        end
    end
    if ~montre
        error('Simulink:Commands:AddLineInvalidPort', ...
              ['Block ''%s'' has no state port: only an Integrator whose ' ...
               'ShowStatePort is ''on'' shows one.'], char(bloc.nom));
    end
    [~, port] = matlibre_sl_ports(bloc);
end

function t = typeCanonique(type)
    try
        entree = matlibre_sl_catalogue('type', type);
        t = entree.type;
    catch
        t = lower(char(type));
    end
end

function oui = estSousSysteme(bloc)
    try
        entree = matlibre_sl_catalogue('type', bloc.type);
        oui = strcmp(entree.type, 'subsystem');
    catch
        oui = false;
    end
end
