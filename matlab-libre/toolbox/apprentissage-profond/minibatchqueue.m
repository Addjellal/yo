classdef minibatchqueue < handle
%MINIBATCHQUEUE Découpe des données en lots successifs.
%   MBQ = MINIBATCHQUEUE(X1,X2,...) range les données et les rend par
%   lots. La dernière dimension de chaque tableau compte les observations,
%   et tous doivent en avoir le même nombre.
%
%   L'apprentissage d'un réseau ne présente pas tout le jeu de données à
%   la fois : il avance par petits lots, ce qui tient en mémoire, donne
%   plusieurs pas de descente par passage, et introduit un bruit qui aide
%   à sortir des minimums étroits. Cet objet tient le compte des
%   observations déjà servies et de l'ordre de tirage.
%
%   Options et valeurs par défaut :
%     'MiniBatchSize'      128
%     'MiniBatchFormat'    le format à donner à chaque sortie, par exemple
%                          {'CB','CB'} ; vide rend des tableaux ordinaires
%     'PartialMiniBatch'   'return', ou 'discard' pour ignorer le dernier
%                          lot quand il est incomplet
%
%   Méthodes : HASDATA dit s'il reste des lots, NEXT rend le suivant,
%   SHUFFLE retire l'ordre au hasard, RESET revient au début.
%
%   MATLAB part d'un magasin de données ; MatLibre accepte directement les
%   tableaux, ce qui revient au même pour des données qui tiennent en
%   mémoire.
%
%   Exemple :
%      mbq = minibatchqueue(randn(3, 100), randn(2, 100), ...
%                           'MiniBatchSize', 16, 'MiniBatchFormat', {'CB', ''});
%      while hasdata(mbq)
%          [X, T] = next(mbq);
%      end
%
%   Voir aussi DLNETWORK, DLFEVAL, ADAMUPDATE.
    properties
        MiniBatchSize = 128
        MiniBatchFormat = {}
        PartialMiniBatch = 'return'
        NumObservations = 0
    end
    properties (Access = private)
        Donnees = {}
        Ordre = []
        Position = 1
    end
    methods
        function obj = minibatchqueue(varargin)
            donnees = {};
            k = 1;
            while k <= numel(varargin)
                if ischar(varargin{k})
                    break
                end
                donnees{end + 1} = varargin{k};     %#ok<AGROW>
                k = k + 1;
            end
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'minibatchsize'
                        obj.MiniBatchSize = round(double(varargin{k + 1}));
                    case 'minibatchformat'
                        obj.MiniBatchFormat = varargin{k + 1};
                    case 'partialminibatch'
                        obj.PartialMiniBatch = lower(char(varargin{k + 1}));
                    case 'minibatchfcn'
                        % La transformation d'un lot n'est pas fournie :
                        % les données sont déjà en mémoire.
                    otherwise
                        error('nnet:minibatchqueue:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            if isempty(donnees)
                error('nnet:minibatchqueue:Donnees', 'Aucune donnée fournie.');
            end
            obj.Donnees = donnees;
            obj.NumObservations = matlibre_dl_nombre_observations(donnees{1});
            for j = 2:numel(donnees)
                if matlibre_dl_nombre_observations(donnees{j}) ~= obj.NumObservations
                    error('nnet:minibatchqueue:Effectifs', ...
                          'Tous les tableaux doivent avoir le même nombre d''observations.');
                end
            end
            reset(obj);
        end

        function reset(obj)
        %RESET Revient au premier lot, dans l'ordre d'origine.
            obj.Ordre = 1:obj.NumObservations;
            obj.Position = 1;
        end

        function shuffle(obj)
        %SHUFFLE Retire l'ordre des observations au hasard.
            obj.Ordre = randperm(obj.NumObservations);
            obj.Position = 1;
        end

        function v = hasdata(obj)
        %HASDATA Reste-t-il un lot à servir ?
            reste = obj.NumObservations - obj.Position + 1;
            if strcmp(obj.PartialMiniBatch, 'discard')
                v = reste >= obj.MiniBatchSize;
            else
                v = reste > 0;
            end
        end

        function varargout = next(obj)
        %NEXT Lot suivant.
            if ~hasdata(obj)
                error('nnet:minibatchqueue:Fin', 'Il ne reste aucun lot.');
            end
            fin = min(obj.Position + obj.MiniBatchSize - 1, obj.NumObservations);
            choisies = obj.Ordre(obj.Position:fin);
            obj.Position = fin + 1;
            varargout = cell(1, max(nargout, 1));
            for k = 1:numel(varargout)
                lot = matlibre_dl_extraire_observations(obj.Donnees{k}, choisies);
                format = '';
                if numel(obj.MiniBatchFormat) >= k
                    format = char(obj.MiniBatchFormat{k});
                end
                if ~isempty(format)
                    lot = dlarray(lot, format);
                end
                varargout{k} = lot;
            end
        end
    end
end
