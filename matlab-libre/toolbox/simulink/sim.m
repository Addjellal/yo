function varargout = sim(modele, varargin)
%SIM Simule un modèle.
%   RESULTAT = SIM(MODELE) simule le modèle avec ses propres réglages :
%   instants de début et de fin, solveur, pas. RESULTAT porte le vecteur
%   des instants et, pour chaque bloc, le signal relevé à sa sortie — ou,
%   pour un bloc qui n'en a pas, ce qui arrive à son entrée.
%
%   SIM(MODELE,TFINAL) fixe l'instant final ; SIM(MODELE,[TDEBUT TFINAL])
%   les deux ; SIM(MODELE,INSTANTS) donne aussi le pas par l'écart de
%   deux instants réguliers. SIM(MODELE,TFINAL,PAS) fixe le pas, et
%   SIM(MODELE,TFINAL,SIMSET(...)) accepte un jeu d'options à la place.
%   SIM(MODELE,INTERVALLE,OPTIONS,[T, U]) alimente les entrées du modèle :
%   le temps, puis une colonne par élément des entrées, rangées par leur
%   paramètre Port ; une structure à temps y sert aussi. Les réglages
%   LoadExternalInput ('on') et ExternalInput ('[t, u]', ou des variables
%   séparées par des virgules, une par entrée) le disent sur le modèle.
%   SIM(MODELE,'StopTime','5','Solver','ode4',...) passe les réglages par
%   nom, comme dans Simulink : ils valent pour cette simulation seulement,
%   et le modèle n'en est pas changé.
%
%   Les réglages sont ceux de la boîte « Paramètres de configuration » de
%   Simulink, que SET_PARAM(MODELE,'Solver','ode4') pose sur le modèle et
%   que GET_PARAM relit : StartTime, StopTime, Solver, FixedStep, RelTol,
%   AbsTol, MaxStep, MinStep, InitialStep, MaxOrder, ExtrapolationOrder,
%   NumberNewtonIterations, ZeroCrossControl, et les
%   diagnostics AlgebraicLoopMsg, UnconnectedInputMsg et
%   UnconnectedOutputMsg (none, warning ou error). Un argument explicite
%   l'emporte toujours sur le réglage enregistré.
%
%   Les solveurs à pas fixe : ode1 (Euler, celui par défaut), ode2
%   (Heun), ode3 (Bogacki-Shampine), ode4 (Runge-Kutta), ode5
%   (Dormand-Prince) et ode8 (Prince-Dormand) ; l'erreur d'un solveur
%   d'ordre p décroît comme le pas à la puissance p. Pour les systèmes
%   raides, ode1be (Euler implicite) et ode14x (Euler implicite
%   extrapolé, d'ordre ExtrapolationOrder), qui font NumberNewtonIterations
%   itérations de Newton par pas. FixedStepDiscrete sert aux modèles sans
%   état continu, et FixedStepAuto choisit ode3 ou le discret.
%
%   Les solveurs à pas variable : ode45 (Dormand-Prince 5(4)), ode23
%   (Bogacki-Shampine 3(2)), ode113 (Adams, d'ordre variable, pour les
%   tolérances fines), et pour les systèmes raides ode15s (NDF, d'ordre 1
%   à MaxOrder), ode23s (Rosenbrock), ode23t (trapèzes) et ode23tb
%   (TR-BDF2) ; VariableStepDiscrete, et VariableStepAuto qui choisit
%   ode45 ou le discret. Le pas suit l'erreur estimée — RelTol, AbsTol —, borné
%   par MaxStep (le cinquantième de la durée par défaut) et MinStep. Il
%   s'arrête exactement sur les instants d'échantillonnage et les
%   cassures des sources (échelon, fronts d'impulsion) ; un seuil franchi
%   dans un pas — l'entrée d'un relais, d'une saturation, d'un
%   aiguillage, d'un Hit Crossing — est localisé par la détection des
%   passages par zéro, que règlent ZeroCrossControl et le paramètre
%   ZeroCross de chaque bloc. Le relevé porte alors un instant par pas
%   majeur ; SIM(MODELE,[T0 T1 ... TN]) ne relève que les instants donnés,
%   que le solveur atteint exactement.
%
%   Les signaux sont des scalaires, des vecteurs ou des matrices : un Mux
%   réunit ses entrées en un vecteur, un Demux les sépare, un gain
%   matriciel les combine. Un bloc peut avoir plusieurs sorties. Avant de
%   simuler, le modèle est compilé : chaque bloc est vérifié — ses
%   paramètres, ses ports, les dimensions de ses signaux, sa période
%   d'échantillonnage —, et chaque erreur le nomme par son chemin,
%   « modele/bloc ». L'ordre de calcul suit le câblage. Une boucle qui
%   ne passe par aucun bloc à état est algébrique : elle est résolue à
%   chaque pas par la méthode de Newton, et signalée selon le réglage
%   AlgebraicLoopMsg.
%
%   Les blocs échantillonnés ne calculent qu'aux instants de leur
%   période — qui, à pas fixe, doit être un multiple du pas — et gardent
%   leur valeur entre deux. Un solveur d'ordre supérieur évalue le modèle
%   en des points intermédiaires du pas ; les états discrets n'y bougent
%   pas.
%
%   Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
%   ne reste que de l'arithmétique. Un paramètre numérique donné entre
%   apostrophes est une expression, évaluée à ce moment-là dans l'espace
%   de travail de base : changer la variable et relancer SIM change le
%   résultat sans que le modèle ait bougé. Les blocs « toworkspace » et
%   « fromworkspace » font l'échange dans les deux sens.
%
%   Un bloc « subsystem » porte tout un modèle : SIM le déplie avant de
%   simuler, et rend exactement ce que rendrait le schéma écrit à plat.
%   Le relevé porte alors les blocs intérieurs sous le nom
%   « sousSysteme/bloc », et le sous-système lui-même la valeur de sa
%   première sortie.
%
%   SIM('NOM') accepte aussi le nom d'un modèle : une variable de
%   l'espace de travail qui porte ce nom, ou un fichier NOM.m qui
%   construit le modèle et le rend.
%
%   OUT = SIM(IN), IN un SIMULINK.SIMULATIONINPUT, simule son modèle avec
%   les variables, les paramètres de blocs et les réglages qu'il pose, le
%   temps de cette simulation ; un tableau IN se simule l'une après
%   l'autre, comme par PARSIM. OUT porte en plus ErrorMessage et
%   SimulationMetadata. L'erreur d'un seul SimulationInput part comme
%   celle de SIM(NOM), sauf avec SIM(IN,'CaptureErrors','on'), qui la
%   range dans ErrorMessage ; celle d'un tableau y est toujours rangée.
%
%   Un signal dont le port de sortie a DataLogging à 'on' — SET_PARAM
%   sur la poignée que rend GET_PARAM(M,BLOC,'PortHandles') — est
%   journalisé : RESULTAT.logsout est un Simulink.SimulationData.Dataset,
%   un élément par signal, avec son nom, le chemin de son bloc, son port
%   et ses valeurs en timeseries. SignalLogging ('off') l'éteint, et
%   SignalLoggingName renomme le champ.
%
%   LoadInitialState ('on') et InitialState (un vecteur, ou l'expression
%   qui le donne) posent l'état continu de départ, dans l'ordre des
%   colonnes de xout ; SaveFinalState ('on') range l'état final dans le
%   champ FinalStateName ('xFinal') du résultat. Ensemble, ils reprennent
%   une simulation là où la précédente s'est arrêtée.
%
%   Ce qui est relevé se règle comme dans le volet « Data Import/Export »
%   de Simulink. SaveTime, SaveState et SaveOutput disent si le résultat
%   porte les instants, les états continus et les sorties OUTPORT, et
%   TimeSaveName ('tout'), StateSaveName ('xout') et OutputSaveName
%   ('yout') sous quel nom ; les états n'y sont que si SaveState vaut
%   'on'. Decimation n'en garde qu'un instant sur n, et LimitDataPoints
%   ('on') les MaxDataPoints derniers. À pas variable, OutputOption
%   choisit les instants : RefineOutputTimes relève chaque pas du
%   solveur, et Refine - 1 points entre deux, où le modèle est calculé
%   sur l'état interpolé ; AdditionalOutputTimes y ajoute les instants
%   OutputTimes, que le solveur atteint exactement ;
%   SpecifiedOutputTimes ne relève que le début, la fin et les instants
%   OutputTimes. SIMSET porte les mêmes réglages sous leurs noms anciens :
%   Refine, OutputPoints ('all' : les instants donnés et chaque pas),
%   Decimation, MaxDataPoints.
%
%   Le résultat porte plusieurs formes. RESULTAT.temps et
%   RESULTAT.signaux.<nom> pour l'accès direct — un signal vecteur y est
%   une matrice à une ligne par instant, un signal matrice un tableau
%   m x n x N, et la deuxième sortie d'un bloc s'appelle <nom>_port2.
%   RESULTAT.time et RESULTAT.signals(k).values pour la « structure with
%   time » de Simulink ; RESULTAT.tout et RESULTAT.yout pour les
%   instants et les sorties OUTPORT, et RESULTAT.xout pour les états
%   continus si SaveState vaut 'on'. [T,X,Y] = SIM(...) rend ces trois
%   derniers, états compris, comme la forme ancienne de Simulink.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%      abs(r.signaux.integ(end) - 10) < 0.01     % l'integrale de 2 sur 5 s
%      m = set_param(m, 'Solver', 'ode4', 'StopTime', 1);
%      r = sim(m);
%      r.temps(end)                               % 1
%      r = sim(m, 'Solver', 'ode45', 'RelTol', 1e-6);
%      abs(r.signaux.integ(end) - 2) < 1e-9       % exact : l'état est une droite
%
%   Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SET_PARAM, SIMSET, LINMOD.
    if isa(modele, 'Simulink.SimulationInput')
        % Chaque SimulationInput nomme son modèle : une variable de
        % l'appelant qui en porte le nom d'abord, comme pour SIM(NOM).
        modeles = cell(1, numel(modele));
        for k = 1:numel(modele)
            nom = modele(k).ModelName;
            if isvarname(nom) && evalin('caller', sprintf('exist(''%s'', ''var'')', nom)) == 1
                candidat = evalin('caller', nom);
                if isstruct(candidat) && isfield(candidat, 'blocs')
                    modeles{k} = candidat;
                end
            end
        end
        varargout{1} = matlibre_sl_lot('sim', modele, modeles, varargin{:});
        return
    end
    if ischar(modele) || isstring(modele)
        % L'espace de travail à consulter est celui de l'appelant de SIM :
        % « evalin('caller') » depuis une sous-fonction ne verrait que
        % l'espace de SIM lui-même.
        nom = char(modele);
        if isvarname(nom) && evalin('caller', sprintf('exist(''%s'', ''var'')', nom)) == 1
            modele = evalin('caller', nom);
        else
            modele = chargerModele(nom);
        end
    end
    if ~isstruct(modele) || ~isfield(modele, 'blocs')
        error('Simulink:Commands:InvalidModel', ...
              ['SIM expects a model built with NEW_SYSTEM, ADD_BLOCK and ' ...
               'ADD_LINE, or the name of one.']);
    end

    if isfield(modele, 'parametres') && isfield(modele.parametres, 'BlockDiagramType') && ...
       strcmpi(modele.parametres.BlockDiagramType, 'library')
        error('Simulink:Engine:CannotSimulateLibrary', ...
              ['''%s'' est une bibliotheque : ses blocs se posent dans un modele, par ' ...
               'ADD_BLOCK(M, ''%s/bloc'', NOM), et c''est le modele qui se simule.'], ...
              char(modele.nom), char(modele.nom));
    end
    % InitFcn d'abord : les variables qu'il pose servent aux réglages et
    % aux blocs, comme dans Simulink.
    matlibre_sl_rappel(modele, 'InitFcn');
    [config, imposes, externe, tousLesPas] = lireArguments(matlibre_sl_config('lire', modele), ...
                                                           varargin);
    nomModele = char(modele.nom);
    tDebut = nombre(config.StartTime, nomModele, 'StartTime');
    tFinal = nombre(config.StopTime, nomModele, 'StopTime');
    if ~isscalar(tFinal) || ~(tFinal >= tDebut)
        error('Simulink:SolverConfig:StopTimeBeforeStartTime', ...
              'La duree doit etre un nombre positif : l''instant final precede le debut.');
    end
    variable = strcmpi(matlibre_sl_config('type', config.Solver), 'Variable-step');
    sortie = instantsDeSortie(config, variable, imposes, tousLesPas, tDebut, tFinal, nomModele);
    solveur = lower(char(config.Solver));
    if strcmp(solveur, 'oden')
        % odeN : la formule que choisit ODENIntegrationMethod, à pas fixe,
        % sans rien adapter
        solveur = lower(char(config.ODENIntegrationMethod));
    end
    pas = config.FixedStep;
    if ischar(pas) && strcmpi(pas, 'auto')
        pas = (tFinal - tDebut) / 50;
        if ~(pas > 0) || isinf(pas)
            pas = 0.01;
        end
    else
        pas = nombre(pas, nomModele, 'FixedStep');
    end
    if ~isscalar(pas) || ~(pas > 0) || isinf(pas)
        error('Simulink:SolverConfig:InvalidFixedStep', 'Le pas doit etre un nombre strictement positif.');
    end

    options = struct('pas', pas, 'tDebut', tDebut, 'tFinal', tFinal, 'config', config, ...
                     'variable', variable);
    % Les entrées externes : le quatrième argument, ou ExternalInput quand
    % LoadExternalInput vaut 'on'. Chaque entrée du modèle y prend sa part.
    if ~isempty(externe)
        options.entrees = entreesExternes(modele, externe, nomModele);
    elseif strcmpi(config.LoadExternalInput, 'on')
        options.entrees = entreesExternes(modele, config.ExternalInput, nomModele);
    end
    c = matlibre_sl_compiler(modele, options);
    if strcmpi(config.LoadInitialState, 'on')
        c.xDepart = etatInitial(config.InitialState, c, nomModele);
    end
    % Les solveurs automatiques choisissent selon qu'il y a des états
    % continus ou non, comme dans Simulink.
    continus = ~isempty(c.x0);
    switch solveur
        case 'variablestepauto'
            solveur = 'ode45';
            if ~continus
                solveur = 'variablestepdiscrete';
            end
        case 'fixedstepauto'
            solveur = 'ode3';
            if ~continus
                solveur = 'fixedstepdiscrete';
            end
    end
    if any(strcmp(solveur, {'fixedstepdiscrete', 'variablestepdiscrete'})) && continus
        k = find(c.xA > 0, 1);
        if variable
            autres = 'ode45, ode23, ode113, ode15s, ode23s, ode23t ou ode23tb';
        else
            autres = 'ode1 a ode5, ode8, ode14x ou ode1be';
        end
        error('Simulink:Engine:DiscreteSolverContinuousStates', ...
              ['Le modele ''%s'' porte des etats continus — le bloc ''%s'' en a — que ' ...
               'le solveur discret %s n''integre pas. Choisissez un solveur %s.'], ...
              c.nom, c.chemins{k}, char(config.Solver), autres);
    end
    % StartFcn quand la simulation commence, StopFcn quand elle s'achève —
    % sur une erreur aussi.
    matlibre_sl_rappel(modele, 'StartFcn');
    deroulement = {c, config, variable, solveur, tDebut, tFinal, pas, sortie, nomModele};
    try
        [T, J, instants] = derouler(deroulement{:}, false);
        resultat = assembler(c, T, J, instants(:));
        resultat = deposer(c, T, J, instants(:), resultat);
        % Le journal des signaux : ceux dont le port a DataLogging à 'on'.
        journalSignaux = [];
        if strcmpi(config.SignalLogging, 'on')
            journalSignaux = matlibre_sl_signaux('journal', c, T, J, instants(:));
            if journalSignaux.numElements > 0
                journalSignaux.Name = char(config.SignalLoggingName);
                resultat.(char(config.SignalLoggingName)) = journalSignaux;
            else
                journalSignaux = [];
            end
        end
    catch err
        matlibre_sl_rappel(modele, 'StopFcn');
        if strncmp(err.identifier, 'Simulink:', 9) || strncmp(err.identifier, 'Stateflow:', 10) || ...
           strncmp(err.identifier, 'Simscape:', 9)
            rethrow(err);
        end
        throw(localiser(err, deroulement));
    end
    matlibre_sl_rappel(modele, 'StopFcn');
    % L'état final, pour reprendre plus tard là où l'on s'arrête : les
    % états continus au dernier instant, dans l'ordre des colonnes de xout.
    if strcmpi(config.SaveFinalState, 'on')
        xFinal = zeros(1, size(resultat.xout, 2));
        if ~isempty(resultat.xout)
            xFinal = resultat.xout(end, :);
        end
        resultat.(char(config.FinalStateName)) = xFinal;
    end
    % Un instant sur Decimation, les MaxDataPoints derniers : ce que
    % l'export garde des instants, des états et des sorties.
    resultat = decimer(resultat, config);
    if nargout > 1
        varargout = {resultat.tout, resultat.xout, resultat.yout};
        return
    end
    [resultat, exportes] = nommer(resultat, config);
    if nargout == 0
        % Sans sortie, comme dans Simulink : le résultat va dans OUT — ou
        % dans tout et yout si ReturnWorkspaceOutputs vaut 'off'.
        if strcmpi(config.ReturnWorkspaceOutputs, 'on')
            assignin('base', char(config.ReturnWorkspaceOutputsName), resultat);
        else
            for k = 1:numel(exportes)
                assignin('base', exportes{k}, resultat.(exportes{k}));
            end
            if strcmpi(config.SaveFinalState, 'on')
                assignin('base', char(config.FinalStateName), xFinal);
            end
            if ~isempty(journalSignaux)
                assignin('base', char(config.SignalLoggingName), journalSignaux);
            end
        end
    else
        varargout{1} = resultat;
    end
end

% Les instants relevés à pas variable : ceux que SIM(MODELE,[T0 ... TN])
% impose — seuls, ou avec chaque pas si OutputPoints vaut 'all' —, sinon
% ceux que règlent OutputOption, Refine et OutputTimes. Un solveur à pas
% fixe relève chacun de ses pas, comme dans Simulink où OutputOption ne
% vaut que pour le pas variable.
function s = instantsDeSortie(config, variable, imposes, tousLesPas, tDebut, tFinal, nomModele)
    s = struct('imposes', imposes, 'tous', tousLesPas || isempty(imposes), 'affiner', 1);
    if ~variable
        return
    end
    if ~isempty(imposes)
        if tousLesPas
            s.affiner = double(config.Refine);
        end
        return
    end
    switch char(config.OutputOption)
        case 'RefineOutputTimes'
            s.affiner = double(config.Refine);
        case 'AdditionalOutputTimes'
            s.imposes = instantsDemandes(config.OutputTimes, tDebut, tFinal, nomModele);
        case 'SpecifiedOutputTimes'
            bornes = tDebut;
            if isfinite(tFinal)
                bornes = [tDebut, tFinal];
            end
            s.imposes = unique([bornes, instantsDemandes(config.OutputTimes, tDebut, tFinal, ...
                                                         nomModele)]);
            s.tous = false;
    end
end

% OutputTimes, évalué : les instants de l'intervalle simulé, triés.
function t = instantsDemandes(v, tDebut, tFinal, nomModele)
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), nomModele, 'OutputTimes');
    end
    if ~((isnumeric(v) || islogical(v)) && isreal(v) && (isvector(v) || isempty(v))) || ...
       any(isnan(double(v(:))))
        error('Simulink:Config:InvalidValue', ...
              ['Le reglage OutputTimes du modele ''%s'' est un vecteur d''instants, ou ' ...
               'l''expression qui le donne.'], nomModele);
    end
    t = unique(double(v(:)).');
    t = t(t >= tDebut & t <= tFinal);
end

% Decimation et MaxDataPoints : les instants gardés de tout, xout et
% yout, sous chacune de ses formes. Le journal des signaux et les blocs To
% Workspace ont leurs propres réglages ; RESULTAT.temps et
% RESULTAT.signaux gardent tout.
function resultat = decimer(resultat, config)
    N = numel(resultat.tout);
    garde = 1:double(config.Decimation):N;
    if strcmpi(config.LimitDataPoints, 'on') && numel(garde) > double(config.MaxDataPoints)
        garde = garde(end - double(config.MaxDataPoints) + 1:end);
    end
    if numel(garde) == N
        return
    end
    resultat.tout = resultat.tout(garde);
    resultat.xout = resultat.xout(garde, :);
    y = resultat.yout;
    if isnumeric(y) || islogical(y)
        resultat.yout = y(garde, :);
    elseif isstruct(y)
        if ~isempty(y.time)
            y.time = y.time(garde);
        end
        for k = 1:numel(y.signals)
            y.signals(k).values = instantsGardes(y.signals(k).values, garde, N);
        end
        resultat.yout = y;
    else
        decime = Simulink.SimulationData.Dataset(y.Name);
        for k = 1:y.numElements
            s = y.getElement(k);
            v = s.Values;
            s.Values = timeseries(instantsGardes(v.Data, garde, N), v.Time(garde), ...
                                  'Name', v.Name);
            decime = addElement(decime, s);
        end
        resultat.yout = decime;
    end
end

% Les instants gardés d'un relevé : ses lignes, ou ses pages s'il est m x
% n x N.
function v = instantsGardes(v, garde, N)
    if ndims(v) == 3 || (size(v, 1) ~= N && size(v, ndims(v)) == N)
        v = v(:, :, garde);
    else
        v = v(garde, :);
    end
end

% SaveTime, SaveState et SaveOutput : les champs que porte le résultat, et
% leurs noms. EXPORTES les nomme, pour l'espace de travail.
function [resultat, exportes] = nommer(resultat, config)
    releves = {resultat.tout, resultat.xout, resultat.yout};
    resultat = rmfield(resultat, {'tout', 'xout', 'yout'});
    reglages = {'SaveTime', 'TimeSaveName'; 'SaveState', 'StateSaveName'; ...
                'SaveOutput', 'OutputSaveName'};
    exportes = {};
    for k = 1:3
        if strcmpi(config.(reglages{k, 1}), 'on')
            nom = char(config.(reglages{k, 2}));
            resultat.(nom) = releves{k};
            exportes{end + 1} = nom; %#ok<AGROW>
        end
    end
end

% La simulation proprement dite : préparer le simulateur, puis avancer à
% pas fixe, à pas variable, ou sans fin. En mode diagnostic, le
% simulateur note chaque bloc qu'il calcule.
function [T, J, instants] = derouler(c, config, variable, solveur, tDebut, tFinal, pas, ...
                                     sortie, nomModele, diagnostic)
    T = matlibre_sl_executer('preparer', c);
    T.diagnostic = diagnostic;
    T.reglagesSolveur = struct('ExtrapolationOrder', config.ExtrapolationOrder, ...
                               'NumberNewtonIterations', config.NumberNewtonIterations, ...
                               'MaxOrder', config.MaxOrder);
    if variable
        reglages = reglagesVariables(config, nomModele);
        J = matlibre_sl_executer('simulerVariable', T, tDebut, tFinal, solveur, ...
                                 reglages, sortie);
        instants = J.temps;
    elseif isinf(tFinal)
        [instants, J] = sansFin(T, tDebut, pas, solveur);
    else
        instants = tDebut:pas:tFinal;
        J = matlibre_sl_executer('simuler', T, instants, solveur);
        instants = instants(1:J.dernier);
    end
end

% Une erreur imprévue pendant la simulation — presque toujours la valeur
% d'un paramètre que le bloc ne sait pas employer. Elle ne dit pas quel
% bloc calculait : on rejoue la simulation en mode diagnostic, qui le
% note, pour rendre l'erreur de Simulink qui le nomme. Si le rejeu passe,
% l'erreur n'était pas celle d'un bloc : elle reste telle quelle.
function err = localiser(err, deroulement)
    matlibre_sl_executer('encours', 0);
    echoue = false;
    try
        derouler(deroulement{:}, true);
    catch
        echoue = true;
    end
    k = matlibre_sl_executer('encours');
    c = deroulement{1};
    if echoue && k >= 1 && k <= c.n
        err = matlibre_sl_fautif(err, c.types{k}, c.p{k}, c.chemins{k});
    end
end

% Les arguments après le modèle : la forme ancienne (instant final, pas
% ou options), ou les réglages par nom. Ils l'emportent sur ceux du
% modèle, qu'ils ne changent pas. IMPOSES porte les instants donnés un à
% un, au-delà de deux : à pas variable, ce sont les seuls relevés — sauf
% si l'option OutputPoints de SIMSET vaut 'all' (TOUSLESPAS).
function [config, imposes, externe, tousLesPas] = lireArguments(config, args)
    imposes = [];
    externe = [];
    tousLesPas = false;
    if isempty(args)
        return
    end
    if ischar(args{1}) || isstring(args{1})
        if mod(numel(args), 2) ~= 0
            error('Simulink:Commands:SimArguments', ...
                  'Les reglages se donnent par paires : un nom, une valeur.');
        end
        for k = 1:2:numel(args)
            config = poser(config, args{k}, args{k + 1});
        end
        return
    end
    if isstruct(args{1}) && ~isfield(args{1}, 'FixedStep')
        champs = fieldnames(args{1});
        for k = 1:numel(champs)
            config = poser(config, champs{k}, args{1}.(champs{k}));
        end
        return
    end
    intervalle = args{1};
    if ~isempty(intervalle)
        intervalle = double(intervalle(:)).';
        if isscalar(intervalle)
            config.StopTime = intervalle;
        else
            ecarts = diff(intervalle);
            if any(ecarts <= 0)
                error('Simulink:SolverConfig:TimeSpanNotIncreasing', ...
                      'Les instants doivent etre strictement croissants.');
            end
            config.StartTime = intervalle(1);
            config.StopTime = intervalle(end);
            % Deux bornes ne disent rien du pas ; au-delà, c'est l'écart qui
            % le donne — sauf si un troisième argument le dit.
            if numel(intervalle) > 2 && numel(args) < 2
                config.FixedStep = ecarts(1);
            end
            if numel(intervalle) > 2
                imposes = intervalle;
            end
        end
    end
    if numel(args) >= 2 && ~isempty(args{2})
        troisieme = args{2};
        if isstruct(troisieme)
            demande = simget(troisieme, 'Solver');
            if ~isempty(demande)
                config = poser(config, 'Solver', demande);
            end
            for nom = {'FixedStep', 'RelTol', 'AbsTol', 'MaxStep', 'MinStep', 'InitialStep', ...
                       'MaxOrder'}
                choisi = simget(troisieme, nom{1});
                if ~isempty(choisi)
                    config = poser(config, nom{1}, choisi);
                end
            end
            for nom = {'Refine', 'Decimation', 'SaveFormat', 'ExtrapolationOrder', ...
                       'NumberNewtonIterations'}
                choisi = simget(troisieme, nom{1});
                if ~isempty(choisi)
                    config = poser(config, nom{1}, choisi);
                end
            end
            limite = simget(troisieme, 'MaxDataPoints');
            if ~isempty(limite)
                config.LimitDataPoints = 'off';   % zéro : tous les instants
                if limite > 0
                    config = poser(config, 'MaxDataPoints', limite);
                    config.LimitDataPoints = 'on';
                end
            end
            points = simget(troisieme, 'OutputPoints');
            if ~isempty(points)
                tousLesPas = strcmpi(char(points), 'all');
            end
            etat = simget(troisieme, 'InitialState');
            if ~isempty(etat)
                config = poser(config, 'InitialState', etat);
                config.LoadInitialState = 'on';
            end
            nomFinal = simget(troisieme, 'FinalStateName');
            if ~isempty(nomFinal)
                config = poser(config, 'FinalStateName', nomFinal);
                config.SaveFinalState = 'on';
            end
            detection = simget(troisieme, 'ZeroCross');
            if ~isempty(detection)
                if strcmpi(char(detection), 'off')
                    config.ZeroCrossControl = 'DisableAll';
                else
                    config.ZeroCrossControl = 'UseLocalSettings';
                end
            end
        else
            if ~(isnumeric(troisieme) && isscalar(troisieme) && troisieme > 0)
                error('Simulink:SolverConfig:InvalidFixedStep', 'Le pas doit etre un nombre strictement positif.');
            end
            config.FixedStep = double(troisieme);
        end
    end
    if numel(args) >= 3
        externe = args{3};
    end
    if numel(args) >= 4
        error('Simulink:Commands:SimArguments', ...
              'SIM(MODELE,INTERVALLE,OPTIONS,ENTREES) prend au plus quatre arguments.');
    end
end

function config = poser(config, nom, valeur)
    canon = matlibre_sl_config('nom', nom);
    if isempty(canon)
        error('Simulink:Commands:ParamUnknown', ...
              ['''%s'' n''est pas un reglage de simulation que MatLibre connait ; ' ...
               'les reglages sont : %s.'], char(nom), ...
              strjoin(fieldnames(matlibre_sl_config('defauts')).', ', '));
    end
    config.(canon) = matlibre_sl_config('valider', canon, valeur);
    % Le solveur et son type vont ensemble, comme sur le modèle.
    if strcmp(canon, 'Solver')
        config.SolverType = matlibre_sl_config('type', config.Solver);
    elseif strcmp(canon, 'SolverType') && ...
           ~strcmp(matlibre_sl_config('type', config.Solver), config.SolverType)
        config.Solver = matlibre_sl_config('automatique', config.SolverType);
    end
end

% Les réglages du pas variable, évalués et vérifiés : un nombre, ou
% 'auto' là où Simulink l'admet.
function r = reglagesVariables(config, nomModele)
    r = struct();
    for nom = {'RelTol', 'AbsTol', 'MaxStep', 'MinStep', 'InitialStep'}
        v = config.(nom{1});
        if ~(ischar(v) && strcmpi(v, 'auto'))
            v = nombre(v, nomModele, nom{1});
            if ~isscalar(v) || ~isreal(v) || isnan(v) || v < 0 || ...
               (v == 0 && ~strcmp(nom{1}, 'MinStep')) || ...
               (isinf(v) && ~strcmp(nom{1}, 'MaxStep'))
                error('Simulink:Config:InvalidValue', ...
                      ['Le reglage %s du modele ''%s'' vaut %s : il faut un nombre ' ...
                       'strictement positif, ou ''auto''.'], nom{1}, nomModele, mat2str(v));
            end
        elseif strcmp(nom{1}, 'RelTol')
            v = 1e-3;
        end
        r.(nom{1}) = v;
    end
    if r.RelTol < 100 * eps
        error('Simulink:Config:InvalidValue', ...
              ['La tolerance relative %g du modele ''%s'' est trop fine pour la ' ...
               'precision des nombres : prenez-la au-dessus de %g.'], r.RelTol, ...
              nomModele, 100 * eps);
    end
    r.MaxOrder = config.MaxOrder;
    if ~ischar(r.MinStep) && ~ischar(r.MaxStep) && r.MinStep > r.MaxStep
        error('Simulink:Config:InvalidValue', ...
              ['Le pas minimal %g du modele ''%s'' depasse son pas maximal %g.'], ...
              r.MinStep, nomModele, r.MaxStep);
    end
end

% L'état de départ que donne InitialState : les états continus, dans
% l'ordre des colonnes de xout — l'état final d'une simulation précédente
% s'y reprend tel quel.
function x = etatInitial(v, c, nomModele)
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), nomModele, 'InitialState');
    end
    if ~(isnumeric(v) || islogical(v)) || ~(isvector(v) || isempty(v))
        error('Simulink:SimInput:InvalidInitialState', ...
              ['L''etat initial du modele ''%s'' est un vecteur : ses etats continus, ' ...
               'dans l''ordre des colonnes de xout.'], nomModele);
    end
    x = double(v(:));
    if numel(x) ~= numel(c.x0)
        error('Simulink:SimInput:InitialStateDimensions', ...
              ['L''etat initial du modele ''%s'' porte %d valeur(s), et le modele %d ' ...
               'etat(s) continu(s), dans l''ordre des colonnes de xout.'], nomModele, ...
              numel(x), numel(c.x0));
    end
end

% Un réglage numérique peut être une expression de l'espace de travail,
% comme un paramètre de bloc.
function v = nombre(v, modele, nom)
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), modele, nom);
    end
    v = double(v);
