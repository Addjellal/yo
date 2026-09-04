function sp = spap2(noeuds, ordre, x, y, w)
%SPAP2 Spline des moindres carrés, à nœuds donnés.
%   SP = SPAP2(NOEUDS,ORDRE,X,Y) ajuste, au sens des moindres carrés, la
%   spline d'ordre ORDRE dont les nœuds sont donnés. À la différence d'une
%   spline d'interpolation, elle ne passe pas par les points : elle a
%   moins de coefficients qu'il n'y a de données, et lisse donc le bruit.
%
%   SP = SPAP2(N,ORDRE,X,Y) où N est un entier place N morceaux de
%   longueur égale sur l'intervalle des données.
%
%   SPAP2(...,W) pondère les points.
%
%   La spline rendue est en B-forme, comme dans MATLAB : elle s'évalue par
%   FNVAL, se dérive par FNDER et se trace par FNPLT.
%
%   Exemple :
%      x = (0:0.05:1)';
%      sp = spap2(4, 4, x, x .^ 3);
%      max(abs(fnval(sp, x) - x .^ 3)) < 1e-10      % un cubique est exact
%
%   Voir aussi CSAPS, SPAPS, FNVAL, FNBRK.
    x = double(x(:));
    y = double(y(:));
    if nargin < 5 || isempty(w)
        w = ones(numel(x), 1);
    else
        w = double(w(:));
    end
    if isscalar(noeuds)
        interieurs = linspace(min(x), max(x), noeuds + 1);
        noeuds = augknt(interieurs, ordre);
    else
        noeuds = double(noeuds(:)).';
        if numel(unique(noeuds)) == numel(noeuds)
            % Une suite simple : on lui donne la multiplicité qu'il faut
            % aux extrémités pour que la spline y soit définie.
            noeuds = augknt(noeuds, ordre);
        end
    end
    N = matlibre_base_bspline(noeuds, ordre, x);
    racine = sqrt(w);
    coefs = ((N .* racine) \ (y .* racine)).';
    sp = struct('form', 'B-', 'knots', noeuds, 'coefs', coefs, ...
                'number', numel(coefs), 'order', ordre, 'dim', 1);
end
