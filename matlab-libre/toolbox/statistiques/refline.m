function H = refline(pente, ordonnee)
%REFLINE Ajoute une droite de référence à un tracé.
%   REFLINE(M,B) ajoute la droite Y = M*X + B au tracé courant, d'un bout
%   à l'autre de l'axe des abscisses, sans changer les limites.
%
%   REFLINE(COEFFS) où COEFFS est le vecteur [M B] fait la même chose.
%
%   REFLINE sans argument ajuste les moindres carrés sur les points déjà
%   tracés et ajoute la droite de régression. C'est la forme la plus
%   employée : on trace un nuage, puis on appelle REFLINE.
%
%   H = REFLINE(...) rend la poignée de la droite.
%
%   Exemples :
%      x = 1:20;
%      plot(x, 2 * x + randn(1, 20) * 2, 'o');
%      refline;                    % la droite des moindres carres
%      refline(2, 0);              % la droite vraie, pour comparer
%
%   Voir aussi REFCURVE, LSLINE, POLYFIT, LINE, YLINE.
    if nargin == 1 && numel(pente) == 2
        ordonnee = pente(2);
        pente = pente(1);
    end
    bornes = xlim();
    if nargin == 0
        % Sans argument : les moindres carrés sur ce qui est déjà tracé.
        [x, y] = matlibre_points_traces();
        if numel(x) < 2
            error('stats:refline:NoData', ...
                  'REFLINE needs points on the axes, or a slope.');
        end
        coefficients = polyfit(x, y, 1);
        pente = coefficients(1);
        ordonnee = coefficients(2);
    end
    aEffacer = ishold();
    hold('on');
    H = plot(bornes, pente * bornes + ordonnee, 'r--');
    if ~aEffacer
        hold('off');
    end
    xlim(bornes);
    if nargout == 0
        clear H;
    end
end
