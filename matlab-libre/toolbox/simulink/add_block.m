function modele = add_block(modele, type, nom, varargin)
%ADD_BLOCK Ajoute un bloc au modèle.
%   MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...)
%
%   Sources — elles n'ont pas d'entrée :
%     constant     Value
%     step         Time, Before, After
%     ramp         Slope
%     sine         Amplitude, Frequency, Phase
%     inport       Port, Value          l'entrée du modèle, vue par LINMOD
%
%   Opérations sans mémoire :
%     gain         Gain
%     bias         Bias
%     sum          Signs (par exemple '+-')
%     product      —                    le produit de toutes ses entrées
%     abs          —
%     sign         —
%     math         Operator : square, sqrt, exp, log, reciprocal
%     trigonometry Operator : sin, cos, tan, asin, acos, atan, atan2,
%                  sinh, cosh, tanh, asinh, acosh, atanh
%     minmax       Function : min ou max, sur toutes les entrées
%     logic        Operator : AND, OR, NAND, NOR, XOR, NXOR, NOT
%     relational   Operator : ==, ~=, <, <=, >, >=
%     switch       Threshold, Criteria : 'u2>=Threshold', 'u2>Threshold',
%                  'u2~=0' — la première entrée passe, ou la troisième
%     saturation   UpperLimit, LowerLimit
%     deadzone     UpperValue, LowerValue
%     quantizer    QuantizationInterval
%     lookup       BreakpointsData, TableData
%     outport      Port                 la sortie du modèle
%
%   Blocs à mémoire — ce sont eux qui coupent les boucles :
%     integrator   InitialCondition
%     delay        InitialCondition     aussi nommé unitdelay
%     memory       InitialCondition     la valeur du pas précédent
%     transportdelay DelayTime, InitialOutput
%     derivative   —                    transmission directe : ne coupe rien
%     relay        OnSwitch, OffSwitch, OnOutput, OffOutput
%     ratelimiter  RisingSlewLimit, FallingSlewLimit, InitialOutput
%     transferfcn  Numerator, Denominator
%     statespace   A, B, C, D, X0
%     pidcontroller P, I, D, N          dérivée filtrée par N/(1+N/s)
%
%   Blocs échantillonnés — ils ne relisent leur entrée qu'à leur période :
%     zoh                  SampleTime   aussi nommé zeroorderhold
%     discreteintegrator   Gain, SampleTime, InitialCondition,
%                          IntegratorMethod : ForwardEuler, BackwardEuler,
%                          Trapezoidal
%     discretetransferfcn  Numerator, Denominator, SampleTime
%     discretestatespace   A, B, C, D, X0, SampleTime
%
%   Passe-plat, pour la lisibilité du schéma : scope, mux, demux,
%   terminator, display, toworkspace, fromworkspace, signalconversion,
%   goto, from.
%
%   Un type inconnu est refusé. Le laisser passer donnerait une
%   simulation qui tourne et un résultat faux.
%
%   Un bloc porte un nom, et c'est par ce nom qu'ADD_LINE le relie : le
%   modèle n'est qu'une liste de blocs et d'arcs, dont SIM tire l'ordre de
%   calcul.
%
%   Tout bloc accepte en outre POSITION, [gauche haut droite bas] comme
%   dans Simulink : il garde alors la place qu'on lui donne, au lieu
%   d'être rangé par couches. C'est ainsi qu'un schéma déplacé à la
%   souris dans l'éditeur du bureau se retient — l'ordonnée y descend,
%   comme sur un écran.
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
%   Le modèle, lui, n'a pas bougé : il porte toujours l'expression, et
%   c'est elle que le schéma affiche. Les paramètres qui sont du texte —
%   Signs, Operator, Criteria, Function, IntegratorMethod, VariableName —
%   restent lus tels quels.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      numel(m.blocs)              % 2
%
%   Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, DELETE_BLOCK, SIM, OPEN_SYSTEM.
    bloc = struct();
    bloc.type = lower(char(type));
    bloc.nom = nom;
    bloc.parametres = struct();
    for k = 1:2:numel(varargin)-1
        bloc.parametres.(char(varargin{k})) = varargin{k+1};
    end
    modele.blocs{end+1} = bloc;
end
