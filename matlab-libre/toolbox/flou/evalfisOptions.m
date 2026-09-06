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
%      fis = addInput(mamfis('Name', 'pilote'), [0 10], 'Name', 'erreur');
%      fis = addMF(fis, 'erreur', 'trimf', [0 0 5], 'Name', 'petite');
%      fis = addMF(fis, 'erreur', 'trimf', [5 10 10], 'Name', 'grande');
%      fis = addOutput(fis, [0 1], 'Name', 'commande');
%      fis = addMF(fis, 'commande', 'trimf', [0 0 0.5], 'Name', 'faible');
%      fis = addMF(fis, 'commande', 'trimf', [0.5 1 1], 'Name', 'forte');
%      fis = addRule(fis, [1 1 1 1; 2 2 1 1]);
%      o = evalfisOptions('NumSamplePoints', 501);
%      y = evalfis(fis, 5);
%      y >= 0 && y <= 1        % la sortie reste dans son intervalle
%
%   Voir aussi EVALFIS, GENSURFOPTIONS, DEFUZZ.
    options = struct('NumSamplePoints', 101, ...
                     'OutOfRangeInputValueMessage', 'warning', ...
                     'NoRuleFiredMessage', 'warning', ...
                     'EmptyOutputFuzzySetMessage', 'warning');
    options = poserOptions(options, 'evalfisOptions', varargin{:});
end
