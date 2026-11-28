function options = tunefisOptions(varargin)
%TUNEFISOPTIONS Options du réglage d'un système flou.
%   O = TUNEFISOPTIONS rend les réglages par défaut de TUNEFIS :
%     Method            'anfis' (défaut) ou 'patternsearch' — MatLibre
%                       ne connaît que la descente locale et l'hybride
%                       d'ANFIS
%     MethodOptions     options de la méthode
%     OptimizationType  'tuning' (défaut) ou 'learning'
%     Display           'all', 'none' ou 'tuningonly'
%     DistributionType  répartition des modalités, 'uniform'
%     IgnoreInvalidParameters  laisser passer un paramètre hors bornes
%     UseParallel       calcul réparti, 0
%
%   Exemple :
%      o = tunefisOptions('Method', 'anfis');
%      o.Method                         % 'anfis'
%      x = (0:0.5:10)';
%      fis0 = genfis1([x, sin(x)], 3);
%      [~, sortie] = getTunableSettings(fis0);
%      fis = tunefis(fis0, sortie, x, sin(x), o);   % les sorties seules
%
%   Voir aussi TUNEFIS, GETTUNABLESETTINGS, ANFISOPTIONS.
    options = struct('Method', 'anfis', 'MethodOptions', [], ...
                     'OptimizationType', 'tuning', 'Display', 'all', ...
                     'DistributionType', 'uniform', ...
                     'IgnoreInvalidParameters', 1, 'UseParallel', 0);
    options = poserOptions(options, 'tunefisOptions', varargin{:});
end
