classdef dlnetwork
%DLNETWORK Réseau dont on écrit soi-même la boucle d'apprentissage.
%   NET = DLNETWORK(COUCHES) construit un réseau à partir d'un tableau de
%   cellules de couches, chaînées dans l'ordre donné.
%   NET = DLNETWORK(GRAPHE) part d'un LAYERGRAPH, ce qui autorise les
%   branches et les connexions résiduelles.
%   NET = DLNETWORK(...,EXEMPLE) initialise les poids d'après un exemple
%   de données plutôt que d'après les tailles déclarées.
%
%   Là où TRAINNETWORK mène l'apprentissage de bout en bout, un DLNETWORK
%   laisse la boucle à l'utilisateur : on calcule la perte et ses dérivées
%   par DLFEVAL et DLGRADIENT, puis on avance les poids par le solveur de
%   son choix. C'est ce qu'il faut dès que la perte n'est pas une des
%   pertes prévues, ou que l'apprentissage a plusieurs réseaux en jeu.
%
%   Propriétés :
%      Layers, Names, Connections  - la structure du réseau
%      Learnables                  - table couche, paramètre, valeur
%      State                       - les moyennes glissantes, s'il y en a
%      InputNames, OutputNames     - les couches d'entrée et de sortie
%      Initialized                 - les poids sont-ils tirés
%
%   Méthodes : FORWARD (à l'apprentissage), PREDICT (en prédiction),
%   INITIALIZE, RESETSTATE, PREDICTANDUPDATESTATE, ACTIVATIONS.
%
%   Exemple :
%      net = dlnetwork({featureInputLayer(2), fullyConnectedLayer(8), ...
%                       reluLayer(), fullyConnectedLayer(3), softmaxLayer()});
%      Y = predict(net, dlarray(randn(2, 5), 'CB'));
%
%   Voir aussi DLFEVAL, DLGRADIENT, ADAMUPDATE, LAYERGRAPH, TRAINNETWORK.
    properties
        Layers = {}
        Names = {}
        Connections = []
        Learnables = []
        State = []
        InputNames = {}
        OutputNames = {}
        Initialized = false
    end
    methods
        function obj = dlnetwork(entree, exemple)
            if nargin == 0
                obj.Connections = matlibre_reseau_connexions_vides();
                obj.Learnables = matlibre_reseau_table_vide();
                obj.State = matlibre_reseau_table_vide();
                return
            end
            if isa(entree, 'dlnetwork')
                obj = entree;
                if nargin > 1
                    obj = initialize(obj, exemple);
                end
                return
            end
            if iscell(entree)
                graphe = layerGraph(entree);
            else
                graphe = entree;
            end
            obj.Layers = graphe.Layers;
            obj.Names = graphe.Names;
            obj.Connections = graphe.Connections;
            obj.Learnables = matlibre_reseau_table_vide();
            obj.State = matlibre_reseau_table_vide();
            [obj.InputNames, obj.OutputNames] = matlibre_reseau_bornes(obj);
            if nargin > 1
                obj = initialize(obj, exemple);
            else
                obj = matlibre_reseau_initialiser(obj, {});
            end
        end

        function obj = initialize(obj, varargin)
        %INITIALIZE Tire les poids du réseau.
        %   NET = INITIALIZE(NET,X1,...) initialise les paramètres d'après
        %   les données données en exemple : une couche ne peut tirer ses
        %   poids qu'une fois connue la taille de ce qui l'alimente.
            obj = matlibre_reseau_initialiser(obj, varargin);
        end

        function varargout = forward(obj, varargin)
        %FORWARD Passage avant en régime d'apprentissage.
        %   [Y,ETAT] = FORWARD(NET,X) applique le réseau en laissant agir
        %   l'abandon et en employant les statistiques du lot pour la
        %   normalisation. C'est le passage qu'on dérive.
            [sorties, etat] = matlibre_reseau_avant(obj, varargin, true);
            varargout = matlibre_reseau_sorties(sorties, etat, nargout);
        end

        function varargout = predict(obj, varargin)
        %PREDICT Passage avant en régime de prédiction.
        %   Y = PREDICT(NET,X) applique le réseau sans abandon et avec les
        %   statistiques accumulées : le résultat d'une observation ne
        %   dépend alors d'aucune autre.
            [sorties, etat] = matlibre_reseau_avant(obj, varargin, false);
            varargout = matlibre_reseau_sorties(sorties, etat, nargout);
        end

        function obj = resetState(obj)
        %RESETSTATE Efface les moyennes glissantes du réseau.
            obj.State = matlibre_reseau_table_vide();
        end

        function [obj, varargout] = predictAndUpdateState(obj, varargin)
        %PREDICTANDUPDATESTATE Prédit et conserve l'état mis à jour.
        %   [NET,Y] = PREDICTANDUPDATESTATE(NET,X) rend la prédiction et
        %   le réseau dont l'état a été actualisé.
            [sorties, etat] = matlibre_reseau_avant(obj, varargin, true);
            obj.State = etat;
            varargout = sorties(1:max(nargout - 1, 1));
        end

        function y = activations(obj, X, couche)
        %ACTIVATIONS Sortie d'une couche intermédiaire.
        %   Y = ACTIVATIONS(NET,X,COUCHE) rend ce que produit la couche
        %   nommée. C'est par là qu'on inspecte ce qu'un réseau a appris,
        %   ou qu'on s'en sert comme extracteur de caractéristiques.
            y = matlibre_reseau_activation(obj, X, couche);
        end

        function disp(obj)
            fprintf('  dlnetwork : %d couches', numel(obj.Layers));
            if obj.Initialized
                fprintf(', %d paramètres appris\n', height(obj.Learnables));
            else
                fprintf(', non initialisé\n');
            end
        end
    end
end
