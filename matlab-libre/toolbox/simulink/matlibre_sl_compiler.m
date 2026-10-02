function c = matlibre_sl_compiler(modele, options)
%MATLIBRE_SL_COMPILER Prépare un modèle pour la simulation.
%   C = MATLIBRE_SL_COMPILER(MODELE,OPTIONS) fait ce que Simulink fait
%   avant de simuler : il déplie les sous-systèmes, résout le type et les
%   paramètres de chaque bloc — les expressions s'évaluent alors dans
%   l'espace de travail de base —, vérifie le câblage port par port,
%   propage les dimensions des signaux, attribue à chaque bloc sa période
%   d'échantillonnage, range les états, ordonne le calcul, et détecte les
%   boucles algébriques pour les résoudre.
%
%   OPTIONS porte les champs pas (le pas de base, 0,01 par défaut),
%   tDebut, tFinal et config (la configuration du modèle, que lit
%   MATLIBRE_SL_CONFIG). Le champ silencieux, vrai, tait les diagnostics
%   de connexion et de boucle — LINMOD s'en sert, qui compile plusieurs
%   fois le même modèle. Le champ variable, vrai, prépare un solveur à
%   pas variable : les périodes n'ont plus à diviser un pas, le retard
%   pur garde les instants avec les valeurs, et les blocs à cassure sont
%   marqués pour la détection des passages par zéro (c.zc).
%
%   Chaque erreur nomme le bloc par son chemin, « modele/bloc », comme
%   Simulink le fait : un port qui n'existe pas, deux liens vers une même
%   entrée, des dimensions qui ne s'accordent pas, une période
%   d'échantillonnage qui n'est pas un multiple du pas, un Goto
%   introuvable. Une entrée non reliée ou une boucle algébrique donnent un
%   avertissement ou une erreur selon les réglages UnconnectedInputMsg et
%   AlgebraicLoopMsg du modèle.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = add_block(new_system('m'), 'constant', 'c', 'Value', [1 2 3]);
%      m = add_line(add_block(m, 'gain', 'k', 'Gain', 2), 'c', 'k');
%      c = matlibre_sl_compiler(m, struct('silencieux', true));
%      c.dims{c.portDebut(2)}                 % [3 1] : un vecteur de trois
%
%   Voir aussi SIM, MATLIBRE_SL_SORTIES, MATLIBRE_SL_CATALOGUE.
    if nargin < 2
        options = struct();
    end
    % Une erreur imprévue, pendant qu'un bloc se compile, devient une
    % erreur de Simulink qui nomme ce bloc et le paramètre qui paraît
    % fautif. Un modèle intérieur — celui d'un sous-système itéré — se
    % compile au milieu d'un autre : on rend l'état d'avant en sortant.
    avant = enCours('sauver');
    % Le Data Type Override du modèle vaut le temps de la compilation : les
    % types des signaux et des paramètres s'y résolvent.
    surchargeAvant = matlibre_sl_types('surcharge');
    config = [];
    if isstruct(options) && isfield(options, 'config')
        config = options.config;
    end
    if isempty(config) && isstruct(modele)
        config = matlibre_sl_config('lire', modele);
    end
    if isstruct(config) && isfield(config, 'DataTypeOverride')
        matlibre_sl_types('surcharge', config.DataTypeOverride, ...
                          config.DataTypeOverrideAppliesTo);
    end
    try
        c = compiler(modele, options);
        if ~isempty(c.aInserer)
            % AutoInsertRateTranBlk : les Rate Transition que Simulink
            % insère, posés dans le modèle, qui se compile de nouveau
            options.transitionsPosees = true;
            c = compiler(insererTransitions(modele, c.aInserer), options);
        end
    catch err
        matlibre_sl_types('surcharge', surchargeAvant);
        [k, bloc, chemin] = enCours('lire');
        enCours('restaurer', avant);
        if k == 0 || strncmp(err.identifier, 'Simulink:', 9) || ...
           strncmp(err.identifier, 'Stateflow:', 10) || strncmp(err.identifier, 'Simscape:', 9)
            rethrow(err);
        end
        throw(matlibre_sl_fautif(err, bloc.type, bloc.parametres, chemin));
    end
    matlibre_sl_types('surcharge', surchargeAvant);
    enCours('restaurer', avant);
end

function c = compiler(modele, options)
    if nargin < 2 || isempty(options)
        options = struct();
    end
    pas = champ(options, 'pas', 0.01);
    tDebut = champ(options, 'tDebut', 0);
    tFinal = champ(options, 'tFinal', 10);
    silencieux = champ(options, 'silencieux', false);
    variable = champ(options, 'variable', false);
    config = champ(options, 'config', []);
    entreesExternes = champ(options, 'entrees', {});
    if isempty(config)
        config = matlibre_sl_config('lire', modele);
    end

    nomModele = char(modele.nom);
    modele = matlibre_sl_aplatir(modele);
    modele = memoiresGlobales(modele);
    modele = variantesDeSignal(modele, nomModele);
    n = numel(modele.blocs);

    c = struct();
    c.nom = nomModele;
    c.n = n;
    c.pas = pas;
    c.variable = variable;
    c.tDebut = tDebut;
    c.tFinal = tFinal;
    c.config = config;
    c.noms = cell(1, n);
    c.chemins = cell(1, n);
    c.types = cell(1, n);
    c.code = zeros(1, n);
    c.p = cell(1, n);
    c.nIn = zeros(1, n);
    c.nOut = zeros(1, n);
    % La garde de chaque bloc — le rang du bloc qui dit si son sous-système
    % conditionnel calcule, 0 hors d'eux —, et la conduite des sorties d'un
    % sous-système conditionnel.
    c.garde = zeros(1, n);
    c.sortieCond = cell(1, n);
    % Les réglages des signaux qui partent de chaque bloc — leur nom, leur
    % journalisation —, que SIM lit pour logsout.
    c.signaux = cell(1, n);
    % La plage [OutMin, OutMax] de chaque bloc qui en dit une, vide sinon.
    c.plage = cell(1, n);

    % --- 1. types et paramètres ---------------------------------------------
    enCours('modele', modele.blocs, cellfun(@(b) [nomModele '/' char(b.nom)], ...
                                            modele.blocs, 'UniformOutput', false));
    for k = 1:n
        enCours('bloc', k);
        bloc = modele.blocs{k};
        c.noms{k} = char(bloc.nom);
        c.chemins{k} = [nomModele '/' c.noms{k}];
        try
            entree = matlibre_sl_catalogue('type', bloc.type);
        catch
            error('Simulink:Commands:InvalidBlockType', ...
                  ['Le bloc ''%s'' est d''un type inconnu : ''%s''. Voir ADD_BLOCK ' ...
                   'pour la liste des types reconnus.'], c.chemins{k}, char(bloc.type));
        end
        c.types{k} = entree.type;
        if isfield(bloc, 'garde')
            c.garde(k) = bloc.garde;
        end
        if isfield(bloc, 'sortieConditionnelle')
            c.sortieCond{k} = sortieInitiale(bloc.sortieConditionnelle, c.chemins{k});
        end
        if isfield(bloc, 'signaux')
            c.signaux{k} = bloc.signaux;
        end
        c.p{k} = lireParametres(entree, bloc, c.chemins{k});
        c.plage{k} = plageDeSortie(c.types{k}, c.p{k}, c.chemins{k});
        % Un bloc qui n'est qu'une autre façon d'en écrire un se ramène à lui :
        % Band-Limited White Noise à Random Number, Discrete Zero-Pole à
        % Discrete Transfer Fcn.
        origine = c.types{k};
        [c.types{k}, c.p{k}] = normaliser(c.types{k}, c.p{k}, c.chemins{k});
        if strcmp(c.types{k}, 'matlabfunction') && ~strcmp(origine, 'matlabfunction')
            c.p{k}.Bibliotheque = origine;   % ce qu'il accepte, en complexe, est le sien
        end
        % Une entrée du modèle qui reçoit une entrée externe la lit comme un
        % From Workspace lirait sa variable.
        if strcmp(c.types{k}, 'inport') && ~any(c.noms{k} == '/') && ...
           ~isempty(entreesExternes)
            rang = double(c.p{k}.Port);
            if rang <= numel(entreesExternes) && ~isempty(entreesExternes{rang})
                c.types{k} = 'fromworkspace';
                c.p{k} = struct('VariableName', '', 'Interpolate', 'on', ...
                                'OutputAfterFinalValue', 'Holding final value', ...
                                'SampleTime', 0, 'ZeroCross', 'on', ...
                                'Donnees', entreesExternes{rang}, ...
                                'OutDataTypeStr', champ(c.p{k}, 'OutDataTypeStr', ''));
            end
        end
        c.code(k) = codeDe(c.types{k});
        [ne, ns] = matlibre_sl_ports(struct('type', c.types{k}, 'nom', bloc.nom, ...
                                            'parametres', c.p{k}), c.types{k});
        if strcmp(c.types{k}, 'msfunction') && any(isnan([ne ns]))
            % Une S-fonction de niveau 2 dit ses ports dans setup : si l'on
            % n'a pas pu les lire, c'est setup qu'on refait, pour rendre
            % l'erreur qui dit pourquoi.
            matlibre_sl_msfonction('preparer', c.p{k}.FunctionName, ...
                                   parametresSFonction(c.p{k}, c.chemins{k}), c.chemins{k});
        end
        if ~(isfinite(ne) && ne >= 0 && ne == round(ne) && isfinite(ns) && ...
             ns >= 0 && ns == round(ns))
            error('Simulink:Parameters:InvalidPortCount', ...
                  ['Le bloc ''%s'' demande un nombre de ports qui n''est pas un ' ...
                   'entier positif : verifiez ses parametres Inputs, Outputs, ' ...
                   'NumInputs ou NumInputPorts.'], c.chemins{k});
        end
        c.nIn(k) = ne;
        c.nOut(k) = ns;
    end

    % Les blocs de code : leur fonction se prépare une fois, ici — une
    % expression devient une poignée, un texte de MATLAB Function un
    % fichier, une S-fonction dit ses tailles.
    c.fonctions = cell(1, n);
    for k = 1:n
        enCours('bloc', k);
        c.fonctions{k} = preparerCode(c, k);
    end

    % --- 2. ports de sortie, numérotés d'un bout à l'autre du modèle --------
    c.portDebut = zeros(1, n);
    c.proprio = zeros(1, 0);
    c.rang = zeros(1, 0);
    total = 0;
    for k = 1:n
        c.portDebut(k) = total + 1;
        c.proprio(total + (1:c.nOut(k))) = k;
        c.rang(total + (1:c.nOut(k))) = 1:c.nOut(k);
        total = total + c.nOut(k);
    end
    c.nPorts = total;

    % --- 3. câblage --------------------------------------------------------
    c.entrees = cell(1, n);
    for k = 1:n
        c.entrees{k} = zeros(1, c.nIn(k));
    end
    liens = matlibre_sl_liens(modele);
    for l = 1:size(liens, 1)
        a = liens(l, 1);
        b = liens(l, 2);
        pe = liens(l, 3);
        ps = liens(l, 4);
        if a < 1 || a > n || b < 1 || b > n
            error('Simulink:Commands:InvalidModel', ...
                  'Le lien %d designe un bloc qui n''existe pas dans ''%s''.', l, nomModele);
        end
        if ps > c.nOut(a)
            if c.nOut(a) == 0
                error('Simulink:Engine:InvalidPort', ...
                      'Le bloc ''%s'' n''a pas de port de sortie ; un lien en part pourtant.', ...
                      c.chemins{a});
            end
            error('Simulink:Engine:InvalidPort', ...
                  ['Le bloc ''%s'' n''a que %d port(s) de sortie ; un lien part de son ' ...
                   'port %d.'], c.chemins{a}, c.nOut(a), ps);
        end
        if pe > c.nIn(b)
            if c.nIn(b) == 0
                error('Simulink:Engine:InvalidPort', ...
                      'Le bloc ''%s'' n''a pas de port d''entree ; un lien y arrive pourtant.', ...
                      c.chemins{b});
            end
            error('Simulink:Engine:InvalidPort', ...
                  ['Le bloc ''%s'' n''a que %d port(s) d''entree ; un lien arrive sur son ' ...
                   'port %d.'], c.chemins{b}, c.nIn(b), pe);
        end
        if c.entrees{b}(pe) ~= 0
            error('Simulink:Engine:MultipleSources', ...
                  ['Le port d''entree %d de ''%s'' recoit deux liens : une entree ne ' ...
                   'recoit qu''un signal.'], pe, c.chemins{b});
        end
        c.entrees{b}(pe) = c.portDebut(a) + ps - 1;
    end

    % --- 4. Goto et From, mémoires partagées, appels de fonction -------------
    c = resoudreGoto(c);
    c = resoudreMemoires(c);
    verifierAppels(c);

    % --- 5. transmission directe -------------------------------------------
    c.direct = true(1, n);
    for k = 1:n
        enCours('bloc', k);
        c.direct(k) = transmissionDirecte(c, k);
    end

    % --- 6. dimensions ------------------------------------------------------
    c.dims = propagerDimensions(c);
    c.dimsCourants = c.dims;   % la forme des bus se lit sur les dimensions
    verifierTypesBus(c);

    % les bus : la forme de celui qu'un Bus Selector ou un Bus Assignment
    % reçoit, et ce qu'il en choisit ; la forme qu'un Bus Creator typé tire
    % de ses entrées. Les types de leurs éléments s'y liront.
    c.formeBus = cell(1, n);
    c.choixBus = cell(1, n);
    for k = 1:n
        switch c.types{k}
            case 'busselector'
                c.formeBus{k} = formeBus(c, c.entrees{k}(1));
                c.choixBus{k} = elementsChoisis(c, k);
            case 'busassignment'
                c.formeBus{k} = formeBus(c, c.entrees{k}(1));
                c.choixBus{k} = placesAssignees(c, k, c.formeBus{k});
            case 'buscreator'
                if ~isempty(matlibre_sl_bus('type', champ(c.p{k}, 'OutDataTypeStr', '')))
                    c.formeBus{k} = formeDesEntrees(c, k);
                end
        end
    end

    % --- 6 bis. types de données ---------------------------------------------
    c.typePort = matlibre_sl_types('propager', c);
    c = initialesEnumerees(c);
    % --- 6 ter. complexité : ce qui est complexe, ce qui le refuse ---------
    c.sourceComplexe = false(1, n);
    for k = find(strcmp(c.types, 'fromworkspace'))
        enCours('bloc', k);
        [~, valeurs] = lireSignalEspace(c.p{k}, c.chemins{k});
        c.sourceComplexe(k) = ~isreal(valeurs);
    end
    c.complexePort = matlibre_sl_types('complexite', c);
    [c.castK, c.arrondiK, c.saturerK] = conversionsDesSorties(c);
    c.largeur = zeros(1, c.nPorts);
    for gp = 1:c.nPorts
        c.largeur(gp) = prod(c.dims{gp});
    end

    % --- 7. tampon des valeurs : V(1) est la masse, puis chaque port ---------
    c.vA = zeros(1, c.nPorts);
    c.vB = zeros(1, c.nPorts);
    suivant = 2;
    for gp = 1:c.nPorts
        c.vA(gp) = suivant;
        c.vB(gp) = suivant + c.largeur(gp) - 1;
        suivant = suivant + c.largeur(gp);
    end
    c.nV = suivant - 1;
    c.inA = cell(1, n);
    c.inB = cell(1, n);
    c.inDims = cell(1, n);
    c.inMat = cell(1, n);
    c.oA = zeros(1, n);
    c.oB = zeros(1, n);
    for k = 1:n
        e = c.entrees{k};
        c.inA{k} = ones(1, numel(e));
        c.inB{k} = ones(1, numel(e));
        c.inDims{k} = cell(1, numel(e));
        c.inMat{k} = false(1, numel(e));
        for j = 1:numel(e)
            if e(j) > 0
                c.inA{k}(j) = c.vA(e(j));
                c.inB{k}(j) = c.vB(e(j));
                c.inDims{k}{j} = c.dims{e(j)};
                c.inMat{k}(j) = all(c.dims{e(j)} > 1);
            else
                c.inDims{k}{j} = [1 1];
            end
        end
        if c.nOut(k) >= 1
            c.oA(k) = c.vA(c.portDebut(k));
            c.oB(k) = c.vB(c.portDebut(k));
        end
    end

    % --- 8. périodes d'échantillonnage -------------------------------------
    % FixedStep 'auto' : le pas se déduit des périodes, avant qu'elles ne
    % se rapportent à lui
    if champ(options, 'pasAuto', false)
        pas = pasFondamental(c, tDebut, tFinal);
        c.pas = pas;
    end
    c = periodes(c, pas);
    c = transitionsDeCadence(c, config, silencieux, champ(options, 'transitionsPosees', false));

    % --- 9. ce que le calcul lira : paramètres et états ---------------------
    c = abaisser(c, pas, tDebut);
    % Un sous-système déclenché ne calcule qu'aux fronts : un état continu
    % n'y aurait rien à intégrer entre deux, et Simulink le refuse.
    c.declenche = false(1, n);
    for k = 1:n
        g = c.garde(k);
        while g > 0
            if ~strcmp(c.p{g}.Trigger, 'none')
                c.declenche(k) = true;
                break
            end
            g = c.garde(g);
        end
        if c.declenche(k) && c.xA(k) > 0
            error('Simulink:blocks:TriggeredSubsystemContinuousStates', ...
                  ['Le bloc ''%s'' a des etats continus, mais il est dans un ' ...
                   'sous-systeme declenche, qui ne calcule qu''aux fronts de son ' ...
                   'entree Trigger. Prenez un bloc discret, ou un sous-systeme ' ...
                   'active par Enable.'], c.chemins{k});
        end
    end

    % --- 10. ordre de calcul et boucles algébriques --------------------------
    c = ordonner(c);
    % Un Algebraic Constraint n'a de sens que dans une boucle : sa sortie z
    % doit revenir à son entrée f(z).
    for k = find(strcmp(c.types, 'algebraicconstraint'))
        dedans = false;
        for b = 1:numel(c.boucles)
            dedans = dedans || any(c.boucles{b}.blocs == k);
        end
        if ~dedans
            error('Simulink:blocks:AlgebraicConstraintNotInLoop', ...
                  ['L''Algebraic Constraint ''%s'' n''est dans aucune boucle algebrique : ' ...
                   'sa sortie z doit revenir a son entree f(z), sans bloc a memoire ' ...
                   'entre elles.'], c.chemins{k});
        end
    end

    % --- 11. passages par zéro ------------------------------------------------
    c.zc = passagesParZero(c);

    % --- 12. diagnostics ----------------------------------------------------
    if ~silencieux
        diagnostiquer(c);
    end
end

% === paramètres ===============================================================

function v = champ(s, nom, defaut)
    if isfield(s, nom) && ~isempty(s.(nom))
        v = s.(nom);
    else
        v = defaut;
    end
end

