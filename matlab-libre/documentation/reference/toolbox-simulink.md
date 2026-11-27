# Toolbox `simulink`

```
% Simulink — simulation de schémas-blocs.
%
% Un modèle est une structure : une liste de blocs, une liste de liens et
% ses réglages de simulation. Avant de simuler, il est compilé comme dans
% Simulink : chaque bloc est vérifié — type, paramètres, ports, dimensions
% de ses signaux, période d'échantillonnage — et chaque erreur le nomme
% par son chemin, « modele/bloc ». L'ordre de calcul suit le câblage ;
% une boucle sans bloc à état est algébrique, et résolue à chaque pas par
% la méthode de Newton.
%
% Les signaux sont des scalaires, des vecteurs ou des matrices : un Mux
% les réunit, un Demux les sépare, un gain matriciel les combine, et un
% bloc peut avoir plusieurs sorties. Les blocs échantillonnés ne calculent
% qu'aux instants de leur période et gardent leur valeur entre deux.
%
% Un modèle est une valeur, non une référence : chaque fonction en rend
% une nouvelle et laisse l'ancienne intacte.
%
% L'espace de travail est partagé, comme dans Simulink : un paramètre
% numérique écrit entre apostrophes est une expression, évaluée à la
% simulation — un gain réglé sur 'K' vaut ce que vaut K. Dans l'autre
% sens, le bloc « toworkspace » y dépose son signal et « fromworkspace »
% y lit le sien. Les fichiers .slx et .mdl de Simulink se lisent par
% load_system et s'écrivent par save_system(m, 'nom.slx') ; par défaut,
% save_system écrit un programme .m qui rebâtit le modèle.
%
% Modèle
%   new_system    - Crée un modèle vide
%   open_system   - Dessine le schéma-bloc, et ouvre le modèle
%   close_system  - Ferme un modèle, et sa figure
%   bdclose       - Ferme un modèle, ou tous
%   bdroot        - Le nom du modèle
%   bdIsLoaded    - Dit si un modèle est ouvert
%   gcs           - Le nom du dernier modèle ouvert
%   getfullname   - Le chemin « modele/bloc » d'un bloc
%   save_system   - Écrit un .m qui rebâtit le modèle
%   load_system   - Relit ce .m
%   getSimulinkBlockHandle - La poignée d'un bloc, ou -1
%
% Restructurer un modèle
%   Simulink.BlockDiagram.createSubsystem   - Range des blocs dans un sous-système
%   Simulink.BlockDiagram.expandSubsystem   - Remplace un sous-système par son contenu
%   Simulink.BlockDiagram.arrangeSystem     - Range les blocs d'un système
%   Simulink.BlockDiagram.deleteContents    - Vide un modèle
%   Simulink.BlockDiagram.copyContentsToSubsystem  - Copie un modèle dans un sous-système
%   Simulink.SubSystem.deleteContents       - Vide un sous-système
%   Simulink.SubSystem.copyContentsToBlockDiagram  - Copie un sous-système dans un modèle
%
% Jeux de configuration
%   getActiveConfigSet  - Le jeu de configuration actif
%   getConfigSets       - Les noms des jeux d'un modèle
%   getConfigSet        - Un jeu, par son nom
%   attachConfigSet     - Attache un jeu à un modèle
%   attachConfigSetCopy - Attache la copie d'un jeu
%   setActiveConfigSet  - Rend un jeu actif
%   detachConfigSet     - Détache un jeu
%
% Du schéma au programme
%   Deux chemins, qu'il ne faut pas confondre. SAVE_SYSTEM écrit le
%   programme qui rebâtit le modèle, et LOAD_SYSTEM le relit : c'est
%   l'aller-retour du schéma. MATLIBRE_SL_PROGRAMME, lui, écrit le
%   programme qui fait ce que le schéma fait — des variables, une boucle,
%   de l'arithmétique, aucun appel à Simulink — et il n'y a pas de
%   retour : on ne remonte pas d'un calcul quelconque au schéma qui
%   l'aurait produit. MATLIBRE_SL_ECRIRE le dépose dans un fichier.
%
% Un schéma dans un bloc
%   Un bloc de type « subsystem » porte tout un modèle, bâti comme les
%   autres. Ses blocs INPORT sont ses entrées et ses blocs OUTPORT ses
%   sorties, dans l'ordre de leur paramètre Port ; SIM le déplie avant de
%   simuler, si bien qu'il rend exactement ce que rendrait le schéma écrit
%   à plat. Le relevé porte ses blocs sous le nom « sousSysteme/bloc », et
%   le sous-système lui-même porte la valeur de sa première sortie. Ils
%   s'emboîtent.
%
% Le solveur et les réglages
%   Les réglages sont ceux de la boîte « Paramètres de configuration » de
%   Simulink : StartTime, StopTime, Solver, FixedStep, et les diagnostics
%   AlgebraicLoopMsg, UnconnectedInputMsg, UnconnectedOutputMsg.
%   SET_PARAM(MODELE,'Solver','ode4') les pose et GET_PARAM les relit,
%   avec leur valeur par défaut. L'intégration se fait à pas fixe : ode1
%   (Euler, celui par défaut), ode2 (Heun), ode3 (Bogacki-Shampine), ode4
%   (Runge-Kutta), ode5 (Dormand-Prince) et ode8 (Prince-Dormand) gagnent
%   en ordre ; ode1be et ode14x, implicites, tiennent les systèmes
%   raides ; FixedStepDiscrete sert aux modèles sans état continu. Ou à
%   pas variable, avec la détection des passages par zéro : ode45, ode23
%   et ode113, et pour les systèmes raides ode15s, ode23s, ode23t et
%   ode23tb. Les états
%   discrets n'avancent qu'aux pas majeurs, si bien que tous les solveurs
%   acceptent tous les blocs.
%
% Blocs et liens
%   add_block     - Ajoute un bloc, avec ses paramètres
%   delete_block  - Retire un bloc, et les liens qui y touchent
%   replace_block - Change le type de tous les blocs d'un type
%   add_line      - Relie une sortie à une entrée
%   delete_line   - Supprime un lien
%   find_system   - Les blocs, éventuellement filtrés
%
% Réglages
%   get_param     - Lit un paramètre de bloc, ou du modèle
%   set_param     - Change les paramètres d'un bloc, ou du modèle
%   add_param     - Pose un réglage sur le modèle
%   delete_param  - Retire un réglage du modèle
%
% Simulation
%   sim           - Simule le modèle ; rend temps, signaux, états, sorties
%   parsim        - Fait une série de simulations décrites par des
%                   Simulink.SimulationInput, l'une après l'autre
%   simset        - Rassemble les options d'une simulation
%   simget        - Lit une option
%   simplot       - Trace les signaux relevés
%
% Objets de Simulink
%   Simulink.Parameter        - Une valeur de paramètre, son type et ses
%                               bornes, lue par les blocs comme une variable
%   Simulink.Signal           - Un signal nommé : il définit la mémoire
%                               partagée globale de son nom
%   Simulink.SimulationInput  - Variables, paramètres de blocs et réglages
%                               le temps d'une simulation ; SIM et PARSIM
%                               le simulent
%   Simulink.Variant          - Une condition nommée, qui active une
%                               variante
%   Simulink.ModelWorkspace   - L'espace de travail d'un modèle, que rend
%                               GET_PARAM(M,'ModelWorkspace') : ses
%                               variables passent avant celles de base
%   Simulink.Bus, Simulink.BusElement - Les types de bus
%   Simulink.SimulationData.Dataset   - Le journal des sorties, en
%                               SaveFormat 'Dataset', et celui des signaux,
%                               logsout
%
% Variantes
%   Un sous-système dont Variant vaut 'on' porte ses variantes — des
%   sous-systèmes, chacun avec sa condition VariantControl — et seule
%   l'active calcule ; Variant Source et Variant Sink font de même pour un
%   signal.
%
% Signaux et journal
%   GET_PARAM(M,BLOC,'PortHandles') rend les poignées des ports d'un bloc ;
%   SET_PARAM(M,H,'Name','vitesse','DataLogging','on') nomme le signal qui
%   part du port H et le journalise : SIM le range dans logsout.
%
% Linéarisation
%   linmod        - Linéarise autour d'un point de fonctionnement
%   dlinmod       - Linéarise et échantillonne
%   trim          - Cherche un point d'équilibre
%   linio         - Un point d'analyse : entrée, sortie, coupure
%   linearize     - Linéarise entre des points d'analyse
```

## `SlDemoSign`

```
SLDEMOSIGN Le signe d'un nombre, en énumération : l'exemple de Simulink.
  Le type que le bloc Enumerated Constant propose d'emblée : ses membres
  sont Positive (1), Zero (0) et Negative (-1), et un signal de type
  « Enum: SlDemoSign » porte l'un d'eux.

  Exemple :
     s = SlDemoSign.Negative;
     int32(s)                    % -1

  Voir aussi SIMULINK.INTENUMTYPE, ENUMERATION.
```

## `add_block`

