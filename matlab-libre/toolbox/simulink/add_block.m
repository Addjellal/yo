function modele = add_block(modele, type, nom, varargin)
%ADD_BLOCK Ajoute un bloc au modèle.
%   MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...) ajoute au
%   modèle un bloc du TYPE donné, nommé NOM. Le type se désigne par son nom
%   MatLibre (« gain »), par son type Simulink (« Gain », « Sin »), par son
%   nom dans la bibliothèque (« Sine Wave ») ou par son chemin
%   (« simulink/Math Operations/Gain ») ; le bloc garde le nom MatLibre,
%   que GET_PARAM(...,'BlockType') rend.
%
%   Sources — elles n'ont pas d'entrée :
%     constant     Value, SampleTime            scalaire, vecteur ou matrice
%     step         Time, Before, After
%     ramp         Slope, Start, InitialOutput
%     sine         Amplitude, Frequency, Phase, Bias, SampleTime
%     clock        —                            le temps
%     digitalclock SampleTime                   le temps, échantillonné
%     pulsegenerator Amplitude, Period, PulseWidth (en % de la période),
%                  PhaseDelay, PulseType, SampleTime
%     ground       —                            un zéro
%     repeatingsequence rep_seq_t, rep_seq_y    une séquence périodique
%     randomnumber Mean, Variance, Seed, SampleTime
%     uniformrandomnumber Minimum, Maximum, Seed, SampleTime
%     inport       Port, Value, PortDimensions  l'entrée du modèle
%     fromworkspace VariableName, Interpolate, OutputAfterFinalValue
%     fromfile     FileName, InterpolationWithinTimeRange,
%                  ExtrapolationAfterLastDataPoint — le fichier MAT
%                  qu'écrit To File : les instants sur la première ligne
%     from         GotoTag                      le signal d'un Goto
%     chirp        f1, T, f2                    la fréquence va de f1 à f2 en T
%     bandlimitedwhitenoise Cov, Ts, seed       variance Cov / Ts, tenu Ts
%     counterfreerunning NumBits, tsamp ; counterlimited uplimit, tsamp
%     signalgenerator WaveForm (sine, square, sawtooth, random),
%                  Amplitude, Frequency, Units (rad/sec, Hertz)
%     repeatingsequencestair OutValues, tsamp   une valeur par instant
%     repeatingsequenceinterpolated OutValues, TimeValues, LookUpMeth,
%                  tsamp — la séquence datée, de période la dernière date
%     signaleditor FileName, ActiveScenario — une sortie par signal du
%                  scénario, un Simulink.SimulationData.Dataset de
%                  timeseries rangé dans le fichier MAT ; interpolé,
%                  tenu après sa dernière valeur
%     fromspreadsheet FileName (un fichier texte : CSV, TXT), Range,
%                  InterpolationWithinTimeRange,
%                  ExtrapolationAfterLastDataPoint — la première colonne
%                  donne les instants, les suivantes le signal
%
%   Les blocs à cassure — abs, sign, saturation, deadzone, relay,
%   relational, comparaisons, minmax, switch, hitcrossing, backlash,
%   coulombfriction, step, fromworkspace, integrator borné — portent
%   ZeroCross ('on' par défaut) : à pas variable, le solveur localise le
%   franchissement de leur seuil.
%
%   Opérations :
%     gain         Gain, Multiplication : 'Element-wise(K.*u)',
%                  'Matrix(K*u)', 'Matrix(u*K)'
%     sum          Signs ('+-', '|++'...) ; une seule entrée : la somme
%                  de ses éléments
%     product      Inputs ('**', '*/'), Multiplication : 'Element-wise(.*)'
%                  ou 'Matrix(*)'
%     abs, sign, unaryminus, bias (Bias), dotproduct
%     math         Operator : exp, log, 10^u, log10, magnitude^2, square,
%                  sqrt, pow, conj, reciprocal, hypot, rem, mod,
%                  transpose, hermitian
%     trigonometry Operator : sin, cos, tan, asin, acos, atan, atan2, sinh,
%                  cosh, tanh, asinh, acosh, atanh, sincos (deux sorties)
%     minmax       Function (min, max), Inputs
%     rounding     Operator : floor, ceil, round, fix
%     polynomial   coefs                        polyval(coefs, u)
%     sqrt         Operator : sqrt, signedSqrt, rSqrt ; « Signed Sqrt » et
%                  « Reciprocal Sqrt » de la bibliothèque en sont réglés
%     sinewavefunction Amplitude, Bias, Frequency, Phase — A sin(F u + P) + B,
%                  l'entrée tenant lieu de temps (SineType 'Time based')
%     permutedimensions Order ; squeeze — comme PERMUTE et SQUEEZE
%     algebraicconstraint Constraint ('f(z) = 0', 'f(z) = z'), InitialGuess —
%                  sa sortie z revient à son entrée par une boucle
%                  algébrique, que la méthode de Newton résout
%     sampletimemath TsampMathOp (+, -, *, /, Ts Only, 1/Ts Only),
%                  weightValue — l'entrée et w Ts, Ts la période du bloc
%     minmaxrunningresettable Function (min, max), vinit — deux entrées :
%                  u, et R qui remet à vinit
%
%   Non-linéarités :
%     saturation   UpperLimit, LowerLimit
%     deadzone     UpperValue, LowerValue
%     relay        OnSwitch, OffSwitch, OnOutput, OffOutput
%     quantizer    QuantizationInterval
%     ratelimiter  RisingSlewLimit, FallingSlewLimit, InitialOutput
%     hitcrossing  HitCrossingOffset, HitCrossingDirection
%     backlash     BacklashWidth, InitialOutput
%     coulombfriction Offset, Gain
%     lookup       BreakpointsData, TableData, InterpMethod, ExtrapMethod ;
%                  NumberOfTableDimensions (jusqu'à 6) et
%                  BreakpointsForDimension2 à 6 en font une table à
%                  plusieurs entrées (n-D Lookup Table)
%     lookup2d     BreakpointsForDimension1, BreakpointsForDimension2, Table
%     directlookup Table, NumberOfTableDimensions (1 à 6) — l'élément que
%                  désignent ses entrées, à partir de 0
%     lookuptabledynamic LookUpMeth — trois entrées : x, xdat, ydat, la table
%                  arrivant par les signaux
%     prelookup    BreakpointsData, OutputSelection, ExtrapMethod,
%                  UseLastBreakpoint — deux sorties : l'indice k, à partir
%                  de 0 (uint32), et la fraction f
%     interpolationusingprelookup NumberOfTableDimensions, Table,
%                  InterpMethod, ExtrapMethod, ValidIndexMayReachLast — les
%                  entrées k1, f1, k2, f2... de Prelookup
%     sinecosine   Formula, NumDataPoints — sin(2 pi u), cos(2 pi u) ou les
%                  deux, lus dans une table d'un quart d'onde
%     saturationdynamic, deadzonedynamic, ratelimiterdynamic — trois
%                  entrées : up, u, lo
%     wraptozero   Threshold                    zéro au-delà du seuil
%
%   Logique :
%     logic        Operator : AND, OR, NAND, NOR, XOR, NXOR, NOT ; Inputs
%     relational   Operator : ==, ~=, <, <=, >=, >
%     comparetoconstant relop, const ; comparetozero relop
%     detectchange, detectincrease, detectdecrease  vinit
%     intervaltest uplimit, lowlimit, IntervalClosedRight, IntervalClosedLeft
%     combinatoriallogic TruthTable        la ligne que désignent les entrées,
%                                          la première en poids fort
%     detectrisepositive, detectrisenonnegative, detectfallnegative,
%                  detectfallnonpositive  vinit — le front du test u > 0,
%                  u >= 0, u < 0, u <= 0
%     intervaltestdynamic IntervalClosedRight, IntervalClosedLeft — trois
%                  entrées : up, u, lo
%     bitwiseoperator logicop (AND, OR, NAND, NOR, XOR, NOT), UseBitMask,
%                  BitMask, NumInputPorts — sur des entiers
%     bitset, bitclear iBit (à partir de 0) ; shiftarithmetic
%                  BitShiftNumber, BitShiftDirection (Left, Right,
%                  Bidirectional) — à droite, le signe se conserve
%
%   Aiguillage :
%     switch       Threshold, Criteria : 'u2 >= Threshold', 'u2 > Threshold',
%                  'u2 ~= 0' — la première entrée passe, ou la troisième
%     multiportswitch Inputs, DataPortOrder ; une seule entrée de données
%                  (« Index Vector ») : l'élément que désigne la commande
%     environmentcontroller —              deux entrées, Sim et Coder : rend Sim
%     bustovector  —                            un bus de scalaires, en vecteur
%     busassignment AssignedSignals ('a,b.c') — le bus, puis un signal par
%                  élément nommé, qui le remplace
%     mux          Inputs (un nombre, ou les largeurs)
%     demux        Outputs (un nombre, ou les largeurs)
%     selector     Indices
%     assignment   NumberOfDimensions (1 ou 2), IndexMode, IndexOptionArray
%                  ('Assign all', 'Index vector (dialog)', 'Starting index
%                  (dialog)'), IndexParamArray, OutputInitialize,
%                  OutputSizeArray — Y0, dont les éléments aux indices
%                  reçoivent ceux de U
%     signalspecification Dimensions, OutDataTypeStr — laisse passer, en
%                  vérifiant les dimensions et le type
%     concatenate  NumInputs, Mode, ConcatenateDimension
%     reshape      OutputDimensionality, OutputDimensions
%     goto         GotoTag, TagVisibility : local, scoped, global
%     signalconversion  —
%     merge        Inputs, InitialOutput        l'entrée dont le sous-système
%                                               vient de calculer
%     manualswitch sw ('1' : la première entrée, '0' : la seconde)
%     datastorememory DataStoreName, InitialValue ; datastoreread et
%                  datastorewrite DataStoreName — une mémoire partagée,
%                  lue avant d'être écrite à chaque pas
%     ratetransition OutPortSampleTime, X0, Deterministic — tenue vers une
%                  période plus lente, retard d'une période lente vers une
%                  plus rapide
%     variantsource VariantControls ({'V == 1', 'V == 2'}), VariantControlMode,
%                  LabelModeActiveChoice, AllowZeroVariantControls — une
%                  entrée par condition, seule l'active passe ;
%                  variantsink de même, une sortie par condition
%     ic           Value                        au premier instant, puis l'entrée
%     width        —                            le nombre d'éléments de l'entrée
%
%   Continu — l'intégrateur et les représentations d'état coupent les
%   boucles :
%     integrator   InitialCondition, LimitOutput, UpperSaturationLimit,
%                  LowerSaturationLimit, ExternalReset (none, rising,
%                  falling, either, level, level hold : une entrée de
%                  remise), InitialConditionSource (external : une entrée
%                  de condition initiale), ShowSaturationPort,
%                  ShowStatePort (le port d'état, 'integ/State') ;
%                  « Integrator Limited » le borne d'avance entre 0 et 1
%     derivative   —                            vaut zéro au premier pas
%     transferfcn  Numerator, Denominator
%     statespace   A, B, C, D, X0
%     zeropole     Zeros, Poles, Gain
%     transportdelay DelayTime, InitialOutput, BufferSize
%     variabletransportdelay VariableDelayType ('Variable transport delay' :
%                  la durée qu'on lit quand le signal entre ; 'Variable
%                  time delay' : celle qu'on lit quand il sort),
%                  MaximumDelay, InitialOutput, MaximumPoints, ZeroDelay —
%                  deux entrées : u, et le retard
%     pidcontroller P, I, D, N (dérivée filtrée par N/(1+N/s)), Controller
%                  (PID, PI, PD, P, I), Form (Parallel, Ideal), TimeDomain
%                  (Continuous-time, Discrete-time : SampleTime,
%                  IntegratorMethod, FilterMethod), UseFilter,
%                  InitialConditionForIntegrator, InitialConditionForFilter,
%                  InitialConditionSource (external : entrées I0 et D0),
%                  ExternalReset (entrée Reset), LimitOutput,
%                  UpperSaturationLimit, LowerSaturationLimit,
%                  AntiWindupMode (back-calculation : Kb ; clamping) ; les
%                  entrées : u, Reset, I0, D0 ; « Discrete PID Controller »
%                  est réglé en Discrete-time
%     secondorderintegrator ICX, ICDXDT         deux sorties : x et dx/dt
%
%   Discret — ils ne calculent qu'aux instants de leur période :
%     delay        InitialCondition, DelayLength, SampleTime ; aussi
%                  nommé unitdelay ; DelayLengthSource ('Input port' : la
%                  longueur par une entrée d, jusqu'à DelayLengthUpperLimit),
%                  ShowEnablePort (entrée enable : désactivé, il tient sa
%                  sortie et ses états), ExternalReset (Rising, Falling,
%                  Either, Level, Level hold), InitialConditionSource
%                  ('Input port' : entrée x0) — les entrées : u, d, enable,
%                  remise, x0 ; Resettable Delay, Enabled Delay et
%                  Variable Integer Delay de la bibliothèque en sont réglés
%     memory       InitialCondition             la valeur du pas précédent
%     zoh          SampleTime (dix pas par défaut)
%     discreteintegrator Gain, SampleTime, InitialCondition,
%                  IntegratorMethod : ForwardEuler, BackwardEuler, Trapezoidal
%                  (ou 'Integration: ...', et 'Accumulation: ...', qui ne
%                  multiplie pas par la période), LimitOutput,
%                  UpperSaturationLimit, LowerSaturationLimit,
%                  ExternalReset (rising, falling, either, level, sampled
%                  level), InitialConditionSource (external : entrée x0),
%                  ShowSaturationPort, ShowStatePort — les entrées : u,
%                  remise, x0 ; les sorties : y, saturation, état
%     discretetransferfcn Numerator, Denominator (puissances de z),
%                  SampleTime
%     discretefilter Numerator, Denominator (puissances de z^-1), SampleTime
%     discretestatespace A, B, C, D, X0, SampleTime
%     discretezeropole Zeros, Poles, Gain, SampleTime
%     discretederivative gainval, ICPrevScaledInput   K (u - u d'avant) / Ts
%     difference   ICPrevInput                  u - u d'avant
%     tappeddelay  NumDelays, vinit, samptime, DelayOrder, includeCurrent
%     discretefirfilter Coefficients, InitialStates, SampleTime
%     transferfcnfirstorder PoleZ, ICPrevOutput   (1 - p) z / (z - p)
%     transferfcnleadorlag PoleZ, ZeroZ, Gain, ICPrevOutput, ICPrevInput
%     transferfcnrealzero ZeroZ, ICPrevInput      (z - zéro) / z
%     firstorderhold Ts                         prolonge les deux derniers
%                                               échantillons en ligne droite
%
%   Sorties :
%     outport      Port, InitialOutput, OutputWhenDisabled (held, reset)
%     scope        NumInputPorts ; display ; terminator
%     toworkspace  VariableName, SaveFormat : Array, Structure With Time,
%                  Structure
%     tofile       Filename, MatrixName, Decimation — [temps ; signal] dans
%                  un fichier MAT, en fin de simulation
%     xygraph      xmin, xmax, ymin, ymax        y en fonction de x
%     stopsimulation — arrête la simulation dès que l'entrée n'est plus nulle
%     assertion    Enabled, StopWhenAssertionFail — échoue dès que
%                  l'entrée s'annule
%     checkstaticrange, checkstaticgap  min, max, min_included, max_included ;
%                  checkstaticlowerbound  min, min_included ;
%                  checkstaticupperbound  max, max_included — échouent quand
%                  le signal sort de ses bornes (ou tombe dans l'écart)
%     checkdynamicrange, checkdynamicgap — trois entrées : max, sig, min ;
%                  checkdynamiclowerbound (min, sig),
%                  checkdynamicupperbound (max, sig) — les bornes sont des
%                  signaux ; tous portent enabled et stopWhenAssertionFail
%
%   Fonctions de l'utilisateur :
%     fcn          Expr                         une expression de u, scalaire :
%                                               'u(1)*sin(u(2))', ou u[2]
%     interpretedmatlabfunction MATLABFcn, OutputDimensions — un nom de
%                  fonction ('sin') ou une expression de u
%     matlabfunction Script                     le texte d'une fonction
%                  MATLAB : ses arguments sont les entrées, ses sorties
%                  les sorties ; une variable persistante y garde un état
%     sfunction    FunctionName, Parameters     une S-fonction de niveau 1,
%                  [sys,x0,str,ts] = f(t,x,u,flag,p1,...)
%     chart        Chart, Inputs, Outputs, InitialContext, SampleTime —
%                  une machine à états bâtie par SFCHART, SFSTATE et
%                  SFTRANSITION, états emboîtés, régions parallèles et
%                  logique temporelle compris (SFAFTER... en secondes de
%                  simulation) ; ses sorties sont des champs de son
%                  contexte, ou « etat », le rang de l'état actif. Les
%                  événements d'entrée de la machine (SFEVENT) arrivent
%                  par un port de déclenchement, après les entrées ; ses
%                  événements de sortie ont chacun un port, après les
%                  sorties, qui peut appeler un sous-système appelé par
%                  fonction
%
%   Un schéma dans un bloc :
%     subsystem    Model                un modèle entier, abrégé en un bloc ;
%                  'Enabled Subsystem', 'Triggered Subsystem', 'Enabled
%                  and Triggered Subsystem', 'If Action Subsystem',
%                  'Switch Case Action Subsystem', 'Function-Call
%                  Subsystem', 'For Iterator Subsystem' et 'While Iterator
%                  Subsystem' en donnent un qui porte déjà In1, Out1 et
%                  son port de contrôle ou son itérateur, comme dans la
%                  bibliothèque de Simulink. Variant ('on') en fait un
%                  sous-système à variantes : ses variantes, des
%                  sous-systèmes posés dedans sans lien, portent chacune
%                  sa condition VariantControl — 'Mode == 1', le nom
%                  d'un Simulink.Variant, '(default)' —, et seule celle
%                  dont la condition est vraie calcule ; ses ports se
%                  raccordent par leur nom. VariantControlMode ('label')
%                  et LabelModeActiveChoice la choisissent par étiquette,
%                  AllowZeroVariantControls ('on') admet qu'aucune ne
%                  le soit. 'Variant Subsystem' en donne un garni de deux
%                  variantes, V == 1 et V == 2
%     enableport   StatesWhenEnabling (held, reset)    posé dedans : il ne
%                  calcule que quand ce port reçoit un signal positif
%     triggerport  TriggerType (rising, falling, either, function-call)
%                  posé dedans : il ne calcule qu'aux fronts du signal de
%                  ce port, ou quand un Function-Call Generator l'appelle
%     functioncallgenerator sample_time    appelle, à chaque instant de sa
%                  période, le sous-système relié à son port
%     foriterator  IterationLimit, IterationSource (internal, external),
%                  IndexMode, ShowIterationPort, ResetStates (held, reset)
%                  posé dedans : le sous-système calcule N fois par pas
%     whileiterator WhileBlockType (while, do-while), MaxIters,
%                  ShowIterationPort, ResetStates — posé dedans : il
%                  calcule tant que l'entrée cond est vraie ; en while,
%                  l'entrée IC dit s'il commence
%     actionport   InitializeStates     posé dedans : il calcule quand un
%                  If ou un Switch Case le désigne
%     if           NumInputs, IfExpression, ElseIfExpressions, ShowElse —
%                  conditions sur u1, u2... ; une sortie d'action par
%                  branche
%     switchcase   CaseConditions ('{1, [2 3]}'), ShowDefaultCase
%     modelreference ModelName             un autre modèle — variable,
%                  fichier .m, .slx ou .mdl —, relu à chaque simulation
%
%   Le sous-système porte le modèle qu'il abrège, bâti comme les autres
%   par NEW_SYSTEM. Ses blocs INPORT sont ses entrées et ses blocs OUTPORT
%   ses sorties, dans l'ordre de leur paramètre Port. SIM le déplie avant
%   de simuler : le résultat est exactement celui du schéma écrit à plat.
%   Un port de contrôle posé dedans en fait un sous-système conditionnel :
%   ce port est une entrée de plus, après les autres, que ADD_LINE
%   désigne par 'sous/Enable', 'sous/Trigger' ou 'sous/Ifaction'. À
%   l'arrêt, ses sorties tiennent leur dernière valeur, ou reviennent à
%   leur valeur initiale (OutputWhenDisabled), et ses états tiennent, ou
%   repartent à la reprise (StatesWhenEnabling). Un sous-système itéré ne
%   se déplie pas : son modèle calcule plusieurs fois par pas, ses blocs à
%   état avançant à chaque itération, et ses sorties sont celles de la
%   dernière.
%
%   ADD_BLOCK(MODELE,'bibliotheque/bloc',NOM) recopie un bloc d'une
%   bibliothèque bâtie par NEW_SYSTEM(...,'Library') — ou d'un autre
%   modèle —, ouverte, dans l'espace de travail ou en fichier. Le bloc
%   d'une bibliothèque y reste lié : GET_PARAM(...,'ReferenceBlock') le
%   dit, et la simulation reprend la bibliothèque telle qu'elle est alors,
%   en gardant les valeurs du masque que le bloc a reçues.
%
%   Un type inconnu est refusé, comme un paramètre que le bloc n'a pas :
%   rangé sans être lu, il ferait croire à un réglage qui n'a pas lieu.
%   Les noms de paramètres se lisent sans égard à la casse, et les noms
%   de Simulink valent pour ceux de MatLibre (« Inputs » pour les signes
%   d'une sommation). Deux blocs du même modèle ne portent pas le même
%   nom ; ADD_BLOCK(...,'MakeNameUnique','on') en choisit un libre.
%
%   Tout bloc accepte en outre POSITION, [gauche haut droite bas] comme
%   dans Simulink : il garde alors la place qu'on lui donne, au lieu
%   d'être rangé par couches.
%
%   Un paramètre numérique donné entre apostrophes est une expression,
%   évaluée dans l'espace de travail de base au moment où l'on simule —
%   comme dans Simulink. C'est ainsi qu'un modèle et un programme
%   partagent leurs variables :
%
%      K = 4;
%      m = add_block(m, 'gain', 'k', 'Gain', 'K');   % non pas 4, mais K
%      r = sim(m, 1, 0.01);                          % le gain vaut 4
%      K = 10; r = sim(m, 1, 0.01);                  % il vaut 10
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'Integrator', 'integ', 'InitialCondition', 0);
%      get_param(m, 'integ', 'BlockType')         % 'integrator'
%
%   Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, DELETE_BLOCK, SIM, OPEN_SYSTEM.
    nom = char(nom);
    % « bibliotheque/bloc » : un bloc d'une bibliothèque de l'utilisateur,
    % ou d'un autre modèle, recopié — et lié s'il vient d'une bibliothèque.
    [source, reference] = blocAilleurs(type);
    if ~isempty(source)
        modele = poserCopie(modele, source, reference, nom, varargin);
        return
    end
    entree = matlibre_sl_catalogue('type', type);
    if strcmp(entree.famille, 'Interne')
        % les blocs que le dépliage fabrique ne se posent pas à la main
        error('Simulink:Commands:InvalidBlockType', ...
              ['Le type de bloc ''%s'' est interne a MatLibre : le depliage des ' ...
               'sous-systemes le fabrique, il ne se pose pas. Posez le sous-systeme.'], ...
              char(type));
    end
    unique = false;
    reglages = {};
    for k = 1:2:numel(varargin)
        if k + 1 > numel(varargin)
            error('Simulink:Commands:ParamValuePairs', ...
                  'Les parametres du bloc ''%s'' se donnent par paires : un nom, une valeur.', ...
                  nom);
        end
        if strcmpi(char(varargin{k}), 'MakeNameUnique')
            unique = strcmpi(char(varargin{k + 1}), 'on');
            continue
        end
        reglages(end + 1:end + 2) = varargin(k:k + 1); %#ok<AGROW>
    end
    if ~isfield(modele, 'blocs')
        error('Simulink:Commands:InvalidModel', ...
              'ADD_BLOCK attend un modele bati par NEW_SYSTEM.');
    end
    % Les sous-systèmes conditionnels de la bibliothèque arrivent garnis,
    % comme dans Simulink : une entrée reliée à une sortie, et leurs ports
    % de contrôle.
    if strcmp(entree.type, 'subsystem') && ...
       ~any(strcmpi(reglages(1:2:end), 'Model') | strcmpi(reglages(1:2:end), 'Modele'))
        gabarit = gabaritDeSousSysteme(type, nom);
        if ~isempty(gabarit)
            reglages(end + 1:end + 2) = {'Model', gabarit};
        end
    end
    % Divide, Subtract, Sum of Elements, Product of Elements : des Product
    % et des Sum que la bibliothèque de Simulink règle d'avance.
    avance = prereglages(type);
    for j = 1:size(avance, 1)
        if ~any(ismember(lower(reglages(1:2:end)), lower(avance{j, 3})))
            reglages(end + 1:end + 2) = avance(j, 1:2);
        end
    end
    % Un « Variant Subsystem » de la bibliothèque est un sous-système à
    % variantes : Variant vaut 'on'.
    if strcmp(entree.type, 'subsystem') && estVariante(type) && ...
       ~any(strcmpi(reglages(1:2:end), 'Variant'))
        reglages(end + 1:end + 2) = {'Variant', 'on'};
    end
    if existe(modele, nom)
        if ~unique
            error('Simulink:Commands:AddBlockCantAdd', ...
                  ['Le modele ''%s'' porte deja un bloc nomme ''%s'' : deux blocs d''un ' ...
                   'meme systeme ne portent pas le meme nom. ADD_BLOCK(..., ' ...
                   '''MakeNameUnique'', ''on'') en choisit un libre.'], ...
                  char(modele.nom), nom);
        end
        base = regexprep(nom, '\d+$', '');
        rang = 1;
        while existe(modele, sprintf('%s%d', base, rang))
            rang = rang + 1;
        end
        nom = sprintf('%s%d', base, rang);
    end
    bloc = struct();
    bloc.type = entree.type;
    bloc.nom = nom;
    bloc.parametres = struct();
    for k = 1:2:numel(reglages)
        canon = matlibre_sl_catalogue('parametre', entree, reglages{k});
        if isempty(canon)
            error('Simulink:Commands:ParamUnknown', ...
                  ['Le bloc ''%s'' (%s) n''a pas de parametre nomme ''%s''. Ses ' ...
                   'parametres sont : %s.'], nom, entree.affiche, char(reglages{k}), ...
                  strjoin(entree.params(:, 1).', ', '));
        end
        bloc.parametres.(canon) = reglages{k + 1};
    end
    modele.blocs{end + 1} = bloc;
end

% Le contenu d'un sous-système conditionnel de la bibliothèque, désigné
% par son nom ou son chemin ; vide pour un autre.
function gabarit = gabaritDeSousSysteme(designation, nom)
    gabarit = [];
    if isstruct(designation)
        return
    end
    texte = char(designation);
    barre = find(texte == '/', 1, 'last');
    if ~isempty(barre)
        texte = texte(barre + 1:end);
    end
    cle = lower(regexprep(texte, '\s', ''));
    switch cle
        case 'enabledsubsystem'
            controles = {'enableport', 'Enable'};
        case 'triggeredsubsystem'
            controles = {'triggerport', 'Trigger'};
        case 'enabledandtriggeredsubsystem'
            controles = {'enableport', 'Enable'; 'triggerport', 'Trigger'};
        case {'ifactionsubsystem', 'switchcaseactionsubsystem'}
            controles = {'actionport', 'Action Port'};
        case 'function-callsubsystem'
            controles = {'triggerport', 'function'};
        case 'foriteratorsubsystem'
            controles = {'foriterator', 'For Iterator'};
        case 'whileiteratorsubsystem'
            controles = {'whileiterator', 'While Iterator'};
        case 'variantsubsystem'
            % deux variantes qui laissent passer leur entrée, V == 1 et
            % V == 2, entre In1 et Out1 — sans lien, comme dans Simulink
            gabarit = new_system(regexprep(nom, '[^A-Za-z0-9_]', '_'));
            gabarit = add_block(gabarit, 'inport', 'In1', 'Port', 1);
            gabarit = add_block(gabarit, 'outport', 'Out1', 'Port', 1);
            variante = new_system('Variante');
            variante = add_block(variante, 'inport', 'In1', 'Port', 1);
            variante = add_block(variante, 'outport', 'Out1', 'Port', 1);
            variante = add_line(variante, 'In1', 'Out1');
            gabarit = add_block(gabarit, 'subsystem', 'Choix1', 'Model', variante, ...
                                'VariantControl', 'V == 1');
            gabarit = add_block(gabarit, 'subsystem', 'Choix2', 'Model', variante, ...
                                'VariantControl', 'V == 2');
            return
        otherwise
            return
    end
    gabarit = new_system(regexprep(nom, '[^A-Za-z0-9_]', '_'));
    gabarit = add_block(gabarit, 'inport', 'In1', 'Port', 1);
    gabarit = add_block(gabarit, 'outport', 'Out1', 'Port', 1);
    gabarit = add_line(gabarit, 'In1', 'Out1');
    for k = 1:size(controles, 1)
        gabarit = add_block(gabarit, controles{k, 1}, controles{k, 2});
    end
    if strcmp(cle, 'function-callsubsystem')
        gabarit = set_param(gabarit, 'function', 'TriggerType', 'function-call');
    end
end

% Le réglage qu'un bloc de la bibliothèque porte d'avance, désigné par
% son nom : un Divide divise, un Subtract soustrait, un Sum of Elements
% somme les éléments de sa seule entrée.
% Les réglages qu'un bloc de la bibliothèque porte d'avance : {nom, valeur,
% noms qui le désignent}, un par ligne. Un réglage donné l'emporte.
function avance = prereglages(designation)
    avance = cell(0, 3);
    if isstruct(designation)
        return
    end
    texte = char(designation);
    barre = find(texte == '/', 1, 'last');
    bibliotheque = ~isempty(barre);
    if bibliotheque
        texte = texte(barre + 1:end);
    end
    signes = {'Signs', 'Inputs', 'ListOfSigns'};
    switch lower(regexprep(texte, '\s', ''))
        case 'divide'
            avance = {'Inputs', '*/', {'Inputs'}};
        case 'productofelements'
            avance = {'Inputs', '*', {'Inputs'}};
        case 'subtract'
            avance = {'Signs', '+-', signes};
        case 'sumofelements'
            avance = {'Signs', '+', signes};
        case 'indexvector'
            avance = {'Inputs', 1, {'Inputs'}; ...
                      'DataPortOrder', 'Zero-based contiguous', {'DataPortOrder'}};
        case 'integratorlimited'
            avance = {'LimitOutput', 'on', {'LimitOutput'}; ...
                      'UpperSaturationLimit', 1, {'UpperSaturationLimit'}; ...
                      'LowerSaturationLimit', 0, {'LowerSaturationLimit'}};
        case 'signedsqrt'
            avance = {'Operator', 'signedSqrt', {'Operator'}};
        case 'reciprocalsqrt'
            avance = {'Operator', 'rSqrt', {'Operator'}};
        case 'discretepidcontroller'
            avance = {'TimeDomain', 'Discrete-time', {'TimeDomain'}};
        case 'delay'
            % le Delay de la bibliothèque retarde de deux pas ; le type
            % « delay » de MatLibre, comme Unit Delay, d'un seul
            if bibliotheque
                avance = {'DelayLength', 2, {'DelayLength'}};
            end
        case 'variabletimedelay'
            avance = {'VariableDelayType', 'Variable time delay', {'VariableDelayType'}};
        case 'resettabledelay'
            avance = {'ExternalReset', 'Rising', {'ExternalReset'}; ...
                      'InitialConditionSource', 'Input port', {'InitialConditionSource'}};
        case 'enableddelay'
            avance = {'ShowEnablePort', 'on', {'ShowEnablePort'}};
        case 'variableintegerdelay'
            avance = {'DelayLengthSource', 'Input port', {'DelayLengthSource'}};
    end
end

function oui = estVariante(designation)
    oui = false;
    if isstruct(designation)
        return
    end
    texte = char(designation);
    barre = find(texte == '/', 1, 'last');
    if ~isempty(barre)
        texte = texte(barre + 1:end);
    end
    oui = strcmp(lower(regexprep(texte, '\s', '')), 'variantsubsystem');
end

% Un bloc désigné par « modele/bloc », quand MODELE est une bibliothèque
% ou un modèle connus — ouverts, dans l'espace de travail ou en fichier — et
% qu'il y porte un bloc de ce nom. Les chemins de la bibliothèque de
% Simulink ne s'y prennent pas : ils sont au catalogue.
function [source, reference] = blocAilleurs(designation)
    source = [];
    reference = '';
    if ~(ischar(designation) || isstring(designation))
        return
    end
    texte = char(designation);
    barre = find(texte == '/', 1);
    if isempty(barre) || any(strcmpi(texte(1:barre - 1), {'simulink', 'sflib'}))
        return
    end
    nomModele = texte(1:barre - 1);
    chemin = texte(barre + 1:end);
    try
        bibliotheque = matlibre_sl_modele(nomModele);
    catch
        return
    end
    [parent, feuille] = deuxParties(chemin);
    if ~isempty(parent)
        try
            bibliotheque = matlibre_sl_dedans(bibliotheque, parent);
        catch
            return
        end
    end
    for k = 1:numel(bibliotheque.blocs)
        if strcmp(bibliotheque.blocs{k}.nom, feuille)
            source = bibliotheque.blocs{k};
            if isfield(bibliotheque.parametres, 'BlockDiagramType') && ...
               strcmpi(bibliotheque.parametres.BlockDiagramType, 'library')
                reference = texte;
            end
            return
        end
    end
end

function [parent, feuille] = deuxParties(chemin)
    barre = find(chemin == '/', 1, 'last');
    if isempty(barre)
        parent = '';
        feuille = chemin;
    else
        parent = chemin(1:barre - 1);
        feuille = chemin(barre + 1:end);
    end
end

function modele = poserCopie(modele, source, reference, nom, reglages)
    if existe(modele, nom)
        error('Simulink:Commands:AddBlockCantAdd', ...
              ['Le modele ''%s'' porte deja un bloc nomme ''%s'' : deux blocs d''un ' ...
               'meme systeme ne portent pas le meme nom.'], char(modele.nom), nom);
    end
    bloc = struct('type', source.type, 'nom', nom, 'parametres', source.parametres);
    if ~isempty(reference)
        bloc.reference = reference;
    end
    modele.blocs{end + 1} = bloc;
    for k = 1:2:numel(reglages) - 1
        if strcmpi(char(reglages{k}), 'MakeNameUnique')
            continue
        end
        modele = set_param(modele, nom, reglages{k}, reglages{k + 1});
    end
end

function oui = existe(modele, nom)
    oui = false;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            oui = true;
            return
        end
    end
end
