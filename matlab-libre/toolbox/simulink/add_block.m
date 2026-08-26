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
    bloc = struct();
    bloc.type = lower(char(type));
    bloc.nom = nom;
    bloc.parametres = struct();
    for k = 1:2:numel(varargin)-1
        bloc.parametres.(char(varargin{k})) = varargin{k+1};
    end
    modele.blocs{end+1} = bloc;
end
