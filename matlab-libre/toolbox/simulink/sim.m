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
%   Le résultat porte plusieurs formes. RESULTAT.temps et
%   RESULTAT.signaux.<nom> pour l'accès direct — un signal vecteur y est
%   une matrice à une ligne par instant, un signal matrice un tableau
%   m x n x N, et la deuxième sortie d'un bloc s'appelle <nom>_port2.
%   RESULTAT.time et RESULTAT.signals(k).values pour la « structure with
%   time » de Simulink ; RESULTAT.tout, RESULTAT.xout et RESULTAT.yout
%   pour les instants, les états continus et les sorties OUTPORT.
%   [T,X,Y] = SIM(...) rend ces trois derniers, comme la forme ancienne
%   de Simulink.
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
    [config, imposes] = lireArguments(matlibre_sl_config('lire', modele), varargin);
    nomModele = char(modele.nom);
    tDebut = nombre(config.StartTime, nomModele, 'StartTime');
    tFinal = nombre(config.StopTime, nomModele, 'StopTime');
    if ~isscalar(tFinal) || ~(tFinal >= tDebut)
        error('simulink:sim:duree', ...
              'La duree doit etre un nombre positif : l''instant final precede le debut.');
    end
    variable = strcmpi(matlibre_sl_config('type', config.Solver), 'Variable-step');
    solveur = lower(char(config.Solver));
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
        error('simulink:sim:pas', 'Le pas doit etre un nombre strictement positif.');
    end

    options = struct('pas', pas, 'tDebut', tDebut, 'tFinal', tFinal, 'config', config, ...
                     'variable', variable);
    c = matlibre_sl_compiler(modele, options);
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
    T = matlibre_sl_executer('preparer', c);
    T.reglagesSolveur = struct('ExtrapolationOrder', config.ExtrapolationOrder, ...
                               'NumberNewtonIterations', config.NumberNewtonIterations, ...
                               'MaxOrder', config.MaxOrder);

    if variable
        reglages = reglagesVariables(config, nomModele);
        J = matlibre_sl_executer('simulerVariable', T, tDebut, tFinal, solveur, reglages, ...
                                 imposes);
        instants = J.temps;
    elseif isinf(tFinal)
        [instants, J] = sansFin(T, tDebut, pas, solveur);
    else
        instants = tDebut:pas:tFinal;
        J = matlibre_sl_executer('simuler', T, instants, solveur);
        instants = instants(1:J.dernier);
    end

    resultat = assembler(c, T, J, instants(:));
    deposer(c, T, J, instants(:));
    if nargout <= 1
        varargout{1} = resultat;
    else
        varargout = {resultat.tout, resultat.xout, resultat.yout};
    end
end

% Les arguments après le modèle : la forme ancienne (instant final, pas
% ou options), ou les réglages par nom. Ils l'emportent sur ceux du
% modèle, qu'ils ne changent pas. IMPOSES porte les instants donnés un à
% un, au-delà de deux : à pas variable, ce sont les seuls relevés.
function [config, imposes] = lireArguments(config, args)
    imposes = [];
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
                error('simulink:sim:intervalle', ...
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
                error('simulink:sim:pas', 'Le pas doit etre un nombre strictement positif.');
            end
            config.FixedStep = double(troisieme);
        end
    end
    if numel(args) >= 3
        error('Simulink:Commands:SimArguments', ...
              ['SIM(MODELE,INTERVALLE,OPTIONS) : les entrees externes (quatrieme ' ...
               'argument) ne sont pas encore lues ; alimentez le modele par des ' ...
               'blocs From Workspace.']);
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
            reprise = struct('V', T.V0, 'Z', T.Z0, 'x', T.x0, 'i0', 0, 'avancer', true);
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
    for k = sorties(ordre)
        yout = [yout, reshape(parBloc{k}, N, [])]; %#ok<AGROW>
    end
    resultat.yout = yout;
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
function deposer(c, T, J, instants)
    N = numel(instants);
    for q = 1:numel(T.releves)
        R = T.releves(q);
        if strcmp(c.types{R.bloc}, 'tofile') && R.port == 1
            ecrireFichier(c.p{R.bloc}, instants, J.releve(R.lignes, :));
            continue
        end
        if ~strcmp(c.types{R.bloc}, 'toworkspace') || R.port ~= 1
            continue
        end
        p = c.p{R.bloc};
        donnees = forme(J.releve(R.lignes, :), R.dims, N);
        switch p.SaveFormat
            case 'Array'
                valeur = donnees;
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
    end
end

% Le bloc To File : une matrice dont la première ligne est le temps, et les
% suivantes le signal, un instant par colonne — une colonne sur Decimation.
function ecrireFichier(p, instants, valeurs)
    decimation = max(1, round(double(p.Decimation)));
    garder = 1:decimation:numel(instants);
    contenu = struct();
    nom = char(p.MatrixName);
    if ~isvarname(nom)
        error('Simulink:blocks:ToFileInvalidName', ...
              'Le nom de variable ''%s'' du bloc To File n''est pas un nom valide.', nom);
    end
    contenu.(nom) = [instants(garder).'; valeurs(:, garder)];
    save(char(p.Filename), '-struct', 'contenu');
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
