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
    nomRacine = '';
    if isfield(modele, 'nom')
        nomRacine = char(modele.nom);
    end
    modele = portsDeBus(modele, nomRacine);
    % Les Simulink Function du modèle, et les appels qui les désignent
    definitions = fonctionsDuModele(modele, nomRacine);
    % Un modèle ordinaire ne paie rien : le dépliage ne coûte que le
    % parcours qui constate qu'il n'y a rien à déplier.
    garde = 0;
    while true
        % les blocs de la bibliothèque que Simulink bâtit en sous-systèmes
        modele = matlibre_sl_bibliotheque(modele);
        if ~isempty(definitions)
            modele = appelsDeFonctions(modele, definitions, nomRacine);
        end
        k = premier(modele);
        if k == 0
            % les réseaux physiques, une fois tout déplié, deviennent des
            % blocs ordinaires
            modele = matlibre_sl_physique('reseaux', modele);
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
function iterateur = sousSystemeItere(bloc, interne, iterateurs, g, chemin)
    if numel(iterateurs) > 1
        error('Simulink:blocks:IteratorDuplicate', ...
              ['Le sous-systeme ''%s'' porte %d blocs d''iteration : un sous-systeme ' ...
               'itere n''en a qu''un.'], chemin, numel(iterateurs));
    end
    if g > 0
        error('Simulink:blocks:IteratorWithControlPort', ...
              ['Le sous-systeme itere ''%s'' porte un port Enable, Trigger ou Action : ' ...
               'placez-le dans un sous-systeme conditionnel plutot.'], chemin);
    end
    espace = struct();
    if isfield(bloc, 'espace')
        espace = bloc.espace;
    end
    if ~isempty(matlibre_sl_masque('variables', bloc))
        espace = matlibre_sl_masque('espace', bloc, espace, chemin);
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

% Les Simulink Function d'un modèle et de ses sous-systèmes : leur nom,
% le système qui les porte — d'où se voit une fonction « scoped » —, leur
% visibilité et leur corps. Les Function Caller se comptent par fonction :
% une fonction à états n'a qu'un appelant, MatLibre dépliant chaque appel.
function definitions = fonctionsDuModele(modele, nomRacine)
    definitions = struct('nom', {}, 'systeme', {}, 'chemin', {}, 'visibilite', {}, ...
                         'interieur', {}, 'appels', {}, 'aEtats', {});
    appels = struct('nom', {}, 'chemin', {});
    [definitions, appels] = parcourirFonctions(modele, nomRacine, definitions, appels);
    for q = 1:numel(appels)
        d = resoudreFonction(definitions, appels(q).nom, appels(q).chemin);
        if d > 0
            definitions(d).appels = definitions(d).appels + 1;
        end
    end
    for d = 1:numel(definitions)
        if definitions(d).appels > 1 && definitions(d).aEtats
            error('Simulink:SimulinkFunction:SharedStateNotSupported', ...
                  ['Le Simulink Function ''%s'' (%s) a des etats, et %d Function Caller ' ...
                   'l''appellent : MatLibre deplie chaque appel, et ne partage pas encore ' ...
                   'ses etats entre eux. Donnez a chaque appelant sa fonction.'], ...
                  definitions(d).chemin, definitions(d).nom, definitions(d).appels);
        end
    end
end

function [definitions, appels] = parcourirFonctions(modele, systeme, definitions, appels)
    modele = matlibre_sl_modele(modele);
    for j = 1:numel(modele.blocs)
        b = modele.blocs{j};
        type = typeCanonique(b.type);
        chemin = [systeme '/' char(b.nom)];
        if strcmp(type, 'functioncaller')
            appels(end + 1) = struct('nom', nomAppele(b.parametres, chemin), ...
                                     'chemin', systeme); %#ok<AGROW>
            continue
        end
        if ~strcmp(type, 'subsystem') || ~(isfield(b.parametres, 'Model') || ...
                                          isfield(b.parametres, 'Modele'))
            continue
        end
        try
            interne = contenu(struct('type', 'subsystem', 'parametres', b.parametres), chemin);
        catch
            continue   % le dépliage dira ce qui ne va pas
        end
        declencheur = declencheurDeFonction(interne);
        if declencheur > 0
            p = interne.blocs{declencheur}.parametres;
            definitions(end + 1) = struct('nom', char(lireParametre(p, 'FunctionName', 'f')), ...
                'systeme', systeme, 'chemin', chemin, ...
                'visibilite', char(lireParametre(p, 'FunctionVisibility', 'scoped')), ...
                'interieur', interne, 'appels', 0, 'aEtats', aDesEtats(interne)); %#ok<AGROW>
            [definitions, appels] = parcourirFonctions(interne, chemin, definitions, appels);
        else
            [definitions, appels] = parcourirFonctions(interne, chemin, definitions, appels);
        end
    end
end

% Le rang du Trigger qui fait d'un sous-système un Simulink Function, 0 s'il
% n'y en a pas.
function k = declencheurDeFonction(interne)
    k = 0;
    for j = 1:numel(interne.blocs)
        b = interne.blocs{j};
        if strcmp(typeCanonique(b.type), 'triggerport') && ...
           strcmpi(char(lireParametre(b.parametres, 'IsSimulinkFunction', 'off')), 'on')
            k = j;
            return
        end
    end
end

% Un corps qui garde un état : un bloc à mémoire, ou un sous-système qui
% en porte un.
function oui = aDesEtats(interne)
    oui = false;
    memoire = {'integrator', 'delay', 'memory', 'discreteintegrator', 'discretetransferfcn', ...
               'discretefilter', 'discretestatespace', 'transferfcn', 'statespace', ...
               'zeropole', 'chart', 'tappeddelay', 'difference', 'discretederivative', ...
               'transportdelay', 'variabletransportdelay', 'secondorderintegrator', ...
               'secondorderintegratorlimited', 'pidcontroller', 'pidcontroller2dof', ...
               'datastorememory', 'ratelimiter', 'counterfreerunning', 'counterlimited', ...
               'zoh', 'firstorderhold', 'descriptorstatespace', 'transferfcndirectformii', ...
               'detectchange', 'detectincrease', 'detectdecrease', 'detectrisepositive', ...
               'detectrisenonnegative', 'detectfallnegative', 'detectfallnonpositive', ...
               'derivative', 'backlash', 'relay', 'ic', 'ratetransition'};
    for j = 1:numel(interne.blocs)
        b = interne.blocs{j};
        type = typeCanonique(b.type);
        if any(strcmp(type, memoire)) || (strcmp(type, 'matlabfunction') && ...
           ~isempty(regexp(char(lireParametre(b.parametres, 'Script', '')), ...
                           '(^|\n)\s*persistent\s', 'once')))
            oui = true;
            return
        end
        if strcmp(type, 'subsystem') && isfield(b.parametres, 'Model')
            try
                oui = aDesEtats(matlibre_sl_modele(b.parametres.Model));
            catch
            end
            if oui
                return
            end
        end
    end
