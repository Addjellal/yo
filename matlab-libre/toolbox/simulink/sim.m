function resultat = sim(modele, tFinal, pas)
%SIM Simule un modèle à pas fixe.
%   RESULTAT = SIM(MODELE,TFINAL,PAS) rend une structure contenant le
%   vecteur des instants et, pour chaque bloc, le signal relevé à sa
%   sortie.
%   SIM(MODELE,INSTANTS) accepte aussi un vecteur d'instants réguliers :
%   il donne alors à la fois l'instant final et le pas.
%
%   L'intégration se fait par défaut par la méthode d'Euler explicite.
%   SIM(MODELE,TFINAL,SIMSET('Solver','ode4')) en choisit une autre :
%   ode1 (Euler), ode2 (Heun), ode3 (Bogacki-Shampine) et ode4
%   (Runge-Kutta d'ordre quatre) sont à pas fixe, et l'erreur d'un
%   solveur d'ordre p décroît comme le pas à la puissance p. Un solveur
%   d'ordre supérieur évalue la dérivée en des points intermédiaires du
%   pas : cela n'a de sens que pour un état continu — intégrateur,
%   représentation d'état, fonction de transfert, PID —, et un modèle
%   qui porte un retard ou un bloc échantillonné est refusé en nommant
%   le bloc. Le modèle peut porter son solveur lui-même, par
%   ADD_PARAM(M,'Solver','ode4').
%
%   Les blocs sont évalués dans l'ordre d'un tri topologique, ce qui garantit
%   qu'une entrée est calculée avant la sortie qui l'utilise. Seuls les
%   blocs sans transmission directe — intégrateur, retard, mémoire,
%   retard pur, tenue d'ordre zéro, et les représentations d'état dont D
%   est nul — coupent la remontée, et cassent donc les boucles
%   algébriques. Un bloc à mémoire mais à transmission directe, comme le
%   dérivateur ou le relais, ne la coupe pas : sa sortie dépend de son
%   entrée à l'instant même.
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
%   « sousSysteme/bloc », et le sous-système lui-même porte la valeur de
%   sa sortie.
%
%   SIM('NOM') accepte aussi le nom d'un modèle : une variable de
%   l'espace de travail qui porte ce nom, ou un fichier NOM.m qui
%   construit le modèle et le rend. Les modèles se décrivent ici en
%   appelant NEW_SYSTEM, ADD_BLOCK et ADD_LINE ; les fichiers .slx de
%   MathWorks, dont le format n'est pas public, ne se lisent pas.
%
%   Le résultat porte les deux formes que Simulink journalise :
%   RESULTAT.temps et RESULTAT.signaux.<nom> pour l'accès direct,
%   RESULTAT.time et RESULTAT.signals(k).values pour la « structure with
%   time » qu'attendent les scripts écrits pour Simulink.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      m = add_line(m, 'un', 'integ');
%      r = sim(m, 5, 0.001);
%      abs(r.signaux.integ(end) - 10) < 0.01     % l'integrale de 2 sur 5 s
%
%   Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SIMPLOT, LINMOD.
    tFinalDonne = nargin >= 2 && ~isempty(tFinal);
    pasDonne = nargin >= 3 && ~isempty(pas);
    % Le troisième argument peut être un jeu d'options de SIMSET plutôt
    % qu'un pas : c'est la forme héritée que Simulink documente encore.
    solveur = '';
    if pasDonne && isstruct(pas)
        demande = simget(pas, 'Solver');
        if ~isempty(demande), solveur = char(demande); end
        choisi = simget(pas, 'FixedStep');
        pasDonne = ~isempty(choisi);
        pas = choisi;
    end
    if ~tFinalDonne, tFinal = 10; end
    if ~pasDonne, pas = 0.01; end
    % Un intervalle donne en vecteur — « sim(m, 0:0.01:1) » — dit a la
    % fois l'instant final et le pas. Le prendre pour un scalaire ne
    % simulait qu'un seul point, et le resultat, juste pour un bloc sans
    % memoire, etait faux des qu'un etat entrait en jeu.
    if ~isscalar(tFinal)
        instantsDonnes = double(tFinal(:))';
        if numel(instantsDonnes) < 2
            error('simulink:sim:intervalle', ...
                  'Un intervalle doit porter au moins deux instants.');
        end
        ecarts = diff(instantsDonnes);
        if any(ecarts <= 0)
            error('simulink:sim:intervalle', ...
                  'Les instants doivent etre strictement croissants.');
        end
        if nargin < 3
            % Un intervalle de deux bornes ne dit rien du pas : on garde
            % celui par defaut. Au-dela, c'est l'ecart qui le donne.
            if numel(instantsDonnes) > 2
                pas = ecarts(1);
            end
        end
        tFinal = instantsDonnes(end);
    end
    if ~isscalar(pas) || ~(pas > 0)
        error('simulink:sim:pas', 'Le pas doit etre un nombre strictement positif.');
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
    % Les réglages portés par le modèle — ceux qu'ADD_PARAM pose — ne
    % valent que si l'appel n'a rien dit : un argument explicite l'emporte
    % toujours sur un réglage enregistré.
    if isfield(modele, 'parametres')
        if ~tFinalDonne && isfield(modele.parametres, 'StopTime')
            tFinal = double(modele.parametres.StopTime);
        end
        if ~pasDonne && isfield(modele.parametres, 'FixedStep')
            pas = double(modele.parametres.FixedStep);
        end
        if isempty(solveur) && isfield(modele.parametres, 'Solver')
            solveur = char(modele.parametres.Solver);
        end
    end
    if isempty(solveur), solveur = 'ode1'; end
    solveur = lower(solveur);
    if strcmp(solveur, 'fixedstepdiscrete'), solveur = 'ode1'; end
    if ~any(strcmp(solveur, {'ode1', 'ode2', 'ode3', 'ode4'}))
        error('Simulink:Commands:SolveurInconnu', ...
              ['Le solveur ''%s'' n''existe pas ici : ode1 (Euler), ode2 ' ...
               '(Heun), ode3 (Bogacki-Shampine) et ode4 (Runge-Kutta) sont ' ...
               'a pas fixe.'], solveur);
    end
    if ~isscalar(pas) || ~(pas > 0)
        error('simulink:sim:pas', 'Le pas doit etre un nombre strictement positif.');
    end
    if ~isscalar(tFinal) || ~(tFinal >= 0)
        error('simulink:sim:duree', 'La duree doit etre un nombre positif.');
    end
    % Un sous-systeme n'est pas un bloc : c'est le schema qu'il abrege.
    % On le deplie ici, une fois pour toutes, et rien de ce qui suit n'a
    % a savoir qu'il existait.
    modele = matlibre_sl_aplatir(modele);
    n = numel(modele.blocs);
    instants = 0:pas:tFinal;
    nInstants = numel(instants);


    % --- préparation : un enregistrement compact par bloc ---
    types = zeros(1, n);          % code numérique du type
    p1 = zeros(1, n);
    p2 = zeros(1, n);
    p3 = zeros(1, n);
    p4 = zeros(1, n);
    signes = cell(1, n);
    matrices = cell(1, n);
    etats = cell(1, n);
    % Deux propriétés distinctes, qu'un simple seuil sur le code
    % confondait : un bloc peut avoir de la mémoire et transmettre
    % pourtant son entrée à l'instant même. Seule l'absence de
    % transmission directe autorise le tri à ne pas remonter aux
    % entrées ; la mémoire, elle, commande la passe de mise à jour.
    directe = true(1, n);         % la sortie dépend de l'entrée à t
    memoire = false(1, n);        % le bloc porte un état à faire avancer
    for k = 1:n
        bloc = modele.blocs{k};
        type = bloc.type;
        if strcmp(type, 'transferfcn')
            [A, B, C, D] = tf2ss(lireNombre(bloc, 'Numerator', 1), ...
                                 lireNombre(bloc, 'Denominator', 1));
            type = 'statespace';
            bloc.parametres.A = A;
            bloc.parametres.B = B;
            bloc.parametres.C = C;
            bloc.parametres.D = D;
        end
        if strcmp(type, 'unitdelay')
            type = 'delay';
        end
        if strcmp(type, 'zeroorderhold')
            type = 'zoh';
        end
        switch type
            case 'constant'
                types(k) = 1;
                p1(k) = lireNombre(bloc, 'Value', 1);
                directe(k) = false;
            case 'step'
                types(k) = 2;
                p1(k) = lireNombre(bloc, 'Time', 1);
                p2(k) = lireNombre(bloc, 'Before', 0);
                p3(k) = lireNombre(bloc, 'After', 1);
                directe(k) = false;
            case 'ramp'
                types(k) = 3;
                p1(k) = lireNombre(bloc, 'Slope', 1);
                directe(k) = false;
            case 'sine'
                types(k) = 4;
                p1(k) = lireNombre(bloc, 'Amplitude', 1);
                p2(k) = lireNombre(bloc, 'Frequency', 1);
                p3(k) = lireNombre(bloc, 'Phase', 0);
                directe(k) = false;
            case 'gain'
                types(k) = 5;
                p1(k) = lireNombre(bloc, 'Gain', 1);
            case 'sum'
                types(k) = 6;
                signes{k} = lireParametre(bloc, 'Signs', '++');
            case 'product'
                types(k) = 7;
            case 'abs'
                types(k) = 8;
            case 'saturation'
                types(k) = 9;
                p1(k) = lireNombre(bloc, 'UpperLimit', 1);
                p2(k) = lireNombre(bloc, 'LowerLimit', -1);
            case 'relay'
                types(k) = 10;
                p1(k) = lireNombre(bloc, 'OnSwitch', 0.5);
                p2(k) = lireNombre(bloc, 'OffSwitch', -0.5);
                p3(k) = lireNombre(bloc, 'OnOutput', 1);
                matrices{k} = lireNombre(bloc, 'OffOutput', 0);
                etats{k} = 0;
                memoire(k) = true;
            case 'integrator'
                types(k) = 11;
                etats{k} = lireNombre(bloc, 'InitialCondition', 0);
                directe(k) = false;
                memoire(k) = true;
            case 'delay'
                types(k) = 12;
                etats{k} = lireNombre(bloc, 'InitialCondition', 0);
                directe(k) = false;
                memoire(k) = true;
            case 'derivative'
                types(k) = 13;
                etats{k} = 0;
                memoire(k) = true;
            case 'statespace'
                types(k) = 14;
                A = lireNombre(bloc, 'A', 0);
                B = lireNombre(bloc, 'B', 0);
                C = lireNombre(bloc, 'C', 1);
                D = lireNombre(bloc, 'D', 0);
                matrices{k} = {A, B, C, D};
                x0 = lireNombre(bloc, 'X0', []);
                if isempty(x0)
                    x0 = zeros(size(A, 1), 1);
                end
                etats{k} = x0(:);
                directe(k) = any(D(:) ~= 0);
                memoire(k) = true;
            case 'math'
                types(k) = 15;
                signes{k} = lireParametre(bloc, 'Operator', 'square');
            case 'deadzone'
                types(k) = 16;
                p1(k) = lireNombre(bloc, 'UpperValue', 0.5);
                p2(k) = lireNombre(bloc, 'LowerValue', -0.5);
            case 'quantizer'
                types(k) = 17;
                p1(k) = lireNombre(bloc, 'QuantizationInterval', 0.5);
            case 'switch'
                types(k) = 18;
                p1(k) = lireNombre(bloc, 'Threshold', 0);
                signes{k} = lireParametre(bloc, 'Criteria', 'u2>=Threshold');
            case 'sign'
                types(k) = 19;
            case 'minmax'
                types(k) = 20;
                signes{k} = lireParametre(bloc, 'Function', 'min');
            case 'trigonometry'
                types(k) = 21;
                signes{k} = lireParametre(bloc, 'Operator', 'sin');
            case 'logic'
                types(k) = 22;
                signes{k} = lireParametre(bloc, 'Operator', 'AND');
            case 'relational'
                types(k) = 23;
                signes{k} = lireParametre(bloc, 'Operator', '<');
            case 'lookup'
                types(k) = 24;
                abscisses = lireNombre(bloc, 'BreakpointsData', [0 1]);
                ordonnees = lireNombre(bloc, 'TableData', [0 1]);
                if numel(abscisses) ~= numel(ordonnees)
                    error('simulink:sim:tableIncoherente', ...
                          ['Le bloc ''%s'' porte %d abscisses et %d valeurs : ' ...
                           'il en faut autant.'], bloc.nom, numel(abscisses), ...
                          numel(ordonnees));
                end
                matrices{k} = {abscisses(:)', ordonnees(:)'};
            case 'bias'
                types(k) = 25;
                p1(k) = lireNombre(bloc, 'Bias', 0);
            case 'memory'
                types(k) = 26;
                etats{k} = lireNombre(bloc, 'InitialCondition', 0);
                directe(k) = false;
                memoire(k) = true;
            case 'transportdelay'
                types(k) = 27;
                retard = lireNombre(bloc, 'DelayTime', 1);
                debut = lireNombre(bloc, 'InitialOutput', 0);
                if retard < 0
                    error('simulink:sim:retardNegatif', ...
                          'Le bloc ''%s'' demande un retard negatif.', bloc.nom);
                end
                longueur = max(1, ceil(retard / pas));
                p1(k) = retard;
                p2(k) = longueur;
                % Le tampon garde les entrées passées, la plus ancienne en
                % tête ; la fraction de pas restante est interpolée.
                etats{k} = repmat(debut, 1, longueur + 1);
                directe(k) = (retard == 0);
                memoire(k) = true;
            case 'ratelimiter'
                types(k) = 28;
                p1(k) = lireNombre(bloc, 'RisingSlewLimit', 1);
                p2(k) = lireNombre(bloc, 'FallingSlewLimit', -1);
                etats{k} = lireNombre(bloc, 'InitialOutput', 0);
                memoire(k) = true;
            case 'zoh'
                types(k) = 29;
                p1(k) = lireNombre(bloc, 'SampleTime', 10 * pas);
                % L'état porte la valeur tenue et la date du dernier
                % échantillonnage ; la seconde vaut -inf tant qu'il n'y en
                % a pas eu, pour que le tout premier instant échantillonne.
                etats{k} = [0, -inf];
                % Le bloc transmet bien son entree a l'instant ou il
                % echantillonne : il ne casse donc pas une boucle
                % algebrique, et son etat avance dans la passe de sortie.
                memoire(k) = false;
            case 'discreteintegrator'
                types(k) = 30;
                p1(k) = lireNombre(bloc, 'Gain', 1);
                p2(k) = lireNombre(bloc, 'SampleTime', pas);
                signes{k} = lireParametre(bloc, 'IntegratorMethod', 'ForwardEuler');
                etats{k} = [lireNombre(bloc, 'InitialCondition', 0), -inf, 0];
                % Euler avant rend l'état lui-même : pas de transmission
                % directe. Euler arrière et le trapèze ajoutent un terme
                % en u(k), donc en transmettent.
                directe(k) = ~strcmpi(signes{k}, 'ForwardEuler');
                memoire(k) = true;
            case 'discretetransferfcn'
                types(k) = 31;
                num = lireNombre(bloc, 'Numerator', 1);
                den = lireNombre(bloc, 'Denominator', 1);
                [num, den] = normaliserFiltre(num, den, bloc.nom);
                matrices{k} = {num, den};
                p1(k) = lireNombre(bloc, 'SampleTime', pas);
                etats{k} = [zeros(1, numel(den) - 1), -inf, 0];
                directe(k) = (num(1) ~= 0);
                memoire(k) = true;
            case 'discretestatespace'
                types(k) = 32;
                A = lireNombre(bloc, 'A', 0);
                B = lireNombre(bloc, 'B', 0);
                C = lireNombre(bloc, 'C', 1);
                D = lireNombre(bloc, 'D', 0);
                matrices{k} = {A, B, C, D};
                x0 = lireNombre(bloc, 'X0', []);
                if isempty(x0)
                    x0 = zeros(size(A, 1), 1);
                end
                p1(k) = lireNombre(bloc, 'SampleTime', pas);
                etats{k} = {x0(:), -inf, 0};
                directe(k) = any(D(:) ~= 0);
                memoire(k) = true;
            case 'pidcontroller'
                types(k) = 33;
                p1(k) = lireNombre(bloc, 'P', 1);
                p2(k) = lireNombre(bloc, 'I', 0);
                p3(k) = lireNombre(bloc, 'D', 0);
                p4(k) = lireNombre(bloc, 'N', 100);
                if p4(k) <= 0
                    error('simulink:sim:filtreDerive', ...
                          ['Le bloc ''%s'' demande un coefficient de filtre N ' ...
                           'strictement positif : une derivee non filtree ne ' ...
                           's''integre pas.'], bloc.nom);
                end
                etats{k} = [lireNombre(bloc, 'InitialConditionForIntegrator', 0), ...
                            lireNombre(bloc, 'InitialConditionForFilter', 0)];
                memoire(k) = true;
            case 'inport'
                types(k) = 34;
                p1(k) = lireNombre(bloc, 'Port', 1);
                p2(k) = lireNombre(bloc, 'Value', 0);
                directe(k) = false;
            case 'outport'
                types(k) = 35;
                p1(k) = lireNombre(bloc, 'Port', 1);
            case 'fromworkspace'
                types(k) = 36;
                nomVariable = lireParametre(bloc, 'VariableName', '');
                % Le signal est rééchantillonné une fois pour toutes sur
                % les instants de la simulation : le faire à chaque pas
                % coûterait une interpolation par bloc et par instant.
                matrices{k} = lireSignalEspace(nomVariable, bloc.nom, instants);
                directe(k) = false;
            case 'toworkspace'
                types(k) = 37;
                signes{k} = char(lireParametre(bloc, 'VariableName', 'simout'));
                if ~isvarname(signes{k})
                    error('simulink:sim:nomVariable', ...
                          ['Le bloc ''%s'' veut ecrire dans ''%s'', qui n''est ' ...
                           'pas un nom de variable.'], bloc.nom, signes{k});
                end
            case {'scope', 'mux', 'demux', 'terminator', 'display', ...
                  'signalconversion', 'goto', 'from'}
                types(k) = 0;   % passe-plat : le bloc laisse passer son entrée
            otherwise
                % Un type inconnu passait silencieusement son entrée : le
                % modèle se simulait, et le résultat était faux sans le
                % dire. Mieux vaut le refuser en nommant le bloc.
                error('Simulink:Commands:InvalidBlockType', ...
                      ['Le bloc ''%s'' est d''un type inconnu : ''%s''. ' ...
                       'Voir ADD_BLOCK pour la liste des types reconnus.'], ...
                      bloc.nom, bloc.type);
        end
        if isempty(etats{k})
            etats{k} = 0;
        end
    end

    % --- liens : pour chaque bloc, la liste (source, position) ---
    sources = cell(1, n);
    for k = 1:n
        sources{k} = [];
    end
    for l = 1:size(modele.liens, 1)
        destination = modele.liens(l, 2);
        sources{destination}(end+1, :) = [modele.liens(l, 1), modele.liens(l, 3)];
    end

    ordre = triTopologique(modele, directe);
    sorties = zeros(1, n);
    releves = zeros(nInstants, n);

    if strcmp(solveur, 'ode1')
        % Euler explicite : la sortie se lit, puis l'etat avance d'un pas.
        % C'est la marche d'origine, et elle sert aussi aux blocs a memoire
        % qui ne s'integrent pas -- retards, blocs echantillonnes.
        for t = 1:nInstants
            temps = instants(t);
            for i = 1:numel(ordre)
                k = ordre(i);
                entrees = rassembler(sources{k}, sorties);
                [sorties(k), etats{k}] = evaluerBloc(types(k), p1(k), p2(k), p3(k), p4(k), ...
                                                     signes{k}, matrices{k}, entrees, ...
                                                     etats{k}, temps, pas, false);
            end
            releves(t, :) = sorties;
            for k = 1:n
                if memoire(k)
                    entrees = rassembler(sources{k}, sorties);
                    [~, etats{k}] = evaluerBloc(types(k), p1(k), p2(k), p3(k), p4(k), ...
                                                signes{k}, matrices{k}, entrees, etats{k}, ...
                                                temps, pas, true);
                end
            end
        end
    else
        % --- Runge-Kutta a pas fixe ---------------------------------
        %
        % Un solveur d'ordre superieur evalue la derivee plusieurs fois
        % par pas, en des points intermediaires. Cela n'a de sens que
        % pour un etat continu : un retard ou un bloc echantillonne n'a
        % pas de derivee, et l'evaluer a mi-pas ne voudrait rien dire.
        % On refuse donc en nommant le bloc, plutot que d'integrer de
        % travers ce qui ne s'integre pas.
        continus = (types == 11) | (types == 14) | (types == 33);
        for k = 1:n
            if memoire(k) && ~continus(k)
                error('Simulink:Commands:SolveurEtatDiscret', ...
                      ['Le bloc ''%s'', de type ''%s'', ne porte pas un etat ' ...
                       'continu : il ne s''integre qu''au pas fixe. Simulez ce ' ...
                       'modele avec le solveur ''ode1''.'], ...
                      modele.blocs{k}.nom, modele.blocs{k}.type);
            end
        end
        for t = 1:nInstants
            temps = instants(t);
            [sorties, d1] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                        signes, matrices, etats, temps, pas, continus);
            releves(t, :) = sorties;
            if t == nInstants
                break   % rien a avancer apres le dernier instant releve
            end
            switch solveur
                case 'ode2'
                    % Heun : une pente au depart, une a l'arrivee, la
                    % moyenne des deux.
                    [~, d2] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d1, continus, pas), ...
                                          temps + pas, pas, continus);
                    etats = combiner(etats, {d1, d2}, [1/2, 1/2], continus, pas);
                case 'ode3'
                    [~, d2] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d1, continus, pas / 2), ...
                                          temps + pas / 2, pas, continus);
                    [~, d3] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d2, continus, 3 * pas / 4), ...
                                          temps + 3 * pas / 4, pas, continus);
                    etats = combiner(etats, {d1, d2, d3}, [2/9, 3/9, 4/9], ...
                                     continus, pas);
                otherwise
                    % ode4 : le Runge-Kutta classique d'ordre quatre.
                    [~, d2] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d1, continus, pas / 2), ...
                                          temps + pas / 2, pas, continus);
                    [~, d3] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d2, continus, pas / 2), ...
                                          temps + pas / 2, pas, continus);
                    [~, d4] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                          signes, matrices, ...
                                          avancer(etats, d3, continus, pas), ...
                                          temps + pas, pas, continus);
                    etats = combiner(etats, {d1, d2, d3, d4}, ...
                                     [1/6, 1/3, 1/3, 1/6], continus, pas);
            end
        end
    end

    resultat = struct();
    resultat.temps = instants(:);
    resultat.signaux = struct();
    for k = 1:n
        resultat.signaux.(nomValide(modele.blocs{k}.nom)) = releves(:, k);
    end
    % La forme « structure with time » de Simulink : c'est celle que lisent
    % les scripts écrits pour lui, avec res.time et res.signals(k).values.
    resultat.time = instants(:);
    signals = struct('values', {}, 'dimensions', {}, 'label', {}, 'blockName', {});
    for k = 1:n
        signals(k).values = releves(:, k);
        signals(k).dimensions = 1;
        signals(k).label = modele.blocs{k}.nom;
        signals(k).blockName = modele.blocs{k}.nom;
    end
    resultat.signals = signals;
    resultat.blockName = modele.nom;

    % Les blocs « vers l'espace de travail » y déposent leur signal, comme
    % dans Simulink : la variable est écrite dans l'espace de base, d'où
    % le reste du programme la lira. C'est fait en dernier, pour qu'une
    % simulation interrompue par une erreur ne laisse pas une variable à
    % moitié remplie.
    for k = 1:n
        if types(k) == 37
            assignin('base', signes{k}, releves(:, k));
        end
    end
