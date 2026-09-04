function [ajustement, qualite, sortie] = fit(x, y, modele, varargin)
%FIT Ajuste un modèle à des données.
%   FO = FIT(X,Y,MODELE) ajuste le modèle aux couples donnés et rend un
%   objet qu'on évalue comme une fonction : FO(XNOUVEAU).
%
%   MODELE est un FITTYPE, ou directement le nom d'un modèle de la
%   bibliothèque ('poly2', 'exp1', 'gauss3', 'smoothingspline'…), ou une
%   expression écrite à la main.
%
%   [FO,QUALITE] = FIT(...) rend aussi la qualité de l'ajustement : somme
%   des carrés des écarts, R carré, R carré ajusté, écart quadratique
%   moyen et degrés de liberté.
%
%   [FO,QUALITE,SORTIE] = FIT(...) rend les résidus, la matrice
%   jacobienne, le nombre d'itérations et le drapeau de sortie.
%
%   FIT(...,OPTIONS) ou FIT(...,'Nom',VALEUR,...) règle l'ajustement ;
%   voir FITOPTIONS. FIT(...,'problem',{...}) donne la valeur des
%   paramètres que le modèle a déclarés imposés.
%
%   Un modèle linéaire en ses coefficients est résolu directement, sans
%   itération ni point de départ : le résultat est le minimum global. Un
%   modèle non linéaire est ajusté par moindres carrés itératifs, depuis
%   un point de départ déduit des données.
%
%   Exemple :
%      x = (0:0.1:5)';
%      y = 3 * exp(-0.7 * x) + 0.01 * randn(size(x));
%      [fo, gof] = fit(x, y, 'exp1');
%      coeffvalues(fo)      % environ 3 et -0.7
%      gof.rsquare
%
%   Voir aussi FITTYPE, FITOPTIONS, CFIT, CONFINT, PREDINT, DIFFERENTIATE.
    x = double(x);
    y = double(y(:));
    if size(x, 2) == 2 && size(x, 1) == numel(y)
        % Deux colonnes d'abscisses : c'est une surface qu'on ajuste.
        [ajustement, qualite, sortie] = matlibre_ajuster_surface(x, y, modele, varargin);
        return
    end
    x = x(:);
    if numel(x) ~= numel(y)
        error('curvefit:fit:Tailles', ...
              'X et Y doivent avoir le même nombre d''éléments.');
    end
    if ~isa(modele, 'fittype')
        modele = fittype(modele);
    end
    [options, valeursImposees] = matlibre_fit_options(modele, varargin);
    [x, y, poids] = matlibre_fit_selection(x, y, options);
    [x, y, ordre] = matlibre_fit_trier(x, y);
    poids = poids(ordre);
    normalisation = matlibre_fit_normalisation(x, options);
    xa = (x - normalisation(1)) / normalisation(2);
    switch matlibre_fit_famille(modele, options)
        case 'interpolant'
            [interpolant, coefficients] = matlibre_fit_interpolant(modele, xa, y, poids, options);
            residus = y - matlibre_evaluer_interpolant(interpolant, xa);
            nombreParametres = numel(x);
            jacobienne = [];
        case 'lineaire'
            A = matlibre_fit_base(modele, xa, valeursImposees);
            [coefficients, jacobienne] = matlibre_ajuster_lineaire(A, y, poids, options);
            interpolant = [];
            residus = y - A * coefficients(:);
            nombreParametres = numel(coefficients);
        otherwise
            [coefficients, residus, jacobienne, iterations] = ...
                matlibre_ajuster_nonlineaire(modele, xa, y, poids, options, valeursImposees);
            interpolant = [];
            nombreParametres = numel(coefficients);
    end
    ajustement = cfit(modele, coefficients, valeursImposees, interpolant, ...
                      normalisation, residus, jacobienne, poids, numel(x) - nombreParametres);
    qualite = matlibre_qualite_ajustement(y, residus, poids, nombreParametres);
    if nargout > 2
        sortie = struct('numobs', numel(x), 'numparam', nombreParametres, ...
                        'residuals', residus, 'Jacobian', jacobienne, ...
                        'exitflag', 1, 'algorithm', options.Method, ...
                        'iterations', 0);
        if exist('iterations', 'var')
            sortie.iterations = iterations;
        end
    end
end