end

% Le nom de la fonction qu'appelle un Function Caller : ScopedFunctionName,
% ou celui de son prototype.
function nom = nomAppele(p, chemin)
    nom = lireParametre(p, 'ScopedFunctionName', '');
    if isstring(nom) && isscalar(nom)
        nom = char(nom);
    end
    if ~ischar(nom) || size(nom, 1) > 1
        error('Simulink:SimulinkFunction:InvalidPrototype', ...
              ['Le nom de la fonction qu''appelle le Function Caller ''%s'' ' ...
               '(ScopedFunctionName) est un texte : f, ou A.f.'], chemin);
    end
    nom = strtrim(nom);
    if isempty(nom)
        [~, nom] = matlibre_sl_prototype(lireParametre(p, 'FunctionPrototype', 'y=f(u)'));
    end
    if isempty(nom)
        error('Simulink:SimulinkFunction:InvalidPrototype', ...
              ['Le prototype du Function Caller ''%s'' ne se lit pas : il s''ecrit ' ...
               'y = f(u), [y1, y2] = f(u1, u2), ou f(u).'], chemin);
    end
end

% La fonction que voit un appel fait depuis le système SYSTEME : « A.f »
% désigne celle du sous-système A ; « f » la plus proche de celles que
% portent SYSTEME et ses parents, ou une fonction globale. 0 si aucune.
function d = resoudreFonction(definitions, nom, systeme)
    d = 0;
    qualifiant = '';
    point = find(nom == '.', 1, 'last');
    if ~isempty(point)
        qualifiant = nom(1:point - 1);
        nom = nom(point + 1:end);
    end
    meilleur = -1;
    for q = 1:numel(definitions)
        D = definitions(q);
        if ~strcmp(D.nom, nom)
            continue
        end
        if ~isempty(qualifiant)
            barre = find(D.systeme == '/', 1, 'last');
            dernier = D.systeme;
            if ~isempty(barre)
                dernier = D.systeme(barre + 1:end);
            end
            visible = strcmp(dernier, qualifiant);
        else
            visible = strcmp(D.visibilite, 'global') || strcmp(systeme, D.systeme) || ...
                      strncmp(systeme, [D.systeme '/'], numel(D.systeme) + 1);
        end
        if visible && numel(D.systeme) > meilleur
            d = q;
            meilleur = numel(D.systeme);
        end
    end
end

% Les blocs du niveau courant : un Simulink Function n'y calcule pas — on
% l'appelle —, et chaque Function Caller devient un sous-système qui porte
% le corps de la fonction, ses arguments en entrées et en sorties.
function modele = appelsDeFonctions(modele, definitions, nomRacine)
    for j = 1:numel(modele.blocs)
        b = modele.blocs{j};
        if strcmp(b.type, 'subsystem') && (isfield(b.parametres, 'Model') || ...
                                          isfield(b.parametres, 'Modele'))
            try
                interne = contenu(b, char(b.nom));
            catch
                continue
            end
            if declencheurDeFonction(interne) > 0
                b.type = 'docblock';   % une définition : elle ne calcule rien ici
                b.parametres = struct();
                modele.blocs{j} = b;
            end
            continue
        end
        if ~strcmp(b.type, 'functioncaller')
            continue
        end
        nom = char(b.nom);
        barre = find(nom == '/', 1, 'last');
        systeme = nomRacine;
        if ~isempty(barre)
            systeme = [nomRacine '/' nom(1:barre - 1)];
        end
        chemin = [nomRacine '/' nom];
        appele = nomAppele(b.parametres, chemin);
        d = resoudreFonction(definitions, appele, systeme);
        if d == 0
            error('Simulink:SimulinkFunction:FunctionNotFound', ...
                  ['Le Function Caller ''%s'' appelle ''%s'', qu''aucun Simulink Function ' ...
                   'visible d''ici ne definit : une fonction « scoped » se voit dans son ' ...
                   'systeme et ses sous-systemes, ou s''appelle qualifiee (A.%s).'], ...
                  chemin, appele, regexprep(appele, '^.*\.', ''));
        end
        b.type = 'subsystem';
        b.parametres = struct('Model', corpsAppele(definitions(d), b.parametres, chemin));
        modele.blocs{j} = b;
    end
end

% Le corps d'une fonction pour un appel : son Trigger ne sert plus, ses
% arguments d'entrée et de sortie deviennent des Inport et des Outport au
% rang de l'argument de même nom dans le prototype de l'appel — ou au même
% rang, si les noms diffèrent mais pas leur nombre.
function interne = corpsAppele(D, p, chemin)
    [sortiesAppel, ~, entreesAppel] = matlibre_sl_prototype( ...
        lireParametre(p, 'FunctionPrototype', 'y=f(u)'));
    interne = D.interieur;
    rangsE = [];
    nomsE = {};
    rangsS = [];
    nomsS = {};
    for j = 1:numel(interne.blocs)
        b = interne.blocs{j};
        switch typeCanonique(b.type)
            case 'triggerport'
                interne.blocs{j}.type = 'docblock';
                interne.blocs{j}.parametres = struct();
            case 'argin'
                rangsE(end + 1) = j; %#ok<AGROW>
                nomsE{end + 1} = nomArgument(b, 'u', D.chemin); %#ok<AGROW>
            case 'argout'
                rangsS(end + 1) = j; %#ok<AGROW>
                nomsS{end + 1} = nomArgument(b, 'y', D.chemin); %#ok<AGROW>
            case {'inport', 'outport'}
                error('Simulink:SimulinkFunction:PortsNotSupported', ...
                      ['Le Simulink Function ''%s'' porte un Inport ou un Outport : MatLibre ' ...
                       'ne lui connait que ses arguments (Argument Inport, Argument Outport).'], ...
                      D.chemin);
        end
    end
    placesE = placerArguments(nomsE, entreesAppel, D, chemin, 'd''entree');
    placesS = placerArguments(nomsS, sortiesAppel, D, chemin, 'de sortie');
    for q = 1:numel(rangsE)
        b = interne.blocs{rangsE(q)};
        interne.blocs{rangsE(q)}.type = 'inport';
        interne.blocs{rangsE(q)}.parametres = argumentEnPort(b.parametres, placesE(q));
    end
    for q = 1:numel(rangsS)
        b = interne.blocs{rangsS(q)};
        interne.blocs{rangsS(q)}.type = 'outport';
        interne.blocs{rangsS(q)}.parametres = argumentEnPort(b.parametres, placesS(q));
    end