end

% Un modèle désigné par son nom : une variable de l'espace de travail de
% l'appelant, ou un fichier .m qui le construit. Les .slx de MathWorks ne
% se lisent pas — leur format n'est pas public.
function modele = chargerModele(nom)
    if exist(nom, 'file') == 2 || exist(nom, 'file') == 6
        modele = feval(nom);
        return
    end
    if exist([nom '.slx'], 'file') || exist([nom '.mdl'], 'file')
        error('Simulink:Commands:SlxNonLu', ...
              ['MatLibre ne lit pas les fichiers .slx ni .mdl : leur format ' ...
               'n''est pas public. Decrivez le modele ''%s'' en appelant ' ...
               'NEW_SYSTEM, ADD_BLOCK et ADD_LINE, dans un fichier %s.m qui ' ...
               'le rend.'], nom, nom);
    end
    error('Simulink:Commands:OpenSystemUnknownSystem', ...
          'Invalid Simulink object name: ''%s''.', nom);
end

% Une passe de sortie complete, a etats donnes : elle rend la sortie de
% chaque bloc et, pour chaque bloc a etat continu, la derivee de cet etat.
% Rien n'y avance : c'est ce qui permet de l'appeler plusieurs fois par
% pas, en des points intermediaires, comme le veut Runge-Kutta.
function [sorties, derivees] = passeSortie(ordre, sources, types, p1, p2, p3, p4, ...
                                           signes, matrices, etats, temps, pas, ...
                                           continus)
    n = numel(types);
    sorties = zeros(1, n);
    derivees = cell(1, n);
    for i = 1:numel(ordre)
        k = ordre(i);
        entrees = rassembler(sources{k}, sorties);
        [sorties(k), ~] = evaluerBloc(types(k), p1(k), p2(k), p3(k), p4(k), ...
                                      signes{k}, matrices{k}, entrees, etats{k}, ...
                                      temps, pas, false);
    end
    % Les derivees seulement une fois toutes les sorties connues. Un bloc
    % a etat n'a pas de transmission directe : le tri le calcule donc
    % avant ce qui l'alimente, et lire son entree pendant la passe
    % l'aurait trouvee a zero -- l'etat n'aurait jamais bouge.
    for k = 1:numel(types)
        if ~continus(k)
            continue
        end
        % La derivee ne se mesure pas, elle se lit : l'entree d'un
        % integrateur est sa derivee, et une representation d'etat donne
        % A x + B u. Le PID en a deux, celle de son integrale et celle
        % de sa derivee filtree.
        u = rassembler(sources{k}, sorties);
        u = u(1);
        switch types(k)
            case 11
                derivees{k} = u;
            case 14
                derivees{k} = matrices{k}{1} * etats{k} + matrices{k}{2} * u;
            otherwise
                derivees{k} = [u, u - p4(k) * etats{k}(2)];
        end
    end
