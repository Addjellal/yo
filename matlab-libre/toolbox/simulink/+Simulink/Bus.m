classdef Bus
%BUS Un type de bus : la liste nommée de ses éléments.
%   B = SIMULINK.BUS crée un type de bus sans élément. Ses éléments, des
%   SIMULINK.BUSELEMENT, vont dans B.Elements. Rangé dans l'espace de
%   travail de base sous un nom — « Capteurs » —, il se donne à un bloc par
%   son paramètre OutDataTypeStr, 'Bus: Capteurs' :
%      Bus Creator   le bus prend les noms des éléments du type, et chaque
%                    entrée doit en avoir les dimensions
%      Inport        l'entrée du modèle, ou du sous-système, est un bus de
%                    ce type
%      Outport       la sortie doit être un bus de ce type
%   Un élément dont DataType vaut 'Bus: Y' est un bus emboîté, de type Y.
%   Un type qui manque, ou qui ne s'accorde pas au signal, est refusé par
%   une erreur Simulink:Bus:… qui nomme le bloc.
%
%   S = SIMULINK.BUS.CREATEMATLABSTRUCT(TYPE) rend la structure qui a la
%   forme du bus : un champ par élément, fait de zéros à ses dimensions,
%   une structure pour un bus emboîté. TYPE est le nom du type, ou l'objet.
%
%   INFO = SIMULINK.BUS.CREATEOBJECT(MODELE,BLOC) crée, dans l'espace de
%   travail de base, le type du bus que forme le Bus Creator BLOC du
%   modèle — slBus1, puis slBus2 pour un bus emboîté —, et rend dans
%   INFO.busName le nom du type créé.
%
%   Exemple :
%      e(1) = Simulink.BusElement;
%      e(1).Name = 'position';
%      e(2) = Simulink.BusElement;
%      e(2).Name = 'vitesse';
%      e(2).Dimensions = 2;
%      Capteurs = Simulink.Bus;
%      Capteurs.Elements = e;
%      s = Simulink.Bus.createMATLABStruct(Capteurs);
%      size(s.vitesse)                  % 2 1
%
%   Voir aussi SIMULINK.BUSELEMENT, ADD_BLOCK, SIM.
    properties
        Description = ''
        DataScope = 'Auto'
        HeaderFile = ''
        Alignment = -1
        PreserveElementDimensions = false
        Elements = []
    end
    methods (Static)
        function s = createMATLABStruct(type)
            if ischar(type) || isstring(type)
                objet = matlibre_sl_bus('objet', char(type), 'Simulink.Bus.createMATLABStruct');
            else
                objet = type;
            end
            s = matlibre_sl_bus('structure', objet);
        end
        function info = createObject(modele, blocs)
            info = matlibre_sl_bus('creer', modele, blocs);
        end
    end
end