```
ADD_BLOCK Ajoute un bloc au modèle.
  MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...) ajoute au
  modèle un bloc du TYPE donné, nommé NOM. Le type se désigne par son nom
  MatLibre (« gain »), par son type Simulink (« Gain », « Sin »), par son
  nom dans la bibliothèque (« Sine Wave ») ou par son chemin
  (« simulink/Math Operations/Gain ») ; le bloc garde le nom MatLibre,
  que GET_PARAM(...,'BlockType') rend.

  Sources — elles n'ont pas d'entrée :
    constant     Value, SampleTime            scalaire, vecteur ou matrice ;
                 un membre d'énumération (Couleur.Rouge) donne un signal
                 de type énuméré
    enumeratedconstant OutDataTypeStr ('Enum: SlDemoSign'), Value
                 (SlDemoSign.Positive) — un membre, constant
    step         Time, Before, After
    ramp         Slope, Start, InitialOutput
    sine         Amplitude, Frequency, Phase, Bias, SampleTime
    clock        —                            le temps
    digitalclock SampleTime                   le temps, échantillonné
    pulsegenerator Amplitude, Period, PulseWidth (en % de la période),
                 PhaseDelay, PulseType, SampleTime
    ground       —                            un zéro
    repeatingsequence rep_seq_t, rep_seq_y    une séquence périodique
    randomnumber Mean, Variance, Seed, SampleTime
    uniformrandomnumber Minimum, Maximum, Seed, SampleTime
    inport       Port, Value, PortDimensions  l'entrée du modèle
    fromworkspace VariableName, Interpolate, OutputAfterFinalValue
    fromfile     FileName, InterpolationWithinTimeRange,
                 ExtrapolationAfterLastDataPoint — le fichier MAT
                 qu'écrit To File : les instants sur la première ligne
    from         GotoTag                      le signal d'un Goto
    chirp        f1, T, f2                    la fréquence va de f1 à f2 en T
    bandlimitedwhitenoise Cov, Ts, seed       variance Cov / Ts, tenu Ts
    counterfreerunning NumBits, tsamp ; counterlimited uplimit, tsamp
    signalgenerator WaveForm (sine, square, sawtooth, random),
                 Amplitude, Frequency, Units (rad/sec, Hertz)
    repeatingsequencestair OutValues, tsamp   une valeur par instant
    repeatingsequenceinterpolated OutValues, TimeValues, LookUpMeth,
                 tsamp — la séquence datée, de période la dernière date
    signaleditor FileName, ActiveScenario — une sortie par signal du
                 scénario, un Simulink.SimulationData.Dataset de
                 timeseries rangé dans le fichier MAT ; interpolé,
                 tenu après sa dernière valeur
    fromspreadsheet FileName (un fichier texte : CSV, TXT), Range,
                 InterpolationWithinTimeRange,
                 ExtrapolationAfterLastDataPoint — la première colonne
                 donne les instants, les suivantes le signal

  Les blocs à cassure — abs, sign, saturation, deadzone, relay,
  relational, comparaisons, minmax, switch, hitcrossing, backlash,
  coulombfriction, step, fromworkspace, integrator borné — portent
  ZeroCross ('on' par défaut) : à pas variable, le solveur localise le
  franchissement de leur seuil.

  Opérations :
    gain         Gain, Multiplication : 'Element-wise(K.*u)',
                 'Matrix(K*u)', 'Matrix(u*K)'
    sum          Signs ('+-', '|++'...) ; une seule entrée : la somme
                 de ses éléments
    product      Inputs ('**', '*/'), Multiplication : 'Element-wise(.*)'
                 ou 'Matrix(*)'
                 gain, sum et product ont aussi OutDataTypeStr ('Inherit:
                 Inherit via internal rule', 'Inherit: Same as first
                 input', ou un type) ; gain, ParamDataTypeStr
    datatypeconversion OutDataTypeStr (double, single, int8 … uint32,
                 boolean, fixdt(1,16,8), sfix16_En8, Enum: Couleur),
                 RndMeth, SaturateOnIntegerOverflow, ConvertRealWorld
                 (Real World Value (RWV), Stored Integer (SI) : garde
                 l'entier stocké) ; un membre devient sa valeur entière,
                 un entier le membre qui la porte
    abs, sign, unaryminus, bias (Bias), dotproduct
    math         Operator : exp, log, 10^u, log10, magnitude^2, square,
                 sqrt, pow, conj, reciprocal, hypot, rem, mod,
                 transpose, hermitian
    trigonometry Operator : sin, cos, tan, asin, acos, atan, atan2, sinh,
                 cosh, tanh, asinh, acosh, atanh, sincos (deux sorties),
                 cos + jsin (exp(ju), complexe)
    complextorealimag Output (Real and imag, Real, Imag) ;
                 complextomagnitudeangle Output (Magnitude and angle,
                 Magnitude, Angle) — les parties d'un signal complexe
    realimagtocomplex, magnitudeangletocomplex Input, ConstantPart — un
                 signal complexe de ses deux parties, ou d'une partie
                 et de la constante ConstantPart
    minmax       Function (min, max), Inputs
    rounding     Operator : floor, ceil, round, fix
    polynomial   coefs                        polyval(coefs, u)
    sqrt         Operator : sqrt, signedSqrt, rSqrt ; « Signed Sqrt » et
                 « Reciprocal Sqrt » de la bibliothèque en sont réglés
    sinewavefunction Amplitude, Bias, Frequency, Phase — A sin(F u + P) + B,
                 l'entrée tenant lieu de temps (SineType 'Time based')
    permutedimensions Order ; squeeze — comme PERMUTE et SQUEEZE
    incrementrealworld, decrementrealworld, incrementstoredinteger,
                 decrementstoredinteger, decrementtozero, decrementtimetozero
                 — un de plus, un de moins, sans descendre sous zéro
    descriptorstatespace E, A, B, C, D, InitialCondition — E dx/dt = A x + B u
    transferfcndirectformii NumCoefVec, DenCoefVec (sans le 1 de tête),
                 vinit, RndMeth, DoSatur — la forme directe II
    datatypescalingstrip — l'entier stocké d'une virgule fixe
    functioncallsplit NumOutputPorts — l'appel d'un générateur partagé
    docblock DocumentType ; modelinfo — des notes, qui ne calculent rien
    functioncaller FunctionPrototype ('y = f(u)', '[s, d] = sd(a, b)'),
                 ScopedFunctionName ('A.f') — appelle le Simulink Function
                 de ce nom ; 'Simulink Function' de la bibliothèque en pose
                 un, y = f(u) ; argin, argout ArgumentName — ses arguments
    inbuselement PortName, Element, Port — dans un sous-système, l'élément
                 Element (n.c pour un bus emboîté, '' pour le bus entier)
                 du bus qui entre par le port PortName
    outbuselement PortName, Element, Port — l'élément Element du bus qui
                 sort par le port PortName
    checkdiscretegradient gradient ; checkinputresolution resolution —
                 enabled, callback, stopWhenAssertionFail, export
    transpose, hermitiantranspose, creatediagonalmatrix, extractdiagonal,
                 matrixsquare (u' * u), crossproduct (deux entrées) — la
                 bibliothèque Matrix Operations
    identitymatrix OutputDimensions, OutDataTypeStr, SampleTime, ou
                 InheritOutputPortAttributes 'on' : celles de l'entrée
    expandscalar ElementValue, OutputDimensions, OutDataTypeStr, SampleTime
    ishermitian, issymmetric, istriangular Mode — un booléen
    permutematrix mode (Columns, Rows), ZeroOneIdxMode, errmode (Clip
                 index, Clip and warn, Generate error), checkDims — deux
                 entrées : A et les indices P
    submatrix    RowSpan, RowIdx, RowIndex, RowOffset, RowEndIdx,
                 RowEndIndex, RowEndOffset, et de même Col... — des lignes
                 et des colonnes contiguës
    algebraicconstraint Constraint ('f(z) = 0', 'f(z) = z'), InitialGuess —
                 sa sortie z revient à son entrée par une boucle
                 algébrique, que la méthode de Newton résout
    sampletimemath TsampMathOp (+, -, *, /, Ts Only, 1/Ts Only),
                 weightValue — l'entrée et w Ts, Ts la période du bloc
    minmaxrunningresettable Function (min, max), vinit — deux entrées :
                 u, et R qui remet à vinit

  Non-linéarités :
    saturation   UpperLimit, LowerLimit
    deadzone     UpperValue, LowerValue
    relay        OnSwitch, OffSwitch, OnOutput, OffOutput
    quantizer    QuantizationInterval
    ratelimiter  RisingSlewLimit, FallingSlewLimit, InitialOutput
    hitcrossing  HitCrossingOffset, HitCrossingDirection
    backlash     BacklashWidth, InitialOutput
    coulombfriction Offset, Gain
    lookup       BreakpointsData, TableData, InterpMethod, ExtrapMethod ;
                 NumberOfTableDimensions (jusqu'à 6) et
                 BreakpointsForDimension2 à 6 en font une table à
                 plusieurs entrées (n-D Lookup Table)
    lookup2d     BreakpointsForDimension1, BreakpointsForDimension2, Table
    directlookup Table, NumberOfTableDimensions (1 à 6) — l'élément que
                 désignent ses entrées, à partir de 0
    lookuptabledynamic LookUpMeth — trois entrées : x, xdat, ydat, la table
                 arrivant par les signaux
    prelookup    BreakpointsData, OutputSelection, ExtrapMethod,
                 UseLastBreakpoint — deux sorties : l'indice k, à partir
                 de 0 (uint32), et la fraction f
    interpolationusingprelookup NumberOfTableDimensions, Table,
                 InterpMethod, ExtrapMethod, ValidIndexMayReachLast — les
                 entrées k1, f1, k2, f2... de Prelookup
    sinecosine   Formula, NumDataPoints — sin(2 pi u), cos(2 pi u) ou les
                 deux, lus dans une table d'un quart d'onde
    saturationdynamic, deadzonedynamic, ratelimiterdynamic — trois
                 entrées : up, u, lo
    wraptozero   Threshold                    zéro au-delà du seuil

  Logique :
    logic        Operator : AND, OR, NAND, NOR, XOR, NXOR, NOT ; Inputs
    relational   Operator : ==, ~=, <, <=, >=, >
    comparetoconstant relop, const ; comparetozero relop
    detectchange, detectincrease, detectdecrease  vinit
    intervaltest uplimit, lowlimit, IntervalClosedRight, IntervalClosedLeft
    combinatoriallogic TruthTable        la ligne que désignent les entrées,
                                         la première en poids fort
    detectrisepositive, detectrisenonnegative, detectfallnegative,
                 detectfallnonpositive  vinit — le front du test u > 0,
                 u >= 0, u < 0, u <= 0
    intervaltestdynamic IntervalClosedRight, IntervalClosedLeft — trois
                 entrées : up, u, lo
    bitwiseoperator logicop (AND, OR, NAND, NOR, XOR, NOT), UseBitMask,
                 BitMask, NumInputPorts — sur des entiers
    bitset, bitclear iBit (à partir de 0) ; shiftarithmetic
                 BitShiftNumber, BitShiftDirection (Left, Right,
                 Bidirectional) — à droite, le signe se conserve

  Aiguillage :
    switch       Threshold, Criteria : 'u2 >= Threshold', 'u2 > Threshold',
                 'u2 ~= 0' — la première entrée passe, ou la troisième
    multiportswitch Inputs, DataPortOrder ('One-based contiguous',
                 'Zero-based contiguous', 'Specify indices'),
                 DataPortIndices ({1, [2 3], 4}, ou des membres pour une
                 commande énumérée), DataPortForDefault ('Last data port',
                 'Additional data port'), DiagnosticForDefault (Error,
                 Warning, None) ; une seule entrée de données (« Index
                 Vector ») : l'élément que désigne la commande
    environmentcontroller —              deux entrées, Sim et Coder : rend Sim
    bustovector  —                            un bus de scalaires, en vecteur
    buscreator   Inputs ('a,b' : les noms des éléments, ou leur nombre),
                 OutDataTypeStr ('Bus: Type') — un bus, dont chaque élément
                 garde le type de son signal ; un type de bus impose le sien
    busselector  OutputSignals ('a,b.c'), OutputAsBus — les éléments
                 choisis, chacun dans son type ; un bus traverse retards,
                 mémoires, bloqueurs et aiguillages
    busassignment AssignedSignals ('a,b.c') — le bus, puis un signal par
                 élément nommé, qui le remplace
    mux          Inputs (un nombre, ou les largeurs)
    demux        Outputs (un nombre, ou les largeurs)
    selector     Indices ; ou NumberOfDimensions (1 ou 2), IndexMode,
                 IndexOptionArray ('Select all', 'Index vector (dialog)',
                 'Index vector (port)', 'Starting index (dialog)',
                 'Starting index (port)'), IndexParamArray,
                 OutputSizeArray — une option par dimension, un port
                 d'indices par option « (port) »
    assignment   NumberOfDimensions (1 ou 2), IndexMode, IndexOptionArray
                 ('Assign all', 'Index vector (dialog)', 'Starting index
                 (dialog)'), IndexParamArray, OutputInitialize,
                 OutputSizeArray — Y0, dont les éléments aux indices
                 reçoivent ceux de U
    signalspecification Dimensions, OutDataTypeStr — laisse passer, en
                 vérifiant les dimensions et le type
    concatenate  NumInputs, Mode, ConcatenateDimension
    reshape      OutputDimensionality, OutputDimensions
    goto         GotoTag, TagVisibility : local, scoped, global
    signalconversion  —
    merge        Inputs, InitialOutput        l'entrée dont le sous-système
                                              vient de calculer
    manualswitch sw ('1' : la première entrée, '0' : la seconde)
    datastorememory DataStoreName, InitialValue, ReadBeforeWriteMsg,
                 WriteAfterReadMsg, WriteAfterWriteMsg ; datastoreread et
                 datastorewrite DataStoreName — une mémoire partagée,
                 lue avant d'être écrite à chaque pas
    ratetransition OutPortSampleTime, X0, Deterministic — tenue vers une
                 période plus lente, retard d'une période lente vers une
                 plus rapide
    variantsource VariantControls ({'V == 1', 'V == 2'}), VariantControlMode,
                 LabelModeActiveChoice, AllowZeroVariantControls — une
                 entrée par condition, seule l'active passe ;
                 variantsink de même, une sortie par condition
    ic           Value                        au premier instant, puis l'entrée
    width        —                            le nombre d'éléments de l'entrée

  Continu — l'intégrateur et les représentations d'état coupent les
  boucles :
    integrator   InitialCondition, LimitOutput, UpperSaturationLimit,
                 LowerSaturationLimit, ExternalReset (none, rising,
                 falling, either, level, level hold : une entrée de
                 remise), InitialConditionSource (external : une entrée
                 de condition initiale), ShowSaturationPort,
                 ShowStatePort (le port d'état, 'integ/State'), WrapState,
                 WrappedStateUpperValue, WrappedStateLowerValue (l'état
                 enroulé, un angle entre -pi et pi) ;
                 « Integrator Limited » le borne d'avance entre 0 et 1
    derivative   —                            vaut zéro au premier pas
    transferfcn  Numerator, Denominator
    statespace   A, B, C, D, X0
    zeropole     Zeros, Poles, Gain
  OutMin et OutMax, vides par défaut, bornent la sortie des blocs de
  calcul (Constant, Gain, Sum, Product, Abs, Data Type Conversion,
  Switch, Multiport Switch, Saturation, les filtres discrets...), et
  l'entrée d'un Outport : SignalRangeChecking dit ce que fait une valeur
  qui en sort ; la valeur d'un Constant doit s'y tenir.
    transportdelay DelayTime, InitialOutput, BufferSize (la taille
                 initiale : le tampon grandit au besoin), FixedBuffer
                 ('on' : il garde sa taille, écrase ses plus anciens
                 échantillons et extrapole ce qu'il n'a plus)
    variabletransportdelay VariableDelayType ('Variable transport delay' :
                 la durée qu'on lit quand le signal entre ; 'Variable
                 time delay' : celle qu'on lit quand il sort),
                 MaximumDelay, InitialOutput, MaximumPoints (taille
                 initiale du tampon), ZeroDelay, FixedBuffer — deux
                 entrées : u, et le retard
    pidcontroller P, I, D, N (dérivée filtrée par N/(1+N/s)), Controller
                 (PID, PI, PD, P, I), Form (Parallel, Ideal), TimeDomain
                 (Continuous-time, Discrete-time : SampleTime,
                 IntegratorMethod, FilterMethod), UseFilter,
                 InitialConditionForIntegrator, InitialConditionForFilter,
                 InitialConditionSource (external : entrées I0 et D0),
                 ExternalReset (entrée Reset), LimitOutput,
                 UpperSaturationLimit, LowerSaturationLimit,
                 AntiWindupMode (back-calculation : Kb ; clamping) ; les
                 entrées : u, Reset, I0, D0 ; « Discrete PID Controller »
                 est réglé en Discrete-time
    secondorderintegrator ICX, ICDXDT, ICSourceX, ICSourceDXDT (internal,
                 external : une entrée x0, dx0), LimitX, UpperLimitX,
                 LowerLimitX, LimitDXDT, UpperLimitDXDT, LowerLimitDXDT,
                 WrapX, WrappedUpperValueX, WrappedLowerValueX,
                 ExternalReset (none, rising, falling, either),
                 ReinitDXDTwhenXreachesSaturation, ShowOutput (both, x,
                 dxdt) — x et dx/dt ; x à sa borne y tient, dx/dt nul
    secondorderintegratorlimited le même, x borné entre 0 et 1

  Discret — ils ne calculent qu'aux instants de leur période :
    delay        InitialCondition, DelayLength, SampleTime ; aussi
                 nommé unitdelay ; DelayLengthSource ('Input port' : la
                 longueur par une entrée d, jusqu'à DelayLengthUpperLimit),
                 ShowEnablePort (entrée enable : désactivé, il tient sa
                 sortie et ses états), ExternalReset (Rising, Falling,
                 Either, Level, Level hold), InitialConditionSource
                 ('Input port' : entrée x0) — les entrées : u, d, enable,
                 remise, x0 ; Resettable Delay, Enabled Delay et
                 Variable Integer Delay de la bibliothèque en sont réglés
    memory       InitialCondition             la valeur du pas précédent
    zoh          SampleTime (dix pas par défaut)
    discreteintegrator Gain, SampleTime, InitialCondition,
                 IntegratorMethod : ForwardEuler, BackwardEuler, Trapezoidal
                 (ou 'Integration: ...', et 'Accumulation: ...', qui ne
                 multiplie pas par la période), LimitOutput,
                 UpperSaturationLimit, LowerSaturationLimit,
                 ExternalReset (rising, falling, either, level, sampled
                 level), InitialConditionSource (external : entrée x0),
                 ShowSaturationPort, ShowStatePort — les entrées : u,
                 remise, x0 ; les sorties : y, saturation, état
    discretetransferfcn Numerator, Denominator (puissances de z),
                 SampleTime
    discretefilter Numerator, Denominator (puissances de z^-1), SampleTime
    discretestatespace A, B, C, D, X0, SampleTime
    discretezeropole Zeros, Poles, Gain, SampleTime
    discretederivative gainval, ICPrevScaledInput   K (u - u d'avant) / Ts
    difference   ICPrevInput                  u - u d'avant
    tappeddelay  NumDelays, vinit, samptime, DelayOrder, includeCurrent
    discretefirfilter Coefficients, InitialStates, SampleTime
    transferfcnfirstorder PoleZ, ICPrevOutput   (1 - p) z / (z - p)
    transferfcnleadorlag PoleZ, ZeroZ, Gain, ICPrevOutput, ICPrevInput
    transferfcnrealzero ZeroZ, ICPrevInput      (z - zéro) / z
    firstorderhold Ts                         prolonge les deux derniers
                                              échantillons en ligne droite

  Sorties :
    outport      Port, InitialOutput, OutputWhenDisabled (held, reset)
    scope        NumInputPorts ; DataLogging ('on' : ses entrées se
                 journalisent), DataLoggingVariableName ('ScopeData'),
                 DataLoggingSaveFormat (Dataset, StructureWithTime,
                 Structure, Array), DataLoggingLimitDataPoints et
                 DataLoggingMaxPoints (les derniers instants),
                 DataLoggingDecimateData et DataLoggingDecimation (un
                 instant sur n), SampleTime ; les noms anciens
                 SaveToWorkspace, SaveName, DataFormat, LimitDataPoints,
                 MaxDataPoints valent aussi ; display ; terminator
    toworkspace  VariableName, SaveFormat : Array, Structure With Time,
                 Structure
    tofile       Filename, MatrixName, Decimation — [temps ; signal] dans
                 un fichier MAT, en fin de simulation
    xygraph      xmin, xmax, ymin, ymax        y en fonction de x
    stopsimulation — arrête la simulation dès que l'entrée n'est plus nulle
    assertion    Enabled, StopWhenAssertionFail — échoue dès que
                 l'entrée s'annule
    checkstaticrange, checkstaticgap  min, max, min_included, max_included ;
                 checkstaticlowerbound  min, min_included ;
                 checkstaticupperbound  max, max_included — échouent quand
                 le signal sort de ses bornes (ou tombe dans l'écart)
    checkdynamicrange, checkdynamicgap — trois entrées : max, sig, min ;
                 checkdynamiclowerbound (min, sig),
                 checkdynamicupperbound (max, sig) — les bornes sont des
                 signaux ; tous portent enabled et stopWhenAssertionFail

  Simscape, réseaux électriques (ports physiques LConn à gauche, RConn à
  droite ; un paramètre NOM_unit dit l'unité de NOM : kOhm, uF, mH, kHz...) :
    resistor R ; capacitor c, r, g, vc ; inductor l, r, g, iL
    electricalreference, solverconfiguration — un de chaque par réseau
    dcvoltagesource v0 ; dccurrentsource i0 ; acvoltagesource,
                 accurrentsource amp, frequency, shift (degrés)
    controlledvoltagesource, controlledcurrentsource — commandées par
                 leur entrée ; voltagesensor, currentsensor — une sortie
                 Ces entrées et sorties sont des signaux physiques, comme
                 celles des blocs de signaux physiques (psgain...) : un
                 signal de Simulink y entre par simulinkpsconverter et en
                 sort par pssimulinkconverter ; une liaison directe entre
                 un port de Simulink et un port de signal physique est
                 refusée, comme dans Simscape.
    opamp — +, - (LConn1, LConn2), sortie (RConn1) : v(+) = v(-)
    idealtransformer n — primaire (LConn1, LConn2), secondaire (RConn1,
                 RConn2) : v1 = n v2, i2 = n i1 ; mutualinductor L1, L2,
                 k, i1, i2 ; opencircuit
    voltagecontrolledvoltagesource K, currentcontrolledvoltagesource K —
                 la commande à gauche, la sortie à droite
    simulinkpsconverter InputSignalUnit, ApplyAffineConversion,
                 FilteringAndDerivatives ('Provide signals', 'Filter input,
                 derivatives calculated', 'Zero derivatives (piecewise
                 constant)'), SimscapeFilterOrder, InputFilterTimeConstant ;
                 pssimulinkconverter OutputSignalUnit, ApplyAffineConversion
  Simscape, mécanique (R à gauche, C à droite ; une force ou un couple
  positif pousse R) :
    mass mass, v ; translationalspring spr_rate, x ; translationaldamper D
    inertia inertia, w ; rotationalspring spr_rate, phi ; rotationaldamper D
    mechanicaltranslationalreference, mechanicalrotationalreference
    idealforcesource, idealtorquesource, idealtranslationalvelocitysource,
                 idealangularvelocitysource — commandés par leur entrée
    idealtranslationalmotionsensor x0, idealrotationalmotionsensor phi0 —
                 deux sorties, la vitesse et la position ; idealforcesensor,
                 idealtorquesensor — une sortie
    rotationalelectromechanicalconverter K — + et - (LConn1, LConn2), R et
                 C (RConn1, RConn2) : v = K w, couple = K i
    translationalelectromechanicalconverter K — de même : v = K u, F = K i
    translationalinerter B, v ; rotationalinerter B, w — F = B d(vR-vC)/dt
    translationalfreeend, rotationalfreeend — un port libre
    gearbox ratio — S (LConn1), O (RConn1) : w(S) = ratio w(O)
    wheelandaxle radius, orientation — l'essieu A (LConn1), la périphérie
                 P (RConn1) : v(P) = r w(A)
  Simscape, thermique (A à gauche, B à droite ; températures absolues,
  en K, degC ou degF) :
    thermalmass mass, sp_heat, T ; thermalreference — le zéro absolu
    conductiveheattransfer area, thickness, th_cond ;
                 convectiveheattransfer area, heat_tr_coeff
    idealtemperaturesource — T(B) - T(A) = entrée ; idealheatflowsource —
                 un flux de A vers B ; idealtemperaturesensor T(A) - T(B),
                 idealheatflowsensor — une sortie
    perfectinsulator — une paroi que la chaleur ne traverse pas
  Simscape, signaux physiques (des signaux en unités SI ; un paramètre
  NOM_unit dit l'unité de NOM) :
    psgain Gain ; psconstant Constant ; psadd, pssubtract (I1 - I2),
                 psproduct, psdivide (I1 / I2), psmax, psmin — deux entrées
    psabs, pssign, psceil, psfloor, psround, psfix
    psmathfunction Function ('sin(u)', 'cos(u)', 'exp(u)', 'log(u)',
                 '10.^u', 'log10(u)', 'u.^2', 'sqrt(u)', '1./u', 'tanh(u)',
                 'u.^v'), v
    psintegrator InitialCondition, ExternalReset, InitialConditionSource,
                 LimitOutput ('None', 'Upper', 'Lower', 'Both'), UpperLimit,
                 LowerLimit
    pssaturation, psdeadzone UpperLimit, LowerLimit ; psswitch Threshold —
                 I1 si la commande I2 atteint le seuil, I3 sinon
    psconstantdelay DelayTime, InputHistory ; psterminator
    pslookuptable1d x, f ; pslookuptable2d x1, x2, f (numel(x1) lignes,
                 numel(x2) colonnes) — InterpolationMethod ('Linear',
                 'Smooth'), ExtrapolationMethod ('Linear', 'Nearest', 'Error')

  Fonctions de l'utilisateur :
    fcn          Expr                         une expression de u, scalaire :
                                              'u(1)*sin(u(2))', ou u[2]
    interpretedmatlabfunction MATLABFcn, OutputDimensions — un nom de
                 fonction ('sin') ou une expression de u
    matlabfunction Script                     le texte d'une fonction
                 MATLAB : ses arguments sont les entrées, ses sorties
                 les sorties ; une variable persistante y garde un état
    sfunction    FunctionName, Parameters     une S-fonction de niveau 1,
                 [sys,x0,str,ts] = f(t,x,u,flag,p1,...)
    chart        Chart, Inputs, Outputs, InitialContext, SampleTime —
                 une machine à états bâtie par SFCHART, SFSTATE et
                 SFTRANSITION, états emboîtés, régions parallèles et
                 logique temporelle compris (SFAFTER... en secondes de
                 simulation) ; ses sorties sont des champs de son
                 contexte, ou « etat », le rang de l'état actif. Les
                 événements d'entrée de la machine (SFEVENT) arrivent
                 par un port de déclenchement, après les entrées ; ses
                 événements de sortie ont chacun un port, après les
                 sorties, qui peut appeler un sous-système appelé par
                 fonction

  Un schéma dans un bloc :
    subsystem    Model                un modèle entier, abrégé en un bloc ;
                 'Enabled Subsystem', 'Triggered Subsystem', 'Enabled
                 and Triggered Subsystem', 'If Action Subsystem',
                 'Switch Case Action Subsystem', 'Function-Call
                 Subsystem', 'Resettable Subsystem', 'For Iterator
                 Subsystem' et 'While Iterator Subsystem' en donnent un
                 qui porte déjà In1, Out1 et son port de contrôle ou son
                 itérateur, comme dans la bibliothèque de Simulink ;
                 'Atomic Subsystem', un sous-système atomique
                 (TreatAsAtomicUnit 'on'), dont SystemSampleTime impose
                 la période aux blocs qui l'héritent. Variant ('on') en fait un
                 sous-système à variantes : ses variantes, des
                 sous-systèmes posés dedans sans lien, portent chacune
                 sa condition VariantControl — 'Mode == 1', le nom
                 d'un Simulink.Variant, '(default)' —, et seule celle
                 dont la condition est vraie calcule ; ses ports se
                 raccordent par leur nom. VariantControlMode ('label')
                 et LabelModeActiveChoice la choisissent par étiquette,
                 AllowZeroVariantControls ('on') admet qu'aucune ne
                 le soit. 'Variant Subsystem' en donne un garni de deux
                 variantes, V == 1 et V == 2
    enableport   StatesWhenEnabling (held, reset)    posé dedans : il ne
                 calcule que quand ce port reçoit un signal positif
    triggerport  TriggerType (rising, falling, either, function-call)
                 posé dedans : il ne calcule qu'aux fronts du signal de
                 ce port, ou quand un Function-Call Generator l'appelle
    functioncallgenerator sample_time    appelle, à chaque instant de sa
                 période, le sous-système relié à son port
    foriterator  IterationLimit, IterationSource (internal, external),
                 IndexMode, ShowIterationPort, ResetStates (held, reset)
                 posé dedans : le sous-système calcule N fois par pas
    whileiterator WhileBlockType (while, do-while), MaxIters,
                 ShowIterationPort, ResetStates — posé dedans : il
                 calcule tant que l'entrée cond est vraie ; en while,
                 l'entrée IC dit s'il commence
    actionport   InitializeStates     posé dedans : il calcule quand un
                 If ou un Switch Case le désigne
    if           NumInputs, IfExpression, ElseIfExpressions, ShowElse —
                 conditions sur u1, u2... ; une sortie d'action par
                 branche
    switchcase   CaseConditions ('{1, [2 3]}', ou des membres pour une
                 entrée énumérée : '{Couleur.Rouge, Couleur.Vert}'),
                 ShowDefaultCase
    modelreference ModelName             un autre modèle — variable,
                 fichier .m, .slx ou .mdl —, relu à chaque simulation,
                 dont les blocs ne voient que son espace de travail ;
                 ParameterArgumentValues (struct('K', '5')) ou
                 InstanceParameters (Name, Value) donnent leur valeur
                 à ses arguments (ParameterArgumentNames)
    subsystemreference ReferencedSubsystem  un fichier de sous-système,
                 NEW_SYSTEM(NOM, 'Subsystem'), déroulé à sa place

  Le sous-système porte le modèle qu'il abrège, bâti comme les autres
  par NEW_SYSTEM. Ses blocs INPORT sont ses entrées et ses blocs OUTPORT
  ses sorties, dans l'ordre de leur paramètre Port. SIM le déplie avant
  de simuler : le résultat est exactement celui du schéma écrit à plat.
  Un port de contrôle posé dedans en fait un sous-système conditionnel :
  ce port est une entrée de plus, après les autres, que ADD_LINE
  désigne par 'sous/Enable', 'sous/Trigger' ou 'sous/Ifaction'. À
  l'arrêt, ses sorties tiennent leur dernière valeur, ou reviennent à
  leur valeur initiale (OutputWhenDisabled), et ses états tiennent, ou
  repartent à la reprise (StatesWhenEnabling). Un sous-système itéré ne
  se déplie pas : son modèle calcule plusieurs fois par pas, ses blocs à
  état avançant à chaque itération, et ses sorties sont celles de la
  dernière.

  ADD_BLOCK(MODELE,'bibliotheque/bloc',NOM) recopie un bloc d'une
  bibliothèque bâtie par NEW_SYSTEM(...,'Library') — ou d'un autre
  modèle —, ouverte, dans l'espace de travail ou en fichier. Le bloc
  d'une bibliothèque y reste lié : GET_PARAM(...,'ReferenceBlock') le
  dit, et la simulation reprend la bibliothèque telle qu'elle est alors,
  en gardant les valeurs du masque que le bloc a reçues.

  Un type inconnu est refusé, comme un paramètre que le bloc n'a pas :
  rangé sans être lu, il ferait croire à un réglage qui n'a pas lieu.
  Les noms de paramètres se lisent sans égard à la casse, et les noms
  de Simulink valent pour ceux de MatLibre (« Inputs » pour les signes
  d'une sommation). Deux blocs du même modèle ne portent pas le même
  nom ; ADD_BLOCK(...,'MakeNameUnique','on') en choisit un libre.

  Tout bloc accepte en outre POSITION, [gauche haut droite bas] comme
  dans Simulink : il garde alors la place qu'on lui donne, au lieu
  d'être rangé par couches.

  Un paramètre numérique donné entre apostrophes est une expression,
  évaluée dans l'espace de travail de base au moment où l'on simule —
  comme dans Simulink. C'est ainsi qu'un modèle et un programme
  partagent leurs variables :

     K = 4;
     m = add_block(m, 'gain', 'k', 'Gain', 'K');   % non pas 4, mais K
     r = sim(m, 1, 0.01);                          % le gain vaut 4
     K = 10; r = sim(m, 1, 0.01);                  % il vaut 10

  La forme de MATLAB : H = ADD_BLOCK(SOURCE,DESTINATION,'Param',VALEUR,...)
  pose dans un modèle de la session — NEW_SYSTEM('nom') l'y met — le bloc
  SOURCE ('simulink/Sources/Step', 'built-in/Gain', ou le chemin d'un
  bloc existant, qu'elle recopie) sous le chemin DESTINATION,
  'nom/bloc' ou 'nom/sousSysteme/bloc', et rend sa poignée. Position s'y
  donne en pixels, et un bloc pris à la bibliothèque y prend les défauts
  de Simulink là où MatLibre en a d'autres : un bloc discret hérite sa
  période (SampleTime -1), To Workspace range une timeseries. Un Inport
  ou un Outport y prend le rang suivant (Port) ; un rang donné s'insère
  et décale ceux qui le suivent : les ports d'un système vont de 1 à N.

  Tout bloc porte aussi Position, Orientation, les couleurs, Tag,
  Description, UserData... et Commented : 'on' retire le bloc du calcul
  — ce qu'il alimentait lit zéro —, 'through' le fait traverser, chaque
  sortie rendant l'entrée de même rang.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'Integrator', 'integ', 'InitialCondition', 0);
     get_param(m, 'integ', 'BlockType')         % 'integrator'

  Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, DELETE_BLOCK, SIM, OPEN_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `add_line`

```
ADD_LINE Relie une sortie d'un bloc à une entrée d'un autre.
  MODELE = ADD_LINE(MODELE,'source','destination') relie la première
  sortie du premier bloc à la première entrée du second.
  ADD_LINE(MODELE,'source','destination',E) choisit l'entrée, ce qui
  importe pour une sommation dont les signes diffèrent.
  ADD_LINE(MODELE,'source','destination',E,S) choisit en plus la sortie
  de la source : un Demux, un sous-système ou un sinus-cosinus en ont
  plusieurs.

  La syntaxe de Simulink est acceptée : ADD_LINE(MODELE,'demux/2',
  'scope/1') relie la deuxième sortie du Demux à la première entrée du
  Scope. Un bloc dont le nom lui-même se termine par « /n » l'emporte
  sur cette lecture. Les ports de contrôle d'un sous-système
  conditionnel se désignent par leur nom : 'sous/Enable',
  'sous/Trigger', 'sous/Ifaction', 'sous/Reset' ; ce sont ses entrées
  qui suivent celles de ses blocs INPORT. Le port d'état d'un intégrateur
  (ShowStatePort à 'on') se désigne de même, 'integrateur/State' : c'est
  sa dernière sortie.

  Une sortie peut alimenter plusieurs entrées : il suffit de plusieurs
  liens. Une entrée, non : un second lien vers une entrée déjà reliée
  est refusé, comme dans Simulink. Un port qui n'existe pas l'est aussi.

  Les ports physiques d'un réseau Simscape se désignent par leur nom,
  LConn1, LConn2… à gauche et RConn1… à droite : ADD_LINE(MODELE,
  'R1/RConn1','C1/LConn1') les relie. Une connexion physique n'a pas de
  sens : les deux ports, et tous ceux qu'on relie à eux, font un même
  nœud. Un port physique ne se relie qu'à un port physique.

  Une boucle peut passer par un bloc à état — intégrateur, retard —, qui
  la coupe. Une boucle qui n'en contient pas est algébrique : SIM la
  résout à chaque pas, et le signale selon le réglage AlgebraicLoopMsg
  du modèle.

  La forme de MATLAB : H = ADD_LINE(SYSTEME,SORTIE,ENTREE), SYSTEME le nom
  d'un modèle de la session ou le chemin d'un de ses sous-systèmes,
  SORTIE et ENTREE des 'bloc/port', des poignées de port, ou des
  cellules de l'un ou de l'autre ; elle rend la poignée de chaque ligne.
  'autorouting' est accepté : le tracé se calcule de toute façon.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);   % le retour
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');

  Voir aussi ADD_BLOCK, DELETE_LINE, NEW_SYSTEM, SIM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `add_param`

```
ADD_PARAM Pose un réglage sur le modèle lui-même.
  MODELE = ADD_PARAM(MODELE,'Nom',VALEUR,...) ajoute un ou plusieurs
  réglages au modèle. Ce ne sont pas les paramètres d'un bloc : ils
  valent pour la simulation entière.

  Ceux de la boîte « Paramètres de configuration » sont lus par SIM
  quand l'appel ne les donne pas, et vérifiés dès qu'on les pose :
    StartTime, StopTime   les instants de début et de fin
    FixedStep             le pas d'intégration
    Solver                le solveur : ode1 à ode5, FixedStepDiscrete
    AlgebraicLoopMsg, UnconnectedInputMsg, UnconnectedOutputMsg
                          none, warning ou error
  Tout autre nom est un réglage propre au modèle, rangé tel quel.

  Un réglage déjà posé est refusé en le nommant : c'est SET_PARAM qui
  le change, comme dans MATLAB, où ADD_PARAM ne sert qu'à créer.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 3);
     m = add_param(m, 'StopTime', 2, 'Solver', 'ode1', 'FixedStep', 0.5);
     r = sim(m);
     r.temps(end)                     % 2
     numel(r.temps)                   % 5 : de 0 a 2 par pas de 0,5

  Voir aussi DELETE_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM, SIM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `attachConfigSet`

```
ATTACHCONFIGSET Attache un jeu de configuration à un modèle.
  ATTACHCONFIGSET(MODELE,CS) attache le Simulink.ConfigSet CS au modèle
  de la session nommé MODELE : le jeu lui est lié dès lors, sans être
  actif — SETACTIVECONFIGSET l'active. Un jeu du même nom est refusé ;
  ATTACHCONFIGSET(MODELE,CS,true) renomme alors CS ('Rapide1').

  MODELE = ATTACHCONFIGSET(MODELE,CS) fait de même sur un modèle par
  valeur, et le rend ; le jeu y est recopié.

  Exemple :
     m = new_system('essai');
     cs = Simulink.ConfigSet;
     cs.Name = 'Rapide';
     set_param(cs, 'StopTime', '1');
     m = attachConfigSet(m, cs);
     getConfigSets(m)                         % {'Configuration'; 'Rapide'}

  Voir aussi ATTACHCONFIGSETCOPY, SETACTIVECONFIGSET, DETACHCONFIGSET,
  SIMULINK.CONFIGSET.
```

## `attachConfigSetCopy`

```
ATTACHCONFIGSETCOPY Attache à un modèle la copie d'un jeu de configuration.
  COPIE = ATTACHCONFIGSETCOPY(MODELE,CS) attache au modèle de la
  session nommé MODELE une copie du Simulink.ConfigSet CS, et la rend :
  CS lui-même reste où il était — libre, ou attaché à un autre modèle.
  ATTACHCONFIGSETCOPY(MODELE,CS,true) renomme la copie si le nom est pris.

  [MODELE,COPIE] = ATTACHCONFIGSETCOPY(MODELE,CS) fait de même sur un
  modèle par valeur.

  Exemple :
     bdclose('all');
     new_system('un');
     new_system('deux');
     cs = getActiveConfigSet('un');
     set_param(cs, 'StopTime', '7');
     copie = attachConfigSetCopy('deux', cs, true);
     setActiveConfigSet('deux', copie.Name);
     get_param('deux', 'StopTime')            % '7'
     bdclose('all');

  Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, SIMULINK.CONFIGSET.
```

## `bdIsLoaded`

```
BDISLOADED Dit si un modèle est ouvert dans la session.
  R = BDISLOADED(NOM) rend vrai si un modèle de ce nom a été ouvert par
  OPEN_SYSTEM ou LOAD_SYSTEM et pas encore fermé.

  Exemple :
     bdclose('all');
     m = new_system('essai');
     bdIsLoaded('essai')              % faux : construit n'est pas ouvert
     open_system(m);
     bdIsLoaded('essai')              % vrai
     bdclose('all');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDCLOSE, GCS, LOAD_SYSTEM.
```

## `bdclose`

```
BDCLOSE Ferme un modèle, ou tous.
  BDCLOSE(NOM) retire du registre le modèle nommé. BDCLOSE('all') les
  retire tous. BDCLOSE() sans argument ferme le dernier ouvert.

  Fermer ne détruit pas la valeur : la variable qui porte le modèle
  reste, et un nouvel OPEN_SYSTEM le rouvre. C'est le registre de la
  session qui se vide, celui que lisent GCS et BDISLOADED.

  Exemple :
     m = new_system('essai');
     open_system(m);
     bdclose('essai');
     bdIsLoaded('essai')              % faux

  Voir aussi CLOSE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS.
```

## `bdroot`

```
BDROOT Le nom du modèle.
  NOM = BDROOT(MODELE) rend le nom du modèle. BDROOT() sans argument
  rend celui du dernier modèle ouvert par OPEN_SYSTEM.

  Dans MATLAB, BDROOT remonte du bloc courant jusqu'au modèle qui le
  contient. Ici un modèle est une valeur qu'on tient dans une variable,
  et non un objet ouvert dans une fenêtre : il n'y a rien à remonter,
  sinon le nom.

  BDROOT(CHEMIN) et BDROOT(H) rendent le nom du modèle qui porte le
  bloc 'modele/sousSysteme/bloc' ou l'objet de poignée H.

  Exemple :
     m = new_system('asservissement');
     bdroot(m)                        % 'asservissement'

  Voir aussi NEW_SYSTEM, GCS, OPEN_SYSTEM, FIND_SYSTEM.
```

## `close_system`

```
CLOSE_SYSTEM Ferme un modèle, en l'enregistrant au besoin.
  CLOSE_SYSTEM(MODELE) retire le modèle du registre de la session et
  ferme la figure que OPEN_SYSTEM avait tracée, s'il y en avait une.
  CLOSE_SYSTEM(MODELE,FICHIER) l'enregistre d'abord, par SAVE_SYSTEM.
  CLOSE_SYSTEM(NOM) accepte aussi le nom d'un modèle ouvert, et
  CLOSE_SYSTEM() sans argument ferme le dernier ouvert.

  Fermer ne détruit pas la valeur : la variable qui porte le modèle
  reste. C'est le registre de la session qui se vide, celui que lisent
  GCS et BDISLOADED.

  CLOSE_SYSTEM(NOM,0) ferme sans enregistrer et CLOSE_SYSTEM(NOM,1)
  enregistre d'abord, sous le nom du modèle : les drapeaux de MATLAB.

  Exemple :
     m = new_system('essai');
     open_system(m);
     close_system(m);
     bdIsLoaded('essai')              % faux

  Voir aussi OPEN_SYSTEM, BDCLOSE, SAVE_SYSTEM, GCS.
```

## `delete_block`

```
DELETE_BLOCK Retire un bloc du modèle, et les liens qui y touchent.
  MODELE = DELETE_BLOCK(MODELE,NOM) enlève le bloc nommé. Les liens qui
  partaient de lui ou arrivaient à lui disparaissent avec lui : laisser
  un lien vers un bloc absent rendrait le modèle insimulable.

  Les blocs qui suivent sont renumérotés, puisque les liens désignent
  les blocs par leur rang. C'est transparent : on désigne toujours un
  bloc par son nom.

  Comme ADD_BLOCK, la fonction rend un nouveau modèle et laisse
  l'ancien intact : un modèle est ici une valeur, non une référence.
  Dans MATLAB, DELETE_BLOCK modifie le modèle ouvert et ne rend rien.

  La forme de MATLAB : DELETE_BLOCK(CHEMIN), le bloc 'modele/bloc' d'un
  modèle de la session, sa poignée, ou une cellule de chemins. Un Inport
  ou un Outport retiré fait reculer d'un rang ceux qui le suivaient,
  comme dans Simulink.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     m = add_line(m, 'c', 'g');
     m = delete_block(m, 'g');
     numel(m.blocs)                       % 1
     isempty(m.liens)                     % le lien est parti avec le bloc

  Voir aussi ADD_BLOCK, DELETE_LINE, REPLACE_BLOCK, FIND_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `delete_line`

