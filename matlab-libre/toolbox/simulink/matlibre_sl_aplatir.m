function modele = matlibre_sl_aplatir(modele)
%MATLIBRE_SL_APLATIR Déplie les sous-systèmes d'un modèle.
%   MODELE = MATLIBRE_SL_APLATIR(MODELE) rend le même modèle, où chaque
%   bloc de type « subsystem » a été remplacé par les blocs qu'il
%   contient. Un modèle sans sous-système est rendu tel quel.
%
%   C'est ainsi qu'un sous-système se simule : non pas comme un bloc à
%   part, mais comme le schéma qu'il abrège. SIM, LINMOD, TRIM et
%   MATLIBRE_SL_PROGRAMME appellent tous cette fonction d'abord, si bien
%   qu'aucun d'eux n'a besoin de savoir qu'un sous-système existe.
%
%   Le dépliage garde trois choses. Les blocs intérieurs prennent le nom
%   « sousSysteme/bloc », comme dans Simulink, et se retrouvent donc
%   nommés dans le relevé. Le bloc du sous-système lui-même ne
%   disparaît pas : il reste, en passe-plat à autant de ports qu'il a de
%   sorties, chaque OUTPORT intérieur alimentant la sortie de même rang
%   — un relevé pris sur le sous-système reste donc celui de sa première
%   sortie, et un lien qui partait de sa deuxième sortie part toujours de
%   la sortie de l'OUTPORT de rang 2. Et les entrées se raccordent par
%   leur rang : le lien qui arrivait sur la deuxième entrée du bloc
%   arrive sur le bloc INPORT intérieur dont le paramètre Port vaut 2.
%
%   Les types sont ramenés à leur nom MatLibre par le catalogue : un
%   bloc intérieur posé sous son nom Simulink (« In1 », « SubSystem »)
%   se déplie comme les autres. Les liens rendus ont quatre colonnes —
%   source, destination, entrée, sortie.
%
%   Les sous-systèmes s'emboîtent : un sous-système qui en contient un
%   autre est déplié jusqu'au bout.
%
%   Un sous-système qui porte un port de contrôle — Enable, Trigger, ou
%   Action Port — est conditionnel. Ses ports de contrôle sont des entrées
%   de plus, après les autres : Enable, puis Trigger ; ou Action Port. Le
%   dépliage fait de son premier port de contrôle une « garde », un bloc
%   qui dit à chaque pas si le sous-système calcule ; chaque bloc
%   intérieur en porte le rang dans son champ garde, et la compilation
%   le lit. Un sous-système emboîté dans un conditionnel en hérite. Les
%   OUTPORT intérieurs gardent leur valeur initiale et leur conduite à
%   l'arrêt (OutputWhenDisabled) dans le champ sortieConditionnelle.
%
%   Un sous-système itéré — qui porte un bloc For Iterator ou While
%   Iterator — ne se déplie pas : il calcule plusieurs fois par pas, ce
%   qu'un schéma à plat ne sait pas dire. Il devient un bloc « iterateur »
%   qui garde son modèle, et que la simulation fait tourner à part.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      interne = new_system('doubleur');
%      interne = add_block(interne, 'inport', 'e', 'Port', 1);
%      interne = add_block(interne, 'gain', 'deux', 'Gain', 2);
%      interne = add_block(interne, 'outport', 's', 'Port', 1);
%      interne = add_line(add_line(interne, 'e', 'deux'), 'deux', 's');
%      m = add_block(new_system('dehors'), 'constant', 'un', 'Value', 3);
%      m = add_block(m, 'subsystem', 'boite', 'Model', interne);
%      m = add_line(m, 'un', 'boite');
%      numel(matlibre_sl_aplatir(m).blocs)      % 5 : un, boite, e, deux, s
%
%   Voir aussi SIM, ADD_BLOCK, MATLIBRE_SL_ORDRE.
    modele = matlibre_sl_modele(modele);
    modele.liens = matlibre_sl_liens(modele);
    modele = rafraichirLiens(modele);
    for j = 1:numel(modele.blocs)
        modele.blocs{j}.type = typeCanonique(modele.blocs{j}.type);
    end
    % Un modèle ordinaire ne paie rien : le dépliage ne coûte que le
    % parcours qui constate qu'il n'y a rien à déplier.
    garde = 0;
    while true
        k = premier(modele);
        if k == 0
            return
        end
        garde = garde + 1;
        if garde > 1000
            error('Simulink:Commands:SousSystemeRecursif', ...
                  ['Le depliage des sous-systemes ne s''arrete pas : un ' ...
                   'sous-systeme se contient lui-meme, directement ou non.']);
        end
        modele = deplier(modele, k);
    end
