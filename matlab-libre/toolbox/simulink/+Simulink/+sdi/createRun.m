function [id, rang, signaux] = createRun(nom, source, varargin)
%CREATERUN Crée un run du Simulation Data Inspector.
%   ID = SIMULINK.SDI.CREATERUN(NOM,'vars',V1,V2,...) range dans un run
%   nommé NOM les signaux des variables : un timeseries, un
%   Simulink.SimulationData.Dataset (chacun de ses éléments), un
%   Simulink.SimulationOutput (ses Dataset, ses timeseries, ses matrices
%   relevées avec tout), une structure avec temps, ou une matrice dont la
%   première colonne est le temps. SIMULINK.SDI.CREATERUN(NOM,'namevalue',
%   NOMS,VALEURS), (NOM,'base',NOMS) et (NOM,'file',FICHIER) les prennent
%   autrement. SIMULINK.SDI.CREATERUN(NOM) crée un run vide.
%   [ID,RANG,SIGNAUX] = ... rend aussi son rang et les identifiants de ses
%   signaux.
%
%   Exemple :
%      ts = timeseries(sin((0:0.1:1)'), 0:0.1:1, 'Name', 'sinus');
%      id = Simulink.sdi.createRun('premier', 'vars', ts);
%      Simulink.sdi.getRun(id).SignalCount   % 1
%      Simulink.sdi.deleteRun(id);
%
%   Voir aussi SIMULINK.SDI.GETRUN, SIMULINK.SDI.COMPARERUNS, SIMULINK.SDI.RUN.
    if nargin < 1
        nom = '';
    end
    if ~(ischar(nom) || (isstring(nom) && isscalar(nom)))
        error('SDI:sdi:InvalidRunName', 'Le nom d''un run est un texte.');
    end
    noms = {};
    valeurs = {};
    if nargin >= 2
        premier = '';
        if strcmpi(char(source), 'vars') && nargin >= 3
            premier = inputname(3);
        end
        [noms, valeurs] = matlibre_sdi_sources(source, varargin, premier);
        if strcmpi(char(source), 'vars')
            for k = 2:numel(varargin)
                n = inputname(k + 2);
                if ~isempty(n)
                    noms{k} = n;
                end
            end
        end
    end
    id = matlibre_sdi('creer', char(nom));
    signaux = matlibre_sdi('ajouter', id, noms, valeurs);
    signaux = signaux(:);
    rang = find(matlibre_sdi('runs') == id, 1);
end
