function options = evalfisOptions(varargin)
%EVALFISOPTIONS Options d'une inférence floue.
%   O = EVALFISOPTIONS rend les réglages par défaut d'EVALFIS :
%     NumSamplePoints        points de la grille de défuzzification, 101
%     OutOfRangeInputValueMessage  ce qu'on fait d'une entrée hors
%                            intervalle : 'warning' (défaut), 'error' ou
%                            'none'
%     NoRuleFiredMessage     ce qu'on fait quand aucune règle ne
%                            s'applique
%     EmptyOutputFuzzySetMessage  de même pour un ensemble de sortie vide
%
%   Exemple :
%      o = evalfisOptions('NumSamplePoints', 501);
%      y = evalfis(fis, 5, o);
%
%   Voir aussi EVALFIS, GENSURFOPTIONS, DEFUZZ.
    options = struct('NumSamplePoints', 101, ...
                     'OutOfRangeInputValueMessage', 'warning', ...
                     'NoRuleFiredMessage', 'warning', ...
                     'EmptyOutputFuzzySetMessage', 'warning');
    options = poserOptions(options, 'evalfisOptions', varargin{:});
end