end

% Les etats continus avances d'un pas H selon une seule pente : c'est le
% point ou Runge-Kutta va relire la derivee.
function etats = avancer(etats, derivees, continus, h)
    for k = 1:numel(etats)
        if continus(k)
            etats{k} = etats{k} + h * derivees{k};
        end
    end
end

% Les etats avances d'un pas complet, selon la moyenne ponderee des
% pentes relevees : c'est la formule du solveur.
function etats = combiner(etats, pentes, poids, continus, pas)
    for k = 1:numel(etats)
        if ~continus(k)
            continue
        end
        cumul = 0 * etats{k};
        for j = 1:numel(pentes)
            cumul = cumul + poids(j) * pentes{j}{k};
        end
        etats{k} = etats{k} + pas * cumul;
    end
end

function entrees = rassembler(liste, sorties)
    if isempty(liste)
        entrees = 0;
        return;
    end
    entrees = zeros(1, max(liste(:, 2)));
    for l = 1:size(liste, 1)
        entrees(liste(l, 2)) = sorties(liste(l, 1));
    end
end

function nom = nomValide(brut)
    nom = regexprep(char(brut), '[^A-Za-z0-9_]', '_');
    if isempty(nom) || ~isletter(nom(1))
        nom = ['b_' nom];
    end
