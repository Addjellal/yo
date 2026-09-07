function modele = add_block(modele, type, nom, varargin)
%ADD_BLOCK Ajoute un bloc au modèle.
%   MODELE = ADD_BLOCK(MODELE,TYPE,NOM,'Param',VALEUR,...)
%
%   Paramètres reconnus selon le type :
%     constant     Value
%     step         Time, Before, After
%     ramp         Slope
%     sine         Amplitude, Frequency, Phase
%     gain         Gain
%     sum          Signs (par exemple '+-')
%     integrator   InitialCondition
%     transferfcn  Numerator, Denominator
%     statespace   A, B, C, D, X0
%     saturation   UpperLimit, LowerLimit
%     delay        InitialCondition
%     relay        OnSwitch, OffSwitch, OnOutput, OffOutput
%
%   Un bloc porte un nom, et c'est par ce nom qu'ADD_LINE le relie : le
%   modèle n'est qu'une liste de blocs et d'arcs, dont SIM tire l'ordre de
%   calcul.
%
%   Exemple :
%      m = new_system('rampe');
%      m = add_block(m, 'constant', 'un', 'Value', 2);
%      m = add_block(m, 'integrator', 'integ', 'InitialCondition', 0);
%      numel(m.blocs)              % 2
%
%   Voir aussi NEW_SYSTEM, ADD_LINE, SET_PARAM, SIM, SIMPLOT.
    bloc = struct();
    bloc.type = lower(char(type));
    bloc.nom = nom;
    bloc.parametres = struct();
    for k = 1:2:numel(varargin)-1
        bloc.parametres.(char(varargin{k})) = varargin{k+1};
    end
    modele.blocs{end+1} = bloc;
end