% Les paramètres d'un bloc, sous leur nom canonique, avec le défaut de ceux
% qu'on n'a pas écrits. Un nom inconnu est refusé en le nommant, comme
% Simulink le fait : rangé, il n'aurait été lu par personne.
function p = lireParametres(entree, bloc, chemin)
    p = struct();
    for i = 1:size(entree.params, 1)
        p.(entree.params{i, 1}) = entree.params{i, 2};
    end
    communs = matlibre_sl_catalogue('communs');
    ecrits = fieldnames(bloc.parametres);
    for i = 1:numel(ecrits)
        canon = matlibre_sl_catalogue('parametre', entree, ecrits{i});
        if isempty(canon)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le bloc ''%s'' (%s) n''a pas de parametre nomme ''%s''. Ses ' ...
                   'parametres sont : %s.'], chemin, entree.affiche, ecrits{i}, ...
                  strjoin(entree.params(:, 1)', ', '));
        end
        if any(strcmp(canon, communs))
            continue
        end
        p.(canon) = bloc.parametres.(ecrits{i});
    end
    for i = 1:size(entree.params, 1)
        nom = entree.params{i, 1};
        nature = entree.params{i, 3};
        v = p.(nom);
        if iscell(nature)
            p.(nom) = choisir(v, nature, chemin, nom);
        elseif strcmp(nature, 'nombre')
            if (ischar(v) || isstring(v)) && isfield(bloc, 'espace')
                v = matlibre_sl_masque('evaluer', char(v), bloc.espace, chemin, nom);
            elseif ischar(v) || isstring(v)
                v = matlibre_sl_expression(char(v), chemin, nom, 'classe');
            elseif isa(v, 'Simulink.Parameter')
                % l'objet donné tel quel, plutôt que par son nom
                v = matlibre_sl_parametre('valeur', v, 'la valeur donnee', chemin, nom);
            end
            if isobject(v) && isenum(v)
                % un membre d'énumération : sa valeur entière, et sa classe,
                % que la propagation des types lit ('Enum: Couleur')
                classe = class(v);
                try
                    v = double(v);
                catch
                    error('Simulink:DataType:EnumTypeNotInteger', ...
                          ['Le parametre ''%s'' du bloc ''%s'' est un membre de ''%s'', une ' ...
                           'enumeration dont les membres ne portent pas de valeurs ' ...
                           'entieres : derivez-la de Simulink.IntEnumType et donnez a ' ...
                           'chaque membre sa valeur, Rouge(1).'], nom, chemin, classe);
                end
                if ~isfield(p, 'Classes')
                    p.Classes = struct();
                end
                p.Classes.(nom) = ['Enum: ' classe];
            end
            if ~(isnumeric(v) || islogical(v))
                error('Simulink:Parameters:InvalidValue', ...
                      'Le parametre ''%s'' du bloc ''%s'' doit etre numerique.', nom, chemin);
            end
            if ~isa(v, 'double')
                % la classe d'origine, que la propagation des types lit :
                % une constante int8(5) donne un signal int8, fi(pi) un
                % signal sfix16_En13
                if ~isfield(p, 'Classes')
                    p.Classes = struct();
                end
                p.Classes.(nom) = class(v);
                if isa(v, 'embedded.fi')
                    p.Classes.(nom) = matlibre_sl_types('nom', matlibre_sl_types('codeValeur', v));
                end
            end
            if any(strcmp(nom, {'SampleTime', 'tsamp', 'samptime', 'sample_time', 'Ts', ...
                                'OutPortSampleTime'}))
                verifierPeriode(v, entree.params{i, 2}, chemin, nom);
            else
                verifierNombre(v, entree.params{i, 2}, chemin, nom, ...
                               complexeAdmis(entree.type, nom));
            end
            p.(nom) = double(v);
        elseif strcmp(nature, 'texte')
            if isnumeric(v)
                p.(nom) = v;
            else
                p.(nom) = char(v);
            end
        end
    end
end

function [type, p] = normaliser(type, p, chemin)
    switch type
        case 'enumeratedconstant'
            % un Constant dont la valeur est un membre, et le type celui de
            % son énumération (OutDataTypeStr, 'Enum: Couleur')
            type = 'constant';
        case 'sum'
            verifierSignes(p.Signs, '+-', chemin, 'Signs', ...
                           'des + et des - (et des | pour espacer les ports)');
        case 'product'
            verifierSignes(p.Inputs, '*/', chemin, 'Inputs', ...
                           'des * et des / (multiplier, diviser)');
        case 'bandlimitedwhitenoise'
            % Un bruit blanc de densité Cov, tenu pendant Ts : sa variance
            % est Cov / Ts, comme dans le bloc de Simulink.
            Ts = double(p.Ts);
            if isempty(Ts) || Ts(1) <= 0
                error('Simulink:Parameters:InvalidValue', ...
                      'La periode Ts du bruit blanc ''%s'' doit etre positive.', chemin);
            end
            if any(double(p.Cov(:)) < 0)
                error('Simulink:Parameters:InvalidValue', ...
                      'La puissance Cov du bruit blanc ''%s'' ne peut pas etre negative.', ...
                      chemin);
            end
            p = struct('Mean', 0, 'Variance', double(p.Cov) / Ts(1), 'Seed', p.seed, ...
                       'SampleTime', Ts);
            type = 'randomnumber';
        case 'lookup'
            dimensions = double(p.NumberOfTableDimensions);
            if dimensions == 2
                p = struct('BreakpointsForDimension1', p.BreakpointsData, ...
                           'BreakpointsForDimension2', p.BreakpointsForDimension2, ...
                           'Table', p.TableData, 'SampleTime', p.SampleTime);
                type = 'lookup2d';
            elseif any(dimensions == 3:6)
                % au-delà de deux dimensions, la table s'interpole par une
                % fonction, que le bloc MATLAB Function calcule
                p = struct('Script', scriptTableND(p, dimensions, chemin), ...
                           'SampleTime', p.SampleTime);
                type = 'matlabfunction';
            elseif dimensions ~= 1
                error('Simulink:blocks:LookupNDDimensions', ...
                      ['La table ''%s'' est a %g dimensions : MatLibre interpole de une ' ...
                       'a six dimensions.'], chemin, dimensions);
            end
        case 'directlookup'
            dimensions = double(p.NumberOfTableDimensions);
            if any(dimensions == 3:6)
                p = struct('Script', scriptTableDirecte(p, dimensions, chemin), ...
                           'SampleTime', p.SampleTime);
                type = 'matlabfunction';
            elseif ~any(dimensions == [1 2])
                error('Simulink:blocks:LookupNDDimensions', ...
                      ['La table directe ''%s'' est a %g dimensions : MatLibre en lit ' ...
                       'de une a six.'], chemin, dimensions);
            end
        case 'discretezeropole'
            numerateur = double(p.Gain) * poly(double(p.Zeros(:)));
            denominateur = poly(double(p.Poles(:)));
            if numel(p.Zeros) > numel(p.Poles)
                error('Simulink:blocks:TransferFcnImproper', ...
                      ['''%s'' porte plus de zeros que de poles : sa transmittance n''est ' ...
                       'pas propre.'], chemin);
            end
            p = struct('Numerator', numerateur, 'Denominator', denominateur, ...
                       'SampleTime', p.SampleTime, 'ZeroPole', true);
            type = 'discretetransferfcn';
        case 'fromfile'
            % From File lit son fichier et devient un From Workspace qui
            % porte ses données.
            [temps, valeurs] = lireFichierSignal(char(p.FileName), chemin);
            interpolation = 'on';
            if strcmp(p.InterpolationWithinTimeRange, 'Zero-order hold')
                interpolation = 'off';
            end
            apres = struct('Linear_extrapolation', 'Extrapolation', ...
                           'Hold_last_value', 'Holding final value', ...
                           'Ground_value', 'Setting to zero');
            p = struct('VariableName', char(p.FileName), 'Interpolate', interpolation, ...
                       'OutputAfterFinalValue', ...
                       apres.(strrep(p.ExtrapolationAfterLastDataPoint, ' ', '_')), ...
                       'SampleTime', p.SampleTime, 'ZeroCross', 'on', ...
                       'Donnees', struct('temps', temps, 'valeurs', valeurs));
            type = 'fromworkspace';
        case 'assignment'
            p = struct('Script', scriptAffectation(p, chemin), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'combinatoriallogic'
            p = struct('Script', scriptLogiqueCombinatoire(p, chemin), ...
                       'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case {'detectrisepositive', 'detectrisenonnegative', 'detectfallnegative', ...
              'detectfallnonpositive'}
            p = struct('Script', scriptDetection(type, p), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'intervaltestdynamic'
            droite = '<=';
            if strcmp(p.IntervalClosedRight, 'off')
                droite = '<';
            end
            gauche = '>=';
            if strcmp(p.IntervalClosedLeft, 'off')
                gauche = '>';
            end
            p = struct('Script', sprintf('function y = fcn(up, u, lo)\ny = (u %s up) & (u %s lo);\n', ...
                                         droite, gauche), 'SampleTime', -1);
            type = 'matlabfunction';
        case {'bitwiseoperator', 'bitset', 'bitclear', 'shiftarithmetic'}
            p = struct('Script', scriptBits(type, p, chemin), 'SampleTime', -1, ...
                       'EntiersSeuls', true);
            type = 'matlabfunction';
        case 'sinewavefunction'
            if strcmp(p.SineType, 'Sample based')
                error('Simulink:blocks:SineWaveFunctionSampleBased', ...
                      ['Le bloc ''%s'' est regle sur ''Sample based'' : MatLibre calcule la ' ...
                       'sinusoide de son entree en ''Time based'', A sin(F u + P) + B.'], chemin);
            end
            p = struct('Script', sprintf('function y = fcn(u)\ny = %s .* sin(%s .* u + %s) + %s;\n', ...
                                         texteValeur(p.Amplitude), texteValeur(p.Frequency), ...
                                         texteValeur(p.Phase), texteValeur(p.Bias)), ...
                       'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'permutedimensions'
            ordre = double(p.Order(:).');
            if numel(ordre) < 2 || ~isequal(sort(ordre), 1:numel(ordre))
                error('Simulink:blocks:PermuteDimensionsOrder', ...
                      ['L''ordre %s du bloc ''%s'' n''est pas une permutation de 1 a N, ' ...
                       'N etant au moins 2.'], mat2str(ordre), chemin);
            end
            p = struct('Script', sprintf('function y = fcn(u)\ny = permute(u, %s);\n', ...
                                         mat2str(ordre)), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'squeeze'
            p = struct('Script', sprintf('function y = fcn(u)\ny = squeeze(u);\n'), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'lookuptabledynamic'
            p = struct('Script', scriptTableDynamique(p, chemin), 'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'prelookup'
            p = struct('Script', scriptPrerecherche(p, chemin), 'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'interpolationusingprelookup'
            p = struct('Script', scriptInterpolationPrerecherche(p, chemin), ...
                       'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'sinecosine'
            p = struct('Script', scriptSinusCosinus(p, chemin), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'discretefirfilter'
            b = double(p.Coefficients(:).');
            if isempty(b)
                error('Simulink:blocks:DiscreteFirCoefficients', ...
                      'Le filtre ''%s'' n''a pas de coefficients.', chemin);
            end
            if all(double(p.InitialStates(:)) == 0)
                p = struct('Numerator', b, 'Denominator', 1, 'SampleTime', p.SampleTime, ...
                           'Bibliotheque', 'discretefirfilter');
                type = 'discretefilter';
            else
                p = struct('Script', scriptRIF(b, double(p.InitialStates), chemin), ...
                           'SampleTime', p.SampleTime);
                type = 'matlabfunction';
            end
        case {'transferfcnfirstorder', 'transferfcnleadorlag', 'transferfcnrealzero'}
            p = struct('Script', scriptPremierOrdre(type, p), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'ratelimiterdynamic'
            % la pente de la sortie reste entre lo et up : sur un pas Ts,
            % la sortie bouge d'au plus up Ts et d'au moins lo Ts
            p = struct('Script', sprintf(['function y = fcn(up, u, lo)\n' ...
                'persistent yAvant tAvant\n[t, Ts] = matlibre_sl_instant();\n' ...
                'if isempty(yAvant)\n    y = double(u);\n    yAvant = y;\n    tAvant = t;\n' ...
                '    return\nend\nif ~(Ts > 0 && isfinite(Ts))\n    Ts = t - tAvant;\nend\n' ...
                'tAvant = t;\nd = min(max(double(u) - yAvant, double(lo) .* Ts), ' ...
                'double(up) .* Ts);\ny = yAvant + d;\nyAvant = y;\n']), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'sampletimemath'
            w = texteValeur(p.weightValue);
            formules = struct('plus', ['u + ' w ' .* Ts'], 'moins', ['u - ' w ' .* Ts'], ...
                              'fois', ['u .* (' w ' .* Ts)'], ...
                              'divise', ['u ./ (' w ' .* Ts)'], 'ts', [w ' .* Ts'], ...
                              'inverse', [w ' ./ Ts']);
            cles = {'plus', 'moins', 'fois', 'divise', 'ts', 'inverse'};
            cle = cles{strcmp(p.TsampMathOp, {'+', '-', '*', '/', 'Ts Only', '1/Ts Only'})};
            % l'entrée ne donne que sa période à Ts Only et 1/Ts Only
            p = struct('Script', sprintf(['function y = fcn(u)\n' ...
                '[~, Ts] = matlibre_sl_instant();\nif ~isfinite(Ts)\n    Ts = 0;\nend\n' ...
                'y = %s;\n'], formules.(cle)), 'SampleTime', -1);
            type = 'matlabfunction';
        case 'minmaxrunningresettable'
            p = struct('Script', sprintf(['function y = fcn(u, R)\npersistent m\n' ...
                'if isempty(m) || any(R(:) ~= 0)\n    m = zeros(size(u)) + %s;\nend\n' ...
                'y = %s(double(u), m);\nm = y;\n'], texteValeur(p.vinit), char(p.Function)), ...
                'SampleTime', -1);
            type = 'matlabfunction';
        case 'firstorderhold'
            Ts = double(p.Ts);
            if ~(isscalar(Ts) && Ts > 0)
                error('Simulink:blocks:FirstOrderHoldSampleTime', ...
                      'La periode Ts de ''%s'' doit etre positive.', chemin);
            end
            % continu : il se calcule à chaque pas majeur, entre les
            % échantillons qu'il prend toutes les Ts
            p = struct('Script', sprintf(['function y = fcn(u)\n' ...
                'persistent uk up tk\n[t, ~] = matlibre_sl_instant();\nTs = %s;\n' ...
                'instant = floor(t / Ts + 1e-9) * Ts;\nif isempty(uk)\n' ...
                '    uk = double(u);\n    up = uk;\n    tk = instant;\n' ...
                'elseif instant > tk + 1e-9 * Ts\n    up = uk;\n    uk = double(u);\n' ...
                '    tk = instant;\nend\ny = uk + (uk - up) / Ts * (t - tk);\n'], ...
                mat2str(Ts, 17)), 'SampleTime', 0);
            type = 'matlabfunction';
        case 'repeatingsequenceinterpolated'
            p = struct('Script', scriptSequenceInterpolee(p, chemin), 'SampleTime', p.tsamp);
            type = 'matlabfunction';
        case 'signaleditor'
            p = struct('Script', scriptScenario(p, chemin), 'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'fromspreadsheet'
            [temps, valeurs] = lireTableur(char(p.FileName), char(p.Range), chemin);
            apres = struct('Linear_extrapolation', 'Extrapolation', ...
                           'Hold_last_value', 'Holding final value', ...
                           'Ground_value', 'Setting to zero');
            p = struct('VariableName', char(p.FileName), ...
                       'Interpolate', char(ifelse(strcmp(p.InterpolationWithinTimeRange, ...
                                                        'Zero order hold'), 'off', 'on')), ...
                       'OutputAfterFinalValue', ...
                       apres.(strrep(p.ExtrapolationAfterLastDataPoint, ' ', '_')), ...
                       'SampleTime', p.SampleTime, 'ZeroCross', 'on', ...
                       'Donnees', struct('temps', temps, 'valeurs', valeurs));
            type = 'fromworkspace';
        case 'bustovector'
            p = struct('Script', sprintf('function y = fcn(u)\ny = u(:);\n'), 'SampleTime', -1);
            type = 'matlabfunction';
        case {'simulinkpsconverter', 'pssimulinkconverter'}
            % un signal physique est un double : le convertisseur y ramène
            % son entrée, comme dans Simscape
            p = struct('OutDataTypeStr', 'double', 'ConvertRealWorld', 'Real World Value (RWV)', ...
                       'RndMeth', 'Zero', 'SaturateOnIntegerOverflow', 'off', 'SampleTime', -1);
            type = 'datatypeconversion';
        case {'complextorealimag', 'complextomagnitudeangle'}
            % les deux parties d'un complexe, ou l'une d'elles
            if strcmp(type, 'complextorealimag')
                f = {'real(u)', 'imag(u)'};
                choix = {'Real and imag', 'Real', 'Imag'};
            else
                f = {'abs(u)', 'angle(u)'};
                choix = {'Magnitude and angle', 'Magnitude', 'Angle'};
            end
            switch find(strcmp(p.Output, choix))
                case 1
                    texte = sprintf('function [a, b] = fcn(u)\na = %s;\nb = %s;\n', f{:});
                case 2
                    texte = sprintf('function y = fcn(u)\ny = %s;\n', f{1});
                otherwise
                    texte = sprintf('function y = fcn(u)\ny = %s;\n', f{2});
            end
            p = struct('Script', texte, 'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case {'realimagtocomplex', 'magnitudeangletocomplex'}
            % un complexe de ses deux parties ; une partie qui manque est
            % ConstantPart
            constante = mat2str(double(p.ConstantPart), 17);
            if strcmp(type, 'realimagtocomplex')
                forme = 'y = complex(a + 0 * b, b + 0 * a);';
                choix = {'Real and imag', 'Real', 'Imag'};
            else
                forme = 'y = complex(a .* cos(b), a .* sin(b));';
                choix = {'Magnitude and angle', 'Magnitude', 'Angle'};
            end
            switch find(strcmp(p.Input, choix))
                case 1
                    texte = sprintf('function y = fcn(a, b)\n%s\n', forme);
                case 2
                    texte = sprintf('function y = fcn(a)\nb = %s;\n%s\n', constante, forme);
                otherwise
                    texte = sprintf('function y = fcn(b)\na = %s;\n%s\n', constante, forme);
            end
            p = struct('Script', texte, 'SampleTime', p.SampleTime);
            type = 'matlabfunction';
        case 'environmentcontroller'
            % en simulation, l'entrée Sim ; Coder ne sert qu'au code produit
            p = struct('Script', sprintf('function y = fcn(Sim, Coder)\ny = Sim;\n'), ...
                       'SampleTime', -1);
            type = 'matlabfunction';
        case {'checkstaticrange', 'checkstaticlowerbound', 'checkstaticupperbound', ...
              'checkstaticgap', 'checkdynamicrange', 'checkdynamiclowerbound', ...
              'checkdynamicupperbound', 'checkdynamicgap'}
            p = verification(type, p, chemin);
            type = 'assertion';
        case 'pidcontroller'
            if strcmp(p.TimeDomain, 'Discrete-time')
                p = struct('Script', scriptPIDDiscret(p, chemin), 'SampleTime', p.SampleTime);
                type = 'matlabfunction';
            end
        case 'signalspecification'
            % un passage qui vérifie ses dimensions et son type
            p = struct('ConversionOutput', 'Signal copy', 'NombreDePorts', 1, ...
                       'OutDataTypeStr', 'Inherit: auto', ...
                       'DimensionsVerifiees', double(p.Dimensions), ...
                       'TypeVerifie', char(p.OutDataTypeStr), ...
                       'ComplexiteVerifiee', char(p.SignalType));
            type = 'signalconversion';
    end
end

% Le signal d'un fichier MAT, comme l'écrit To File : une matrice dont la
% première ligne porte les instants et chaque autre ligne un élément du
% signal ; ou une timeseries.
function [temps, valeurs] = lireFichierSignal(fichier, chemin)
    chemin_fichier = fichier;
    if exist(chemin_fichier, 'file') ~= 2
        [~, ~, extension] = fileparts(fichier);
        if isempty(extension) && exist([fichier '.mat'], 'file') == 2
            chemin_fichier = [fichier '.mat'];
        else
            error('Simulink:blocks:FromFileNotFound', ...
                  'Le bloc From File ''%s'' lit ''%s'', qui n''existe pas.', chemin, fichier);
        end
    end
    try
        contenu = load(chemin_fichier);
    catch err
        error('Simulink:blocks:FromFileInvalidData', ...
              'Le bloc From File ''%s'' ne sait pas lire ''%s'' : %s', chemin, fichier, ...
              err.message);
    end
    noms = fieldnames(contenu);
    if isempty(noms)
        error('Simulink:blocks:FromFileInvalidData', ...
              'Le fichier ''%s'' que lit le bloc From File ''%s'' est vide.', fichier, chemin);
    end
    donnees = contenu.(noms{1});
    if isa(donnees, 'timeseries')
        [temps, valeurs] = matlibre_sl_serie(donnees);
        return
    end
    if ~(isnumeric(donnees) && ismatrix(donnees) && size(donnees, 1) >= 2 && ...
         size(donnees, 2) >= 1)
        error('Simulink:blocks:FromFileInvalidData', ...
              ['La variable ''%s'' du fichier ''%s'' que lit le bloc From File ''%s'' ' ...
               'doit etre une matrice : les instants sur la premiere ligne, un element du ' ...
               'signal par ligne suivante — ce qu''ecrit To File —, ou une timeseries.'], ...
              noms{1}, fichier, chemin);
    end
    temps = double(donnees(1, :)).';
    if any(diff(temps) < 0)
        error('Simulink:blocks:FromFileInvalidData', ...
              'Les instants du fichier ''%s'' que lit le bloc From File ''%s'' decroissent.', ...
              fichier, chemin);
    end
    valeurs = double(donnees(2:end, :)).';
end

% Assignment : y vaut Y0 — ou des zéros de la taille donnée —, puis ses
% éléments aux indices voulus reçoivent ceux de U. Il s'écrit en une
% fonction, que le bloc MATLAB Function calcule.
function script = scriptAffectation(p, chemin)
    n = double(p.NumberOfDimensions);
    if ~(isscalar(n) && any(n == [1 2]))
        error('Simulink:blocks:AssignmentDimensions', ...
              ['Le bloc Assignment ''%s'' a %s dimension(s) : MatLibre affecte en une ou ' ...
               'deux dimensions.'], chemin, mat2str(n));
    end
    options = celluleDe(p.IndexOptionArray);
    indices = celluleDe(p.IndexParamArray);
    if numel(options) < n
        error('Simulink:blocks:AssignmentIndexOptions', ...
              ['Le bloc Assignment ''%s'' a %d dimension(s) et %d option(s) d''indice ' ...
               '(IndexOptionArray) : une par dimension.'], chemin, n, numel(options));
    end
    zero = double(strcmp(p.IndexMode, 'Zero-based'));
    parY0 = strcmp(p.OutputInitialize, 'Initialize using input port <Y0>');
    arguments_ = {};
    if parY0
        arguments_{end + 1} = 'y0';
    end
    arguments_{end + 1} = 'u';
    expressions = cell(1, n);
    for d = 1:n
        taille = sprintf('size(u, %d)', d);
        if n == 1
            taille = 'numel(u)';
        end
        switch options{d}
            case 'Assign all'
                expressions{d} = ':';
            case {'Index vector (dialog)', 'Starting index (dialog)'}
                if numel(indices) < d
                    error('Simulink:blocks:AssignmentIndexOptions', ...
                          'Le bloc Assignment ''%s'' ne donne pas d''indice pour la dimension %d.', ...
                          chemin, d);
                end
                v = indices{d};
                if ischar(v) || isstring(v)
                    v = matlibre_sl_expression(char(v), chemin, 'IndexParamArray');
                end
                v = double(v(:).') + zero;
                if any(v < 1) || any(v ~= round(v))
                    error('Simulink:blocks:AssignmentInvalidIndex', ...
                          ['Les indices %s de la dimension %d du bloc Assignment ''%s'' ne ' ...
                           'sont pas des entiers positifs (IndexMode %s).'], mat2str(v - zero), ...
                          d, chemin, p.IndexMode);
                end
                if strcmp(options{d}, 'Index vector (dialog)')
                    expressions{d} = mat2str(v);
                else
                    expressions{d} = sprintf('%d - 1 + (1:%s)', v(1), taille);
                end
            case {'Index vector (port)', 'Starting index (port)'}
                error('Simulink:blocks:AssignmentIndexOptions', ...
                      ['Le bloc Assignment ''%s'' prend ses indices par un port : MatLibre ' ...
                       'les veut dans le dialogue (''Index vector (dialog)'', ''Starting ' ...
                       'index (dialog)'') ou ''Assign all''.'], chemin);
            otherwise
                error('Simulink:blocks:AssignmentIndexOptions', ...
                      ['L''option d''indice ''%s'' du bloc Assignment ''%s'' est inconnue : ' ...
                       '''Assign all'', ''Index vector (dialog)'', ''Index vector (port)'', ' ...
                       '''Starting index (dialog)'' ou ''Starting index (port)''.'], ...
                      options{d}, chemin);
        end
    end
    if parY0
        depart = 'y = y0;';
    else
        tailles = celluleDe(p.OutputSizeArray);
        dims = zeros(1, max(2, n));
        dims(:) = 1;
        for d = 1:min(n, numel(tailles))
            v = tailles{d};
            if ischar(v) || isstring(v)
                v = matlibre_sl_expression(char(v), chemin, 'OutputSizeArray');
            end
            dims(d) = double(v);
        end
        if n == 1
            dims = [dims(1) 1];
        end
        depart = sprintf('y = zeros(%s);', mat2str(dims));
    end
    message = strrep(sprintf(['Le bloc Assignment ''%s'' affecte hors de sa sortie, ou ' ...
                              'des elements en nombre different de ceux de son entree U'], ...
                             chemin), '''', '''''');
    % chaque indice est vérifié : MATLAB agrandirait la sortie, Simulink
    % refuse un indice qui en sort
    controles = '';
    noms = cell(1, n);
    for d = 1:n
        if strcmp(expressions{d}, ':')
            noms{d} = ':';
            continue
        end
        noms{d} = sprintf('I%d', d);
        borne = sprintf('size(y, %d)', d);
        if n == 1
            borne = 'numel(y)';
        end
        controles = [controles, sprintf(['I%d = %s;\nif any(I%d < 1) || any(I%d > %s)\n' ...
            '    error(''Simulink:blocks:AssignmentOutOfRange'', ''%s.'');\nend\n'], ...
            d, expressions{d}, d, d, borne, message)]; %#ok<AGROW>
    end
    script = sprintf(['function y = fcn(%s)\n%s\n%stry\n    y(%s) = u;\ncatch\n' ...
                      '    error(''Simulink:blocks:AssignmentOutOfRange'', ''%s.'');\nend\n'], ...
                     strjoin(arguments_, ', '), depart, controles, strjoin(noms, ', '), message);
end

% Combinatorial Logic : la ligne de la table de vérité que désignent ses
% entrées booléennes, la première étant le bit de poids fort.
function script = scriptLogiqueCombinatoire(p, chemin)
    table = double(p.TruthTable);
    lignes = size(table, 1);
    if lignes < 2 || abs(log2(lignes) - round(log2(lignes))) > 0
        error('Simulink:blocks:CombinatorialLogicRows', ...
              ['La table de verite du bloc ''%s'' a %d ligne(s) : il en faut une puissance ' ...
               'de deux, une par combinaison des entrees.'], chemin, lignes);
    end
    message = strrep(sprintf(['Le bloc Combinatorial Logic ''%s'' recoit %%d entree(s), et ' ...
                              'sa table de verite a %d ligne(s) : il en faut 2^%%d.'], ...
                             chemin, lignes), '''', '''''');
    script = sprintf(['function y = fcn(u)\nT = %s;\nn = numel(u);\n' ...
                      'if size(T, 1) ~= 2^n\n' ...
                      '    error(''Simulink:blocks:CombinatorialLogicRows'', ''%s'', n, n);\n' ...
                      'end\nk = 1 + sum((u(:).'' ~= 0) .* 2.^(n - 1:-1:0));\ny = T(k, :).'';\n'], ...
                     mat2str(table), message);
end

% Une table à N dimensions : ses points de rupture, vérifiés, et son
% interpolation, confiée à MATLIBRE_SL_TABLEND.
function script = scriptTableND(p, n, chemin)
    T = double(p.TableData);
    tailles = size(T);
    tailles(end + 1:n) = 1;
    points = cell(1, n);
    for d = 1:n
        if d == 1
            b = p.BreakpointsData;
        else
            b = p.(sprintf('BreakpointsForDimension%d', d));
        end
        b = double(b(:).');
        if any(diff(b) <= 0)
            error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                  ['Les points de rupture de la dimension %d de la table ''%s'' ne ' ...
                   'croissent pas strictement.'], d, chemin);
        end
        if numel(b) ~= tailles(d)
            error('Simulink:blocks:LookupTableSizeMismatch', ...
                  ['La table ''%s'' a %d element(s) sur sa dimension %d, et %d point(s) ' ...
                   'de rupture pour elle.'], chemin, tailles(d), d, numel(b));
        end
        points{d} = mat2str(b, 17);
    end
    if numel(tailles) > n && any(tailles(n + 1:end) > 1)
        error('Simulink:blocks:LookupTableSizeMismatch', ...
              'La table ''%s'' a plus de %d dimensions.', chemin, n);
    end
    arguments_ = arrayfun(@(d) sprintf('u%d', d), 1:n, 'UniformOutput', false);
    script = sprintf(['function y = fcn(%s)\nT = reshape(%s, %s);\nB = {%s};\n' ...
                      'y = matlibre_sl_tablend(T, B, {%s}, ''%s'', ''%s'');\n'], ...
                     strjoin(arguments_, ', '), mat2str(T(:).', 17), mat2str(tailles(1:n)), ...
                     strjoin(points, ', '), strjoin(arguments_, ', '), char(p.InterpMethod), ...
                     char(p.ExtrapMethod));
end

% Une table directe à N dimensions : ses entrées, à partir de 0, ramenées
% dans les bornes, désignent l'élément rendu.
function script = scriptTableDirecte(p, n, chemin)
    T = double(p.Table);
    tailles = size(T);
    tailles(end + 1:n) = 1;
    if numel(tailles) > n && any(tailles(n + 1:end) > 1)
        error('Simulink:blocks:LookupTableSizeMismatch', ...
              'La table directe ''%s'' a plus de %d dimensions.', chemin, n);
    end
    arguments_ = arrayfun(@(d) sprintf('u%d', d), 1:n, 'UniformOutput', false);
    indices = arrayfun(@(d) sprintf('min(max(floor(double(u%d(:))), 0), %d) + 1', d, ...
                                    tailles(d) - 1), 1:n, 'UniformOutput', false);
    script = sprintf(['function y = fcn(%s)\nT = reshape(%s, %s);\n' ...
                      'y = T(sub2ind(%s, %s));\n'], strjoin(arguments_, ', '), ...
                     mat2str(T(:).', 17), mat2str(tailles(1:n)), mat2str(tailles(1:n)), ...
                     strjoin(indices, ', '));
end

% Signal Editor : chaque signal du scénario, interpolé à l'instant — ou
% tenu, pour une timeseries en tenue d'ordre zéro —, et tenu hors de ses
% dates.
function script = scriptScenario(p, chemin)
    signaux = matlibre_sl_scenario(char(p.FileName), char(p.ActiveScenario), chemin);
    n = numel(signaux);
    sorties = arrayfun(@(q) sprintf('y%d', q), 1:n, 'UniformOutput', false);
    L = {sprintf('function [%s] = fcn()', strjoin(sorties, ', ')), ...
         '[t, ~] = matlibre_sl_instant();'};
    for q = 1:n
        tk = signaux(q).temps;
        vk = signaux(q).valeurs;
        parties = {real(vk)};
        if ~isreal(vk)
            parties{2} = imag(vk);
        end
        texte = cell(1, numel(parties));
        for i = 1:numel(parties)
            if numel(tk) == 1
                texte{i} = mat2str(parties{i}(:), 17);
            else
                texte{i} = sprintf('interp1(%s, %s, min(max(t, %s), %s), ''%s'').''', ...
                                   mat2str(tk, 17), mat2str(parties{i}, 17), ...
                                   mat2str(tk(1), 17), mat2str(tk(end), 17), ...
                                   signaux(q).methode);
            end
        end
        if numel(parties) == 1
            L{end + 1} = sprintf('y%d = %s;', q, texte{1}); %#ok<AGROW>
        else
            L{end + 1} = sprintf('y%d = complex(%s, %s);', q, texte{:}); %#ok<AGROW>
        end
    end
    script = [strjoin(L, sprintf('\n')), sprintf('\n')];
end

function v = ifelse(condition, oui, non)
    if condition
        v = oui;
    else
        v = non;
    end
end

% Repeating Sequence Interpolated : la table (TimeValues, OutValues) lue au
% temps pris modulo la dernière date, par la méthode LookUpMeth.
function script = scriptSequenceInterpolee(p, chemin)
    t = double(p.TimeValues(:));
    v = double(p.OutValues(:));
    if numel(t) ~= numel(v) || numel(t) < 2
        error('Simulink:blocks:RepeatingSequenceSize', ...
              ['''%s'' porte %d date(s) et %d valeur(s) : il en faut autant, au moins ' ...
               'deux.'], chemin, numel(t), numel(v));
    end
    if any(diff(t) < 0) || t(end) <= 0
        error('Simulink:blocks:RepeatingSequenceTimes', ...
              ['Les dates de ''%s'' doivent croitre, et la derniere, qui fait la ' ...
               'periode, etre positive.'], chemin);
    end
    methodes = struct('Interpolation_Extrapolation', 'linear', ...
                      'Interpolation_Use_End_Values', 'linear', ...
                      'Use_Input_Nearest', 'nearest', 'Use_Input_Below', 'previous', ...
                      'Use_Input_Above', 'next');
    cle = strrep(strrep(char(p.LookUpMeth), '-', '_'), ' ', '_');
    % des dates répétées marquent un saut : on garde la dernière valeur
    [tu, derniers] = unique(t, 'last');
    script = sprintf(['function y = fcn()\n[t, ~] = matlibre_sl_instant();\n' ...
                      'td = %s;\nvd = %s;\nq = min(max(mod(t, %s), td(1)), td(end));\n' ...
                      'y = interp1(td, vd, q, ''%s'');\n'], mat2str(tu, 17), ...
                     mat2str(v(derniers), 17), mat2str(t(end), 17), methodes.(cle));
end

% Un signal dans un fichier texte de tableur : la première colonne donne
% les instants, les suivantes les éléments du signal.
function [temps, valeurs] = lireTableur(fichier, plage, chemin)
    if exist(fichier, 'file') ~= 2
        error('Simulink:blocks:FromSpreadsheetNotFound', ...
              'Le fichier ''%s'' que lit ''%s'' est introuvable.', fichier, chemin);
    end
    try
        if isempty(plage)
            M = readmatrix(fichier);
        else
            M = readmatrix(fichier, 'Range', plage);
        end
    catch err
        error('Simulink:blocks:FromSpreadsheetFormat', ...
              ['''%s'' ne sait pas lire ''%s'' : MatLibre lit les tableurs en texte ' ...
               '(CSV, TXT). %s'], chemin, fichier, err.message);
    end
    M = M(~all(isnan(M), 2), :);
    if size(M, 2) < 2 || size(M, 1) < 1 || any(isnan(M(:)))
        error('Simulink:blocks:FromSpreadsheetInvalidData', ...
              ['''%s'' attend dans ''%s'' une colonne d''instants suivie d''au moins ' ...
               'une colonne de valeurs, toutes numeriques.'], chemin, fichier);
    end
    temps = M(:, 1);
    if any(diff(temps) < 0)
        error('Simulink:blocks:FromSpreadsheetInvalidData', ...
              'Les instants lus par ''%s'' dans ''%s'' doivent croitre.', chemin, fichier);
    end
    valeurs = M(:, 2:end);
end

% Les gains du PID continu tel que le calcul les lit, un par élément : les
% parties que Controller écarte valent zéro ; la forme idéale multiplie
% I et D par P. Sans dérivée, N vaut zéro et le filtre ne bouge pas.
function [P, I, D, N] = gainsPID(p, w, ch)
    type = upper(char(p.Controller));
    P = etendre(p.P, w, ch, 'P');
    I = etendre(p.I, w, ch, 'I');
    D = etendre(p.D, w, ch, 'D');
    N = etendre(p.N, w, ch, 'N');
    if strcmp(p.Form, 'Ideal') && any(type == 'P')
        I = P .* I;
        D = P .* D;
    end
    if ~any(type == 'P')
        P = zeros(w, 1);
    end
    if ~any(type == 'I')
        I = zeros(w, 1);
    end
    if ~any(type == 'D')
        D = zeros(w, 1);
        N = zeros(w, 1);
    elseif any(N <= 0)
        error('Simulink:blocks:PIDFilterCoefficientNotPositive', ...
              ['Le bloc ''%s'' demande un coefficient de filtre N ' ...
               'strictement positif : une derivee non filtree ne ' ...
               's''integre pas.'], ch);
    end
end

% Le PID discret : l'intégrale et le filtre de la dérivée par la méthode
% qu'on leur choisit (Forward Euler, Backward Euler, Trapezoidal), la
% sortie bornée, l'anti-emballement par recalcul (Kb) ou par blocage, la
% remise par l'entrée Reset, les conditions initiales internes ou
% externes (I0, D0). Le pas est la période du bloc, que donne
% MATLIBRE_SL_INSTANT.
function script = scriptPIDDiscret(p, chemin)
    type = upper(char(p.Controller));
    aP = any(type == 'P');
    aI = any(type == 'I');
    aD = any(type == 'D');
    P = double(p.P);
    I = double(p.I);
    D = double(p.D);
    N = double(p.N);
    if strcmp(p.Form, 'Ideal') && aP
        I = P .* I;
        D = P .* D;
    end
    filtre = strcmp(p.UseFilter, 'on');
    if aD && filtre && any(N(:) <= 0)
        error('Simulink:blocks:PIDFilterCoefficientNotPositive', ...
              ['Le bloc ''%s'' demande un coefficient de filtre N strictement ' ...
               'positif.'], chemin);
    end
    Ts = double(p.SampleTime);
    if ~(Ts(1) == -1 || Ts(1) > 0)
        error('Simulink:SampleTime:DiscreteBlockContinuous', ...
              ['Le PID discret ''%s'' a une periode nulle : donnez-lui une periode ' ...
               'positive, ou -1 pour l''heriter.'], chemin);
    end
    methodes = {'Forward Euler', 'Backward Euler', 'Trapezoidal'};
    mI = find(strcmp(p.IntegratorMethod, methodes));
    mD = find(strcmp(p.FilterMethod, methodes));
    remise = find(strcmp(p.ExternalReset, {'rising', 'falling', 'either', 'level'}));
    externe = strcmp(p.InitialConditionSource, 'external');
    entrees = {'u'};
    if ~isempty(remise)
        entrees{end + 1} = 'r';
    end
    ciI = texteValeur(p.InitialConditionForIntegrator);
    ciD = texteValeur(p.InitialConditionForFilter);
    if externe && aI
        entrees{end + 1} = 'I0';
        ciI = 'double(I0)';
    end
    if externe && aD && filtre
        entrees{end + 1} = 'D0';
        ciD = 'double(D0)';
    end
    borne = strcmp(p.LimitOutput, 'on');
    haut = double(p.UpperSaturationLimit);
    bas = double(p.LowerSaturationLimit);
    if borne && any(bas(:) > haut(:))
        error('Simulink:blocks:PIDSaturationLimits', ...
              'La borne basse de la sortie de ''%s'' depasse sa borne haute.', chemin);
    end
    anti = 0;
    if borne
        anti = find(strcmp(p.AntiWindupMode, {'none', 'back-calculation', 'clamping'})) - 1;
    end
    L = {sprintf('function y = fcn(%s)', strjoin(entrees, ', ')), ...
         'persistent s f dAvant xAvant eAvant rAvant tAvant', ...
         '[t, Ts] = matlibre_sl_instant();', 'e = double(u);', ...
         'if isempty(s)', ...
         sprintf('    s = zeros(size(e)) + %s;', ciI), ...
         sprintf('    f = zeros(size(e)) + %s;', ciD), ...
         '    dAvant = zeros(size(e));', '    xAvant = zeros(size(e));', ...
         '    eAvant = e;', '    rAvant = [];', '    tAvant = t;', 'end', ...
         'if ~(Ts > 0 && isfinite(Ts))', '    Ts = t - tAvant;', 'end', 'tAvant = t;'};
    if ~isempty(remise)
        conditions = {'(ra < 0 & rr >= 0) | (ra == 0 & rr > 0)', ...
                      '(ra > 0 & rr <= 0) | (ra == 0 & rr < 0)', ...
                      ['(ra < 0 & rr >= 0) | (ra == 0 & rr ~= 0) | ' ...
                       '(ra > 0 & rr <= 0)'], ...
                      'rr ~= 0 | (ra ~= 0 & rr == 0)'};
        L = [L, {'rr = double(r) + zeros(size(e));', 'ra = rAvant;', ...
                 'if isempty(ra)', '    ra = rr;   % pas de front au premier instant', ...
                 'end', sprintf('remis = %s;', conditions{remise}), 'rAvant = rr;', ...
                 'if any(remis(:))', sprintf('    base = zeros(size(e)) + %s;', ciI), ...
                 '    s(remis) = base(remis);', ...
                 sprintf('    base = zeros(size(e)) + %s;', ciD), ...
                 '    f(remis) = base(remis);', '    dAvant(remis) = 0;', ...
                 '    xAvant(remis) = 0;', 'end'}];
    end
    % les trois parties
    if aP
        L{end + 1} = sprintf('yP = %s .* e;', texteValeur(P));
    else
        L{end + 1} = 'yP = zeros(size(e));';
    end
    if aI
        L{end + 1} = sprintf('iE = %s .* e;', texteValeur(I));
        switch mI
            case 1
                L = [L, {'h = 0;', 'base = s;'}];
            case 2
                L = [L, {'h = Ts;', 'base = s;'}];
            otherwise
                L = [L, {'h = Ts / 2;', 'base = s + Ts / 2 .* xAvant;'}];
        end
    else
        L = [L, {'iE = zeros(size(e));', 'h = 0;', 'base = zeros(size(e));'}];
    end
    if aD && filtre
        DN = {texteValeur(D), texteValeur(N)};
        switch mD
            case 1
                L{end + 1} = sprintf('yD = %s .* (%s .* e - f);', DN{2}, DN{1});
            case 2
                L{end + 1} = sprintf('yD = %s .* (%s .* e - f) ./ (1 + %s .* Ts);', ...
                                     DN{2}, DN{1}, DN{2});
            otherwise
                L{end + 1} = sprintf(['yD = %s .* (%s .* e - f - Ts / 2 .* dAvant) ./ ' ...
                                      '(1 + %s .* Ts / 2);'], DN{2}, DN{1}, DN{2});
        end
    elseif aD
        L = [L, {'if Ts > 0', sprintf('    yD = %s .* (e - eAvant) ./ Ts;', texteValeur(D)), ...
                 'else', '    yD = zeros(size(e));', 'end'}];
    else
        L{end + 1} = 'yD = zeros(size(e));';
    end
    L{end + 1} = 'y = yP + base + h .* iE + yD;';
    L{end + 1} = 'x = iE;';
    if borne
        L = [L, {sprintf('haut = zeros(size(e)) + %s;', texteValeur(haut)), ...
                 sprintf('bas = zeros(size(e)) + %s;', texteValeur(bas))}];
        switch anti
            case 1   % recalcul : l'intégrale reçoit Kb (sortie bornée - sortie)
                L = [L, {sprintf('kb = zeros(size(e)) + %s;', texteValeur(p.Kb)), ...
                         'dessus = y > haut;', 'dessous = y < bas;', ...
                         'y(dessus) = (y(dessus) + h .* kb(dessus) .* haut(dessus)) ./ (1 + h .* kb(dessus));', ...
                         'y(dessous) = (y(dessous) + h .* kb(dessous) .* bas(dessous)) ./ (1 + h .* kb(dessous));', ...
                         'yb = min(max(y, bas), haut);', 'x = iE + kb .* (yb - y);'}];
            case 2   % blocage : l'intégrale s'arrête quand elle pousse la sortie hors des bornes
                L = [L, {'yb = min(max(y, bas), haut);', ...
                         'bloque = (y ~= yb) & (sign(iE) == sign(y - yb));', ...
                         'x(bloque) = 0;', 'y = y - h .* (iE - x);', ...
                         'yb = min(max(y, bas), haut);'}];
            otherwise
                L{end + 1} = 'yb = min(max(y, bas), haut);';
        end
    else
        L{end + 1} = 'yb = y;';
    end
    % les mises à jour
    if aI
        switch mI
            case 3
                L = [L, {'s = s + Ts / 2 .* (x + xAvant);', 'xAvant = x;'}];
            otherwise
                L{end + 1} = 's = s + Ts .* x;';
        end
    end
    if aD && filtre
        switch mD
            case 3
                L = [L, {'f = f + Ts / 2 .* (yD + dAvant);', 'dAvant = yD;'}];
            otherwise
                L{end + 1} = 'f = f + Ts .* yD;';
        end
    end
    L = [L, {'eAvant = e;', 'y = yb;'}];
    script = [strjoin(L, sprintf('\n')), sprintf('\n')];
end

% La méthode du Discrete-Time Integrator : 1 Forward Euler, 2 Backward
% Euler, 3 trapèzes ; CUMUL vaut vrai pour « Accumulation », qui ne
% multiplie pas par la période.
function [methode, cumul] = methodeDTI(texte)
    texte = char(texte);
    cumul = strncmp(texte, 'Accumulation', 12);
    if ~isempty(strfind(texte, 'Backward'))
        methode = 2;
    elseif ~isempty(strfind(texte, 'Trapezoidal'))
        methode = 3;
    else
        methode = 1;
    end
end

% Un texte écrit dans le code d'une fonction, entre apostrophes.
function t = litteral(texte)
    t = ['''' strrep(texte, '''', '''''') ''''];
end

% Une valeur écrite dans le code d'une fonction : un vecteur en colonne,
% comme les signaux.
function t = texteValeur(v)
    v = double(v);
    if isvector(v) && ~isscalar(v)
        v = v(:);
    end
    t = mat2str(v, 17);
end

% Les détections de franchissement : l'entrée comparée à zéro, et ce même
% test au pas d'avant, dont vinit donne la valeur au départ.
function script = scriptDetection(type, p)
    tests = struct('detectrisepositive', 'u > 0', 'detectrisenonnegative', 'u >= 0', ...
                   'detectfallnegative', 'u < 0', 'detectfallnonpositive', 'u <= 0');
    script = sprintf(['function y = fcn(u)\npersistent avant\nif isempty(avant)\n' ...
                      '    avant = (zeros(size(u)) + %s) ~= 0;\nend\nvrai = %s;\n' ...
                      'y = vrai & ~avant;\navant = vrai;\n'], texteValeur(p.vinit), tests.(type));
end

% Les opérations bit à bit, sur des entiers : le type des entrées est
% vérifié avec les autres types (EntiersSeuls).
function script = scriptBits(type, p, chemin)
    switch type
        case 'bitwiseoperator'
            op = char(p.logicop);
            masque = strcmp(p.UseBitMask, 'on');
            if strcmp(op, 'NOT')
                script = sprintf('function y = fcn(u)\ny = bitcmp(u);\n');
                return
            end
            base = struct('AND', 'bitand', 'OR', 'bitor', 'NAND', 'bitand', 'NOR', 'bitor', ...
                          'XOR', 'bitxor');
            if masque
                m = double(p.BitMask);
                if any(m(:) < 0 | m(:) ~= round(m(:)))
                    error('Simulink:blocks:BitwiseOperatorMask', ...
                          'Le masque du bloc ''%s'' doit etre un entier positif ou nul.', chemin);
                end
                corps = sprintf('y = %s(u, cast(%s, ''like'', u));\n', base.(op), texteValeur(m));
                entrees = 'u';
            else
                n = double(p.NumInputPorts);
                if ~(isscalar(n) && n >= 2 && n == round(n))
                    error('Simulink:blocks:BitwiseOperatorInputs', ...
                          ['Sans masque, le bloc ''%s'' opere entre ses entrees : il lui en ' ...
                           'faut au moins deux, pas %s.'], chemin, mat2str(n));
                end
                noms = arrayfun(@(j) sprintf('u%d', j), 1:n, 'UniformOutput', false);
                entrees = strjoin(noms, ', ');
                corps = sprintf('y = u1;\n');
                for j = 2:n
                    corps = [corps, sprintf('y = %s(y, u%d);\n', base.(op), j)]; %#ok<AGROW>
                end
            end
            if any(strcmp(op, {'NAND', 'NOR'}))
                corps = [corps, sprintf('y = bitcmp(y);\n')];
            end
            script = sprintf('function y = fcn(%s)\n%s', entrees, corps);
        case {'bitset', 'bitclear'}
            rang = double(p.iBit);
            if ~(isscalar(rang) && rang >= 0 && rang == round(rang) && rang < 32)
                error('Simulink:blocks:BitIndex', ...
                      ['Le bit %s du bloc ''%s'' n''existe pas : les bits se comptent de 0 ' ...
                       'a la largeur du type moins un.'], mat2str(rang), chemin);
            end
            script = sprintf(['function y = fcn(u)\nif %d >= 8 * numel(typecast(u(1), ''uint8''))\n' ...
                              '    error(''Simulink:blocks:BitIndex'', ''%%s'', [%s class(u) ''.'']);\n' ...
                              'end\ny = bitset(u, %d, %d);\n'], rang, ...
                             litteral(sprintf('Le bit %d du bloc ''%s'' depasse la largeur d''un ', ...
                                              rang, chemin)), rang + 1, strcmp(type, 'bitset'));
        case 'shiftarithmetic'
            n = double(p.BitShiftNumber);
            if ~(all(n(:) == round(n(:))))
                error('Simulink:blocks:ShiftArithmeticNumber', ...
                      'Le decalage du bloc ''%s'' doit etre un nombre entier de bits.', chemin);
            end
            if double(p.BinPtShiftNumber) ~= 0
                error('Simulink:blocks:ShiftArithmeticBinaryPoint', ...
                      ['Le bloc ''%s'' deplace la virgule binaire : MatLibre n''a pas de ' ...
                       'types a virgule fixe, BinPtShiftNumber doit valoir 0.'], chemin);
            end
            switch p.BitShiftDirection
                case 'Left'
                    decalage = texteValeur(abs(n));
                case 'Right'
                    decalage = ['-' texteValeur(abs(n))];
                otherwise
                    decalage = texteValeur(n);   % positif à gauche, négatif à droite
            end
            % à droite, un entier signé garde son signe : la division par
            % une puissance de deux arrondie vers moins l'infini
            script = sprintf(['function y = fcn(u)\nd = %s + zeros(size(u));\ny = u;\n' ...
                              'g = d > 0;\ny(g) = bitshift(u(g), d(g));\n' ...
                              'r = d < 0;\ny(r) = cast(floor(double(u(r)) ./ 2 .^ -d(r)), ''like'', u);\n'], ...
                             decalage);
    end
end

% Lookup Table Dynamic : la table arrive par ses entrées xdat et ydat.
function script = scriptTableDynamique(p, chemin)
    methodes = struct('Interpolation_Extrapolation', 'linear'', ''extrap', ...
                      'Interpolation_Use_End_Values', 'linear', ...
                      'Use_Input_Nearest', 'nearest', 'Use_Input_Below', 'previous', ...
                      'Use_Input_Above', 'next');
    cle = strrep(strrep(char(p.LookUpMeth), '-', '_'), ' ', '_');
    borner = 'x = min(max(double(x), xdat(1)), xdat(end));\n';
    if strcmp(cle, 'Interpolation_Extrapolation')
        borner = 'x = double(x);\n';
    end
    % des entrées toutes nulles sont celles qui sondent les dimensions
    script = sprintf(['function y = fcn(x, xdat, ydat)\nxdat = double(xdat(:));\n' ...
                      'ydat = double(ydat(:));\n' ...
                      'if numel(xdat) ~= numel(ydat)\n' ...
                      '    error(''Simulink:blocks:LookupTableDynamicSize'', ''%%s'', ' ...
                      'sprintf(%s, numel(xdat), numel(ydat)));\nend\n' ...
                      'if all(xdat == 0) && all(ydat == 0)\n    y = zeros(size(x));\n    return\nend\n' ...
                      'if numel(xdat) < 2 || any(diff(xdat) <= 0)\n' ...
                      '    error(''Simulink:blocks:LookupTableDynamicBreakpoints'', ''%%s'', %s);\nend\n' ...
                      borner 'y = reshape(interp1(xdat, ydat, x(:), ''%s''), size(x));\n'], ...
                     litteral(strrep(sprintf(['Le bloc ''%s'' recoit %%d point(s) xdat et %%d ' ...
                                              'valeur(s) ydat : il en faut autant.'], chemin), ...
                                     '\', '\\')), ...
                     litteral(sprintf(['Les points xdat du bloc ''%s'' doivent etre au moins ' ...
                                       'deux et croitre strictement.'], chemin)), methodes.(cle));
end

% Prelookup : l'indice k, compté à partir de 0, de l'intervalle où tombe
% l'entrée, et la fraction f qu'elle y parcourt.
function script = scriptPrerecherche(p, chemin)
    b = double(p.BreakpointsData(:));
    if numel(b) < 2 || any(diff(b) <= 0)
        error('Simulink:blocks:PrelookupBreakpoints', ...
              ['Les points de rupture du bloc ''%s'' doivent etre au moins deux et ' ...
               'croitre strictement.'], chemin);
    end
    dernier = strcmp(p.UseLastBreakpoint, 'on');
    lineaire = strcmp(p.ExtrapMethod, 'Linear');
    sorties = 'k, f';
    if strcmp(p.OutputSelection, 'Index only')
        sorties = 'k';
    end
    script = sprintf(['function [%s] = fcn(u)\nb = %s;\nn = numel(b);\nx = double(u(:));\n' ...
                      'k = sum(x >= b.'', 2);\nk = min(max(k, 1), n - 1);\n' ...
                      'f = (x - b(k)) ./ (b(k + 1) - b(k));\n' ...
                      'if ~%d\n    f = min(max(f, 0), 1);\nend\n' ...
                      'if %d\n    fin = f >= 1 & x >= b(n);\n    k(fin) = n;\n    f(fin) = 0;\nend\n' ...
                      'k = reshape(uint32(k - 1), size(u));\nf = reshape(f, size(u));\n'], ...
                     sorties, mat2str(b, 17), lineaire, dernier && ~lineaire);
end

% Interpolation Using Prelookup : chaque dimension reçoit un indice k et une
% fraction f ; k + f est la place du point parmi les indices de la table.
function script = scriptInterpolationPrerecherche(p, chemin)
    n = double(p.NumberOfTableDimensions);
    if ~(isscalar(n) && any(n == 1:6))
        error('Simulink:blocks:LookupNDDimensions', ...
              ['La table ''%s'' est a %s dimensions : MatLibre interpole de une ' ...
               'a six dimensions.'], chemin, mat2str(n));
    end
    T = double(p.Table);
    if n == 1
        T = T(:);
    end
    tailles = size(T);
    tailles(end + 1:n) = 1;
    if numel(tailles) > n && any(tailles(n + 1:end) > 1)
        error('Simulink:blocks:LookupTableSizeMismatch', ...
              'La table ''%s'' a plus de %d dimensions.', chemin, n);
    end
    tailles = tailles(1:n);
    if any(tailles < 2)
        error('Simulink:blocks:LookupTableSizeMismatch', ...
              'La table ''%s'' doit avoir au moins deux valeurs sur chaque dimension.', chemin);
    end
    noms = cell(1, 2 * n);
    places = cell(1, n);
    points = cell(1, n);
    for d = 1:n
        noms{2 * d - 1} = sprintf('k%d', d);
        noms{2 * d} = sprintf('f%d', d);
        fraction = sprintf('double(f%d)', d);
        if strcmp(p.InterpMethod, 'Flat')
            fraction = '0';
        end
        if strcmp(p.ValidIndexMayReachLast, 'on')
            places{d} = sprintf('double(k%d) + %s', d, fraction);
        else
            places{d} = sprintf('min(double(k%d), %d) + %s', d, tailles(d) - 2, fraction);
        end
        points{d} = sprintf('0:%d', tailles(d) - 1);
    end
    methode = char(p.InterpMethod);
    if strcmp(methode, 'Flat')
        methode = 'Linear';   % la fraction est déjà nulle
    end
    script = sprintf(['function y = fcn(%s)\nT = reshape(%s, %s);\n' ...
                      'y = matlibre_sl_tablend(T, {%s}, {%s}, ''%s'', ''%s'');\n'], ...
                     strjoin(noms, ', '), mat2str(T(:).', 17), mat2str([tailles 1]), ...
                     strjoin(points, ', '), strjoin(places, ', '), methode, char(p.ExtrapMethod));
end

% Sine, Cosine : sin(2 pi u) et cos(2 pi u), lus dans une table d'un quart
% d'onde de NumDataPoints points, interpolée linéairement.
function script = scriptSinusCosinus(p, chemin)
    n = double(p.NumDataPoints);
    if ~(isscalar(n) && n >= 2 && n == round(n))
        error('Simulink:blocks:SineCosineTableSize', ...
              'La table du bloc ''%s'' doit avoir au moins deux points, pas %s.', ...
              chemin, mat2str(n));
    end
    table = sprintf('q = linspace(0, 0.25, %d);\ntab = sin(2 * pi * q);\n', n);
    sinus = 'quartOnde(mod(double(u), 1), q, tab)';
    cosinus = 'quartOnde(mod(double(u) + 0.25, 1), q, tab)';
    switch p.Formula
        case 'sin(2*pi*u)'
            script = sprintf('function y = fcn(u)\n%sy = %s;\n', table, sinus);
        case 'cos(2*pi*u)'
            script = sprintf('function y = fcn(u)\n%sy = %s;\n', table, cosinus);
        otherwise
            script = sprintf('function [s, c] = fcn(u)\n%ss = %s;\nc = %s;\n', table, sinus, cosinus);
    end
    script = [script, sprintf(['\nfunction y = quartOnde(v, q, tab)\n' ...
                               '%% le sinus sur une période, par symétrie du premier quart\n' ...
                               'y = zeros(size(v));\nfor e = 1:numel(v)\n    x = v(e);\n' ...
                               '    signe = 1;\n    if x >= 0.5\n        x = x - 0.5;\n' ...
                               '        signe = -1;\n    end\n    if x > 0.25\n' ...
                               '        x = 0.5 - x;\n    end\n' ...
                               '    y(e) = signe * interp1(q, tab, x);\nend\n'])];
end

% Discrete FIR Filter dont les états de départ ne sont pas nuls : les
% entrées passées, tenues dans une variable persistante.
function script = scriptRIF(b, etats, chemin)
    m = numel(b) - 1;
    if m == 0
        script = sprintf('function y = fcn(u)\ny = %s * u;\n', mat2str(b, 17));
        return
    end
    if ~(isscalar(etats) || numel(etats) == m)
        error('Simulink:blocks:DiscreteFirInitialStates', ...
              ['Le filtre ''%s'' a %d etat(s) : InitialStates en donne %d ; il en faut un, ' ...
               'ou un par etat.'], chemin, m, numel(etats));
    end
    script = sprintf(['function y = fcn(u)\npersistent z\nif isempty(z)\n' ...
                      '    z = %s + zeros(%d, numel(u));\nend\nb = %s;\nx = double(u(:)).'';\n' ...
                      'y = reshape(b(1) * x + b(2:end) * z, size(u));\nz = [x; z(1:end - 1, :)];\n'], ...
                     texteValeur(etats), m, mat2str(b, 17));
end

% Les transmittances discrètes de la bibliothèque, écrites en récurrence.
function script = scriptPremierOrdre(type, p)
    switch type
        case 'transferfcnfirstorder'   % (1 - p) z / (z - p)
            script = sprintf(['function y = fcn(u)\npersistent yAvant\nif isempty(yAvant)\n' ...
                              '    yAvant = %s + zeros(size(u));\nend\n' ...
                              'y = %s .* yAvant + (1 - %s) .* double(u);\nyAvant = y;\n'], ...
                             texteValeur(p.ICPrevOutput), texteValeur(p.PoleZ), texteValeur(p.PoleZ));
        case 'transferfcnleadorlag'    % K (z - zéro) / (z - pôle)
            script = sprintf(['function y = fcn(u)\npersistent yAvant uAvant\nif isempty(yAvant)\n' ...
                              '    yAvant = %s + zeros(size(u));\n    uAvant = %s + zeros(size(u));\nend\n' ...
                              'y = %s .* yAvant + %s .* (double(u) - %s .* uAvant);\n' ...
                              'yAvant = y;\nuAvant = double(u);\n'], ...
                             texteValeur(p.ICPrevOutput), texteValeur(p.ICPrevInput), ...
                             texteValeur(p.PoleZ), texteValeur(p.Gain), texteValeur(p.ZeroZ));
        otherwise                      % (z - zéro) / z
            script = sprintf(['function y = fcn(u)\npersistent uAvant\nif isempty(uAvant)\n' ...
                              '    uAvant = %s + zeros(size(u));\nend\n' ...
                              'y = double(u) - %s .* uAvant;\nuAvant = double(u);\n'], ...
                             texteValeur(p.ICPrevInput), texteValeur(p.ZeroZ));
    end
end

% Les blocs de vérification sont des assertions qui portent leur critère :
% son genre, ses bornes, et le nombre de signaux qu'il lit.
function q = verification(type, p, chemin)
    genres = {'checkstaticrange', 'checkstaticlowerbound', 'checkstaticupperbound', ...
              'checkstaticgap', 'checkdynamicrange', 'checkdynamiclowerbound', ...
              'checkdynamicupperbound', 'checkdynamicgap'};
    entrees = [1 1 1 1 3 2 2 3];
    genre = find(strcmp(type, genres));
    q = struct('Enabled', p.enabled, 'StopWhenAssertionFail', p.stopWhenAssertionFail, ...
               'Genre', genre, 'Min', double(champ(p, 'min', 0)), ...
               'Max', double(champ(p, 'max', 0)), ...
               'MinInclus', strcmp(champ(p, 'min_included', 'on'), 'on'), ...
               'MaxInclus', strcmp(champ(p, 'max_included', 'on'), 'on'), ...
               'NombreEntrees', entrees(genre));
    if any(genre == [1 4])
        bas = q.Min;
        haut = q.Max;
        if ~(isscalar(bas) || isscalar(haut) || numel(bas) == numel(haut))
            error('Simulink:blocks:CheckBoundsSize', ...
                  'Les bornes min et max du bloc ''%s'' n''ont pas le meme nombre d''elements.', ...
                  chemin);
        end
        if any(bas(:) > haut(:))
            error('Simulink:blocks:CheckBoundsOrder', ...
                  ['La borne min du bloc ''%s'' depasse sa borne max : l''intervalle ' ...
                   'est vide.'], chemin);
        end
    end
end

function c = celluleDe(v)
    if iscell(v)
        c = v;
    elseif ischar(v) || isstring(v)
        texte = strtrim(char(v));
        if ~isempty(texte) && texte(1) == '{'
            c = eval(texte);
        else
            c = {texte};
        end
    else
        c = {v};
    end
end

% Un choix se compare sans la casse ni les espaces : « u2>=Threshold » et
% « u2 >= Threshold » disent la même chose.
function v = choisir(v, admis, chemin, nom)
    if isnumeric(v) && isscalar(v)
        v = num2str(v);
    end
    cle = lower(regexprep(char(v), '\s', ''));
    for i = 1:numel(admis)
        if strcmp(cle, lower(regexprep(admis{i}, '\s', '')))
            v = admis{i};
            return
        end
    end
    error('Simulink:Parameters:InvalidValue', ...
          ['Le parametre ''%s'' du bloc ''%s'' vaut ''%s'' ; les valeurs admises ' ...
           'sont : %s.'], nom, chemin, char(v), strjoin(admis, ', '));
end

% Le code numérique de chaque type : c'est lui que la boucle de calcul
% aiguille, plus vite qu'une chaîne. La table est la seule : les fichiers
% d'exécution citent le type en commentaire de chaque cas.
function x = codeDe(type)
    persistent table
    if isempty(table)
        noms = {'constant', 1; 'step', 2; 'ramp', 3; 'sine', 4; 'clock', 5; ...
                'digitalclock', 6; 'pulsegenerator', 7; 'ground', 8; ...
                'repeatingsequence', 9; 'randomnumber', 10; ...
                'uniformrandomnumber', 11; 'inport', 12; 'fromworkspace', 13; ...
                'from', 14; ...
                'gain', 20; 'sum', 21; 'product', 22; 'abs', 23; 'sign', 24; ...
                'math', 25; 'trigonometry', 26; 'minmax', 27; 'bias', 28; ...
                'dotproduct', 29; 'unaryminus', 30; 'rounding', 31; ...
                'polynomial', 32; 'sqrt', 33; ...
                'saturation', 40; 'deadzone', 41; 'relay', 42; 'quantizer', 43; ...
                'ratelimiter', 44; 'hitcrossing', 45; 'backlash', 46; ...
                'coulombfriction', 47; 'lookup', 48; 'lookup2d', 49; ...
                'logic', 50; 'relational', 51; 'comparetoconstant', 52; ...
                'comparetozero', 53; 'detectchange', 54; 'detectincrease', 55; ...
                'detectdecrease', 56; ...
                'switch', 60; 'multiportswitch', 61; 'mux', 62; 'demux', 63; ...
                'selector', 64; 'concatenate', 65; 'reshape', 66; 'goto', 67; ...
                'signalconversion', 68; ...
                'integrator', 70; 'derivative', 71; 'transferfcn', 72; ...
                'statespace', 73; 'zeropole', 74; 'transportdelay', 75; ...
                'pidcontroller', 76; ...
                'delay', 80; 'memory', 81; 'zoh', 82; 'discreteintegrator', 83; ...
                'discretetransferfcn', 84; 'discretefilter', 85; ...
                'discretestatespace', 86; ...
                'outport', 90; 'scope', 91; 'display', 92; 'toworkspace', 93; ...
                'terminator', 94; 'stopsimulation', 95; 'assertion', 96; ...
                'subsystem', 99; ...
                'if', 110; 'switchcase', 111; 'merge', 112; 'garde', 113; ...
                'enableport', 114; 'triggerport', 115; 'actionport', 116; ...
                'fcn', 100; 'matlabfunction', 101; 'interpretedmatlabfunction', 102; ...
                'sfunction', 103; 'chart', 104; 'msfunction', 109; ...
                'buscreator', 62; 'busselector', 63; 'datatypeconversion', 34; ...
                'chirp', 15; 'counterfreerunning', 16; 'counterlimited', 17; ...
                'signalgenerator', 18; 'repeatingsequencestair', 19; ...
                'wraptozero', 35; 'intervaltest', 36; 'saturationdynamic', 37; ...
                'deadzonedynamic', 38; 'manualswitch', 39; ...
                'ic', 57; 'width', 58; 'datastoreread', 59; 'datastorewrite', 69; ...
                'secondorderintegrator', 77; 'variabletransportdelay', 78; ...
                'algebraicconstraint', 79; 'busassignment', 121; ...
                'discretederivative', 87; 'tappeddelay', 88; 'difference', 89; ...
                'xygraph', 97; 'tofile', 98; ...
                'datastorememory', 117; 'ratetransition', 118; ...
                'iterateur', 105; 'foriterator', 106; 'whileiterator', 107; ...
                'functioncallgenerator', 108; 'directlookup', 120};
        table = containers.Map(noms(:, 1)', noms(:, 2)');
    end
    x = table(type);
end

% === Goto et From ==============================================================
%
% Un From rend le signal qui entre dans le Goto de même étiquette. La
% portée suit TagVisibility : « local », le même système ; « global »,
% tout le modèle ; « scoped », le système du Goto et ceux qu'il contient.
% Le From lit donc, sans lien visible, le port qui alimente le Goto.
function c = resoudreGoto(c)
    gotos = find(strcmp(c.types, 'goto'));
    froms = find(strcmp(c.types, 'from'));
    for f = froms
        etiquette = char(c.p{f}.GotoTag);
        systemeFrom = parent(c.noms{f});
        candidats = [];
        for g = gotos
            if ~strcmp(char(c.p{g}.GotoTag), etiquette)
                continue
            end
            systemeGoto = parent(c.noms{g});
            switch c.p{g}.TagVisibility
                case 'global'
                    visible = true;
                case 'scoped'
                    visible = strncmp(systemeFrom, systemeGoto, numel(systemeGoto));
                otherwise
                    visible = strcmp(systemeFrom, systemeGoto);
            end
            if visible
                candidats(end + 1) = g; %#ok<AGROW>
            end
        end
        if isempty(candidats)
            error('Simulink:Engine:GotoTagMissing', ...
                  ['Le bloc From ''%s'' lit l''etiquette ''%s'', qu''aucun bloc Goto ' ...
                   'visible depuis lui ne porte.'], c.chemins{f}, etiquette);
        end
        if numel(candidats) > 1
            error('Simulink:Engine:GotoTagDuplicate', ...
                  ['L''etiquette ''%s'' que lit ''%s'' est portee par plusieurs blocs ' ...
                   'Goto : %s.'], etiquette, c.chemins{f}, ...
                  strjoin(c.chemins(candidats), ', '));
        end
        % Le From lit ce qui entre dans le Goto : une entrée invisible, que
        % le calcul et l'ordre traitent comme un lien.
        c.entrees{f} = c.entrees{candidats}(1);
        c.nIn(f) = 1;
    end
end

% Un Data Store Read ou Write désigne sa mémoire par son nom : le bloc Data
% Store Memory de ce nom dans son système, ou dans un système qui
% l'englobe — le plus proche. C.MEMOIRE rend son rang.
function c = resoudreMemoires(c)
    c.memoire = zeros(1, c.n);
    memoires = find(strcmp(c.types, 'datastorememory'));
    for m = memoires
        nom = char(c.p{m}.DataStoreName);
        doubles = memoires(arrayfun(@(j) strcmp(char(c.p{j}.DataStoreName), nom) && ...
                                    strcmp(parent(c.noms{j}), parent(c.noms{m})), memoires));
        if numel(doubles) > 1
            error('Simulink:DataStores:DuplicateDataStore', ...
                  'La memoire partagee ''%s'' est definie deux fois dans le meme systeme : %s.', ...
                  nom, strjoin(c.chemins(doubles), ', '));
        end
    end
    for k = find(ismember(c.types, {'datastoreread', 'datastorewrite'}))
        nom = char(c.p{k}.DataStoreName);
        systeme = parent(c.noms{k});
        meilleur = 0;
        profondeur = -1;
        for m = memoires
            if ~strcmp(char(c.p{m}.DataStoreName), nom)
                continue
            end
            sien = parent(c.noms{m});
            visible = isempty(sien) || strcmp(sien, systeme) || ...
                      strncmp([sien '/'], [systeme '/'], numel(sien) + 1);
            if visible && numel(sien) > profondeur
                meilleur = m;
                profondeur = numel(sien);
            end
        end
        if meilleur == 0
            error('Simulink:DataStores:DataStoreNotFound', ...
                  ['Le bloc ''%s'' designe la memoire partagee ''%s'', qu''aucun bloc ' ...
                   'Data Store Memory visible depuis lui ne definit. Posez-en un dans ' ...
                   'son systeme, ou dans un systeme qui l''englobe.'], c.chemins{k}, nom);
        end
        c.memoire(k) = meilleur;
    end
end

% Une mémoire que lisent ou écrivent des blocs sans qu'aucun Data Store
% Memory ne la définisse peut l'être par un Simulink.Signal de l'espace de
% travail de base qui porte son nom : c'est une mémoire globale, que l'on
% pose ici comme un Data Store Memory à la racine du modèle, visible de
% partout.
function modele = memoiresGlobales(modele)
    definies = {};
    cherchees = {};
    for k = 1:numel(modele.blocs)
        b = modele.blocs{k};
        try
            entree = matlibre_sl_catalogue('type', b.type);
        catch
            continue   % un type inconnu : la compilation le dira
        end
        if ~any(strcmp(entree.type, {'datastorememory', 'datastoreread', 'datastorewrite'}))
            continue
        end
        nom = 'A';
        if isfield(b, 'parametres') && isfield(b.parametres, 'DataStoreName')
            nom = char(b.parametres.DataStoreName);
        end
        if strcmp(entree.type, 'datastorememory')
            definies{end + 1} = nom; %#ok<AGROW>
        else
            cherchees{end + 1} = nom; %#ok<AGROW>
        end
    end
    noms = {};
    for k = 1:numel(modele.blocs)
        noms{end + 1} = char(modele.blocs{k}.nom); %#ok<AGROW>
    end
    for nom = unique(setdiff(cherchees, definies))
        if ~isvarname(nom{1}) || evalin('base', sprintf('exist(''%s'', ''var'')', nom{1})) ~= 1
            continue
        end
        signal = evalin('base', nom{1});
        if ~isa(signal, 'Simulink.Signal')
            continue
        end
        origine = sprintf('Simulink.Signal %s', nom{1});
        valeur = 0;
        if ~isempty(strtrim(signal.InitialValue))
            valeur = matlibre_sl_expression(signal.InitialValue, origine, 'InitialValue', ...
                                            'classe');
        end
        dims = signal.Dimensions;
        if ~isequal(dims, -1)
            if isscalar(dims)
                dims = [dims 1];
            end
            if isscalar(valeur)
                valeur = valeur * ones(dims);
            elseif numel(valeur) ~= prod(dims)
                error('Simulink:DataStores:InvalidInitialValue', ...
                      ['La memoire globale ''%s'' est definie par un Simulink.Signal de ' ...
                       'dimensions %s, et sa valeur initiale porte %d element(s).'], ...
                      nom{1}, mat2str(signal.Dimensions), numel(valeur));
            end
        end
        if any(strcmp(signal.DataType, matlibre_sl_parametre('types'))) && ...
           ~strcmp(signal.DataType, 'auto')
            if strcmp(signal.DataType, 'boolean')
                valeur = logical(valeur ~= 0);
            else
                valeur = cast(valeur, signal.DataType);
            end
        end
        bloc = sprintf('%s (Simulink.Signal)', nom{1});
        while any(strcmp(noms, bloc))
            bloc = [bloc '_']; %#ok<AGROW>
        end
        noms{end + 1} = bloc; %#ok<AGROW>
        modele = add_block(modele, 'datastorememory', bloc, 'DataStoreName', nom{1}, ...
                           'InitialValue', double(valeur));
    end
end

% Un Variant Source ne laisse passer que son entrée active, un Variant
% Sink n'envoie son entrée qu'à sa sortie active : ils deviennent un
% simple passage, et leurs autres liens sont retirés — une sortie
% inactive d'un Variant Sink vaut zéro. Sans variante active et avec
% AllowZeroVariantControls à 'on', rien ne passe.
function modele = variantesDeSignal(modele, nomModele)
    nBlocs = numel(modele.blocs);
    for k = 1:nBlocs
        bloc = modele.blocs{k};
        try
            entree = matlibre_sl_catalogue('type', bloc.type);
        catch
            continue
        end
        if ~any(strcmp(entree.type, {'variantsource', 'variantsink'}))
            continue
        end
        chemin = [nomModele '/' char(bloc.nom)];
        p = bloc.parametres;
        controles = matlibre_sl_variantes('liste', lireReglage(p, 'VariantControls', ...
                                                               {'V == 1', 'V == 2'}));
        source = strcmp(entree.type, 'variantsource');
        if source
            noms = arrayfun(@(i) sprintf('%s, entree %d', chemin, i), 1:numel(controles), ...
                            'UniformOutput', false);
        else
            noms = arrayfun(@(i) sprintf('%s, sortie %d', chemin, i), 1:numel(controles), ...
                            'UniformOutput', false);
        end
        actif = matlibre_sl_variantes('choisir', controles, ...
                    char(lireReglage(p, 'VariantControlMode', 'expression')), ...
                    char(lireReglage(p, 'LabelModeActiveChoice', '')), ...
                    strcmpi(char(lireReglage(p, 'AllowZeroVariantControls', 'off')), 'on'), ...
                    chemin, noms);
        liens = matlibre_sl_liens(modele);
        passage = bloc;
        passage.parametres = struct();
        if source
            % l'entrée active arrive sur le port 1 ; les autres liens partent
            arrivee = find(liens(:, 2) == k);
            garder = arrivee(liens(arrivee, 3) == actif);
            liens(garder, 3) = 1;
            liens(setdiff(arrivee, garder), :) = [];
            if actif == 0
                passage.type = 'ground';
            else
                passage.type = 'signalconversion';
            end
        else
            depart = find(liens(:, 1) == k);
            if actif == 0
                passage.type = 'terminator';
            else
                passage.type = 'signalconversion';
            end
            inactifs = depart(liens(depart, 4) ~= actif);
            liens(depart(liens(depart, 4) == actif), 4) = 1;
            if ~isempty(inactifs)
                masse = bloc;
                masse.type = 'ground';
                masse.nom = sprintf('%s (zero)', char(bloc.nom));
                masse.parametres = struct();
                modele.blocs{end + 1} = masse;
                liens(inactifs, 1) = numel(modele.blocs);
                liens(inactifs, 4) = 1;
            end
        end
        modele.blocs{k} = passage;
        modele.liens = liens;
    end
end

function v = lireReglage(p, nom, defaut)
    v = defaut;
    for champ = fieldnames(p).'
        if strcmpi(champ{1}, nom)
            v = p.(champ{1});
            return
        end
    end
end

% Un sous-système appelé par fonction ne reçoit ses appels que d'un
% générateur d'appels, et un générateur n'appelle que de tels
% sous-systèmes : Simulink refuse l'un et l'autre mélange.
function verifierAppels(c)
    for g = find(strcmp(c.types, 'garde'))
        if ~strcmp(c.p{g}.Trigger, 'function-call')
            continue
        end
        rang = 1 + (c.p{g}.Enable ~= 0);
        e = c.entrees{g};
        if rang <= numel(e) && e(rang) ~= 0 && appelParGraphe(c, e(rang))
            continue
        end
        if rang > numel(e) || e(rang) == 0 || ...
           ~strcmp(c.types{c.proprio(e(rang))}, 'functioncallgenerator')
            error('Simulink:blocks:FcnCallSubsystemInputNotFcnCall', ...
                  ['Le sous-systeme appele par fonction dont ''%s'' est le port Trigger ' ...
                   'doit etre relie a un Function-Call Generator.'], c.chemins{g});
        end
    end
    for k = find(strcmp(c.types, 'functioncallgenerator'))
        for b = 1:c.n
            e = c.entrees{b};
            if ~any(e == c.portDebut(k))
                continue
            end
            appele = strcmp(c.types{b}, 'garde') && strcmp(c.p{b}.Trigger, 'function-call');
            if ~appele
                error('Simulink:blocks:FcnCallOutputToNonFcnCallInput', ...
                      ['Le generateur d''appels ''%s'' est relie a ''%s'', qui n''est pas ' ...
                       'le port Trigger d''un sous-systeme appele par fonction.'], ...
                      c.chemins{k}, c.chemins{b});
            end
        end
    end
end

% Le port global G est-il un événement de sortie 'Function call' d'un
% bloc Chart ? Il appelle alors, comme un Function-Call Generator.
function oui = appelParGraphe(c, g)
    oui = false;
    k = c.proprio(g);
    if ~strcmp(c.types{k}, 'chart') || ~isfield(c.fonctions{k}, 'sortiesEvt')
        return
    end
    code = c.fonctions{k};
    q = g - c.portDebut(k) + 1 - numel(code.sorties);
    oui = q >= 1 && q <= numel(code.sortiesEvt) && ...
          strcmp(code.sortiesEvt(q).declencheur, 'Function call');
end

% Signal Specification : les dimensions qu'il annonce doivent être
% celles de son entrée.
function verifierSpecification(c, k, dE)
    p = c.p{k};
    if ~isfield(p, 'DimensionsVerifiees') || isequal(p.DimensionsVerifiees, -1) || ...
       isempty(dE) || isempty(dE{1})
        return
    end
    attendu = p.DimensionsVerifiees;
    d = dE{1};
    if isscalar(attendu)
        bon = prod(d) == attendu && any(d == 1);
    else
        bon = isequal(d(:).', attendu(:).');
    end
    if ~bon
        error('Simulink:blocks:SignalSpecificationDimensions', ...
              ['Le bloc Signal Specification ''%s'' annonce des dimensions %s, et son ' ...
               'entree en a %s.'], c.chemins{k}, mat2str(attendu), mat2str(d));
    end
end

function s = parent(nom)
    barre = find(nom == '/', 1, 'last');
    if isempty(barre)
        s = '';
    else
        s = nom(1:barre - 1);
    end
end

% === transmission directe =====================================================
%
% Un bloc transmet directement quand sa sortie à l'instant t dépend de son
% entrée à l'instant t. C'est ce qui ordonne le calcul — il vient après ce
% qui l'alimente — et ce qui fait qu'une boucle sans autre bloc est
% algébrique.
function d = transmissionDirecte(c, k)
    p = c.p{k};
    switch c.types{k}
        case {'integrator', 'delay', 'memory'}
            % une longueur donnée par une entrée peut valoir zéro
            d = strcmp(c.types{k}, 'delay') && ...
                (p.DelayLength == 0 || strcmp(p.DelayLengthSource, 'Input port'));
        case {'secondorderintegrator', 'width', 'foriterator', 'whileiterator'}
            d = false;
        case 'tappeddelay'
            d = strcmp(p.includeCurrent, 'on');
        case {'statespace', 'discretestatespace'}
            d = any(p.D(:) ~= 0);
        case 'transferfcn'
            [num, den] = transmittance(p.Numerator, p.Denominator, c.chemins{k});
            d = numel(num) == numel(den) && num(1) ~= 0;
        case 'zeropole'
            d = numel(p.Zeros) == numel(p.Poles) && p.Gain ~= 0;
        case 'transportdelay'
            d = p.DelayTime == 0;
        case 'variabletransportdelay'
            % le retard se lit aussi à la passe refaite, après son entrée
            d = strcmp(p.ZeroDelay, 'on');
        case 'discreteintegrator'
            d = methodeDTI(p.IntegratorMethod) ~= 1;
        case 'sfunction'
            d = c.fonctions{k}.tailles(6) ~= 0;
        case 'msfunction'
            d = c.fonctions{k}.direct;
        case {'discretetransferfcn', 'discretefilter'}
            [b, ~] = filtreDiscret(p.Numerator, p.Denominator, ...
                                   strcmp(c.types{k}, 'discretetransferfcn'), c.chemins{k});
            d = b(1) ~= 0;
        otherwise
            d = true;
    end
end

% Une transmittance continue : le numérateur ne doit pas être de degré plus
% haut que le dénominateur, sans quoi elle n'a pas de réalisation d'état.
function [num, den] = transmittance(num, den, chemin)
    num = double(num(:)).';
    den = double(den(:)).';
    while numel(num) > 1 && num(1) == 0
        num(1) = [];
    end
    while numel(den) > 1 && den(1) == 0
        den(1) = [];
    end
    if isempty(den) || all(den == 0)
        error('Simulink:blocks:TransferFcnZeroDenominator', ...
              'Le denominateur de ''%s'' est nul.', chemin);
    end
    if numel(num) > numel(den)
        error('Simulink:blocks:TransferFcnImproper', ...
              ['La transmittance de ''%s'' a un numerateur de degre %d et un ' ...
               'denominateur de degre %d : elle n''est pas propre, et n''a pas de ' ...
               'realisation d''etat.'], chemin, numel(num) - 1, numel(den) - 1);
    end
end

% Un filtre discret ramené à deux vecteurs de même longueur, en puissances
% croissantes de z^-1, le premier coefficient du dénominateur valant un.
% « Discrete Transfer Fcn » s'écrit en puissances de z : le polynôme court
% se complète à gauche. « Discrete Filter » s'écrit en puissances de z^-1 :
% il se complète à droite. Les deux coïncident quand les longueurs sont
% égales.
function [b, a] = filtreDiscret(num, den, enZ, chemin)
    b = double(num(:)).';
    a = double(den(:)).';
    if enZ
        while numel(a) > 1 && a(1) == 0
            a(1) = [];
        end
    end
    if isempty(a) || a(1) == 0
        error('Simulink:blocks:TransferFcnZeroDenominator', ...
              ['Le bloc ''%s'' a un denominateur dont le premier coefficient ' ...
               'est nul : la recurrence ne se resout pas.'], chemin);
    end
    if enZ && numel(b) > numel(a)
        error('Simulink:blocks:TransferFcnImproper', ...
              ['La transmittance discrete de ''%s'' a un numerateur de degre plus ' ...
               'haut que son denominateur : elle demanderait l''entree future.'], chemin);
    end
    L = max(numel(a), numel(b));
    if enZ
        b = [zeros(1, L - numel(b)), b];
        a = [a, zeros(1, L - numel(a))];
    else
        b = [b, zeros(1, L - numel(b))];
        a = [a, zeros(1, L - numel(a))];
    end
    b = b / a(1);
    a = a / a(1);
end

% === dimensions ================================================================
%
% On part des sources, dont les paramètres disent la taille, et l'on
% avance jusqu'à ce que plus rien ne change. Une boucle dont aucun bloc ne
% fixe la taille — un intégrateur de condition initiale scalaire bouclé
% sur un gain — reste alors indéterminée : les blocs à état y prennent la
% taille de leur condition initiale, et l'on repart.
function dims = propagerDimensions(c)
    dims = cell(1, c.nPorts);
    connu = false(1, c.nPorts);
    forcer = false;
    for tour = 1:(4 * c.n + 10)
        progres = false;
        for k = 1:c.n
            enCours('bloc', k);
            if c.nOut(k) == 0
                continue
            end
            ports = c.portDebut(k) + (0:c.nOut(k) - 1);
            if all(connu(ports))
                continue
            end
            [dimsE, complet] = dimsEntrees(c, k, dims, connu);
            if strcmp(c.types{k}, 'busselector')
                c.dimsCourants = dims;   % il lit la forme du bus en amont
            end
            sortie = regleDims(c, k, dimsE, complet, forcer);
            if isempty(sortie) || any(cellfun(@isempty, sortie))
                continue
            end
            for q = 1:numel(ports)
                dims{ports(q)} = sortie{q};
                connu(ports(q)) = true;
            end
            progres = true;
        end
        if all(connu)
            break
        end
        if ~progres
            if forcer
                % Plus rien ne se détermine : ce qui reste est scalaire.
                for gp = find(~connu)
                    dims{gp} = [1 1];
                    connu(gp) = true;
                end
                break
            end
            forcer = true;
        end
    end
    % Une fois tout connu, chaque bloc vérifie ses entrées : c'est là que
    % tombent les désaccords de dimensions.
    c.dimsCourants = dims;
    for k = 1:c.n
        enCours('bloc', k);
        [dimsE, ~] = dimsEntrees(c, k, dims, connu);
        sortie = regleDims(c, k, dimsE, true, true);
        if c.nOut(k) == 0
            continue
        end
        ports = c.portDebut(k) + (0:c.nOut(k) - 1);
        for q = 1:numel(ports)
            if ~isequal(dims{ports(q)}, sortie{q})
                error('Simulink:Engine:DimensionMismatch', ...
                      ['Erreur de dimensions : la sortie %d de ''%s'' devrait etre de ' ...
                       'dimension %s, mais la boucle ou elle se trouve lui impose %s.'], ...
                      q, c.chemins{k}, texteDims(sortie{q}), texteDims(dims{ports(q)}));
            end
        end
    end
end

function [dimsE, complet] = dimsEntrees(c, k, dims, connu)
    e = c.entrees{k};
    dimsE = cell(1, numel(e));
    complet = true;
    for j = 1:numel(e)
        if e(j) == 0
            dimsE{j} = [1 1];     % une entrée en l'air vaut un zéro scalaire
        elseif connu(e(j))
            dimsE{j} = dims{e(j)};
        else
            dimsE{j} = [];
            complet = false;
        end
    end
end

function t = texteDims(d)
    if isempty(d)
        t = '(inconnue)';
    elseif prod(d) == 1
        t = 'scalaire';
    elseif d(2) == 1
        t = sprintf('%d (vecteur)', d(1));
    else
        t = sprintf('[%d %d]', d(1), d(2));
    end
end

% La taille d'un paramètre devenu signal : un vecteur, ligne ou colonne,
% est un vecteur ; une matrice reste une matrice.
function d = dimsDe(v)
    if numel(v) <= 1
        d = [1 1];
    elseif isvector(v)
        d = [numel(v) 1];
    else
        d = size(v);
        d = d(1:2);
    end
end

% Des dimensions qui doivent s'accorder : égales, ou l'une scalaire, qui
% s'étend aux autres. C'est la règle des blocs élément par élément.
function d = accorder(liste, c, k, quoi)
    d = [1 1];
    premiere = 0;
    for j = 1:numel(liste)
        x = liste{j};
        if isempty(x) || prod(x) == 1
            continue
        end
        if prod(d) == 1
            d = x;
            premiere = j;
        elseif ~isequal(x, d)
            if numel(quoi) >= max(j, premiere)
                a = quoi{premiere};
                b = quoi{j};
            else
                a = sprintf('l''entree %d', premiere);
                b = sprintf('l''entree %d', j);
            end
            error('Simulink:Engine:DimensionMismatch', ...
                  ['Erreur de dimensions dans ''%s'' : %s est de dimension %s et %s ' ...
                   'de dimension %s. Elles doivent etre egales, ou l''une scalaire.'], ...
                  c.chemins{k}, a, texteDims(d), b, texteDims(x));
        end
    end
end

function q = nomsEntrees(n)
    q = cell(1, n);
    for j = 1:n
        q{j} = sprintf('l''entree %d', j);
    end
end

% Les dimensions des sorties d'un bloc, d'après ses paramètres et celles
% de ses entrées. Rend {} quand il faut attendre une entrée inconnue.
function s = regleDims(c, k, dE, complet, forcer)
    p = c.p{k};
    t = c.types{k};
    s = {};
    switch t
        % --- sources ---
        case 'constant'
            s = {dimsDe(p.Value)};
        case 'step'
            s = {accorder({dimsDe(p.Time), dimsDe(p.Before), dimsDe(p.After)}, c, k, ...
                          {'Time', 'Before', 'After'})};
        case 'ramp'
            s = {accorder({dimsDe(p.Slope), dimsDe(p.Start), dimsDe(p.InitialOutput)}, ...
                          c, k, {'Slope', 'Start', 'InitialOutput'})};
        case 'sine'
            s = {accorder({dimsDe(p.Amplitude), dimsDe(p.Frequency), dimsDe(p.Phase), ...
                           dimsDe(p.Bias)}, c, k, ...
                          {'Amplitude', 'Frequency', 'Phase', 'Bias'})};
        case {'clock', 'digitalclock', 'ground', 'repeatingsequence', ...
              'counterfreerunning', 'counterlimited', 'repeatingsequencestair', 'width'}
            s = {[1 1]};
        case 'chirp'
            s = {accorder({dimsDe(p.f1), dimsDe(p.T), dimsDe(p.f2)}, c, k, ...
                          {'f1', 'T', 'f2'})};
        case 'signalgenerator'
            s = {accorder({dimsDe(p.Amplitude), dimsDe(p.Frequency)}, c, k, ...
                          {'Amplitude', 'Frequency'})};
        case 'datastoreread'
            s = {dimsDe(c.p{c.memoire(k)}.InitialValue)};
        case {'foriterator', 'whileiterator', 'functioncallgenerator'}
            s = repmat({[1 1]}, 1, c.nOut(k));
        case 'iterateur'
            if ~complet
                return
            end
            [~, ci, ~, sorties] = interieurIterateur(c, k, dE);
            s = cell(1, numel(sorties));
            for j = 1:numel(sorties)
                s{j} = ci.inDims{sorties(j)}{1};
            end
        case {'enableport', 'triggerport', 'actionport'}
            s = {};
        case 'pulsegenerator'
            s = {accorder({dimsDe(p.Amplitude), dimsDe(p.Period), dimsDe(p.PulseWidth), ...
                           dimsDe(p.PhaseDelay)}, c, k, ...
                          {'Amplitude', 'Period', 'PulseWidth', 'PhaseDelay'})};
        case 'randomnumber'
            s = {accorder({dimsDe(p.Mean), dimsDe(p.Variance), dimsDe(p.Seed)}, c, k, ...
                          {'Mean', 'Variance', 'Seed'})};
        case 'uniformrandomnumber'
            s = {accorder({dimsDe(p.Minimum), dimsDe(p.Maximum), dimsDe(p.Seed)}, c, k, ...
                          {'Minimum', 'Maximum', 'Seed'})};
        case 'inport'
            nomType = matlibre_sl_bus('type', champ(p, 'OutDataTypeStr', ''));
            if ~isempty(nomType)
                % une entrée qui est un bus : sa largeur est celle du type
                f = matlibre_sl_bus('forme', matlibre_sl_bus('objet', nomType, c.chemins{k}), ...
                                    c.chemins{k});
                s = {[sum([f.largeur]) 1]};
            elseif isnumeric(p.PortDimensions) && all(p.PortDimensions > 0)
                d = double(p.PortDimensions);
                if isscalar(d), d = [d 1]; end
                s = {d(1:2)};
            else
                s = {dimsDe(p.Value)};
            end
        case 'fromworkspace'
            [~, valeurs] = lireSignalEspace(p, c.chemins{k});
            s = {dimsDe(zeros(size(valeurs, 2), 1))};
        case 'from'
            if isempty(c.entrees{k}) || c.entrees{k}(1) == 0
                s = {[1 1]};
            elseif complet || ~isempty(dE)
                if isempty(dE) || isempty(dE{1})
                    return
                end
                s = dE(1);
            end
        otherwise
            if ~complet && ~forcer && ~ismember(t, {'statespace', 'transferfcn', ...
                    'zeropole', 'discretetransferfcn', 'discretefilter', ...
                    'discretestatespace', 'integrator', 'delay', 'memory', ...
                    'discreteintegrator', 'sfunction', 'msfunction', 'secondorderintegrator', ...
                    'tappeddelay', 'ratetransition', 'algebraicconstraint'})
                return
            end
            s = regleTraitement(c, k, dE, complet, forcer);
    end
end

function s = regleTraitement(c, k, dE, complet, forcer)
    p = c.p{k};
    t = c.types{k};
    s = {};
    q = nomsEntrees(numel(dE));
    switch t
        case 'gain'
            K = p.Gain;
            switch p.Multiplication
                case 'Element-wise(K.*u)'
                    s = {accorder({dimsDe(K), dE{1}}, c, k, {'le gain', 'l''entree'})};
                case {'Matrix(K*u)', 'Matrix(K*u) (u vector)'}
                    if prod(dE{1}) ~= size(K, 2) && ~(isscalar(K))
                        erreurMatrice(c, k, sprintf(['le gain a %d colonne(s) et ' ...
                            'l''entree %d element(s)'], size(K, 2), prod(dE{1})));
                    end
                    if isscalar(K), s = dE(1); else, s = {[size(K, 1) 1]}; end
                case 'Matrix(u*K)'
                    if prod(dE{1}) ~= size(K, 1) && ~isscalar(K)
                        erreurMatrice(c, k, sprintf(['le gain a %d ligne(s) et ' ...
                            'l''entree %d element(s)'], size(K, 1), prod(dE{1})));
                    end
                    if isscalar(K), s = dE(1); else, s = {[size(K, 2) 1]}; end
            end
        case {'sum', 'product', 'minmax'}
            if numel(dE) == 1 && ~(strcmp(t, 'product') && ...
                    strcmp(p.Multiplication, 'Matrix(*)'))
                s = {[1 1]};     % une seule entrée : sur ses éléments
            elseif strcmp(t, 'product') && strcmp(p.Multiplication, 'Matrix(*)')
                s = {produitMatriciel(c, k, dE)};
            else
                s = {accorder(dE, c, k, q)};
            end
        case {'abs', 'sign', 'unaryminus', 'rounding', 'polynomial', 'sqrt', ...
              'quantizer', 'hitcrossing', 'coulombfriction', 'lookup', ...
              'comparetozero', 'detectchange', 'detectincrease', 'detectdecrease', ...
              'derivative', 'zoh', 'signalconversion'}
            if strcmp(t, 'signalconversion')
                s = dE;
                if isempty(s), s = {[1 1]}; end
                verifierSpecification(c, k, dE);
            else
                s = dE(1);
            end
        case 'math'
            switch p.Operator
                case {'pow', 'hypot', 'rem', 'mod'}
                    s = {accorder(dE, c, k, q)};
                case {'transpose', 'hermitian'}
                    d = dE{1};
                    s = {[d(2) d(1)]};
                otherwise
                    s = dE(1);
            end
        case 'trigonometry'
            if strcmp(p.Operator, 'atan2')
                s = {accorder(dE, c, k, q)};
            elseif strcmp(p.Operator, 'sincos')
                s = {dE{1}, dE{1}};
            else
                s = dE(1);
            end
        case 'bias'
            s = {accorder({dE{1}, dimsDe(p.Bias)}, c, k, {'l''entree', 'Bias'})};
        case 'dotproduct'
            accorder(dE, c, k, q);
            s = {[1 1]};
        case 'saturation'
            s = {accorder({dE{1}, dimsDe(p.UpperLimit), dimsDe(p.LowerLimit)}, c, k, ...
                          {'l''entree', 'UpperLimit', 'LowerLimit'})};
        case 'deadzone'
            s = {accorder({dE{1}, dimsDe(p.UpperValue), dimsDe(p.LowerValue)}, c, k, ...
                          {'l''entree', 'UpperValue', 'LowerValue'})};
        case 'relay'
            s = {accorder({dE{1}, dimsDe(p.OnSwitch), dimsDe(p.OffSwitch), ...
                           dimsDe(p.OnOutput), dimsDe(p.OffOutput)}, c, k, ...
                          {'l''entree', 'OnSwitch', 'OffSwitch', 'OnOutput', 'OffOutput'})};
        case 'ratelimiter'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'backlash'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'lookup2d'
            s = {accorder(dE, c, k, q)};
        case {'logic'}
            if numel(dE) == 1 && ~strcmp(p.Operator, 'NOT')
                s = {[1 1]};
            else
                s = {accorder(dE, c, k, q)};
            end
        case 'relational'
            s = {accorder(dE, c, k, q)};
        case 'comparetoconstant'
            s = {accorder({dE{1}, dimsDe(p.const)}, c, k, {'l''entree', 'const'})};
        case 'switch'
            s = {accorder(dE, c, k, q)};
        case 'multiportswitch'
            if prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      'L''entree de commande de ''%s'' doit etre scalaire.', c.chemins{k});
            end
            if numel(dE) == 2
                s = {[1 1]};   % une seule entrée de données : l'Index Vector en choisit un élément
            else
                s = {accorder(dE(2:end), c, k, q(2:end))};
            end
        case 'assertion'
            % les bornes d'un bloc de vérification dynamique s'accordent au signal
            if numel(dE) > 1
                noms = {'max', 'sig', 'min'};
                if champ(p, 'Genre', 0) == 6
                    noms = {'min', 'sig'};
                end
                accorder(dE, c, k, noms(1:numel(dE)));
            end
        case 'buscreator'
            s = {[sum(cellfun(@prod, dE)) 1]};
        case 'busselector'
            choix = elementsChoisis(c, k);
            if isempty(choix)
                return   % la forme du bus n'est pas encore connue
            end
            if strcmp(p.OutputAsBus, 'on')
                s = {[sum([choix.largeur]) 1]};
            else
                s = arrayfun(@(e) e.dims, choix, 'UniformOutput', false);
            end
        case 'datatypeconversion'
            s = dE(1);
        case 'mux'
            largeurs = cellfun(@prod, dE);
            attendues = double(p.Inputs);
            if ~isscalar(attendues)
                for j = 1:numel(attendues)
                    if attendues(j) > 0 && attendues(j) ~= largeurs(j)
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['L''entree %d de ''%s'' est de largeur %d ; le parametre ' ...
                               'Inputs en attend %d.'], j, c.chemins{k}, largeurs(j), ...
                              attendues(j));
                    end
                end
            end
            s = {[sum(largeurs) 1]};
        case 'demux'
            W = prod(dE{1});
            parts = double(p.Outputs);
            if isscalar(parts)
                if mod(W, parts) ~= 0
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['L''entree de ''%s'' est de largeur %d, qui ne se partage pas en ' ...
                           '%d sorties egales ; donnez leurs largeurs dans Outputs.'], ...
                          c.chemins{k}, W, parts);
                end
                largeurs = repmat(W / parts, 1, parts);
            else
                largeurs = parts;
                libres = find(largeurs < 0);
                if numel(libres) == 1
                    largeurs(libres) = W - sum(largeurs(largeurs > 0));
                end
                if sum(largeurs) ~= W || any(largeurs < 1)
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['Les largeurs demandees par ''%s'' (%s) ne font pas la largeur ' ...
                           'de son entree (%d).'], c.chemins{k}, mat2str(parts), W);
                end
            end
            s = cell(1, numel(largeurs));
            for j = 1:numel(largeurs)
                s{j} = [largeurs(j) 1];
            end
        case 'selector'
            W = prod(dE{1});
            indices = double(p.Indices(:));
            if any(indices < 1) || any(indices ~= round(indices)) || any(indices > W)
                error('Simulink:Selector:IndexOutOfRange', ...
                      ['Les indices de ''%s'' (%s) sortent de son entree, de largeur %d.'], ...
                      c.chemins{k}, mat2str(indices.'), W);
            end
            s = {dimsDe(indices)};
        case 'concatenate'
            if strcmp(p.Mode, 'Vector')
                s = {[sum(cellfun(@prod, dE)) 1]};
            else
                dim = double(p.ConcatenateDimension);
                modele = zeros(dE{1});
                for j = 2:numel(dE)
                    try
                        modele = cat(dim, modele, zeros(dE{j}));
                    catch
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['Les entrees de ''%s'' ne se concatenent pas selon la ' ...
                               'dimension %d : %s et %s.'], c.chemins{k}, dim, ...
                              texteDims(dE{1}), texteDims(dE{j}));
                    end
                end
                s = {size(modele)};
            end
        case 'reshape'
            W = prod(dE{1});
            switch p.OutputDimensionality
                case {'1-D array', 'Column vector (2-D)'}
                    s = {[W 1]};
                case 'Row vector (2-D)'
                    s = {[1 W]};
                otherwise
                    d = double(p.OutputDimensions);
                    if isscalar(d), d = [d 1]; end
                    if prod(d) ~= W
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['''%s'' ne peut donner la forme %s a une entree de %d ' ...
                               'elements.'], c.chemins{k}, mat2str(d), W);
                    end
                    s = {d(1:2)};
            end
        case 'integrator'
            % La condition initiale externe donne la forme de l'état, comme
            % le ferait le paramètre ; les ports de saturation et d'état ont
            % celle de la sortie.
            remise = ~strcmp(p.ExternalReset, 'none');
            externe = strcmp(p.InitialConditionSource, 'external');
            ci = p.InitialCondition;
            if externe
                % l'entrée donne la largeur ; une entrée scalaire prend
                % celle de la condition initiale
                ci = 0;
                rangCI = 2 + remise;
                if numel(dE) >= rangCI && ~isempty(dE{rangCI}) && prod(dE{rangCI}) > 1 && ...
                   (isempty(dE{1}) || prod(dE{1}) == 1)
                    ci = zeros(dE{rangCI});
                end
            end
            d = dimsAvecEtat(dE, ci, complet, forcer);
            if complet && ~isempty(d)
                w = prod(d);
                for j = 2:numel(dE)
                    if ~isempty(dE{j}) && ~any(prod(dE{j}) == [1 w])
                        quoi = 'de remise';
                        if j == numel(dE) && externe
                            quoi = 'de condition initiale';
                        end
                        error('Simulink:Engine:DimensionMismatch', ...
                              ['L''entree %s de ''%s'' porte %d valeur(s), pour un etat ' ...
                               'de largeur %d : il en faut une, ou autant que l''etat.'], ...
                              quoi, c.chemins{k}, prod(dE{j}), w);
                    end
                end
            end
            s = repmat({d}, 1, c.nOut(k));
        case {'delay', 'memory'}
            s = {dimsAvecEtat(dE, p.InitialCondition, complet, forcer)};
        case 'secondorderintegrator'
            d = dimsAvecEtat(dE, p.ICX, complet, forcer);
            if numel(p.ICDXDT) > 1 && prod(d) == 1
                d = dimsDe(p.ICDXDT);
            end
            s = {d, d};
        case 'ratetransition'
            s = {dimsAvecEtat(dE, p.X0, complet, forcer)};
        case 'tappeddelay'
            if complet && ~isempty(dE{1}) && prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      ['L''entree de ''%s'' est de largeur %d : un Tapped Delay retarde ' ...
                       'un signal scalaire.'], c.chemins{k}, prod(dE{1}));
            end
            s = {[double(p.NumDelays) + strcmp(p.includeCurrent, 'on'), 1]};
        case {'wraptozero', 'ic', 'difference', 'discretederivative'}
            switch t
                case 'wraptozero'
                    s = {accorder({dE{1}, dimsDe(p.Threshold)}, c, k, ...
                                  {'l''entree', 'Threshold'})};
                case 'ic'
                    s = {accorder({dE{1}, dimsDe(p.Value)}, c, k, {'l''entree', 'Value'})};
                case 'difference'
                    s = {accorder({dE{1}, dimsDe(p.ICPrevInput)}, c, k, ...
                                  {'l''entree', 'ICPrevInput'})};
                otherwise
                    s = {accorder({dE{1}, dimsDe(p.gainval), dimsDe(p.ICPrevScaledInput)}, ...
                                  c, k, {'l''entree', 'gainval', 'ICPrevScaledInput'})};
            end
        case 'intervaltest'
            s = {accorder({dE{1}, dimsDe(p.uplimit), dimsDe(p.lowlimit)}, c, k, ...
                          {'l''entree', 'uplimit', 'lowlimit'})};
        case {'saturationdynamic', 'deadzonedynamic', 'manualswitch', 'directlookup'}
            s = {accorder(dE, c, k, q)};
        case 'discreteintegrator'
            s = repmat({dimsAvecEtat(dE, p.InitialCondition, complet, forcer)}, 1, c.nOut(k));
        case {'discretetransferfcn', 'discretefilter'}
            % Comme dans Simulink, chaque élément d'un vecteur ou d'une
            % matrice est une voie, filtrée à part — sauf pour le
            % Discrete Zero-Pole, qui ne traite qu'un scalaire.
            if isfield(p, 'ZeroPole') && complet && prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      ['L''entree de ''%s'' est de largeur %d : un Discrete Zero-Pole ' ...
                       'ne traite qu''un signal scalaire.'], c.chemins{k}, prod(dE{1}));
            end
            s = {dimsAvecEtat(dE, 0, complet, forcer)};
        case {'transferfcn', 'zeropole'}
            if complet && prod(dE{1}) ~= 1
                error('Simulink:Engine:DimensionMismatch', ...
                      ['L''entree de ''%s'' est de largeur %d : une transmittance ne ' ...
                       'traite qu''un signal scalaire. Un State-Space traite un vecteur.'], ...
                      c.chemins{k}, prod(dE{1}));
            end
            s = {[1 1]};
        case {'statespace', 'discretestatespace'}
            [~, B, C, D] = matricesEtat(p, c.chemins{k});
            if complet
                w = prod(dE{1});
                attendu = size(B, 2);
                if size(B, 1) == 0, attendu = size(D, 2); end
                if w ~= attendu && ~(w == 1)
                    error('Simulink:Engine:DimensionMismatch', ...
                          ['L''entree de ''%s'' est de largeur %d, mais la matrice B a %d ' ...
                           'colonne(s) : il faut autant d''entrees que de colonnes.'], ...
                          c.chemins{k}, w, attendu);
                end
            end
            s = {[size(C, 1) 1]};
        case 'transportdelay'
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'variabletransportdelay'
            if numel(dE) > 1 && ~isempty(dE{2}) && prod(dE{2}) ~= 1
                error('Simulink:blocks:VariableTransportDelayInput', ...
                      ['Le retard que recoit ''%s'' par sa seconde entree est de dimension ' ...
                       '%s : c''est un scalaire.'], c.chemins{k}, texteDims(dE{2}));
            end
            s = {accorder({dE{1}, dimsDe(p.InitialOutput)}, c, k, ...
                          {'l''entree', 'InitialOutput'})};
        case 'pidcontroller'
            s = dE(1);
        case 'algebraicconstraint'
            % dans la boucle, z a d'abord les dimensions de sa valeur de départ
            s = {accorder({dE{1}, dimsDe(p.InitialGuess)}, c, k, ...
                          {'l''entree f(z)', 'InitialGuess'})};
        case 'busassignment'
            s = dE(1);
        case {'garde', 'if', 'switchcase'}
            s = repmat({[1 1]}, 1, c.nOut(k));
        case 'fcn'
            s = {[1 1]};
        case 'interpretedmatlabfunction'
            d = double(p.OutputDimensions);
            if isequal(d, -1)
                s = dE(1);
            else
                if isscalar(d), d = [d 1]; end
                s = {d(1:2)};
            end
        case 'matlabfunction'
            s = dimsFonction(c, k, dE);
        case 'chart'
            code = c.fonctions{k};
            nEvt = numel(code.entreesEvt);
            if nEvt > 0 && numel(dE) > code.nDonnees && ~isempty(dE{code.nDonnees + 1})
                largeur = prod(dE{code.nDonnees + 1});
                if largeur ~= nEvt
                    error('Simulink:blocks:ChartTriggerWidth', ...
                          ['Le port de declenchement du bloc Chart ''%s'' recoit %d ' ...
                           'element(s), et sa machine declare %d evenement(s) d''entree ' ...
                           '(%s) : un element par evenement.'], c.chemins{k}, largeur, ...
                          nEvt, strjoin({code.entreesEvt.nom}, ', '));
                end
            end
            s = code.dims;
        case 'msfunction'
            % Ses ports dynamiques prennent les dimensions de ce qu'ils
            % reçoivent : on attend de les connaître, sauf pour les sorties
            % fixées, qui se connaissent seules.
            code = c.fonctions{k};
            if complet || forcer
                s = matlibre_sl_msfonction('dimensions', code, dE, c.chemins{k});
            else
                s = {};
                for j = 1:code.bloc.NumOutputPorts
                    d = double(code.bloc.OutputPort(j).Dimensions);
                    if isequal(d, -1)
                        s = {};
                        return
                    end
                    if isscalar(d), d = [d 1]; end
                    s{j} = d; %#ok<AGROW>
                end
            end
        case 'sfunction'
            ny = c.fonctions{k}.tailles(3);
            if ny < 0
                s = dE(1);   % dimensionnée par son entrée
            else
                s = {[ny 1]};
            end
        case 'merge'
            s = {accorder([dE, {dimsDe(p.InitialOutput)}], c, k, [q, {'InitialOutput'}])};
    end
end

% Un bloc à état prend la taille de sa condition initiale quand elle n'est
% pas scalaire ; sinon celle de son entrée ; et, dans une boucle où rien ne
% la fixe, celle de sa condition initiale, scalaire.
function d = dimsAvecEtat(dE, ci, complet, forcer)
    if numel(ci) > 1
        d = dimsDe(ci);
        return
    end
    if complet && ~isempty(dE) && ~isempty(dE{1})
        d = dE{1};
        return
    end
    if forcer
        d = [1 1];
        return
    end
    d = [];
    if isempty(d)
        d = [];
    end
end

function d = produitMatriciel(c, k, dE)
    d = dE{1};
    for j = 2:numel(dE)
        e = dE{j};
        if d(2) ~= e(1)
            if prod(d) == 1 || prod(e) == 1
                d = e .* (prod(d) == 1) + d .* (prod(d) ~= 1);
                continue
            end
            erreurMatrice(c, k, sprintf('%s multiplie %s', texteDims(d), texteDims(e)));
        end
        d = [d(1) e(2)];
    end
end

function erreurMatrice(c, k, detail)
    error('Simulink:Engine:DimensionMismatch', ...
          'Produit matriciel impossible dans ''%s'' : %s.', c.chemins{k}, detail);
end

% Les matrices d'une représentation d'état, vérifiées : A carrée, B, C et D
% de tailles accordées. D donnée scalaire nulle s'étend.
function [A, B, C, D] = matricesEtat(p, chemin)
    A = double(p.A);
    B = double(p.B);
    C = double(p.C);
    D = double(p.D);
    n = size(A, 1);
    if size(A, 2) ~= n
        error('Simulink:blocks:StateSpaceANotSquare', ...
              'La matrice A de ''%s'' doit etre carree ; elle est de taille %s.', ...
              chemin, mat2str(size(A)));
    end
    if n > 0
        if size(B, 1) ~= n
            error('Simulink:blocks:StateSpaceBDimension', ...
                  'La matrice B de ''%s'' doit avoir %d ligne(s), autant que A.', chemin, n);
        end
        if size(C, 2) ~= n
            error('Simulink:blocks:StateSpaceCDimension', ...
                  'La matrice C de ''%s'' doit avoir %d colonne(s), autant que A.', chemin, n);
        end
    end
    if isscalar(D) && D == 0 && ~(size(C, 1) == 1 && size(B, 2) == 1)
        D = zeros(size(C, 1), size(B, 2));
    end
    if n > 0 && ~isequal(size(D), [size(C, 1), size(B, 2)])
        error('Simulink:blocks:StateSpaceDDimension', ...
              'La matrice D de ''%s'' doit etre de taille %s.', chemin, ...
              mat2str([size(C, 1), size(B, 2)]));
    end
end

% === périodes d'échantillonnage ===============================================
%
% Chaque bloc a une cadence : 0 s'il est continu, une période s'il est
% échantillonné, Inf s'il est constant. Les blocs qui n'en disent rien
% héritent de ce qui les alimente : continus si une entrée l'est, sinon au
% rythme de l'entrée la plus rapide. Une période qui n'est pas un multiple
% du pas fixe est refusée, comme dans Simulink : le bloc tomberait entre
% deux pas.
function c = periodes(c, pas, verifier)
    if nargin < 3
        verifier = true;   % faux : les périodes seules, sans les rapporter au pas
    end
    n = c.n;
    c.cadence = -ones(1, n);
    c.decalage = zeros(1, n);
    c.majeurSeul = false(1, n);
    for k = 1:n
        enCours('bloc', k);
        p = c.p{k};
        t = c.types{k};
        switch t
            case {'constant', 'ground'}
                c.cadence(k) = Inf;
                if isfield(p, 'SampleTime') && isfinite(p.SampleTime(1)) && p.SampleTime(1) > 0
                    c.cadence(k) = p.SampleTime(1);
                end
            case {'step', 'ramp', 'sine', 'clock', 'repeatingsequence', 'inport', ...
                  'fromworkspace'}
                c.cadence(k) = 0;
                if isfield(p, 'SampleTime') && p.SampleTime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                % À pas variable, une source qui casse ne change qu'aux pas
                % majeurs : le solveur s'arrête sur chaque cassure, et les
                % pas mineurs du pas qui y mène ne voient pas la valeur
                % d'après — comme le mode figé d'un bloc de Simulink.
                if c.variable && (strcmp(t, 'step') || ...
                                  (strcmp(t, 'fromworkspace') && strcmp(p.Interpolate, 'off')))
                    c.majeurSeul(k) = true;
                end
            case 'pulsegenerator'
                c.cadence(k) = 0;
                if strcmp(p.PulseType, 'Sample based')
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                elseif c.variable
                    c.majeurSeul(k) = true;   % comme l'échelon
                end
            case {'digitalclock', 'randomnumber', 'uniformrandomnumber'}
                [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
            case {'integrator', 'transferfcn', 'statespace', 'zeropole', 'pidcontroller', ...
                  'secondorderintegrator', 'chirp'}
                c.cadence(k) = 0;
            case 'signalgenerator'
                c.cadence(k) = 0;
                c.majeurSeul(k) = strcmp(p.WaveForm, 'random');   % un tirage par pas majeur
            case {'counterfreerunning', 'counterlimited', 'repeatingsequencestair'}
                % Sans période donnée, une source hérite du pas de base : le
                % pas fixe, ou chaque pas majeur à pas variable.
                if p.tsamp(1) == -1 || p.tsamp(1) == 0
                    if c.variable
                        c.cadence(k) = 0;
                        c.majeurSeul(k) = true;
                    else
                        c.cadence(k) = pas;
                    end
                else
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.tsamp);
                end
            case 'datastoreread'
                c.cadence(k) = 0;
                if p.SampleTime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
            case 'datastorewrite'
                % L'écriture se fait aux pas majeurs, ou aux instants de sa
                % période : un pas mineur ne touche pas à la mémoire.
                c.majeurSeul(k) = true;
                if p.SampleTime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
            case {'datastorememory', 'width'}
                c.cadence(k) = Inf;
            case 'iterateur'
                % Un sous-système itéré calcule aux pas majeurs, ou aux
                % instants de la période qu'il hérite.
                c.majeurSeul(k) = true;
            case 'functioncallgenerator'
                if p.sample_time(1) <= 0
                    error('Simulink:blocks:FcnCallGenSampleTime', ...
                          'La periode du generateur d''appels ''%s'' doit etre positive.', ...
                          c.chemins{k});
                end
                if p.numberOfIterations ~= 1
                    error('Simulink:blocks:FcnCallGenIterations', ...
                          ['Le generateur ''%s'' appelle %g fois par instant : MatLibre ' ...
                           'n''appelle encore qu''une fois.'], c.chemins{k}, ...
                          p.numberOfIterations);
                end
                [c.cadence(k), c.decalage(k)] = lirePeriode(p.sample_time);
            case 'ratetransition'
                if p.OutPortSampleTime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.OutPortSampleTime);
                end
            case 'tappeddelay'
                if p.samptime(1) > 0
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.samptime);
                end
            case {'garde', 'if', 'switchcase'}
                % La condition d'un sous-système se décide aux pas majeurs :
                % entre deux, il garde son état, comme dans Simulink.
                c.cadence(k) = 0;
                c.majeurSeul(k) = true;
            case {'enableport', 'triggerport', 'actionport'}
                c.cadence(k) = Inf;   % hors d'un sous-système : sans effet
            case {'sfunction', 'msfunction'}
                ts = c.fonctions{k}.ts;
                if ts(1) == -1
                    c.cadence(k) = -1;
                elseif ts(1) == 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = numel(ts) >= 2 && ts(2) == 1;   % [0 1] : aux pas majeurs
                else
                    [c.cadence(k), c.decalage(k)] = lirePeriode(ts);
                end
            case 'chart'
                % Un diagramme fait un pas par instant d'échantillonnage : à
                % ses instants s'il en a, sinon à chaque pas majeur.
                c.cadence(k) = -1;
                if p.SampleTime(1) ~= -1
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                c.majeurSeul(k) = true;
            case 'matlabfunction'
                c.cadence(k) = -1;
                if p.SampleTime(1) ~= -1
                    [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                end
                % Une fonction qui garde un état entre deux appels ne se
                % rappelle qu'aux pas majeurs : un pas mineur ne doit pas
                % faire avancer sa mémoire.
                if c.fonctions{k}.persistante
                    c.majeurSeul(k) = true;
                end
            case 'variabletransportdelay'
                c.cadence(k) = 0;   % lu à chaque passe, poussé aux pas majeurs
            case {'derivative', 'transportdelay', 'memory', 'ratelimiter', 'relay', ...
                  'backlash', 'hitcrossing', 'detectchange', 'detectincrease', ...
                  'detectdecrease'}
                % Continus pour ce qui les suit, mais calculés aux seuls pas
                % majeurs : ils comparent l'entrée à celle du pas précédent.
                % Le retard pur à pas variable fait exception : il lit son
                % tampon à chaque passe, pas mineurs compris, comme Simulink.
                c.cadence(k) = 0;
                c.majeurSeul(k) = ~(c.variable && strcmp(t, 'transportdelay'));
            case {'delay', 'discreteintegrator', 'discretetransferfcn', ...
                  'discretefilter', 'discretestatespace', 'zoh'}
                periode = p.SampleTime;
                if isempty(periode)
                    if strcmp(t, 'zoh')
                        periode = 10 * pas;
                    else
                        periode = pas;
                    end
                end
                if periode(1) == -1
                    c.cadence(k) = -1;
                elseif periode(1) == 0
                    error('Simulink:SampleTime:DiscreteBlockContinuous', ...
                          ['Le bloc ''%s'' est discret : sa periode d''echantillonnage ' ...
                           'ne peut pas etre nulle.'], c.chemins{k});
                else
                    [c.cadence(k), c.decalage(k)] = lirePeriode(periode);
                end
            otherwise
                if isfield(p, 'SampleTime') && ~isempty(p.SampleTime) && p.SampleTime(1) ~= -1
                    if p.SampleTime(1) == 0
                        c.cadence(k) = 0;
                    else
                        [c.cadence(k), c.decalage(k)] = lirePeriode(p.SampleTime);
                    end
                end
        end
    end
    % Dans un sous-système conditionnel, rien n'est constant : ce qui ne
    % change jamais doit encore se calculer quand le sous-système s'éveille.
    % Une constante y prend donc la cadence de sa garde, aux pas majeurs —
    % comme Simulink, où elle hérite de celle du sous-système.
    for k = find(c.garde > 0 & isinf(c.cadence))
        c.cadence(k) = 0;
        c.majeurSeul(k) = true;
    end
    % L'héritage : on propage jusqu'à ce que plus rien ne change.
    for tour = 1:(n + 2)
        change = false;
        for k = find(c.cadence == -1)
            e = c.entrees{k};
            e = e(e > 0);
            if isempty(e)
                c.cadence(k) = Inf;
                if c.garde(k) > 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = true;
                end
                change = true;
                continue
            end
            sources = c.proprio(e);
            cad = c.cadence(sources);
            if any(cad == 0)
                c.cadence(k) = 0;
            elseif any(cad == -1)
                continue
            elseif all(isinf(cad))
                c.cadence(k) = Inf;
                if c.garde(k) > 0
                    c.cadence(k) = 0;
                    c.majeurSeul(k) = true;
                end
            else
                finies = cad(isfinite(cad) & cad > 0);
                c.cadence(k) = min(finies);
            end
            change = true;
        end
        if ~change
            break
        end
    end
    c.cadence(c.cadence == -1) = 0;   % une boucle d'héritiers : continue

    % Un IC ne se calcule pas une fois pour toutes : il rend sa valeur au
    % premier instant, puis son entrée, fût-elle constante. Un sous-système
    % itéré non plus : ses états avancent à chaque pas ; ni une fonction qui
    % garde un état — une détection de front, une transmittance discrète.
    for k = find(isinf(c.cadence))
        if any(strcmp(c.types{k}, {'ic', 'iterateur'})) || ...
           (strcmp(c.types{k}, 'matlabfunction') && c.fonctions{k}.persistante)
            c.cadence(k) = 0;
            c.majeurSeul(k) = true;
        end
    end
    % Les blocs discrets par nature qui héritent leur période ne peuvent
    % hériter d'un signal continu : Simulink le refuse, et le dit.
    for k = find(ismember(c.types, {'discretederivative', 'difference', 'tappeddelay'}))
        if c.cadence(k) == 0 && c.garde(k) == 0
            error('Simulink:SampleTime:DiscreteBlockContinuous', ...
                  ['Le bloc ''%s'' est discret, et herite de son entree une periode ' ...
                   'continue. Donnez-lui une periode, ou echantillonnez son entree ' ...
                   '(Zero-Order Hold, Rate Transition).'], c.chemins{k});
        end
    end
    % Le Rate Transition : vers une période plus lente, il tient l'entrée à
    % ses instants ; vers une plus rapide, il la retarde d'une période de
    % l'entrée, ce qui rend le transfert déterministe.
    c.periodeEntree = zeros(1, n);
    c.decalageEntree = zeros(1, n);
    for k = find(strcmp(c.types, 'ratetransition'))
        e = c.entrees{k};
        if isempty(e) || e(1) == 0
            continue
        end
        source = c.proprio(e(1));
        c.periodeEntree(k) = c.cadence(source);
        c.decalageEntree(k) = c.decalage(source);
    end

    c.periodePas = zeros(1, n);
    c.decalagePas = zeros(1, n);
    for k = 1:n
        if c.cadence(k) > 0 && isfinite(c.cadence(k)) && ...
           (c.decalage(k) < 0 || c.decalage(k) >= c.cadence(k))
            error('Simulink:SampleTime:InvalidOffset', ...
                  ['Le decalage %g de la periode de ''%s'' doit etre positif et ' ...
                   'inferieur a la periode %g : [periode, decalage] avec 0 <= decalage ' ...
                   '< periode.'], c.decalage(k), c.chemins{k}, c.cadence(k));
        end
        if c.variable && c.cadence(k) > 0 && isfinite(c.cadence(k))
            % À pas variable, le solveur s'arrête sur chaque instant
            % d'échantillonnage : une période n'a rien à diviser.
            c.majeurSeul(k) = true;
        elseif verifier && c.cadence(k) > 0 && isfinite(c.cadence(k))
            rapport = c.cadence(k) / pas;
            if abs(rapport - round(rapport)) > 1e-9 * max(1, rapport) || round(rapport) < 1
                error('Simulink:SampleTime:NotMultipleOfFixedStep', ...
                      ['La periode d''echantillonnage %g de ''%s'' n''est pas un multiple ' ...
                       'entier du pas fixe %g du modele ''%s''. Choisissez un pas qui la ' ...
                       'divise.'], c.cadence(k), c.chemins{k}, pas, c.nom);
            end
            c.periodePas(k) = round(rapport);
            decal = c.decalage(k) / pas;
            if abs(decal - round(decal)) > 1e-9 * max(1, decal)
                error('Simulink:SampleTime:NotMultipleOfFixedStep', ...
                      ['Le decalage %g de la periode de ''%s'' n''est pas un multiple ' ...
                       'entier du pas fixe %g.'], c.decalage(k), c.chemins{k}, pas);
            end
            c.decalagePas(k) = round(decal);
            c.majeurSeul(k) = true;
        elseif isinf(c.cadence(k))
            c.majeurSeul(k) = true;
        end
    end
end

% La plage de sortie d'un bloc : OutMin et OutMax, des nombres réels —
% un par élément, ou un pour tous —, vides pour ne rien borner. La valeur
% d'un Constant doit s'y tenir, comme Simulink le vérifie à la compilation.
function P = plageDeSortie(type, p, chemin)
    P = [];
    if ~isfield(p, 'OutMin') || (isempty(p.OutMin) && isempty(p.OutMax))
        return
    end
    bas = p.OutMin;
    haut = p.OutMax;
    valide = @(v) isempty(v) || ((isnumeric(v) || islogical(v)) && isreal(v) && ...
                                 isvector(v) && ~any(isnan(double(v(:)))));
    if ~valide(bas) || ~valide(haut)
        error('Simulink:blocks:InvalidOutMinMax', ...
              ['OutMin et OutMax de ''%s'' sont des nombres reels — un par element, ou un ' ...
               'pour tous —, ou vides.'], chemin);
    end
    if isempty(bas)
        bas = -Inf;
    end
    if isempty(haut)
        haut = Inf;
    end
    bas = double(bas(:));
    haut = double(haut(:));
    if numel(bas) ~= numel(haut) && numel(bas) > 1 && numel(haut) > 1
        error('Simulink:blocks:InvalidOutMinMax', ...
              'OutMin et OutMax de ''%s'' n''ont pas le meme nombre d''elements.', chemin);
    end
    if any(bas > haut)
        error('Simulink:blocks:InvalidOutMinMax', ...
              'OutMin de ''%s'' depasse son OutMax : la plage [%s, %s] est vide.', chemin, ...
              mat2str(bas.'), mat2str(haut.'));
    end
    P = struct('bas', bas, 'haut', haut);
    if strcmp(type, 'constant') && (isnumeric(p.Value) || islogical(p.Value)) && ...
       isreal(p.Value)
        v = double(p.Value(:));
        if (numel(bas) == 1 || numel(bas) == numel(v)) && ...
           (numel(haut) == 1 || numel(haut) == numel(v)) && any(v < bas | v > haut)
            error('Simulink:Parameters:ValueOutsideOutMinMax', ...
                  ['La valeur %s du Constant ''%s'' sort de la plage [%s, %s] que donnent ' ...
                   'OutMin et OutMax.'], mat2str(p.Value), chemin, mat2str(bas.'), ...
                  mat2str(haut.'));
        end
    end
end

% Les transitions de cadence, comme Simulink les voit : la sortie d'un bloc
% discret lue par un bloc discret d'une autre période ou d'un autre
% décalage, sans Rate Transition entre eux — un Zero-Order Hold plus lent
% que sa source en tient lieu. En multitâche (EnableMultiTasking, à pas
% fixe), MultiTaskRateTransMsg en décide, et AutoInsertRateTranBlk y pose
% des Rate Transition (AINSERER) ; en monotâche, SingleTaskRateTransMsg.
% Les blocs virtuels — Mux, Demux, bus, Goto, From — se traversent : la
% transition est entre les blocs qui calculent. Ceux d'un sous-système
% conditionnel suivent sa garde, et ne comptent pas.
function c = transitionsDeCadence(c, config, silencieux, posees)
    c.aInserer = struct('chemin', {}, 'port', {}, 'periode', {}, 'decalage', {});
    if ~isfield(config, 'EnableMultiTasking')
        return
    end
    multitache = strcmp(config.EnableMultiTasking, 'on') && ~c.variable;
    if multitache
        niveau = 1 + strcmp(config.MultiTaskRateTransMsg, 'error');
        auto = strcmp(config.AutoInsertRateTranBlk, 'on') && ~posees;
    else
        niveau = find(strcmp({'none', 'warning', 'error'}, config.SingleTaskRateTransMsg)) - 1;
        auto = false;
    end
    if niveau == 0 && ~auto
        return
    end
    virtuels = {'mux', 'demux', 'buscreator', 'busselector', 'from', 'goto', 'bustovector'};
    discret = c.cadence > 0 & isfinite(c.cadence);
    for k = 1:c.n
        if ~discret(k) || c.garde(k) > 0 || ...
           any(strcmp(c.types{k}, [virtuels, {'ratetransition'}]))
            continue
        end
        for j = 1:numel(c.entrees{k})
            if c.entrees{k}(j) == 0
                continue
            end
            % les blocs qui calculent derrière cette entrée
            pile = c.proprio(c.entrees{k}(j));
            vus = [];
            sources = [];
            while ~isempty(pile)
                s = pile(end);
                pile(end) = [];
                if any(vus == s)
                    continue
                end
                vus(end + 1) = s; %#ok<AGROW>
                if any(strcmp(c.types{s}, virtuels))
                    e = c.entrees{s};
                    pile = [pile, c.proprio(e(e > 0))]; %#ok<AGROW>
                else
                    sources(end + 1) = s; %#ok<AGROW>
                end
            end
            for s = sources
                tolerance = 1e-9 * c.cadence(k);
                if ~discret(s) || c.garde(s) > 0 || ...
                   (abs(c.cadence(s) - c.cadence(k)) <= tolerance && ...
                    abs(c.decalage(s) - c.decalage(k)) <= tolerance)
                    continue
                end
                if strcmp(c.types{k}, 'zoh') && c.cadence(k) > c.cadence(s)
                    continue   % un bloqueur plus lent que sa source : du rapide au lent
                end
                if auto
                    c.aInserer(end + 1) = struct('chemin', c.noms{k}, 'port', j, ...
                                                 'periode', c.cadence(k), ...
                                                 'decalage', c.decalage(k));
                    break
                end
                if multitache
                    reglage = ['en multitache, il y faut un bloc Rate Transition — ' ...
                               'AutoInsertRateTranBlk (''on'') le pose ; ' ...
                               'MultiTaskRateTransMsg regle ce diagnostic'];
                else
                    reglage = ['il y faut un bloc Rate Transition ; SingleTaskRateTransMsg ' ...
                               'regle ce diagnostic'];
                end
                texte = sprintf(['Transition de cadence illegale entre la sortie de ''%s'' ' ...
                                 '(periode %g) et l''entree %d de ''%s'' (periode %g) : %s.'], ...
                                c.chemins{s}, c.cadence(s), j, c.chemins{k}, c.cadence(k), ...
                                reglage);
                if niveau == 2
                    error('Simulink:SampleTime:IllegalRateTransition', '%s', texte);
                elseif niveau == 1 && ~silencieux
                    warning('Simulink:SampleTime:IllegalRateTransition', '%s', texte);
                end
            end
        end
    end
end

% Les Rate Transition qu'insère AutoInsertRateTranBlk : chacun sur l'entrée
% du bloc qui lit, dans le système où ce bloc se trouve, à la période de ce
% bloc.
function modele = insererTransitions(modele, liste)
    for q = 1:numel(liste)
        modele = insererTransition(modele, strsplit(liste(q).chemin, '/'), liste(q), q);
    end
end

function modele = insererTransition(modele, parties, T, rang)
    noms = cellfun(@(b) char(b.nom), modele.blocs, 'UniformOutput', false);
    if numel(parties) > 1
        i = find(strcmp(noms, parties{1}), 1);
        if isempty(i) || ~isfield(modele.blocs{i}.parametres, 'Model')
            return
        end
        b = modele.blocs{i};
        b.parametres.Model = insererTransition(b.parametres.Model, parties(2:end), T, rang);
        modele.blocs{i} = b;
        return
    end
    kb = find(strcmp(noms, parties{1}), 1);
    liens = matlibre_sl_liens(modele);
    l = find(liens(:, 2) == kb & liens(:, 3) == T.port, 1);
    if isempty(kb) || isempty(l)
        return
    end
    source = noms{liens(l, 1)};
    ps = liens(l, 4);
    nom = sprintf('RateTransitionAuto%d', rang);
    while any(strcmp(noms, nom))
        nom = [nom '_']; %#ok<AGROW>
    end
    modele = add_block(modele, 'ratetransition', nom, 'OutPortSampleTime', ...
                       [T.periode, T.decalage]);
    modele = delete_line(modele, sprintf('%s/%d', source, ps), ...
                         sprintf('%s/%d', parties{1}, T.port));
    modele = add_line(modele, sprintf('%s/%d', source, ps), [nom '/1']);
    modele = add_line(modele, [nom '/1'], sprintf('%s/%d', parties{1}, T.port));
end

function [periode, decalage] = lirePeriode(v)
    v = double(v);
    periode = v(1);
    decalage = 0;
    if numel(v) >= 2
        decalage = v(2);
    end
end

% FixedStep 'auto', comme dans Simulink : le pas fondamental, plus grand
% commun diviseur des périodes d'échantillonnage du modèle et de leurs
% décalages. Sans période, la durée en cinquante pas — 0,2 s sans fin —, au
% plus le tiers de la période de la sinusoïde la plus rapide d'un Sine
% Wave ou d'un Signal Generator. Les périodes se lisent comme à la
% compilation ; celles qu'un bloc tient du pas lui-même ne comptent pas.
function pas = pasFondamental(c, tDebut, tFinal)
    essai = periodes(c, Inf, false);
    valeurs = [essai.cadence(essai.cadence > 0 & isfinite(essai.cadence)), ...
               essai.decalage(essai.decalage > 0 & isfinite(essai.decalage))];
    if ~isempty(valeurs)
        pas = pgcdReel(valeurs);
        return
    end
    pas = 0.2;
    if isfinite(tFinal) && tFinal > tDebut
        pas = (tFinal - tDebut) / 50;
    end
    frequence = 0;   % en hertz
    for k = 1:c.n
        p = c.p{k};
        switch c.types{k}
            case 'sine'
                frequence = max(frequence, max(abs(double(p.Frequency(:)))) / (2 * pi));
            case 'signalgenerator'
                f = max(abs(double(p.Frequency(:))));
                if strcmp(p.Units, 'rad/sec')
                    f = f / (2 * pi);
                end
                frequence = max(frequence, f);
        end
    end
    if frequence > 0
        pas = min(pas, 1 / (3 * frequence));
    end
end

% Le plus grand commun diviseur de périodes réelles : en entiers quand
% elles sont décimales, sinon par Euclide, un reste sous la précision des
% périodes valant zéro.
function g = pgcdReel(v)
    for echelle = 10 .^ (0:9)
        e = v * echelle;
        if all(abs(e - round(e)) <= 1e-9 * max(1, e))
            e = round(e);
            g = e(1);
            for x = e(2:end)
                while x ~= 0
                    [g, x] = deal(x, mod(g, x));
                end
            end
            g = g / echelle;
            return
        end
    end
    g = v(1);
    for x = v(2:end)
        a = max(g, x);
        b = min(g, x);
        tolerance = 1e-9 * a;
        while b > tolerance
            r = mod(a, b);
            if r > b - tolerance
                r = 0;
            end
            a = b;
            b = r;
        end
        g = a;
    end
end

% === ce que le calcul lira ===================================================
%
% Chaque bloc est ramené à des nombres : un segment de paramètres (SEG),
% un code d'opération (SUB), et deux sortes d'états. Les états continus
% forment un seul vecteur, celui qu'intègre le solveur. Les autres —
% tampons des retards, valeurs tenues, modes des relais — forment un
% second vecteur, que la mise à jour fait avancer aux pas majeurs. Tout
% est vérifié ici, une fois : pendant la simulation il ne reste que de
% l'arithmétique.
%
% La disposition de chaque segment est décrite à côté du bloc ; c'est
% celle que lit MATLIBRE_SL_EXECUTER.
function c = abaisser(c, pas, tDebut)
    n = c.n;
    c.objets = cell(1, n);
    c.xA = zeros(1, n);
    c.xB = zeros(1, n);
    c.x0 = zeros(0, 1);
    c.seg = cell(1, n);
    c.sub = zeros(1, n);
    c.z0 = cell(1, n);
    for k = 1:n
        enCours('bloc', k);
        p = c.p{k};
        w = sortieLargeur(c, k);
        ch = c.chemins{k};
        seg = zeros(0, 1);
        z0 = zeros(0, 1);
        sub = 0;
        switch c.types{k}
            % --- sources ---
            case 'constant'
                seg = double(p.Value(:));
                type = c.typePort(c.portDebut(k));
                if type > 100 && type <= 200
                    seg = double(matlibre_sl_types('convertir', type, seg));
                end
            case 'step'                   % [Time; Before; After], w chacun
                seg = [etendre(p.Time, w, ch, 'Time'); etendre(p.Before, w, ch, 'Before'); ...
                       etendre(p.After, w, ch, 'After')];
            case 'ramp'                   % [Slope; Start; InitialOutput]
                seg = [etendre(p.Slope, w, ch, 'Slope'); etendre(p.Start, w, ch, 'Start'); ...
                       etendre(p.InitialOutput, w, ch, 'InitialOutput')];
            case 'sine'                   % [Amplitude; Frequency; Phase; Bias]
                seg = [etendre(p.Amplitude, w, ch, 'Amplitude'); ...
                       etendre(p.Frequency, w, ch, 'Frequency'); ...
                       etendre(p.Phase, w, ch, 'Phase'); etendre(p.Bias, w, ch, 'Bias')];
            case 'pulsegenerator'         % [Amplitude; Period; PulseWidth; PhaseDelay; Ts]
                periode = etendre(p.Period, w, ch, 'Period');
                largeur = etendre(p.PulseWidth, w, ch, 'PulseWidth');
                if any(periode <= 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La periode du generateur d''impulsions ''%s'' doit etre positive.', ch);
                end
                sub = 1 + strcmp(p.PulseType, 'Sample based');
                if sub == 1 && any(largeur < 0 | largeur > 100)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['La largeur d''impulsion de ''%s'' est un pourcentage de la ' ...
                           'periode, entre 0 et 100.'], ch);
                end
                seg = [etendre(p.Amplitude, w, ch, 'Amplitude'); periode; largeur; ...
                       etendre(p.PhaseDelay, w, ch, 'PhaseDelay'); c.cadence(k)];
            case 'repeatingsequence'      % [n; instants; valeurs]
                tv = double(p.rep_seq_t(:));
                yv = double(p.rep_seq_y(:));
                if numel(tv) ~= numel(yv) || numel(tv) < 2 || any(diff(tv) < 0) || ...
                        tv(end) <= tv(1)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['Les instants et les valeurs de ''%s'' doivent avoir la meme ' ...
                           'longueur, au moins deux points, et des instants croissants.'], ch);
                end
                seg = [numel(tv); tv; yv];
            case {'randomnumber', 'uniformrandomnumber'}
                % Le tirage suit Park et Miller, un générateur que tout le
                % monde peut refaire : l'état de chaque élément est dans Z,
                % avec la valeur courante. SEG : [gaussien; moyenne ou
                % minimum; variance ou maximum], w chacun.
                gaussien = strcmp(c.types{k}, 'randomnumber');
                if gaussien
                    un = etendre(p.Mean, w, ch, 'Mean');
                    deux = etendre(p.Variance, w, ch, 'Variance');
                    if any(deux < 0)
                        error('Simulink:Parameters:InvalidValue', ...
                              'La variance de ''%s'' ne peut pas etre negative.', ch);
                    end
                else
                    un = etendre(p.Minimum, w, ch, 'Minimum');
                    deux = etendre(p.Maximum, w, ch, 'Maximum');
                end
                seg = [double(gaussien); un; deux];
                graines = etendre(p.Seed, w, ch, 'Seed');
                etatsPM = mod(floor(abs(graines)), 2147483646) + 1;
                [valeurs, etatsPM] = matlibre_sl_hasard(etatsPM, gaussien, un, deux);
                z0 = [etatsPM; valeurs];
            case 'inport'
                seg = etendre(p.Value, w, ch, 'Value');
            case 'fromworkspace'          % [n; w; interpole; apres; temps; valeurs]
                [temps, valeurs] = lireSignalEspace(p, ch);
                apres = find(strcmp(p.OutputAfterFinalValue, ...
                                    {'Setting to zero', 'Holding final value', ...
                                     'Extrapolation'})) - 1;
                seg = [numel(temps); size(valeurs, 2); strcmp(p.Interpolate, 'on'); apres; ...
                       temps; valeurs(:)];
                z0 = 1;   % le rang du dernier instant atteint, pour ne pas chercher
            % --- opérations ---
            case 'gain'                   % [lignes; colonnes; K(:)]
                K = double(p.Gain);
                if c.entrees{k}(1) > 0 && c.typePort(c.entrees{k}(1)) > 100 && ...
                   c.typePort(c.entrees{k}(1)) <= 200
                    % une entrée à virgule fixe : le gain sur la grille de
                    % son propre type, comme Simulink le range
                    typeK = matlibre_sl_types('parametreGain', p, ...
                                              c.typePort(c.entrees{k}(1)), ch);
                    K = double(matlibre_sl_types('convertir', typeK, K));
                end
                sub = find(strcmp(p.Multiplication, {'Element-wise(K.*u)', 'Matrix(K*u)', ...
                                                     'Matrix(u*K)', 'Matrix(K*u) (u vector)'}));
                seg = [size(K, 1); size(K, 2); K(:)];
            case 'sum'                    % [n; signes]
                signes = signesDe(p.Signs, '+-', c.nIn(k));
                if numel(signes) ~= c.nIn(k)
                    signes = ones(1, c.nIn(k));
                end
                seg = [c.nIn(k); signes(:)];
            case 'product'                % [n; operations; matriciel; dimensions]
                ops = signesDe(p.Inputs, '*/', c.nIn(k));
                if numel(ops) ~= c.nIn(k)
                    ops = ones(1, c.nIn(k));
                end
                matriciel = strcmp(p.Multiplication, 'Matrix(*)');
                d = zeros(2 * c.nIn(k), 1);
                for j = 1:c.nIn(k)
                    d(2 * j - 1:2 * j) = c.inDims{k}{j}(:);
                end
                seg = [c.nIn(k); ops(:); matriciel; d];
                sub = 1 + matriciel;
            case 'math'
                sub = find(strcmp(p.Operator, {'exp', 'log', '10^u', 'log10', 'magnitude^2', ...
                                               'square', 'sqrt', 'pow', 'conj', 'reciprocal', ...
                                               'hypot', 'rem', 'mod', 'transpose', 'hermitian'}));
                d = c.inDims{k}{1};
                seg = d(:);
            case 'trigonometry'
                sub = find(strcmp(p.Operator, {'sin', 'cos', 'tan', 'asin', 'acos', 'atan', ...
                                               'atan2', 'sinh', 'cosh', 'tanh', 'asinh', ...
                                               'acosh', 'atanh', 'sincos', ...
                                               'cos + jsin'}));
            case 'minmax'
                sub = 1 + strcmp(p.Function, 'max');
                seg = c.nIn(k);
            case 'bias'
                seg = etendre(p.Bias, w, ch, 'Bias');
            case 'rounding'
                sub = find(strcmp(p.Operator, {'floor', 'ceil', 'round', 'fix'}));
            case 'polynomial'
                coefs = double(p.coefs(:));
                if isempty(coefs)
                    coefs = 0;
                end
                seg = [numel(coefs); coefs];
            case 'sqrt'
                sub = find(strcmp(p.Operator, {'sqrt', 'signedSqrt', 'rSqrt'}));
            % --- non-linéarités ---
            case 'saturation'             % [haut; bas]
                haut = etendre(p.UpperLimit, w, ch, 'UpperLimit');
                bas = etendre(p.LowerLimit, w, ch, 'LowerLimit');
                if any(bas > haut)
                    error('Simulink:blocks:SaturationLimits', ...
                          ['La limite basse de ''%s'' depasse sa limite haute : la ' ...
                           'saturation n''a pas de sens.'], ch);
                end
                seg = [haut; bas];
            case 'deadzone'               % [haut; bas]
                haut = etendre(p.UpperValue, w, ch, 'UpperValue');
                bas = etendre(p.LowerValue, w, ch, 'LowerValue');
                if any(bas > haut)
                    error('Simulink:blocks:DeadZoneLimits', ...
                          'Le debut de la zone morte de ''%s'' depasse sa fin.', ch);
                end
                seg = [haut; bas];
            case 'relay'                  % [marche; arret; sortieMarche; sortieArret]
                marche = etendre(p.OnSwitch, w, ch, 'OnSwitch');
                arret = etendre(p.OffSwitch, w, ch, 'OffSwitch');
                if any(arret > marche)
                    error('Simulink:blocks:RelayOnOffSwitch', ...
                          ['Le seuil de marche de ''%s'' doit etre au-dessus de son seuil ' ...
                           'd''arret.'], ch);
                end
                seg = [marche; arret; etendre(p.OnOutput, w, ch, 'OnOutput'); ...
                       etendre(p.OffOutput, w, ch, 'OffOutput')];
                z0 = zeros(w, 1);
            case 'quantizer'
                q = etendre(p.QuantizationInterval, w, ch, 'QuantizationInterval');
                if any(q <= 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'Le pas de quantification de ''%s'' doit etre positif.', ch);
                end
                seg = q;
            case 'ratelimiter'            % [montee; descente]  Z : [parti; t; y]
                montee = etendre(p.RisingSlewLimit, w, ch, 'RisingSlewLimit');
                descente = etendre(p.FallingSlewLimit, w, ch, 'FallingSlewLimit');
                if any(montee < descente)
                    error('Simulink:Parameters:InvalidValue', ...
                          ['La pente de montee de ''%s'' doit etre au-dessus de sa pente ' ...
                           'de descente.'], ch);
                end
                seg = [montee; descente];
                z0 = [0; tDebut; etendre(p.InitialOutput, w, ch, 'InitialOutput')];
            case 'hitcrossing'            % [seuil]  Z : [parti; ecart precedent]
                seg = etendre(p.HitCrossingOffset, w, ch, 'HitCrossingOffset');
                sub = find(strcmp(p.HitCrossingDirection, {'rising', 'falling', 'either'}));
                z0 = [0; zeros(w, 1)];
            case 'backlash'               % [largeur]  Z : sortie tenue
                largeur = etendre(p.BacklashWidth, w, ch, 'BacklashWidth');
                if any(largeur < 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La largeur du jeu de ''%s'' ne peut pas etre negative.', ch);
                end
                seg = largeur;
                z0 = etendre(p.InitialOutput, w, ch, 'InitialOutput');
            case 'coulombfriction'        % [offset; gain]
                seg = [etendre(p.offset, w, ch, 'Offset'); etendre(p.gain, w, ch, 'Gain')];
            case 'lookup'                 % [n; interpolation; extrapolation; x; y]
                x = double(p.BreakpointsData(:));
                y = double(p.TableData(:));
                if numel(x) ~= numel(y)
                    error('Simulink:blocks:LookupTableDimensionMismatch', ...
                          ['Le bloc ''%s'' porte %d abscisses et %d valeurs : ' ...
                           'il en faut autant.'], ch, numel(x), numel(y));
                end
                if numel(x) < 2
                    error('Simulink:blocks:LookupTableDimensionMismatch', ...
                          'La table de ''%s'' demande au moins deux points.', ch);
                end
                if any(diff(x) <= 0)
                    error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                          ['Les abscisses de la table de ''%s'' doivent etre strictement ' ...
                           'croissantes.'], ch);
                end
                interpolation = find(strcmp(p.InterpMethod, {'Linear point-slope', ...
                                                             'Flat', 'Nearest'}));
                if isempty(interpolation)
                    interpolation = 1;   % « Linear », l'ancien nom de Simulink
                end
                seg = [numel(x); interpolation; 1 + strcmp(p.ExtrapMethod, 'Linear'); x; y];
            case 'lookup2d'               % [nr; ns; r; s; table(:)]
                r = double(p.BreakpointsForDimension1(:));
                s = double(p.BreakpointsForDimension2(:));
                T = double(p.Table);
                if ~isequal(size(T), [numel(r), numel(s)])
                    error('Simulink:blocks:LookupTableDimensionMismatch', ...
                          ['La table de ''%s'' est de taille %s ; ses abscisses en ' ...
                           'demandent %s.'], ch, mat2str(size(T)), mat2str([numel(r), numel(s)]));
                end
                if numel(r) < 2 || numel(s) < 2 || any(diff(r) <= 0) || any(diff(s) <= 0)
                    error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                          ['Les abscisses de la table de ''%s'' doivent etre au moins deux ' ...
                           'par dimension, et strictement croissantes.'], ch);
                end
                seg = [numel(r); numel(s); r; s; T(:)];
            % --- logique ---
            case 'logic'
                sub = find(strcmp(p.Operator, {'AND', 'OR', 'NAND', 'NOR', 'XOR', 'NXOR', 'NOT'}));
                seg = c.nIn(k);
            case 'relational'
                sub = find(strcmp(p.Operator, {'==', '~=', '<', '<=', '>=', '>'}));
            case 'comparetoconstant'
                sub = find(strcmp(p.relop, {'==', '~=', '<', '<=', '>=', '>'}));
                seg = etendre(p.const, w, ch, 'Constant');
            case 'comparetozero'
                sub = find(strcmp(p.relop, {'==', '~=', '<', '<=', '>=', '>'}));
            case {'detectchange', 'detectincrease', 'detectdecrease'}
                z0 = etendre(p.vinit, w, ch, 'InitialCondition');
            % --- aiguillage ---
            case 'switch'                 % [n; seuil]
                sub = find(strcmp(p.Criteria, {'u2 >= Threshold', 'u2 > Threshold', 'u2 ~= 0'}));
                seuil = double(p.Threshold(:));
                seg = [numel(seuil); seuil];
            case 'multiportswitch'
                % [données; base zéro; indices dits; port de plus; diagnostic;
                %  type de la commande; pour chaque port de données : n, ses
                %  indices]
                seg = segmentMultiport(c, k, p, ch);
            case 'demux'                  % [debut; fin] par sortie
                bornes = zeros(2 * c.nOut(k), 1);
                debut = 1;
                for q = 1:c.nOut(k)
                    L = c.largeur(c.portDebut(k) + q - 1);
                    bornes(2 * q - 1:2 * q) = [debut; debut + L - 1];
                    debut = debut + L;
                end
                seg = bornes;
            case 'busselector'            % comme un Demux, ou comme un Selector
                choix = elementsChoisis(c, k);
                if strcmp(p.OutputAsBus, 'on')
                    indices = [];
                    for q = 1:numel(choix)
                        indices = [indices, choix(q).debut:choix(q).debut + ...
                                   choix(q).largeur - 1]; %#ok<AGROW>
                    end
                    c.code(k) = 64;
                    seg = [numel(indices); indices(:)];
                else
                    bornes = zeros(2 * numel(choix), 1);
                    for q = 1:numel(choix)
                        bornes(2 * q - 1:2 * q) = [choix(q).debut; ...
                                                   choix(q).debut + choix(q).largeur - 1];
                    end
                    seg = bornes;
                end
            case 'datatypeconversion'     % [type; arrondi; saturation; SI; type d'entrée]
                arrondis = {'Zero', 'Nearest', 'Round', 'Floor', 'Ceiling', 'Convergent', ...
                            'Simplest'};
                typeEntree = 2;
                if c.entrees{k}(1) > 0
                    typeEntree = c.typePort(c.entrees{k}(1));
                end
                seg = [max(1, c.typePort(c.portDebut(k))); ...
                       find(strcmp(arrondis, p.RndMeth)); ...
                       strcmp(p.SaturateOnIntegerOverflow, 'on'); ...
                       strcmp(p.ConvertRealWorld, 'Stored Integer (SI)'); typeEntree];
                if seg(1) > 200
                    % vers un type énuméré : les valeurs de ses membres, que
                    % chaque entrée doit porter
                    valeurs = matlibre_sl_types('valeurs', seg(1));
                    seg = [seg; numel(valeurs); valeurs(:)];
                end
            case 'selector'               % [n; indices]
                indices = double(p.Indices(:));
                seg = [numel(indices); indices];
            case 'concatenate'            % [dimension; n; dimensions des entrees]
                sub = 1 + strcmp(p.Mode, 'Multidimensional array');
                d = zeros(2 * c.nIn(k), 1);
                for j = 1:c.nIn(k)
                    d(2 * j - 1:2 * j) = c.inDims{k}{j}(:);
                end
                seg = [double(p.ConcatenateDimension); c.nIn(k); d];
            case 'signalconversion'
                seg = c.nIn(k);
            case 'manualswitch'
                sub = 1 + strcmp(p.sw, '0');
            case 'directlookup'           % [dimensions; lignes; colonnes; table(:)]
                table = double(p.Table);
                if p.NumberOfTableDimensions == 1
                    table = table(:);
                end
                seg = [p.NumberOfTableDimensions; size(table, 1); size(table, 2); table(:)];
            case 'intervaltest'           % [haut; bas; fermé à droite; fermé à gauche]
                seg = [etendre(p.uplimit, w, ch, 'uplimit'); ...
                       etendre(p.lowlimit, w, ch, 'lowlimit'); ...
                       strcmp(p.IntervalClosedRight, 'on'); strcmp(p.IntervalClosedLeft, 'on')];
            case 'wraptozero'
                seg = etendre(p.Threshold, w, ch, 'Threshold');
            case 'ic'                     % [valeur]  Z : [passé]
                seg = surGrille(c, k, etendre(p.Value, w, ch, 'Value'));
                z0 = 0;
            case 'width'
                seg = largeurEntree(c, k, 1);
            case {'datastoreread', 'datastorewrite'}   % [mémoire; largeur]
                m = c.memoire(k);
                largeur = numel(c.p{m}.InitialValue);
                if strcmp(c.types{k}, 'datastorewrite')
                    lue = largeurEntree(c, k, 1);
                    if ~any(lue == [1 largeur])
                        error('Simulink:DataStores:DataStoreWidthMismatch', ...
                              ['''%s'' ecrit %d valeur(s) dans la memoire ''%s'', qui en ' ...
                               'porte %d.'], ch, lue, char(c.p{m}.DataStoreName), largeur);
                    end
                end
                seg = [m; largeur];
            case 'datastorememory'
                z0 = double(p.InitialValue(:));
            case 'ratetransition'         % [mode; période de l'entrée; décalage]  Z : [tenue]
                x0 = etendre(p.X0, w, ch, 'X0');
                lent = c.cadence(k) > 0 && isfinite(c.cadence(k)) && ...
                       c.periodeEntree(k) > c.cadence(k) + 1e-12 && ...
                       isfinite(c.periodeEntree(k)) && strcmp(p.Deterministic, 'on');
                sub = 1 + lent;
                seg = [c.periodeEntree(k); c.decalageEntree(k)];
                if lent
                    z0 = [x0; x0];   % la tenue, et l'entrée prise à l'instant lent
                end
            case 'iterateur'              % le modèle intérieur, prêt, dans objets
                entrees = c.entrees{k};
                dE = cell(1, numel(entrees));
                for j = 1:numel(entrees)
                    dE{j} = [1 1];
                    if entrees(j) > 0
                        dE{j} = c.dims{entrees(j)};
                    end
                end
                [~, ci, lesEntrees, lesSorties, iter] = interieurIterateur(c, k, dE);
                q = ci.p{iter};
                O = struct('T', matlibre_sl_executer('preparer', ci), 'entrees', lesEntrees, ...
                           'sorties', lesSorties, 'iter', iter, ...
                           'pour', strcmp(ci.types{iter}, 'foriterator'), ...
                           'remise', strcmp(q.ResetStates, 'reset'));
                if O.pour
                    O.externe = strcmp(q.IterationSource, 'external');
                    O.N = double(q.IterationLimit);
                    O.zero = strcmp(q.IndexMode, 'Zero-based');
                    if ~O.externe && (O.N < 0 || O.N ~= round(O.N))
                        error('Simulink:blocks:ForIteratorInvalidLimit', ...
                              'Le nombre d''iterations de ''%s'' est un entier positif.', ...
                              ci.chemins{iter});
                    end
                else
                    O.faire = strcmp(q.WhileBlockType, 'do-while');
                    O.max = double(q.MaxIters);
                    if O.max == 0 || O.max < -1 || O.max ~= round(O.max)
                        error('Simulink:blocks:WhileIteratorInvalidMax', ...
                              ['Le nombre maximal d''iterations de ''%s'' est un entier ' ...
                               'positif, ou -1 pour ne pas en mettre.'], ci.chemins{iter});
                    end
                end
                c.objets{k} = O;
            case {'foriterator', 'whileiterator'}   % [rang de l'itération]
                seg = 0;
            case 'functioncallgenerator'  % [période; décalage]
                seg = [c.cadence(k); c.decalage(k)];
            case 'chirp'                  % [f1; T; f2]
                seg = [etendre(p.f1, w, ch, 'f1'); etendre(p.T, w, ch, 'T'); ...
                       etendre(p.f2, w, ch, 'f2')];
                if any(seg(w + 1:2 * w) <= 0)
                    error('Simulink:Parameters:InvalidValue', ...
                          'Le temps cible T de ''%s'' doit etre positif.', ch);
                end
            case 'signalgenerator'        % [amplitude; pulsation]  Z (random) : [états; valeurs]
                sub = find(strcmp(p.WaveForm, {'sine', 'square', 'sawtooth', 'random'}));
                pulsation = etendre(p.Frequency, w, ch, 'Frequency');
                if strcmp(p.Units, 'Hertz')
                    pulsation = 2 * pi * pulsation;
                end
                amplitude = etendre(p.Amplitude, w, ch, 'Amplitude');
                seg = [amplitude; pulsation];
                if sub == 4
                    etats = (1:w).';
                    [valeurs, etats] = matlibre_sl_hasard(etats, false, -amplitude, amplitude);
                    z0 = [etats; valeurs];
                elseif sub > 1
                    z0 = zeros(w, 1);   % le morceau où l'on est, figé au pas majeur
                end
            case 'counterfreerunning'     % [modulo]  Z : [compte]
                if ~isscalar(p.NumBits) || ~(p.NumBits >= 1) || ...
                   p.NumBits ~= round(p.NumBits) || p.NumBits > 52
                    error('Simulink:Parameters:InvalidValue', ...
                          'Le nombre de bits de ''%s'' est un entier de 1 a 52.', ch);
                end
                seg = 2 ^ double(p.NumBits);
                z0 = 0;
            case 'counterlimited'         % [limite]  Z : [compte]
                if p.uplimit < 0 || p.uplimit ~= round(p.uplimit)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La limite du compteur ''%s'' est un entier positif.', ch);
                end
                seg = double(p.uplimit);
                z0 = 0;
            case 'repeatingsequencestair' % [n; valeurs]  Z : [rang]
                valeurs = double(p.OutValues(:));
                if isempty(valeurs)
                    error('Simulink:Parameters:InvalidValue', ...
                          'La suite de valeurs de ''%s'' est vide.', ch);
                end
                seg = [numel(valeurs); valeurs];
                z0 = 0;
            case 'secondorderintegrator'  % [largeur]  états : [x; dx]
                c = ajouterEtat(c, k, [etendre(p.ICX, w, ch, 'ICX'); ...
                                       etendre(p.ICDXDT, w, ch, 'ICDXDT')]);
                seg = w;
            case 'discretederivative'     % [K / Ts]  Z : [K u d'avant / Ts]
                seg = etendre(p.gainval, w, ch, 'gainval') / c.cadence(k);
                z0 = etendre(p.ICPrevScaledInput, w, ch, 'ICPrevScaledInput');
            case 'difference'             % Z : [u d'avant]
                z0 = etendre(p.ICPrevInput, w, ch, 'ICPrevInput');
            case 'tappeddelay'            % [N; plus récent d'abord; courant]  Z : [N valeurs]
                N = double(p.NumDelays);
                if N < 1 || N ~= round(N)
                    error('Simulink:Parameters:InvalidValue', ...
                          'Le nombre de retards de ''%s'' est un entier positif.', ch);
                end
                seg = [N; strcmp(p.DelayOrder, 'Newest'); strcmp(p.includeCurrent, 'on')];
                z0 = etendre(p.vinit, N, ch, 'vinit');
            % --- continu ---
            case 'integrator'             % [borne; haut; bas; remise; externe; wr; sat; etat]
                % Z, s'il y a remise ou condition initiale externe : [vu;
                % reset précédent (wr); instant de la remise; état d'avant
                % elle (w)].
                remise = find(strcmp(p.ExternalReset, {'rising', 'falling', 'either', ...
                                                       'level', 'level hold'}));
                if isempty(remise)
                    remise = 0;
                end
                externe = strcmp(p.InitialConditionSource, 'external');
                wr = 0;
                if remise > 0
                    wr = largeurEntree(c, k, 2);
                end
                if externe
                    x0 = zeros(w, 1);
                else
                    x0 = etendre(p.InitialCondition, w, ch, 'InitialCondition');
                end
                haut = etendre(p.UpperSaturationLimit, w, ch, 'UpperSaturationLimit');
                bas = etendre(p.LowerSaturationLimit, w, ch, 'LowerSaturationLimit');
                borne = strcmp(p.LimitOutput, 'on');
                if borne && any(bas > haut)
                    error('Simulink:blocks:IntegratorLimits', ...
                          'La borne basse de ''%s'' depasse sa borne haute.', ch);
                end
                if borne
                    x0 = min(max(x0, bas), haut);
                end
                c = ajouterEtat(c, k, x0);
                seg = [borne; haut; bas; remise; externe; wr; ...
                       strcmp(p.ShowSaturationPort, 'on'); strcmp(p.ShowStatePort, 'on')];
                if remise > 0 || externe
                    z0 = [0; zeros(wr, 1); -Inf; zeros(w, 1)];
                end
            case 'derivative'             % Z : [parti; t; u]
                z0 = [0; tDebut; zeros(largeurEntree(c, k, 1), 1)];
            case {'transferfcn', 'zeropole', 'statespace'}   % [nx; ny; nu; A; B; C; D]
                switch c.types{k}
                    case 'transferfcn'
                        [num, den] = transmittance(p.Numerator, p.Denominator, ch);
                        [A, B, C, D] = tf2ss(num, den);
                        x0 = zeros(size(A, 1), 1);
                    case 'zeropole'
                        lesZeros = double(p.Zeros(:));
                        lesPoles = double(p.Poles(:));
                        if numel(lesZeros) > numel(lesPoles)
                            error('Simulink:blocks:TransferFcnImproper', ...
                                  ['''%s'' porte plus de zeros que de poles : elle n''est ' ...
                                   'pas propre.'], ch);
                        end
                        [A, B, C, D] = zp2ss(lesZeros, lesPoles, double(p.Gain));
                        x0 = zeros(size(A, 1), 1);
                    otherwise
                        [A, B, C, D] = matricesEtat(p, ch);
                        x0 = double(p.X0(:));
                        if isempty(x0)
                            x0 = zeros(size(A, 1), 1);
                        elseif numel(x0) == 1 && size(A, 1) > 1
                            x0 = repmat(x0, size(A, 1), 1);
                        elseif numel(x0) ~= size(A, 1)
                            error('Simulink:blocks:StateSpaceX0Dimension', ...
                                  ['La condition initiale de ''%s'' porte %d valeur(s) pour ' ...
                                   '%d etat(s).'], ch, numel(x0), size(A, 1));
                        end
                end
                c = ajouterEtat(c, k, x0);
                seg = matricesSegment(A, B, C, D);
            case 'transportdelay'         % [retard; longueur; sortie initiale]  Z : [n; tampon]
                if p.DelayTime < 0
                    error('Simulink:blocks:TransportDelayNegativeDelay', ...
                          'Le bloc ''%s'' demande un retard negatif.', ch);
                end
                % [retard; longueur; sortie initiale w; tampon fixe]
                if c.variable
                    % À pas variable, le tampon garde les instants avec les
                    % valeurs, et grandit au besoin : il vit hors de Z, dans
                    % les tampons du simulateur. Sa longueur est la taille
                    % initiale, BufferSize.
                    longueur = max(16, round(double(p.BufferSize)));
                    seg = [p.DelayTime; longueur; ...
                           etendre(p.InitialOutput, w, ch, 'InitialOutput'); ...
                           strcmp(p.FixedBuffer, 'on')];
                else
                    longueur = ceil(p.DelayTime / pas - 1e-9) + 2;
                    seg = [p.DelayTime; longueur; ...
                           etendre(p.InitialOutput, w, ch, 'InitialOutput'); ...
                           strcmp(p.FixedBuffer, 'on')];
                    z0 = [0; zeros(w * longueur, 1)];
                end
            case 'variabletransportdelay'
                % [genre; retard maximal; taille; zéro direct; sortie
                % initiale w; tampon fixe]
                % Z : [échantillons depuis la remise; 0; retard vu] — les
                % échantillons eux-mêmes vivent hors de Z, dans les tampons
                % du simulateur : le tampon grandit au besoin, comme celui
                % de Simulink dont MaximumPoints n'est que la taille
                % initiale.
                tMax = double(p.MaximumDelay);
                if ~(isscalar(tMax) && tMax > 0)
                    error('Simulink:blocks:VariableTransportDelayMaximum', ...
                          'Le retard maximal de ''%s'' doit etre positif.', ch);
                end
                L = max(16, round(double(p.MaximumPoints)));
                genre = 1 + strcmp(p.VariableDelayType, 'Variable time delay');
                seg = [genre; tMax; L; strcmp(p.ZeroDelay, 'on'); ...
                       etendre(p.InitialOutput, w, ch, 'InitialOutput'); ...
                       strcmp(p.FixedBuffer, 'on')];
                z0 = [0; 0; NaN];
            case 'algebraicconstraint'    % [f(z) = z ; valeur de départ w]
                seg = [strcmp(p.Constraint, 'f(z) = z'); ...
                       etendre(p.InitialGuess, w, ch, 'InitialGuess')];
            case 'busassignment'          % [n; début, largeur par élément]
                seg = elementsAssignes(c, k);
            case 'pidcontroller'          % [P; I; D; N], w chacun
                % Les états sont ceux de Simulink : l'intégrale de I u, et
                % le filtre f de la dérivée, f' = N (D u - f).
                [P, I, D, N] = gainsPID(p, w, ch);
                xi = zeros(w, 1);
                xd = zeros(w, 1);
                if any(I ~= 0)
                    xi = etendre(p.InitialConditionForIntegrator, w, ch, ...
                                 'InitialConditionForIntegrator');
                end
                if any(N ~= 0)
                    xd = etendre(p.InitialConditionForFilter, w, ch, ...
                                 'InitialConditionForFilter');
                end
                c = ajouterEtat(c, k, [xi; xd]);
                seg = [P; I; D; N];
            % --- discret ---
            case 'delay'   % [L; taille; entrée d; activation; remise; externe; wr]
                % Z : [tete; tampon w x taille], puis, pour un retard qui
                % s'active, se remet ou lit sa condition initiale :
                % [sortie tenue w; premier; remise d'avant wr; désactivé]
                variable = strcmp(p.DelayLengthSource, 'Input port');
                L = double(p.DelayLength);
                if variable
                    L = double(p.DelayLengthUpperLimit);
                    if ~(isscalar(L) && L >= 1 && L == round(L))
                        error('Simulink:blocks:DelayLengthUpperLimit', ...
                              ['La longueur maximale du retard ''%s'' est un entier ' ...
                               'positif.'], ch);
                    end
                elseif ~(isscalar(L) && L >= 0 && L == round(L))
                    error('Simulink:Parameters:InvalidValue', ...
                          'La longueur de retard de ''%s'' est un entier positif ou nul.', ch);
                end
                active = strcmp(p.ShowEnablePort, 'on');
                remise = find(strcmp(p.ExternalReset, {'Rising', 'Falling', 'Either', ...
                                                       'Level', 'Level hold'}));
                if isempty(remise)
                    remise = 0;
                end
                externe = strcmp(p.InitialConditionSource, 'Input port');
                wr = 0;
                if remise > 0
                    wr = largeurEntree(c, k, 2 + variable + active);
                end
                avance = variable || active || remise > 0 || externe;
                seg = L;
                if avance
                    seg = [L; L; variable; active; remise; externe; wr];
                end
                if L > 0
                    ci = surGrille(c, k, double(p.InitialCondition));
                    if numel(ci) == w * L && L > 1 && ~variable
                        tampon = reshape(ci, w, L);
                    else
                        tampon = repmat(etendre(ci, w, ch, 'InitialCondition'), 1, L);
                    end
                    z0 = [1; tampon(:)];
                    if avance
                        z0 = [z0; tampon(:, end); 0; zeros(wr, 1); 0];
                    end
                end
            case 'memory'
                z0 = surGrille(c, k, etendre(p.InitialCondition, w, ch, 'InitialCondition'));
            case 'discreteintegrator'
                % [K T; méthode; bornée; haut w; bas w; remise; externe; wr;
                %  port de saturation; port d'état]
                % Z : état, puis, pour une remise ou une condition initiale
                % externe : [premier; remise d'avant wr; état d'avant la
                % remise w; instant de la remise]
                [methode, cumul] = methodeDTI(p.IntegratorMethod);
                K = double(p.Gain);
                if ~isscalar(K)
                    error('Simulink:blocks:DiscreteIntegratorGain', ...
                          'Le gain de l''integrateur ''%s'' est un scalaire.', ch);
                end
                if ~cumul
                    K = K * c.cadence(k);
                end
                borne = strcmp(p.LimitOutput, 'on');
                haut = etendre(p.UpperSaturationLimit, w, ch, 'UpperSaturationLimit');
                bas = etendre(p.LowerSaturationLimit, w, ch, 'LowerSaturationLimit');
                if borne && any(bas > haut)
                    error('Simulink:blocks:DiscreteIntegratorLimits', ...
                          ['La borne basse de l''integrateur ''%s'' depasse sa borne ' ...
                           'haute.'], ch);
                end
                remise = find(strcmp(p.ExternalReset, {'rising', 'falling', 'either', ...
                                                       'level', 'sampled level'}));
                if isempty(remise)
                    remise = 0;
                end
                externe = strcmp(p.InitialConditionSource, 'external');
                wr = 0;
                if remise > 0
                    wr = largeurEntree(c, k, 2);
                end
                seg = [K; methode; borne; haut; bas; remise; externe; wr; ...
                       strcmp(p.ShowSaturationPort, 'on'); strcmp(p.ShowStatePort, 'on')];
                ci = etendre(p.InitialCondition, w, ch, 'InitialCondition');
                if borne
                    ci = min(max(ci, bas), haut);
                end
                z0 = ci;
                if remise > 0 || externe
                    z0 = [ci; 0; zeros(wr, 1); ci; -Inf];
                end
            case {'discretetransferfcn', 'discretefilter'}   % [m; b; a]
                [b, a] = filtreDiscret(p.Numerator, p.Denominator, ...
                                       strcmp(c.types{k}, 'discretetransferfcn'), ch);
                seg = [numel(a) - 1; b(:); a(:)];
                z0 = zeros((numel(a) - 1) * w, 1);   % une colonne d'états par voie
            case 'discretestatespace'     % [nx; ny; nu; A; B; C; D]  Z : x
                [A, B, C, D] = matricesEtat(p, ch);
                x0 = double(p.X0(:));
                if isempty(x0)
                    x0 = zeros(size(A, 1), 1);
                elseif numel(x0) == 1 && size(A, 1) > 1
                    x0 = repmat(x0, size(A, 1), 1);
                elseif numel(x0) ~= size(A, 1)
                    error('Simulink:blocks:StateSpaceX0Dimension', ...
                          'La condition initiale de ''%s'' porte %d valeur(s) pour %d etat(s).', ...
                          ch, numel(x0), size(A, 1));
                end
                seg = matricesSegment(A, B, C, D);
                z0 = x0;
            % --- sorties ---
            case 'tofile'
                fichier = p.Filename;
                if ~(ischar(fichier) || isstring(fichier)) || isempty(strtrim(char(fichier))) || ...
                   any(char(fichier) < 32)
                    error('Simulink:blocks:ToFileInvalidFileName', ...
                          'Le bloc To File ''%s'' ne nomme pas de fichier ou il puisse ecrire.', ch);
                end
                if ~isvarname(char(p.MatrixName))
                    error('Simulink:blocks:ToFileInvalidName', ...
                          ['Le nom de variable ''%s'' du bloc To File ''%s'' n''est pas un ' ...
                           'nom valide.'], char(p.MatrixName), ch);
                end
            case 'toworkspace'
                if ~isvarname(char(p.VariableName))
                    error('Simulink:blocks:ToWorkspaceInvalidVariableName', ...
                          ['Le bloc ''%s'' veut ecrire dans ''%s'', qui n''est ' ...
                           'pas un nom de variable.'], ch, char(p.VariableName));
                end
            case 'assertion'   % [active; arreter; genre; min inclus; max inclus; n; min; n; max]
                bas = double(champ(p, 'Min', 0));
                haut = double(champ(p, 'Max', 0));
                seg = [strcmp(p.Enabled, 'on'); strcmp(p.StopWhenAssertionFail, 'on'); ...
                       champ(p, 'Genre', 0); champ(p, 'MinInclus', 1); champ(p, 'MaxInclus', 1); ...
                       numel(bas); bas(:); numel(haut); haut(:)];
            % --- sous-systèmes conditionnels ---
            case 'garde'                  % [enable; front; action; remise; largeur du front]
                % Z : [amorcée; active au pas d'avant; front d'avant]
                fronts = struct('none', 0, 'rising', 1, 'falling', 2, 'either', 3, ...
                                'function_call', 4);
                largeurFront = 0;
                if ~strcmp(p.Trigger, 'none')
                    largeurFront = largeurEntree(c, k, 1 + (p.Enable ~= 0));
                end
                seg = [p.Enable ~= 0; fronts.(strrep(p.Trigger, '-', '_')); p.Action ~= 0; ...
                       p.Reset ~= 0; ...
                       largeurFront];
                z0 = [0; 0; zeros(largeurFront, 1)];
            case 'if'                     % [entrées; conditions; sinon]
                [c.objets{k}, nCond] = conditionsSi(p, c.nIn(k), ch, c, k);
                seg = [c.nIn(k); nCond; strcmpi(p.ShowElse, 'on')];
            case 'switchcase'             % [cas; défaut]
                [c.objets{k}, classeCas] = casDe(p.CaseConditions, ch);
                typeEntree = 2;
                if c.entrees{k}(1) > 0
                    typeEntree = c.typePort(c.entrees{k}(1));
                    if c.largeur(c.entrees{k}(1)) ~= 1
                        error('Simulink:blocks:SwitchCaseInputNotScalar', ...
                              ['L''entree de ''%s'' porte %d valeurs : un Switch Case choisit ' ...
                               'son cas d''apres un scalaire.'], ch, ...
                              c.largeur(c.entrees{k}(1)));
                    end
                end
                accorderIndices(typeEntree, classeCas, ch, 'CaseConditions', 'cas');
                seg = [numel(c.objets{k}); strcmpi(p.ShowDefaultCase, 'on')];
            case {'fcn', 'interpretedmatlabfunction'}   % [largeur d'entrée]  poignée dans objets
                c.objets{k} = c.fonctions{k}.h;
                verifierCode(c, k, w);
                seg = largeurEntree(c, k, 1);
            case 'chart'                  % [entrées; sorties]  machine dans objets
                c.objets{k} = c.fonctions{k};
                seg = [c.nIn(k); c.nOut(k)];
            case 'matlabfunction'         % [entrées; sorties]  poignée dans objets
                c.objets{k} = c.fonctions{k}.h;
                seg = [c.nIn(k); c.nOut(k)];
            case 'msfunction'             % [entrées; sorties]  le bloc dans objets
                x0 = matlibre_sl_msfonction('demarrer', c.fonctions{k}, ch);
                c = ajouterEtat(c, k, x0);
                c.objets{k} = c.fonctions{k};
                seg = [c.nIn(k); c.nOut(k)];
            case 'sfunction'              % [continus; discrets; sorties; entrées]
                T0 = c.fonctions{k};
                nc = T0.tailles(1);
                nd = T0.tailles(2);
                c.objets{k} = struct('f', T0.h, 'p', {T0.parametres});
                c = ajouterEtat(c, k, T0.x0(1:nc));
                z0 = T0.x0(nc + 1:nc + nd);
                seg = [nc; nd; w * (c.nOut(k) > 0); T0.tailles(4)];
            case 'merge'                  % [entrées; valeur initiale (w); garde de chaque source]
                seg = [c.nIn(k); etendre(initialeEnum(c, k, p, 'InitialOutput'), w, ch, ...
                                         'InitialOutput'); ...
                       gardesDesSources(c, k)];
        end
        c.seg{k} = double(seg(:));
        c.sub(k) = sub;
        c.z0{k} = double(z0(:));
    end
end

% Une représentation d'état en un segment : ses tailles, puis ses quatre
% matrices par colonnes.
function seg = matricesSegment(A, B, C, D)
    nx = size(A, 1);
    ny = size(C, 1);
    nu = size(B, 2);
    if nx == 0
        ny = size(D, 1);
        nu = size(D, 2);
    end
    if isscalar(D) && (ny ~= 1 || nu ~= 1)
        D = repmat(D, ny, nu);
    end
    seg = [nx; ny; nu; A(:); B(:); C(:); D(:)];
end

function c = ajouterEtat(c, k, x0)
    if isempty(x0)
        return   % une transmittance réduite à un gain n'a pas d'état
    end
    debut = numel(c.x0) + 1;
    c.x0 = [c.x0; x0(:)];
    c.xA(k) = debut;
    c.xB(k) = numel(c.x0);
end

function w = sortieLargeur(c, k)
    if c.nOut(k) >= 1
        w = c.largeur(c.portDebut(k));
    elseif c.nIn(k) >= 1
        w = largeurEntree(c, k, 1);
    else
        w = 1;
    end
end

function w = largeurEntree(c, k, j)
    e = c.entrees{k};
    if j > numel(e) || e(j) == 0
        w = 1;
    else
        w = c.largeur(e(j));
    end
end

% Une valeur donnée scalaire s'étend à toute la largeur du signal ; donnée
% vecteur, elle doit en avoir la largeur.
function v = etendre(v, w, chemin, nom)
    v = double(v(:));
    if numel(v) == 1
        v = repmat(v, w, 1);
    elseif numel(v) ~= w
        error('Simulink:Engine:DimensionMismatch', ...
              ['Le parametre %s de ''%s'' porte %d valeur(s) pour un signal de ' ...
               'largeur %d.'], nom, chemin, numel(v), w);
    end
end

% Les signes d'une sommation ou d'un produit, en +1 et -1 : « +- » donne
% [1 -1], « **/ » donne [1 1 -1].
function s = signesDe(v, admis, n)
    if isnumeric(v)
        s = ones(1, n);
        return
    end
    texte = char(v);
    valeur = str2double(texte);
    if ~isnan(valeur) && all(ismember(texte, '0123456789 '))
        s = ones(1, n);
        return
    end
    texte = texte(ismember(texte, admis));
    s = ones(1, numel(texte));
    s(texte == admis(2)) = -1;
end

% === ordre de calcul et boucles algébriques ===================================
%
% Le graphe des dépendances va d'un bloc à ceux qui lisent sa sortie à
% l'instant même. Ses composantes fortement connexes sont les boucles
% algébriques ; hors d'elles, un tri topologique ordonne le calcul. Chaque
% boucle est coupée en quelques blocs, dont les sorties deviennent les
% inconnues qu'une méthode de Newton ajuste à chaque pas.
function c = ordonner(c)
    n = c.n;
    succ = cell(1, n);
    for k = 1:n
        succ{k} = [];
    end
    for k = 1:n
        if ~c.direct(k)
            continue
        end
        e = c.entrees{k};
        for j = 1:numel(e)
            if e(j) > 0
                a = c.proprio(e(j));
                succ{a}(end + 1) = k;
            end
        end
        % Un bloc gardé lit la garde de son sous-système : elle calcule
        % avant lui. Un Merge lit celles de ses sources.
        if c.garde(k) > 0
            succ{c.garde(k)}(end + 1) = k;
        end
        if strcmp(c.types{k}, 'merge')
            for g = unique(c.seg{k}(end - c.nIn(k) + 1:end)).'
                if g > 0
                    succ{g}(end + 1) = k;
                end
            end
        end
    end
    % Une mémoire partagée se lit avant de s'écrire : chaque Data Store
    % Read passe avant les Data Store Write de sa mémoire, et rend ce que le
    % pas d'avant y a laissé.
    for w = find(strcmp(c.types, 'datastorewrite'))
        for r = find(strcmp(c.types, 'datastoreread') & c.memoire == c.memoire(w))
            succ{r}(end + 1) = w;
        end
    end
    composantes = tarjan(succ, n);
    % Tarjan rend les composantes dans l'ordre topologique inverse.
    composantes = composantes(end:-1:1);
    c.etapes = {};
    c.boucles = {};
    courant = [];
    for i = 1:numel(composantes)
        comp = composantes{i};
        estBoucle = numel(comp) > 1 || any(succ{comp(1)} == comp(1));
        if ~estBoucle
            courant(end + 1) = comp(1); %#ok<AGROW>
            continue
        end
        if ~isempty(courant)
            c.etapes{end + 1} = courant;
            courant = [];
        end
        boucle = decouper(c, comp, succ);
        c.boucles{end + 1} = boucle;
        c.etapes{end + 1} = boucle;
    end
    if ~isempty(courant)
        c.etapes{end + 1} = courant;
    end
end

function composantes = tarjan(succ, n)
    indice = zeros(1, n);
    bas = zeros(1, n);
    surPile = false(1, n);
    pile = zeros(1, n);
    sommet = 0;
    compteur = 0;
    composantes = {};
    % Une version itérative : la récursion profonde d'un grand modèle
    % épuiserait la pile de l'interpréteur.
    for depart = 1:n
        if indice(depart) ~= 0
            continue
        end
        travail = [depart, 1];
        compteur = compteur + 1;
        indice(depart) = compteur;
        bas(depart) = compteur;
        sommet = sommet + 1;
        pile(sommet) = depart;
        surPile(depart) = true;
        while ~isempty(travail)
            v = travail(end, 1);
            i = travail(end, 2);
            s = succ{v};
            if i <= numel(s)
                travail(end, 2) = i + 1;
                w = s(i);
                if indice(w) == 0
                    compteur = compteur + 1;
                    indice(w) = compteur;
                    bas(w) = compteur;
                    sommet = sommet + 1;
                    pile(sommet) = w;
                    surPile(w) = true;
                    travail(end + 1, :) = [w, 1]; %#ok<AGROW>
                elseif surPile(w)
                    bas(v) = min(bas(v), indice(w));
                end
            else
                if bas(v) == indice(v)
                    comp = [];
                    while true
                        w = pile(sommet);
                        sommet = sommet - 1;
                        surPile(w) = false;
                        comp(end + 1) = w; %#ok<AGROW>
                        if w == v
                            break
                        end
                    end
                    composantes{end + 1} = sort(comp); %#ok<AGROW>
                end
                travail(end, :) = [];
                if ~isempty(travail)
                    u = travail(end, 1);
                    bas(u) = min(bas(u), bas(v));
                end
            end
        end
    end
end

% Couper une boucle : on retire des blocs jusqu'à ce que ce qui reste soit
% sans cycle. Chaque fois, celui qui a le plus de voisins dans la boucle —
% c'est lui qui en coupe le plus. Les sorties des blocs retirés sont les
% inconnues ; le calcul range les autres dans l'ordre, puis les retirés.
function boucle = decouper(c, comp, succ)
    dans = false(1, c.n);
    dans(comp) = true;
    dechires = [];
    restants = comp;
    for tour = 1:numel(comp)
        sousSucc = cell(1, c.n);
        for v = restants
            s = succ{v};
            sousSucc{v} = s(dans(s) & ~ismember(s, dechires));
        end
        cyclique = [];
        for v = restants
            for w = sousSucc{v}
                if w == v
                    cyclique(end + 1) = v; %#ok<AGROW>
                end
            end
        end
        sousComp = tarjan(sousSucc, c.n);
        for i = 1:numel(sousComp)
            sc = sousComp{i};
            sc = sc(ismember(sc, restants));
            if numel(sc) > 1
                cyclique = [cyclique, sc]; %#ok<AGROW>
            end
        end
        cyclique = unique(cyclique);
        if isempty(cyclique)
            break
        end
        meilleur = cyclique(1);
        score = -1;
        % un Algebraic Constraint porte l'inconnue de sa boucle
        contrainte = cyclique(strcmp(c.types(cyclique), 'algebraicconstraint'));
        if ~isempty(contrainte)
            cyclique = contrainte;
        end
        for v = cyclique
            sortants = sum(ismember(sousSucc{v}, cyclique));
            entrants = 0;
            for w = cyclique
                entrants = entrants + sum(sousSucc{w} == v);
            end
            if sortants * entrants > score
                score = sortants * entrants;
                meilleur = v;
            end
        end
        dechires(end + 1) = meilleur; %#ok<AGROW>
        restants(restants == meilleur) = [];
    end
    % L'ordre des blocs qui restent, les sorties des retirés tenues pour
    % connues.
    sousSucc = cell(1, c.n);
    for v = restants
        s = succ{v};
        sousSucc{v} = s(ismember(s, restants));
    end
    ordreRestants = [];
    comps = tarjan(sousSucc, c.n);
    comps = comps(end:-1:1);
    for i = 1:numel(comps)
        sc = comps{i};
        sc = sc(ismember(sc, restants));
        ordreRestants = [ordreRestants, sc]; %#ok<AGROW>
    end
    zA = [];
    zB = [];
    for d = dechires
        for q = 1:c.nOut(d)
            gp = c.portDebut(d) + q - 1;
            zA(end + 1) = c.vA(gp); %#ok<AGROW>
            zB(end + 1) = c.vB(gp); %#ok<AGROW>
        end
    end
    indices = [];
    for i = 1:numel(zA)
        indices = [indices, zA(i):zB(i)]; %#ok<AGROW>
    end
    boucle = struct('blocs', comp, 'ordre', [ordreRestants, dechires], ...
                    'dechires', dechires, 'z', indices);
end

% === sous-systèmes itérés =====================================================
%
% Le modèle d'un sous-système itéré se compile à part, ses INPORT à la
% forme des signaux qui y entrent. Ses blocs calculent tous à chaque
% itération : ils ne portent pas de période à eux, et pas d'état continu.
function [interne, ci, entrees, sorties, iter] = interieurIterateur(c, k, dE)
    interne = matlibre_sl_modele(c.p{k}.Model);
    interne.nom = c.chemins{k};
    types = cell(1, numel(interne.blocs));
    for j = 1:numel(interne.blocs)
        types{j} = matlibre_sl_catalogue('type', interne.blocs{j}.type).type;
        P = interne.blocs{j}.parametres;
        for champ = fieldnames(P).'
            if any(strcmpi(champ{1}, {'SampleTime', 'tsamp', 'samptime', 'st'})) && ...
               isnumeric(P.(champ{1})) && ~isempty(P.(champ{1})) && P.(champ{1})(1) > 0
                error('Simulink:blocks:IteratorSubsystemSampleTime', ...
                      ['Le bloc ''%s/%s'' porte la periode %g, mais il est dans un ' ...
                       'sous-systeme itere : ses blocs calculent a chaque iteration, et ' ...
                       'heritent leur periode (-1).'], c.chemins{k}, interne.blocs{j}.nom, ...
                      P.(champ{1})(1));
            end
        end
    end
    rangs = find(strcmp(types, 'inport'));
    ports = zeros(size(rangs));
    for j = 1:numel(rangs)
        P = interne.blocs{rangs(j)}.parametres;
        ports(j) = j;
        if isfield(P, 'Port')
            ports(j) = double(P.Port);
        end
    end
    [~, ordre] = sort(ports);
    rangs = rangs(ordre);
    for j = 1:numel(rangs)
        d = [1 1];
        if j <= numel(dE) && ~isempty(dE{j})
            d = dE{j};
        end
        interne.blocs{rangs(j)}.parametres.Value = zeros(d);
        interne.blocs{rangs(j)}.parametres.PortDimensions = -1;
    end
    options = struct('pas', 1, 'silencieux', true, 'variable', false, 'config', c.config);
    ci = matlibre_sl_compiler(interne, options);
    if ~isempty(ci.x0)
        continu = find(ci.xA > 0, 1);
        error('Simulink:blocks:IteratorSubsystemContinuousStates', ...
              ['Le bloc ''%s'' a des etats continus, mais il est dans un sous-systeme ' ...
               'itere, qui calcule plusieurs fois par pas sans avancer le temps. ' ...
               'Prenez un bloc discret.'], ci.chemins{continu});
    end
    % Les INPORT et les OUTPORT, par leur rang ; le bloc d'itération.
    entrees = rangs;
    sorties = find(strcmp(ci.types, 'outport'));
    ports = zeros(size(sorties));
    for j = 1:numel(sorties)
        ports(j) = double(ci.p{sorties(j)}.Port);
    end
    [~, ordre] = sort(ports);
    sorties = sorties(ordre);
    iter = find(ismember(ci.types, {'foriterator', 'whileiterator'}), 1);
end

% === blocs de code ============================================================

function code = preparerCode(c, k)
    code = [];
    p = c.p{k};
    ch = c.chemins{k};
    switch c.types{k}
        case 'fcn'
            code.h = matlibre_sl_fonction('expression', p.Expr, ch);
        case 'interpretedmatlabfunction'
            code.h = matlibre_sl_fonction('expression', p.MATLABFcn, ch);
        case 'chart'
            code = preparerGraphe(p, ch);
        case 'matlabfunction'
            code.h = matlibre_sl_fonction('installer', p.Script, ch);
            code.persistante = ~isempty(regexp(char(p.Script), '(^|\n)\s*persistent\s', 'once'));
            code.instant = ~isempty(strfind(char(p.Script), 'matlibre_sl_instant'));
        case 'msfunction'
            code = matlibre_sl_msfonction('preparer', p.FunctionName, ...
                                          parametresSFonction(p, ch), ch);
        case 'sfunction'
            parametres = p.Parameters;
            if ischar(parametres) || isstring(parametres)
                try
                    parametres = evalin('base', ['{' char(parametres) '}']);
                catch err
                    error('Simulink:blocks:SFunctionParameters', ...
                          'Les parametres ''%s'' du bloc ''%s'' ne s''evaluent pas : %s', ...
                          char(p.Parameters), ch, err.message);
                end
            elseif ~iscell(parametres)
                parametres = {parametres};
            end
            [code.tailles, code.x0, code.ts] = matlibre_sl_fonction('sfonction', ...
                                                                    p.FunctionName, parametres, ch);
            code.h = str2func(char(p.FunctionName));
            code.parametres = parametres;
            if any(code.tailles(1:2) < 0)
                error('Simulink:blocks:SFunctionSizes', ...
                      'La S-fonction du bloc ''%s'' annonce un nombre d''etats negatif.', ch);
            end
    end
end

% Les paramètres d'une S-fonction : la cellule que donne son paramètre
% Parameters, un texte évalué dans l'espace de travail de base.
function parametres = parametresSFonction(p, ch)
    parametres = p.Parameters;
    if ischar(parametres) || isstring(parametres)
        try
            parametres = evalin('base', ['{' char(parametres) '}']);
        catch err
            error('Simulink:blocks:SFunctionParameters', ...
                  'Les parametres ''%s'' du bloc ''%s'' ne s''evaluent pas : %s', ...
                  char(p.Parameters), ch, err.message);
        end
    elseif ~iscell(parametres)
        parametres = {parametres};
    end
end

% Un diagramme Stateflow : la machine bâtie par SFCHART, les champs du
% contexte qu'il rend — « etat », le rang de l'état actif —, et leurs
% dimensions, lues au démarrage de la machine.
function code = preparerGraphe(p, chemin)
    machine = p.Chart;
    if ~isstruct(machine) || ~isfield(machine, 'etats') || ~isfield(machine, 'transitions')
        error('Simulink:blocks:ChartMachineMissing', ...
              ['Le bloc Chart ''%s'' ne porte pas de machine : donnez-lui celle que ' ...
               'batissent SFCHART, SFSTATE et SFTRANSITION, par son parametre Chart.'], ...
              chemin);
    end
    if isempty(machine.etats)
        error('Simulink:blocks:ChartNoState', 'La machine du bloc ''%s'' n''a pas d''etat.', ...
              chemin);
    end
    sorties = p.Outputs;
    if ischar(sorties) || isstring(sorties)
        sorties = cellstr(sorties);
    end
    contexte = p.InitialContext;
    if isempty(contexte)
        contexte = struct();
    end
    try
        [courant, contexte] = sfstep(machine, '', contexte, []);
    catch err
        error('Simulink:blocks:ChartError', ...
              'La machine du bloc ''%s'' echoue en entrant dans son etat initial : %s', ...
              chemin, err.message);
    end
    code = struct('machine', machine, 'sorties', {sorties}, 'contexte', contexte, ...
                  'initial', p.InitialContext);
    code.noms = cellfun(@(e) e.nom, machine.etats, 'UniformOutput', false);
    % Les événements : ceux d'entrée arrivent par un port de déclenchement,
    % après les entrées de données ; ceux de sortie ont chacun leur port,
    % après les sorties de données.
    code.nDonnees = double(p.Inputs);
    code.entreesEvt = struct('nom', {}, 'portee', {}, 'declencheur', {});
    code.sortiesEvt = code.entreesEvt;
    if isfield(machine, 'evenements') && ~isempty(machine.evenements)
        portees = {machine.evenements.portee};
        code.entreesEvt = machine.evenements(strcmp(portees, 'Input'));
        code.sortiesEvt = machine.evenements(strcmp(portees, 'Output'));
    end
    code.dims = cell(1, numel(sorties));
    for q = 1:numel(sorties)
        if strcmp(sorties{q}, 'etat')
            code.dims{q} = [1 1];
            continue
        end
        if ~isfield(contexte, sorties{q})
            error('Simulink:blocks:ChartOutputMissing', ...
                  ['La sortie ''%s'' du bloc Chart ''%s'' n''est pas un champ du contexte ' ...
                   'de sa machine ; donnez-le dans InitialContext, ou par une action ' ...
                   'd''entree de l''etat initial ''%s''.'], sorties{q}, chemin, courant);
        end
        v = contexte.(sorties{q});
        membre = isobject(v) && isenum(v);   % un membre d'énumération : son type
        if ~(isnumeric(v) || islogical(v) || membre) || isempty(v) || ndims(v) > 2
            error('Simulink:blocks:ChartOutputType', ...
                  ['La sortie ''%s'' du bloc Chart ''%s'' n''est pas un tableau de nombres ' ...
                   'ni de membres d''une enumeration.'], sorties{q}, chemin);
        end
        code.dims{q} = size(v);
    end
    for q = 1:numel(code.sortiesEvt)
        code.dims{end + 1} = [1 1];
    end
end

% Une expression de Fcn ou d'Interpreted MATLAB Function s'essaie sur des
% zéros : ce qu'elle rend doit avoir la largeur de la sortie.
function verifierCode(c, k, w)
    u = zeros(max(1, largeurEntree(c, k, 1)), 1);
    try
        y = c.objets{k}(u);
    catch err
        error('Simulink:blocks:FcnEvaluationError', ...
              'Le bloc ''%s'' echoue sur une entree de %d zero(s) : %s', c.chemins{k}, ...
              numel(u), err.message);
    end
    if ~(isnumeric(y) || islogical(y)) || numel(y) ~= w
        if strcmp(c.types{k}, 'fcn')
            detail = 'un Fcn rend un scalaire';
        else
            detail = sprintf('OutputDimensions en annonce %d', w);
        end
        error('Simulink:blocks:FcnOutputDimension', ...
              'Le bloc ''%s'' rend %d valeur(s) : %s.', c.chemins{k}, numel(y), detail);
    end
end

% Les dimensions des sorties d'une MATLAB Function : un appel d'essai sur
% des zéros, puis ses variables persistantes remises à zéro.
function s = dimsFonction(c, k, dE)
    h = c.fonctions{k}.h;
    u = cell(1, c.nIn(k));
    for j = 1:c.nIn(k)
        if j <= numel(dE) && ~isempty(dE{j})
            u{j} = zeros(dE{j});
        else
            u{j} = 0;   % dans une boucle, une entrée pas encore connue : un scalaire
        end
    end
    sorties = cell(1, c.nOut(k));
    try
        [sorties{:}] = h(u{:});
    catch err
        % une erreur de Simulink qui nomme déjà le bloc passe telle quelle
        if strncmp(err.identifier, 'Simulink:', 9) && ~isempty(strfind(err.message, c.chemins{k}))
            rethrow(err);
        end
        % les types ne sont pas encore connus : une fonction qui lit des
        % membres d'énumération s'essaie sur le membre par défaut de
        % chacune de celles que le schéma emploie
        [sorties, ok] = essaiEnumere(c, h, u, c.nOut(k));
        if ~ok
            error('Simulink:blocks:MATLABFunctionError', ...
                  'La fonction du bloc ''%s'' echoue sur des entrees nulles : %s', ...
                  c.chemins{k}, err.message);
        end
    end
    clear(func2str(h));
    s = cell(1, c.nOut(k));
    for q = 1:c.nOut(k)
        membre = isobject(sorties{q}) && isenum(sorties{q});
        if ~(isnumeric(sorties{q}) || islogical(sorties{q}) || membre) || ndims(sorties{q}) > 2
            error('Simulink:blocks:MATLABFunctionOutput', ...
                  ['La sortie %d du bloc ''%s'' n''est pas un tableau de nombres a deux ' ...
                   'dimensions.'], q, c.chemins{k});
        end
        d = size(sorties{q});
        if prod(d) == 0
            error('Simulink:blocks:MATLABFunctionOutput', ...
                  'La sortie %d du bloc ''%s'' est vide.', q, c.chemins{k});
        end
        s{q} = d;
    end
end

% Une MATLAB Function appelée sur le membre par défaut d'une énumération
% que le schéma emploie, à la place de ses entrées nulles.
function [sorties, ok] = essaiEnumere(c, h, u, nOut)
    sorties = cell(1, nOut);
    ok = false;
    classes = {};
    for k = 1:c.n
        p = c.p{k};
        if isfield(p, 'Classes')
            valeurs = struct2cell(p.Classes);
            for i = 1:numel(valeurs)
                if ischar(valeurs{i}) && strncmp(valeurs{i}, 'Enum:', 5)
                    classes{end + 1} = valeurs{i}; %#ok<AGROW>
                end
            end
        end
        if isfield(p, 'OutDataTypeStr') && ischar(p.OutDataTypeStr) && ...
           strncmp(p.OutDataTypeStr, 'Enum:', 5)
            classes{end + 1} = p.OutDataTypeStr; %#ok<AGROW>
        end
    end
    for classe = unique(classes)
        code = matlibre_sl_types('code', classe{1});
        if code <= 200
            continue
        end
        v = u;
        try
            for j = 1:numel(v)
                v{j} = matlibre_sl_types('convertir', code, ...
                                         matlibre_sl_types('defaut', code) * ones(size(u{j})));
            end
            [sorties{:}] = h(v{:});
            ok = true;
            return
        catch
        end
    end
end

% === bus =======================================================================
%
% La forme d'un bus : ses éléments, chacun avec son nom, ses dimensions, sa
% place dans le vecteur qui les porte bout à bout, et, s'il est lui-même
% un bus, sa forme. On la lit en remontant du port jusqu'au Bus Creator,
% à travers les passe-plats — un sous-système déplié, un Goto et son
% From.
function forme = formeBus(c, gp)
    forme = [];
    for pas = 1:c.n
        if gp == 0
            return
        end
        a = c.proprio(gp);
        % Un bloc typé — un Bus Creator, une entrée, un port de
        % sous-système dont OutDataTypeStr vaut 'Bus: X' — donne au bus la
        % forme de son type : VERIFIERTYPESBUS a vérifié qu'il la porte.
        nomType = '';
        if any(strcmp(c.types{a}, {'buscreator', 'signalconversion', 'inport', ...
                                   'fromworkspace'}))
            nomType = matlibre_sl_bus('type', champ(c.p{a}, 'OutDataTypeStr', ''));
        end
        if ~isempty(nomType)
            forme = matlibre_sl_bus('forme', matlibre_sl_bus('objet', nomType, ...
                                                              c.chemins{a}), c.chemins{a});
            return
        end
        switch c.types{a}
            case 'buscreator'
                break
            case {'signalconversion', 'from'}
                gp = c.entrees{a}(max(1, min(c.rang(gp), c.nIn(a))));
            case 'busassignment'
                gp = c.entrees{a}(1);   % le bus passe, éléments remplacés
            case {'zoh', 'memory', 'delay', 'ratetransition', 'manualswitch', 'merge', 'switch'}
                % un bloc qui laisse passer un bus, comme dans Simulink : il
                % vient de sa première entrée — les données d'un Switch, les
                % entrées d'un Merge portent le même
                gp = c.entrees{a}(1);
            case 'multiportswitch'
                gp = c.entrees{a}(min(2, c.nIn(a)));
            otherwise
                return
        end
    end
    forme = formeDesEntrees(c, a);
end

% La forme du bus que forment les entrées d'un Bus Creator : un élément par
% entrée, qui garde le port d'où vient son signal — son type s'y lira.
function forme = formeDesEntrees(c, a)
    noms = nomsDuBus(c.p{a}.Inputs, c.nIn(a));
    forme = struct('nom', {}, 'dims', {}, 'largeur', {}, 'debut', {}, 'sous', {}, ...
                   'source', {}, 'donnee', {});
    debut = 1;
    for j = 1:c.nIn(a)
        source = c.entrees{a}(j);
        d = [1 1];
        if source > 0
            if ~isfield(c, 'dimsCourants') || isempty(c.dimsCourants{source})
                forme = [];
                return
            end
            d = c.dimsCourants{source};
        end
        w = prod(d);
        forme(end + 1) = struct('nom', noms{j}, 'dims', d, 'largeur', w, 'debut', debut, ...
                                'sous', {formeBus(c, source)}, 'source', source, ...
                                'donnee', ''); %#ok<AGROW>
        debut = debut + w;
    end
end

% La place de chaque élément qu'un Bus Assignment remplace, sans en
% vérifier la largeur, que les segments vérifieront.
function places = placesAssignees(c, k, forme)
    places = struct('debut', {}, 'largeur', {});
    if isempty(forme)
        return
    end
    demandes = strtrim(strsplit(char(c.p{k}.AssignedSignals), ','));
    for q = 1:numel(demandes)
        parties = strsplit(demandes{q}, '.');
        niveau = forme;
        decalage = 0;
        element = [];
        for i = 1:numel(parties)
            rang = find(strcmp({niveau.nom}, parties{i}), 1);
            if isempty(rang) || (i < numel(parties) && isempty(niveau(rang).sous))
                places = struct('debut', {}, 'largeur', {});
                return   % les segments nommeront la faute
            end
            element = niveau(rang);
            decalage = decalage + element.debut - 1;
            if i < numel(parties)
                niveau = element.sous;
            end
        end
        places(end + 1) = struct('debut', decalage + 1, 'largeur', element.largeur); %#ok<AGROW>
    end
end

% Les blocs dont une sortie n'est pas double, et qui calculent : leur
% résultat se ramène au type de la sortie, arrondi selon RndMeth (Floor
% par défaut, Zero pour un produit) et, au-delà des bornes, replié — ou
% saturé si SaturateOnIntegerOverflow vaut 'on'. Les blocs d'aiguillage
% et de mémoire ne font que transmettre des valeurs déjà typées.
function [castK, arrondiK, saturerK] = conversionsDesSorties(c)
    aiguillage = {'zoh', 'memory', 'delay', 'ratetransition', 'from', 'selector', 'reshape', ...
                  'demux', 'mux', 'concatenate', 'merge', 'switch', 'multiportswitch', ...
                  'manualswitch', 'busselector', 'tappeddelay', 'signalconversion', ...
                  'datatypeconversion', 'constant', 'matlabfunction', 'chart', 'logic', ...
                  'relational', 'comparetoconstant', 'comparetozero', 'detectchange', ...
                  'detectincrease', 'detectdecrease', 'intervaltest'};
    arrondis = {'Zero', 'Nearest', 'Round', 'Floor', 'Ceiling', 'Convergent', 'Simplest'};
    castK = false(1, c.n);
    arrondiK = 4 * ones(1, c.n);
    saturerK = false(1, c.n);
    for k = 1:c.n
        if c.nOut(k) == 0 || any(strcmp(c.types{k}, aiguillage))
            continue
        end
        ports = c.portDebut(k) + (0:c.nOut(k) - 1);
        castK(k) = any(c.typePort(ports) ~= 2);
        p = c.p{k};
        if isfield(p, 'RndMeth')
            arrondiK(k) = find(strcmp(arrondis, p.RndMeth), 1);
        end
        if isfield(p, 'SaturateOnIntegerOverflow')
            saturerK(k) = strcmp(p.SaturateOnIntegerOverflow, 'on');
        end
    end
end

% Les blocs typés par un Simulink.Bus : le type doit exister, et le bus
% qui les traverse en être. Un Bus Creator reçoit autant d'entrées que le
% type a d'éléments, chacune à ses dimensions — un bus emboîté du type
% emboîté ; une entrée, une sortie, un port de sous-système reçoivent un
% bus de leur type.
function verifierTypesBus(c)
    for k = 1:c.n
        if ~any(strcmp(c.types{k}, {'buscreator', 'signalconversion', 'outport', 'inport'}))
            continue
        end
        nomType = matlibre_sl_bus('type', champ(c.p{k}, 'OutDataTypeStr', ''));
        if isempty(nomType)
            continue
        end
        objet = matlibre_sl_bus('objet', nomType, c.chemins{k});
        attendue = matlibre_sl_bus('forme', objet, c.chemins{k});
        switch c.types{k}
            case 'inport'
                continue   % la source du bus : elle a la forme de son type
            case 'buscreator'
                if c.nIn(k) ~= numel(attendue)
                    error('Simulink:Bus:BusCreatorElementCountMismatch', ...
                          ['Le Bus Creator ''%s'' forme un bus de type ''%s'', qui a %d ' ...
                           'element(s) : il lui faut autant d''entrees, et il en a %d.'], ...
                          c.chemins{k}, nomType, numel(attendue), c.nIn(k));
                end
                for j = 1:c.nIn(k)
                    source = c.entrees{k}(j);
                    largeur = 1;
                    if source > 0
                        largeur = prod(c.dims{source});
                    end
                    if ~isempty(attendue(j).sous)
                        vu = [];
                        if source > 0
                            vu = formeBus(c, source);
                        end
                        if isempty(vu)
                            error('Simulink:Bus:ElementNotBus', ...
                                  ['Le Bus Creator ''%s'' forme un bus de type ''%s'' : son ' ...
                                   'entree %d, l''element ''%s'', doit etre un bus.'], ...
                                  c.chemins{k}, nomType, j, attendue(j).nom);
                        end
                        emboite = matlibre_sl_bus('type', objet.Elements(j).DataType);
                        matlibre_sl_bus('accorder', vu, ...
                                        matlibre_sl_bus('objet', emboite, c.chemins{k}), ...
                                        c.chemins{k}, emboite);
                    elseif largeur ~= attendue(j).largeur
                        error('Simulink:Bus:ElementDimensionsMismatch', ...
                              ['Le Bus Creator ''%s'' forme un bus de type ''%s'' : son ' ...
                               'entree %d, l''element ''%s'', doit etre de dimensions %s, ' ...
                               'et elle est de largeur %d.'], c.chemins{k}, nomType, j, ...
                              attendue(j).nom, mat2str(attendue(j).dims), largeur);
                    end
                    verifierNomElement(c, k, j, source, attendue(j).nom, nomType);
                end
            otherwise   % une sortie, un port de sous-système
                source = c.entrees{k}(1);
                vu = [];
                if source > 0
                    vu = formeBus(c, source);
                end
                matlibre_sl_bus('accorder', vu, objet, c.chemins{k}, nomType);
        end
    end
end

% BusObjectLabelMismatch, comme dans Simulink : un signal nommé qui entre
% dans un Bus Creator typé sous un autre nom que celui de son élément —
% rien, un avertissement, ou l'arrêt, en nommant le bloc, le signal et
% l'élément. Un signal sans nom prend celui de l'élément.
function verifierNomElement(c, k, j, source, attendu, nomType)
    niveau = 1;
    if isstruct(c.config) && isfield(c.config, 'BusObjectLabelMismatch')
        niveau = find(strcmp({'none', 'warning', 'error'}, c.config.BusObjectLabelMismatch)) - 1;
    end
    if niveau == 0 || source == 0
        return
    end
    s = c.proprio(source);
    q = source - c.portDebut(s) + 1;
    nom = '';
    reglages = c.signaux{s};
    for i = 1:numel(reglages)
        if reglages(i).Port == q
            nom = char(reglages(i).Name);
        end
    end
    if isempty(nom) || strcmp(nom, attendu)
        return
    end
    texte = sprintf(['Le signal ''%s'' qui entre en %d dans ''%s'' ne porte pas le nom de ' ...
                     'l''element ''%s'' du type de bus ''%s''. BusObjectLabelMismatch regle ' ...
                     'ce diagnostic.'], nom, j, c.chemins{k}, attendu, nomType);
    if niveau == 2
        error('Simulink:Bus:ElementNameMismatch', '%s', texte);
    end
    warning('Simulink:Bus:ElementNameMismatch', '%s', texte);
end

function noms = nomsDuBus(entrees, n)
    texte = strtrim(char(num2str(entrees)));
    if isnan(str2double(texte))
        noms = strtrim(strsplit(texte, ','));
    else
        noms = arrayfun(@(j) sprintf('signal%d', j), 1:n, 'UniformOutput', false);
    end
end

% Les éléments qu'un Bus Selector reprend, dans l'ordre de OutputSignals ;
% « mesures.vitesse » descend dans un bus emboîté.
function choix = elementsChoisis(c, k)
    choix = [];
    forme = formeBus(c, c.entrees{k}(1));
    if isempty(forme)
        if c.entrees{k}(1) == 0 || (isfield(c, 'dimsCourants') && ...
                                    ~isempty(c.dimsCourants{c.entrees{k}(1)}))
            error('Simulink:Bus:SelectorInputNotBus', ...
                  ['L''entree du Bus Selector ''%s'' n''est pas un bus : il lui faut le ' ...
                   'signal d''un Bus Creator.'], c.chemins{k});
        end
        return
    end
    demandes = strtrim(strsplit(char(c.p{k}.OutputSignals), ','));
    choix = struct('nom', {}, 'dims', {}, 'largeur', {}, 'debut', {});
    for q = 1:numel(demandes)
        parties = strsplit(demandes{q}, '.');
        niveau = forme;
        decalage = 0;
        element = [];
        for i = 1:numel(parties)
            rang = find(strcmp({niveau.nom}, parties{i}), 1);
            if isempty(rang)
                error('Simulink:Bus:SelectorElementNotFound', ...
                      ['Le Bus Selector ''%s'' demande ''%s'', que le bus ne porte pas ; ' ...
                       'ses elements sont : %s.'], c.chemins{k}, demandes{q}, ...
                      strjoin({niveau.nom}, ', '));
            end
            element = niveau(rang);
            decalage = decalage + element.debut - 1;
            if i < numel(parties)
                if isempty(element.sous)
                    error('Simulink:Bus:SelectorElementNotFound', ...
                          ['Le Bus Selector ''%s'' demande ''%s'', mais ''%s'' n''est ' ...
                           'pas un bus.'], c.chemins{k}, demandes{q}, parties{i});
                end
                niveau = element.sous;
            end
        end
        choix(end + 1) = struct('nom', demandes{q}, 'dims', element.dims, ...
                                'largeur', element.largeur, 'debut', decalage + 1); %#ok<AGROW>
    end
end

% Les éléments qu'un Bus Assignment remplace : leur place dans le bus, et
% leur largeur, qui doit être celle du signal qui les remplace.
function seg = elementsAssignes(c, k)
    forme = formeBus(c, c.entrees{k}(1));
    if isempty(forme)
        error('Simulink:Bus:AssignmentInputNotBus', ...
              ['La premiere entree du Bus Assignment ''%s'' n''est pas un bus : il lui ' ...
               'faut le signal d''un Bus Creator.'], c.chemins{k});
    end
    demandes = strtrim(strsplit(char(c.p{k}.AssignedSignals), ','));
    seg = numel(demandes);
    for q = 1:numel(demandes)
        parties = strsplit(demandes{q}, '.');
        niveau = forme;
        decalage = 0;
        element = [];
        for i = 1:numel(parties)
            rang = find(strcmp({niveau.nom}, parties{i}), 1);
            if isempty(rang)
                error('Simulink:Bus:AssignmentElementNotFound', ...
                      ['Le Bus Assignment ''%s'' remplace ''%s'', que le bus ne porte ' ...
                       'pas ; ses elements sont : %s.'], c.chemins{k}, demandes{q}, ...
                      strjoin({niveau.nom}, ', '));
            end
            element = niveau(rang);
            decalage = decalage + element.debut - 1;
            if i < numel(parties)
                if isempty(element.sous)
                    error('Simulink:Bus:AssignmentElementNotFound', ...
                          ['Le Bus Assignment ''%s'' remplace ''%s'', mais ''%s'' n''est ' ...
                           'pas un bus.'], c.chemins{k}, demandes{q}, parties{i});
                end
                niveau = element.sous;
            end
        end
        largeur = largeurEntree(c, k, q + 1);
        if largeur ~= element.largeur
            error('Simulink:Bus:AssignmentDimensions', ...
                  ['Le Bus Assignment ''%s'' remplace ''%s'', de %d element(s), par un ' ...
                   'signal de %d element(s).'], c.chemins{k}, demandes{q}, ...
                  element.largeur, largeur);
        end
        seg = [seg; decalage + 1; element.largeur]; %#ok<AGROW>
    end
end

% === sous-systèmes conditionnels ================================================
%
% Les conditions d'un bloc If deviennent des fonctions de u1, u2... : la
% première qui vaut vrai choisit sa sortie. Chacune est essayée à la
% compilation sur des zéros, pour qu'une faute de frappe se dise en
% nommant le bloc, non au milieu de la simulation.
function [conditions, nCond] = conditionsSi(p, nIn, chemin, c, k)
    textes = [{char(p.IfExpression)}, expressionsSinonSi(p.ElseIfExpressions)];
    nCond = numel(textes);
    arguments = strjoin(arrayfun(@(j) sprintf('u%d', j), 1:nIn, 'UniformOutput', false), ',');
    essai = cell(1, nIn);
    for j = 1:nIn
        essai{j} = zeros(max(1, largeurEntree(c, k, j)), 1);
    end
    conditions = cell(1, nCond);
    for i = 1:nCond
        if isempty(strtrim(textes{i}))
            error('Simulink:blocks:IfExpressionEmpty', ...
                  'La condition %d du bloc If ''%s'' est vide.', i, chemin);
        end
        try
            conditions{i} = str2func(sprintf('@(%s) %s', arguments, textes{i}));
            r = conditions{i}(essai{:});
            if ~(isnumeric(r) || islogical(r)) || numel(r) ~= 1
                error('Simulink:blocks:IfExpressionNotScalar', 'pas scalaire');
            end
        catch err
            error('Simulink:blocks:IfExpressionInvalid', ...
                  ['La condition ''%s'' du bloc If ''%s'' ne s''evalue pas en un booleen ' ...
                   'scalaire de ses entrees u1 a u%d : %s'], textes{i}, chemin, nIn, ...
                  err.message);
        end
    end
end

function liste = expressionsSinonSi(texte)
    liste = {};
    texte = char(texte);
    if isempty(strtrim(texte))
        return
    end
    profondeur = 0;
    debut = 1;
    for i = 1:numel(texte)
        switch texte(i)
            case {'(', '[', '{'}
                profondeur = profondeur + 1;
            case {')', ']', '}'}
                profondeur = profondeur - 1;
            case ','
                if profondeur == 0
                    liste{end + 1} = strtrim(texte(debut:i - 1)); %#ok<AGROW>
                    debut = i + 1;
                end
        end
    end
    liste{end + 1} = strtrim(texte(debut:end));
end

% Les cas d'un Switch Case : une cellule de valeurs entières, écrite comme
% dans Simulink, « {1, [2 3], 7} », ou de membres d'une même énumération,
% « {Couleur.Rouge, [Couleur.Vert Couleur.Bleu]} » — CLASSE la nomme alors.
function [cas, classe] = casDe(texte, chemin)
    [cas, classe] = indicesDe(texte, chemin, 'Simulink:blocks:SwitchCaseConditionsInvalid', ...
                              'Les cas');
end

% Une cellule d'indices : des entiers, ou des membres d'une même
% énumération, ramenés à leurs valeurs.
function [cas, classe] = indicesDe(texte, chemin, identifiant, quoi)
    cas = texte;
    classe = '';
    if ischar(cas) || isstring(cas)
        try
            cas = evalin('base', char(cas));
        catch err
            error(identifiant, '%s de ''%s'' ne s''evaluent pas : %s', quoi, chemin, ...
                  err.message);
        end
    end
    if isnumeric(cas) || (isobject(cas) && isenum(cas))
        cas = num2cell(cas);
    end
    if iscell(cas) && ~isempty(cas) && all(cellfun(@(v) isobject(v) && isenum(v), cas))
        classes = cellfun(@class, cas, 'UniformOutput', false);
        if any(~strcmp(classes, classes{1}))
            error(identifiant, ['%s de ''%s'' melangent des membres de %s et de %s : ils ' ...
                                'sont d''une seule enumeration.'], quoi, chemin, classes{1}, ...
                  classes{find(~strcmp(classes, classes{1}), 1)});
        end
        classe = classes{1};
        try
            cas = cellfun(@(v) double(v), cas, 'UniformOutput', false);
        catch
            error('Simulink:DataType:EnumTypeNotInteger', ...
                  ['%s de ''%s'' sont des membres de ''%s'', une enumeration dont les ' ...
                   'membres ne portent pas de valeurs entieres.'], quoi, chemin, classe);
        end
    end
    if ~iscell(cas) || isempty(cas) || ...
       ~all(cellfun(@(v) isnumeric(v) && ~isempty(v) && all(v(:) == round(v(:))), cas))
        error(identifiant, ['%s de ''%s'' sont une cellule de valeurs entieres, comme ' ...
                            '{1, [2 3], 7}, ou de membres d''une enumeration.'], quoi, chemin);
    end
    cas = cellfun(@(v) double(v(:)), cas, 'UniformOutput', false);
end

% Des indices énumérés vont avec une entrée de leur type, des indices
% entiers avec une entrée numérique.
function accorderIndices(typeEntree, classe, chemin, parametre, quoi)
    classeEntree = matlibre_sl_types('enum', typeEntree);
    if strcmp(classeEntree, classe)
        return
    end
    if isempty(classe)
        error('Simulink:DataType:EnumTypeMismatch', ...
              ['L''entree de ''%s'' est de type %s, et ses %s (%s) sont des entiers : ' ...
               'donnez-les en membres de %s.'], chemin, ...
              matlibre_sl_types('nom', typeEntree), quoi, parametre, classeEntree);
    elseif isempty(classeEntree)
        error('Simulink:DataType:EnumTypeMismatch', ...
              ['Les %s de ''%s'' (%s) sont des membres de %s, et son entree est de type ' ...
               '%s : elle doit etre de type Enum: %s.'], quoi, chemin, parametre, classe, ...
              matlibre_sl_types('nom', max(2, typeEntree)), classe);
    else
        error('Simulink:DataType:EnumTypeMismatch', ...
              ['Les %s de ''%s'' (%s) sont des membres de %s, et son entree est de type ' ...
               '%s.'], quoi, chemin, parametre, classe, matlibre_sl_types('nom', typeEntree));
    end
end

% Le segment d'un Multiport Switch : ses ports de données, numérotés à
% partir de un ou de zéro, ou désignés chacun par ses indices ; le port du
% cas par défaut — le dernier, ou un port de plus — et ce qu'on dit quand
% la commande ne désigne aucun port.
function seg = segmentMultiport(c, k, p, ch)
    specifies = strcmp(p.DataPortOrder, 'Specify indices');
    plus = strcmp(p.DataPortForDefault, 'Additional data port');
    diagnostic = find(strcmp(p.DiagnosticForDefault, {'None', 'Warning', 'Error'})) - 1;
    nDonnees = c.nIn(k) - 1 - plus;
    typeCommande = 2;
    if c.entrees{k}(1) > 0
        typeCommande = c.typePort(c.entrees{k}(1));
    end
    seg = [nDonnees; strcmp(p.DataPortOrder, 'Zero-based contiguous'); specifies; plus; ...
           diagnostic; typeCommande];
    if ~specifies
        if typeCommande > 200
            error('Simulink:DataType:EnumTypeMismatch', ...
                  ['La commande de ''%s'' est de type %s : ses ports de donnees se designent ' ...
                   'alors par des membres, DataPortOrder ''Specify indices'' et ' ...
                   'DataPortIndices {%s.%s, ...}.'], ch, matlibre_sl_types('nom', typeCommande), ...
                  matlibre_sl_types('enum', typeCommande), premierMembre(typeCommande));
        end
        return
    end
    [indices, classe] = indicesDe(p.DataPortIndices, ch, ...
                                  'Simulink:blocks:MultiPortSwitchInvalidIndices', ...
                                  'Les indices des ports de donnees');
    if numel(indices) ~= nDonnees
        error('Simulink:blocks:MultiPortSwitchInvalidIndices', ...
              ['''%s'' a %d port(s) de donnees et %d indice(s) (DataPortIndices) : il en ' ...
               'faut un par port.'], ch, nDonnees, numel(indices));
    end
    tous = vertcat(indices{:});
    if numel(unique(tous)) < numel(tous)
        error('Simulink:blocks:MultiPortSwitchInvalidIndices', ...
              '''%s'' designe deux ports de donnees par un meme indice (DataPortIndices).', ch);
    end
    accorderIndices(typeCommande, classe, ch, 'DataPortIndices', 'indices de ports');
    for j = 1:nDonnees
        seg = [seg; numel(indices{j}); indices{j}(:)]; %#ok<AGROW>
    end
end

function n = premierMembre(code)
    [~, noms] = enumeration(matlibre_sl_types('enum', code));
    n = noms{1};
end

% La valeur initiale d'une sortie énumérée qu'on ne dit pas — zéro, le
% défaut du bloc — : le membre par défaut de son type.
function v = initialeEnum(c, k, p, nom)
    v = p.(nom);
    type = c.typePort(c.portDebut(k));
    if type > 200 && ~(isfield(p, 'Classes') && isfield(p.Classes, nom)) && ...
       all(double(v(:)) == 0)
        v = matlibre_sl_types('defaut', type);
    end
end

% La sortie initiale d'un sous-système conditionnel, évaluée comme un
% paramètre : un membre d'énumération y garde sa classe.
function s = sortieInitiale(s, chemin)
    s.classe = '';
    v = s.initiale;
    if ischar(v) || isstring(v)
        v = matlibre_sl_expression(char(v), chemin, 'InitialOutput', 'classe');
    end
    if isobject(v) && isenum(v)
        s.classe = class(v);
        try
            v = double(v);
        catch
            error('Simulink:DataType:EnumTypeNotInteger', ...
                  ['La sortie initiale de ''%s'' est un membre de ''%s'', une enumeration ' ...
                   'dont les membres ne portent pas de valeurs entieres.'], chemin, s.classe);
        end
    end
    s.initiale = v;
end

% Une sortie conditionnelle énumérée part d'un membre de son type : celui
% qu'on lui donne, ou le membre par défaut quand on ne dit rien.
function c = initialesEnumerees(c)
    for k = 1:c.n
        if isempty(c.sortieCond{k}) || c.nOut(k) == 0
            continue
        end
        type = c.typePort(c.portDebut(k));
        s = c.sortieCond{k};
        if type <= 200
            if ~isempty(s.classe)
                error('Simulink:DataType:EnumParameterMismatch', ...
                      ['La sortie initiale de ''%s'' est un membre de %s, et son signal est ' ...
                       'de type %s.'], c.chemins{k}, s.classe, matlibre_sl_types('nom', ...
                                                                              max(type, 2)));
            end
            continue
        end
        classe = matlibre_sl_types('enum', type);
        if isempty(s.classe) && all(double(s.initiale(:)) == 0)
            c.sortieCond{k}.initiale = matlibre_sl_types('defaut', type);
        elseif ~strcmp(s.classe, classe)
            error('Simulink:DataType:EnumParameterMismatch', ...
                  ['La sortie initiale de ''%s'' doit etre un membre de %s, le type de son ' ...
                   'signal (InitialOutput).'], c.chemins{k}, classe);
        end
    end
end

% Pour chaque entrée d'un Merge, la garde du sous-système d'où vient son
% signal — en remontant les passe-plats —, ou 0 s'il n'en vient d'aucun.
function gardes = gardesDesSources(c, k)
    gardes = zeros(c.nIn(k), 1);
    for j = 1:c.nIn(k)
        gp = c.entrees{k}(j);
        for pas = 1:c.n
            if gp == 0
                break
            end
            a = c.proprio(gp);
            if c.garde(a) > 0
                gardes(j) = c.garde(a);
                break
            end
            if ~strcmp(c.types{a}, 'signalconversion')
                break
            end
            gp = c.entrees{a}(c.rang(gp));
        end
    end
end

% === passages par zéro ========================================================
%
% Les blocs dont la sortie casse quand un signal franchit un seuil : leur
% entrée, comparée au seuil, est surveillée par le solveur à pas
% variable, qui localise l'instant du franchissement au lieu de le
% sauter. C'est la liste de Simulink, et son réglage : ZeroCrossControl
% vaut UseLocalSettings (le paramètre ZeroCross de chaque bloc décide),
% EnableAll ou DisableAll.
function zc = passagesParZero(c)
    zc = false(1, c.n);
    capables = {'abs', 'sign', 'comparetozero', 'comparetoconstant', 'relational', ...
                'minmax', 'saturation', 'deadzone', 'relay', 'hitcrossing', 'switch', ...
                'integrator', 'backlash', 'coulombfriction', 'garde'};
    controle = 'UseLocalSettings';
    if isstruct(c.config) && isfield(c.config, 'ZeroCrossControl')
        controle = char(c.config.ZeroCrossControl);
    end
    if strcmpi(controle, 'DisableAll')
        return
    end
    for k = 1:c.n
        enCours('bloc', k);
        type = c.types{k};
        if ~any(strcmp(type, capables))
            continue
        end
        p = c.p{k};
        switch type
            case 'integrator'
                % Les bornes cassent, et les fronts de l'entrée de remise.
                w = (numel(c.seg{k}) - 6) / 2;
                remise = c.seg{k}(2 + 2 * w);
                if c.seg{k}(1) == 0 && ~(remise >= 1 && remise <= 3)
                    continue
                end
            case 'minmax'
                if c.nIn(k) < 2
                    continue
                end
            case 'garde'
                if c.nIn(k) == 0 || p.Action ~= 0
                    continue   % une action se décide au pas majeur, par le If
                end
        end
        if strcmpi(controle, 'EnableAll')
            zc(k) = true;
        else
            zc(k) = ~isfield(p, 'ZeroCross') || strcmpi(char(p.ZeroCross), 'on');
        end
    end
end

% === diagnostics ===============================================================

function diagnostiquer(c)
    niveau = lower(char(c.config.UnconnectedInputMsg));
    if ~strcmp(niveau, 'none')
        for k = 1:c.n
            if strcmp(c.types{k}, 'from')
                continue
            end
            for j = find(c.entrees{k} == 0)
                signaler(niveau, 'Simulink:Engine:InputNotConnected', ...
                         ['Le port d''entree %d de ''%s'' n''est pas relie : il vaut ' ...
                          'zero.'], j, c.chemins{k});
            end
        end
    end
    niveau = lower(char(c.config.UnconnectedOutputMsg));
    if ~strcmp(niveau, 'none')
        lus = false(1, c.nPorts);
        for k = 1:c.n
            e = c.entrees{k};
            lus(e(e > 0)) = true;
        end
        for gp = find(~lus)
            k = c.proprio(gp);
            signaler(niveau, 'Simulink:Engine:OutputNotConnected', ...
                     'Le port de sortie %d de ''%s'' n''est relie a rien.', ...
                     c.rang(gp), c.chemins{k});
        end
    end
    niveau = lower(char(c.config.AlgebraicLoopMsg));
    if ~strcmp(niveau, 'none') && ~isempty(c.boucles)
        textes = cell(1, numel(c.boucles));
        for i = 1:numel(c.boucles)
            textes{i} = strjoin(c.chemins(c.boucles{i}.blocs), ', ');
        end
        signaler(niveau, 'Simulink:Engine:AlgebraicLoop', ...
                 ['Le modele ''%s'' contient %d boucle(s) algebrique(s) : %s. Elle(s) ' ...
                  'est (sont) resolue(s) a chaque pas par la methode de Newton ; le ' ...
                  'reglage AlgebraicLoopMsg du modele regle ce message.'], ...
                 c.nom, numel(c.boucles), strjoin(textes, ' ; '));
    end
end

function signaler(niveau, identifiant, format, varargin)
    if strcmp(niveau, 'error')
        error(identifiant, format, varargin{:});
    else
        warning(identifiant, format, varargin{:});
    end
end

% === l'espace de travail =======================================================

% Un bloc « depuis l'espace de travail » lit une variable de l'espace de
% base : une matrice [temps valeurs...], dont chaque colonne après la
% première est un élément du signal, ou la structure à temps que SIM
% journalise.
function [temps, valeurs] = lireSignalEspace(p, nomBloc)
    nomVariable = char(p.VariableName);
    if isfield(p, 'Donnees')
        % une entrée externe du modèle : ses données sont déjà là
        temps = double(p.Donnees.temps(:));
        valeurs = double(p.Donnees.valeurs);
        return
    end
    if isempty(nomVariable)
        error('Simulink:blocks:FromWorkspaceVariableNotFound', ...
              ['Le bloc ''%s'' ne dit pas quelle variable lire : donnez-lui ' ...
               'un parametre VariableName.'], nomBloc);
    end
    if ~isvarname(nomVariable)
        donnees = matlibre_sl_expression(nomVariable, nomBloc, 'VariableName');
    elseif evalin('base', sprintf('exist(''%s'', ''var'')', nomVariable)) ~= 1
        error('Simulink:blocks:FromWorkspaceVariableNotFound', ...
              ['Le bloc ''%s'' lit la variable ''%s'', qui n''existe pas dans ' ...
               'l''espace de travail de base.'], nomBloc, nomVariable);
    else
        donnees = evalin('base', nomVariable);
    end
    if isa(donnees, 'timeseries')
        [temps, valeurs] = matlibre_sl_serie(donnees);
    elseif isstruct(donnees) && isfield(donnees, 'time') && isfield(donnees, 'signals')
        temps = double(donnees.time(:));
        valeurs = double(donnees.signals(1).values);
        if isvector(valeurs)
            valeurs = valeurs(:);
        end
    elseif isnumeric(donnees) && ismatrix(donnees) && size(donnees, 2) >= 2 && ...
            (size(donnees, 1) >= 2 || size(donnees, 2) == 2)
        % Une seule ligne de plus de deux nombres serait ambiguë : un
        % instant et plusieurs valeurs, ou une suite de valeurs écrite en
        % ligne ? On la refuse plutôt que de deviner.
        temps = double(donnees(:, 1));
        valeurs = double(donnees(:, 2:end));
    else
        error('Simulink:SimInput:InvalidFormat', ...
              ['La variable ''%s'' que lit le bloc ''%s'' doit porter au moins deux ' ...
               'colonnes — le temps puis une valeur par element du signal —, la ' ...
               'structure a temps que SIM journalise, ou une timeseries. Elle est de ' ...
               'taille %s.'], ...
              nomVariable, nomBloc, mat2str(size(donnees)));
    end
    if numel(temps) ~= size(valeurs, 1)
        error('Simulink:SimInput:InvalidFormat', ...
              'La variable ''%s'' porte %d instants et %d valeurs.', ...
              nomVariable, numel(temps), size(valeurs, 1));
    end
end

% Une période d'échantillonnage : -1 (héritée), 0 (continue), Inf
% (constante), une période positive, ou [période, décalage]. Vide
% seulement là où le bloc l'admet par défaut.
function verifierPeriode(v, defaut, chemin, nom)
    if isempty(v) && isempty(defaut)
        return
    end
    v = double(v);
    bon = ~isempty(v) && numel(v) <= 2 && isreal(v) && ~any(isnan(v(:))) && ...
          (v(1) == -1 || v(1) >= 0);
    if bon && numel(v) == 2
        bon = isfinite(v(2)) && (v(1) > 0 || v(2) == 0);
    end
    if ~bon
        error('Simulink:SampleTime:InvalidSampleTime', ...
              ['La periode d''echantillonnage de ''%s'' (parametre %s) vaut %s : elle ' ...
               'doit etre -1 (heritee), 0 (continue), inf (constante), une periode ' ...
               'positive, ou [periode, decalage].'], chemin, nom, apercu(v));
    end
end

% Le bloc que la compilation traite, et le modèle aplati où il se trouve.
function varargout = enCours(action, varargin)
    persistent k blocs chemins
    if isempty(k)
        k = 0;
        blocs = {};
        chemins = {};
    end
    switch action
        case 'modele'
            blocs = varargin{1};
            chemins = varargin{2};
            k = 0;
        case 'bloc'
            k = varargin{1};
        case 'lire'
            if k < 1 || k > numel(blocs)
                varargout = {0, [], ''};
            else
                varargout = {k, blocs{k}, chemins{k}};
            end
        case 'sauver'
            varargout = {{k, blocs, chemins}};
        case 'restaurer'
            etat = varargin{1};
            [k, blocs, chemins] = etat{:};
    end
end

function t = apercu(v)
    if isempty(v)
        t = '[]';
    elseif isnumeric(v) || islogical(v)
        t = mat2str(v, 6);
        if numel(t) > 40
            t = sprintf('une matrice %dx%d', size(v, 1), size(v, 2));
        end
    else
        t = ['''' char(v) ''''];
    end
end

% Les valeurs qu'aucun bloc ne sait employer, refusées avant de simuler
% comme Simulink les refuse : un nombre complexe (MatLibre ne simule que
% des signaux réels), une valeur vide là où le bloc en attend une, un
% nombre de ports ou de retards qui n'est pas un entier positif, un
% retard négatif ou infini.
% Les paramètres qu'un nombre complexe n'embarrasse pas : ceux des blocs
% qui calculent en complexe.
function oui = complexeAdmis(type, nom)
    admis = {'constant.Value', 'gain.Gain', 'bias.Bias', 'ic.Value', ...
             'delay.InitialCondition', 'memory.InitialCondition', 'difference.ICPrevInput', ...
             'tappeddelay.vinit', 'realimagtocomplex.ConstantPart'};
    oui = any(strcmp([type '.' nom], admis));
end

function verifierNombre(v, defaut, chemin, nom, complexe)
    if ~isreal(v) && ~(nargin >= 5 && complexe)
        error('Simulink:Parameters:InvParamSetting', ...
              ['Le parametre ''%s'' de ''%s'' vaut %s, un nombre complexe : ce parametre ' ...
               'n''admet que des reels.'], nom, chemin, apercu(v));
    end
    if isempty(v) && ~isempty(defaut) && ...
       ~any(strcmp(nom, {'Zeros', 'Poles', 'A', 'B', 'C', 'D', 'X0'}))
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' est vide : le bloc demande une valeur.', ...
              nom, chemin);
    end
    entiers = {'Port', 'NumDelays', 'BufferSize', 'NumberOfTableDimensions', ...
               'NumInputPorts', 'Decimation'};
    if any(strcmp(nom, entiers)) && ~(isscalar(v) && v >= 1 && v == round(v) && isfinite(v))
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' vaut %s : il faut un entier positif.', ...
              nom, chemin, apercu(v));
    end
    if strcmp(nom, 'DelayLength') && ~(isscalar(v) && v >= 0 && v == round(v) && isfinite(v))
        error('Simulink:Parameters:InvParamSetting', ...
              'Le parametre ''%s'' de ''%s'' vaut %s : il faut un entier positif ou nul.', ...
              nom, chemin, apercu(v));
    end
    if strcmp(nom, 'ConcatenateDimension') && ~(isscalar(v) && any(v == [1 2]))
        error('Simulink:Parameters:InvParamSetting', ...
              ['Le parametre ''%s'' de ''%s'' vaut %s : on concatene selon la dimension ' ...
               '1 ou 2.'], nom, chemin, apercu(v));
    end
    if strcmp(nom, 'DelayTime') && ~(all(isfinite(v(:))) && all(v(:) >= 0))
        error('Simulink:blocks:TransportDelayNegativeDelay', ...
              ['Le retard de ''%s'' vaut %s : il doit etre positif ou nul, et fini.'], ...
              chemin, apercu(v));
    end
end

% La liste des signes d'une somme ou d'un produit : un entier positif,
% ou des caractères admis — l'espaceur | en plus.
function verifierSignes(v, admis, chemin, nom, attendu)
    if isnumeric(v) || islogical(v)
        bon = isscalar(v) && isreal(v) && v >= 1 && v == round(v);
    else
        texte = strtrim(char(v));
        bon = ~isempty(regexp(texte, '^\d+$', 'once')) && str2double(texte) >= 1;
        if ~bon
            reste = texte(~ismember(texte, ['|' admis]));
            bon = isempty(reste) && any(ismember(texte, admis));
        end
    end
    if ~bon
        error('Simulink:Parameters:InvParamSetting', ...
              ['Le parametre ''%s'' de ''%s'' vaut %s : il faut un nombre d''entrees, ou ' ...
               '%s.'], nom, chemin, apercu(v), attendu);
    end
end

% Une condition initiale sur la grille du type à virgule fixe de la sortie
% du bloc, comme Simulink la range ; telle quelle pour un autre type.
function v = surGrille(c, k, v)
    if isfield(c, 'typePort') && c.nOut(k) > 0
        type = c.typePort(c.portDebut(k));
        if type > 100 && type <= 200
            v = double(matlibre_sl_types('convertir', type, v));
        end
    end
end
