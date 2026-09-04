classdef creditscorecard
%CREDITSCORECARD Grille de score de crédit.
%   SC = CREDITSCORECARD(DONNEES,'IDVar',I,'ResponseVar',R) construit une
%   grille à partir d'un tableau d'observations : une ligne par
%   emprunteur, une colonne par caractéristique, et une colonne qui dit
%   s'il a fait défaut.
%
%   Une grille de score est une régression logistique déguisée en
%   barème. Chaque caractéristique est découpée en tranches ; chaque
%   tranche reçoit un poids tiré du rapport entre bons et mauvais
%   dossiers qu'elle contient — le « poids de la preuve » —, puis une
%   régression pèse les caractéristiques entre elles. Les coefficients
%   sont enfin traduits en points, de sorte qu'un opérateur puisse
%   additionner sans calculer d'exponentielle.
%
%   Le chemin habituel : AUTOBINNING découpe, BININFO montre le
%   découpage, FITMODEL ajuste, FORMATPOINTS choisit l'échelle,
%   DISPLAYPOINTS écrit le barème, SCORE note un dossier, PROBDEFAULT en
%   donne la probabilité de défaut et VALIDATEMODEL mesure le pouvoir
%   discriminant.
%
%   Les options : 'PredictorVars' limite les caractéristiques retenues,
%   'GoodLabel' dit quelle valeur de la réponse désigne un bon dossier
%   (la plus fréquente par défaut), 'WeightsVar' pondère les
%   observations, 'BinMissingData' traite les valeurs manquantes comme
%   une tranche.
%
%   Exemple :
%      sc = creditscorecard(donnees, 'IDVar', 'id', 'ResponseVar', 'defaut');
%      sc = autobinning(sc);
%      sc = fitmodel(sc);
%      sc = formatpoints(sc, 'PointsOddsAndPDO', [500 2 50]);
%      displaypoints(sc)
%
%   Voir aussi BININFO, BINDATA, FITMODEL, DISPLAYPOINTS, FORMATPOINTS,
%   SCORE, PROBDEFAULT, VALIDATEMODEL.
    properties
        Data = []
        IDVar = ''
        ResponseVar = ''
        PredictorVars = {}
        GoodLabel = []
        WeightsVar = ''
        BinMissingData = false
        Bins = {}
        ModelVars = {}
        ModelCoefficients = []
        Shift = 0
        Slope = 1
        Fitted = []
    end

    methods
        function obj = creditscorecard(donnees, varargin)
            if nargin == 0
                return
            end
            obj.Data = matlibre_score_colonnes(donnees);
            noms = fieldnames(obj.Data);
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'idvar',          obj.IDVar = char(varargin{k+1});
                    case 'responsevar',    obj.ResponseVar = char(varargin{k+1});
                    case 'predictorvars'
                        valeur = varargin{k+1};
                        if ischar(valeur) || isstring(valeur)
                            obj.PredictorVars = {char(valeur)};
                        else
                            obj.PredictorVars = valeur(:).';
                        end
                    case 'goodlabel',      obj.GoodLabel = varargin{k+1};
                    case 'weightsvar',     obj.WeightsVar = char(varargin{k+1});
                    case 'binmissingdata', obj.BinMissingData = logical(varargin{k+1});
                    otherwise
                        error('risque:creditscorecard:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            if isempty(obj.ResponseVar)
                obj.ResponseVar = noms{end};
            end
            if isempty(obj.PredictorVars)
                exclues = {obj.IDVar, obj.ResponseVar, obj.WeightsVar};
                obj.PredictorVars = noms(~ismember(noms, exclues)).';
            end
            reponse = obj.Data.(obj.ResponseVar);
            if isempty(obj.GoodLabel)
                obj.GoodLabel = matlibre_score_etiquette(reponse);
            end
        end
    end
end
