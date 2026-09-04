function fonction = matlibre_fonction_expression(expression, coefficients, probleme, independante)
%MATLIBRE_FONCTION_EXPRESSION Rend évaluable une expression écrite à la main.
%   F = MATLIBRE_FONCTION_EXPRESSION(EXPRESSION,COEFFICIENTS,PROBLEME,
%   INDEPENDANTE) construit la fonction anonyme qui prend le vecteur des
%   coefficients, les paramètres imposés et la variable indépendante, et
%   rend la valeur de l'expression.
%
%   Exemple :
%      f = matlibre_fonction_expression('a*x + b', {'a', 'b'}, {}, 'x');
%      f([2 1], {}, 3)      % 7
%
%   Voir aussi FITTYPE, FEVAL.
    arguments = [coefficients(:).', probleme(:).', {independante}];
    % L'expression est rendue applicable terme a terme, comme le fait
    % MATLAB : l'utilisateur ecrit « a*x^2 » et non « a.*x.^2 », et le
    % modele doit pourtant s'evaluer sur tout un vecteur d'abscisses.
    texte = sprintf('@(%s) %s', strjoin(arguments, ', '), vectorize(expression));
    brute = str2func(texte);
    fonction = @(c, p, x) matlibre_appeler_expression(brute, c, p, x);
end