end

% Une simulation sans instant final : elle avance par tranches jusqu'à ce
% qu'un bloc Stop Simulation l'arrête.
function [instants, J] = sansFin(T, tDebut, pas, solveur)
    tranche = 4096;
    releve = zeros(numel(T.journal), 0);
    etats = zeros(numel(T.x0), 0);
    reprise = [];
    fait = 0;
    while true
        morceau = tDebut + (fait + (0:tranche - 1)) * pas;
        if isempty(reprise)
            reprise = struct('V', T.V0, 'Z', T.Z0, 'x', T.xDepart, 'i0', 0, 'avancer', true);
            reprise.premier = true;
        end
        J = matlibre_sl_executer('simuler', T, morceau, solveur, reprise);
        releve = [releve, J.releve]; %#ok<AGROW>
        etats = [etats, J.etats]; %#ok<AGROW>
        if J.arret
            instants = tDebut + (0:fait + J.dernier - 1) * pas;
            break
        end
        fait = fait + tranche;
        reprise = struct('V', J.V, 'Z', J.Z, 'x', J.x, 'i0', fait, 'avancer', true);
        reprise.tampons = J.tampons;
    end
    J.releve = releve;
    J.etats = etats;
    J.dernier = size(releve, 2);
end

% Le résultat, sous les formes que Simulink journalise.
function resultat = assembler(c, T, J, instants)
    N = numel(instants);
    resultat = struct();
    resultat.temps = instants;
    resultat.signaux = struct();
    parBloc = cell(1, c.n);
    dimsBloc = cell(1, c.n);
    for q = 1:numel(T.releves)
        R = T.releves(q);
        donnees = forme(J.releve(R.lignes, :), R.dims, N);
        nom = nomValide(c.noms{R.bloc});
        if R.port > 1
            nom = sprintf('%s_port%d', nom, R.port);
        end
        resultat.signaux.(nom) = donnees;
        if R.port == 1
            parBloc{R.bloc} = donnees;
            dimsBloc{R.bloc} = R.dims;
        end
    end
    % La forme « structure with time » de Simulink : c'est celle que lisent
    % les scripts écrits pour lui, avec res.time et res.signals(k).values.
    resultat.time = instants;
    signals = struct('values', {}, 'dimensions', {}, 'label', {}, 'blockName', {});
    for k = 1:c.n
        valeurs = parBloc{k};
        d = dimsBloc{k};
        if isempty(valeurs)
            valeurs = zeros(N, 1);
            d = [1 1];
        end
        signals(k).values = valeurs;
        signals(k).dimensions = dimensionsSimulink(d);
        signals(k).label = c.noms{k};
        signals(k).blockName = c.noms{k};
    end
    resultat.signals = signals;
    resultat.blockName = c.nom;
    resultat.tout = instants;
    resultat.xout = J.etats.';
    yout = zeros(N, 0);
    sorties = find(strcmp(c.types, 'outport'));
    rangs = zeros(size(sorties));
    for i = 1:numel(sorties)
        rangs(i) = double(c.p{sorties(i)}.Port);
    end
    [~, ordre] = sort(rangs);
    typesSorties = zeros(1, numel(sorties));
    for k = sorties(ordre)
        valeurs = parBloc{k};
        d = dimsBloc{k};
        if numel(d) >= 2 && d(1) > 1 && d(2) > 1
            % une matrice est relevée m x n x N : une ligne par instant,
            % ses éléments colonne après colonne
            valeurs = reshape(valeurs, d(1) * d(2), N).';
        end
        yout = [yout, reshape(valeurs, N, [])]; %#ok<AGROW>
    end
    for i = 1:numel(sorties)
        source = c.entrees{sorties(i)}(1);
        typesSorties(i) = 2;
        if source > 0
            typesSorties(i) = c.typePort(source);
        end
    end
    % des sorties toutes d'un même type rendent yout de ce type
    if ~isempty(typesSorties) && all(typesSorties == typesSorties(1)) && typesSorties(1) > 2
        yout = matlibre_sl_types('convertir', typesSorties(1), yout);
    end
    resultat.yout = yout;
    % La forme de yout que demande SaveFormat : la matrice, une structure
    % par sortie, ou un Dataset de timeseries.
    format = 'Array';
    if isstruct(c.config) && isfield(c.config, 'SaveFormat')
        format = char(c.config.SaveFormat);
    end
    if ~strcmp(format, 'Array')
        resultat.yout = youtForme(c, parBloc, dimsBloc, sorties(ordre), typesSorties, ...
                                  instants, format);
    end
