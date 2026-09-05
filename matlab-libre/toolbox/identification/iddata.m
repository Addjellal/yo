classdef iddata
%IDDATA Jeu de données entrée-sortie pour l'identification.
%   Z = IDDATA(Y,U,TS) range les mesures : une colonne par sortie dans Y,
%   une par entrée dans U, et la période d'échantillonnage TS. C'est
%   l'objet que prennent tous les estimateurs.
%
%   Z = IDDATA(Y) décrit une série sans entrée, comme en attend AR.
%   Z = IDDATA(Y,U,TS,'Name',VALEUR,...) nomme le jeu, ses voies ou son
%   instant de départ ('Name', 'OutputName', 'InputName', 'Tstart',
%   'TimeUnit', 'ExperimentName').
%
%   Plusieurs expériences se rangent dans un même objet : MERGE les
%   assemble, et les estimateurs les traitent ensemble — ce qui vaut mieux
%   que d'estimer sur chacune et de moyenner, puisque le bruit ne se
%   raccorde pas d'une expérience à l'autre.
%
%   Propriétés : OutputData, InputData, Ts, Tstart, TimeUnit, Name,
%   OutputName, InputName, ExperimentName ; et, en abrégé, y, u et N.
%
%   Ce qu'on lui fait : DETREND retire la moyenne ou la tendance, RETREND
%   la remet, RESAMPLE change la cadence, MISDATA remplace les données
%   manquantes, NKSHIFT décale l'entrée, MERGE assemble des expériences,
%   PLOT trace.
%
%   Exemple :
%      t = (0:0.1:20)';
%      u = sign(sin(t));
%      y = filter(0.2, [1 -0.8], u);
%      z = iddata(y, u, 0.1);
%      m = arx(z, [1 1 1]);
%
%   Voir aussi ARX, ARMAX, OE, BJ, N4SID, COMPARE, RESID.
    properties
        OutputData = []
        InputData = []
        Ts = 1
        Tstart = 0
        TimeUnit = 'seconds'
        Name = ''
        OutputName = {}
        InputName = {}
        ExperimentName = {}
    end
    properties (Dependent)
        y
        u
        N
    end
    methods
        function obj = iddata(sortie, entree, periode, varargin)
            if nargin == 0
                return
            end
            if isa(sortie, 'iddata')
                obj = sortie;
                return
            end
            if nargin < 2
                entree = [];
            end
            if nargin < 3 || isempty(periode)
                periode = 1;
            end
            obj.OutputData = matlibre_id_colonnes(sortie);
            obj.InputData = matlibre_id_colonnes(entree);
            obj.Ts = double(periode);
            for k = 1:2:numel(varargin) - 1
                nom = matlibre_id_propriete(char(varargin{k}));
                obj.(nom) = varargin{k + 1};
            end
            obj = matlibre_id_nommer(obj);
        end

        function v = get.y(obj), v = obj.OutputData; end
        function v = get.u(obj), v = obj.InputData; end
        function v = get.N(obj)
            v = matlibre_id_longueurs(obj.OutputData);
            if numel(v) == 1
                v = v(1);
            end
        end

        function varargout = size(obj, dimension)
        %SIZE Nombre d'échantillons, de sorties et d'entrées.
            taille = [matlibre_id_longueurs(obj.OutputData), ...
                      matlibre_id_voies(obj.OutputData), ...
                      matlibre_id_voies(obj.InputData)];
            if nargin > 1
                varargout{1} = taille(dimension);
            elseif nargout <= 1
                varargout{1} = taille;
            else
                for k = 1:nargout
                    varargout{k} = taille(min(k, numel(taille)));
                end
            end
        end

        function n = numel(obj), n = 1; end                          %#ok<MANU>
        function n = nexp(obj)
        %NEXP Nombre d'expériences que porte le jeu.
            if iscell(obj.OutputData)
                n = numel(obj.OutputData);
            else
                n = 1;
            end
        end

        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                sortie = matlibre_id_extraire(obj, s(1).subs);
                if numel(s) > 1
                    [varargout{1:nargout}] = subsref(sortie, s(2:end));
                else
                    varargout{1} = sortie;
                end
            else
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end

        function z = getexp(obj, indice)
        %GETEXP Une expérience d'un jeu qui en porte plusieurs.
            z = matlibre_id_experience(obj, indice);
        end

        function [z, moyennes] = detrend(obj, ordre)
        %DETREND Retire la moyenne, ou la tendance, des voies.
        %   Z = DETREND(Z) retire la moyenne de chaque voie ; DETREND(Z,1)
        %   retire une droite ajustée aux moindres carrés.
            if nargin < 2
                ordre = 0;
            end
            [z, moyennes] = matlibre_id_detendre(obj, ordre);
        end

        function z = retrend(obj, tendance)
        %RETREND Remet une tendance retirée par DETREND.
            z = matlibre_id_retendre(obj, tendance);
        end

        function z = resample(obj, p, q)
        %RESAMPLE Change la cadence d'échantillonnage.
        %   Z = RESAMPLE(Z,P,Q) rééchantillonne dans le rapport P sur Q.
            if nargin < 3
                q = 1;
            end
            z = matlibre_id_reechantillonner(obj, p, q);
        end

        function z = misdata(obj)
        %MISDATA Remplace les données manquantes.
        %   Les valeurs NaN sont reconstruites par interpolation, puis par
        %   prolongement aux bords : un estimateur ne sait pas quoi faire
        %   d'un trou, et l'écarter romprait la suite temporelle.
            z = matlibre_id_completer(obj);
        end

        function z = nkshift(obj, decalage)
        %NKSHIFT Décale l'entrée par rapport à la sortie.
        %   Z = NKSHIFT(Z,NK) avance l'entrée de NK échantillons, ce qui
        %   retire un retard connu avant l'estimation.
            z = matlibre_id_decaler(obj, decalage);
        end

        function z = merge(varargin)
        %MERGE Assemble plusieurs jeux en autant d'expériences.
            z = matlibre_id_fusionner(varargin);
        end

        function h = plot(obj, varargin)
        %PLOT Trace les sorties et les entrées.
            h = matlibre_id_tracer(obj, varargin);
        end

        function disp(obj)
            taille = size(obj);
            if nexp(obj) > 1
                fprintf('  iddata : %d expériences, %d sorties, %d entrées, Ts = %g\n', ...
                        nexp(obj), taille(2), taille(3), obj.Ts);
            else
                fprintf('  iddata : %d échantillons, %d sorties, %d entrées, Ts = %g\n', ...
                        taille(1), taille(2), taille(3), obj.Ts);
            end
        end
    end
end
