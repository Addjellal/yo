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
%     from         GotoTag                      le signal d'un Goto
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
%     sqrt         Operator : sqrt, signedSqrt, rSqrt
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
%     lookup       BreakpointsData, TableData, InterpMethod, ExtrapMethod
%     lookup2d     BreakpointsForDimension1, BreakpointsForDimension2, Table
%
%   Logique :
%     logic        Operator : AND, OR, NAND, NOR, XOR, NXOR, NOT ; Inputs
%     relational   Operator : ==, ~=, <, <=, >=, >
%     comparetoconstant relop, const ; comparetozero relop
%     detectchange, detectincrease, detectdecrease  vinit
%
%   Aiguillage :
%     switch       Threshold, Criteria : 'u2 >= Threshold', 'u2 > Threshold',
%                  'u2 ~= 0' — la première entrée passe, ou la troisième
%     multiportswitch Inputs, DataPortOrder
%     mux          Inputs (un nombre, ou les largeurs)
%     demux        Outputs (un nombre, ou les largeurs)
%     selector     Indices
%     concatenate  NumInputs, Mode, ConcatenateDimension
%     reshape      OutputDimensionality, OutputDimensions
%     goto         GotoTag, TagVisibility : local, scoped, global
%     signalconversion  —
%
%   Continu — l'intégrateur et les représentations d'état coupent les
%   boucles :
%     integrator   InitialCondition, LimitOutput, UpperSaturationLimit,
%                  LowerSaturationLimit
%     derivative   —                            vaut zéro au premier pas
%     transferfcn  Numerator, Denominator
%     statespace   A, B, C, D, X0
%     zeropole     Zeros, Poles, Gain
%     transportdelay DelayTime, InitialOutput
%     pidcontroller P, I, D, N                  dérivée filtrée par N/(1+N/s)
%
%   Discret — ils ne calculent qu'aux instants de leur période :
%     delay        InitialCondition, DelayLength, SampleTime ; aussi
%                  nommé unitdelay
%     memory       InitialCondition             la valeur du pas précédent
%     zoh          SampleTime (dix pas par défaut)
%     discreteintegrator Gain, SampleTime, InitialCondition,
%                  IntegratorMethod : ForwardEuler, BackwardEuler, Trapezoidal
%     discretetransferfcn Numerator, Denominator (puissances de z),
%                  SampleTime
%     discretefilter Numerator, Denominator (puissances de z^-1), SampleTime
%     discretestatespace A, B, C, D, X0, SampleTime
%
%   Sorties :
%     outport      Port                         la sortie du modèle
%     scope        NumInputPorts ; display ; terminator
%     toworkspace  VariableName, SaveFormat : Array, Structure With Time,
%                  Structure
%     stopsimulation — arrête la simulation dès que l'entrée n'est plus nulle
%     assertion    Enabled, StopWhenAssertionFail — échoue dès que
%                  l'entrée s'annule
%
%   Un schéma dans un bloc :
%     subsystem    Model                un modèle entier, abrégé en un bloc
%
%   Le sous-système porte le modèle qu'il abrège, bâti comme les autres
%   par NEW_SYSTEM. Ses blocs INPORT sont ses entrées et ses blocs OUTPORT
%   ses sorties, dans l'ordre de leur paramètre Port. SIM le déplie avant
%   de simuler : le résultat est exactement celui du schéma écrit à plat.
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
    entree = matlibre_sl_catalogue('type', type);
    nom = char(nom);
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

function oui = existe(modele, nom)
    oui = false;
    for i = 1:numel(modele.blocs)
        if strcmp(modele.blocs{i}.nom, nom)
            oui = true;
            return
        end
    end
end