end

function y = youtForme(c, parBloc, dimsBloc, sorties, typesSorties, instants, format)
    N = numel(instants);
    if strcmp(format, 'Dataset')
        y = Simulink.SimulationData.Dataset;
        for i = 1:numel(sorties)
            k = sorties(i);
            valeurs = parBloc{k};
            if isempty(valeurs)
                valeurs = zeros(N, 1);
            end
            if typesSorties(i) > 2
                valeurs = matlibre_sl_types('convertir', typesSorties(i), valeurs);
            end
            s = Simulink.SimulationData.Signal;
            s.Name = c.noms{k};
            s.BlockPath = c.chemins{k};
            s.PortType = 'inport';
            s.PortIndex = 1;
            s.Values = timeseries(valeurs, instants, 'Name', c.noms{k});
            y = addElement(y, s);
        end
        return
    end
    signaux = struct('values', {}, 'dimensions', {}, 'label', {}, 'blockName', {});
    for i = 1:numel(sorties)
        k = sorties(i);
        valeurs = parBloc{k};
        d = dimsBloc{k};
        if isempty(valeurs)
            valeurs = zeros(N, 1);
            d = [1 1];
        end
        signaux(i).values = valeurs;
        signaux(i).dimensions = dimensionsSimulink(d);
        signaux(i).label = '';
        signaux(i).blockName = c.chemins{k};
    end
    temps = [];
    if strcmp(format, 'StructureWithTime')
        temps = instants;
    end
    y = struct('time', temps, 'signals', signaux);
