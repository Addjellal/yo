classdef idfrd
%IDFRD Réponse fréquentielle mesurée.
%   M = IDFRD(REPONSE,FREQUENCE,TS) range une réponse fréquentielle
%   estimée : un nombre complexe par fréquence. C'est ce que rendent SPA
%   et ETFE.
%
%   Un modèle de réponse fréquentielle ne suppose aucune structure : il ne
%   dit pas combien de pôles a le système, seulement ce qu'il fait à
%   chaque fréquence. C'est ce qui en fait le premier regard qu'on porte
%   sur des données, avant de choisir un ordre.
%
%   Propriétés : ResponseData, Frequency, Ts, SpectrumData, CovarianceData.
%
%   Exemple :
%      g = spa(z);
%      bode(g);
%
%   Voir aussi SPA, ETFE, IDTF, IDPOLY.
    properties
        ResponseData = []
        Frequency = []
        Ts = 1
        SpectrumData = []
        CovarianceData = []
        Name = ''
        Report = []
    end
    methods
        function obj = idfrd(reponse, frequence, periode)
            if nargin == 0
                return
            end
            if isa(reponse, 'idfrd')
                obj = reponse;
                return
            end
            obj.ResponseData = reponse(:);
            if nargin > 1
                obj.Frequency = double(frequence(:));
            end
            if nargin > 2
                obj.Ts = periode;
            end
        end

        function [amplitude, phase, frequence] = bode(obj, varargin)
        %BODE Amplitude et phase de la réponse mesurée.
            amplitude = abs(obj.ResponseData);
            phase = unwrap(angle(obj.ResponseData)) * 180 / pi;
            frequence = obj.Frequency;
            if nargout == 0
                matlibre_id_tracer_frequentiel(frequence, amplitude, phase);
            end
        end

        function h = plot(obj, varargin)
        %PLOT Trace la réponse en amplitude et en phase.
            bode(obj);
            h = gcf();
        end

        function reponse = freqresp(obj, frequence)
        %FREQRESP Réponse interpolée aux fréquences demandées.
            if nargin < 2
                reponse = obj.ResponseData;
                return
            end
            reponse = interp1(obj.Frequency, obj.ResponseData, frequence(:), ...
                              'linear', 'extrap');
        end

        function disp(obj)
            fprintf('  Réponse fréquentielle mesurée : %d fréquences, Ts = %g\n', ...
                    numel(obj.Frequency), obj.Ts);
        end
    end
end
