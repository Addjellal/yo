function modele = set_param(modele, nom, varargin)
%SET_PARAM Modifie les paramètres d'un bloc, ou les réglages du modèle.
%   MODELE = SET_PARAM(MODELE,BLOC,'Param',VALEUR,...) change un ou
%   plusieurs paramètres du bloc nommé, sans toucher aux autres ni au
%   câblage. BLOC est le nom du bloc, ou son chemin « modele/bloc » ; un
%   chemin « sousSysteme/bloc » descend dans un sous-système.
%
%   C'est ainsi qu'on balaie un réglage : construire le modèle une fois,
%   puis le simuler pour chaque valeur d'un gain ou d'une condition
%   initiale.
%
%   Les noms de paramètres reconnus sont ceux qu'ADD_BLOCK décrit, par
%   type de bloc ; la casse est indifférente, et les noms de Simulink
%   valent pour ceux de MatLibre. Un nom que le bloc n'a pas est refusé
%   en le nommant : rangé, il ne serait lu par personne. 'BlockType' ne
%   se change pas — REPLACE_BLOCK change le type d'un bloc.
%
%   'Name' fait exception : il renomme le bloc, comme dans Simulink, au
%   lieu de poser un réglage de ce nom. Sur un sous-système masqué, une
%   variable du masque (MaskVariables) se règle comme un paramètre. Les liens désignent les blocs par
%   leur rang, si bien que le câblage ne bouge pas.
%
%   MODELE = SET_PARAM(MODELE,'Reglage',VALEUR,...) — sans nom de bloc
%   devant, donc en nombre impair d'arguments — change les réglages du
%   modèle lui-même, ceux de la boîte « Paramètres de configuration » de
%   Simulink : StartTime, StopTime, Solver ('ode1' à 'ode5', 'ode8',
%   'ode14x', 'ode1be', 'FixedStepDiscrete' à pas fixe ; 'ode45', 'ode23',
%   'ode113', 'ode15s', 'ode23s', 'ode23t', 'ode23tb',
%   'VariableStepDiscrete' à pas variable), SolverType, FixedStep,
%   RelTol, AbsTol, MaxStep, MinStep, InitialStep, ZeroCrossControl,
%   AlgebraicLoopMsg, UnconnectedInputMsg, UnconnectedOutputMsg... La
%   valeur est vérifiée avant d'être posée : un solveur inconnu est
%   refusé en disant ceux qui existent. Le type suit le solveur. Un
%   réglage posé par ADD_PARAM se change de même.
%
%   Exemple :
%      m = new_system('boucle');
%      m = add_block(m, 'constant', 'consigne', 'Value', 1);
%      m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
%      m = add_block(m, 'gain', 'gain', 'Gain', 2);
%      m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
%      m = add_line(m, 'consigne', 'erreur', 1);
%      m = add_line(m, 'sortie', 'erreur', 2);
%      m = add_line(m, 'erreur', 'gain');
%      m = add_line(m, 'gain', 'sortie');
%      for K = [1 2 5]
%          m = set_param(m, 'gain', 'Gain', K);
%          r = sim(m, 5, 0.01);
%      end
%      m = set_param(m, 'gain', 'Name', 'correcteur');
%      get_param(m, 'correcteur', 'Gain')       % 5 : le bloc a change de nom
%      m = set_param(m, 'Solver', 'ode4', 'StopTime', 2);
%      get_param(m, 'Solver')                   % 'ode4'
%
%   Voir aussi GET_PARAM, ADD_PARAM, ADD_BLOCK, SIM, REPLACE_BLOCK.
    nom = char(nom);
    if mod(numel(varargin), 2) == 1
        modele = reglerModele(modele, [{nom}, varargin]);
        return
    end
    [parent, feuille] = decouper(modele, nom);
    if ~isempty(parent)
        interieur = matlibre_sl_dedans(modele, parent);
        interieur = set_param(interieur, feuille, varargin{:});
        modele = matlibre_sl_remplacer(modele, parent, interieur);
        return
    end
    i = trouver(modele, feuille);
    if i == 0
        error('simulink:set_param:unknownBlock', 'Unknown block ''%s''.', nom);
    end
    b = modele.blocs{i};
    entree = matlibre_sl_catalogue('type', b.type);
    for k = 1:2:numel(varargin) - 1
        champ = char(varargin{k});
        valeur = varargin{k + 1};
        if strcmpi(champ, 'Name')
            nouveau = char(valeur);
            j = trouver(modele, nouveau);
            if j ~= 0 && j ~= i
                error('Simulink:Commands:SetParamNameExists', ...
                      ['Le modele ''%s'' porte deja un bloc nomme ''%s'' : on ne peut ' ...
                       'pas lui donner ce nom.'], char(modele.nom), nouveau);
            end
            b.nom = nouveau;
            continue
        end
        if strcmpi(champ, 'BlockType') || strcmpi(champ, 'Type')
            error('Simulink:Commands:ParamReadOnly', ...
                  ['Le type d''un bloc ne se change pas par SET_PARAM : REPLACE_BLOCK ' ...
                   'le fait, en gardant le cablage.']);
        end
        % Une variable de masque est un paramètre du bloc masqué, comme
        % dans Simulink.
        variablesMasque = matlibre_sl_masque('variables', b);
        if any(strcmp(variablesMasque, champ))
            b = matlibre_sl_masque('poser', b, champ, valeur);
            continue
        end
        canon = matlibre_sl_catalogue('parametre', entree, champ);
        if isempty(canon)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le bloc ''%s'' (%s) n''a pas de parametre nomme ''%s''. Ses ' ...
                   'parametres sont : %s.'], b.nom, entree.affiche, champ, ...
                  strjoin(entree.params(:, 1).', ', '));
        end
        b.parametres.(canon) = valeur;
    end
    modele.blocs{i} = b;
end

% Les réglages du modèle, par couples. Un nom de la boîte de configuration
% est vérifié et rangé sous son écriture canonique ; un réglage posé par
% ADD_PARAM se change tel quel ; tout autre nom est refusé.
function modele = reglerModele(modele, couples)
    if ~isfield(modele, 'parametres') || isempty(modele.parametres)
        modele.parametres = struct();
    end
    for k = 1:2:numel(couples)
        nom = char(couples{k});
        valeur = couples{k + 1};
        if strcmpi(nom, 'Name')
            modele.nom = char(valeur);
            continue
        end
        if strcmpi(nom, 'SimulationCommand')
            commander(modele, valeur);
            continue
        end
        canon = matlibre_sl_config('nom', nom);
        if ~isempty(canon)
            modele.parametres.(canon) = matlibre_sl_config('valider', canon, valeur);
            % Le solveur et son type vont ensemble, comme dans Simulink :
            % le type suit le solveur, et un type qui ne convient plus au
            % solveur le remplace par le solveur automatique de ce type.
            if strcmp(canon, 'Solver') && isfield(modele.parametres, 'SolverType')
                modele.parametres.SolverType = matlibre_sl_config('type', ...
                                                                  modele.parametres.Solver);
            elseif strcmp(canon, 'SolverType')
                actuel = matlibre_sl_config('lire', modele);
                if ~strcmp(matlibre_sl_config('type', actuel.Solver), ...
                           modele.parametres.SolverType)
                    modele.parametres.Solver = matlibre_sl_config('automatique', ...
                                                                  modele.parametres.SolverType);
                end
            end
            continue
        end
        existant = '';
        champs = fieldnames(modele.parametres);
        for j = 1:numel(champs)
            if strcmpi(champs{j}, nom)
                existant = champs{j};
            end
        end
        if isempty(existant)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le modele ''%s'' n''a pas de reglage nomme ''%s''. Ses reglages ' ...
                   'sont : %s ; ADD_PARAM en pose un nouveau.'], char(modele.nom), nom, ...
                  strjoin(fieldnames(matlibre_sl_config('defauts')).', ', '));
        end
        modele.parametres.(existant) = valeur;
    end
end

% SimulationCommand, comme les boutons de Simulink : 'update' compile le
% modèle — ses erreurs et ses avertissements sortent —, 'start' le simule
% et dépose le résultat dans OUT ; les autres ne font rien quand aucune
% simulation ne tourne.
function commander(modele, commande)
    switch lower(char(commande))
        case 'update'
            matlibre_sl_compiler(modele, struct('config', matlibre_sl_config('lire', modele)));
        case 'start'
            resultat = sim(modele);
            config = matlibre_sl_config('lire', modele);
            assignin('base', char(config.ReturnWorkspaceOutputsName), resultat);
        case {'stop', 'pause', 'continue', 'step'}
        otherwise
            error('Simulink:Commands:SetParamInvalidArgumentValue', ...
                  ['SimulationCommand vaut update, start, stop, pause, continue ou ' ...
                   'step ; pas ''%s''.'], char(commande));
    end
end

% « bloc », « modele/bloc » ou « sousSysteme/bloc ». Le nom exact d'un
% bloc l'emporte : un bloc peut porter une barre dans son nom.
function [parent, feuille] = decouper(modele, nom)
    parent = '';
    feuille = nom;
    if trouver(modele, nom) ~= 0 || ~any(nom == '/')
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

function i = trouver(modele, nom)
    i = 0;
    for k = 1:numel(modele.blocs)
        if strcmp(modele.blocs{k}.nom, nom)
            i = k;
            return
        end
    end
end