end

% Le nom d'un argument de Simulink Function : un identificateur.
function nom = nomArgument(b, defaut, chemin)
    nom = lireParametre(b.parametres, 'ArgumentName', defaut);
    if isstring(nom) && isscalar(nom)
        nom = char(nom);
    end
    if ~ischar(nom) || ~isvarname(strtrim(nom))
        error('Simulink:SimulinkFunction:InvalidArgumentName', ...
              ['L''argument ''%s'' du Simulink Function ''%s'' doit porter un nom ' ...
               '(ArgumentName) : un identificateur, u ou y.'], char(b.nom), chemin);
    end
    nom = strtrim(nom);
end

function places = placerArguments(noms, appel, D, chemin, quoi)
    if numel(noms) ~= numel(appel)
        error('Simulink:SimulinkFunction:PrototypeMismatch', ...
              ['Le Function Caller ''%s'' passe %d argument(s) %s a ''%s'', qui en prend ' ...
               '%d (%s).'], chemin, numel(appel), quoi, D.chemin, numel(noms), ...
              strjoin(noms, ', '));
    end
    places = 1:numel(noms);
    [trouves, ou] = ismember(noms, appel);
    if all(trouves)
        places = ou;
    end
end

function q = argumentEnPort(p, rang)
    q = struct('Port', rang);
    for champ = {'OutDataTypeStr', 'PortDimensions'}
        v = lireParametre(p, champ{1}, []);
        if ~isempty(v) && ~(ischar(v) && strncmpi(v, 'Inherit', 7)) && ...
           ~(isnumeric(v) && isequal(double(v), -1))
            q.(champ{1}) = v;
        end
    end
end