end

function v = lireParametre(bloc, nom, defaut)
    if isfield(bloc.parametres, nom)
        v = bloc.parametres.(nom);
    else
        v = defaut;
    end
end

% Un paramètre numérique peut être donné par une expression, comme dans
% Simulink : « 'Gain', 'K' » vaut ce que vaut K dans l'espace de travail
% de base au moment où l'on simule. C'est ainsi que le modèle et l'espace
% de travail partagent leurs variables.
function v = lireNombre(bloc, nom, defaut)
    v = lireParametre(bloc, nom, defaut);
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), bloc.nom, nom);
    end
end


% Le tri ne remonte aux entrées que d'un bloc à transmission directe.
% Un bloc qui n'en a pas — intégrateur, retard, mémoire — rend une valeur
% qui ne dépend que de son état : il peut donc être placé le premier, et
% c'est ce qui casse les boucles.
function ordre = triTopologique(modele, directe)
    n = numel(modele.blocs);
    visite = zeros(1, n);
    ordre = [];
    for k = 1:n
        [ordre, visite] = visiter(modele, k, directe, visite, ordre);
    end
end

function [ordre, visite] = visiter(modele, k, directe, visite, ordre)
    if visite(k) ~= 0
        return;   % déjà placé, ou boucle passant par un bloc sans transmission
    end
    visite(k) = 2;
    if directe(k)
        for l = 1:size(modele.liens, 1)
            if modele.liens(l, 2) == k
                [ordre, visite] = visiter(modele, modele.liens(l, 1), directe, visite, ordre);
            end
        end
    end
    visite(k) = 1;
    ordre(end+1) = k;