end

% Un sous-système itéré reste un bloc : son modèle, dont chaque bloc garde
% l'espace du masque qui l'englobe, tourne à part. Un seul itérateur, et
% pas de port de contrôle, comme dans Simulink.
function iterateur = sousSystemeItere(bloc, interne, iterateurs, g)
    if numel(iterateurs) > 1
        error('Simulink:blocks:IteratorDuplicate', ...
              ['Le sous-systeme ''%s'' porte %d blocs d''iteration : un sous-systeme ' ...
               'itere n''en a qu''un.'], char(bloc.nom), numel(iterateurs));
    end
    if g > 0
        error('Simulink:blocks:IteratorWithControlPort', ...
              ['Le sous-systeme itere ''%s'' porte un port Enable, Trigger ou Action : ' ...
               'placez-le dans un sous-systeme conditionnel plutot.'], char(bloc.nom));
    end
    espace = struct();
    if isfield(bloc, 'espace')
        espace = bloc.espace;
    end
    if ~isempty(matlibre_sl_masque('variables', bloc))
        espace = matlibre_sl_masque('espace', bloc, espace, char(bloc.nom));
    end
    if ~isempty(fieldnames(espace))
        for j = 1:numel(interne.blocs)
            interne.blocs{j}.espace = espace;
        end
    end
    iterateur = bloc;
    iterateur.type = 'iterateur';
    iterateur.parametres = struct('Model', interne);
    if isfield(bloc.parametres, 'Position')
        iterateur.parametres.Position = bloc.parametres.Position;
    end
end

% Un bloc lié à une bibliothèque reprend ce qu'elle porte au moment de
% simuler : son type, ses paramètres, son contenu. Il garde son nom, et les
% valeurs qu'on a données à son masque. Une bibliothèque introuvable laisse
% la copie, en le disant.
function modele = rafraichirLiens(modele)
    for j = 1:numel(modele.blocs)
        bloc = modele.blocs{j};
        if ~isfield(bloc, 'reference') || isempty(bloc.reference)
            continue
        end
        barre = find(bloc.reference == '/', 1);
        source = [];
        try
            bibliotheque = matlibre_sl_modele(bloc.reference(1:barre - 1));
            chemin = bloc.reference(barre + 1:end);
            dernier = find(chemin == '/', 1, 'last');
            if ~isempty(dernier)
                bibliotheque = matlibre_sl_dedans(bibliotheque, chemin(1:dernier - 1));
                chemin = chemin(dernier + 1:end);
            end
            for k = 1:numel(bibliotheque.blocs)
                if strcmp(bibliotheque.blocs{k}.nom, chemin)
                    source = bibliotheque.blocs{k};
                end
            end
        catch
        end
        if isempty(source)
            warning('Simulink:Libraries:MissingSourceBlock', ...
                    ['Le bloc ''%s'' est lie a ''%s'', introuvable : sa copie sert a la ' ...
                     'place.'], char(bloc.nom), bloc.reference);
            continue
        end
        neuf = bloc;
        neuf.type = source.type;
        neuf.parametres = source.parametres;
        valeurs = matlibre_sl_masque('variables', bloc);
        if isfield(bloc.parametres, 'MaskValueString') && ...
           isequal(valeurs, matlibre_sl_masque('variables', neuf))
            neuf.parametres.MaskValueString = bloc.parametres.MaskValueString;
        end
        if isfield(bloc.parametres, 'Position')
            neuf.parametres.Position = bloc.parametres.Position;
        end
        modele.blocs{j} = neuf;
    end
end

% Le nom MatLibre d'un type, quelle que soit la façon dont on l'a écrit.
% Un type inconnu reste tel quel : c'est la compilation qui le refusera,
% en nommant le bloc par son chemin.
function t = typeCanonique(type)
    try
        entree = matlibre_sl_catalogue('type', type);
        t = entree.type;
    catch
        t = char(type);
    end
end

function k = premier(modele)
    k = 0;
    for j = 1:numel(modele.blocs)
        if any(strcmp(modele.blocs{j}.type, {'subsystem', 'modelreference'}))
            k = j;
            return
        end
    end
end

