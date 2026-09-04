function y = matlibre_appeler_expression(fonction, coefficients, probleme, x)
%MATLIBRE_APPELER_EXPRESSION Appelle une expression avec ses arguments à plat.
%   Y = MATLIBRE_APPELER_EXPRESSION(F,COEFFICIENTS,PROBLEME,X) déplie les
%   coefficients et les paramètres imposés en arguments séparés, ce que
%   demande la fonction anonyme construite depuis l'expression.
%
%   Exemple :
%      f = str2func('@(a,b,x) a*x + b');
%      matlibre_appeler_expression(f, [2 1], {}, 3)      % 7
%
%   Voir aussi MATLIBRE_FONCTION_EXPRESSION.
    liste = num2cell(coefficients(:).');
    if ~isempty(probleme)
        if iscell(probleme)
            liste = [liste, probleme(:).'];
        else
            liste = [liste, num2cell(probleme(:).')];
        end
    end
    y = fonction(liste{:}, x);
    y = y(:);
end