end

% Un filtre discret se donne par ses deux polynômes en z^-1. Le
% dénominateur est ramené à un premier coefficient unité ; s'il est nul,
% la récurrence n'a pas de sens et on le dit.
function [num, den] = normaliserFiltre(num, den, nom)
    num = double(num(:))';
    den = double(den(:))';
    if isempty(den) || den(1) == 0
        error('simulink:sim:denominateurNul', ...
              ['Le bloc ''%s'' a un denominateur dont le premier coefficient ' ...
               'est nul : la recurrence ne se resout pas.'], nom);
    end
    num = num / den(1);
    den = den / den(1);
    if numel(num) < numel(den)
        num(numel(den)) = 0;
    elseif numel(den) < numel(num)
        den(numel(num)) = 0;
    end
end

function [y, etat] = evaluerBloc(type, p1, p2, p3, p4, signes, matrices, entrees, ...
                                 etat, temps, pas, miseAJour)
    u = entrees(1);
    switch type
        case 1
            y = p1;
        case 2
            if temps >= p1
                y = p3;
            else
                y = p2;
            end
        case 3
            y = p1 * temps;
        case 4
            y = p1 * sin(p2 * temps + p3);
        case 5
            y = p1 * u;
        case 6
            y = 0;
            for k = 1:numel(entrees)
                if k <= numel(signes) && signes(k) == '-'
                    y = y - entrees(k);
                else
                    y = y + entrees(k);
                end
            end
        case 7
            y = 1;
            for k = 1:numel(entrees)
                y = y * entrees(k);
            end
        case 8
            y = abs(u);
        case 9
            y = min(max(u, p2), p1);
        case 10
            if u >= p1
                etat = 1;
            elseif u <= p2
                etat = 0;
            end
            if etat == 1
                y = p3;
            else
                y = matrices;
            end
        case 11
            y = etat;
            if miseAJour
                etat = etat + pas * u;
            end
        case 12
            y = etat;
            if miseAJour
                etat = u;
            end
        case 13
            y = (u - etat) / pas;
            if miseAJour
                etat = u;
            end
        case 14
            A = matrices{1};
            B = matrices{2};
            C = matrices{3};
            D = matrices{4};
            y = C * etat + D * u;
            if miseAJour
                etat = etat + pas * (A * etat + B * u);
            end
        case 15
            switch signes
                case 'square', y = u ^ 2;
                case 'sqrt', y = sqrt(max(u, 0));
                case 'exp', y = exp(u);
                case 'log', y = log(max(u, eps));
                case 'reciprocal', y = 1 / u;
                otherwise, y = u;
            end
        case 16
            % Zone morte : la bande [p2, p1] est rendue nulle, et ce qui
            % la dépasse est ramené de sa largeur — la courbe reste
            % continue aux deux bords.
            if u > p1
                y = u - p1;
            elseif u < p2
                y = u - p2;
            else
                y = 0;
            end
        case 17
            y = p1 * round(u / p1);
        case 18
            % Aiguillage : la première entrée passe si la seconde
            % satisfait le critère, la troisième sinon.
            if numel(entrees) < 3
                entrees(3) = 0;
            end
            switch signes
                case 'u2>Threshold', passe = entrees(2) > p1;
                case 'u2~=0',        passe = entrees(2) ~= 0;
                otherwise,           passe = entrees(2) >= p1;
            end
            if passe
                y = entrees(1);
            else
                y = entrees(3);
            end
        case 19
            y = sign(u);
        case 20
            if strcmpi(signes, 'max')
                y = max(entrees);
            else
                y = min(entrees);
            end
        case 21
            switch lower(signes)
                case 'sin',   y = sin(u);
                case 'cos',   y = cos(u);
                case 'tan',   y = tan(u);
                case 'asin',  y = asin(u);
                case 'acos',  y = acos(u);
                case 'atan',  y = atan(u);
                case 'sinh',  y = sinh(u);
                case 'cosh',  y = cosh(u);
                case 'tanh',  y = tanh(u);
                case 'asinh', y = asinh(u);
                case 'acosh', y = acosh(u);
                case 'atanh', y = atanh(u);
                case 'atan2'
                    if numel(entrees) < 2
                        entrees(2) = 0;
                    end
                    y = atan2(entrees(1), entrees(2));
                otherwise
                    error('simulink:sim:trigonometrieInconnue', ...
                          'Operateur trigonometrique inconnu : ''%s''.', signes);
            end
        case 22
            bits = entrees ~= 0;
            switch upper(signes)
                case 'AND',  y = all(bits);
                case 'OR',   y = any(bits);
                case 'NAND', y = ~all(bits);
                case 'NOR',  y = ~any(bits);
                case 'XOR',  y = mod(sum(bits), 2) == 1;
                case 'NXOR', y = mod(sum(bits), 2) == 0;
                case 'NOT',  y = ~bits(1);
                otherwise,   y = all(bits);
            end
            y = double(y);
        case 23
            if numel(entrees) < 2
                entrees(2) = 0;
            end
            a = entrees(1);
            b = entrees(2);
            switch signes
                case '==',  y = a == b;
                case '~=',  y = a ~= b;
                case '<',   y = a < b;
                case '<=',  y = a <= b;
                case '>',   y = a > b;
                case '>=',  y = a >= b;
                otherwise,  y = a < b;
            end
            y = double(y);
        case 24
            abscisses = matrices{1};
            valeurs = matrices{2};
            % Hors table, la valeur est tenue : c'est le comportement par
            % défaut du bloc, qui ne prolonge pas la pente.
            if u <= abscisses(1)
                y = valeurs(1);
            elseif u >= abscisses(end)
                y = valeurs(end);
            else
                y = interp1(abscisses, valeurs, u);
            end
        case 25
            y = u + p1;
        case 26
            y = etat;
            if miseAJour
                etat = u;
            end
        case 27
            % Retard pur : le tampon garde les entrées passées, la plus
            % ancienne en tête. La position cherchée est rarement entière ;
            % les deux échantillons qui l'encadrent sont interpolés.
            longueur = p2;
            if p1 == 0
                y = u;
            else
                place = longueur + 2 - p1 / pas;
                place = min(max(place, 1), longueur + 1);
                bas = floor(place);
                if bas >= longueur + 1
                    y = etat(longueur + 1);
                else
                    part = place - bas;
                    y = (1 - part) * etat(bas) + part * etat(bas + 1);
                end
            end
            if miseAJour
                etat = [etat(2:end), u];
            end
        case 28
            pente = (u - etat) / pas;
            if pente > p1
                y = etat + pas * p1;
            elseif pente < p2
                y = etat + pas * p2;
            else
                y = u;
            end
            if miseAJour
                etat = y;
            end
        case 29
            % Tenue d'ordre zéro : l'entrée n'est relue qu'aux instants
            % d'échantillonnage, et tenue entre deux.
            if temps - etat(2) >= p1 - pas / 2
                etat(1) = u;
                etat(2) = temps;
            end
            y = etat(1);
        case 30
            [y, etat] = integrateurDiscret(p1, p2, signes, u, etat, temps, pas, miseAJour);
        case 31
            [y, etat] = filtreDiscret(matrices{1}, matrices{2}, p1, u, etat, temps, ...
                                      pas, miseAJour);
        case 32
            [y, etat] = etatDiscret(matrices, p1, u, etat, temps, pas, miseAJour);
        case 33
            % PID en forme parallèle, dérivée filtrée par N/(1+N/s) : sans
            % ce filtre la dérivée d'un échelon serait infinie, et le pas
            % fixe la rendrait simplement fausse.
            y = p1 * u + p2 * etat(1) + p3 * p4 * (u - p4 * etat(2));
            if miseAJour
                etat(1) = etat(1) + pas * u;
                etat(2) = etat(2) + pas * (u - p4 * etat(2));
            end
        case 34
            y = p2;
        case 35
            y = u;
        case 36
            % Le signal lu dans l'espace de travail, déjà rééchantillonné
            % sur les instants : le rang se déduit du temps.
            rang = round(temps / pas) + 1;
            y = matrices(min(max(rang, 1), numel(matrices)));
        case 37
            y = u;
        otherwise
            y = u;
    end