function modele = deplier(modele, k)
    bloc = modele.blocs{k};
    interne = contenu(bloc);
    interne.liens = matlibre_sl_liens(interne);
    interne = rafraichirLiens(interne);
    for j = 1:numel(interne.blocs)
        interne.blocs{j}.type = typeCanonique(interne.blocs{j}.type);
    end
    n = numel(modele.blocs);
    m = numel(interne.blocs);
    entrees = parRang(interne, 'inport');
    sorties = parRang(interne, 'outport');
    [controles, g] = portsDeControle(interne, bloc);
    gardeParent = 0;
    if isfield(bloc, 'garde')
        gardeParent = bloc.garde;
    end
    types = cellfun(@(b) b.type, interne.blocs, 'UniformOutput', false);
    iterateurs = find(ismember(types, {'foriterator', 'whileiterator'}));
    if ~isempty(iterateurs)
        modele.blocs{k} = sousSystemeItere(bloc, interne, iterateurs, g);
        return
    end
    % Un masque ouvre un espace : ses variables, évaluées dans l'espace de
    % celui qui l'englobe, valent pour tous les blocs du dedans.
    espaceParent = struct();
    if isfield(bloc, 'espace')
        espaceParent = bloc.espace;
    end
    espaceInterieur = espaceParent;
    if ~isempty(matlibre_sl_masque('variables', bloc))
        espaceInterieur = matlibre_sl_masque('espace', bloc, espaceParent, char(bloc.nom));
    end

    % Le bloc du sous-système garde sa place dans la liste — donc son
    % rang, donc tous les liens qui le désignent —, mais devient un
    % passe-plat : chacune de ses sorties portera la valeur de l'OUTPORT
    % intérieur de même rang.
    passePlat = bloc;
    passePlat.type = 'signalconversion';
    passePlat.parametres = struct();
    if numel(sorties) > 1
        passePlat.parametres.NombreDePorts = numel(sorties);
    end
    if isfield(bloc.parametres, 'Position')
        passePlat.parametres.Position = bloc.parametres.Position;
    end
    passePlat.garde = gardeParent;
    modele.blocs{k} = passePlat;

    % Les blocs intérieurs viennent à la suite, sous le nom
    % « sousSysteme/bloc ». Ils perdent leur place : elle était donnée
    % dans le repère du sous-système, et n'a pas de sens dans celui du
    % schéma qui l'abrège.
    for j = 1:m
        enfant = interne.blocs{j};
        enfant.nom = [char(bloc.nom) '/' char(enfant.nom)];
        if isfield(enfant.parametres, 'Position')
            enfant.parametres = rmfield(enfant.parametres, 'Position');
        end
        % Un bloc intérieur calcule sous la garde du sous-système, s'il est
        % conditionnel, sinon sous celle qui gardait le sous-système.
        enfant.garde = gardeParent;
        if g > 0 && ~any(j == controles.tous)
            enfant.garde = n + g;
        end
        if ~isempty(fieldnames(espaceInterieur))
            enfant.espace = espaceInterieur;
        end
        modele.blocs{n + j} = enfant;
    end
    if ~isempty(interne.liens)
        modele.liens = [modele.liens; ...
                        [interne.liens(:, 1) + n, interne.liens(:, 2) + n, ...
                         interne.liens(:, 3:4)]];
    end

    % Les bornes d'un sous-système sont les siennes, non celles du modèle
    % qui l'abrège : dépliées telles quelles, LINMOD et TRIM les auraient
    % prises pour des entrées et des sorties du schéma entier, et rendu
    % des matrices d'un ordre trop grand. On les rend donc passe-plat —
    % l'entrée que rien n'alimente devient la constante qu'elle valait,
    % ce que SIM lui faisait déjà rendre.
    for j = 1:numel(sorties)
        interieur = modele.blocs{n + sorties(j)};
        if g > 0
            % La sortie d'un sous-système conditionnel part de sa valeur
            % initiale, et y revient à l'arrêt si OutputWhenDisabled vaut
            % reset ; sinon elle tient la dernière.
            initiale = 0;
            if isfield(interieur.parametres, 'InitialOutput')
                initiale = interieur.parametres.InitialOutput;
            end
            revient = isfield(interieur.parametres, 'OutputWhenDisabled') && ...
                      strcmpi(char(interieur.parametres.OutputWhenDisabled), 'reset');
            modele.blocs{n + sorties(j)}.sortieConditionnelle = ...
                struct('initiale', {initiale}, 'revient', revient);
        end
        modele.blocs{n + sorties(j)}.type = 'signalconversion';
        modele.blocs{n + sorties(j)}.parametres = struct();
    end
    % Le premier port de contrôle devient la garde ; le Trigger d'un
    % sous-système qui a aussi un Enable devient le passe-plat de son
    % signal, que la garde lit en seconde entrée.
    if g > 0
        garde = modele.blocs{n + g};
        garde.type = 'garde';
        garde.parametres = parametresDeGarde(interne, controles);
        garde.garde = gardeParent;
        modele.blocs{n + g} = garde;
        if controles.enable > 0 && controles.trigger > 0
            declencheur = modele.blocs{n + controles.trigger};
            declencheur.type = 'signalconversion';
            declencheur.parametres = struct();
            modele.blocs{n + controles.trigger} = declencheur;
            modele.liens = [modele.liens; n + controles.trigger, n + g, 2, 1];
        end
    end
    for j = 1:numel(entrees)
        indice = n + entrees(j);
        valeur = 0;
        if isfield(modele.blocs{indice}.parametres, 'Value')
            valeur = modele.blocs{indice}.parametres.Value;
        end
        modele.blocs{indice}.type = 'constant';
        modele.blocs{indice}.parametres = struct('Value', {valeur});
    end

    % Chaque lien qui arrivait sur le bloc arrive à présent sur l'INPORT
    % de même rang, lequel cesse d'être une source pour devenir le
    % passe-plat de ce qu'on lui donne.
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 2) ~= k
            continue
        end
        port = modele.liens(l, 3);
        if port > numel(entrees) && port <= numel(entrees) + numel(controles.ordre)
            % Un port de contrôle : le lien arrive sur la garde, ou sur le
            % passe-plat du Trigger.
            cible = controles.ordre(port - numel(entrees));
            if cible == g
                modele.liens(l, 2) = n + g;
                modele.liens(l, 3) = 1;
            else
                modele.liens(l, 2) = n + cible;
                modele.liens(l, 3) = 1;
            end
            continue
        end
        if port < 1 || port > numel(entrees)
            error('Simulink:Commands:SousSystemeEntreeAbsente', ...
                  ['Le sous-systeme ''%s'' recoit un lien sur son entree %d, ' ...
                   'mais il n''a que %d bloc(s) INPORT et %d port(s) de controle.'], ...
                  char(bloc.nom), port, numel(entrees), numel(controles.ordre));
        end
        interieur = n + entrees(port);
        modele.blocs{interieur}.type = 'signalconversion';
        modele.blocs{interieur}.parametres = struct();
        modele.liens(l, 2) = interieur;
        modele.liens(l, 3) = 1;
    end

    % Un lien qui part d'une sortie que le sous-système n'a pas est refusé
    % en le nommant : il ne mènerait nulle part.
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 1) == k && modele.liens(l, 4) > max(1, numel(sorties))
            error('Simulink:Commands:SousSystemeSortieAbsente', ...
                  ['Un lien part de la sortie %d du sous-systeme ''%s'', qui n''a ' ...
                   'que %d bloc(s) OUTPORT.'], modele.liens(l, 4), char(bloc.nom), ...
                  numel(sorties));
        end
    end

    % Et chaque sortie du sous-système est celle de l'OUTPORT de même rang.
    for j = 1:numel(sorties)
        modele.liens = [modele.liens; n + sorties(j), k, j, 1];
    end
