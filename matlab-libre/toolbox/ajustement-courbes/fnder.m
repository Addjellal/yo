function derivee = fnder(f, nombre)
%FNDER Dérivée d'une fonction par morceaux.
%   D = FNDER(F) rend la dérivée de la spline F, sous la même forme.
%   D = FNDER(F,N) dérive N fois ; N négatif intègre.
%
%   Dériver une spline cubique donne une spline quadratique : l'ordre
%   baisse d'un, les morceaux restent les mêmes.
%
%   Exemple :
%      pp = spline(1:5, (1:5).^2);
%      fnval(fnder(pp), 3)      % 6, la derivee de x^2
%
%   Voir aussi FNINT, FNVAL, PPVAL, SPLINE.
    if nargin < 2
        nombre = 1;
    end
    if nombre < 0
        derivee = fnint(f);
        for k = 2:(-nombre)
            derivee = fnint(derivee);
        end
        return
    end
    derivee = matlibre_pp_forme(f);
    for tour = 1:nombre
        ordre = derivee.order;
        if ordre <= 1
            derivee.coefs = zeros(derivee.pieces, 1);
            derivee.order = 1;
            continue
        end
        coefs = derivee.coefs;
        nouveaux = zeros(size(coefs, 1), ordre - 1);
        for j = 1:(ordre - 1)
            nouveaux(:, j) = coefs(:, j) * (ordre - j);
        end
        derivee.coefs = nouveaux;
        derivee.order = ordre - 1;
    end
end