end

% Un bloc « depuis l'espace de travail » lit une variable de l'espace de
% base : soit deux colonnes [temps valeur], soit la structure à temps que
% SIM journalise. Le signal est interpolé linéairement sur les instants
% demandés, et tenu au-delà de ses bornes.
function valeurs = lireSignalEspace(nomVariable, nomBloc, instants)
    nomVariable = char(nomVariable);
    if isempty(nomVariable)
        error('simulink:sim:variableAbsente', ...
              ['Le bloc ''%s'' ne dit pas quelle variable lire : donnez-lui ' ...
               'un parametre VariableName.'], nomBloc);
    end
    if ~isvarname(nomVariable)
        donnees = matlibre_sl_expression(nomVariable, nomBloc, 'VariableName');
    elseif evalin('base', sprintf('exist(''%s'', ''var'')', nomVariable)) ~= 1
        error('simulink:sim:variableAbsente', ...
              ['Le bloc ''%s'' lit la variable ''%s'', qui n''existe pas dans ' ...
               'l''espace de travail de base.'], nomBloc, nomVariable);
    else
        donnees = evalin('base', nomVariable);
    end
    if isstruct(donnees) && isfield(donnees, 'time') && isfield(donnees, 'signals')
        temps = double(donnees.time(:));
        signal = double(donnees.signals(1).values(:));
    elseif isnumeric(donnees) && ismatrix(donnees) && size(donnees, 2) == 2
        temps = double(donnees(:, 1));
        signal = double(donnees(:, 2));
    else
        % Exactement deux colonnes : les signaux de MatLibre sont
        % scalaires, si bien qu'une troisième colonne serait un second
        % signal, qu'aucun lien ne saurait où porter.
        error('simulink:sim:signalMalForme', ...
              ['La variable ''%s'' que lit le bloc ''%s'' doit porter deux ' ...
               'colonnes — le temps puis la valeur — ou la structure a temps ' ...
               'que SIM journalise. Elle est de taille %s.'], nomVariable, ...
              nomBloc, mat2str(size(donnees)));
    end
    if numel(temps) ~= numel(signal)
        error('simulink:sim:signalMalForme', ...
              ['La variable ''%s'' porte %d instants et %d valeurs.'], ...
              nomVariable, numel(temps), numel(signal));
    end
    if numel(temps) == 1
        valeurs = repmat(signal(1), 1, numel(instants));
        return
    end
    valeurs = interp1(temps, signal, instants, 'linear');
    % Hors des bornes du signal donné, la valeur est tenue plutôt que
    % rendue absente : une simulation ne s'arrête pas au bout des données.
    valeurs(instants < temps(1)) = signal(1);
    valeurs(instants > temps(end)) = signal(end);