end

function interne = contenu(bloc)
    if strcmp(bloc.type, 'modelreference')
        % Une référence de modèle relit son modèle à chaque simulation.
        nom = '';
        if isfield(bloc.parametres, 'ModelName')
            nom = char(bloc.parametres.ModelName);
        end
        if isempty(nom)
            error('Simulink:modelReference:ModelNameEmpty', ...
                  'La reference de modele ''%s'' ne nomme pas de modele (ModelName).', ...
                  char(bloc.nom));
        end
        nom = regexprep(nom, '\.(slx|mdl)$', '');
        try
            interne = matlibre_sl_modele(nom);
        catch err
            error('Simulink:modelReference:ModelNotFound', ...
                  'La reference de modele ''%s'' designe ''%s'', introuvable : %s', ...
                  char(bloc.nom), nom, err.message);
        end
        return
    end
    if isfield(bloc.parametres, 'Model')
        interne = matlibre_sl_modele(bloc.parametres.Model);
    elseif isfield(bloc.parametres, 'Modele')
        interne = matlibre_sl_modele(bloc.parametres.Modele);
    else
        error('Simulink:Commands:SousSystemeVide', ...
              ['Le sous-systeme ''%s'' ne porte pas de modele : donnez-le ' ...
               'par ADD_BLOCK(...,''subsystem'',NOM,''Model'',SOUSMODELE).'], ...
              char(bloc.nom));
    end
