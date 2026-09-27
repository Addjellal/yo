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
%
%   GET_PARAM(MODELE,'ModelWorkspace') rend l'espace de travail du modèle,
%   un Simulink.ModelWorkspace, dont les variables passent avant celles de
%   l'espace de base.
%
%   GET_PARAM(MODELE,'Reglage') rend un réglage du modèle : Name, Blocks,
%   et ceux de la boîte « Paramètres de configuration » — StopTime,
%   Solver, FixedStep... —, avec leur valeur par défaut quand on ne les a
%   pas posés. Un réglage posé par ADD_PARAM se lit de même.
%
%   GET_PARAM(MODELE,H,'Reglage'), H une poignée de port, rend un réglage
%   du signal qui part de ce port — Name, DataLogging... — ou PortType,
%   PortNumber, Parent.
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
    if isempty(canon)
        error('Simulink:Commands:ParamUnknown', ...
              'Le bloc ''%s'' n''a pas de paramètre ''%s''.', feuille, champ);
    end
    if isfield(bloc.parametres, canon)
        valeur = bloc.parametres.(canon);
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