end

% Un relevé mis à la forme de Simulink : N x 1 pour un scalaire, N x w
% pour un vecteur, m x n x N pour une matrice.
function donnees = forme(brut, dims, N)
    if numel(dims) >= 2 && dims(1) > 1 && dims(2) > 1
        donnees = reshape(brut, dims(1), dims(2), N);
    else
        donnees = brut.';
    end
end

function d = dimensionsSimulink(dims)
    if prod(dims) == 1
        d = 1;
    elseif dims(1) > 1 && dims(2) > 1
        d = dims(1:2);
    else
        d = prod(dims);
    end
end

% Les blocs « vers l'espace de travail » y déposent leur signal, comme
% dans Simulink : la variable est écrite dans l'espace de base, d'où le
% reste du programme la lira. C'est fait en dernier, pour qu'une
% simulation interrompue par une erreur ne laisse pas une variable à
% moitié remplie.
function resultat = deposer(c, T, J, instants, resultat)
    N = numel(instants);
    for q = 1:numel(T.releves)
        R = T.releves(q);
        if strcmp(c.types{R.bloc}, 'tofile') && R.port == 1
            ecrireFichier(c.p{R.bloc}, c.chemins{R.bloc}, instants, J.releve(R.lignes, :));
            continue
        end
        if ~strcmp(c.types{R.bloc}, 'toworkspace') || R.port ~= 1
            continue
        end
        p = c.p{R.bloc};
        donnees = forme(J.releve(R.lignes, :), R.dims, N);
        % la variable a la classe du signal : int8, single, logical...
        source = c.entrees{R.bloc}(1);
        if source > 0 && c.typePort(source) > 2
            donnees = matlibre_sl_types('convertir', c.typePort(source), donnees);
        end
        switch p.SaveFormat
            case 'Array'
                valeur = donnees;
            case 'Timeseries'
                valeur = timeseries(donnees, instants, 'Name', char(p.VariableName));
            otherwise
                temps = instants;
                if strcmp(p.SaveFormat, 'Structure')
                    temps = [];
                end
                valeur = struct('time', temps, ...
                                'signals', struct('values', donnees, ...
                                                  'dimensions', dimensionsSimulink(R.dims), ...
                                                  'label', '', ...
                                                  'blockName', c.chemins{R.bloc}), ...
                                'blockName', c.chemins{R.bloc});
        end
        assignin('base', char(p.VariableName), valeur);
        % et dans le résultat, sous le même nom, comme Simulink le range
        % dans sa sortie de simulation
        if isvarname(char(p.VariableName)) && ~isfield(resultat, char(p.VariableName))
            resultat.(char(p.VariableName)) = valeur;
        end
    end