```
DELETE_LINE Supprime le lien qui va d'un bloc à un autre.
  MODELE = DELETE_LINE(MODELE,SOURCE,DESTINATION) supprime le lien
  allant d'une sortie du premier bloc à une entrée du second.
  DELETE_LINE(MODELE,SOURCE,DESTINATION,E) précise l'entrée, quand
  plusieurs liens joignent les deux mêmes blocs ;
  DELETE_LINE(MODELE,SOURCE,DESTINATION,E,S) précise aussi la sortie.
  La syntaxe de Simulink, « 'demux/2' », désigne un port comme dans
  ADD_LINE.

  Un lien qui n'existe pas lève une erreur qui nomme les deux blocs,
  plutôt que de laisser croire à une suppression qui n'a pas eu lieu.

  La forme de MATLAB : DELETE_LINE(SYSTEME,SORTIE,ENTREE) sur un modèle
  de la session désigné par son nom, et DELETE_LINE(H), H la poignée
  d'une ligne, qui retire tous les liens partant de ce port.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     m = add_line(m, 'c', 'g');
     m = delete_line(m, 'c', 'g');
     isempty(m.liens)                 % vrai

  Voir aussi ADD_LINE, DELETE_BLOCK, NEW_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `delete_param`

```
DELETE_PARAM Retire un réglage du modèle.
  MODELE = DELETE_PARAM(MODELE,'Nom',...) enlève un ou plusieurs
  réglages posés par ADD_PARAM. Le modèle retrouve alors le
  comportement par défaut : SIM reprend ses dix secondes et son
  centième de seconde.

  Un réglage absent est refusé en le nommant, plutôt que passé sous
  silence : croire avoir retiré ce qui n'y était pas mène à chercher
  longtemps pourquoi rien n'a changé.

  Exemple :
     m = new_system('essai');
     m = add_param(m, 'StopTime', 2);
     m = delete_param(m, 'StopTime');
     isfield(m.parametres, 'StopTime')        % faux

  Voir aussi ADD_PARAM, SET_PARAM, GET_PARAM, NEW_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `detachConfigSet`

```
DETACHCONFIGSET Détache un jeu de configuration d'un modèle.
  CS = DETACHCONFIGSET(MODELE,NOM) retire du modèle de la session nommé
  MODELE le jeu nommé NOM, et le rend, libre. Le jeu actif ne se
  détache pas : il faut d'abord en activer un autre.

  [MODELE,CS] = DETACHCONFIGSET(MODELE,NOM) fait de même sur un modèle
  par valeur.

  Exemple :
     m = new_system('essai');
     cs = Simulink.ConfigSet;
     cs.Name = 'Rapide';
     m = attachConfigSet(m, cs);
     [m, libre] = detachConfigSet(m, 'Rapide');
     getConfigSets(m)                         % {'Configuration'}

  Voir aussi ATTACHCONFIGSET, SETACTIVECONFIGSET, GETCONFIGSETS.
```

## `dlinmod`

```
DLINMOD Linéarise un modèle et l'échantillonne à la période TS.
  [A,B,C,D] = DLINMOD(MODELE,TS) linéarise le modèle comme LINMOD, puis
  discrétise le résultat par bloqueur d'ordre zéro : l'entrée est tenue
  constante entre deux instants d'échantillonnage.
  [A,B,C,D] = DLINMOD(MODELE,TS,X,U) choisit le point de
  fonctionnement ; PARA joue le même rôle que dans LINMOD.
  SYS = DLINMOD(...) rend la structure à champs a, b, c, d.

  La discrétisation est exacte, non approchée : Ad et Bd sortent d'une
  seule exponentielle de matrice, celle de [A B ; 0 0]*TS, dont le bloc
  supérieur droit vaut l'intégrale de exp(A t) B — ce qui évite d'avoir
  à inverser A, qui est souvent singulière.

  TS nul rend la linéarisation continue elle-même, comme dans MATLAB.

  Les états discrets — Unit Delay et Delay, Discrete-Time Integrator,
  Discrete Transfer Fcn, Discrete Filter, Discrete Zero-Pole, Discrete
  State-Space — tournant à la période TS se linéarisent par leur mise à
  jour : l'état X du modèle échantillonné porte les états continus, puis
  les discrets, et la partie continue s'échantillonne par bloqueur
  d'ordre zéro, les états discrets et les entrées tenus entre deux
  instants. X donne alors les deux sortes d'états, ou les seuls états
  continus. Un bloc discret d'une autre période est refusé : MatLibre ne
  le rééchantillonne pas.

  Exemple :
     m = new_system('premier');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'x', 's', 2);
     m = add_line(m, 's', 'x');
     m = add_line(m, 'x', 'y');
     [Ad, Bd] = dlinmod(m, 0.5);
     abs(Ad - exp(-0.5)) < 1e-12          % le pole continu -1

  Voir aussi LINMOD, TRIM, C2D, SIM.
```

## `find_system`

```
FIND_SYSTEM Les blocs d'un modèle, éventuellement filtrés.
  NOMS = FIND_SYSTEM(MODELE) rend le nom de tous les blocs.
  NOMS = FIND_SYSTEM(MODELE,'BlockType',TYPE) ne garde que ceux du type
  donné. D'autres couples nom-valeur filtrent sur les paramètres.

  Le filtre est conjonctif : un bloc n'est gardé que s'il répond à tous
  les critères. Sans critère, tous les blocs sortent.

  La comparaison est textuelle, y compris sur les valeurs numériques :
  un gain de 2 se retrouve aussi bien par 2 que par '2', puisque c'est
  ainsi qu'ADD_BLOCK accepte de l'écrire.

  La forme de MATLAB : FIND_SYSTEM(SYSTEME,OPTIONS...,CRITERES...),
  SYSTEME le nom d'un modèle de la session, un chemin ou une poignée,
  rend en colonne les chemins complets — le système lui-même, puis ses
  blocs, sous-systèmes compris. Options : SearchDepth, LookUnderMasks,
  FollowLinks, FindAll (des poignées, lignes et ports compris), RegExp,
  CaseSensitive, FirstResultOnly, et IncludeCommented : un bloc mis en
  commentaire, et ce qu'il contient, ne sort que si elle vaut 'on'.
  FIND_SYSTEM() cherche dans tous les modèles ouverts,
  FIND_SYSTEM('type','block_diagram') les nomme.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g1', 'Gain', 2);
     m = add_block(m, 'gain', 'g2', 'Gain', 3);
     m = add_block(m, 'constant', 'c', 'Value', 1);
     numel(find_system(m))                        % 3
     numel(find_system(m, 'BlockType', 'gain'))   % 2
     find_system(m, 'Gain', 3)                    % {'g2'}

  Voir aussi GET_PARAM, SET_PARAM, ADD_BLOCK, NEW_SYSTEM.
La forme de MATLAB : les modèles ouverts, désignés par leur nom ;
FIND_SYSTEM() les rend tous.
```

## `gcb`

```
GCB Le bloc courant.
  GCB rend le chemin du bloc courant — celui qu'on a choisi dans
  l'éditeur de Simulink. Hors de l'éditeur, aucun bloc ne l'est : GCB
  rend un texte vide, comme Simulink quand rien n'est choisi.
  GCB(SYSTEME) est accepté de même.

  Exemple :
     bdclose('all');
     m = new_system('regulateur');
     add_block(m, 'gain', 'g', 'Gain', 2);
     isempty(gcb())                   % vrai : aucun bloc n'est choisi
     bdclose('all');

  Voir aussi GCS, BDROOT, GETFULLNAME.
```

## `gcs`

```
GCS Le nom du dernier modèle ouvert.
  NOM = GCS() rend le nom du modèle ouvert le plus récemment par
  OPEN_SYSTEM ou LOAD_SYSTEM, et une chaîne vide si aucun ne l'est.

  Dans MATLAB, GCS rend le système courant, celui dont la fenêtre a le
  focus. Il n'y a pas de fenêtre ici, et la notion la plus proche est
  celle du dernier modèle ouvert : c'est ce que rend GCS.

  Exemple :
     bdclose('all');
     m = new_system('regulateur');
     open_system(m);
     gcs()                            % 'regulateur'
     bdclose('all');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, BDROOT, BDISLOADED.
```

## `getActiveConfigSet`

```
GETACTIVECONFIGSET Le jeu de configuration actif d'un modèle.
  CS = GETACTIVECONFIGSET(MODELE) rend le Simulink.ConfigSet actif du
  modèle : ses réglages sont ceux que SIM applique. MODELE est le nom
  d'un modèle de la session — le jeu y reste alors lié, et
  SET_PARAM(CS,...) règle le modèle — ou un modèle par valeur, dont le
  jeu rendu est une copie.

  Exemple :
     bdclose('all');
     new_system('essai');
     cs = getActiveConfigSet('essai');
     set_param(cs, 'StopTime', '5');
     get_param('essai', 'StopTime')           % '5'
     bdclose('all');

  Voir aussi SIMULINK.CONFIGSET, GETCONFIGSETS, SETACTIVECONFIGSET,
  ATTACHCONFIGSET.
```

## `getConfigSet`

```
GETCONFIGSET Un jeu de configuration d'un modèle, par son nom.
  CS = GETCONFIGSET(MODELE,NOM) rend le Simulink.ConfigSet nommé NOM
  parmi ceux du modèle, actif ou non. Pour un modèle de la session,
  désigné par son nom, le jeu y reste lié ; pour un modèle par valeur,
  c'est une copie.

  Exemple :
     m = new_system('essai');
     cs = Simulink.ConfigSet;
     cs.Name = 'Rapide';
     m = attachConfigSet(m, cs);
     get_param(getConfigSet(m, 'Rapide'), 'StopTime')     % '10'

  Voir aussi GETCONFIGSETS, GETACTIVECONFIGSET, ATTACHCONFIGSET.
```

## `getConfigSets`

```
GETCONFIGSETS Les noms des jeux de configuration d'un modèle.
  NOMS = GETCONFIGSETS(MODELE) rend en colonne les noms des jeux du
  modèle, le jeu actif d'abord. MODELE est le nom d'un modèle de la
  session, ou un modèle par valeur.

  Exemple :
     m = new_system('essai');
     getConfigSets(m)                         % {'Configuration'}

  Voir aussi GETCONFIGSET, GETACTIVECONFIGSET, ATTACHCONFIGSET.
```

## `getSimulinkBlockHandle`

```
GETSIMULINKBLOCKHANDLE La poignée d'un bloc, ou -1 s'il n'existe pas.
  H = GETSIMULINKBLOCKHANDLE(CHEMIN) rend la poignée du bloc
  'modele/bloc' d'un modèle de la session, et -1 si le modèle n'est pas
  ouvert ou n'a pas ce bloc : c'est la façon de demander si un bloc
  existe sans attraper d'erreur. Une cellule de chemins rend un vecteur.
  GETSIMULINKBLOCKHANDLE(CHEMIN,true) charge d'abord le modèle par
  LOAD_SYSTEM s'il n'est pas ouvert.

  Exemple :
     bdclose('all');
     new_system('essai');
     add_block('built-in/Gain', 'essai/g');
     getSimulinkBlockHandle('essai/g') > 0        % vrai
     getSimulinkBlockHandle('essai/absent')       % -1
     bdclose('all');

  Voir aussi GET_PARAM, GETFULLNAME, FIND_SYSTEM, SIMULINK.FINDBLOCKS.
```

## `get_param`

```
GET_PARAM Lit un paramètre d'un bloc, ou un réglage du modèle.
  V = GET_PARAM(MODELE,BLOC,'Param') rend la valeur du paramètre du bloc
  nommé — celle qu'on lui a donnée, ou, à défaut, sa valeur par défaut,
  comme dans Simulink. BLOC est le nom du bloc, ou son chemin
  « modele/bloc » ; « sousSysteme/bloc » descend dans un sous-système.
  GET_PARAM(MODELE,BLOC) rend la structure entière du bloc : son type,
  son nom et les paramètres qu'on lui a donnés.

  Quelques paramètres se lisent sans avoir été posés :
    BlockType     le type MatLibre du bloc (« gain », « integrator »)
    Name, Parent  son nom, et le système qui le contient
    Ports         [entrées sorties 0 0 0 0 0 0], comme Simulink
    PortHandles   les poignées de ses ports : Inport, Outport...
    DialogParameters  la liste de ses paramètres, avec leurs valeurs
                  admises quand ce sont des choix
    ObjectParameters  tous ses paramètres — ceux du dialogue, et Name,
                  Parent, BlockType, Ports... —, leur type, leurs valeurs
                  admises et s'ils se règlent (Attributes)
    Mask, MaskType  'off' et '' pour un bloc sans masque
    Position, Orientation, BackgroundColor, ShowName, Commented...  les
                  réglages que tout bloc porte ; non posés, ils valent
                  le défaut de Simulink, et Position le cadre où la mise
                  en place range le bloc
    CompiledSampleTime  sa période, [période décalage], une fois le
                  modèle compilé : [0 0] continue, [0 1] continue fixée
                  aux pas mineurs, [Inf 0] constante
    CompiledPortWidths, CompiledPortDimensions, CompiledPortDataTypes,
    CompiledPortComplexSignals  la largeur, les dimensions ([nombre de
                  dimensions, dimensions...] par port), le type et la
                  complexité de ses ports, Inport et Outport

  GET_PARAM(MODELE,'ModelWorkspace') rend l'espace de travail du modèle,
  un Simulink.ModelWorkspace, dont les variables passent avant celles de
  l'espace de base.

  GET_PARAM(MODELE,'Reglage') rend un réglage du modèle : Name, Blocks,
  et ceux de la boîte « Paramètres de configuration » — StopTime,
  Solver, FixedStep... —, avec leur valeur par défaut quand on ne les a
  pas posés. Un réglage posé par ADD_PARAM se lit de même.

  GET_PARAM(MODELE,H,'Reglage'), H une poignée de port, rend un réglage
  du signal qui part de ce port — Name, DataLogging... — ou PortType,
  PortNumber, Parent.

  C'est le pendant de SET_PARAM. Un paramètre que le bloc n'a pas lève
  une erreur qui le nomme, plutôt que de rendre une valeur vide dont on
  ne saurait pas si elle est le réglage ou son absence.

  La forme de MATLAB : V = GET_PARAM(OBJET,'Param'), OBJET un modèle de
  la session ('modele'), un bloc ('modele/bloc'), une poignée, ou une
  cellule de ceux-là. Elle répond comme Simulink : les paramètres du
  dialogue et les réglages de configuration en texte ('3', non 3),
  BlockType le type de Simulink ('Gain'), Type 'block', 'block_diagram',
  'port' ou 'line'. S'y ajoutent Handle, LineHandles, PortConnectivity,
  Lines et, pour un port ou une ligne, Line, SrcBlockHandle,
  SrcPortHandle, DstBlockHandle, DstPortHandle. Position y est en
  pixels. Du modèle se lisent aussi Dirty — 'on' s'il a changé depuis
  son fichier — et FileName, le fichier d'où il vient ou vers lequel
  on l'a enregistré.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     get_param(m, 'g', 'Gain')            % 2
     m = set_param(m, 'g', 'Gain', 5);
     get_param(m, 'g', 'Gain')            % 5
     get_param(m, 'g').type               % 'gain'
     get_param(m, 'g', 'Multiplication')  % 'Element-wise(K.*u)', le défaut
     get_param(m, 'essai/g', 'Ports')     % [1 1 0 0 0 0 0 0]
     get_param(m, 'Solver')               % 'VariableStepAuto'

  Voir aussi SET_PARAM, ADD_PARAM, ADD_BLOCK, FIND_SYSTEM, NEW_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `getfullname`

```
GETFULLNAME Le chemin complet d'un bloc, « modele/bloc ».
  CHEMIN = GETFULLNAME(MODELE,NOM) rend 'modele/bloc', la forme sous
  laquelle Simulink désigne un bloc. GETFULLNAME(MODELE) rend le nom du
  modèle seul.

  Le bloc doit exister : un chemin vers un bloc absent se propagerait
  sans erreur jusqu'à l'endroit où il ne veut rien dire.

  La forme de MATLAB : GETFULLNAME(H) rend le chemin de l'objet que
  désigne une poignée — un modèle, un bloc, 'modele/bloc/port' pour un
  port ou une ligne — et une cellule pour plusieurs.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     getfullname(m, 'k')              % 'boucle/k'

  Voir aussi FIND_SYSTEM, GET_PARAM, BDROOT, NEW_SYSTEM.
La forme de MATLAB : GETFULLNAME(H), une poignée, plusieurs, ou un chemin.
```

## `linearize`

```
LINEARIZE Linéarise un modèle entre des points d'analyse.
  SYS = LINEARIZE(MODELE,IO) linéarise le modèle autour de son état
  initial, des entrées aux sorties que désignent les points IO de
  LINIO, et rend un modèle d'état SS. Une 'input' ajoute une
  perturbation au signal, une 'output' le mesure, une coupure ouvre la
  boucle : c'est ainsi qu'on lit, sur le schéma d'une boucle fermée, le
  procédé seul, la boucle ouverte, ou la sensibilité.
  SYS = LINEARIZE(MODELE) linéarise des blocs INPORT aux blocs OUTPORT
  du modèle, comme LINMOD.
  [SYS,POINT] = LINEARIZE(...) rend aussi le point de fonctionnement :
  une structure à champs x et u.

  MODELE est le nom d'un modèle de la session, ou un modèle par valeur.
  Un point se pose sur n'importe quel bloc, sous-systèmes compris, par
  son chemin : 'modele/regulateur/gain'. Les points posés sur un même
  signal se suivent dans l'ordre où on les donne.

  Le calcul est celui de LINMOD, sur le modèle où chaque point est
  devenu ce qu'il dit : il est donc exact, à l'arrondi près, sur un
  modèle linéaire. Un modèle à états discrets se linéarise par DLINMOD,
  à la période de ses blocs discrets, et SYS est échantillonné.

  Ce que LINEARIZE ne fait pas : choisir un autre point de
  fonctionnement que l'état initial — LINMOD(MODELE,X,U) le fait, entre
  les ports du modèle — ; retirer les états qui ne pèsent pas sur le
  transfert demandé — SYS garde tous les états du modèle, et MINREAL
  réduit — ; rééchantillonner un modèle à plusieurs périodes.

  Exemple :
     bdclose('all');
     new_system('boucle');
     add_block('simulink/Sources/Step', 'boucle/consigne');
     add_block('simulink/Math Operations/Sum', 'boucle/ecart', 'Inputs', '+-');
     add_block('simulink/Math Operations/Gain', 'boucle/regul', 'Gain', '4');
     add_block('simulink/Continuous/Transfer Fcn', 'boucle/procede', ...
               'Numerator', '1', 'Denominator', '[1 2 1]');
     add_line('boucle', {'consigne/1', 'ecart/1', 'regul/1', 'procede/1'}, ...
              {'ecart/1', 'regul/1', 'procede/1', 'ecart/2'});
     io(1) = linio('boucle/consigne', 1, 'input');
     io(2) = linio('boucle/procede', 1, 'output');
     ferme = linearize('boucle', io);
     dcgain(ferme)                            % 0.8 : 4/(1+4)
     io(1) = linio('boucle/regul', 1, 'openinput');
     procede = linearize('boucle', io);
     dcgain(procede)                          % 1 : le procédé seul
     bdclose('all');

  Voir aussi LINIO, LINMOD, DLINMOD, TRIM, SS, MINREAL.
```

## `linio`

```
LINIO Un point d'analyse, pour LINEARIZE.
  IO = LINIO(BLOC,PORT,TYPE) désigne le signal qui part du port de
  sortie PORT du bloc BLOC — son chemin 'modele/bloc', ou sa poignée —
  et dit ce que LINEARIZE y fait :
    'input'            une entrée : une perturbation ajoutée au signal
    'output'           une sortie : le signal, mesuré
    'loopbreak'        une coupure : la boucle est ouverte ici
    'openinput'        une coupure, puis une entrée
    'openoutput'       une sortie, puis une coupure
    'looptransfer'     une sortie, une coupure, puis une entrée : le
                       transfert de boucle, avec le signe du schéma
    'sensitivity'      une entrée, puis une sortie
    'compsensitivity'  une sortie, puis une entrée
  LINIO(BLOC,PORT) pose une entrée.

  IO est une structure : Active ('on'), Block, OpenLoop, PortNumber,
  Type, BusElement et Description. Plusieurs points se rangent en
  vecteur : IO(1) = LINIO(...); IO(2) = LINIO(...). OpenLoop réglé sur
  'on' coupe la boucle au point — d'une 'input', il fait une
  'openinput' — ; un type qui porte déjà sa coupure la garde quel que
  soit OpenLoop : pour la retirer, on change Type. Active réglé sur
  'off' fait ignorer le point.

  L'ancienne écriture est comprise : LINIO(BLOC,PORT,T,OUVERTURE), T
  valant 'in', 'out', 'inout' (sensitivity), 'outin' (compsensitivity)
  ou 'none', et OUVERTURE 'on' ou 'off'.

  Exemple :
     io(1) = linio('boucle/consigne', 1, 'input');
     io(2) = linio('boucle/procede', 1, 'openoutput');
     io(2).Type                               % 'openoutput'
     io(2).OpenLoop                           % 'on'

  Voir aussi LINEARIZE, LINMOD, DLINMOD.
```

## `linmod`

```
LINMOD Linéarise un modèle autour d'un point de fonctionnement.
  [A,B,C,D] = LINMOD(MODELE) linéarise le modèle autour de son état
  initial et de l'entrée nulle. Les entrées sont les blocs INPORT,
  classés par leur paramètre Port ; les sorties, les blocs OUTPORT ; les
  états, ceux des blocs continus — intégrateurs, représentations d'état,
  fonctions de transfert, PID —, dans l'ordre du modèle. Une entrée ou
  une sortie vecteur compte pour autant de voies qu'elle a d'éléments.

  [A,B,C,D] = LINMOD(MODELE,X,U) choisit le point de fonctionnement.
  [A,B,C,D] = LINMOD(MODELE,X,U,PARA) donne dans PARA(3) le pas de
  perturbation ; PARA(1) est accepté et sans effet, rien n'étant
  simulé : le modèle s'évalue en un point.
  SYS = LINMOD(...) rend une structure à champs a, b, c, d, StateName,
  InputName et OutputName, comme MATLAB.

  La linéarisation est numérique, par différences centrées : elle est
  donc exacte, à l'arrondi près, sur un modèle déjà linéaire. Sur un
  bloc à cassure — saturation, zone morte, relais, aiguillage — elle
  rend la pente locale, et n'a pas de sens au point de cassure même.

  Un bloc DERIVATIVE est refusé : sa sortie dépend du pas de calcul,
  si bien que sa linéarisation dépendrait d'un réglage du simulateur
  plutôt que du modèle.

  Exemple :
     m = new_system('deuxieme');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'v');
     m = add_block(m, 'integrator', 'p');
     m = add_block(m, 'gain', 'k', 'Gain', 4);
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'k', 's', 2);
     m = add_line(m, 's', 'v');
     m = add_line(m, 'v', 'p');
     m = add_line(m, 'p', 'k');
     m = add_line(m, 'p', 'y');
     [A, B, C, D] = linmod(m);
     A                                   % [0 -4 ; 1 0]

  Voir aussi DLINMOD, TRIM, SIM, SS.
```

## `load_system`

```
LOAD_SYSTEM Relit un modèle enregistré, et l'ouvre dans la session.
  MODELE = LOAD_SYSTEM(NOM) exécute le fichier NOM.m — celui qu'écrit
  SAVE_SYSTEM, ou tout autre programme qui rend un modèle — et rend le
  modèle obtenu. Le modèle est inscrit au registre de la session :
  BDISLOADED répond vrai, et GCS le nomme.

  Le chemin peut porter l'extension .m ou non. Un fichier .slx ou .mdl,
  ceux qu'enregistre Simulink, se lit aussi : ses blocs, ses liens, ses
  sous-systèmes et sa configuration deviennent un modèle de MatLibre
  (voir MATLIBRE_SL_SLX). Les rappels PreLoadFcn et PostLoadFcn du
  modèle s'exécutent au chargement.

  Exemple :
     m = new_system('petit');
     m = add_block(m, 'constant', 'c', 'Value', 7);
     chemin = save_system(m, [tempname() '.m']);
     relu = load_system(chemin);
     get_param(relu, 'c', 'Value')            % 7
     bdclose('petit');
     delete(chemin);

  Voir aussi SAVE_SYSTEM, OPEN_SYSTEM, BDISLOADED, GCS, SIM.
```

## `matlibre_meme_valeur`

```
MATLIBRE_MEME_VALEUR Compare deux valeurs de paramètre, texte ou nombre.
  Un paramètre de bloc s'écrit indifféremment en nombre ou en texte :
  ADD_BLOCK accepte « 'Gain', 2 » comme « 'Gain', '2' ». La recherche
  doit donc les tenir pour égaux, sans quoi retrouver un bloc dépendrait
  de la façon dont on l'a écrit.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_meme_valeur(2, '2')        % 1
     matlibre_meme_valeur('abc', 'abc')  % 1
     matlibre_meme_valeur(2, 3)          % 0

  Voir aussi FIND_SYSTEM, GET_PARAM.
```

## `matlibre_sl_allure`

```
MATLIBRE_SL_ALLURE Dessine dans le bloc l'allure de ce qu'il produit.
  TRACE = MATLIBRE_SL_ALLURE(BLOC,X,Y,L,H) trace la petite courbe qui
  figure la fonction du bloc — l'échelon, la rampe, la sinusoïde, la
  saturation — et rend vrai si elle a été tracée.

  Un dessin dit d'un coup ce qu'un nom demande de lire. Les blocs sans
  allure connue rendent faux, et c'est alors leur étiquette qui parle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_allure(struct('type', 'step'), 0, 0, 1.7, 1)   % 1

  Voir aussi MATLIBRE_SL_FORME, MATLIBRE_SL_ETIQUETTE.