% Les ports d'élément de bus d'un système deviennent ce qu'ils abrègent.
% Les In Bus Element de même nom de port sont une seule entrée — un
% Inport —, dont chacun reprend son élément par un Bus Selector, ou le bus
% entier si son élément est vide. Les Out Bus Element de même nom de port
% forment ensemble le bus d'une seule sortie : un Bus Creator, dont chaque
% élément est le signal de l'un d'eux, alimente un Outport.
function modele = portsDeBus(modele, chemin)
    types = cellfun(@(b) b.type, modele.blocs, 'UniformOutput', false);
    entrees = find(strcmp(types, 'inbuselement'));
    sorties = find(strcmp(types, 'outbuselement'));
    if isempty(entrees) && isempty(sorties)
        return
    end
    noms = cellfun(@(b) char(b.nom), modele.blocs, 'UniformOutput', false);
    ports = struct('nom', {}, 'bloc', {});
    for j = entrees
        p = modele.blocs{j}.parametres;
        nomPort = texteDuPort(p, 'PortName', 'InBus', chemin, modele.blocs{j}.nom);
        element = strtrim(texteDuPort(p, 'Element', 'signal1', chemin, modele.blocs{j}.nom));
        q = find(strcmp({ports.nom}, nomPort), 1);
        if isempty(q)
            parametres = struct('Port', lireParametre(p, 'Port', 1));
            for champ = {'OutDataTypeStr', 'PortDimensions', 'SampleTime'}
                v = lireParametre(p, champ{1}, []);
                if ~isempty(v) && ~(ischar(v) && strncmpi(v, 'Inherit', 7)) && ...
                   ~(isnumeric(v) && isequal(double(v), -1))
                    parametres.(champ{1}) = v;
                end
            end
            nomEntree = nomLibre(noms, nomPort);
            modele.blocs{end + 1} = struct('type', 'inport', 'nom', nomEntree, ...
                                           'parametres', parametres);
            noms{end + 1} = nomEntree; %#ok<AGROW>
            ports(end + 1) = struct('nom', nomPort, 'bloc', numel(modele.blocs)); %#ok<AGROW>
            q = numel(ports);
        end
        b = modele.blocs{j};
        if isempty(element)
            b.type = 'signalconversion';
            b.parametres = struct();
        else
            b.type = 'busselector';
            b.parametres = struct('OutputSignals', element);
        end
        modele.blocs{j} = b;
        modele.liens(end + 1, :) = [ports(q).bloc, j, 1, 1];
    end
    groupes = struct('nom', {}, 'blocs', {}, 'elements', {});
    for j = sorties
        p = modele.blocs{j}.parametres;
        nomPort = texteDuPort(p, 'PortName', 'OutBus', chemin, modele.blocs{j}.nom);
        element = strtrim(texteDuPort(p, 'Element', 'signal1', chemin, modele.blocs{j}.nom));
        if any(element == '.')
            error('Simulink:blocks:BusElementPortNested', ...
                  ['L''element ''%s'' de ''%s/%s'' est emboite : MatLibre ne batit pas un bus ' ...
                   'emboite par des Out Bus Element ; formez-le par un Bus Creator.'], ...
                  element, chemin, char(modele.blocs{j}.nom));
        end
        q = find(strcmp({groupes.nom}, nomPort), 1);
        if isempty(q)
            groupes(end + 1) = struct('nom', nomPort, 'blocs', [], 'elements', {{}}); %#ok<AGROW>
            q = numel(groupes);
        end
        if any(strcmp(groupes(q).elements, element)) || ...
           (~isempty(groupes(q).elements) && (isempty(element) || any(cellfun(@isempty, ...
                                                                    groupes(q).elements))))
            error('Simulink:blocks:BusElementPortDuplicate', ...
                  ['''%s/%s'' ecrit l''element ''%s'' du port ''%s'', qu''un autre Out Bus ' ...
                   'Element ecrit deja : chaque element d''un port est unique.'], chemin, ...
                  char(modele.blocs{j}.nom), element, nomPort);
        end
        groupes(q).blocs(end + 1) = j;
        groupes(q).elements{end + 1} = element;
    end
    for q = 1:numel(groupes)
        premierBloc = modele.blocs{groupes(q).blocs(1)};
        p = premierBloc.parametres;
        parametres = struct('Port', lireParametre(p, 'Port', 1), ...
                            'OutputWhenDisabled', lireParametre(p, 'OutputWhenDisabled', 'held'));
        initiale = lireParametre(p, 'InitialOutput', []);
        if ~isempty(initiale)
            parametres.InitialOutput = initiale;
        end
        nomSortie = nomLibre(noms, groupes(q).nom);
        modele.blocs{end + 1} = struct('type', 'outport', 'nom', nomSortie, ...
                                       'parametres', parametres);
        noms{end + 1} = nomSortie; %#ok<AGROW>
        sortie = numel(modele.blocs);
        if isempty(groupes(q).elements{1})
            % le signal entier, ou le bus entier, sans élément
            source = groupes(q).blocs(1);
            modele.blocs{source}.type = 'signalconversion';
            modele.blocs{source}.parametres = struct();
            modele.liens(end + 1, :) = [source, sortie, 1, 1];
            continue
        end
        nomBus = nomLibre(noms, [groupes(q).nom ' bus']);
        modele.blocs{end + 1} = struct('type', 'buscreator', 'nom', nomBus, 'parametres', ...
                                       struct('Inputs', strjoin(groupes(q).elements, ',')));
        noms{end + 1} = nomBus; %#ok<AGROW>
        createur = numel(modele.blocs);
        for r = 1:numel(groupes(q).blocs)
            j = groupes(q).blocs(r);
            modele.blocs{j}.type = 'signalconversion';
            modele.blocs{j}.parametres = struct();
            modele.liens(end + 1, :) = [j, createur, r, 1];
        end
        modele.liens(end + 1, :) = [createur, sortie, 1, 1];
    end
end

% Un nom de bloc libre dans le système, tiré de BASE.
% Le nom d'un port d'élément de bus, ou de son élément : un texte d'une
% ligne.
function v = texteDuPort(p, nom, defaut, chemin, bloc)
    v = lireParametre(p, nom, defaut);
    if isstring(v) && isscalar(v)
        v = char(v);
    end
    if ~ischar(v) || size(v, 1) > 1
        error('Simulink:blocks:BusElementPortName', ...
              ['Le parametre %s de ''%s/%s'' est un texte : le nom du port, ou le chemin ' ...
               'de l''element dans le bus.'], nom, chemin, char(bloc));
    end
end

function nom = nomLibre(noms, base)
    nom = base;
    rang = 1;
    while any(strcmp(noms, nom))
        rang = rang + 1;
        nom = sprintf('%s %d', base, rang);
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
        if any(strcmp(modele.blocs{j}.type, {'subsystem', 'modelreference', ...
                                             'subsystemreference'}))
            k = j;
            return
        end
    end
end

function modele = deplier(modele, k)
    bloc = modele.blocs{k};
    % le chemin du bloc, comme Simulink le donne dans ses messages
    chemin = char(bloc.nom);
    if isfield(modele, 'nom') && ~isempty(modele.nom)
        chemin = [char(modele.nom) '/' chemin];
    end
    interne = contenu(bloc, chemin);
    interne.liens = matlibre_sl_liens(interne);
    interne = rafraichirLiens(interne);
    for j = 1:numel(interne.blocs)
        interne.blocs{j}.type = typeCanonique(interne.blocs{j}.type);
    end
    interne = portsDeBus(interne, chemin);
    n = numel(modele.blocs);
    m = numel(interne.blocs);
    entrees = parRang(interne, 'inport');
    sorties = parRang(interne, 'outport');
    [controles, g] = portsDeControle(interne, chemin);
    gardeParent = 0;
    if isfield(bloc, 'garde')
        gardeParent = bloc.garde;
    end
    % Un sous-système atomique dont SystemSampleTime est dit impose sa
    % période à ses blocs, emboîtés compris.
    periode = periodeImposee(bloc, chemin);
    types = cellfun(@(b) b.type, interne.blocs, 'UniformOutput', false);
    % Une fonction d'événement — un Event Listener dedans — calcule une
    % fois, au début (Initialize) ou à la fin (Terminate) : ses blocs le
    % portent, emboîtés compris.
    evenement = '';
    if isfield(bloc, 'evenement')
        evenement = bloc.evenement;
    end
    ecouteurs = find(strcmp(types, 'eventlistener'));
    if ~isempty(ecouteurs)
        evenement = evenementDe(interne, ecouteurs, entrees, sorties, controles, chemin, ...
                                evenement, gardeParent);
    end
    iterateurs = find(ismember(types, {'foriterator', 'whileiterator', 'foreach'}));
    if ~isempty(iterateurs)
        modele.blocs{k} = sousSystemeItere(bloc, interne, iterateurs, g, chemin);
        if ~isempty(evenement)
            modele.blocs{k}.evenement = evenement;
        end
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
        espaceInterieur = matlibre_sl_masque('espace', bloc, espaceParent, chemin);
    end
    if strcmp(bloc.type, 'modelreference')
        % un modèle référencé ne voit que son propre espace de travail, et
        % les arguments que lui passe le bloc Model
        espaceInterieur = espaceReference(bloc, interne, chemin, espaceParent);
    end

    % Le bloc du sous-système garde sa place dans la liste — donc son
    % rang, donc tous les liens qui le désignent —, mais devient un
    % passe-plat : chacune de ses sorties portera la valeur de l'OUTPORT
    % intérieur de même rang.
    passePlat = bloc;
    passePlat.type = 'signalconversion';
    passePlat.parametres = struct();
    if numel(sorties) ~= 1
        % sans sortie, il n'a rien à passer : aucun port, que le
        % diagnostic des entrées non reliées compterait
        passePlat.parametres.NombreDePorts = numel(sorties);
    end
    if isfield(bloc.parametres, 'Position')
        passePlat.parametres.Position = bloc.parametres.Position;
    end
    passePlat.garde = gardeParent;
    % Un sous-système virtuel — ni atomique, ni conditionnel, ni référence
    % de modèle — n'est qu'un regroupement graphique : ce qui lit sa sortie
    % lit l'Outport du dedans, et une boucle ne passe par lui que si elle
    % passe par ses blocs.
    passePlat.virtuel = strcmp(bloc.type, 'subsystem') && g == 0 && ...
        ~strcmpi(char(lireParametre(bloc.parametres, 'TreatAsAtomicUnit', 'off')), 'on');
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
        if ~isempty(evenement)
            enfant.evenement = evenement;
        end
        if ~isempty(periode)
            enfant = imposerPeriode(enfant, periode, chemin);
        end
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
    % les connexions physiques du dedans suivent leurs blocs
    if isfield(interne, 'connexions') && ~isempty(interne.connexions)
        if ~isfield(modele, 'connexions')
            modele.connexions = zeros(0, 4);
        end
        modele.connexions = [modele.connexions; ...
                             [interne.connexions(:, 1) + n, interne.connexions(:, 2), ...
                              interne.connexions(:, 3) + n, interne.connexions(:, 4)]];
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
        modele.blocs{n + sorties(j)}.parametres = typeDuPort(interieur.parametres);
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
        % les autres ports de contrôle — le Trigger après l'Enable, le
        % Reset après eux — deviennent les passe-plats de leur signal, que
        % la garde lit à leur rang
        for rang = 2:numel(controles.ordre)
            autre = modele.blocs{n + controles.ordre(rang)};
            autre.type = 'signalconversion';
            autre.parametres = struct();
            modele.blocs{n + controles.ordre(rang)} = autre;
            modele.liens = [modele.liens; n + controles.ordre(rang), n + g, rang, 1];
        end
    end
    typesEntrees = cell(1, numel(entrees));
    for j = 1:numel(entrees)
        indice = n + entrees(j);
        typesEntrees{j} = typeDuPort(modele.blocs{indice}.parametres);
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
                  chemin, port, numel(entrees), numel(controles.ordre));
        end
        interieur = n + entrees(port);
        modele.blocs{interieur}.type = 'signalconversion';
        modele.blocs{interieur}.parametres = typesEntrees{port};
        modele.liens(l, 2) = interieur;
        modele.liens(l, 3) = 1;
    end

    % Un lien qui part d'une sortie que le sous-système n'a pas est refusé
    % en le nommant : il ne mènerait nulle part.
    for l = 1:size(modele.liens, 1)
        if modele.liens(l, 1) == k && modele.liens(l, 4) > max(1, numel(sorties))
            error('Simulink:Commands:SousSystemeSortieAbsente', ...
                  ['Un lien part de la sortie %d du sous-systeme ''%s'', qui n''a ' ...
                   'que %d bloc(s) OUTPORT.'], modele.liens(l, 4), chemin, ...
                  numel(sorties));
        end
    end

    % Et chaque sortie du sous-système est celle de l'OUTPORT de même rang.
    for j = 1:numel(sorties)
        modele.liens = [modele.liens; n + sorties(j), k, j, 1];
    end
end

% Un port de sous-système devenu passe-plat garde son type de bus : le
% bus qui le traverse doit être de ce type.
function p = typeDuPort(parametres)
    p = struct();
    if isfield(parametres, 'OutDataTypeStr') && ...
       ~isempty(matlibre_sl_bus('type', parametres.OutDataTypeStr))
        p.OutDataTypeStr = parametres.OutDataTypeStr;
    end
end

function interne = contenu(bloc, chemin)
    if strcmp(bloc.type, 'subsystemreference')
        % Un Subsystem Reference déroule à sa place le fichier de
        % sous-système qu'il désigne, relu à chaque simulation.
        nom = lireParametre(bloc.parametres, 'ReferencedSubsystem', '');
        if isstring(nom) && isscalar(nom)
            nom = char(nom);
        end
        if ~ischar(nom) || size(nom, 1) > 1
            error('Simulink:SubsystemReference:InvalidReference', ...
                  ['Le Subsystem Reference ''%s'' designe son fichier de sous-systeme par ' ...
                   'un nom, en texte (ReferencedSubsystem).'], chemin);
        end
        nom = strtrim(nom);
        if isempty(nom)
            error('Simulink:SubsystemReference:EmptyReference', ...
                  ['Le Subsystem Reference ''%s'' ne designe pas de fichier de sous-systeme ' ...
                   '(ReferencedSubsystem).'], chemin);
        end
        nom = regexprep(nom, '\.(slx|mdl)$', '');
        try
            interne = matlibre_sl_modele(nom);
        catch err
            error('Simulink:SubsystemReference:SubsystemNotFound', ...
                  'Le Subsystem Reference ''%s'' designe ''%s'', introuvable : %s', ...
                  chemin, nom, err.message);
        end
        genre = genreDiagramme(interne);
        if ~strcmp(genre, 'subsystem')
            error('Simulink:SubsystemReference:NotASubsystemFile', ...
                  ['Le Subsystem Reference ''%s'' designe ''%s'', qui est un%s et non un ' ...
                   'fichier de sous-systeme : un fichier de sous-systeme se cree par ' ...
                   'NEW_SYSTEM(NOM, ''Subsystem''), un modele se reference par un bloc Model.'], ...
                  chemin, nom, libelleDiagramme(genre));
        end
        return
    end
    if strcmp(bloc.type, 'modelreference')
        % Une référence de modèle relit son modèle à chaque simulation.
        nom = '';
        if isfield(bloc.parametres, 'ModelName')
            nom = char(bloc.parametres.ModelName);
        end
        if isempty(nom)
            error('Simulink:modelReference:ModelNameEmpty', ...
                  'La reference de modele ''%s'' ne nomme pas de modele (ModelName).', ...
                  chemin);
        end
        nom = regexprep(nom, '\.(slx|mdl)$', '');
        try
            interne = matlibre_sl_modele(nom);
        catch err
            error('Simulink:modelReference:ModelNotFound', ...
                  'La reference de modele ''%s'' designe ''%s'', introuvable : %s', ...
                  chemin, nom, err.message);
        end
        if strcmp(genreDiagramme(interne), 'subsystem')
            error('Simulink:modelReference:SubsystemFileReferenced', ...
                  ['La reference de modele ''%s'' designe ''%s'', un fichier de ' ...
                   'sous-systeme : c''est un Subsystem Reference qui le deroule.'], chemin, nom);
        end
        return
    end
    if isfield(bloc.parametres, 'Model') || isfield(bloc.parametres, 'Modele')
        if isfield(bloc.parametres, 'Model')
            dedans = bloc.parametres.Model;
        else
            dedans = bloc.parametres.Modele;
        end
        try
            interne = matlibre_sl_modele(dedans);
        catch err
            error('Simulink:Commands:SousSystemeVide', ...
                  ['Le sous-systeme ''%s'' porte, dans son parametre Model, ce qui ' ...
                   'n''est pas un modele : %s'], chemin, err.message);
        end
        if strcmpi(char(lireParametre(bloc.parametres, 'Variant', 'off')), 'on')
            interne = choisirVariante(interne, bloc.parametres, chemin);
        end
    else
        error('Simulink:Commands:SousSystemeVide', ...
              ['Le sous-systeme ''%s'' ne porte pas de modele : donnez-le ' ...
               'par ADD_BLOCK(...,''subsystem'',NOM,''Model'',SOUSMODELE).'], ...
              chemin);
    end
end

% Un sous-système à variantes porte ses variantes — des sous-systèmes ou
% des références de modèle, chacun sa condition VariantControl — entre
% ses Inport et ses Outport, sans lien. Seule la variante active reste :
% ses entrées et ses sorties se raccordent, par leur nom, aux ports du
% sous-système ; une sortie qu'elle n'a pas vaut zéro. Sans variante
% active et avec AllowZeroVariantControls à 'on', toutes les sorties
% valent zéro.
function nouveau = choisirVariante(interne, p, chemin)
    types = cellfun(@(b) typeCanonique(b.type), interne.blocs, 'UniformOutput', false);
    choix = find(ismember(types, {'subsystem', 'modelreference', 'subsystemreference'}));
    autres = find(~ismember(types, {'subsystem', 'modelreference', 'subsystemreference', ...
                                    'inport', 'outport'}));
    if ~isempty(autres)
        error('Simulink:Variants:InvalidBlockInVariant', ...
              ['Le sous-systeme a variantes ''%s'' ne porte que ses ports et ses ' ...
               'variantes ; ''%s'' (%s) n''y a pas sa place.'], chemin, ...
              char(interne.blocs{autres(1)}.nom), types{autres(1)});
    end
    if isempty(choix)
        error('Simulink:Variants:NoVariantChoices', ...
              ['Le sous-systeme a variantes ''%s'' n''a pas de variante : posez-y des ' ...
               'sous-systemes, chacun avec sa condition VariantControl.'], chemin);
    end
    controles = cell(1, numel(choix));
    noms = cell(1, numel(choix));
    for i = 1:numel(choix)
        b = interne.blocs{choix(i)};
        controles{i} = char(lireParametre(b.parametres, 'VariantControl', ''));
        noms{i} = [chemin '/' char(b.nom)];
    end
    k = matlibre_sl_variantes('choisir', controles, ...
                              char(lireParametre(p, 'VariantControlMode', 'expression')), ...
                              char(lireParametre(p, 'LabelModeActiveChoice', '')), ...
                              strcmpi(char(lireParametre(p, 'AllowZeroVariantControls', ...
                                                         'off')), 'on'), chemin, noms);
    nouveau = interne;
    nouveau.blocs = {};
    nouveau.liens = zeros(0, 4);
    entrees = find(strcmp(types, 'inport'));
    sorties = find(strcmp(types, 'outport'));
    for j = [entrees, sorties]
        nouveau.blocs{end + 1} = interne.blocs{j};
    end
    rangEntree = 1:numel(entrees);
    rangSortie = numel(entrees) + (1:numel(sorties));
    actif = 0;
    nomsChoix = {};
    if k > 0
        variante = interne.blocs{choix(k)};
        nouveau.blocs{end + 1} = variante;
        actif = numel(nouveau.blocs);
        dedans = contenu(variante, noms{k});
        [nomsE, portsE] = portsNommes(dedans, 'inport');
        [nomsS, portsS] = portsNommes(dedans, 'outport');
        nomsChoix = nomsS;
        for i = 1:numel(nomsE)
            j = find(cellfun(@(b) strcmp(char(b.nom), nomsE{i}), interne.blocs(entrees)), 1);
            if isempty(j)
                error('Simulink:Variants:PortMismatch', ...
                      ['La variante ''%s'' a une entree ''%s'' que le sous-systeme a ' ...
                       'variantes ''%s'' n''a pas : ses ports se raccordent par leur ' ...
                       'nom.'], noms{k}, nomsE{i}, chemin);
            end
            nouveau.liens(end + 1, :) = [rangEntree(j), actif, portsE(i), 1];
        end
        for i = 1:numel(nomsS)
            if ~any(cellfun(@(b) strcmp(char(b.nom), nomsS{i}), interne.blocs(sorties)))
                error('Simulink:Variants:PortMismatch', ...
                      ['La variante ''%s'' a une sortie ''%s'' que le sous-systeme a ' ...
                       'variantes ''%s'' n''a pas : ses ports se raccordent par leur ' ...
                       'nom.'], noms{k}, nomsS{i}, chemin);
            end
        end
    end
    for j = 1:numel(sorties)
        nomSortie = char(interne.blocs{sorties(j)}.nom);
        i = find(strcmp(nomsChoix, nomSortie), 1);
        if ~isempty(i)
            nouveau.liens(end + 1, :) = [actif, rangSortie(j), 1, portsS(i)];
        else
            % une sortie que la variante active n'a pas : zéro
            nouveau.blocs{end + 1} = struct('type', 'ground', ...
                                            'nom', sprintf('%s (zero)', nomSortie), ...
                                            'parametres', struct());
            nouveau.liens(end + 1, :) = [numel(nouveau.blocs), rangSortie(j), 1, 1];
        end
    end
end

% Les Inport — ou les Outport — d'un modèle : leurs noms et leurs rangs.
function [noms, rangs] = portsNommes(modele, type)
    noms = {};
    rangs = [];
    for i = 1:numel(modele.blocs)
        b = modele.blocs{i};
        if ~strcmp(typeCanonique(b.type), type)
            continue
        end
        noms{end + 1} = char(b.nom); %#ok<AGROW>
        rangs(end + 1) = double(lireParametre(b.parametres, 'Port', numel(rangs) + 1)); %#ok<AGROW>
    end
    % le rang du port est sa place parmi les autres, comme au dépliage
    [~, ordre] = sort(rangs);
    rangs(ordre) = 1:numel(rangs);
end

% L'espace des blocs d'un modèle référencé : son espace de travail — que
% le champ matlibre__modele désigne —, et les valeurs que le bloc Model
% donne à ses arguments (ParameterArgumentNames), par
% ParameterArgumentValues ou InstanceParameters, évaluées là où le bloc
% Model se trouve. Un argument sans valeur garde celle de l'espace de
% travail du modèle référencé.
function W = espaceReference(bloc, interne, chemin, espaceParent)
    nomRef = char(interne.nom);
    W = struct('matlibre__modele', nomRef);
    declares = {};
    if isfield(interne, 'parametres') && isfield(interne.parametres, 'ParameterArgumentNames')
        declares = strtrim(strsplit(char(interne.parametres.ParameterArgumentNames), ','));
        declares = declares(~cellfun(@isempty, declares));
    end
    nomsEspace = matlibre_sl_espace('variables', nomRef);
    for q = 1:numel(declares)
        if ~any(strcmp(nomsEspace, declares{q}))
            error('Simulink:modelReference:ArgumentNotInWorkspace', ...
                  ['L''argument ''%s'' du modele ''%s'' (ParameterArgumentNames), que ''%s'' ' ...
                   'reference, n''est pas une variable de son espace de travail : posez-l''y ' ...
                   '(get_param(modele, ''ModelWorkspace'')).'], declares{q}, nomRef, chemin);
        end
    end
    [noms, valeurs] = valeursArguments(bloc.parametres, chemin);
    for q = 1:numel(noms)
        if ~any(strcmp(declares, noms{q}))
            liste = strjoin(declares, ', ');
            if isempty(liste)
                liste = 'aucun';
            end
            error('Simulink:modelReference:NotAnArgument', ...
                  ['Le bloc Model ''%s'' donne une valeur a ''%s'', qui n''est pas un argument ' ...
                   'du modele ''%s'' (ParameterArgumentNames : %s).'], chemin, noms{q}, ...
                  nomRef, liste);
        end
        v = valeurs{q};
        if ischar(v) || isstring(v)
            if isempty(strtrim(char(v)))
                continue   % sans valeur : celle de l'espace de travail du modèle référencé
            end
            v = matlibre_sl_masque('evaluer', char(v), espaceParent, chemin, noms{q});
        end
        W.(noms{q}) = v;
    end
end

% Les arguments que donne un bloc Model : ParameterArgumentValues, une
% structure dont chaque champ est un argument, et InstanceParameters, une
% structure par argument (Name, Value) — ou l'expression qui les écrit,
% telle qu'un fichier la relit.
function [noms, valeurs] = valeursArguments(p, chemin)
    noms = {};
    valeurs = {};
    valeursArg = lireStructure(lireParametre(p, 'ParameterArgumentValues', []), chemin, ...
                               'ParameterArgumentValues');
    if ~isempty(valeursArg)
        if ~isscalar(valeursArg)
            error('Simulink:modelReference:InvalidArgumentValues', ...
                  ['ParameterArgumentValues du bloc Model ''%s'' est une structure, un champ ' ...
                   'par argument.'], chemin);
        end
        for f = fieldnames(valeursArg).'
            noms{end + 1} = f{1}; %#ok<AGROW>
            valeurs{end + 1} = valeursArg.(f{1}); %#ok<AGROW>
        end
    end
    instances = lireStructure(lireParametre(p, 'InstanceParameters', []), chemin, ...
                              'InstanceParameters');
    if ~isempty(instances)
        if ~isfield(instances, 'Name') || ~isfield(instances, 'Value')
            error('Simulink:modelReference:InvalidArgumentValues', ...
                  ['InstanceParameters du bloc Model ''%s'' est une structure par argument, ' ...
                   'de champs Name et Value.'], chemin);
        end
        for i = 1:numel(instances)
            noms{end + 1} = char(instances(i).Name); %#ok<AGROW>
            valeurs{end + 1} = instances(i).Value; %#ok<AGROW>
        end
    end
end

function v = lireStructure(v, chemin, nom)
    if isstring(v)
        v = char(v);
    end
    if ischar(v)
        texte = strtrim(v);
        if isempty(texte) || strcmp(texte, '[]')
            v = [];
            return
        end
        try
            v = eval(texte);
        catch err
            error('Simulink:modelReference:InvalidArgumentValues', ...
                  '%s du bloc Model ''%s'' ne se lit pas : %s', nom, chemin, err.message);
        end
    end
    if isempty(v) && ~isstruct(v)
        v = [];
        return
    end
    if ~isstruct(v)
        error('Simulink:modelReference:InvalidArgumentValues', ...
              '%s du bloc Model ''%s'' est une structure.', nom, chemin);
    end
end

% Ce qu'est un diagramme : 'model', 'library' ou 'subsystem'
% (BlockDiagramType).
function genre = genreDiagramme(modele)
    genre = 'model';
    if isfield(modele, 'parametres') && isfield(modele.parametres, 'BlockDiagramType')
        genre = lower(char(modele.parametres.BlockDiagramType));
    end
end

function texte = libelleDiagramme(genre)
    switch genre
        case 'library'
            texte = 'e bibliotheque';
        otherwise
            texte = ' modele';
    end
end

function v = lireParametre(p, nom, defaut)
    v = defaut;
    champs = fieldnames(p);
    for k = 1:numel(champs)
        if strcmpi(champs{k}, nom)
            v = p.(champs{k});
            if ischar(v) && any(strcmpi(nom, {'Port'}))
                v = str2double(v);
            end
            return
        end
    end
end

% Les ports de contrôle d'un sous-système : Enable, Trigger, Action Port,
% un de chaque au plus, et Action Port seul. G est le rang de celui qui
% devient la garde, 0 s'il n'y en a pas. CONTROLES.ordre les range comme
% les entrées de contrôle du bloc : Enable, puis Trigger ; ou Action.
function [controles, g] = portsDeControle(interne, chemin)
    controles = struct('enable', 0, 'trigger', 0, 'action', 0, 'reset', 0, 'ordre', [], ...
                       'tous', []);
    noms = {'enableport', 'enable'; 'triggerport', 'trigger'; 'actionport', 'action'; ...
            'resetport', 'reset'};
    for i = 1:size(noms, 1)
        trouves = find(cellfun(@(b) strcmp(b.type, noms{i, 1}), interne.blocs));
        if numel(trouves) > 1
            ports = cellfun(@(b) ['''' chemin '/' char(b.nom) ''''], ...
                            interne.blocs(trouves), 'UniformOutput', false);
            error('Simulink:blocks:ControlPortDuplicate', ...
                  ['Le sous-systeme ''%s'' porte %d ports de la meme sorte (%s) : un ' ...
                   'sous-systeme n''a qu''un port de chaque sorte.'], chemin, ...
                  numel(trouves), strjoin(ports, ', '));
        end
        if ~isempty(trouves)
            controles.(noms{i, 2}) = trouves;
        end
    end
    if controles.action > 0 && (controles.enable > 0 || controles.trigger > 0)
        error('Simulink:blocks:ActionPortWithEnableTrigger', ...
              ['Le sous-systeme ''%s'' porte un Action Port avec un port Enable ou ' ...
               'Trigger : un sous-systeme d''action n''a que son Action Port.'], ...
              chemin);
    end
    if controles.action > 0 && controles.reset > 0
        error('Simulink:blocks:ActionPortWithReset', ...
              ['Le sous-systeme ''%s'' porte un Action Port avec un port Reset : un ' ...
               'sous-systeme d''action n''a que son Action Port.'], chemin);
    end
    controles.ordre = [controles.enable, controles.trigger, controles.action, controles.reset];
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
               'Action', double(controles.action > 0), 'Reset', 0, 'ZeroCross', 'on', ...
               'ResetPort', 'none');
    if controles.reset > 0
        p.ResetPort = 'rising';
        q = interne.blocs{controles.reset}.parametres;
        if isfield(q, 'ResetTriggerType')
            p.ResetPort = lower(char(q.ResetTriggerType));
        end
    end
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

% La période qu'impose un sous-système atomique (TreatAsAtomicUnit 'on')
% dont SystemSampleTime n'est pas -1, ou celle qu'il tient de celui qui le
% contient ; [] s'il n'en impose pas.
function ts = periodeImposee(bloc, chemin)
    ts = [];
    if isfield(bloc, 'periodeImposee')
        ts = bloc.periodeImposee;
    end
    p = bloc.parametres;
    atomique = strcmpi(char(lireParametre(p, 'TreatAsAtomicUnit', 'off')), 'on');
    if ~atomique
        return
    end
    v = lireParametre(p, 'SystemSampleTime', -1);
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), chemin, 'SystemSampleTime');
    end
    v = double(v);
    if isempty(v) || ~isnumeric(v) || ~all(isfinite(v(1))) || v(1) == -1
        return
    end
    if v(1) <= 0
        error('Simulink:SampleTime:InvalidSystemSampleTime', ...
              ['La periode du sous-systeme atomique ''%s'' (SystemSampleTime) est -1, ' ...
               'qu''il herite, ou une periode discrete positive : pas %g.'], chemin, v(1));
    end
    ts = v(1);
end

% Un bloc dans un sous-système atomique qui impose sa période : il en
% hérite si la sienne est héritée (-1), et la sienne doit être la même
% sinon — une constante (Inf) mise à part. Un bloc continu y est refusé.
function enfant = imposerPeriode(enfant, ts, chemin)
    nom = [chemin '/' regexprep(char(enfant.nom), '^.*/', '')];
    if any(strcmp(enfant.type, {'subsystem', 'modelreference', 'subsystemreference'}))
        enfant.periodeImposee = ts;
        return
    end
    try
        entree = matlibre_sl_catalogue('type', enfant.type);
    catch
        return
    end
    % la période se nomme SampleTime, ou tsamp pour un compteur ou un
    % Repeating Sequence Stair
    nomPeriode = '';
    for candidat = {'SampleTime', 'tsamp'}
        if isempty(nomPeriode) && ~isempty(entree.params) && ...
           any(strcmp(entree.params(:, 1), candidat{1}))
            nomPeriode = candidat{1};
        end
    end
    aPeriode = ~isempty(nomPeriode);
    if ~aPeriode
        if strcmp(entree.famille, 'Continu')
            error('Simulink:SampleTime:AtomicSubsystemContinuousBlock', ...
                  ['Le bloc continu ''%s'' est dans le sous-systeme atomique ''%s'', qui ' ...
                   'impose la periode discrete %g (SystemSampleTime) : un bloc continu ' ...
                   'n''y a pas sa place.'], nom, chemin, ts);
        end
        return
    end
    v = lireParametre(enfant.parametres, nomPeriode, -1);
    if ischar(v) || isstring(v)
        try
            v = matlibre_sl_expression(char(v), chemin, nomPeriode);
        catch
            return   % la compilation dira ce qui ne va pas
        end
    end
    v = double(v);
    if isempty(v) || v(1) == -1
        champ = nomPeriode;
        for f = fieldnames(enfant.parametres).'
            if strcmpi(f{1}, nomPeriode)
                champ = f{1};
            end
        end
        enfant.parametres.(champ) = ts;
    elseif isinf(v(1)) || abs(v(1) - ts) <= 1e-12 * max(1, ts)
        return
    else
        error('Simulink:SampleTime:AtomicSubsystemSampleTimeMismatch', ...
              ['Le bloc ''%s'' a la periode %g, et le sous-systeme atomique ''%s'' qui le ' ...
               'contient impose %g (SystemSampleTime) : ses blocs heritent de sa periode ' ...
               '(-1) ou ont la meme.'], nom, v(1), chemin, ts);
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

% L'événement d'une fonction d'événement : l'EventType de son seul Event
% Listener. Elle n'a ni entrée ni sortie, et ne se pose ni dans une autre
% fonction d'événement ni dans un sous-système conditionnel.
function evenement = evenementDe(interne, ecouteurs, entrees, sorties, controles, chemin, ...
                                 parent, gardeParent)
    if numel(ecouteurs) > 1
        error('Simulink:blocks:EventListenerMultiple', ...
              ['Le sous-systeme ''%s'' porte %d blocs Event Listener : une fonction ' ...
               'd''evenement n''en a qu''un.'], chemin, numel(ecouteurs));
    end
    if ~isempty(entrees) || ~isempty(sorties) || ~isempty(controles.ordre)
        error('Simulink:blocks:EventFunctionPorts', ...
              ['La fonction d''evenement ''%s'' a des ports : elle n''a ni entree ni ' ...
               'sortie. Elle lit l''etat des blocs (State Reader, Data Store Read) et ' ...
               'l''ecrit (State Writer, Data Store Write).'], chemin);
    end
    if ~isempty(parent) || gardeParent > 0
        error('Simulink:blocks:EventFunctionNested', ...
              ['La fonction d''evenement ''%s'' est dans une autre fonction d''evenement ou ' ...
               'dans un sous-systeme conditionnel : elle se pose dans le modele, ou dans un ' ...
               'sous-systeme qui calcule toujours.'], chemin);
    end
    p = interne.blocs{ecouteurs}.parametres;
    evenement = 'Initialize';
    for nom = fieldnames(p).'
        if strcmpi(nom{1}, 'EventType')
            evenement = char(p.(nom{1}));
        end
    end
    choix = {'Initialize', 'Reset', 'Terminate'};
    j = find(strcmpi(evenement, choix), 1);
    if isempty(j)
        error('Simulink:Parameters:InvalidValue', ...
              'L''EventType de l''Event Listener de ''%s'' vaut Initialize, Reset ou Terminate.', ...
              chemin);
    end
    evenement = choix{j};
end
