function noms = matlibre_coefficients_expression(expression, independante, probleme)
%MATLIBRE_COEFFICIENTS_EXPRESSION Coefficients d'une expression écrite à la main.
%   N = MATLIBRE_COEFFICIENTS_EXPRESSION(EXPRESSION,INDEPENDANTE,PROBLEME)
%   relève les identifiants de l'expression et écarte la variable
%   indépendante, les paramètres imposés et les noms de fonctions connues.
%   Ce qui reste est ajusté. Les noms sont rangés par ordre alphabétique,
%   comme dans MATLAB, ce qui fixe l'ordre des coefficients.
%
%   Un identifiant suivi d'une parenthèse est un appel de fonction et non
%   un coefficient : c'est ce qui distingue « a*exp(b*x) » de « a*e(b) ».
%
%   Exemple :
%      matlibre_coefficients_expression('a*exp(b*x)', 'x', {})     % a, b
%
%   Voir aussi FITTYPE.
    identifiants = regexp(expression, '[A-Za-z_]\w*', 'match');
    appels = regexp(expression, '[A-Za-z_]\w*\s*\(', 'match');
    for k = 1:numel(appels)
        appels{k} = strtrim(strrep(appels{k}, '(', ''));
    end
    exclus = [{independante}, probleme(:).', appels];
    noms = {};
    for k = 1:numel(identifiants)
        nom = identifiants{k};
        if any(strcmp(exclus, nom)) || any(strcmp(noms, nom))
            continue
        end
        noms{end + 1} = nom;     %#ok<AGROW>
    end
    noms = sort(noms);
end