```

## `matlibre_sl_aplatir`

```
MATLIBRE_SL_APLATIR Déplie les sous-systèmes d'un modèle.
  MODELE = MATLIBRE_SL_APLATIR(MODELE) rend le même modèle, où chaque
  bloc de type « subsystem » a été remplacé par les blocs qu'il
  contient. Un modèle sans sous-système est rendu tel quel.

  Les blocs mis en commentaire (Commented) partent d'abord, par
  MATLIBRE_SL_COMMENTES : rien de ce qui calcule ne les voit.

  C'est ainsi qu'un sous-système se simule : non pas comme un bloc à
  part, mais comme le schéma qu'il abrège. SIM, LINMOD, TRIM et
  MATLIBRE_SL_PROGRAMME appellent tous cette fonction d'abord, si bien
  qu'aucun d'eux n'a besoin de savoir qu'un sous-système existe.

  Le dépliage garde trois choses. Les blocs intérieurs prennent le nom
  « sousSysteme/bloc », comme dans Simulink, et se retrouvent donc
  nommés dans le relevé. Le bloc du sous-système lui-même ne
  disparaît pas : il reste, en passe-plat à autant de ports qu'il a de
  sorties, chaque OUTPORT intérieur alimentant la sortie de même rang
  — un relevé pris sur le sous-système reste donc celui de sa première
  sortie, et un lien qui partait de sa deuxième sortie part toujours de
  la sortie de l'OUTPORT de rang 2. Et les entrées se raccordent par
  leur rang : le lien qui arrivait sur la deuxième entrée du bloc
  arrive sur le bloc INPORT intérieur dont le paramètre Port vaut 2.

  Les types sont ramenés à leur nom MatLibre par le catalogue : un
  bloc intérieur posé sous son nom Simulink (« In1 », « SubSystem »)
  se déplie comme les autres. Les liens rendus ont quatre colonnes —
  source, destination, entrée, sortie.

  Les sous-systèmes s'emboîtent : un sous-système qui en contient un
  autre est déplié jusqu'au bout.

  Un sous-système qui porte un port de contrôle — Enable, Trigger, ou
  Action Port — est conditionnel. Ses ports de contrôle sont des entrées
  de plus, après les autres : Enable, puis Trigger ; ou Action Port. Le
  dépliage fait de son premier port de contrôle une « garde », un bloc
  qui dit à chaque pas si le sous-système calcule ; chaque bloc
  intérieur en porte le rang dans son champ garde, et la compilation
  le lit. Un sous-système emboîté dans un conditionnel en hérite. Les
  OUTPORT intérieurs gardent leur valeur initiale et leur conduite à
  l'arrêt (OutputWhenDisabled) dans le champ sortieConditionnelle.

  Un sous-système itéré — qui porte un bloc For Iterator ou While
  Iterator — ne se déplie pas : il calcule plusieurs fois par pas, ce
  qu'un schéma à plat ne sait pas dire. Il devient un bloc « iterateur »
  qui garde son modèle, et que la simulation fait tourner à part.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = new_system('doubleur');
     interne = add_block(interne, 'inport', 'e', 'Port', 1);
     interne = add_block(interne, 'gain', 'deux', 'Gain', 2);
     interne = add_block(interne, 'outport', 's', 'Port', 1);
     interne = add_line(add_line(interne, 'e', 'deux'), 'deux', 's');
     m = add_block(new_system('dehors'), 'constant', 'un', 'Value', 3);
     m = add_block(m, 'subsystem', 'boite', 'Model', interne);
     m = add_line(m, 'un', 'boite');
     numel(matlibre_sl_aplatir(m).blocs)      % 5 : un, boite, e, deux, s

  Voir aussi SIM, ADD_BLOCK, MATLIBRE_SL_ORDRE.
```

## `matlibre_sl_bibliotheque`

```
MATLIBRE_SL_BIBLIOTHEQUE Déplie les blocs que Simulink bâtit en sous-systèmes.
  MODELE = MATLIBRE_SL_BIBLIOTHEQUE(MODELE) remplace chaque bloc de la
  bibliothèque que Simulink construit comme un sous-système masqué, et
  que MatLibre ne calcule pas d'un seul tenant, par le sous-système de
  blocs élémentaires qui fait la même chose. Le bloc garde son nom, ses
  liens et le relevé de sa sortie ; ses paramètres passent aux blocs du
  dedans tels qu'on les a écrits, expressions comprises.

  C'est le cas du PID continu dont on borne la sortie, qu'on protège de
  l'emballement (back-calculation, clamping), qu'on remet à zéro par une
  entrée, dont les conditions initiales arrivent par des entrées, ou
  dont la dérivée n'est pas filtrée : il devient gains, intégrateurs,
  dérivateur, sommes et saturation, comme dans Simulink. Le PID continu
  ordinaire et le PID discret se calculent d'un seul tenant.

  MATLIBRE_SL_APLATIR l'appelle avant de déplier les sous-systèmes.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'pidcontroller', 'k', 'LimitOutput', 'on', ...
                   'UpperSaturationLimit', 1);
     m = matlibre_sl_bibliotheque(m);
     m.blocs{1}.type                              % 'subsystem'

  Voir aussi MATLIBRE_SL_APLATIR, ADD_BLOCK.
```

## `matlibre_sl_bus`

```
MATLIBRE_SL_BUS Les types de bus : lecture, forme, conformité.
  NOM = MATLIBRE_SL_BUS('type',TEXTE) rend le nom du type d'un paramètre
  OutDataTypeStr qui vaut 'Bus: NOM', ou '' pour tout autre type.

  B = MATLIBRE_SL_BUS('objet',NOM,QUI) lit dans l'espace de travail de
  base l'objet SIMULINK.BUS nommé NOM ; QUI, le bloc qui le demande,
  est nommé dans l'erreur s'il manque ou n'est pas un type de bus.

  F = MATLIBRE_SL_BUS('forme',B,QUI) rend la forme du bus de type B :
  un élément par élément du type, avec son nom, ses dimensions, sa
  largeur, sa place dans le vecteur qui les porte bout à bout, et, pour
  un bus emboîté, sa propre forme.

  MATLIBRE_SL_BUS('accorder',F,B,QUI,NOMTYPE) vérifie qu'un bus de forme
  F est du type B : les mêmes éléments, sous les mêmes noms, dans le
  même ordre, aux mêmes dimensions.

  S = MATLIBRE_SL_BUS('structure',B) rend la structure qui a la forme du
  bus, faite de zéros.

  INFO = MATLIBRE_SL_BUS('creer',MODELE,BLOCS) crée les types des bus
  que forment des Bus Creator : c'est SIMULINK.BUS.CREATEOBJECT.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_bus('type', 'Bus: Capteurs')        % 'Capteurs'

  Voir aussi SIMULINK.BUS, SIMULINK.BUSELEMENT, MATLIBRE_SL_COMPILER.
```

## `matlibre_sl_catalogue`

```
MATLIBRE_SL_CATALOGUE Le catalogue des blocs : types, paramètres, bibliothèque.
  CAT = MATLIBRE_SL_CATALOGUE() rend le tableau de structures qui décrit
  chaque type de bloc que SIM sait simuler : son nom dans MatLibre, son
  type Simulink (BlockType), son nom dans la bibliothèque de Simulink et
  ses chemins (« simulink/Math Operations/Gain »), sa famille dans la
  bibliothèque du bureau, et la liste de ses paramètres avec leur valeur
  par défaut et leur nature.

  E = MATLIBRE_SL_CATALOGUE('type',DESIGNATION) rend l'entrée d'un type,
  désigné par son nom MatLibre (« gain »), son type Simulink (« Gain »,
  « Sin », « Saturate »), son nom de bibliothèque (« Sine Wave »,
  « Zero-Order Hold ») ou son chemin (« simulink/Sources/Step »). Une
  désignation inconnue est refusée en disant les types voisins.

  NOM = MATLIBRE_SL_CATALOGUE('parametre',E,NOM) rend l'écriture
  canonique d'un nom de paramètre pour le type E — la casse est
  indifférente, comme dans Simulink, et les noms de Simulink et ceux de
  MatLibre sont reconnus l'un pour l'autre (« Inputs » et « Signs » pour
  une sommation). Rend '' si le type ne porte pas ce paramètre.

  C'est la source unique de ce que chaque bloc accepte : ADD_BLOCK et
  SET_PARAM y valident les paramètres, GET_PARAM y lit les valeurs par
  défaut, SIM y prend les défauts qu'on n'a pas écrits.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     e = matlibre_sl_catalogue('type', 'simulink/Math Operations/Gain');
     e.type                                        % 'gain'
     matlibre_sl_catalogue('parametre', e, 'gain') % 'Gain'

  Voir aussi ADD_BLOCK, SET_PARAM, GET_PARAM, SIM.
```

## `matlibre_sl_charger`

```
MATLIBRE_SL_CHARGER Relit un modèle et le dépose dans l'espace de travail.
  NOM = MATLIBRE_SL_CHARGER(CHEMIN) relit le modèle — le fichier .m qui
  le bâtit, celui qu'écrit SAVE_SYSTEM, ou un fichier .slx ou .mdl venu
  de Simulink — et pose le modèle obtenu dans l'espace de travail de
  base, sous son propre nom. Il rend ce nom.

  C'est ce que fait l'éditeur du bureau quand on ouvre un modèle : il
  ne garde pas le modèle pour lui, il le met là où tout le monde le
  voit — la console, l'explorateur de variables, et l'éditeur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('reprise'), 'gain', 'k', 'Gain', 2);
     chemin = save_system(m, [tempname() '.m']);
     nom = matlibre_sl_charger(chemin);
     strcmp(nom, 'reprise')                  % 1
     delete(chemin);

  Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, OPEN_SYSTEM.
```

## `matlibre_sl_commentes`

```
MATLIBRE_SL_COMMENTES Retire du modèle les blocs mis en commentaire.
  [MODELE,CHANGE] = MATLIBRE_SL_COMMENTES(MODELE) rend le modèle tel que
  Simulink le calcule quand des blocs portent le réglage Commented :
    'on'       le bloc n'existe plus : ce qu'il alimentait lit zéro,
               comme d'un Ground
    'through'  le bloc est traversé : chaque sortie rend l'entrée de
               même rang. Il lui faut autant d'entrées que de sorties.
  Un sous-système commenté part avec tout ce qu'il contient ; les blocs
  commentés d'un sous-système qui reste sont retirés de même. Un modèle
  sans bloc commenté est rendu tel quel, et CHANGE est faux.

  MATLIBRE_SL_APLATIR l'appelle d'abord : SIM, LINMOD, TRIM et la
  compilation ne voient donc jamais un bloc commenté. GET_PARAM,
  FIND_SYSTEM et OPEN_SYSTEM, eux, le voient toujours : il est dans le
  modèle, il ne calcule pas.

  Un bloc de port d'un sous-système — Inport, Outport, Enable,
  Trigger... — ne se commente pas : il emporterait un port du
  sous-système, et les liens qui y tiennent. Ceux du modèle le peuvent :
  l'entrée commentée vaut zéro, la sortie commentée n'est plus une
  sortie.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 3);
     m = add_block(m, 'gain', 'g', 'Gain', 2, 'Commented', 'through');
     m = add_block(m, 'outport', 'y');
     m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
     numel(matlibre_sl_commentes(m).blocs)     % 2 : le gain est traversé
     r = sim(m, 'StopTime', 1);
     r.yout(end)                               % 3, non 6

  Voir aussi MATLIBRE_SL_APLATIR, SET_PARAM, SIM.
```

## `matlibre_sl_compiler`

```
MATLIBRE_SL_COMPILER Prépare un modèle pour la simulation.
  C = MATLIBRE_SL_COMPILER(MODELE,OPTIONS) fait ce que Simulink fait
  avant de simuler : il déplie les sous-systèmes, résout le type et les
  paramètres de chaque bloc — les expressions s'évaluent alors dans
  l'espace de travail de base —, vérifie le câblage port par port,
  propage les dimensions des signaux, attribue à chaque bloc sa période
  d'échantillonnage, range les états, ordonne le calcul, et détecte les
  boucles algébriques pour les résoudre.

  OPTIONS porte les champs pas (le pas de base, 0,01 par défaut),
  tDebut, tFinal et config (la configuration du modèle, que lit
  MATLIBRE_SL_CONFIG). Le champ silencieux, vrai, tait les diagnostics
  de connexion et de boucle — LINMOD s'en sert, qui compile plusieurs
  fois le même modèle. Le champ variable, vrai, prépare un solveur à
  pas variable : les périodes n'ont plus à diviser un pas, le retard
  pur garde les instants avec les valeurs, et les blocs à cassure sont
  marqués pour la détection des passages par zéro (c.zc).

  Chaque erreur nomme le bloc par son chemin, « modele/bloc », comme
  Simulink le fait : un port qui n'existe pas, deux liens vers une même
  entrée, des dimensions qui ne s'accordent pas, une période
  d'échantillonnage qui n'est pas un multiple du pas, un Goto
  introuvable. Une entrée non reliée ou une boucle algébrique donnent un
  avertissement ou une erreur selon les réglages UnconnectedInputMsg et
  AlgebraicLoopMsg du modèle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('m'), 'constant', 'c', 'Value', [1 2 3]);
     m = add_line(add_block(m, 'gain', 'k', 'Gain', 2), 'c', 'k');
     c = matlibre_sl_compiler(m, struct('silencieux', true));
     c.dims{c.portDebut(2)}                 % [3 1] : un vecteur de trois

  Voir aussi SIM, MATLIBRE_SL_SORTIES, MATLIBRE_SL_CATALOGUE.
```

## `matlibre_sl_config`

```
MATLIBRE_SL_CONFIG Les réglages d'un modèle : solveur, instants, diagnostics.
  C = MATLIBRE_SL_CONFIG('lire',MODELE) rend la configuration complète
  du modèle : chaque réglage qu'il porte, et la valeur par défaut de
  ceux qu'il ne porte pas. C'est ce que SIM applique, et ce que la boîte
  « Paramètres de configuration » de l'éditeur montre.

  NOM = MATLIBRE_SL_CONFIG('nom',NOM) rend l'écriture canonique d'un
  réglage — la casse est indifférente, comme dans Simulink — ou '' s'il
  n'existe pas.

  V = MATLIBRE_SL_CONFIG('valider',NOM,V) vérifie une valeur avant
  qu'on la pose, et la rend sous sa forme canonique : un nom de solveur
  inconnu est refusé en le nommant plutôt que rangé pour rien.

  S = MATLIBRE_SL_CONFIG('solveurs') rend la liste des solveurs
  disponibles, en deux champs : fixe et variable.

  T = MATLIBRE_SL_CONFIG('type',SOLVEUR) rend le type d'un solveur,
  'Fixed-step' ou 'Variable-step' ; MATLIBRE_SL_CONFIG('automatique',T)
  le solveur automatique d'un type.

  Les réglages reconnus, avec leur valeur par défaut :
    StartTime            0          l'instant initial
    StopTime             10         l'instant final
    SolverType           'Variable-step'  ou 'Fixed-step'
    Solver               'VariableStepAuto'  le solveur, comme dans un
                                    modèle neuf de Simulink. À pas fixe : ode1 à
                                    ode5, ode8, ode14x et ode1be
                                    (raides), odeN (la formule que
                                    choisit ODENIntegrationMethod),
                                    FixedStepDiscrete sans état
                                    continu, FixedStepAuto (ode3, ou
                                    le discret s'il n'y a pas d'état
                                    continu). À pas variable : ode45,
                                    ode23, ode113, ode15s, ode23s,
                                    ode23t et ode23tb (raides), daessc
                                    (les BDF, d'ordre 1 à MaxOrder),
                                    VariableStepDiscrete, et
                                    VariableStepAuto (ode45, ou le
                                    discret).
    FixedStep            0.01       le pas, en pas fixe ; 'auto' : le pas
                                    fondamental — le plus grand commun
                                    diviseur des périodes
                                    d'échantillonnage et de leurs
                                    décalages —, ou sans période la
                                    durée en cinquante pas (0,2 s sans
                                    fin), au plus le tiers de la
                                    période du sinus le plus rapide
    MaxStep, MinStep, InitialStep   'auto'  bornes du pas variable
    RelTol               1e-3       tolérance relative du pas variable
    AbsTol               'auto'     tolérance absolue du pas variable
    MaxOrder             5          l'ordre maximal d'ode15s et de
                                    daessc, de 1 à 5
    ODENIntegrationMethod 'ode3'    la formule d'odeN : ode1, ode2,
                                    ode3, ode4, ode5 ou ode8
    ExtrapolationOrder   4          l'ordre d'extrapolation d'ode14x,
                                    de 1 à 4
    NumberNewtonIterations  1       les itérations de Newton d'ode14x
                                    et d'ode1be à chaque pas
    ZeroCrossControl     'UseLocalSettings'  détection des passages par zéro
    ZeroCrossAlgorithm   'Nonadaptive'  'Adaptive' : un bloc qui bascule
                                    sans cesse n'est plus localisé,
                                    jusqu'au pas qui ne bascule pas
    ZcThreshold          'auto'     la bande autour de zéro où
                                    l'algorithme adaptatif ignore une
                                    traversée
    ConsecutiveZCsStepRelTol '10*128*eps'  la tolérance en temps : deux
                                    passages par zéro plus proches que
                                    elle fois l'instant se suivent, et
                                    comptent pour MaxConsecutiveZCs ;
                                    sous la résolution de localisation
                                    de MatLibre, 1e-7 fois l'instant,
                                    elle n'y change rien
    AutoScaleAbsTol      'on'       avec AbsTol 'auto' : la tolérance
                                    absolue de chaque état suit le plus
                                    grand module qu'il a pris, fois
                                    RelTol ; 'off' : elle reste à RelTol
                                    fois 1e-3
    ShapePreserveControl 'DisableAll'  'EnableAll' est accepté et
                                    rangé ; le pas de MatLibre ne suit
                                    que l'erreur estimée
    SolverJacobianMethodControl 'auto'  ou SparsePerturbation,
                                    FullPerturbation, SparseAnalytical,
                                    FullAnalytical : les solveurs
                                    implicites de MatLibre calculent le
                                    jacobien par perturbation, en
                                    entier — ce que Simulink fait aussi
                                    d'un bloc sans jacobien analytique
    SolverResetMethod    'Fast'     ou 'Robust' : le jacobien se
                                    recalcule à chaque pas, remises du
                                    solveur comprises, comme en Robust
    SampleTimeConstraint 'Unconstrained'  à pas fixe — 'STIndependent' :
                                    le modèle doit pouvoir hériter ses
                                    périodes de qui le référence, aucun
                                    bloc ne fixe la sienne et le pas
                                    reste 'auto' ; 'Specified' : ses
                                    périodes sont celles de
                                    SampleTimeProperty, et le pas
                                    'auto' leur plus grand commun
                                    diviseur
    SampleTimeProperty   []         les périodes imposées : une
                                    structure par période, champs
                                    SamplePeriod, Offset et Priority,
                                    de la plus rapide à la plus lente
    PositivePriorityOrder 'off', ConcurrentTasks 'off'  réglages de la
                                    génération de code, acceptés et
                                    rangés : la simulation n'en dépend
                                    pas
    ParameterArgumentNames ''       les arguments du modèle, quand un
                                    bloc Model le référence : des
                                    variables de son espace de travail,
                                    séparées par des virgules, auxquelles
                                    chaque bloc Model peut donner sa
                                    valeur (ParameterArgumentValues,
                                    InstanceParameters)
    LoggingToFile        'off'      'on' : les données journalisées en
    LoggingFileName      'out.mat'  Dataset — logsout, yout, xout — vont
                                    aussi dans ce fichier MAT
    SignalLoggingSaveFormat 'Dataset'  la forme du journal des signaux
    Description          ''         un texte qui décrit le modèle
    FastRestart          'off'      'on' est accepté : chaque simulation
                                    recompile le modèle, et donne ce
                                    qu'elle donnerait sans
    EnablePacing 'off', PacingRate 1  le rythme de la simulation dans
                                    l'éditeur, accepté et rangé
    ArrayBoundsChecking  'none'     accepté : un indice hors d'un
                                    tableau, dans une MATLAB Function,
                                    arrête toujours la simulation
    StrictBusMsg, DefaultParameterBehavior, InlineParams,
    SystemTargetFile, TargetLang, GenerateReport, Lock,
    SampleTimeColors, ShowPortDataTypes, RecordCoverage  réglages de la
                                    génération de code, de l'affichage
                                    et de la couverture : acceptés et
                                    rangés, la simulation n'en dépend
                                    pas
    SimulationStatus, SimulationTime, BlockDiagramType  se lisent sans
                                    se régler : 'stopped' et 0 hors
                                    simulation ; 'model', 'library' ou
                                    'subsystem'
    EnableMultiTasking   'off'      'on', à pas fixe : chaque cadence est
                                    une tâche, et un bloc discret ne lit
                                    un bloc d'une autre cadence qu'à
                                    travers un Rate Transition — ou un
                                    Zero-Order Hold, du rapide au lent
    AutoInsertRateTranBlk 'off'     'on' : les Rate Transition qui
                                    manquent se posent d'eux-mêmes
    MultiTaskRateTransMsg 'error'   une transition illégale en
                                    multitâche : warning ou error
    SingleTaskRateTransMsg 'none'   une transition sans Rate Transition
                                    en monotâche : none, warning, error
    ReadBeforeWriteMsg, WriteAfterReadMsg, WriteAfterWriteMsg
                         'UseLocalSettings'  les accès d'un pas aux
                                    mémoires partagées : lecture avant
                                    toute écriture, écriture après une
                                    lecture, seconde écriture — le
                                    réglage de chaque Data Store Memory
                                    ('none', 'none', 'warning' par
                                    défaut), ou 'DisableAll',
                                    'EnableAllAsWarning',
                                    'EnableAllAsError' pour toutes
    CheckMatrixSingularityMsg 'none'  un Product en multiplication
                                    matricielle qui inverse une matrice
                                    singulière : none, warning, error
    InheritedTsInSrcMsg  'warning'  un bloc source à période -1 — un
                                    compteur, un Repeating Sequence
                                    Stair par défaut —, qui l'hérite en
                                    arrière de ce qu'il alimente : none,
                                    warning, error
    BusObjectLabelMismatch 'warning'  un signal nommé qui entre dans un
                                    Bus Creator typé sous un autre nom
                                    que son élément : none, warning,
                                    error
    ParameterDowncastMsg 'error'    un paramètre qui porte un type,
                                    int32(5), rangé dans un type plus
                                    étroit
    ParameterOverflowMsg 'error'    la valeur d'un paramètre hors des
                                    bornes de son type entier ou à
                                    virgule fixe, saturée sinon
    ParameterUnderflowMsg 'none'    une valeur non nulle que son type
                                    rend nulle
    ParameterPrecisionLossMsg 'warning'  une valeur que son type
                                    arrondit ; ces quatre-là valent
                                    none, warning ou error, et portent
                                    sur la valeur d'un Constant et le
                                    gain d'un Gain (ParamDataTypeStr)
    AlgebraicLoopMsg     'warning'  boucle algébrique : none, warning, error
    UnconnectedInputMsg  'warning'  entrée non reliée : none, warning, error
    UnconnectedOutputMsg 'none'     sortie non reliée : none, warning, error
    MinStepSizeMsg       'warning'  à pas variable, plus de
    MaxConsecutiveMinStep 1         MaxConsecutiveMinStep pas de suite
                                    au pas minimal MinStep sans tenir
                                    la tolérance : warning, ou error
    MaxConsecutiveZCs    1000       plus de MaxConsecutiveZCs passages
    MaxConsecutiveZCsMsg 'error'    par zéro de suite, sans que le
                                    temps avance : none ou warning
                                    continuent en franchissant le
                                    seuil suivant sans le localiser
    SignalInfNanChecking 'none'     une sortie de bloc qui vaut Inf ou
                                    NaN à un pas majeur
    SignalRangeChecking  'none'     un signal hors de la plage [OutMin,
                                    OutMax] de son bloc
    DataTypeOverride     'UseLocalSettings'  'Double', 'Single' ou
                                    'ScaledDouble' : les types
                                    numériques des signaux et des
                                    paramètres se remplacent par le
                                    double ou le single — pour voir un
                                    modèle à virgule fixe sans ses
                                    débordements —, les booléens et les
                                    énumérations jamais ; 'Off' comme
                                    'UseLocalSettings' n'en remplace
                                    aucun
    DataTypeOverrideAppliesTo 'AllNumericTypes'  ou 'Floating-point',
                                    ou 'Fixed-point' (les entiers et
                                    les virgules fixes)
    IntegerOverflowMsg   'warning'  un entier ou une virgule fixe qui
                                    déborde de son type et s'y replie
    IntegerSaturationMsg 'warning'  ... et s'y sature
                                    (SaturateOnIntegerOverflow) ; ces
                                    trois-là valent none, warning ou
                                    error, l'avertissement une fois par
                                    bloc et par simulation
    LoadExternalInput    'off'      'on' : les entrées du modèle lisent
                                    ExternalInput
    InitFcn, StartFcn, StopFcn, PreLoadFcn, PostLoadFcn, PreSaveFcn,
    PostSaveFcn, CloseFcn   ''      les rappels du modèle : du code
                                    évalué dans l'espace de travail de
                                    base (voir MATLIBRE_SL_RAPPEL)
    SaveFormat           'Array'    la forme de yout : Array (une
                                    matrice), Structure,
                                    StructureWithTime, ou Dataset (un
                                    Simulink.SimulationData.Dataset de
                                    timeseries)
    SimulationMode       'normal'   accelerator et les autres modes
                                    sont acceptés, et simulent comme
                                    normal
    ReturnWorkspaceOutputs 'on', ReturnWorkspaceOutputsName 'out' : SIM
                                    appelé sans sortie dépose son
                                    résultat dans cette variable ; sinon
                                    dans tout et yout
    ExternalInput        '[t, u]'   le temps puis une colonne par
                                    élément des entrées, ou des
                                    variables séparées par des virgules,
                                    une par entrée
    LoadInitialState     'off'      'on' : la simulation part de
    InitialState         'xInitial' cet état — les états continus,
                                    dans l'ordre des colonnes de xout,
                                    ou un état de fonctionnement
                                    (Simulink.op.ModelOperatingPoint),
                                    d'où elle reprend
    SaveFinalState       'off'      'on' : le résultat porte l'état
    FinalStateName       'xFinal'   final dans ce champ
    SaveOperatingPoint   'off'      'on' : cet état final est l'état de
                                    fonctionnement complet
    SignalLogging        'on'       les signaux dont le port a
    SignalLoggingName    'logsout'  DataLogging à 'on' vont dans ce
                                    champ du résultat, un Dataset
    SaveTime             'on'       les instants relevés, dans le champ
    TimeSaveName         'tout'     TimeSaveName du résultat
    SaveState            'off'      'on' : les états continus, une
    StateSaveName        'xout'     colonne par état, dans StateSaveName
    SaveOutput           'on'       les sorties OUTPORT, dans
    OutputSaveName       'yout'     OutputSaveName
    Decimation           1          n'en garder qu'un instant sur
                                    Decimation
    LimitDataPoints      'off'      'on' : n'en garder que les
    MaxDataPoints        1000       MaxDataPoints derniers
    OutputOption         'RefineOutputTimes'  à pas variable, les
                                    instants relevés : les pas du
                                    solveur, et Refine - 1 points
                                    entre deux, calculés sur l'état
                                    interpolé (RefineOutputTimes) ; les
                                    pas et les instants OutputTimes,
                                    que le solveur atteint
                                    (AdditionalOutputTimes) ; le début,
                                    la fin et les instants OutputTimes
                                    seuls (SpecifiedOutputTimes). Un
                                    solveur à pas fixe relève chacun de
                                    ses pas.
    Refine               1          le facteur d'affinage
    OutputTimes          '[]'       les instants demandés : un vecteur,
                                    ou l'expression qui le donne

  Le solveur et son type vont ensemble, comme dans Simulink : poser
  Solver sur ode45 fait le type Variable-step ; poser SolverType sur
  Variable-step quand le solveur est à pas fixe le remplace par
  VariableStepAuto, et inversement par FixedStepAuto.

  Un modèle part, comme dans Simulink, du pas variable automatique ;
  un programme qui veut le pas fixe d'Euler le demande
  (set_param(m, 'Solver', 'ode1')).

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     c = matlibre_sl_config('lire', new_system('m'));
     c.Solver                                   % 'VariableStepAuto'
     matlibre_sl_config('nom', 'reltol')        % 'RelTol'

  Voir aussi SET_PARAM, GET_PARAM, SIM, SIMSET.
```

## `matlibre_sl_dedans`

```
MATLIBRE_SL_DEDANS Le modèle que porte un sous-système, au bout d'un chemin.
  SOUS = MATLIBRE_SL_DEDANS(MODELE,CHEMIN) descend dans les
  sous-systèmes que CHEMIN désigne — « boite » pour un seul niveau,
  « boite/interne » pour deux — et rend le modèle trouvé au bout. Un
  chemin vide rend le modèle lui-même.

  C'est ainsi que l'éditeur du bureau ouvre un sous-système : il ne le
  recopie pas, il le désigne. MATLIBRE_SL_REMPLACER fait le chemin
  inverse, et repose dessous ce qu'on y a modifié.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
     m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
                   'Model', interne);
     matlibre_sl_dedans(m, 'boite').nom          % 'dedans'

  Voir aussi MATLIBRE_SL_REMPLACER, MATLIBRE_SL_APLATIR, ADD_BLOCK.
