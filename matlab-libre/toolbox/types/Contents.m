% Types de données — durées, dates, catégories, tables.
%
% Ces classes complètent les types natifs du langage. Elles s'appuient sur
% « subsref » et « subsasgn », que l'interpréteur route vers la classe,
% comme le décrit la documentation MathWorks. À l'intérieur d'une méthode,
% l'indexation reste celle du langage : c'est la règle de MATLAB.
%
% Classes
%   duration          - Durée, stockée en secondes
%   calendarDuration  - Durée de calendrier (mois, jours, temps)
%   datetime          - Date et heure, numéro de série compatible datenum
%   categorical       - Valeurs prises dans un ensemble fini
%   table             - Tableau à colonnes nommées et hétérogènes
%   timetable         - Table indexée par un axe de temps
%
% Durées
%   seconds, minutes, hours, days, years, milliseconds - construction et
%                       extraction ; le format d'affichage suit l'unité
%   isduration        - Test de type
%
% Durées de calendrier
%   caldays, calweeks, calmonths, calquarters, calyears - construction et
%                       extraction
%   time              - Partie horaire, sous forme de duration
%   iscalendarduration - Test de type
%
% Dates
%   NaT               - Date manquante
%   isdatetime, isnat - Tests
%   year, month, day, hour, minute, second - composantes (méthodes)
%   quarter, week, weekday, isweekend, ymd, hms, timeofday - dérivées
%   dateshift, between, caldiff, isbetween - déplacements et écarts
%   datenum, datevec, datestr, posixtime, exceltime, juliandate - conversions
%
% Catégories
%   categories, iscategory, addcats, removecats, mergecats, renamecats,
%   reordercats, setcats, countcats, isundefined, isordinal - méthodes
%   iscategorical     - Test de type
%
% Tables
%   array2table, cell2table, struct2table - construction
%   table2array, table2cell, table2struct - conversion
%   readtable, writetable                 - fichiers délimités
%   istable, height, width                - inspection
%   head, tail, sortrows, summary         - exploration
%   addvars, removevars, movevars, renamevars, convertvars - variables
%   varfun, rowfun, groupsummary          - calculs, groupés ou non
%   join, innerjoin, outerjoin            - jointures par clé
%
% Tables temporelles
%   table2timetable, timetable2table - conversions
%   retime, synchronize              - ré-échantillonnage et réunion
%   isregular, istimetable           - inspection
%
% Outils internes
%   appliquerReste, assignerReste - application d'une chaîne d'indexation
%                       restante, partagée par tous les subsref/subsasgn