end

% Les entrées externes, découpées entre les entrées du modèle rangées par
% leur paramètre Port. Une matrice [t, u] donne à chacune autant de
% colonnes que sa largeur ; une structure à temps, un signal par entrée ;
% un texte s'évalue dans l'espace de travail de base, et plusieurs
% variables séparées par des virgules en donnent une par entrée.
function entrees = entreesExternes(modele, donnees, nomModele)
    ports = [];
    largeurs = [];
    for k = 1:numel(modele.blocs)
        b = modele.blocs{k};
        entree = matlibre_sl_catalogue('type', b.type);
        if ~strcmp(entree.type, 'inport')
            continue
        end
        rang = numel(ports) + 1;
        largeur = 1;
        for champ = fieldnames(b.parametres).'
            if strcmpi(champ{1}, 'Port')
                rang = double(b.parametres.(champ{1}));
            elseif strcmpi(champ{1}, 'PortDimensions') && isnumeric(b.parametres.(champ{1})) ...
                   && all(b.parametres.(champ{1}) > 0)
                largeur = prod(double(b.parametres.(champ{1})));
            end
        end
        % une entrée typée par un Simulink.Bus : autant de colonnes que le bus
        % a d'éléments, chacun à sa largeur
        for champ = fieldnames(b.parametres).'
            if strcmpi(champ{1}, 'OutDataTypeStr')
                nomType = matlibre_sl_bus('type', b.parametres.(champ{1}));
                if ~isempty(nomType)
                    chemin = [nomModele '/' char(b.nom)];
                    f = matlibre_sl_bus('forme', matlibre_sl_bus('objet', nomType, chemin), ...
                                        chemin);
                    largeur = sum([f.largeur]);
                end
            end
        end
        ports(end + 1) = rang; %#ok<AGROW>
        largeurs(end + 1) = largeur; %#ok<AGROW>
    end
    [ports, ordre] = sort(ports);
    largeurs = largeurs(ordre);
    n = numel(ports);
    if ischar(donnees) || isstring(donnees)
        noms = decouperNoms(char(donnees));
        valeurs = cell(1, numel(noms));
        for j = 1:numel(noms)
            try
                valeurs{j} = evalin('base', noms{j});
            catch err
                error('Simulink:SimInput:InvalidExpression', ...
                      ['L''entree externe ''%s'' du modele ''%s'' ne s''evalue pas : %s'], ...
                      noms{j}, nomModele, err.message);
            end
        end
        if numel(valeurs) == 1
            donnees = valeurs{1};
        else
            donnees = valeurs;
        end
    end
    entrees = cell(1, n);
    if iscell(donnees)
        % une variable par entrée
        if numel(donnees) ~= n
            error('Simulink:SimInput:NumPortsMismatch', ...
                  'Le modele ''%s'' a %d entree(s), et l''on en donne %d.', ...
                  nomModele, n, numel(donnees));
        end
        for j = 1:n
            d = donnees{j};
            if isa(d, 'timeseries')
                [temps, v] = matlibre_sl_serie(d);
            elseif isstruct(d) && isfield(d, 'time') && isfield(d, 'signals')
                temps = double(d.time(:));
                v = double(d.signals(1).values);
                if size(v, 1) ~= numel(temps)
                    v = reshape(v, numel(temps), []);
                end
            elseif isnumeric(d) && ismatrix(d) && size(d, 2) >= 2
                temps = double(d(:, 1));
                v = double(d(:, 2:end));
            else
                error('Simulink:SimInput:InvalidFormat', ...
                      ['L''entree externe %d du modele ''%s'' est une matrice [t, u], une ' ...
                       'structure a temps ou une timeseries.'], j, nomModele);
            end
            entrees{j} = struct('temps', temps, 'valeurs', v);
        end
        return
    end
    if isa(donnees, 'timeseries')
        % une timeseries : l'unique entrée du modèle
        if n ~= 1
            error('Simulink:SimInput:NumPortsMismatch', ...
                  'Le modele ''%s'' a %d entree(s), et l''on ne donne qu''une timeseries.', ...
                  nomModele, n);
        end
        [temps, v] = matlibre_sl_serie(donnees);
        entrees{1} = struct('temps', temps, 'valeurs', v);
        return
    end
    if isstruct(donnees) && isfield(donnees, 'time') && isfield(donnees, 'signals')
        if numel(donnees.signals) ~= n
            error('Simulink:SimInput:NumPortsMismatch', ...
                  'Le modele ''%s'' a %d entree(s), et la structure en porte %d.', ...
                  nomModele, n, numel(donnees.signals));
        end
        temps = double(donnees.time(:));
        for j = 1:n
            v = double(donnees.signals(j).values);
            if size(v, 1) ~= numel(temps)
                v = reshape(v, numel(temps), []);
            end
            entrees{j} = struct('temps', temps, 'valeurs', v);
        end
        return
    end
    if ~(isnumeric(donnees) && ismatrix(donnees) && size(donnees, 2) >= 2)
        error('Simulink:SimInput:InvalidFormat', ...
              ['L''entree externe du modele ''%s'' est une matrice [t, u] — le temps ' ...
               'puis une colonne par element des entrees —, une structure a temps, ou ' ...
               'des variables separees par des virgules.'], nomModele);
    end
    temps = double(donnees(:, 1));
    if any(diff(temps) < 0)
        error('Simulink:SimInput:TimeNotMonotonic', ...
              'Les instants de l''entree externe du modele ''%s'' doivent croitre.', nomModele);
    end
    colonnes = size(donnees, 2) - 1;
    if colonnes ~= sum(largeurs)
        error('Simulink:SimInput:NumPortsMismatch', ...
              ['L''entree externe du modele ''%s'' porte %d colonne(s) de signal, pour %d ' ...
               'entree(s) de largeur totale %d.'], nomModele, colonnes, n, sum(largeurs));
    end
    debut = 2;
    for j = 1:n
        entrees{j} = struct('temps', temps, ...
                            'valeurs', double(donnees(:, debut:debut + largeurs(j) - 1)));
        debut = debut + largeurs(j);
    end