```

## `matlibre_sl_derivee`

```
MATLIBRE_SL_DERIVEE Dérivée d'état et sortie d'un modèle en un point.
  [DX,Y] = MATLIBRE_SL_DERIVEE(MODELE,X,U) place les états continus à X
  et les entrées à U, calcule une passe de sortie, et rend la dérivée de
  chaque état ainsi que la valeur de chaque sortie. MODELE peut aussi
  être le modèle déjà préparé que rend MATLIBRE_SL_ETATS : les appels
  répétés de LINMOD et de TRIM ne le recompilent pas. Un quatrième
  argument, le pas, est accepté et ignoré : rien n'est simulé.

  La dérivée ne se mesure pas : elle se lit. L'entrée d'un intégrateur
  est sa dérivée, et une représentation d'état donne A x + B u, calculé
  sur l'entrée à l'instant même.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('chaine');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 3);
     m = add_block(m, 'integrator', 'x');
     m = add_line(m, 'u', 'k');
     m = add_line(m, 'k', 'x');
     matlibre_sl_derivee(m, 0, 2)           % 6 : la dérivée vaut 3*u

  Voir aussi LINMOD, DLINMOD, TRIM, SIM.
```

## `matlibre_sl_disposition`

```
MATLIBRE_SL_DISPOSITION Place les blocs d'un schéma sur la feuille.
  [X,Y,L,H] = MATLIBRE_SL_DISPOSITION(MODELE,RANGS) rend le centre de
  chaque bloc, ainsi que la largeur et la hauteur communes.

  Les blocs d'une même couche sont ordonnés par la hauteur moyenne de
  ceux qui les alimentent — le barycentre. Deux passes suffisent à
  défaire l'essentiel des croisements ; les ranger dans l'ordre de
  création en produirait à chaque embranchement.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     [x, y] = matlibre_sl_disposition(m, matlibre_sl_rangs(m));
     x(2) > x(1)                     % 1 : le gain est a droite

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_RANGS.
```

## `matlibre_sl_ecrire`

```
MATLIBRE_SL_ECRIRE Écrit dans un fichier le programme qui simule un schéma.
  CHEMIN = MATLIBRE_SL_ECRIRE(MODELE,CHEMIN) écrit à cet endroit le
  programme que rend MATLIBRE_SL_PROGRAMME, et rend le chemin écrit.
  L'extension .m est ajoutée si elle manque, et le nom de la fonction
  est celui du fichier — sans quoi elle ne s'appellerait pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('petit'), 'constant', 'c', 'Value', 1);
     f = matlibre_sl_ecrire(m, [tempname() '.m']);
     isfile(f)                                % 1
     delete(f);

  Voir aussi MATLIBRE_SL_PROGRAMME, SAVE_SYSTEM.
```

## `matlibre_sl_espace`

```
MATLIBRE_SL_ESPACE Les espaces de travail des modèles de la session.
  HWS = MATLIBRE_SL_ESPACE('lire',NOM) rend le Simulink.ModelWorkspace
  du modèle NOM, créé vide la première fois ; OUI =
  MATLIBRE_SL_ESPACE('existe',NOM) dit s'il y en a un ;
  MATLIBRE_SL_ESPACE('oublier',NOM) le retire — un modèle neuf part
  d'un espace vide.

  [NOMS,VALEURS] = MATLIBRE_SL_ESPACE('variables',CHEMIN) rend les
  variables de l'espace du modèle dont CHEMIN — « modele/bloc » — est
  un bloc : ce que les paramètres de ses blocs lisent avant l'espace de
  travail de base.

  D = MATLIBRE_SL_ESPACE('executer',D,CODE,NOM) exécute CODE dans un
  espace où les champs de la structure D sont des variables, et rend
  les variables qu'il y laisse.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     hws = matlibre_sl_espace('lire', 'essaiEspace');
     assignin(hws, 'K', 2);
     [noms, valeurs] = matlibre_sl_espace('variables', 'essaiEspace/gain');
     matlibre_sl_espace('oublier', 'essaiEspace');

  Voir aussi SIMULINK.MODELWORKSPACE, GET_PARAM.
```

## `matlibre_sl_etats`

```
MATLIBRE_SL_ETATS Recense les états continus, les entrées et les sorties.
  [BLOCS,RANGS,ENTREES,SORTIES] = MATLIBRE_SL_ETATS(MODELE) rend, pour
  chaque bloc à état continu, son rang dans le modèle déplié (BLOCS) et
  le rang des composantes d'état qu'il porte dans le vecteur global
  (RANGS, une cellule par bloc). ENTREES et SORTIES rendent les rangs
  des blocs INPORT et OUTPORT, classés par leur paramètre Port.
  [...,T] = MATLIBRE_SL_ETATS(MODELE) rend aussi le modèle compilé et
  préparé, que MATLIBRE_SL_DERIVEE évalue sans le recompiler.

  Portent un état continu l'intégrateur, la représentation d'état, la
  fonction de transfert, le zéro-pôle et le PID — deux états par voie
  pour ce dernier : son intégrale et le filtre de sa dérivée.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('chaine');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 'x');
     m = add_line(m, 'x', 'y');
     [b, r] = matlibre_sl_etats(m);
     numel(b)                          % 1 : un seul etat

  Voir aussi LINMOD, DLINMOD, TRIM, SIM.
```

## `matlibre_sl_etiquette`

```
MATLIBRE_SL_ETIQUETTE Ce qui s'écrit dans un bloc.
  TEXTE = MATLIBRE_SL_ETIQUETTE(BLOC) rend ce que le bloc affiche : sa
  valeur pour une constante, son gain pour un gain, sa transmittance
  pour un intégrateur ou un retard.

  C'est le réglage qui s'écrit, non le type : « 1/s » dit plus qu'
  « integrator », et un gain de 2 se lit d'un coup d'œil là où il
  faudrait sinon ouvrir le bloc.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_etiquette(struct('type', 'integrator', 'parametres', struct()))

  Voir aussi MATLIBRE_SL_FORME, OPEN_SYSTEM, GET_PARAM.
```

## `matlibre_sl_executer`

```
MATLIBRE_SL_EXECUTER Fait tourner un modèle compilé.
  T = MATLIBRE_SL_EXECUTER('preparer',C) range le modèle C, compilé par
  MATLIBRE_SL_COMPILER, en tableaux de nombres : ce que chaque pas lit
  sans avoir rien à chercher.

  J = MATLIBRE_SL_EXECUTER('simuler',T,INSTANTS,SOLVEUR) simule aux
  INSTANTS, régulièrement espacés du pas de la compilation, avec le
  solveur à pas fixe SOLVEUR : ode1 (Euler), ode2 (Heun), ode3
  (Bogacki-Shampine), ode4 (Runge-Kutta), ode5 (Dormand-Prince), ode8
  (Prince-Dormand, d'ordre huit), ou, pour les systèmes raides, ode1be
  (Euler implicite) et ode14x (Euler implicite extrapolé). J
  porte le relevé — une colonne par instant, une ligne par valeur
  relevée, dans l'ordre de T.releves —, les états continus, et le rang
  du dernier instant simulé, qu'un bloc Stop Simulation peut avancer.

  J = MATLIBRE_SL_EXECUTER('simulerVariable',T,TDEBUT,TFINAL,SOLVEUR,
  REGLAGES,IMPOSES) simule à pas variable, pour un modèle compilé avec
  l'option variable : ode45 (Dormand-Prince 5(4)), ode23
  (Bogacki-Shampine 3(2)), ode113 (Adams, d'ordre 1 à 12), et pour les
  systèmes raides ode15s (NDF, d'ordre 1 à MaxOrder), daessc (BDF,
  d'ordre 1 à MaxOrder), ode23s (Rosenbrock), ode23t (trapèzes) et
  ode23tb (TR-BDF2) ; ou
  VariableStepDiscrete. Le pas suit les tolérances RelTol et
  AbsTol de REGLAGES, borné par MaxStep et MinStep ; il s'arrête sur
  chaque instant d'échantillonnage, chaque cassure d'une source
  (échelon, front d'impulsion) et chaque passage par zéro, localisé
  dans le pas. IMPOSES, s'il n'est pas vide, donne les seuls instants
  relevés, que le solveur atteint exactement. J porte en plus le champ
  temps, les instants relevés.

  [Y,DX] = MATLIBRE_SL_EXECUTER('point',T,X,U) évalue le modèle en un
  point : états continus X, entrées U des blocs INPORT dans l'ordre de
  leur paramètre Port. Y rend les sorties — ce qui arrive aux blocs
  OUTPORT —, DX la dérivée des états. C'est ce que LINMOD et TRIM
  perturbent.

  Chaque pas se fait comme dans Simulink. Une passe de sortie d'abord,
  où chaque bloc calcule sa sortie dans l'ordre que la compilation a
  fixé ; une boucle algébrique y est résolue par la méthode de Newton,
  son jacobien gardé d'un pas à l'autre. Puis les dérivées des états
  continus, la mise à jour des états discrets, et l'intégration. Un
  solveur d'ordre supérieur refait des passes de sortie en des points
  intermédiaires du pas : ce sont les pas mineurs, où les blocs
  échantillonnés, et ceux qui comparent leur entrée à celle du pas
  précédent, gardent la valeur du pas majeur.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('m'), 'constant', 'c', 'Value', 2);
     m = add_line(add_block(m, 'integrator', 'x'), 'c', 'x');
     T = matlibre_sl_executer('preparer', matlibre_sl_compiler(m, ...
                              struct('pas', 0.1, 'silencieux', true)));
     J = matlibre_sl_executer('simuler', T, 0:0.1:1, 'ode1');
     J.etats(end)                           % 2 : l'intégrale de 2 sur 1 s

  Voir aussi SIM, MATLIBRE_SL_COMPILER, LINMOD.
```

## `matlibre_sl_expression`

```
MATLIBRE_SL_EXPRESSION Évalue un paramètre de bloc donné par une expression.
  V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE) évalue TEXTE dans
  l'espace de travail de base et rend sa valeur numérique, en double.
  V = MATLIBRE_SL_EXPRESSION(TEXTE,BLOC,PARAMETRE,'classe') la rend dans
  sa classe : 'int8(5)' reste un int8, que la propagation des types lit.

  C'est ainsi qu'un modèle et l'espace de travail partagent leurs
  variables : un gain réglé à 'K' vaut ce que vaut K au moment où l'on
  simule, non ce qu'il valait quand on a posé le bloc. Changer K et
  relancer SIM suffit ; le modèle, lui, ne bouge pas.

  Les variables de l'espace de travail du modèle — celui du modèle dont
  BLOC est un bloc, « modele/bloc » — passent avant celles de base.

  Une variable qui porte un SIMULINK.PARAMETER y vaut la valeur de
  l'objet, convertie dans son DataType et vérifiée contre ses bornes
  Min et Max : '2*K' se calcule avec la valeur de K, comme dans
  Simulink.

  L'espace consulté est celui de base, comme dans Simulink : un modèle
  ne voit pas les variables locales de la fonction qui le simule.

  Une expression qui ne s'évalue pas, ou qui ne rend pas un nombre, est
  refusée en nommant le bloc et le paramètre — sans quoi on chercherait
  longtemps d'où vient un résultat faux.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     assignin('base', 'K', 3);
     matlibre_sl_expression('2 * K', 'gain', 'Gain')      % 6

  Voir aussi SIM, ADD_BLOCK, SET_PARAM, EVALIN, SIMULINK.PARAMETER.
Les objets paramètres que nomme l'expression : chacun est remplacé
par sa valeur. Sans eux, l'évaluation se fait telle quelle dans
l'espace de base.
```

## `matlibre_sl_fautif`

```
MATLIBRE_SL_FAUTIF L'erreur de Simulink qui nomme un bloc et son paramètre fautif.
  EX = MATLIBRE_SL_FAUTIF(ERR,TYPE,PARAMETRES,CHEMIN) rend l'exception
  Simulink:Parameters:InvParamSetting pour ERR, une erreur imprévue
  tombée pendant que le bloc CHEMIN — de type TYPE, de paramètres
  PARAMETRES — se compilait ou se calculait. C'est presque toujours la
  valeur d'un paramètre que le bloc ne sait pas employer : l'exception
  nomme le bloc par son chemin, et, parmi ses paramètres, ceux dont la
  valeur s'écarte de la forme de leur valeur par défaut — vide, NaN,
  complexe, une matrice là où il faut un scalaire, un nombre négatif là
  où il faut un compte. Le message d'origine suit, en détail.

  MATLIBRE_SL_COMPILER et SIM s'en servent : l'un sait quel bloc il
  compile, l'autre rejoue la simulation pour savoir lequel calculait.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     err = MException('MATLAB:badsubscript', 'Index exceeds...');
     ex = matlibre_sl_fautif(err, 'gain', struct('Gain', []), 'm/g');
     ex.identifier                 % 'Simulink:Parameters:InvParamSetting'

  Voir aussi SIM, MATLIBRE_SL_COMPILER, MATLIBRE_SL_CATALOGUE.
```

## `matlibre_sl_fil`

```
MATLIBRE_SL_FIL Trace une liaison entre deux blocs, à angles droits.
  MATLIBRE_SL_FIL(DEPART,ARRIVEE) relie le point DEPART au point
  ARRIVEE par des segments horizontaux et verticaux, et pose une
  pointe de flèche à l'arrivée.

  MATLIBRE_SL_FIL(DEPART,ARRIVEE,true,BAS) trace un retour de boucle :
  la liaison descend sous le schéma, à la hauteur BAS, revient vers la
  gauche, puis remonte. Tracée en ligne droite, elle passerait au
  travers des blocs qu'elle enjambe.

  Le contournement sert aussi quand la cible n'est pas devant la
  source, retour ou non : un bloc déplacé à la souris peut se retrouver
  derrière celui qui l'alimente, et une liaison directe reviendrait
  alors sur ses pas, la pointe de flèche pointant à l'envers.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_fil([0 0], [3 1]);

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FORME.
```

## `matlibre_sl_fonction`

```
MATLIBRE_SL_FONCTION Les blocs de code : Fcn, MATLAB Function, S-Function.
  H = MATLIBRE_SL_FONCTION('expression',TEXTE,CHEMIN) rend la poignée
  @(u) TEXTE d'un bloc Fcn ou Interpreted MATLAB Function. Elle est
  créée dans l'espace de travail de base : les variables qu'elle nomme y
  sont prises au moment de la compilation, comme dans Simulink.
  L'écriture ancienne u[2] vaut u(2). Un nom de fonction seul — « sin »
  — donne la fonction appliquée à u.

  [NE,NS,ENTREES,SORTIES] = MATLIBRE_SL_FONCTION('signature',SCRIPT)
  lit la ligne « function [y1,y2] = f(u,v) » du texte d'un bloc MATLAB
  Function : ses arguments sont les entrées du bloc, ses sorties les
  sorties.

  H = MATLIBRE_SL_FONCTION('installer',SCRIPT,CHEMIN) écrit le texte
  dans un fichier de fonction, sous un nom tiré du texte — et du chemin
  du bloc quand la fonction a des variables persistantes : deux blocs
  au même texte ne partagent pas leur mémoire, comme dans Simulink —,
  dans un dossier de la session mis sur le chemin, et rend la poignée
  de la fonction. Ses variables persistantes sont remises à zéro.

  [TAILLES,X0,TS] = MATLIBRE_SL_FONCTION('sfonction',F,PARAMETRES,
  CHEMIN) interroge une S-fonction de niveau 1, [sys,x0,str,ts] =
  f(t,x,u,flag,p1,p2,...), par le drapeau 0 : TAILLES porte le nombre
  d'états continus et discrets, de sorties et d'entrées, la transmission
  directe, et TS la période.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     h = matlibre_sl_fonction('expression', 'u(1)^2 + u[2]', 'm/f');
     h([3; 1])                              % 10
     [ne, ns] = matlibre_sl_fonction('signature', ...
                sprintf('function [a, b] = f(x, y, z)\na = x; b = y + z;'))

  Voir aussi ADD_BLOCK, SIM.
```

## `matlibre_sl_forme`

```
MATLIBRE_SL_FORME Dessine un bloc, selon ce qu'il fait.
  MATLIBRE_SL_FORME(BLOC,X,Y,L,H) trace le bloc centré en (X,Y).

  La forme dit la fonction avant que le texte ne la nomme : un gain est
  un triangle, une sommation un cercle, une source porte l'allure de
  son signal. C'est la convention des schémas-blocs, et elle se lit
  plus vite qu'une liste de rectangles étiquetés.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_forme(struct('type', 'gain', 'nom', 'k', ...
                              'parametres', struct('Gain', 3)), 0, 0, 1.7, 1);

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_FIL.
```

## `matlibre_sl_geometrie`

```
MATLIBRE_SL_GEOMETRIE Où se place chaque bloc, et par où passe chaque lien.
  G = MATLIBRE_SL_GEOMETRIE(MODELE) rend une structure décrivant le
  schéma : pour chaque bloc son nom, son type, son étiquette, ses signes
  et son cadre ; pour chaque lien ses deux bouts, son port d'arrivée et
  s'il referme une boucle.

  C'est la géométrie que partagent les deux façons de montrer un
  schéma : OPEN_SYSTEM la trace dans une figure, l'éditeur du bureau la
  peint sur sa toile et s'en sert pour savoir où l'on a cliqué. Une
  seule mise en place, donc, et deux dessins qui s'accordent.

  Un bloc qui porte un paramètre POSITION garde la place qu'on lui a
  donnée — c'est ainsi qu'un schéma déplacé à la souris se retient.
  POSITION vaut [gauche haut droite bas], comme dans Simulink. Les
  autres sont placés par couches, de la source vers la sortie.

  Les champs rendus :
    G.blocs(k).nom, .type, .etiquette, .signes
    G.blocs(k).noms, .valeurs                  ses réglages, en texte
    G.blocs(k).parametres, .defauts, .choix    tous ceux que le type
                                               accepte, avec leur valeur
                                               et leurs choix « a|b|c »
    G.blocs(k).entrees, .sorties               son nombre de ports
    G.blocs(k).physG, .physD                   ses ports physiques (Simscape),
                                               à gauche et à droite
    G.blocs(k).gauche, .haut, .droite, .bas    le cadre du bloc
    G.blocs(k).pose                            vrai si POSITION le fixait
    G.blocs(k).masque                          vrai pour un sous-système
                                               masqué : ses paramètres sont
                                               les variables du masque
    G.liens(k).source, .cible, .port, .sortie, .retour
    G.liens(k).nom, .journal                  le nom du signal, et s'il
                                               est journalisé
    G.connexions(k).a, .pa, .b, .pb           une connexion physique : deux
                                               blocs et leurs ports, +i pour
                                               LConn i, -i pour RConn i
    G.largeur, G.hauteur                       la taille d'un bloc par défaut
    G.configuration                            les réglages de simulation,
                                               en texte
    G.solveurs.fixe, .variable                 les solveurs disponibles

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     g = matlibre_sl_geometrie(m);
     g.blocs(2).gauche > g.blocs(1).gauche      % le gain est a droite

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION, MATLIBRE_SL_RANGS.
```

## `matlibre_sl_hasard`

```
MATLIBRE_SL_HASARD Le tirage suivant des blocs de nombres au hasard.
  [V,E] = MATLIBRE_SL_HASARD(E,GAUSSIEN,UN,DEUX) avance d'un tirage
  l'état E de chaque élément et rend la valeur tirée. Pour un bruit
  gaussien (GAUSSIEN vrai), UN est la moyenne et DEUX la variance ; pour
  un bruit uniforme, UN est le minimum et DEUX le maximum.

  Le générateur est celui de Park et Miller, x <- 16807 x modulo
  2^31 - 1, et la gaussienne vient de deux tirages par la méthode de
  Box et Muller. C'est un générateur que chacun peut refaire : la même
  graine donne la même suite, d'une simulation à l'autre et d'une
  machine à l'autre. Il ne reproduit pas les suites de Simulink, dont
  l'algorithme n'est pas documenté.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [v, e] = matlibre_sl_hasard(1, false, 0, 1);
     v                                   % 16807 / (2^31 - 1)

  Voir aussi SIM, MATLIBRE_SL_EXECUTER.
```

## `matlibre_sl_indice`

```
MATLIBRE_SL_INDICE Rang d'un bloc désigné par son nom.
  K = MATLIBRE_SL_INDICE(MODELE,NOM) rend le rang du bloc dans
  MODELE.blocs, et lève une erreur qui nomme le bloc s'il n'existe pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     matlibre_sl_indice(m, 'g')       % 1

  Voir aussi ADD_LINE, DELETE_BLOCK, GET_PARAM.
```

## `matlibre_sl_instant`

```
MATLIBRE_SL_INSTANT L'instant de la simulation, pour le code d'un bloc.
  [T,TS] = MATLIBRE_SL_INSTANT() rend l'instant où calcule le bloc
  MATLAB Function qui l'appelle, et la période d'échantillonnage de ce
  bloc : sa période s'il en a une, héritée ou donnée ; 0 s'il est
  continu. Hors d'une simulation, T et TS valent ce qu'ils valaient au
  dernier appel, 0 au départ.

  MATLIBRE_SL_INSTANT(T,TS) les règle : SIM le fait avant d'appeler la
  fonction d'un bloc qui s'en sert.

  [T,TS,ESSAI] = MATLIBRE_SL_INSTANT() dit aussi si la fonction est
  appelée pour de bon ou essayée par la compilation sur des entrées
  nulles, pour connaître ses dimensions : un bloc ne signale pas alors
  ce que ces entrées ont de faux. MATLIBRE_SL_INSTANT('essai',VRAI) le
  règle. Les blocs de la bibliothèque que
  MatLibre écrit en MATLAB Function — le PID discret, l'intégrateur
  discret borné, les retards variables — y lisent leur pas.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_instant(0.5, 0.1);
     [t, Ts] = matlibre_sl_instant()          % 0.5 et 0.1

  Voir aussi SIM, ADD_BLOCK.
```

## `matlibre_sl_jeux`

```
MATLIBRE_SL_JEUX Les jeux de configuration d'un modèle.
  Un modèle porte un jeu de configuration actif — ses réglages, ceux
  que SET_PARAM pose et que SIM applique — et, à côté, ceux qu'on lui a
  attachés. Les réglages du jeu actif vivent dans MODELE.parametres ;
  les autres attendent dans MODELE.jeux, avec le nom de l'actif.

  NOMS = MATLIBRE_SL_JEUX('noms',MODELE)        tous les jeux, l'actif d'abord
  NOM = MATLIBRE_SL_JEUX('actif',MODELE)        le nom du jeu actif
  J = MATLIBRE_SL_JEUX('lire',MODELE,NOM)       un jeu : Name, Description, Reglages
  MODELE = MATLIBRE_SL_JEUX('attacher',MODELE,J,RENOMMER)
  MODELE = MATLIBRE_SL_JEUX('activer',MODELE,NOM)
  MODELE = MATLIBRE_SL_JEUX('detacher',MODELE,NOM)
  MODELE = MATLIBRE_SL_JEUX('regler',MODELE,NOM,COUPLES)   les réglages d'un jeu
  MODELE = MATLIBRE_SL_JEUX('nommer',MODELE,NOM,NOUVEAU,DESCRIPTION)

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     matlibre_sl_jeux('noms', m)                % {'Configuration'}
     j = struct('Name', 'Rapide', 'Description', '', ...
                'Reglages', struct('StopTime', 1));
     m = matlibre_sl_jeux('attacher', m, j, false);
     m = matlibre_sl_jeux('activer', m, 'Rapide');
     get_param(m, 'StopTime')                   % 1

  Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, SETACTIVECONFIGSET.
```

## `matlibre_sl_liens`

```
MATLIBRE_SL_LIENS Les liens d'un modèle, sous leur forme à quatre colonnes.
  L = MATLIBRE_SL_LIENS(MODELE) rend la table des liens, une ligne par
  lien : [bloc source, bloc cible, port d'entrée de la cible, port de
  sortie de la source]. Les blocs sont désignés par leur rang.

  Les modèles écrits avant que les blocs n'aient plusieurs sorties ont
  une table à trois colonnes : leur port de sortie est le premier, et
  c'est ce que cette fonction complète. Tout ce qui lit les liens passe
  par elle, si bien qu'un modèle ancien se lit comme un neuf.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('m'), 'constant', 'c');
     m = add_block(m, 'gain', 'k');
     m = add_line(m, 'c', 'k');
     matlibre_sl_liens(m)          % [1 2 1 1]

  Voir aussi ADD_LINE, DELETE_LINE.
```

## `matlibre_sl_lot`

```
MATLIBRE_SL_LOT Fait les simulations que décrivent des SimulationInput.
  OUT = MATLIBRE_SL_LOT('sim',IN,MODELES,...) est ce que fait SIM(IN) ;
  OUT = MATLIBRE_SL_LOT('parsim',IN,MODELES,...) ce que fait PARSIM(IN).
  MODELES{K} est le modèle de IN(K) quand l'appelant l'a trouvé — une
  variable de son espace qui porte le nom du modèle —, vide sinon : le
  modèle est alors celui que le SimulationInput porte, ou celui d'un
  modèle ouvert, d'une variable de base ou d'un fichier de ce nom.
  MATLIBRE_SL_LOT('valider',IN,{[]}) vérifie sans simuler.

  Pour chaque simulation : PreSimFcn, puis les réglages et les
  paramètres de blocs posés sur une copie du modèle, les variables
  posées dans l'espace de travail de base, la simulation, l'espace de
  base rendu tel qu'il était, et PostSimFcn. Une erreur est rangée dans
  ErrorMessage — sauf pour SIM d'un seul SimulationInput sans
  'CaptureErrors' à 'on', où elle part comme celle de SIM.

  Options de 'sim' : CaptureErrors, StopOnError, ShowProgress ('off').
  Options de 'parsim' : ShowProgress ('on'), StopOnError, SetupFcn,
  CleanupFcn ; TransferBaseWorkspaceVariables, UseFastRestart,
  ShowSimulationManager, AttachedFiles, ManageDependencies sont admises
  sans effet — tout se passe dans la même session.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('m'), 'constant', 'c', 'Value', 'K');
     m = add_line(add_block(m, 'outport', 'y'), 'c', 'y');
     in = Simulink.SimulationInput(m);
     in = in.setVariable('K', 7);
     out = matlibre_sl_lot('sim', in, {[]});
     out.yout(end)                      % 7

  Voir aussi SIM, PARSIM, SIMULINK.SIMULATIONINPUT.
