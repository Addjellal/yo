function lineaire = matlibre_expression_lineaire(expression, coefficients, independante)
%MATLIBRE_EXPRESSION_LINEAIRE L'expression est-elle linéaire en ses coefficients ?
%   L = MATLIBRE_EXPRESSION_LINEAIRE(EXPRESSION,COEFFICIENTS,INDEPENDANTE)
%   répond en évaluant : un modèle linéaire vérifie que la valeur en la
%   somme de deux jeux de coefficients est la somme des valeurs, et qu'elle
%   s'annule en zéro. Le contrôle porte sur plusieurs abscisses tirées au
%   hasard, ce qui écarte les coïncidences.
%
%   Savoir qu'un modèle est linéaire change tout : ses coefficients
%   s'obtiennent alors par une résolution directe, sans point de départ ni
%   itération, et le résultat est le minimum global.
%
%   Exemple :
%      matlibre_expression_lineaire('a*x + b*x^2', {'a', 'b'}, 'x')     % vrai
%
%   Voir aussi FITTYPE, FIT.
    lineaire = false;
    n = numel(coefficients);
    if n == 0
        return
    end
    try
        fonction = matlibre_fonction_expression(expression, coefficients, {}, independante);
        x = linspace(0.3, 2.7, 7).';
        u = (1:n) / n;
        v = ((n:-1:1) / n) .^ 2;
        somme = fonction(u + v, {}, x);
        separe = fonction(u, {}, x) + fonction(v, {}, x);
        zero = fonction(zeros(1, n), {}, x);
        echelle = max(1, max(abs(somme)));
        lineaire = max(abs(somme - separe)) < 1e-9 * echelle && ...
                   max(abs(zero)) < 1e-9 * echelle;
    catch
        lineaire = false;
    end
end
