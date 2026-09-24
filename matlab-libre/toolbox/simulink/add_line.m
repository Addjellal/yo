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
%   sur cette lecture.
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
    error('simulink:add_line:unknownBlock', 'Unknown block ''%s'' (%s du lien).', ...
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

function oui = estSousSysteme(bloc)
    try
        entree = matlibre_sl_catalogue('type', bloc.type);
        oui = strcmp(entree.type, 'subsystem');
    catch
        oui = false;
    end
end