```

## `matlibre_sl_masque`

```
MATLIBRE_SL_MASQUE Les masques des sous-systèmes : leurs paramètres, leur espace.
  Un sous-système masqué montre des paramètres à lui, comme un bloc de
  la bibliothèque : ses variables de masque. Les blocs qu'il contient
  les nomment dans leurs propres paramètres — un gain réglé sur 'K' —,
  et c'est la valeur du masque qui vaut, avant l'espace de travail.

  Le masque se décrit comme dans Simulink, par les paramètres du bloc :
  Mask ('on'), MaskVariables ('K=@1;nom=&2;' : la variable K prend la
  première valeur, évaluée ; nom la deuxième, telle quelle),
  MaskValueString (les valeurs, séparées par « | ») et MaskPrompts
  (les libellés que la boîte de dialogue montre).

  NOMS = MATLIBRE_SL_MASQUE('variables',BLOC) rend les noms des
  variables du masque, cellule vide si le bloc n'est pas masqué.
  V = MATLIBRE_SL_MASQUE('lire',BLOC,NOM) rend la valeur, en texte, de
  la variable NOM ; BLOC = MATLIBRE_SL_MASQUE('poser',BLOC,NOM,V) la
  change.
  W = MATLIBRE_SL_MASQUE('espace',BLOC,PARENT,CHEMIN) évalue les
  variables du masque dans l'espace PARENT — celui du masque qui
  l'englobe, ou l'espace de travail — et rend la structure qui les
  porte.
  V = MATLIBRE_SL_MASQUE('evaluer',TEXTE,ESPACE,CHEMIN,NOM) évalue une
  expression : les variables du masque d'abord, puis celles de l'espace
  de travail.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     b = struct('type', 'subsystem', 'nom', 's', 'parametres', ...
                struct('Mask', 'on', 'MaskVariables', 'K=@1;tau=@2;', ...
                       'MaskValueString', '2|0.5'));
     matlibre_sl_masque('lire', b, 'tau')                  % '0.5'
     W = matlibre_sl_masque('espace', b, struct(), 's');
     matlibre_sl_masque('evaluer', 'K / tau', W, 's/g', 'Gain')   % 4

  Voir aussi SET_PARAM, GET_PARAM, ADD_BLOCK.
```

## `matlibre_sl_modele`

```
MATLIBRE_SL_MODELE Rend un modèle, qu'on l'ait donné par valeur ou par nom.
  MODELE = MATLIBRE_SL_MODELE(ENTREE) accepte un modèle bâti par
  NEW_SYSTEM, ou le nom d'une variable de l'espace de travail de base
  qui en porte un, ou le nom d'un modèle ouvert dans la session, ou le
  nom d'un fichier .m qui le rend.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     nom = matlibre_sl_modele(m).nom;      % 'essai'

  Voir aussi LINMOD, TRIM, OPEN_SYSTEM, LOAD_SYSTEM, SIM.
```

## `matlibre_sl_msfonction`

```
MATLIBRE_SL_MSFONCTION Fait tourner une S-fonction de niveau 2.
  CODE = MATLIBRE_SL_MSFONCTION('preparer',NOM,PARAMETRES,CHEMIN) crée
  le bloc (un SIMULINK.MSFCNRUNTIMEBLOCK), y pose les paramètres —
  block.DialogPrm(i).Data —, et appelle la S-fonction NOM, qui appelle
  sa fonction setup : le bloc dit alors ses ports, sa période, ses
  états et ses méthodes.

  [NE,NS] = MATLIBRE_SL_MSFONCTION('ports',NOM,PARAMETRES,CHEMIN) rend
  le nombre de ses ports d'entrée et de sortie.

  DS = MATLIBRE_SL_MSFONCTION('dimensions',CODE,DE,CHEMIN) fixe les
  dimensions de ses ports, les dynamiques (-1) prenant celles des
  signaux DE qu'il reçoit — une sortie dynamique, celle de la première
  entrée —, et rend celles des sorties.

  X0 = MATLIBRE_SL_MSFONCTION('demarrer',CODE,CHEMIN) appelle
  PostPropagationSetup, InitializeConditions et Start, et rend l'état
  continu de départ.

  S = MATLIBRE_SL_MSFONCTION('sorties',CODE,T,U,X), DX =
  MATLIBRE_SL_MSFONCTION('derivees',CODE,T,U,X) et
  MATLIBRE_SL_MSFONCTION('maj',CODE,T,U,X) appellent Outputs,
  Derivatives et Update à l'instant T, les entrées U (une cellule, un
  vecteur par port) et l'état continu X posés sur le bloc.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     code = struct('bloc', Simulink.MSFcnRunTimeBlock);
     class(code.bloc)                  % 'Simulink.MSFcnRunTimeBlock'

  Voir aussi SIMULINK.MSFCNRUNTIMEBLOCK, ADD_BLOCK, SIM.
```

## `matlibre_sl_nomme`

```
MATLIBRE_SL_NOMME La forme de MATLAB : le modèle désigné par son nom.
  Dans MATLAB, un modèle est un objet de la session, qu'on désigne par
  son nom, un bloc par son chemin « modele/sousSysteme/bloc », et l'un
  comme l'autre par sa poignée :

     new_system('boucle');
     add_block('simulink/Sources/Step', 'boucle/echelon');
     set_param('boucle/echelon', 'Time', '2');

  Les fonctions de cette boîte travaillent sur une valeur, qu'elles
  prennent et rendent. Cette fonction fait le pont : elle lit le modèle
  au registre de la session (MATLIBRE_SL_OUVERTS), appelle la fonction
  par valeur sur le système que le chemin désigne, et range le résultat
  à sa place. Chaque fonction publique lui passe la main dès que son
  premier argument n'est pas un modèle.

  SORTIES = MATLIBRE_SL_NOMME(ACTION,NBSORTIES,ARGUMENTS...) : ACTION
  est le nom de la fonction publique — 'add_block', 'add_line',
  'delete_block', 'delete_line', 'set_param', 'get_param',
  'find_system', 'save_system', 'replace_block', 'add_param',
  'delete_param', 'getfullname', 'bdroot'.
  MATLIBRE_SL_NOMME('ranger',NOM,MODELE) inscrit un modèle en gardant sa
  figure ; MATLIBRE_SL_NOMME('systeme',OBJET) rend le nom du modèle et
  le chemin, dans ce modèle, de ce qu'un nom ou une poignée désigne ;
  [MODELE,NOM] = MATLIBRE_SL_NOMME('modele',OBJET) rend le modèle de la
  session qui porte l'objet ; MATLIBRE_SL_NOMME('reglage',NOM,V) rend la
  valeur d'un réglage de configuration comme Simulink la rend, en texte ;
  MATLIBRE_SL_NOMME('fichier',NOM,FICHIER) note que le modèle vient
  d'être lu de ce fichier ou d'y être écrit, et
  MATLIBRE_SL_NOMME('chemin',FICHIER) rend son chemin absolu.

  Trois choses distinguent cette forme de la forme par valeur, pour
  répondre comme Simulink : Position s'y dit en pixels — le modèle la
  range quarante fois plus petite, dans l'unité de sa mise en place — ;
  un bloc pris à la bibliothèque y prend les défauts de Simulink ; et
  la session tient pour chaque modèle Dirty et FileName.

  Les poignées sont celles de MATLIBRE_SL_SIGNAUX : un nombre par
  modèle, par bloc, par port et par ligne, le même tant que dure la
  session.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     bdclose('all');
     new_system('pont');
     add_block('simulink/Sources/Constant', 'pont/c', 'Value', '4');
     [racine, chemin] = matlibre_sl_nomme('systeme', 'pont/c')   % 'pont', 'c'
     bdclose('all');

  Voir aussi NEW_SYSTEM, ADD_BLOCK, SET_PARAM, GET_PARAM, FIND_SYSTEM.
```

## `matlibre_sl_ordre`

```
MATLIBRE_SL_ORDRE L'ordre dans lequel les blocs se calculent.
  [ORDRE,DIRECTE,MEMOIRE] = MATLIBRE_SL_ORDRE(MODELE) rend l'ordre de
  calcul des blocs, et pour chacun s'il transmet son entrée à l'instant
  même et s'il porte un état.

  Un bloc à transmission directe se calcule après ce qui l'alimente.
  Un bloc qui n'en a pas — intégrateur, retard, mémoire, et une
  représentation d'état dont D est nul — rend une valeur qui ne dépend
  que de son état : il peut donc être placé le premier, et c'est ce qui
  casse les boucles.

  C'est la même règle que celle de SIM. Elle est ici pour que le
  programme engendré par MATLIBRE_SL_PROGRAMME calcule dans le même
  ordre — sans quoi il rendrait d'autres nombres que la simulation.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_line(m, 'u', 'k');
     matlibre_sl_ordre(m)             % [2 1] : la source avant le gain

  Voir aussi SIM, MATLIBRE_SL_PROGRAMME.
```

## `matlibre_sl_ouverts`

```
MATLIBRE_SL_OUVERTS Registre des modèles ouverts dans la session.
  Un modèle est ici une valeur, non une fenêtre. « Ouvert » veut donc
  dire « connu de la session » : OPEN_SYSTEM et LOAD_SYSTEM y
  inscrivent le modèle, CLOSE_SYSTEM et BDCLOSE l'en retirent, GCS rend
  le dernier inscrit, et BDISLOADED répond sur un nom.

  L'inscription retient aussi le numéro de la figure où le schéma est
  tracé, quand il y en a une, pour que CLOSE_SYSTEM sache laquelle
  fermer.

  Elle retient enfin ce que la session sait du modèle sans que ce soit
  le modèle : le fichier d'où il vient ou vers lequel on l'a enregistré
  (FileName), et s'il a changé depuis (Dirty). 'info' rend ces deux
  champs, 'noter' en règle : MATLIBRE_SL_OUVERTS('noter',NOM,S) pose
  les champs de la structure S.

  Actions : 'inscrire', 'retirer', 'vider', 'lire', 'figure', 'connu',
  'noms', 'dernier', 'info', 'noter'.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_ouverts('vider');
     matlibre_sl_ouverts('inscrire', 'essai', new_system('essai'));
     matlibre_sl_ouverts('dernier')          % 'essai'
     matlibre_sl_ouverts('vider');

  Voir aussi OPEN_SYSTEM, CLOSE_SYSTEM, GCS, BDISLOADED, LOAD_SYSTEM.
```

## `matlibre_sl_parametre`

```
MATLIBRE_SL_PARAMETRE Ce que valent les objets Simulink.Parameter.
  V = MATLIBRE_SL_PARAMETRE('valeur',P,VARIABLE,BLOC,PARAMETRE) rend la
  valeur que lit un bloc dont le paramètre PARAMETRE nomme la variable
  VARIABLE, qui porte le Simulink.Parameter P : sa valeur, convertie
  dans son DataType quand il n'est pas 'auto', et vérifiée contre ses
  bornes Min et Max. Une valeur qui en sort, qui déborde son type
  entier, ou un type que MatLibre n'a pas, arrête tout par une erreur
  qui nomme le bloc, le paramètre et la variable.

  L = MATLIBRE_SL_PARAMETRE('types') rend les noms de types que
  Simulink.Parameter et Simulink.Signal convertissent : 'auto',
  'double', 'single', les entiers, 'boolean'.

  B = MATLIBRE_SL_PARAMETRE('borne',V,NOM), T =
  MATLIBRE_SL_PARAMETRE('texte',V,NOM) et C =
  MATLIBRE_SL_PARAMETRE('choix',V,NOM,ADMIS) vérifient une propriété
  avant qu'un objet la pose.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     K = Simulink.Parameter(300);
     K.DataType = 'int16';
     v = matlibre_sl_parametre('valeur', K, 'K', 'm/c', 'Value');
     class(v)                           % 'int16'

  Voir aussi SIMULINK.PARAMETER, SIMULINK.SIGNAL, MATLIBRE_SL_EXPRESSION.
```

## `matlibre_sl_physique`

```
MATLIBRE_SL_PHYSIQUE Les réseaux physiques de Simscape dans un schéma.
  [G,D,E,S] = MATLIBRE_SL_PHYSIQUE('ports',TYPE) rend les ports d'un
  bloc physique : G ports physiques à gauche (LConn), D à droite (RConn),
  E entrées et S sorties de signal. Un type qui n'est pas physique rend
  des zéros, et OUI = MATLIBRE_SL_PHYSIQUE('est',TYPE) le dit.
  DOM = MATLIBRE_SL_PHYSIQUE('domaine',TYPE,CODE) rend le domaine d'un
  port physique : 'electrique', 'translation', 'rotation' ou 'thermique'
  ('' pour le Solver Configuration, qui se relie à tous).

  MODELE = MATLIBRE_SL_PHYSIQUE('reseaux',MODELE) remplace chaque réseau
  physique d'un modèle déplié par des blocs ordinaires. Les connexions
  physiques (MODELE.connexions, une ligne [bloc, port, bloc, port], un
  port +i pour LConn i, -i pour RConn i) font les nœuds ; les nœuds et
  les blocs qu'ils relient font les réseaux. Chaque réseau doit avoir
  un bloc Solver Configuration, et une référence dans chacun de ses
  domaines — Electrical Reference, Mechanical Translational Reference,
  Mechanical Rotational Reference, Thermal Reference.

  Un réseau s'écrit par l'analyse nodale modifiée, la même dans tous les
  domaines : une grandeur « à travers » — tension, vitesse, vitesse
  angulaire, température — par nœud, une grandeur « traversante » —
  courant, force, couple, flux de chaleur — par branche. Une masse, une
  inertie, une masse thermique sont des condensateurs vers la référence ;
  un ressort une bobine ; un amortisseur, une paroi des conductances ;
  une source de force ou de couple une source de courant.
  Le convertisseur électromécanique lie les deux domaines : v = K w,
  couple = K i ; le transformateur idéal, le réducteur, la roue et
  l'essieu lient de même deux grandeurs à travers et deux efforts.
  L'amplificateur opérationnel idéal égale ses deux entrées sans y
  laisser passer de courant. Ses états sont les tensions des condensateurs, les
  vitesses des masses et des inerties, les températures des masses
  thermiques, les courants des bobines, les
  efforts des ressorts, et la position que mesure chaque capteur de
  mouvement. Le réseau étant linéaire, il devient une représentation
  d'état : le bloc Solver Configuration devient un bloc State-Space, que
  tous les solveurs intègrent et que LINMOD linéarise.

  Des éléments à état solidaires — deux inerties sur un même arbre, deux
  masses thermiques sur un même nœud, un ressort au bout libre, un
  enroulement ouvert — n'ont pas d'états indépendants : les équations
  algébriques du réseau sont alors singulières, et le système
  algébro-différentiel se réduit, contrainte après contrainte, aux
  combinaisons d'états qu'il laisse libres. Une source qui impose l'état
  d'un élément (une source de vitesse sur une masse) demande la dérivée
  de sa commande : le Simulink-PS Converter la fournit en filtrant son
  entrée (FilteringAndDerivatives), ou la dit nulle (constante par
  morceaux). Les convertisseurs lisent l'unité de leur signal (mA, rpm,
  degC...) et la ramènent aux unités SI dans lesquelles le réseau calcule.

  Conventions de Simscape : une grandeur traversante va du port de gauche
  (+, R) au port de droite (-, C) à travers le bloc ; une grandeur à
  travers est la différence gauche moins droite. Une source de force ou
  de couple positive agit de C vers R : elle pousse le port R. Une
  source de température impose T(B) - T(A), ses ports A et B étant à
  gauche et à droite ; les températures sont absolues.

  Les blocs de signaux physiques — PS Gain, PS Add, PS Subtract, PS
  Product, PS Divide, PS Abs, PS Sign, PS Ceil, PS Floor, PS Round, PS
  Fix, PS Max, PS Min, PS Constant, PS Math Function, PS Integrator, PS
  Saturation, PS Dead Zone, PS Switch, PS Constant Delay, PS Terminator,
  PS Lookup Table (1D) et (2D) —
  calculent sur des signaux, en unités SI : chacun devient le bloc de
  Simulink qui calcule la même chose. OUI = MATLIBRE_SL_PHYSIQUE(
  'estSignal',TYPE) les reconnaît, [NE,NS] = MATLIBRE_SL_PHYSIQUE(
  'portsSignal',TYPE,PARAMETRES) rend leurs entrées et leurs sorties.

  V = MATLIBRE_SL_PHYSIQUE('unite',V,UNITE,BASE,CHEMIN,NOM) ramène une
  valeur écrite dans une unité (kOhm, uF, mH, kHz, deg, rpm, g, mm...) à
  l'unité BASE du paramètre.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi ADD_LINE, MATLIBRE_SL_APLATIR.
```

## `matlibre_sl_pile`

```
MATLIBRE_SL_PILE Les états passés d'un modèle, pour défaire et refaire.
  MATLIBRE_SL_PILE('poser',MODELE) retient l'état courant du modèle
  avant qu'on le change.
  MODELE = MATLIBRE_SL_PILE('annuler',MODELE) rend l'état d'avant le
  dernier changement, et garde celui qu'on quitte pour pouvoir le
  refaire.
  MODELE = MATLIBRE_SL_PILE('refaire',MODELE) revient sur une annulation.
  MATLIBRE_SL_PILE('vider',MODELE) oublie tout d'un modèle.
  N = MATLIBRE_SL_PILE('profondeur',MODELE) dit combien d'annulations
  restent possibles, et 'refaisables' combien de rétablissements.

  Les états sont rangés par nom de modèle, et la pile vit aussi
  longtemps que la session. Un modèle est une valeur : en retenir une
  copie suffit, il n'y a pas de références à démêler.

  Poser un état efface ce qu'on pouvait refaire : c'est la règle de
  toute pile d'annulation, et l'ignorer laisserait rétablir un état qui
  n'a plus de suite.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  dont l'annulation n'existe que dans l'éditeur.

  Exemple :
     m = add_block(new_system('essai'), 'gain', 'k', 'Gain', 1);
     matlibre_sl_pile('vider', m);
     matlibre_sl_pile('poser', m);
     m = set_param(m, 'k', 'Gain', 5);
     m = matlibre_sl_pile('annuler', m);
     get_param(m, 'k', 'Gain')                % 1 : le changement est defait

  Voir aussi SET_PARAM, ADD_BLOCK, DELETE_BLOCK, OPEN_SYSTEM.
```

## `matlibre_sl_pointanalyse`

```
MATLIBRE_SL_POINTANALYSE Les points d'analyse de LINIO, et ce qu'ils font.
  [TYPE,OUVERTURE] = MATLIBRE_SL_POINTANALYSE('canon',TYPE,OUVERTURE)
  ramène un type de point — les noms d'aujourd'hui ('input',
  'openoutput', 'looptransfer'...) ou ceux d'hier ('in', 'out', 'inout',
  'outin', 'none') — et son ouverture ('on', 'off') à l'écriture que
  LINIO range : le type d'aujourd'hui, coupure comprise, et l'ouverture
  qui lui répond.

  ETAPES = MATLIBRE_SL_POINTANALYSE('etapes',TYPE,OUVERTURE) rend ce
  que LINEARIZE fait au signal, dans l'ordre : 'mesurer', 'couper',
  'ajouter'. Une liste vide : le point ne fait rien.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [t, o] = matlibre_sl_pointanalyse('canon', 'out', 'on')   % 'openoutput', 'on'
     matlibre_sl_pointanalyse('etapes', 'looptransfer', 'on')  % mesurer, couper, ajouter

  Voir aussi LINIO, LINEARIZE.
```

## `matlibre_sl_pointe`

```
MATLIBRE_SL_POINTE Pointe de flèche à l'entrée d'un bloc.
  MATLIBRE_SL_POINTE(ARRIVEE) pose un petit triangle plein pointant
  vers la droite au point donné.

  Sans elle, un schéma-bloc ne dit pas dans quel sens l'information
  circule — et c'est précisément ce qu'un schéma-bloc sert à dire.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     figure;
     matlibre_sl_pointe([1 1]);

  Voir aussi MATLIBRE_SL_FIL, OPEN_SYSTEM.
```

## `matlibre_sl_ports`

```
MATLIBRE_SL_PORTS Le nombre de ports d'entrée et de sortie d'un bloc.
  [NE,NS] = MATLIBRE_SL_PORTS(BLOC) rend le nombre de ports d'entrée et
  de sortie du bloc, tel que ses paramètres le fixent : une sommation a
  autant d'entrées que de signes, un Mux autant que son paramètre
  Inputs, un Demux autant de sorties que son paramètre Outputs, un
  sous-système autant d'entrées et de sorties que le modèle qu'il abrège
  porte de blocs INPORT et OUTPORT.

  [NE,NS] = MATLIBRE_SL_PORTS(BLOC,TYPE) prend le type canonique déjà
  résolu, ce qui épargne une recherche dans le catalogue.

  Un paramètre donné par une expression — « 'Inputs', 'n' » — ne se
  connaît qu'au moment de simuler : le nombre rendu est alors NaN, et
  c'est la compilation du modèle qui tranchera.

  ADD_LINE s'en sert pour refuser un port qui n'existe pas, la
  compilation pour valider le câblage, l'éditeur pour dessiner les ports.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     b = struct('type', 'sum', 'nom', 's', 'parametres', struct('Signs', '+-+'));
     [ne, ns] = matlibre_sl_ports(b)          % 3 et 1

  Voir aussi ADD_LINE, MATLIBRE_SL_CATALOGUE.
```

## `matlibre_sl_programme`

```
MATLIBRE_SL_PROGRAMME Écrit le programme .m qui simule un schéma-bloc.
  TEXTE = MATLIBRE_SL_PROGRAMME(MODELE) rend le texte d'une fonction
  MATLAB qui calcule ce que calcule le schéma, sans passer par
  Simulink : des variables, une boucle, de l'arithmétique.
  MATLIBRE_SL_PROGRAMME(MODELE,NOM) choisit le nom de la fonction.

  Ce n'est pas SAVE_SYSTEM. SAVE_SYSTEM écrit le programme qui
  *rebâtit* le modèle — NEW_SYSTEM, ADD_BLOCK, ADD_LINE —, et
  LOAD_SYSTEM le relit : c'est l'aller-retour du schéma. Ici, on écrit
  le programme qui *fait ce que le schéma fait*, et il n'y a pas de
  retour : on ne remonte pas d'un calcul quelconque au schéma qui
  l'aurait produit.

  Le programme rendu ne dépend de rien : les réglages y sont inscrits
  tels qu'ils valent au moment où on l'écrit. Un gain réglé sur « K »
  y devient la valeur de K, non la lettre — sans quoi le programme
  demanderait un espace de travail qu'il n'a pas. C'est ce que fait
  aussi le générateur de code de MathWorks.

  Le modèle est d'abord compilé comme pour SIM : l'ordre de calcul,
  les dimensions des signaux — scalaires ou vecteurs —, les paramètres
  sont ceux que SIM emploie, et chaque bloc s'écrit avec les formules
  mêmes du simulateur. Le programme rend donc les mêmes nombres, au bit
  près, que SIM avec le solveur ode1. C'est ce que vérifie le test.

  Ne s'écrivent pas encore, et sont refusés en les nommant plutôt que
  traduits de travers : les blocs échantillonnés à une autre période
  que le pas, le retard pur, les échanges avec l'espace de travail, les
  nombres au hasard, les signaux matrices, les boucles algébriques,
  les sous-systèmes conditionnels, et les solveurs autres qu'Euler.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
  dont le générateur de code écrit du C, non du MATLAB.

  Exemple :
     m = new_system('chute');
     m = add_block(m, 'constant', 'g', 'Value', -9.81);
     m = add_block(m, 'integrator', 'vitesse');
     m = add_line(m, 'g', 'vitesse');
     p = matlibre_sl_programme(m);
     ~isempty(strfind(p, 'function'))          % 1 : c'est une fonction

  Voir aussi SAVE_SYSTEM, LOAD_SYSTEM, SIM, MATLIBRE_SL_COMPILER.
```

## `matlibre_sl_proprietes`

```
MATLIBRE_SL_PROPRIETES Affiche un objet de Simulink comme MATLAB le fait.
  MATLIBRE_SL_PROPRIETES(OBJET,NOMS) écrit « Classe with properties: »
  puis, alignées à droite, les propriétés NOMS de l'objet avec leur
  valeur résumée : le texte entre apostrophes, un petit tableau en
  entier, les autres par leur taille et leur classe. Pour un tableau
  d'objets, seulement les noms. Les méthodes DISP de SIMULINK.PARAMETER,
  SIMULINK.SIGNAL et SIMULINK.SIMULATIONINPUT s'en servent.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     K = Simulink.Parameter(2);
     matlibre_sl_proprietes(K, {'Value', 'DataType'})

  Voir aussi SIMULINK.PARAMETER, DISP.
```

## `matlibre_sl_prototype`

```
MATLIBRE_SL_PROTOTYPE Les arguments d'un prototype de Simulink Function.
  [SORTIES,NOM,ENTREES] = MATLIBRE_SL_PROTOTYPE(TEXTE) lit un prototype
  comme l'écrit un Function Caller — « y = f(u) », « [s, d] = sd(a, b) »,
  « f(u) », « y = f() », « y = A.f(u) » pour une fonction d'un
  sous-système — et rend les noms des arguments de sortie, le nom de la
  fonction (qualifié s'il l'est) et ceux des arguments d'entrée, en
  cellules. Un texte qui n'est pas un prototype rend NOM vide.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [s, f, e] = matlibre_sl_prototype('[s, d] = sd(a, b)')
     % s = {'s', 'd'}, f = 'sd', e = {'a', 'b'}

  Voir aussi ADD_BLOCK.
```

## `matlibre_sl_rangs`

```
MATLIBRE_SL_RANGS Range les blocs en couches, de la source vers la sortie.
  [RANGS,RETOURS] = MATLIBRE_SL_RANGS(MODELE) rend le numéro de couche
  de chaque bloc et la liste des liens de rebouclage.

  Un schéma bouclé n'a pas d'ordre : le rangement se fait sur la partie
  sans circuit, et les liens qui referment une boucle sont mis à part
  pour être tracés en retour. C'est ce qui donne au schéma sa lecture
  de gauche à droite, la contre-réaction passant par-dessous.

  Le rang d'un bloc est la longueur du plus long chemin qui y mène :
  prendre le plus court tasserait les blocs contre leur source et
  ferait se croiser les liaisons.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('c');
     m = add_block(m, 'constant', 'u', 'Value', 1);
     m = add_block(m, 'gain', 'k', 'Gain', 2);
     m = add_line(m, 'u', 'k');
     matlibre_sl_rangs(m)            % [0 1]

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
```

## `matlibre_sl_rappel`

```
MATLIBRE_SL_RAPPEL Exécute un rappel du modèle : InitFcn, StopFcn...
  MATLIBRE_SL_RAPPEL(MODELE,NOM) évalue dans l'espace de travail de base
  le code que le modèle porte dans son réglage NOM, s'il en porte un.
  Ce sont les rappels de Simulink : PreLoadFcn et PostLoadFcn quand le
  modèle se charge, InitFcn avant qu'il se compile — les variables
  qu'il définit servent à ses blocs —, StartFcn quand la simulation
  commence, StopFcn quand elle s'achève, PreSaveFcn et PostSaveFcn
  autour d'un enregistrement, CloseFcn à la fermeture.

  Une erreur dans le rappel est rendue en le nommant, avec le modèle.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = set_param(new_system('rappels'), 'InitFcn', 'gainDuRappel = 3;');
     matlibre_sl_rappel(m, 'InitFcn');
     evalin('base', 'gainDuRappel')            % 3

  Voir aussi SIM, LOAD_SYSTEM, SAVE_SYSTEM, SET_PARAM.
