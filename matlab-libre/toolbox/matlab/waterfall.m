function H = waterfall(varargin)
%WATERFALL Surface dessinée en lignes, une par rangée.
%   WATERFALL(X,Y,Z) trace une courbe par ligne de Z, décalée de sorte
%   que les courbes se suivent comme les marches d'une cascade. C'est la
%   façon de montrer une famille de signaux — un spectre au fil du temps,
%   par exemple — sans les superposer.
%
%   WATERFALL(Z) prend une grille entière.
%
%   H = WATERFALL(...) rend les poignées.
%
%   Le rendu de MatLibre est plan : les courbes sont décalées
%   verticalement d'un pas constant, ce qui donne la même lecture que la
%   perspective de MATLAB.
%
%   Exemples :
%      waterfall(peaks(20));
%
%      t = linspace(0, 1, 200);
%      S = zeros(8, 200);
%      for k = 1:8, S(k, :) = sin(2*pi*k*t) / k; end
%      waterfall(S);
%
%   Voir aussi RIBBON, MESH, SURF, PLOT3, STACKEDPLOT.
    entrees = varargin;
    if numel(entrees) >= 3
        x = entrees{1};
        Z = entrees{3};
        if ~isvector(x)
            x = x(1, :);
        end
    else
        Z = entrees{1};
        x = 1:size(Z, 2);
    end
    x = x(:)';
    [lignes, ~] = size(Z);
    etendue = max(Z(:)) - min(Z(:));
    if etendue == 0
        etendue = 1;
    end
    pas = etendue / max(lignes - 1, 1);
    aEffacer = ishold();
    if ~aEffacer
        cla;
    end
    hold('on');
    H = [];
    for k = 1:lignes
        H(end + 1) = plot(x, Z(k, :) + (k - 1) * pas);    %#ok<AGROW>
    end
    if ~aEffacer
        hold('off');
    end
    if nargout == 0
        clear H;
    end
end
