function [modele, change] = matlibre_sl_commentes(modele, interieur)
%MATLIBRE_SL_COMMENTES Retire du modèle les blocs mis en commentaire.
%   [MODELE,CHANGE] = MATLIBRE_SL_COMMENTES(MODELE) rend le modèle tel que
%   Simulink le calcule quand des blocs portent le réglage Commented :
%     'on'       le bloc n'existe plus : ce qu'il alimentait lit zéro,
%                comme d'un Ground
%     'through'  le bloc est traversé : chaque sortie rend l'entrée de
%                même rang. Il lui faut autant d'entrées que de sorties.
%   Un sous-système commenté part avec tout ce qu'il contient ; les blocs
%   commentés d'un sous-système qui reste sont retirés de même. Un modèle
%   sans bloc commenté est rendu tel quel, et CHANGE est faux.
%
%   MATLIBRE_SL_APLATIR l'appelle d'abord : SIM, LINMOD, TRIM et la
%   compilation ne voient donc jamais un bloc commenté. GET_PARAM,
%   FIND_SYSTEM et OPEN_SYSTEM, eux, le voient toujours : il est dans le
%   modèle, il ne calcule pas.
%
%   Un bloc de port d'un sous-système — Inport, Outport, Enable,
%   Trigger... — ne se commente pas : il emporterait un port du
%   sous-système, et les liens qui y tiennent. Ceux du modèle le peuvent :
%   l'entrée commentée vaut zéro, la sortie commentée n'est plus une
%   sortie.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'constant', 'c', 'Value', 3);
%      m = add_block(m, 'gain', 'g', 'Gain', 2, 'Commented', 'through');
%      m = add_block(m, 'outport', 'y');
%      m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
%      numel(matlibre_sl_commentes(m).blocs)     % 2 : le gain est traversé
%      r = sim(m, 'StopTime', 1);
%      r.yout(end)                               % 3, non 6
%
%   Voir aussi MATLIBRE_SL_APLATIR, SET_PARAM, SIM.
    if nargin < 2
        interieur = false;
    end
    change = false;
    if ~isfield(modele, 'blocs') || isempty(modele.blocs)
        return
    end
    % L'intérieur des sous-systèmes qui restent, d'abord ; et le constat,
    % au passage, qu'il y a ou non quelque chose à retirer ici.
    aRetirer = false;
    for k = 1:numel(modele.blocs)
        b = modele.blocs{k};
        if ~isfield(b, 'parametres') || ~isstruct(b.parametres)
            continue
        end
        if ~strcmp(etat(b, modele), 'off')
            aRetirer = true;
            continue
        end
        for champ = {'Model', 'Modele'}
            if isfield(b.parametres, champ{1}) && isstruct(b.parametres.(champ{1})) && ...
               isfield(b.parametres.(champ{1}), 'blocs')
                [reduit, sousChange] = matlibre_sl_commentes(b.parametres.(champ{1}), true);
                if sousChange
                    modele.blocs{k}.parametres.(champ{1}) = reduit;
                    change = true;
                end
            end
        end
    end
    if ~aRetirer
        return
    end
    change = true;
    liens = matlibre_sl_liens(modele);
    k = 1;
    while k <= numel(modele.blocs)
        b = modele.blocs{k};
        e = 'off';
        if isfield(b, 'parametres') && isstruct(b.parametres)
            e = etat(b, modele);
        end
        if strcmp(e, 'off')
            k = k + 1;
            continue
        end
        if interieur && estPort(b)
            error('Simulink:Commands:CommentPortBlock', ...
                  ['Le bloc ''%s'' est un port du sous-systeme ''%s'' : il ne se commente ' ...
                   'pas, il emporterait le port et les liens qui y tiennent. Commentez ce ' ...
                   'qu''il alimente, ou le sous-systeme entier.'], char(b.nom), char(modele.nom));
        end
        entrants = find(liens(:, 2) == k);
        if strcmp(e, 'through')
            [ne, ns] = matlibre_sl_ports(b);
            if ~(ne == ns)
                error('Simulink:Commands:CommentThroughPorts', ...
                      ['Le bloc ''%s'' du modele ''%s'' ne se traverse pas (Commented ' ...
                       '''through'') : il lui faudrait autant d''entrees que de sorties, et ' ...
                       'il a %g entree(s) pour %g sortie(s).'], char(b.nom), ...
                      char(modele.nom), ne, ns);
            end
        end
        for r = find(liens(:, 1) == k).'
            source = [];
            if strcmp(e, 'through')
                i = entrants(liens(entrants, 3) == liens(r, 4));
                if ~isempty(i) && liens(i(1), 1) ~= k
                    source = liens(i(1), [1 4]);
                end
            end
            if isempty(source)
                % plus rien n'alimente cette entrée : un Ground, zéro
                modele.blocs{end + 1} = struct('type', 'ground', ...
                                               'nom', nomLibre(modele, b.nom), ...
                                               'parametres', struct());
                source = [numel(modele.blocs), 1];
            end
            liens(r, 1) = source(1);
            liens(r, 4) = source(2);
        end
        liens(liens(:, 2) == k, :) = [];
        modele.liens = liens;
        modele = delete_block(modele, b.nom);
        liens = matlibre_sl_liens(modele);
    end
end

% 'off', 'on' ou 'through' : ce que dit le réglage Commented du bloc.
function e = etat(b, modele)
    e = 'off';
    if ~isfield(b.parametres, 'Commented')
        return
    end
    v = b.parametres.Commented;
    if (ischar(v) || (isstring(v) && isscalar(v))) && ...
       any(strcmpi(char(v), {'off', 'on', 'through'}))
        e = lower(char(v));
        return
    end
    error('Simulink:Commands:InvalidCommented', ...
          ['Le reglage Commented du bloc ''%s'' du modele ''%s'' vaut ''off'', ''on'' ou ' ...
           '''through''.'], char(b.nom), char(modele.nom));
end

function oui = estPort(b)
    oui = false;
    try
        entree = matlibre_sl_catalogue('type', b.type);
    catch
        return
    end
    oui = any(strcmp(entree.type, {'inport', 'outport', 'enableport', 'triggerport', ...
                                   'resetport', 'actionport', 'foreach', 'foriterator', ...
                                   'whileiterator'}));
end

function nom = nomLibre(modele, pour)
    pris = cellfun(@(x) char(x.nom), modele.blocs, 'UniformOutput', false);
    n = 1;
    nom = sprintf('%s (commente) %d', char(pour), n);
    while any(strcmp(pris, nom))
        n = n + 1;
        nom = sprintf('%s (commente) %d', char(pour), n);
    end
end