```

## `matlibre_sl_remplacer`

```
MATLIBRE_SL_REMPLACER Repose un modèle sous le sous-système d'où il vient.
  MODELE = MATLIBRE_SL_REMPLACER(MODELE,CHEMIN,SOUS) rend MODELE où le
  sous-système que CHEMIN désigne porte à présent SOUS. Le chemin
  s'écrit « boite » pour un niveau, « boite/interne » pour deux ; un
  chemin vide rend SOUS lui-même.

  C'est le retour de MATLIBRE_SL_DEDANS. L'éditeur du bureau s'en sert
  quand on modifie un bloc à l'intérieur d'un sous-système : il
  descend, applique la modification, et repose le tout — en une seule
  commande, si bien qu'un CTRL+Z la défait d'un coup.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     interne = add_block(new_system('dedans'), 'gain', 'k', 'Gain', 3);
     m = add_block(new_system('dehors'), 'subsystem', 'boite', ...
                   'Model', interne);
     m = matlibre_sl_remplacer(m, 'boite', ...
                               set_param(interne, 'k', 'Gain', 5));
     get_param(matlibre_sl_dedans(m, 'boite'), 'k', 'Gain')     % 5

  Voir aussi MATLIBRE_SL_DEDANS, MATLIBRE_SL_APLATIR, SET_PARAM.
```

## `matlibre_sl_restructurer`

```
MATLIBRE_SL_RESTRUCTURER Regroupe, déplie, vide ou range un système.
  Les opérations sur la valeur d'un système — un modèle, ou le contenu
  d'un sous-système —, que SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM,
  EXPANDSUBSYSTEM, ARRANGESYSTEM, DELETECONTENTS et leurs voisines
  appliquent au modèle de la session :

  S = MATLIBRE_SL_RESTRUCTURER('arranger',S)  retire la Position de
      chaque bloc du système : la mise en place automatique les range.
  S = MATLIBRE_SL_RESTRUCTURER('vider',S)  retire ses blocs et ses liens.
  [S,NOM] = MATLIBRE_SL_RESTRUCTURER('regrouper',S,BLOCS,NOM,UNIQUE,OU)
      range les blocs nommés dans un sous-système neuf, et rend son nom.
  [S,NOMS] = MATLIBRE_SL_RESTRUCTURER('deplier',S,BLOC,OU)  remplace le
      sous-système BLOC par son contenu, et rend les noms des blocs posés.
  C = MATLIBRE_SL_RESTRUCTURER('contenu',S,BLOC,OU)  le contenu du
      sous-système BLOC.
  S = MATLIBRE_SL_RESTRUCTURER('viderSousSysteme',S,BLOC,OU)
  S = MATLIBRE_SL_RESTRUCTURER('remplir',S,BLOC,C,OU)  pose le contenu C
      dans le sous-système vide BLOC.
  OU est le chemin du système, pour que les erreurs nomment les blocs
  comme Simulink.

  Et pour un modèle de la session :
  CTX = MATLIBRE_SL_RESTRUCTURER('ouvrir',RACINE,CHEMIN)  le système au
      chemin CHEMIN du modèle RACINE ('' : le modèle) : CTX.systeme ;
  MATLIBRE_SL_RESTRUCTURER('fermer',CTX,S)  le remet à sa place.

  Les liens se rebranchent comme dans Simulink. Regrouper : un signal
  qui entre dans le groupe devient une entrée du sous-système, une
  seule par signal ; un signal qui en sort, une sortie ; un port resté
  libre reçoit son Inport ou son Outport ; un bloc Inport ou Outport du
  groupe part dedans, et un bloc de même nom et de même rang le
  remplace dehors. Déplier : chaque signal qui arrivait sur une entrée
  du sous-système va droit aux blocs que son Inport alimentait, et ce
  qui alimentait un Outport va droit aux blocs que la sortie
  alimentait ; les Inport et les Outport disparaissent.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 2);
     m = add_block(m, 'gain', 'g', 'Gain', 3);
     m = add_block(m, 'outport', 'y');
     m = add_line(add_line(m, 'c', 'g'), 'g', 'y');
     [m, nom] = matlibre_sl_restructurer('regrouper', m, {'g'}, '', true, 'essai');
     nom                                      % 'Subsystem'
     m = matlibre_sl_restructurer('deplier', m, nom, 'essai');
     numel(m.blocs)                           % 3, comme avant

  Voir aussi SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM,
  SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM, SIMULINK.BLOCKDIAGRAM.ARRANGESYSTEM.
```

## `matlibre_sl_scenario`

```
MATLIBRE_SL_SCENARIO Les signaux d'un scénario du Signal Editor.
  S = MATLIBRE_SL_SCENARIO(FICHIER,SCENARIO,CHEMIN) lit dans le fichier
  MAT FICHIER la variable SCENARIO, un Simulink.SimulationData.Dataset
  dont chaque élément est une timeseries, ou un
  Simulink.SimulationData.Signal qui en porte une. Rend un tableau de
  structures, une par signal : nom, temps (colonne), valeurs (une ligne
  par instant), methode ('linear', ou 'previous' pour une timeseries en
  tenue d'ordre zéro). CHEMIN nomme le bloc dans les erreurs.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     Scenario = Simulink.SimulationData.Dataset;
     Scenario = addElement(Scenario, timeseries([0; 1], [0; 1], 'Name', 's'));
     f = [tempname() '.mat'];
     save(f, 'Scenario');
     s = matlibre_sl_scenario(f, 'Scenario', 'm/editeur');
     s(1).nom                                   % 's'
     delete(f);

  Voir aussi ADD_BLOCK, SIM.
```

## `matlibre_sl_serie`

```
MATLIBRE_SL_SERIE Les instants et les valeurs d'une timeseries, en lignes.
  [T,V] = MATLIBRE_SL_SERIE(TS) rend les instants de la TIMESERIES TS en
  colonne, et ses valeurs une ligne par instant : un échantillon
  matriciel m-par-n s'y déplie en m*n colonnes. C'est la forme que lisent
  le bloc From Workspace et les entrées externes de SIM.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [t, v] = matlibre_sl_serie(timeseries([1 2; 3 4], [0 1]))  % v = [1 2; 3 4]

  Voir aussi TIMESERIES, SIM.
```

## `matlibre_sl_signaux`

```
MATLIBRE_SL_SIGNAUX Les ports des blocs, leurs signaux et leur journal.
  PH = MATLIBRE_SL_SIGNAUX('poignees',MODELE,BLOC) rend les poignées des
  ports du bloc, comme GET_PARAM(MODELE,BLOC,'PortHandles') : une
  structure à champs Inport, Outport, Enable, Trigger, State, LConn,
  RConn, Ifaction et Reset. Une poignée est un nombre, le même pour un
  même port tout au long de la session.

  M = MATLIBRE_SL_SIGNAUX('poser',MODELE,H,NOM,VALEUR,...) règle le
  signal qui part du port de sortie H : son nom (Name) et sa
  journalisation — DataLogging, DataLoggingNameMode ('SignalName' ou
  'Custom'), DataLoggingName, DataLoggingDecimateData et
  DataLoggingDecimation, DataLoggingLimitDataPoints et
  DataLoggingMaxPoints —, et TestPoint. SET_PARAM(MODELE,H,...) passe
  par là. V = MATLIBRE_SL_SIGNAUX('lire',MODELE,H,NOM) relit un réglage,
  ou PortType, PortNumber, Parent et Handle ; GET_PARAM(MODELE,H,NOM)
  passe par là.

  DS = MATLIBRE_SL_SIGNAUX('journal',C,T,J,INSTANTS) rend le journal
  des signaux d'une simulation — ce que SIM range dans logsout — : un
  Simulink.SimulationData.Dataset, un élément par signal dont
  DataLogging vaut 'on', chacun portant son nom, le chemin de son bloc,
  son port et ses valeurs en timeseries. Vide si aucun signal n'est
  journalisé.

  Les réglages d'un signal sont rangés dans le bloc d'où il part, champ
  SIGNAUX : c'est le port de sortie qui porte le signal, comme dans
  Simulink.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = add_block(new_system('m'), 'sine', 's');
     ph = matlibre_sl_signaux('poignees', m, 's');
     m = matlibre_sl_signaux('poser', m, ph.Outport(1), 'Name', 'onde');
     matlibre_sl_signaux('lire', m, ph.Outport(1), 'Name')     % 'onde'

  Voir aussi GET_PARAM, SET_PARAM, SIM, SIMULINK.SIMULATIONDATA.DATASET.
```

## `matlibre_sl_signes`

```
MATLIBRE_SL_SIGNES Signes d'un bloc de sommation.
  SIGNES = MATLIBRE_SL_SIGNES(BLOC) rend la chaîne des signes, « ++ »
  par défaut : une sommation sans signe déclaré additionne.

  C'est aussi par cette chaîne que le nombre d'entrées d'un bloc
  voyage jusqu'à la toile de l'éditeur, qui compte ses caractères. Un
  sous-système en rend donc autant qu'il abrège de blocs INPORT — sans
  quoi ses liaisons arriveraient toutes au même point.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_signes(struct('parametres', struct('Signs', '+-')))

  Voir aussi MATLIBRE_SL_FORME, ADD_BLOCK.
```

## `matlibre_sl_slx`

```
MATLIBRE_SL_SLX Lit et écrit les fichiers de modèle de Simulink, .slx et .mdl.
  MODELE = MATLIBRE_SL_SLX('lire',FICHIER) lit un modèle enregistré par
  Simulink et le rend sous la forme de NEW_SYSTEM : ses blocs, leurs
  paramètres, ses liens, ses sous-systèmes, sa configuration.

  Un .slx est une archive ZIP de fichiers XML, que UNZIP ouvre : le
  modèle et ses réglages dans simulink/blockdiagram.xml, chaque système
  dans simulink/systems/system_*.xml — ou, dans les fichiers plus
  anciens, emboîté dans le premier —, la configuration dans
  simulink/configSet0.xml. Chaque bloc porte son type (BlockType), son
  nom, son identifiant (SID) et ceux de ses paramètres qui diffèrent du
  défaut ; un lien va d'un « SID#out:n » à un « SID#in:m », et se
  ramifie par ses Branch. Un .mdl dit la même chose en texte, par
  sections emboîtées « Block { ... } ».

  Un bloc de bibliothèque masqué (BlockType Reference) est reconnu par
  son chemin, SourceBlock : « simulink/Sources/Ramp » est la rampe de
  MatLibre. Les paramètres que le catalogue ne connaît pas — la mise en
  page, les couleurs, les attributs d'affichage — sont laissés de côté ;
  un bloc dont le type n'a pas d'équivalent est refusé, avec les autres,
  en une seule erreur qui les nomme tous, plutôt que simulé de travers.

  MATLIBRE_SL_SLX('ecrire',MODELE,FICHIER) écrit le modèle au format
  .slx, dans la disposition des fichiers de Simulink : blocs, liens par
  SID, sous-systèmes emboîtés, réglages du solveur. Le fichier se relit
  par LOAD_SYSTEM.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     m = new_system('petit');
     m = add_block(m, 'constant', 'c', 'Value', 3);
     m = add_block(m, 'gain', 'g', 'Gain', 2);
     m = add_line(m, 'c', 'g');
     fichier = [tempname() '.slx'];
     matlibre_sl_slx('ecrire', m, fichier);
     relu = matlibre_sl_slx('lire', fichier);
     get_param(relu, 'g', 'Gain')             % '2'

  Voir aussi LOAD_SYSTEM, SAVE_SYSTEM, UNZIP, ZIP.
```

## `matlibre_sl_tablend`

```
MATLIBRE_SL_TABLEND Interpole dans une table à N dimensions.
  Y = MATLIBRE_SL_TABLEND(T,B,U,METHODE,EXTRAPOLATION) rend, pour chaque
  élément des entrées, la valeur de la table T — un tableau à N
  dimensions, de taille numel(B{1}) x ... x numel(B{N}) — au point
  U{1}(k), ..., U{N}(k). B{D} porte les points de la dimension D, en
  ordre croissant. Une entrée scalaire vaut pour tous les éléments.

  METHODE : 'Linear point-slope' ou 'Linear' (multilinéaire), 'Flat'
  (la valeur au point de rupture inférieur) ou 'Nearest' (au plus
  proche). EXTRAPOLATION : 'Clip' (les entrées sont ramenées dans les
  bornes) ou 'Linear' (prolongée par le premier ou le dernier
  intervalle).

  C'est ce que calcule le bloc n-D Lookup Table au-delà de deux
  dimensions.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     T = reshape(1:8, [2 2 2]);
     matlibre_sl_tablend(T, {[0 1], [0 1], [0 1]}, {0.5, 0, 1}, 'Linear', 'Clip')  % 5.5

  Voir aussi INTERPN, ADD_BLOCK.
```

## `matlibre_sl_tableps`

```
MATLIBRE_SL_TABLEPS Les tables des signaux physiques de Simscape.
  Y = MATLIBRE_SL_TABLEPS(GRILLES,VALEURS,ENTREES,LISSE,EXTRAPOLATION,
  CHEMIN) lit la table d'un PS Lookup Table (1D) ou (2D) : GRILLES est
  une cellule d'une ou de deux grilles croissantes, VALEURS le vecteur ou
  la matrice des valeurs, ENTREES une cellule d'autant de signaux. LISSE
  interpole par la méthode d'Akima modifiée, sinon linéairement ; hors de
  la grille, EXTRAPOLATION vaut 'Linear' (le prolongement des deux points
  extrêmes), 'Nearest' (la valeur du bord) ou 'Error'.

  En deux dimensions, la table s'interpole le long de la première grille,
  puis de la seconde.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi MATLIBRE_SL_PHYSIQUE.
```

## `matlibre_sl_toile`

```
MATLIBRE_SL_TOILE Taille de figure qui convient à un schéma.
  [L,H] = MATLIBRE_SL_TOILE(UX,UY) rend la largeur et la hauteur en
  pixels d'une figure où un schéma de UX sur UY unités se lise : assez
  grande pour qu'un nom de bloc tienne sous son bloc, assez petite pour
  tenir sur un écran.

  La toile garde les proportions du schéma. Sans cela, « axis equal »
  ajuste l'échelle au côté le plus contraint et laisse le reste en
  blanc : un schéma en long se retrouvait en bandeau au milieu d'une
  toile carrée, ses étiquettes serrées à l'illisible.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     [l, h] = matlibre_sl_toile(20, 5);
     abs(l / h - 4) < 0.05            % la toile suit les proportions

  Voir aussi OPEN_SYSTEM, MATLIBRE_SL_DISPOSITION.
```

## `matlibre_sl_types`

```
MATLIBRE_SL_TYPES Les types de données des signaux : propagation et contrôle.
  T = MATLIBRE_SL_TYPES('propager',C) rend le type de chaque port de
  sortie du modèle compilé C, comme Simulink le propage : un code par
  port — 2 double, 3 single, 4 int8, 5 uint8, 6 int16, 7 uint16,
  8 int32, 9 uint32, 10 boolean, et à partir de 101 les types à
  virgule fixe (fixdt(1,16,8), 'sfix16_En8'), numérotés à mesure
  qu'on les rencontre. Une constante a le type de sa valeur ou
  celui de son OutDataTypeStr ; une entrée, celui de son OutDataTypeStr,
  double sinon ; un opérateur relationnel ou logique rend un booléen ;
  un bloc de calcul ou d'aiguillage hérite du type de ses entrées —
  double si elles en ont plusieurs —, une MATLAB Function de la classe
  de ce qu'elle rend. Un signal que rien ne type est double.

  Les types sont ensuite contrôlés comme Simulink les contrôle : un
  bloc continu, un Fcn, une S-fonction, une fonction trigonométrique ne
  reçoivent que des doubles ; les entrées d'un Merge sont d'un même
  type ; une entrée ou une sortie typée reçoit son type. Chaque refus
  est une erreur Simulink:DataType:… qui nomme le bloc.

  X = MATLIBRE_SL_TYPES('complexite',C) rend, pour chaque port de
  sortie, vrai si son signal est complexe : une constante, un gain, une
  donnée de l'espace de travail complexes le rendent complexe, un calcul
  le transmet, Abs ou Complex to Real-Imag le rendent réel. Un bloc qui
  ne calcule qu'en réel — une saturation, un intégrateur, une table... —
  refuse une entrée complexe : Simulink:DataType:InputPortComplexityMismatch.

  Un calcul à virgule fixe dont le type n'est pas dit (Inherit via
  internal rule) prend le type qui ne perd rien : une somme garde la
  plus fine des échelles et gagne les bits de ses retenues, un produit
  additionne tailles et bits après la virgule, un gain y range d'abord
  son paramètre en meilleure précision sur la taille de l'entrée ; le
  tout borné à 32 bits, en rognant les bits après la virgule.

  V = MATLIBRE_SL_TYPES('convertir',CODE,V) range V dans le type CODE :
  un FI pour un type à virgule fixe. T = MATLIBRE_SL_TYPES('numerictype',
  CODE) rend le NUMERICTYPE d'un type à virgule fixe, et L =
  MATLIBRE_SL_TYPES('fixes') la table de ceux qu'on a rencontrés : une
  ligne [signe, taille, bits après la virgule, ajustement, biais] par
  code, à partir de 101.

  C = MATLIBRE_SL_TYPES('code',NOM) rend le code d'un nom de type
  ('int8', 'boolean'...), 0 pour un type hérité ; N =
  MATLIBRE_SL_TYPES('nom',CODE) le nom ; K =
  MATLIBRE_SL_TYPES('classe',CODE) la classe MATLAB ('logical' pour
  boolean).

  Un type énuméré s'écrit 'Enum: Couleur', où Couleur est une
  énumération de valeurs entières — dérivée de Simulink.IntEnumType ou
  d'un entier de MATLAB. Ses codes vont à partir de 201, dans l'ordre où
  on les rencontre. Son signal porte la valeur entière de chaque membre ;
  il ne se calcule pas — un gain, une somme le refusent —, mais il se
  retarde, s'aiguille, se compare à un membre du même type et se
  convertit en entier (Data Type Conversion). K =
  MATLIBRE_SL_TYPES('enum',CODE) rend la classe d'un type énuméré, '' pour
  un autre type ; V = MATLIBRE_SL_TYPES('defaut',CODE) la valeur de son
  membre par défaut — celui que rend la méthode statique getDefaultValue
  de la classe, le premier membre sinon — ; V =
  MATLIBRE_SL_TYPES('valeurs',CODE) les valeurs de ses membres ; T =
  MATLIBRE_SL_TYPES('texte',M) le texte MATLAB d'un membre ou d'un
  tableau de membres, 'Couleur.Rouge' ou '[Couleur.Rouge Couleur.Vert]',
  comme un modèle l'enregistre.

  MATLIBRE_SL_TYPES('surcharge',MODE,PORTEE) pose le Data Type Override
  de Simulink le temps d'une compilation : MODE 'Double', 'Single' ou
  'ScaledDouble' remplace les types numériques — tous
  ('AllNumericTypes'), les flottants ('Floating-point') ou les entiers et
  virgules fixes ('Fixed-point') —, les booléens et les énumérations
  jamais ; 'UseLocalSettings' et 'Off' n'en remplacent aucun.
  MATLIBRE_SL_TYPES('surcharge') rend l'état, que la même action
  restaure.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     matlibre_sl_types('code', 'int16')          % 6

  Voir aussi MATLIBRE_SL_COMPILER, ADD_BLOCK.
```

## `matlibre_sl_variantes`

```
MATLIBRE_SL_VARIANTES La variante active parmi plusieurs.
  K = MATLIBRE_SL_VARIANTES('choisir',CONTROLES,MODE,ETIQUETTE,ZERO,
  CHEMIN,NOMS) rend le rang de la variante active : CONTROLES{I} est la
  condition de la variante I, dont le nom — pour les messages — est
  NOMS{I}.

  L = MATLIBRE_SL_VARIANTES('liste',V) rend les conditions d'un Variant
  Source ou d'un Variant Sink en cellule de textes : V est une cellule,
  ou le texte « {'V == 1', 'V == 2'} » qu'un fichier .slx porte.

  En MODE 'expression', chaque condition s'évalue dans l'espace de
  travail de base : une expression — 'Mode == 1' —, ou le nom d'un
  SIMULINK.VARIANT, dont la condition s'évalue alors. Une variante dont
  la condition vaut '(default)' est active quand aucune autre ne l'est ;
  une condition vide n'est jamais vraie. En MODE 'label', la variante
  active est celle dont la condition — une étiquette — vaut ETIQUETTE.

  Aucune variante active : K vaut 0 si ZERO est vrai
  (AllowZeroVariantControls), sinon une erreur
  Simulink:Variants:NoActiveVariant nomme le bloc CHEMIN et les
  conditions. Plusieurs : une erreur Simulink:Variants:
  MultipleActiveVariants les nomme.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Exemple :
     assignin('base', 'Mode', 2);
     matlibre_sl_variantes('choisir', {'Mode == 1', 'Mode == 2'}, ...
                           'expression', '', false, 'm/v', {'un', 'deux'})  % 2

  Voir aussi SIMULINK.VARIANT, ADD_BLOCK, SIM.
```

## `new_system`

```
NEW_SYSTEM Crée un modèle Simulink vide.
  MODELE = NEW_SYSTEM(NOM) rend un modèle sans bloc ni lien. On le
  remplit par ADD_BLOCK, on le câble par ADD_LINE, on le règle par
  SET_PARAM, on le regarde par OPEN_SYSTEM, et on le simule par SIM.

  Le modèle est une structure à quatre champs : NOM, BLOCS, LIENS et
  PARAMETRES. C'est une valeur, non une référence : chaque fonction en
  rend une nouvelle et laisse l'ancienne intacte.

  PARAMETRES porte les réglages du modèle lui-même — StopTime,
  FixedStep —, que SIM emploie quand on ne lui donne ni durée ni pas.
  ADD_PARAM les pose, DELETE_PARAM les retire.

  NEW_SYSTEM(NOM,'Library') crée une bibliothèque : ses blocs se posent
  dans d'autres modèles par ADD_BLOCK(M,'nomBibliotheque/bloc',NOM), qui
  y garde le lien — la bibliothèque changée, le bloc suit —, mais elle ne
  se simule pas elle-même.

  NEW_SYSTEM(NOM,'Subsystem') crée un fichier de sous-système : un bloc
  Subsystem Reference le désigne par son nom (ReferencedSubsystem), et
  la compilation le déroule à sa place, comme un sous-système. Il ne se
  simule pas seul.

  Les modèles se décrivent ici en appelant ces fonctions, ou se lisent
  d'un fichier .slx ou .mdl de Simulink par LOAD_SYSTEM. SAVE_SYSTEM en
  écrit un programme .m, ou un .slx, que LOAD_SYSTEM relit.

  La forme de MATLAB — NEW_SYSTEM(NOM) sans reprendre la sortie — met le
  modèle dans la session : ADD_BLOCK, ADD_LINE, SET_PARAM, GET_PARAM,
  FIND_SYSTEM, SIM et SAVE_SYSTEM le désignent alors par son nom, et ses
  blocs par leur chemin « nom/bloc ». Un modèle de ce nom déjà ouvert
  est refusé ; BDCLOSE le ferme. Le modèle y part des réglages d'un
  modèle neuf de Simulink — le solveur automatique à pas variable
  (VariableStepAuto), les sorties en Dataset (SaveFormat) —, là où le
  modèle par valeur part de ceux de MatLibre : ode1 au pas de 0,01, et
  des sorties en tableau.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     m = add_line(m, 'un', 'integ');
     r = sim(m, 5, 0.001);

     new_system('session');
     add_block('simulink/Sources/Constant', 'session/c', 'Value', '3');
     get_param('session/c', 'Value')          % '3'
     bdclose('session');

  Voir aussi ADD_BLOCK, ADD_LINE, SET_PARAM, ADD_PARAM, SIM, OPEN_SYSTEM.
```

## `open_system`

```
OPEN_SYSTEM Ouvre un modèle et en dessine le schéma-bloc.
  OPEN_SYSTEM(MODELE) trace le schéma : un bloc par élément, sa forme
  disant ce qu'il fait, et les liaisons fléchées entre eux.
  H = OPEN_SYSTEM(MODELE) rend en plus la poignée de la figure.

  Les blocs sont rangés en couches, de la source vers la sortie, et
  ordonnés dans chaque couche pour croiser le moins de liaisons
  possible. Une contre-réaction passe sous le schéma : tracée en ligne
  droite, elle traverserait les blocs qu'elle enjambe.

  Le schéma est reconstruit à partir du modèle à chaque appel : il n'y
  a pas de position enregistrée, et donc rien à déplacer à la souris.
  MATLAB ouvre un éditeur, MatLibre rend une figure — on voit le
  schéma, on ne le modifie pas là.

  Le modèle est inscrit au registre de la session : GCS le nomme,
  BDISLOADED répond vrai, et CLOSE_SYSTEM le ferme avec sa figure.
  OPEN_SYSTEM(NOM) rouvre un modèle déjà inscrit, ou exécute le
  fichier NOM.m qui le rend.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'correcteur', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'correcteur');
     m = add_line(m, 'correcteur', 'sortie');
     open_system(m);
     close_system(m);

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM, GCS, SIM.
```

## `parsim`

```
PARSIM Fait toute une série de simulations, décrites par des SimulationInput.
  OUT = PARSIM(IN) simule chaque élément du tableau IN de
  SIMULINK.SIMULATIONINPUT — un même modèle avec d'autres variables,
  d'autres paramètres de blocs, d'autres réglages — et rend OUT, le
  tableau de même taille de leurs résultats. Chacun porte ce que rend
  SIM, plus ErrorMessage — vide si la simulation a abouti — et
  SimulationMetadata (le modèle, ses instants, son solveur, la durée).

  Une simulation qui échoue n'arrête pas les autres : son résultat
  porte le message de l'erreur dans ErrorMessage, et ses autres champs
  sont vides. Après chaque simulation, l'espace de travail de base
  retrouve les variables qu'il avait.

  Simulink répartit les simulations sur les cœurs d'un pool parallèle ;
  MatLibre, qui n'en a pas, les fait l'une après l'autre, et les
  résultats sont les mêmes.

  OUT = PARSIM(IN,NOM,VALEUR,...) :
     'ShowProgress'  'on' (défaut) : une ligne par simulation terminée
     'StopOnError'   'off' (défaut) ; 'on' : après une erreur, les
                     simulations suivantes ne se font pas, et leur
                     ErrorMessage le dit
     'SetupFcn'      @f, appelée une fois avant les simulations
     'CleanupFcn'    @f, appelée une fois après, même sur une erreur
     'TransferBaseWorkspaceVariables', 'UseFastRestart',
     'ShowSimulationManager', 'AttachedFiles', 'ManageDependencies'
                     admises, sans effet : tout se passe dans la même
                     session, qui voit déjà l'espace de travail
     'RunInBackground'  'off' seulement

  Exemple :
     pd = new_system('pd');
     pd = add_block(pd, 'constant', 'c', 'Value', 'K');
     pd = add_block(pd, 'outport', 'y');
     pd = add_line(pd, 'c', 'y');
     in(1:3) = Simulink.SimulationInput('pd');
     for k = 1:3
         in(k) = in(k).setVariable('K', 10 * k);
     end
     out = parsim(in, 'ShowProgress', 'off');
     out(2).yout(end)                   % 20

  Voir aussi SIMULINK.SIMULATIONINPUT, SIM.
