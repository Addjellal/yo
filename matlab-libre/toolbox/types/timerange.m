classdef timerange
%TIMERANGE Sélecteur de lignes d'une table temporelle, par intervalle.
%   S = TIMERANGE(DEBUT,FIN) désigne les lignes dont l'instant tombe dans
%   [DEBUT, FIN[. On s'en sert comme d'un indice :
%
%      tt(timerange(d1, d2), :)
%
%   S = TIMERANGE(DEBUT,FIN,TYPE) où TYPE vaut 'openright' (défaut),
%   'openleft', 'open' ou 'closed' choisit quelles bornes sont incluses.
%
%   L'intérêt est de ne pas avoir à connaître les instants exacts : on
%   décrit une période, et la table rend les lignes qui y tombent.
%
%   Exemple :
%      tt = timetable(seconds([1;2;3;4]), (10:10:40)');
%      s = tt(timerange(seconds(2), seconds(4)), :);
%      height(s)   % 2 : les instants 2 et 3
%
%   Voir aussi WITHTOL, VARTYPE, TIMETABLE.
    properties
        Debut
        Fin
        Type = 'openright'
    end
    methods
        function r = timerange(debut, fin, type)
            if nargin < 2
                error('MATLAB:timerange:NotEnoughInputs', ...
                      'Il faut un début et une fin.');
            end
            if nargin >= 3 && ~isempty(type)
                type = lower(char(type));
                if ~any(strcmp(type, {'openright', 'openleft', 'open', 'closed'}))
                    error('MATLAB:timerange:BadType', ...
                          'Le type doit être ''openright'', ''openleft'', ''open'' ou ''closed''.');
                end
                r.Type = type;
            end
            r.Debut = debut;
            r.Fin = fin;
        end

        function i = lignesRetenues(r, temps)
%LIGNESRETENUES Indices des instants de TEMPS qui tombent dans l'intervalle.
            axe = timetable.axe(temps);
            d = timetable.axe(r.Debut);
            f = timetable.axe(r.Fin);
            switch r.Type
                case 'closed',   dans = axe >= d(1) & axe <= f(1);
                case 'open',     dans = axe >  d(1) & axe <  f(1);
                case 'openleft', dans = axe >  d(1) & axe <= f(1);
                otherwise,       dans = axe >= d(1) & axe <  f(1);
            end
            i = find(dans);
            i = i(:);
        end
    end
end
