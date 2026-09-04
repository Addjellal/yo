function h = matlibre_tracer_ajustement(ajustement, arguments)
%MATLIBRE_TRACER_AJUSTEMENT Trace une courbe ajustée et ses données.
%   H = MATLIBRE_TRACER_AJUSTEMENT(FO,ARGUMENTS) trace la courbe sur
%   l'intervalle des données quand celles-ci sont fournies, sinon sur
%   l'intervalle unité, et superpose les points.
%
%   Exemple :
%      fo = fit((1:10)', (1:10)'.^2, 'poly2');
%      plot(fo, (1:10)', (1:10)'.^2);
%
%   Voir aussi FIT, CFIT.
    x = [];
    y = [];
    if numel(arguments) >= 2 && isnumeric(arguments{1}) && isnumeric(arguments{2})
        x = double(arguments{1}(:));
        y = double(arguments{2}(:));
    end
    if isempty(x)
        grille = linspace(0, 1, 200).';
    else
        grille = linspace(min(x), max(x), 200).';
    end
    h = plot(grille, feval(ajustement, grille), 'b-');
    if ~isempty(x)
        etat = ishold();
        hold('on');
        plot(x, y, 'k.');
        if ~etat
            hold('off');
        end
    end
end
