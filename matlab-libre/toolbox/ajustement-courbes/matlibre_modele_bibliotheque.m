function modele = matlibre_modele_bibliotheque(nom)
%MATLIBRE_MODELE_BIBLIOTHEQUE Description d'un modèle nommé.
%   M = MATLIBRE_MODELE_BIBLIOTHEQUE(NOM) rend la description du modèle
%   que NOM désigne : sa formule, le nom de ses coefficients, la fonction
%   qui l'évalue, s'il est linéaire en ses coefficients, et de quoi partir
%   quand il ne l'est pas.
%
%   Les noms suivent ceux de MATLAB : 'poly1' à 'poly9', 'exp1' et
%   'exp2', 'power1' et 'power2', 'gauss1' à 'gauss8', 'sin1' à 'sin8',
%   'fourier1' à 'fourier8', 'rat' suivi de deux chiffres, 'weibull', et
%   les interpolants 'linearinterp', 'nearestinterp', 'pchipinterp',
%   'cubicinterp', 'splineinterp', 'smoothingspline'.
%
%   Un modèle vide est rendu si le nom n'est pas connu : c'est alors que
%   FITTYPE le lit comme une expression.
%
%   Exemple :
%      m = matlibre_modele_bibliotheque('poly2');
%      m.Coefficients     % p1 p2 p3
%
%   Voir aussi FITTYPE, FIT.
    modele = [];
    nom = lower(strtrim(char(nom)));
    if isempty(nom)
        return
    end
    interpolants = {'linearinterp', 'nearestinterp', 'pchipinterp', ...
                    'cubicinterp', 'splineinterp', 'smoothingspline', ...
                    'lowess', 'loess'};
    if any(strcmp(nom, interpolants))
        modele = matlibre_modele_neuf(nom, nom, {}, false);
        modele.Categorie = 'interpolant';
        return
    end
    [famille, ordre] = matlibre_modele_famille(nom);
    switch famille
        case 'poly'
            noms = cell(1, ordre + 1);
            for k = 1:(ordre + 1)
                noms{k} = sprintf('p%d', k);
            end
            modele = matlibre_modele_neuf(nom, matlibre_formule_polynome(ordre), noms, true);
            modele.Base = @(x) matlibre_base_polynome(x, ordre);
            modele.Evaluer = @(c, x) matlibre_base_polynome(x, ordre) * c(:);
        case 'exp'
            if ordre == 1
                modele = matlibre_modele_neuf(nom, 'a*exp(b*x)', {'a', 'b'}, false);
                modele.Evaluer = @(c, x) c(1) * exp(c(2) * x);
            else
                modele = matlibre_modele_neuf(nom, 'a*exp(b*x) + c*exp(d*x)', ...
                                              {'a', 'b', 'c', 'd'}, false);
                modele.Evaluer = @(c, x) c(1) * exp(c(2) * x) + c(3) * exp(c(4) * x);
            end
            modele.Depart = @(x, y) matlibre_depart_exponentielle(x, y, ordre);
        case 'power'
            if ordre == 1
                modele = matlibre_modele_neuf(nom, 'a*x^b', {'a', 'b'}, false);
                modele.Evaluer = @(c, x) c(1) * x .^ c(2);
            else
                modele = matlibre_modele_neuf(nom, 'a*x^b + c', {'a', 'b', 'c'}, false);
                modele.Evaluer = @(c, x) c(1) * x .^ c(2) + c(3);
            end
            modele.Depart = @(x, y) matlibre_depart_puissance(x, y, ordre);
        case 'gauss'
            noms = cell(1, 3 * ordre);
            for k = 1:ordre
                noms{3 * k - 2} = sprintf('a%d', k);
                noms{3 * k - 1} = sprintf('b%d', k);
                noms{3 * k} = sprintf('c%d', k);
            end
            modele = matlibre_modele_neuf(nom, matlibre_formule_gauss(ordre), noms, false);
            modele.Evaluer = @(c, x) matlibre_evaluer_gauss(c, x, ordre);
            modele.Depart = @(x, y) matlibre_depart_gauss(x, y, ordre);
            bornes = -inf(1, 3 * ordre);
            bornes(3:3:end) = 0;
            modele.Lower = bornes;
        case 'sin'
            noms = cell(1, 3 * ordre);
            for k = 1:ordre
                noms{3 * k - 2} = sprintf('a%d', k);
                noms{3 * k - 1} = sprintf('b%d', k);
                noms{3 * k} = sprintf('c%d', k);
            end
            modele = matlibre_modele_neuf(nom, matlibre_formule_sinus(ordre), noms, false);
            modele.Evaluer = @(c, x) matlibre_evaluer_sinus(c, x, ordre);
            modele.Depart = @(x, y) matlibre_depart_sinus(x, y, ordre);
        case 'fourier'
            noms = cell(1, 2 * ordre + 2);
            noms{1} = 'a0';
            for k = 1:ordre
                noms{2 * k} = sprintf('a%d', k);
                noms{2 * k + 1} = sprintf('b%d', k);
            end
            noms{end} = 'w';
            modele = matlibre_modele_neuf(nom, matlibre_formule_fourier(ordre), noms, false);
            modele.Evaluer = @(c, x) matlibre_evaluer_fourier(c, x, ordre);
            modele.Depart = @(x, y) matlibre_depart_fourier(x, y, ordre);
        case 'rat'
            haut = floor(ordre / 10);
            bas = mod(ordre, 10);
            noms = cell(1, haut + bas + 1);
            for k = 1:(haut + 1)
                noms{k} = sprintf('p%d', k);
            end
            for k = 1:bas
                noms{haut + 1 + k} = sprintf('q%d', k);
            end
            modele = matlibre_modele_neuf(nom, matlibre_formule_rationnelle(haut, bas), ...
                                          noms, false);
            modele.Evaluer = @(c, x) matlibre_evaluer_rationnelle(c, x, haut, bas);
            modele.Depart = @(x, y) matlibre_depart_rationnelle(x, y, haut, bas);
        case 'weibull'
            modele = matlibre_modele_neuf(nom, 'a*b*x^(b-1)*exp(-a*x^b)', {'a', 'b'}, false);
            modele.Evaluer = @(c, x) c(1) * c(2) * x .^ (c(2) - 1) .* exp(-c(1) * x .^ c(2));
            modele.Depart = @(x, y) [1, 1];
            modele.Lower = [0 0];
        otherwise
            modele = [];
    end
end

function [famille, ordre] = matlibre_modele_famille(nom)
% Un nom de modèle est une famille suivie d'un ordre ; 'weibull' n'en a
% pas, et 'rat' en porte deux chiffres.
    famille = '';
    ordre = 0;
    if strcmp(nom, 'weibull')
        famille = 'weibull';
        return
    end
    chiffres = nom(isstrprop(nom, 'digit'));
    lettres = nom(~isstrprop(nom, 'digit'));
    if isempty(chiffres)
        return
    end
    connues = {'poly', 'exp', 'power', 'gauss', 'sin', 'fourier', 'rat'};
    if ~any(strcmp(lettres, connues))
        return
    end
    famille = lettres;
    ordre = str2double(chiffres);
end

function m = matlibre_modele_neuf(nom, formule, coefficients, lineaire)
    m = struct('Type', nom, 'Formula', formule, 'Coefficients', {coefficients}, ...
               'Linear', lineaire, 'Categorie', 'library', ...
               'Evaluer', [], 'Base', [], 'Depart', [], ...
               'Lower', [], 'Upper', []);
end
