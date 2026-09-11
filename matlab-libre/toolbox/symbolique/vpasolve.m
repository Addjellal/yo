function racines = vpasolve(equation, variable, depart)
%VPASOLVE Résolution numérique d'une équation symbolique.
%   VPASOLVE(F) résout F = 0 numériquement. VPASOLVE(F,X) nomme
%   l'inconnue. VPASOLVE(F,X,X0) part de X0 et rend la racine trouvée
%   depuis là.
%
%   La différence avec SOLVE tient à ce qu'on cherche. SOLVE résout
%   exactement, et n'y arrive que sur les équations polynomiales.
%   VPASOLVE cherche numériquement, et y arrive sur toute équation dont
%   on sait évaluer le membre de gauche — y compris celles qui n'ont pas
%   de solution en forme close, comme x = cos(x).
%
%   Sans point de départ, l'équation polynomiale rend toutes ses racines
%   et les autres sont balayées sur un intervalle autour de zéro : une
%   racine lointaine peut échapper, et c'est pour cela que le point de
%   départ existe.
%
%   Une seule racine est rendue telle quelle ; plusieurs le sont dans une
%   cellule, comme SOLVE les rend.
%
%   Exemple :
%      syms x
%      double(vpasolve(cos(x) - x, x, 1))     % 0.739085..., le point fixe
%      deux = vpasolve(x^2 - 2, x);
%      abs(double(deux{2}) - sqrt(2)) < 1e-12
%
%   Voir aussi SOLVE, FZERO, ROOTS, DOUBLE.
    equation = sym(equation);
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(equation);
    end
    nom = matlibre_sym_nom(variable);
    fonction = @(v) double(symeval(equation.arbre, {nom}, {v}));

    if nargin >= 3 && ~isempty(depart)
        valeur = fzero(fonction, double(depart));
        racines = sym(valeur);
        return
    end
    % Un polynome se resout par ses racines : on les a toutes, exactement.
    try
        coefficients = matlibre_sym_coefficients(equation.arbre, nom);
        if numel(coefficients) > 1
            valeurs = roots(coefficients);
            proches = abs(imag(valeurs)) < 1e-12 * max(abs(valeurs), 1);
            valeurs(proches) = real(valeurs(proches));
            racines = enSym(sort(valeurs));
            return
        end
    catch
        % Pas polynomiale : on balaie.
    end
    racines = enSym(balayer(fonction));
end

function valeurs = balayer(fonction)
% On cherche les changements de signe sur un intervalle autour de zero,
% puis on affine chacun. Une racine sans changement de signe — un
% contact tangent — echappe a ce procede, ce que l'aide annonce.
    grille = linspace(-20, 20, 4001);
    valeurs = [];
    precedente = NaN;
    for k = 1:numel(grille)
        courante = valeurEvaluee(fonction, grille(k));
        if k > 1 && isfinite(courante) && isfinite(precedente) && ...
                courante * precedente < 0
            try
                valeurs(end + 1) = fzero(fonction, [grille(k-1) grille(k)]);   %#ok<AGROW>
            catch
            end
        elseif isfinite(courante) && courante == 0
            valeurs(end + 1) = grille(k);   %#ok<AGROW>
        end
        precedente = courante;
    end
    valeurs = unique(round(valeurs * 1e12) / 1e12);
end

function v = valeurEvaluee(fonction, x)
    try
        v = fonction(x);
    catch
        v = NaN;
    end
    if ~isscalar(v) || ~isreal(v)
        v = NaN;
    end
end

function r = enSym(valeurs)
    valeurs = valeurs(:);
    if isempty(valeurs)
        r = sym([]);
        return
    end
    if numel(valeurs) == 1
        r = sym(valeurs(1));
        return
    end
    r = cell(numel(valeurs), 1);
    for k = 1:numel(valeurs)
        r{k} = sym(valeurs(k));
    end
end