```

## `replace_block`

```
REPLACE_BLOCK Remplace les blocs d'un type par un autre type.
  MODELE = REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU) change le type de tous
  les blocs de type ANCIEN en NOUVEAU. Les noms et les liens sont
  conservés, ainsi que les paramètres que le nouveau type porte aussi ;
  les autres sont retirés, puisque plus personne ne les lirait. Les
  types se désignent comme dans ADD_BLOCK : nom MatLibre, type Simulink
  ou chemin de bibliothèque.
  REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU,'Param',VALEUR,...) fixe en outre
  des paramètres sur chaque bloc remplacé.

  Le câblage ne bouge pas : c'est tout l'intérêt, remplacer un
  intégrateur continu par son équivalent discret sans redessiner le
  schéma.

  La forme de MATLAB : REPLACE_BLOCK(SYSTEME,ANCIEN,NOUVEAU,'noprompt')
  sur un modèle de la session désigné par son nom, à tous ses niveaux ;
  elle rend les chemins des blocs remplacés.

  Exemple :
     m = new_system('essai');
     m = add_block(m, 'integrator', 'i1');
     m = add_block(m, 'integrator', 'i2');
     m = replace_block(m, 'integrator', 'discreteintegrator', ...
                       'SampleTime', 0.1);
     get_param(m, 'i1', 'BlockType')          % 'discreteintegrator'
     get_param(m, 'i2', 'SampleTime')         % 0.1

  Voir aussi ADD_BLOCK, DELETE_BLOCK, SET_PARAM, FIND_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `save_system`

```
SAVE_SYSTEM Enregistre un modèle dans un fichier .m qui le rebâtit.
  SAVE_SYSTEM(MODELE) écrit MODELE.nom.m dans le dossier courant.
  SAVE_SYSTEM(MODELE,FICHIER) choisit le nom du fichier ; l'extension
  .m est ajoutée si elle manque. La fonction rend le chemin écrit.
  SAVE_SYSTEM(MODELE,'nom.slx') écrit au format de Simulink, une
  archive de fichiers XML que LOAD_SYSTEM relit (voir MATLIBRE_SL_SLX).

  Le fichier produit est un programme : une fonction sans argument qui
  appelle NEW_SYSTEM, ADD_BLOCK et ADD_LINE, et rend le modèle.
  LOAD_SYSTEM le relit, et SIM l'accepte par son nom. C'est un format
  qui se lit, se compare et se range dans un dépôt, mieux qu'une
  archive .slx.

  Les valeurs de paramètres sont réécrites par MAT2STR pour les
  nombres et entre apostrophes pour le texte : ce qu'on relit est ce
  qu'on avait, à la représentation près.

  Un sous-système porte tout un modèle en paramètre. Le fichier le
  bâtit d'abord, dans sa propre variable, puis le donne au bloc qui
  l'abrège : un schéma emboîté se relit donc comme un schéma plat.

  La forme de MATLAB : SAVE_SYSTEM(NOM) écrit NOM.slx depuis le modèle de
  la session ; SAVE_SYSTEM(NOM,FICHIER) sous un autre nom de fichier, que
  le modèle ouvert prend alors, comme dans Simulink.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'c', 'Value', 2);
     m = add_block(m, 'gain', 'g', 'Gain', 3);
     m = add_line(m, 'c', 'g');
     chemin = save_system(m, [tempname() '.m']);
     relu = load_system(chemin);
     get_param(relu, 'g', 'Gain')             % 3
     delete(chemin);

  Voir aussi LOAD_SYSTEM, NEW_SYSTEM, ADD_BLOCK, ADD_LINE, CLOSE_SYSTEM.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `setActiveConfigSet`

```
SETACTIVECONFIGSET Rend actif un jeu de configuration du modèle.
  SETACTIVECONFIGSET(MODELE,NOM) active le jeu nommé NOM du modèle de
  la session nommé MODELE : ses réglages deviennent ceux du modèle —
  ceux que GET_PARAM lit et que SIM applique —, et ceux du jeu qui
  était actif attendent d'être réactivés.

  MODELE = SETACTIVECONFIGSET(MODELE,NOM) fait de même sur un modèle
  par valeur, et le rend.

  Exemple :
     m = new_system('essai');
     cs = Simulink.ConfigSet;
     cs.Name = 'Rapide';
     set_param(cs, 'StopTime', '1');
     m = setActiveConfigSet(attachConfigSet(m, cs), 'Rapide');
     get_param(m, 'StopTime')                 % 1
     m = setActiveConfigSet(m, 'Configuration');
     get_param(m, 'StopTime')                 % 10

  Voir aussi GETACTIVECONFIGSET, ATTACHCONFIGSET, GETCONFIGSETS.
```

## `set_param`

```
SET_PARAM Modifie les paramètres d'un bloc, ou les réglages du modèle.
  MODELE = SET_PARAM(MODELE,BLOC,'Param',VALEUR,...) change un ou
  plusieurs paramètres du bloc nommé, sans toucher aux autres ni au
  câblage. BLOC est le nom du bloc, ou son chemin « modele/bloc » ; un
  chemin « sousSysteme/bloc » descend dans un sous-système.

  C'est ainsi qu'on balaie un réglage : construire le modèle une fois,
  puis le simuler pour chaque valeur d'un gain ou d'une condition
  initiale.

  Les noms de paramètres reconnus sont ceux qu'ADD_BLOCK décrit, par
  type de bloc ; la casse est indifférente, et les noms de Simulink
  valent pour ceux de MatLibre. Un nom que le bloc n'a pas est refusé
  en le nommant : rangé, il ne serait lu par personne. 'BlockType' ne
  se change pas — REPLACE_BLOCK change le type d'un bloc.

  'Name' fait exception : il renomme le bloc, comme dans Simulink, au
  lieu de poser un réglage de ce nom. Sur un sous-système masqué, une
  variable du masque (MaskVariables) se règle comme un paramètre. Les liens désignent les blocs par
  leur rang, si bien que le câblage ne bouge pas.

  MODELE = SET_PARAM(MODELE,'Reglage',VALEUR,...) — sans nom de bloc
  devant, donc en nombre impair d'arguments — change les réglages du
  modèle lui-même, ceux de la boîte « Paramètres de configuration » de
  Simulink : StartTime, StopTime, Solver ('ode1' à 'ode5', 'ode8',
  'ode14x', 'ode1be', 'FixedStepDiscrete' à pas fixe ; 'ode45', 'ode23',
  'ode113', 'ode15s', 'ode23s', 'ode23t', 'ode23tb',
  'VariableStepDiscrete' à pas variable), SolverType, FixedStep,
  RelTol, AbsTol, MaxStep, MinStep, InitialStep, ZeroCrossControl,
  AlgebraicLoopMsg, UnconnectedInputMsg, UnconnectedOutputMsg... La
  valeur est vérifiée avant d'être posée : un solveur inconnu est
  refusé en disant ceux qui existent. Le type suit le solveur. Un
  réglage posé par ADD_PARAM se change de même.

  SET_PARAM(MODELE,H,'Name','vitesse','DataLogging','on'), H une
  poignée de port de sortie que rend GET_PARAM(MODELE,BLOC,
  'PortHandles'), nomme le signal qui part de ce port et le
  journalise : SIM le range alors dans logsout, un
  Simulink.SimulationData.Dataset. DataLoggingNameMode ('SignalName'
  ou 'Custom') et DataLoggingName nomment l'élément du journal ;
  DataLoggingDecimateData et DataLoggingDecimation n'en gardent qu'un
  instant sur N, DataLoggingLimitDataPoints et DataLoggingMaxPoints
  les derniers.

  La forme de MATLAB : SET_PARAM(OBJET,'Param',VALEUR,...), sans sortie,
  règle dans la session l'objet que désigne son nom ('modele'), son
  chemin ('modele/bloc') ou sa poignée — un modèle, un bloc, un port, ou
  une ligne, qui porte les réglages du signal. Position s'y donne en
  pixels, comme dans Simulink ; Dirty, que la session tient pour chaque
  modèle, s'y règle ('on', 'off'). Changer le rang (Port) d'un Inport ou
  d'un Outport décale les autres, pour que les rangs restent 1 à N.

  Commented met un bloc en commentaire : 'on' le retire du calcul — ce
  qu'il alimentait lit zéro —, 'through' le fait traverser, chaque
  sortie rendant l'entrée de même rang ; 'off' le rétablit.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');
     for K = [1 2 5]
         m = set_param(m, 'gain', 'Gain', K);
         r = sim(m, 5, 0.01);
     end
     m = set_param(m, 'gain', 'Name', 'correcteur');
     get_param(m, 'correcteur', 'Gain')       % 5 : le bloc a change de nom
     m = set_param(m, 'Solver', 'ode4', 'StopTime', 2);
     get_param(m, 'Solver')                   % 'ode4'

  Voir aussi GET_PARAM, ADD_PARAM, ADD_BLOCK, SIM, REPLACE_BLOCK.
La forme de MATLAB : le modèle désigné par son nom ou sa poignée.
```

## `sim`

```
SIM Simule un modèle.
  RESULTAT = SIM(MODELE) simule le modèle avec ses propres réglages :
  instants de début et de fin, solveur, pas. RESULTAT, un
  SIMULINK.SIMULATIONOUTPUT, porte le vecteur des instants et, pour
  chaque bloc, le signal relevé à sa sortie — ou, pour un bloc qui n'en
  a pas, ce qui arrive à son entrée —, ses métadonnées
  (SimulationMetadata) et ErrorMessage ; RESULTAT.get('yout') et
  RESULTAT.who s'y emploient comme dans Simulink.

  SIM(MODELE,TFINAL) fixe l'instant final ; SIM(MODELE,[TDEBUT TFINAL])
  les deux ; SIM(MODELE,INSTANTS) donne aussi le pas par l'écart de
  deux instants réguliers. SIM(MODELE,TFINAL,PAS) fixe le pas — un
  modèle resté sur le solveur automatique à pas variable passe alors à
  son pendant à pas fixe, FixedStepAuto —, et
  SIM(MODELE,TFINAL,SIMSET(...)) accepte un jeu d'options à la place.
  SIM(MODELE,INTERVALLE,OPTIONS,[T, U]) alimente les entrées du modèle :
  le temps, puis une colonne par élément des entrées, rangées par leur
  paramètre Port ; une structure à temps y sert aussi. Les réglages
  LoadExternalInput ('on') et ExternalInput ('[t, u]', ou des variables
  séparées par des virgules, une par entrée) le disent sur le modèle.
  SIM(MODELE,'StopTime','5','Solver','ode4',...) passe les réglages par
  nom, comme dans Simulink : ils valent pour cette simulation seulement,
  et le modèle n'en est pas changé.

  Les réglages sont ceux de la boîte « Paramètres de configuration » de
  Simulink, que SET_PARAM(MODELE,'Solver','ode4') pose sur le modèle et
  que GET_PARAM relit : StartTime, StopTime, Solver, FixedStep, RelTol,
  AbsTol, MaxStep, MinStep, InitialStep, MaxOrder, ExtrapolationOrder,
  NumberNewtonIterations, ZeroCrossControl, ZeroCrossAlgorithm
  ('Nonadaptive' ; 'Adaptive' cesse de localiser les passages par zéro
  d'un bloc qui bascule sans cesse, et ignore ceux de la bande
  ZcThreshold), MaxConsecutiveZCs,
  MaxConsecutiveMinStep, et les diagnostics AlgebraicLoopMsg,
  UnconnectedInputMsg, UnconnectedOutputMsg, MaxConsecutiveZCsMsg,
  SignalInfNanChecking — une sortie de bloc Inf ou NaN —,
  SignalRangeChecking — un signal hors de la plage [OutMin, OutMax] de
  son bloc —,
  IntegerOverflowMsg et IntegerSaturationMsg — un entier ou une virgule
  fixe qui déborde de son type, replié ou saturé — (none, warning ou
  error), et MinStepSizeMsg (warning ou error). Un avertissement ne
  vient qu'une fois par bloc et par simulation. Un argument explicite
  l'emporte toujours sur le réglage enregistré.

  Les solveurs à pas fixe : ode1 (Euler), ode2
  (Heun), ode3 (Bogacki-Shampine), ode4 (Runge-Kutta), ode5
  (Dormand-Prince) et ode8 (Prince-Dormand) ; l'erreur d'un solveur
  d'ordre p décroît comme le pas à la puissance p. Pour les systèmes
  raides, ode1be (Euler implicite) et ode14x (Euler implicite
  extrapolé, d'ordre ExtrapolationOrder), qui font NumberNewtonIterations
  itérations de Newton par pas. FixedStepDiscrete sert aux modèles sans
  état continu, et FixedStepAuto choisit ode3 ou le discret.

  Les solveurs à pas variable : ode45 (Dormand-Prince 5(4)), ode23
  (Bogacki-Shampine 3(2)), ode113 (Adams, d'ordre variable, pour les
  tolérances fines), et pour les systèmes raides ode15s (NDF, d'ordre 1
  à MaxOrder), ode23s (Rosenbrock), ode23t (trapèzes) et ode23tb
  (TR-BDF2) ; VariableStepDiscrete, et VariableStepAuto, le solveur
  d'un modèle neuf comme dans Simulink, qui choisit ode45 ou le
  discret. Le pas suit l'erreur estimée — RelTol, AbsTol —, borné
  par MaxStep (le cinquantième de la durée par défaut) et MinStep. Il
  s'arrête exactement sur les instants d'échantillonnage et les
  cassures des sources (échelon, fronts d'impulsion) ; un seuil franchi
  dans un pas — l'entrée d'un relais, d'une saturation, d'un
  aiguillage, d'un Hit Crossing — est localisé par la détection des
  passages par zéro, que règlent ZeroCrossControl et le paramètre
  ZeroCross de chaque bloc. Le relevé porte alors un instant par pas
  majeur ; SIM(MODELE,[T0 T1 ... TN]) ne relève que les instants donnés,
  que le solveur atteint exactement.

  Les signaux sont des scalaires, des vecteurs ou des matrices : un Mux
  réunit ses entrées en un vecteur, un Demux les sépare, un gain
  matriciel les combine. Un bloc peut avoir plusieurs sorties. Avant de
  simuler, le modèle est compilé : chaque bloc est vérifié — ses
  paramètres, ses ports, les dimensions de ses signaux, sa période
  d'échantillonnage —, et chaque erreur le nomme par son chemin,
  « modele/bloc ». L'ordre de calcul suit le câblage. Une boucle qui
  ne passe par aucun bloc à état est algébrique : elle est résolue à
  chaque pas par la méthode de Newton, et signalée selon le réglage
  AlgebraicLoopMsg.

  Les blocs échantillonnés ne calculent qu'aux instants de leur
  période — qui, à pas fixe, doit être un multiple du pas — et gardent
  leur valeur entre deux. Un solveur d'ordre supérieur évalue le modèle
  en des points intermédiaires du pas ; les états discrets n'y bougent
  pas.

  Tous les paramètres sont résolus avant la boucle : à l'intérieur, il
  ne reste que de l'arithmétique. Un paramètre numérique donné entre
  apostrophes est une expression, évaluée à ce moment-là dans l'espace
  de travail de base : changer la variable et relancer SIM change le
  résultat sans que le modèle ait bougé. Les blocs « toworkspace » et
  « fromworkspace » font l'échange dans les deux sens.

  Un bloc « subsystem » porte tout un modèle : SIM le déplie avant de
  simuler, et rend exactement ce que rendrait le schéma écrit à plat.
  Le relevé porte alors les blocs intérieurs sous le nom
  « sousSysteme/bloc », et le sous-système lui-même la valeur de sa
  première sortie.

  SIM('NOM') accepte aussi le nom d'un modèle : une variable de
  l'espace de travail qui porte ce nom, ou un fichier NOM.m qui
  construit le modèle et le rend.

  OUT = SIM(IN), IN un SIMULINK.SIMULATIONINPUT, simule son modèle avec
  les variables, les paramètres de blocs et les réglages qu'il pose, le
  temps de cette simulation ; un tableau IN se simule l'une après
  l'autre, comme par PARSIM. OUT porte en plus ErrorMessage et
  SimulationMetadata. L'erreur d'un seul SimulationInput part comme
  celle de SIM(NOM), sauf avec SIM(IN,'CaptureErrors','on'), qui la
  range dans ErrorMessage ; celle d'un tableau y est toujours rangée.

  Un signal dont le port de sortie a DataLogging à 'on' — SET_PARAM
  sur la poignée que rend GET_PARAM(M,BLOC,'PortHandles') — est
  journalisé : RESULTAT.logsout est un Simulink.SimulationData.Dataset,
  un élément par signal, avec son nom, le chemin de son bloc, son port
  et ses valeurs en timeseries. SignalLogging ('off') l'éteint, et
  SignalLoggingName renomme le champ.

  LoadInitialState ('on') et InitialState (un vecteur, ou l'expression
  qui le donne) posent l'état continu de départ, dans l'ordre des
  colonnes de xout ; SaveFinalState ('on') range l'état final dans le
  champ FinalStateName ('xFinal') du résultat. Ensemble, ils reprennent
  une simulation là où la précédente s'est arrêtée — ses états
  continus. Avec SaveOperatingPoint ('on'), l'état final est l'état de
  fonctionnement complet, un Simulink.op.ModelOperatingPoint : états
  continus et discrets, sorties tenues, tampons des retards, diagrammes
  Stateflow, mémoire persistante des blocs MATLAB Function. Donné à
  InitialState, il fait reprendre la simulation à son
  instant, snapshotTime, jusqu'à StopTime : à pas fixe, exactement comme
  la simulation d'une traite ; à pas variable, le solveur repart de son
  premier pas. Il ne se charge que dans le modèle d'où il vient, tel
  qu'il était.

  Ce qui est relevé se règle comme dans le volet « Data Import/Export »
  de Simulink. SaveTime, SaveState et SaveOutput disent si le résultat
  porte les instants, les états continus et les sorties OUTPORT, et
  TimeSaveName ('tout'), StateSaveName ('xout') et OutputSaveName
  ('yout') sous quel nom ; les états n'y sont que si SaveState vaut
  'on'. Decimation n'en garde qu'un instant sur n, et LimitDataPoints
  ('on') les MaxDataPoints derniers. À pas variable, OutputOption
  choisit les instants : RefineOutputTimes relève chaque pas du
  solveur, et Refine - 1 points entre deux, où le modèle est calculé
  sur l'état interpolé ; AdditionalOutputTimes y ajoute les instants
  OutputTimes, que le solveur atteint exactement ;
  SpecifiedOutputTimes ne relève que le début, la fin et les instants
  OutputTimes. SIMSET porte les mêmes réglages sous leurs noms anciens :
  Refine, OutputPoints ('all' : les instants donnés et chaque pas),
  Decimation, MaxDataPoints.

  Le résultat porte plusieurs formes. RESULTAT.temps et
  RESULTAT.signaux.<nom> pour l'accès direct — un signal vecteur y est
  une matrice à une ligne par instant, un signal matrice un tableau
  m x n x N, et la deuxième sortie d'un bloc s'appelle <nom>_port2.
  RESULTAT.time et RESULTAT.signals(k).values pour la « structure with
  time » de Simulink ; RESULTAT.tout et RESULTAT.yout pour les
  instants et les sorties OUTPORT, et RESULTAT.xout pour les états
  continus si SaveState vaut 'on'. [T,X,Y] = SIM(...) rend ces trois
  derniers, états compris, comme la forme ancienne de Simulink.

  Exemple :
     m = new_system('rampe');
     m = add_block(m, 'constant', 'un', 'Value', 2);
     m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
     m = add_line(m, 'un', 'integ');
     r = sim(m, 5, 0.001);
     abs(r.signaux.integ(end) - 10) < 0.01     % l'integrale de 2 sur 5 s
     m = set_param(m, 'Solver', 'ode4', 'StopTime', 1);
     r = sim(m);
     r.temps(end)                               % 1
     r = sim(m, 'Solver', 'ode45', 'RelTol', 1e-6);
     abs(r.signaux.integ(end) - 2) < 1e-9       % exact : l'état est une droite

  Voir aussi NEW_SYSTEM, ADD_BLOCK, ADD_LINE, SET_PARAM, SIMSET, LINMOD.
```

## `simget`

```
SIMGET Lit une option de simulation.
  V = SIMGET(OPTIONS,'Nom') rend la valeur de l'option, et une matrice
  vide si elle n'est pas réglée. SIMGET(OPTIONS) rend la structure
  entière.

  Exemple :
     o = simset('FixedStep', 0.02);
     simget(o, 'FixedStep')           % 0.02
     isempty(simget(simset(), 'FixedStep'))   % vrai : rien n'est regle

  Voir aussi SIMSET, SIM.
```

## `simplot`

```
SIMPLOT Trace les signaux relevés par SIM.
  SIMPLOT(RESULTAT) trace tous les signaux du résultat sur le même axe,
  en fonction du temps. SIMPLOT(RESULTAT,NOMS) n'en trace que
  quelques-uns, désignés par leur nom de bloc.

  Exemple :
     m = new_system('boucle');
     m = add_block(m, 'constant', 'consigne', 'Value', 1);
     m = add_block(m, 'sum', 'erreur', 'Signs', '+-');
     m = add_block(m, 'gain', 'gain', 'Gain', 2);
     m = add_block(m, 'integrator', 'sortie', 'InitialCondition', 0);
     m = add_line(m, 'consigne', 'erreur', 1);
     m = add_line(m, 'sortie', 'erreur', 2);
     m = add_line(m, 'erreur', 'gain');
     m = add_line(m, 'gain', 'sortie');
     r = sim(m, 5, 0.01);
     simplot(r, {'consigne', 'sortie'});

  Voir aussi SIM, PLOT, LEGEND.
```

## `simset`

```
SIMSET Rassemble les options d'une simulation.
  OPTIONS = SIMSET('Nom',VALEUR,...) rend une structure d'options que
  SIM accepte à la place du pas : SIM(MODELE,TFINAL,OPTIONS).
  OPTIONS = SIMSET(ANCIENNES,'Nom',VALEUR,...) part d'un jeu existant.
  SIMSET() sans argument rend le jeu par défaut, où rien n'est fixé :
  une option vide laisse valoir le réglage du modèle.

  Options lues :
    Solver          le solveur. À pas fixe : 'ode1' (Euler explicite),
                    'ode2' (Heun), 'ode3' (Bogacki-Shampine), 'ode4'
                    (Runge-Kutta d'ordre quatre), 'ode5'
                    (Dormand-Prince), 'ode8', 'ode14x' et 'ode1be'
                    (raides), 'FixedStepDiscrete' pour un modèle sans
                    état continu. À pas variable : 'ode45', 'ode23',
                    'ode113', 'ode15s', 'ode23s', 'ode23t', 'ode23tb'
                    (raides), 'VariableStepDiscrete'. Tout autre nom
                    est refusé plutôt qu'ignoré.
    FixedStep       le pas d'intégration, à pas fixe
    RelTol, AbsTol  les tolérances du pas variable
    MaxStep, MinStep, InitialStep   les bornes du pas variable
    MaxOrder        l'ordre maximal d'ode15s, de 1 à 5
    ExtrapolationOrder, NumberNewtonIterations   les réglages d'ode14x
    ZeroCross       'on' ou 'off' : la détection des passages par zéro
    Refine          le facteur d'affinage du pas variable : Refine - 1
                    instants de plus entre deux pas
    OutputPoints    'specified' (celui par défaut) : relever les seuls
                    instants que donne SIM(MODELE,[T0 ... TN]) ; 'all' :
                    ceux-là et chaque pas du solveur
    Decimation      ne garder qu'un instant relevé sur Decimation
    MaxDataPoints   ne garder que les derniers instants relevés ; 0,
                    tous
    SaveFormat      la forme de yout : 'Array', 'Structure',
                    'StructureWithTime' ou 'Dataset'
    InitialState    l'état continu de départ
    FinalStateName  le champ du résultat qui porte l'état final

  Les blocs échantillonnés et les retards se simulent avec tous les
  solveurs : leurs états n'avancent qu'aux pas majeurs, et les points
  intermédiaires d'un solveur d'ordre supérieur ne les touchent pas.

  Les options que MATLAB accepte et que MatLibre ne sait pas honorer
  sont refusées en le disant : une option acceptée sans effet ferait
  croire à un réglage qui n'a pas lieu.

  Exemple :
     o = simset('FixedStep', 0.05);
     m = new_system('essai');
     m = add_block(m, 'constant', 'c', 'Value', 1);
     r = sim(m, 1, o);
     numel(r.temps)                   % 21
     o = simset('Solver', 'ode45', 'RelTol', 1e-6, 'MaxStep', 0.1);
     r = sim(m, 1, o);
     numel(r.temps)                   % 11 : le pas maximal borne tout

  Voir aussi SIMGET, SIM, SET_PARAM.
```

## `trim`

```
TRIM Cherche un point d'équilibre d'un modèle.
  [X,U,Y,DX] = TRIM(MODELE) cherche l'état et l'entrée qui annulent
  toutes les dérivées, en partant de zéro.
  TRIM(MODELE,X0,U0,Y0) part des valeurs données et vise la sortie Y0.
  TRIM(MODELE,X0,U0,Y0,IX,IU,IY) tient fixées les composantes désignées
  par IX dans l'état et IU dans l'entrée, et n'impose la sortie que sur
  les composantes IY.

  La recherche est un Gauss-Newton amorti sur le résidu formé des
  dérivées d'état et des écarts de sortie imposés. Le jacobien vient de
  différences centrées, comme dans LINMOD : sur un modèle linéaire,
  l'équilibre est donc atteint en une itération, à l'arrondi près.

  DX est rendu pour qu'on puisse juger : un équilibre trouvé se
  reconnaît à ce que DX y est nul, non à ce que la fonction a rendu
  sans erreur. Quand la recherche n'y parvient pas, l'avertissement le
  dit et le meilleur point trouvé est rendu quand même.

  Exemple :
     m = new_system('premier');
     m = add_block(m, 'inport', 'u', 'Port', 1);
     m = add_block(m, 'sum', 's', 'Signs', '+-');
     m = add_block(m, 'integrator', 'x');
     m = add_block(m, 'outport', 'y', 'Port', 1);
     m = add_line(m, 'u', 's', 1);
     m = add_line(m, 'x', 's', 2);
     m = add_line(m, 's', 'x');
     m = add_line(m, 'x', 'y');
     [xe, ue, ye, dxe] = trim(m, 0, 1, [], [], 1, []);
     abs(xe - 1) < 1e-8                   % l'equilibre de x' = u - x

  Voir aussi LINMOD, DLINMOD, SIM, FSOLVE.
un modèle de la session se désigne aussi par son nom
```

