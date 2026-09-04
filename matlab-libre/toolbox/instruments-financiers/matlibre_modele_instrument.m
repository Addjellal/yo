function [champs, classes] = matlibre_modele_instrument(type)
%MATLIBRE_MODELE_INSTRUMENT Champs attendus par un type d'instrument.
%   Les noms et l'ordre sont ceux de MATLAB : c'est dans cet ordre que
%   INSTADD prend ses arguments.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    switch lower(type)
        case 'bond'
            champs = {'CouponRate', 'Settle', 'Maturity', 'Period', 'Basis', ...
                      'EndMonthRule', 'IssueDate', 'FirstCouponDate', ...
                      'LastCouponDate', 'StartDate', 'Face'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'cashflow'
            champs = {'CFlowAmounts', 'CFlowDates', 'Settle', 'Basis'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'fixed'
            champs = {'CouponRate', 'Settle', 'Maturity', 'Reset', 'Basis', ...
                      'Principal', 'EndMonthRule'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'float'
            champs = {'Spread', 'Settle', 'Maturity', 'Reset', 'Basis', ...
                      'Principal', 'EndMonthRule'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'swap'
            champs = {'LegRate', 'Settle', 'Maturity', 'LegReset', 'Basis', ...
                      'Principal', 'LegType', 'EndMonthRule'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'optstock'
            champs = {'OptSpec', 'Strike', 'Settle', 'ExerciseDates', 'AmericanOpt'};
            classes = {'char', 'dble', 'dble', 'dble', 'dble'};
        case 'barrier'
            champs = {'OptSpec', 'Strike', 'Settle', 'ExerciseDates', 'AmericanOpt', ...
                      'BarrierSpec', 'Barrier', 'Rebate'};
            classes = {'char', 'dble', 'dble', 'dble', 'dble', 'char', 'dble', 'dble'};
        case 'lookback'
            champs = {'OptSpec', 'Strike', 'Settle', 'ExerciseDates', 'AmericanOpt'};
            classes = {'char', 'dble', 'dble', 'dble', 'dble'};
        case 'asian'
            champs = {'OptSpec', 'Strike', 'Settle', 'ExerciseDates', 'AmericanOpt', ...
                      'AvgType', 'AvgPrice', 'AvgDate'};
            classes = {'char', 'dble', 'dble', 'dble', 'dble', 'char', 'dble', 'dble'};
        case 'cap'
            champs = {'Strike', 'Settle', 'Maturity', 'Reset', 'Basis', 'Principal'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'floor'
            champs = {'Strike', 'Settle', 'Maturity', 'Reset', 'Basis', 'Principal'};
            classes = repmat({'dble'}, 1, numel(champs));
        case 'swaption'
            champs = {'OptSpec', 'Strike', 'ExerciseDates', 'Spread', 'Settle', ...
                      'Maturity', 'AmericanOpt', 'Reset', 'Basis', 'Principal'};
            classes = {'char', 'dble', 'dble', 'dble', 'dble', 'dble', 'dble', ...
                       'dble', 'dble', 'dble'};
        otherwise
            champs = {};
            classes = {};
    end
end
