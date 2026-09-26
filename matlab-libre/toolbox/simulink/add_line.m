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
%   'sous/Trigger', 'sous/Ifaction' ; ce sont ses entrées qui suivent
%   celles de ses blocs INPORT. Le port d'état d'un intégrateur
%   (ShowStatePort à 'on') se désigne de même, 'integrateur/State' : c'est
%   sa dernière sortie.
%
%   Une sortie peut alimenter plusieurs entrées : il suffit de plusieurs
%   liens. Une entrée, non : un second lien vers une entrée déjà reliée
%   est refusé, comme dans Simulink. Un port qui n'existe pas l'est aussi.
%
%   Une boucle peut passer par un bloc à état — intégrateur, retard —, qui
%   la coupe. Une boucle qui n'en contient pas est algébrique : SIM la
%   résout à chaque pas, et le signale selon le réglage AlgebraicLoopMsg
%   du modèle.
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
    [a, portSortie] = designer(modele, source, 'source');
    [b, portEntree] = designer(modele, destination, 'destination');
    if nargin >= 4 && ~isempty(entree)
        portEntree = entree;
    end
    if nargin >= 5 && ~isempty(sortie)
        portSortie = sortie;
    end
    portEntree = numeroDePort(portEntree, 'd''entree');
    portSortie = numeroDePort(portSortie, 'de sortie');

    nomModele = '';
    if isfield(modele, 'nom'), nomModele = char(modele.nom); end
    chemin = @(k) cheminBloc(nomModele, modele.blocs{k}.nom);

    % Le port doit exister, quand les parametres du bloc le disent deja.
    % Pour un sous-systeme, ce sont ses blocs INPORT et OUTPORT qui font ses
    % ports : l'erreur le dit.
    [~, nsA] = matlibre_sl_ports(modele.blocs{a});
    if ~isnan(nsA) && portSortie > nsA && estSousSysteme(modele.blocs{a})
        error('Simulink:Commands:SousSystemeSortieAbsente', ...
              ['Un lien part de la sortie %d du sous-systeme ''%s'', qui n''a que %d ' ...
               'bloc(s) OUTPORT.'], portSortie, chemin(a), nsA);
    end
    if ~isnan(nsA) && portSortie > nsA
        if nsA == 0
            error('Simulink:Commands:AddLineInvalidPort', ...
                  'Le bloc ''%s'' n''a pas de port de sortie : on ne tire pas de fil depuis lui.', ...
                  chemin(a));
        end
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Le bloc ''%s'' n''a que %d port(s) de sortie ; le lien part du port %d.', ...
              chemin(a), nsA, portSortie);
    end
    [neB, ~] = matlibre_sl_ports(modele.blocs{b});
    if ~isnan(neB) && portEntree > neB && estSousSysteme(modele.blocs{b})
        error('Simulink:Commands:SousSystemeEntreeAbsente', ...
              ['Le sous-systeme ''%s'' recoit un lien sur son entree %d, mais il n''a ' ...
               'que %d bloc(s) INPORT.'], chemin(b), portEntree, neB);
    end
    if ~isnan(neB) && portEntree > neB
        if neB == 0
            error('Simulink:Commands:AddLineInvalidPort', ...
                  'Le bloc ''%s'' n''a pas de port d''entree : c''est une source.', chemin(b));
        end
        error('Simulink:Commands:AddLineInvalidPort', ...
              'Le bloc ''%s'' n''a que %d port(s) d''entree ; le lien arrive sur le port %d.', ...
              chemin(b), neB, portEntree);
    end

    % Une entree ne recoit qu'un signal : le second lien aurait ecrase le
    % premier en silence.
    liens = matlibre_sl_liens(modele);
    if any(liens(:, 2) == b & liens(:, 3) == portEntree)
        error('Simulink:Commands:AddLineDestConnected', ...
              ['Le port d''entree %d de ''%s'' est deja relie : une entree ne ' ...
               'recoit qu''un signal. DELETE_LINE retire le lien existant.'], ...
              portEntree, chemin(b));
    end
    modele.liens = [liens; a, b, portEntree, portSortie];
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
    jetons = regexp(texte, '^(.*)/(Enable|Trigger|Ifaction)$', 'tokens', 'once', ...
                    'ignorecase');
    if ~isempty(jetons) && strcmp(role, 'destination')
        k = chercher(modele, jetons{1});
        if k > 0
            port = portDeControle(modele.blocs{k}, jetons{2}, texte);
            return
        end
    end
    error('Simulink:Commands:InvSimulinkObjectName', ['Nom d''objet Simulink invalide : ' ...
           'aucun bloc ne s''appelle ''%s'' (%s du lien).'], ...
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
              'Un numero de port %s est un entier positif.', quoi);
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
              'Le bloc ''%s'' n''est pas un sous-systeme : il n''a pas de port %s.', ...
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
    for candidat = {'enableport', 'triggerport', 'actionport'}
        if any(strcmp(types, candidat{1}))
            ordre{end + 1} = candidat{1}; %#ok<AGROW>
        end
    end
    voulu = struct('enable', 'enableport', 'trigger', 'triggerport', 'ifaction', 'actionport');
    rang = find(strcmp(ordre, voulu.(lower(nom))), 1);
    if isempty(rang)
        error('Simulink:Commands:AddLineInvalidPort', ...
              ['Le sous-systeme ''%s'' n''a pas de port %s : posez-y un bloc %s ' ...
               '(''%s'').'], char(bloc.nom), nom, ...
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
              ['Le bloc ''%s'' n''a pas de port d''etat : seul un integrateur dont ' ...
               'ShowStatePort vaut ''on'' en montre un.'], char(bloc.nom));
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