end

% Intégrateur discret. Les trois méthodes de Simulink diffèrent par ce
% qu'elles font de l'entrée courante : Euler avant l'ignore — d'où
% l'absence de transmission directe —, Euler arrière la prend entière, le
% trapèze la prend pour moitié.
function [y, etat] = integrateurDiscret(gain, periode, methode, u, etat, temps, ...
                                        pas, miseAJour)
    echantillon = (temps - etat(2) >= periode - pas / 2);
    if ~echantillon
        y = etat(3);
        return
    end
    x = etat(1);
    switch lower(methode)
        case 'backwardeuler'
            y = x + gain * periode * u;
        case 'trapezoidal'
            y = x + gain * periode * u / 2;
        otherwise
            y = x;
    end
    etat(3) = y;
    if miseAJour
        switch lower(methode)
            case 'backwardeuler'
                etat(1) = y;
            case 'trapezoidal'
                etat(1) = y + gain * periode * u / 2;
            otherwise
                etat(1) = x + gain * periode * u;
        end
        etat(2) = temps;
    end
end

% Fonction de transfert discrète, forme directe II : un seul jeu de
% valeurs retardées sert au numérateur et au dénominateur.
function [y, etat] = filtreDiscret(num, den, periode, u, etat, temps, pas, miseAJour)
    m = numel(den) - 1;
    passe = etat(1:m);
    dernier = etat(m + 1);
    echantillon = (temps - dernier >= periode - pas / 2);
    if ~echantillon
        y = etat(m + 2);
        return
    end
    if num(1) ~= 0
        w = u - den(2:end) * passe(:);
        y = num(1) * w + num(2:end) * passe(:);
    else
        y = num(2:end) * passe(:);
    end
    etat(m + 2) = y;
    if miseAJour
        if m > 0
            w = u - den(2:end) * passe(:);
            etat(1:m) = [w, passe(1:m-1)];
        end
        etat(m + 1) = temps;
    end
end

% Représentation d'état discrète : x(k+1) = A x(k) + B u(k), y = C x + D u.
function [y, etat] = etatDiscret(matrices, periode, u, etat, temps, pas, miseAJour)
    A = matrices{1};
    B = matrices{2};
    C = matrices{3};
    D = matrices{4};
    x = etat{1};
    echantillon = (temps - etat{2} >= periode - pas / 2);
    if ~echantillon
        y = etat{3};
        return
    end
    y = C * x + D * u;
    etat{3} = y;
    if miseAJour
        etat{1} = A * x + B * u;
        etat{2} = temps;
    end
end
