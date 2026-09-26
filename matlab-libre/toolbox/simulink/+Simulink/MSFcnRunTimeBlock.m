classdef MSFcnRunTimeBlock < handle
%MSFCNRUNTIMEBLOCK Le bloc que reçoit une S-fonction de niveau 2.
%   Une S-fonction de niveau 2 est une fonction MATLAB d'un seul argument,
%   le bloc, qui appelle sa fonction setup. Dans setup, elle dit ce qu'est
%   le bloc et enregistre ses méthodes :
%      block.NumInputPorts, block.NumOutputPorts    ses ports ;
%      block.InputPort(i), block.OutputPort(j)      leurs dimensions (-1 :
%                                                   celles du signal),
%                                                   DirectFeedthrough ;
%      block.NumDialogPrms, block.DialogPrm(i).Data ses paramètres, donnés
%                                                   par le paramètre
%                                                   Parameters du bloc ;
%      block.SampleTimes         [période décalage] : [-1 0] hérite, [0 0]
%                                est continu ;
%      block.NumContStates       ses états continus, dans
%                                block.ContStates.Data ;
%      block.NumDworks, block.Dwork(i)   ses vecteurs de travail, posés
%                                dans PostPropagationSetup ;
%      block.RegBlockMethod(NOM, @f)     une méthode : PostPropagationSetup,
%                                InitializeConditions, Start, Outputs,
%                                Update, Derivatives, Terminate,
%                                CheckParameters.
%   À chaque instant, block.CurrentTime est le temps, block.InputPort(i).Data
%   l'entrée ; Outputs pose block.OutputPort(j).Data, Update les états
%   discrets, Derivatives block.Derivatives.Data.
%
%   C'est ce que le bloc « Level-2 MATLAB S-Function » (ADD_BLOCK, type
%   msfunction) passe à la fonction que nomme son paramètre FunctionName.
%
%   Exemple :
%      b = Simulink.MSFcnRunTimeBlock;
%      b.NumInputPorts = 1;
%      b.NumOutputPorts = 1;
%      b.InputPort(1).DirectFeedthrough = true;
%      b.RegBlockMethod('Outputs', @(blk) disp(blk.CurrentTime));
%
%   Voir aussi SIMULINK.BLOCKPORTDATA, SIMULINK.BLOCKDATA, ADD_BLOCK.
    properties
        NumInputPorts = 0
        NumOutputPorts = 0
        InputPort = []
        OutputPort = []
        NumDialogPrms = 0
        DialogPrm = []
        SampleTimes = [-1 0]
        NumContStates = 0
        ContStates = []
        Derivatives = []
        NumDworks = 0
        Dwork = []
        CurrentTime = 0
        SimStateCompliance = 'DefaultSimState'
        Methodes = struct()
    end
    methods
        function set.NumInputPorts(obj, n)
            n = Simulink.MSFcnRunTimeBlock.compte(n, 'NumInputPorts');
            obj.NumInputPorts = n;
            obj.InputPort = Simulink.MSFcnRunTimeBlock.ports(n);
        end
        function set.NumOutputPorts(obj, n)
            n = Simulink.MSFcnRunTimeBlock.compte(n, 'NumOutputPorts');
            obj.NumOutputPorts = n;
            obj.OutputPort = Simulink.MSFcnRunTimeBlock.ports(n);
        end
        function set.NumContStates(obj, n)
            n = Simulink.MSFcnRunTimeBlock.compte(n, 'NumContStates');
            obj.NumContStates = n;
            obj.ContStates = Simulink.BlockData;
            obj.ContStates.Dimensions = n;
            obj.ContStates.Data = zeros(n, 1);
            obj.Derivatives = Simulink.BlockData;
            obj.Derivatives.Dimensions = n;
            obj.Derivatives.Data = zeros(n, 1);
        end
        function set.NumDworks(obj, n)
            n = Simulink.MSFcnRunTimeBlock.compte(n, 'NumDworks');
            obj.NumDworks = n;
            travail = Simulink.BlockData.empty(0, 1);
            for k = 1:n
                travail(k) = Simulink.BlockData;
            end
            obj.Dwork = travail;
        end
        function RegBlockMethod(obj, nom, poignee)
            if ~(ischar(nom) || isstring(nom)) || ~isa(poignee, 'function_handle')
                error('Simulink:blocks:SFunctionRegBlockMethod', ...
                      'RegBlockMethod prend un nom de methode et une poignee de fonction.');
            end
            obj.Methodes.(char(nom)) = poignee;
        end
        function SetPreCompInpPortInfoToDynamic(obj)
            for k = 1:obj.NumInputPorts
                obj.InputPort(k).Dimensions = -1;
            end
        end
        function SetPreCompOutPortInfoToDynamic(obj)
            for k = 1:obj.NumOutputPorts
                obj.OutputPort(k).Dimensions = -1;
            end
        end
        function SetPreCompPortInfoToDefaults(obj)
            for k = 1:obj.NumInputPorts
                obj.InputPort(k).Dimensions = 1;
                obj.InputPort(k).DatatypeID = 0;
                obj.InputPort(k).Complexity = 'Real';
            end
            for k = 1:obj.NumOutputPorts
                obj.OutputPort(k).Dimensions = 1;
                obj.OutputPort(k).DatatypeID = 0;
                obj.OutputPort(k).Complexity = 'Real';
            end
        end
        function SetAccelRunOnTLC(obj, varargin) %#ok<INUSD>
        end
        function SetSimViewingDevice(obj, varargin) %#ok<INUSD>
        end
        function AutoRegRuntimePrms(obj) %#ok<MANU>
        end
        function AutoUpdateRuntimePrms(obj) %#ok<MANU>
        end
    end
    methods (Static)
        function n = compte(n, nom)
            if ~(isnumeric(n) && isscalar(n) && isreal(n) && n >= 0 && n == round(n))
                error('Simulink:blocks:SFunctionInvalidCount', ...
                      '%s est un entier positif ou nul ; pas %s.', nom, mat2str(n));
            end
            n = double(n);
        end
        function p = ports(n)
            p = Simulink.BlockPortData.empty(0, 1);
            for k = 1:n
                p(k) = Simulink.BlockPortData;
            end
        end
    end
end
