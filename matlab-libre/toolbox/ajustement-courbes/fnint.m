function primitive = fnint(f, valeur)
%FNINT Primitive d'une fonction par morceaux.
%   P = FNINT(F) rend la primitive de la spline F qui s'annule en son
%   premier nœud. FNINT(F,V) lui donne la valeur V en ce point.
%
%   Les constantes d'intégration des morceaux ne sont pas libres : elles
%   sont fixées par la continuité de la primitive d'un morceau au suivant.
%
%   Exemple :
%      pp = spline(0:4, (0:4).^2);
%      fnval(fnint(pp), 3)      % 9, l'integrale de x^2 de 0 a 3
%
%   Voir aussi FNDER, FNVAL, PPVAL.
    if nargin < 2
        valeur = 0;
    end
    primitive = matlibre_pp_forme(f);
    ordre = primitive.order;
    coefs = primitive.coefs;
    morceaux = size(coefs, 1);
    nouveaux = zeros(morceaux, ordre + 1);
    for j = 1:ordre
        nouveaux(:, j) = coefs(:, j) / (ordre + 1 - j);
    end
    ruptures = primitive.breaks;
    cumul = valeur;
    for i = 1:morceaux
        nouveaux(i, end) = cumul;
        largeur = ruptures(i + 1) - ruptures(i);
        cumul = polyval(nouveaux(i, :), largeur);
    end
    primitive.coefs = nouveaux;
    primitive.order = ordre + 1;
end
