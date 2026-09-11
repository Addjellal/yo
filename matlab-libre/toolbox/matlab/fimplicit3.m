function H = fimplicit3(fonction, intervalle)
%FIMPLICIT3 Surface implicite F(x,y,z) = 0.
%   FIMPLICIT3(F) trace la surface où F s'annule, sur [-5 5]^3. F est une
%   poignée de trois variables.
%   FIMPLICIT3(F,[A B]) emploie le cube [A B]^3.
%   FIMPLICIT3(F,[A B C D E G]) emploie le pavé donné.
%
%   H = FIMPLICIT3(...) rend la poignée.
%
%   La surface est obtenue en découpant le pavé en tranches et en traçant
%   la ligne de niveau zéro de chacune. C'est la même idée qu'en deux
%   dimensions, empilée : une surface implicite est la réunion de ses
%   coupes, et chacune est une courbe implicite.
%
%   Une surface qui ne coupe aucune tranche ne se voit pas : serrer les
%   tranches est le remède, comme serrer la grille l'est pour une courbe.
%
%   Exemple :
%      fimplicit3(@(x, y, z) x.^2 + y.^2 + z.^2 - 4, [-3 3]);   % la sphere
%
%   Voir aussi FIMPLICIT, FSURF, ISOSURFACE, CONTOUR3, FPLOT3.
    if nargin < 2 || isempty(intervalle)
        intervalle = [-5 5];
    end
    if numel(intervalle) == 2
        intervalle = repmat(intervalle, 1, 3);
    end
    densite = 60;
    tranches = 40;
    xs = linspace(intervalle(1), intervalle(2), densite);
    ys = linspace(intervalle(3), intervalle(4), densite);
    zs = linspace(intervalle(5), intervalle(6), tranches);
    [X, Y] = meshgrid(xs, ys);
    tenu = ishold;
    H = [];
    for k = 1:numel(zs)
        Z = matlibre_evaluer_grille3(fonction, X, Y, zs(k));
        if min(Z(:)) > 0 || max(Z(:)) < 0
            continue     % la tranche ne rencontre pas la surface
        end
        [lignes, ~] = contour(X, Y, Z, [0 0]);
        segments = matlibre_contour_segments(lignes);
        for s = 1:numel(segments)
            H = plot3(segments{s}(1, :), segments{s}(2, :), ...
                      zs(k) * ones(1, size(segments{s}, 2)));
            hold on
        end
    end
    if ~tenu
        hold off
    end
    if nargout == 0
        clear H;
    end
end
