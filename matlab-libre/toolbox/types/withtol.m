classdef withtol
%WITHTOL Sélecteur de lignes d'une table temporelle, à tolérance près.
%   S = WITHTOL(TEMPS,TOLERANCE) désigne les lignes dont l'instant est à
%   moins de TOLERANCE de l'un des instants demandés. On s'en sert comme
%   d'un indice :
%
%      tt(withtol(t, seconds(0.1)), :)
%
%   Sans tolérance, une table temporelle exige l'instant exact, ce qui
%   n'arrive jamais avec des mesures datées par une horloge réelle.
%
%   Exemple :
%      tt = timetable(seconds([1;2;3]), (10:10:30)');
%      s = tt(withtol(seconds(2.05), seconds(0.1)), :);
%      height(s)   % 1
%
%   Voir aussi TIMERANGE, VARTYPE, TIMETABLE.
    properties
        Temps
        Tolerance
    end
    methods
        function w = withtol(temps, tolerance)
            if nargin < 2
                error('MATLAB:withtol:NotEnoughInputs', ...
                      'Il faut des instants et une tolérance.');
            end
            w.Temps = temps;
            w.Tolerance = tolerance;
        end

        function i = lignesRetenues(w, temps)
%LIGNESRETENUES Indices des instants proches de ceux demandés.
            axe = timetable.axe(temps);
            cibles = timetable.axe(w.Temps);
            tol = timetable.axe(w.Tolerance);
            tol = abs(tol(1));
            retenues = false(numel(axe), 1);
            for k = 1:numel(cibles)
                retenues = retenues | (abs(axe - cibles(k)) <= tol + 1e-12);
            end
            i = find(retenues);
            i = i(:);
        end
    end
end
