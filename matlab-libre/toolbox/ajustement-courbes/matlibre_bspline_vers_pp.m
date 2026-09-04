function pp = matlibre_bspline_vers_pp(sp)
%MATLIBRE_BSPLINE_VERS_PP Convertit une B-forme en morceaux polynomiaux.
%   PP = MATLIBRE_BSPLINE_VERS_PP(SP) rend la même spline sous la forme
%   qu'attendent PPVAL, FNDER et FNINT.
%
%   La conversion se fait par développement de Taylor au début de chaque
%   morceau : les dérivées successives de la spline s'obtiennent
%   exactement par la récurrence des B-splines, et non par différence
%   finie.
%
%   Exemple :
%      sp = spap2(2, 3, (0:0.1:1)', (0:0.1:1)'.^2);
%      max(abs(ppval(matlibre_bspline_vers_pp(sp), 0.5) - fnval(sp, 0.5)))
%
%   Voir aussi SPAP2, FNVAL, MATLIBRE_PP_FORME.
    noeuds = double(sp.knots(:)).';
    ordre = sp.order;
    coefs = double(sp.coefs(:)).';
    ruptures = unique(noeuds(ordre:(end - ordre + 1)));
    morceaux = numel(ruptures) - 1;
    tableau = zeros(morceaux, ordre);
    derivees = cell(1, ordre);
    n = noeuds; o = ordre; c = coefs;
    for d = 1:ordre
        derivees{d} = struct('knots', n, 'order', o, 'coefs', c);
        [n, o, c] = matlibre_bspline_deriver(n, o, c);
    end
    factorielle = 1;
    for d = 1:ordre
        if d > 1
            factorielle = factorielle * (d - 1);
        end
        valeurs = matlibre_bspline_valeurs(derivees{d}.knots, derivees{d}.order, ...
                                           derivees{d}.coefs, ruptures(1:morceaux).');
        % La colonne des puissances décroissantes : la dérivée d-1 divisée
        % par sa factorielle occupe la place de la puissance d-1.
        tableau(:, ordre - d + 1) = valeurs(:) / factorielle;
    end
    pp = struct('form', 'pp', 'breaks', ruptures, 'coefs', tableau, ...
                'pieces', morceaux, 'order', ordre, 'dim', 1);
end