end

% Les ports de contrôle d'un sous-système : Enable, Trigger, Action Port,
% un de chaque au plus, et Action Port seul. G est le rang de celui qui
% devient la garde, 0 s'il n'y en a pas. CONTROLES.ordre les range comme
% les entrées de contrôle du bloc : Enable, puis Trigger ; ou Action.
function [controles, g] = portsDeControle(interne, bloc)
    controles = struct('enable', 0, 'trigger', 0, 'action', 0, 'ordre', [], 'tous', []);
    noms = {'enableport', 'enable'; 'triggerport', 'trigger'; 'actionport', 'action'};
    for i = 1:size(noms, 1)
        trouves = find(cellfun(@(b) strcmp(b.type, noms{i, 1}), interne.blocs));
        if numel(trouves) > 1
            error('Simulink:blocks:ControlPortDuplicate', ...
                  ['Le sous-systeme ''%s'' porte %d blocs ''%s'' : un sous-systeme n''a ' ...
                   'qu''un port de chaque sorte.'], char(bloc.nom), numel(trouves), ...
                  interne.blocs{trouves(1)}.nom);
        end
        if ~isempty(trouves)
            controles.(noms{i, 2}) = trouves;
        end
    end
    if controles.action > 0 && (controles.enable > 0 || controles.trigger > 0)
        error('Simulink:blocks:ActionPortWithEnableTrigger', ...
              ['Le sous-systeme ''%s'' porte un Action Port avec un port Enable ou ' ...
               'Trigger : un sous-systeme d''action n''a que son Action Port.'], ...
              char(bloc.nom));
    end
    controles.ordre = [controles.enable, controles.trigger, controles.action];
    controles.ordre = controles.ordre(controles.ordre > 0);
    controles.tous = controles.ordre;
    g = 0;
    if ~isempty(controles.ordre)
        g = controles.ordre(1);
    end
end

% Ce que la garde doit savoir : quels contrôles, quel front, et s'il faut
% remettre les états à zéro quand le sous-système reprend.
function p = parametresDeGarde(interne, controles)
    p = struct('Enable', double(controles.enable > 0), 'Trigger', 'none', ...
               'Action', double(controles.action > 0), 'Reset', 0, 'ZeroCross', 'on');
    if controles.enable > 0
        q = interne.blocs{controles.enable}.parametres;
        if isfield(q, 'StatesWhenEnabling') && strcmpi(char(q.StatesWhenEnabling), 'reset')
            p.Reset = 1;
        end
        if isfield(q, 'ZeroCross')
            p.ZeroCross = lower(char(q.ZeroCross));
        end
    end
    if controles.trigger > 0
        p.Trigger = 'rising';
        q = interne.blocs{controles.trigger}.parametres;
        if isfield(q, 'TriggerType')
            p.Trigger = lower(char(q.TriggerType));
        end
        if isfield(q, 'ZeroCross') && strcmpi(char(q.ZeroCross), 'off')
            p.ZeroCross = 'off';
        end
    end
    if controles.action > 0
        q = interne.blocs{controles.action}.parametres;
        if isfield(q, 'InitializeStates') && strcmpi(char(q.InitializeStates), 'reset')
            p.Reset = 1;
        end
    end
end

% Les blocs d'un type donné, rangés par leur paramètre Port. Ceux qui
% n'en portent pas viennent après, dans l'ordre où ils ont été posés :
% c'est le rang qui compte, et l'ordre d'écriture en est un.
function indices = parRang(modele, type)
    indices = [];
    rangs = [];
    suivant = 0;
    for j = 1:numel(modele.blocs)
        if ~strcmp(modele.blocs{j}.type, type)
            continue
        end
        suivant = suivant + 1;
        rang = suivant;
        if isfield(modele.blocs{j}.parametres, 'Port')
            rang = double(modele.blocs{j}.parametres.Port);
        end
        indices(end + 1) = j;      %#ok<AGROW>
        rangs(end + 1) = rang;     %#ok<AGROW>
    end
    [~, ordre] = sort(rangs);
    indices = indices(ordre);
end