end

% « u1, u2 » : les noms, séparés par les virgules qui ne sont dans aucun
% crochet ni aucune parenthèse.
function noms = decouperNoms(texte)
    noms = {};
    profondeur = 0;
    debut = 1;
    for i = 1:numel(texte)
        switch texte(i)
            case {'[', '('}
                profondeur = profondeur + 1;
            case {']', ')'}
                profondeur = profondeur - 1;
            case ','
                if profondeur == 0
                    noms{end + 1} = strtrim(texte(debut:i - 1)); %#ok<AGROW>
                    debut = i + 1;
                end
        end
    end
    noms{end + 1} = strtrim(texte(debut:end));
end

% Le bloc To File : une matrice dont la première ligne est le temps, et les
% suivantes le signal, un instant par colonne — une colonne sur Decimation.
function ecrireFichier(p, chemin, instants, valeurs)
    decimation = max(1, round(double(p.Decimation)));
    garder = 1:decimation:numel(instants);
    contenu = struct();
    nom = char(p.MatrixName);
    if ~isvarname(nom)
        error('Simulink:blocks:ToFileInvalidName', ...
              'Le nom de variable ''%s'' du bloc To File ''%s'' n''est pas un nom valide.', ...
              nom, chemin);
    end
    contenu.(nom) = [instants(garder).'; valeurs(:, garder)];
    try
        save(char(p.Filename), '-struct', 'contenu');
    catch err
        error('Simulink:blocks:ToFileWriteError', ...
              'Le bloc To File ''%s'' ne peut pas ecrire ''%s'' : %s', chemin, ...
              char(p.Filename), err.message);
    end
end

% Un modèle désigné par son nom : une variable de l'espace de travail de
% l'appelant, un fichier .m qui le construit, ou un fichier .slx ou .mdl
% de Simulink, que MATLIBRE_SL_SLX lit.
function modele = chargerModele(nom)
    [~, ~, extension] = fileparts(nom);
    if any(strcmpi(extension, {'.slx', '.mdl'}))
        modele = matlibre_sl_slx('lire', nom);
        return
    end
    if exist(nom, 'file') == 2 || exist(nom, 'file') == 6
        modele = feval(nom);
        return
    end
    for autre = {'.slx', '.mdl'}
        if exist([nom autre{1}], 'file') == 2
            modele = matlibre_sl_slx('lire', [nom autre{1}]);
            return
        end
    end
    error('Simulink:Commands:OpenSystemUnknownSystem', ...
          'Invalid Simulink object name: ''%s''.', nom);
end

function nom = nomValide(brut)
    nom = regexprep(char(brut), '[^A-Za-z0-9_]', '_');
    if isempty(nom) || ~isletter(nom(1))
        nom = ['b_' nom];
    end
end
