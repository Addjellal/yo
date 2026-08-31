function H = stem3(varargin)
%STEM3 Tiges dans l'espace.
%   STEM3(X,Y,Z) trace, pour chaque triplet, une tige verticale surmontée
%   d'un cercle.
%   STEM3(Z) place les tiges aux nœuds d'une grille entière.
%   STEM3(...,STYLE) prend une chaîne de style.
%
%   H = STEM3(...) rend la poignée.
%
%   Le rendu de MatLibre est plan : la tige va de zéro à Z, dessinée dans
%   le plan des X et des Z.
%
%   Exemples :
%      t = linspace(0, 2*pi, 20);
%      stem3(cos(t), sin(t), t);
%      stem3(rand(4, 4));
%
%   Voir aussi STEM, PLOT3, SCATTER3, BAR3.
    entrees = varargin;
    style = {};
    if ~isempty(entrees) && (ischar(entrees{end}) || isstring(entrees{end}))
        style = {char(entrees{end})};
        entrees = entrees(1:end - 1);
    end
    if numel(entrees) == 1
        z = entrees{1};
        x = 1:numel(z);
        z = z(:)';
    elseif numel(entrees) >= 3
        x = entrees{1};
        z = entrees{3};
        x = x(:)';
        z = z(:)';
    else
        error('MATLAB:stem3:NotEnoughInputs', 'Not enough input arguments.');
    end
    H = stem(x, z, style{:});
    if nargout == 0
        clear H;
    end
end
