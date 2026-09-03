function coefficients = matlibre_sym_coefficients(arbre, nom)
%MATLIBRE_SYM_COEFFICIENTS Coefficients d'un polynôme en une variable.
%   Rendus par puissances décroissantes, comme POLYVAL les attend. Une
%   expression qui n'est pas polynomiale en cette variable est refusée
%   plutôt que tronquée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    croissants = matlibre_sym_croissants(arbre, nom);
    coefficients = fliplr(croissants);
    % Les zéros de tête ne portent rien.
    premier = find(abs(coefficients) > 0, 1);
    if isempty(premier)
        coefficients = 0;
    else
        coefficients = coefficients(premier:end);
    end
end

function c = matlibre_sym_croissants(arbre, nom)
%MATLIBRE_SYM_CROISSANTS Coefficients par puissances croissantes.
    switch arbre{1}
        case 'num'
            c = arbre{2};
        case 'var'
            if strcmp(arbre{2}, nom)
                c = [0 1];
            else
                error('symbolic:sym2poly:AutreVariable', ...
                      'L''expression dépend aussi de %s.', arbre{2});
            end
        case '+'
            c = matlibre_sym_somme(matlibre_sym_croissants(arbre{2}, nom), ...
                                   matlibre_sym_croissants(arbre{3}, nom));
        case '-'
            c = matlibre_sym_somme(matlibre_sym_croissants(arbre{2}, nom), ...
                                   -matlibre_sym_croissants(arbre{3}, nom));
        case '*'
            c = conv(matlibre_sym_croissants(arbre{2}, nom), ...
                     matlibre_sym_croissants(arbre{3}, nom));
        case '/'
            diviseur = matlibre_sym_croissants(arbre{3}, nom);
            if numel(diviseur) > 1
                error('symbolic:sym2poly:Fraction', ...
                      'La division par une expression en %s n''est pas polynomiale.', nom);
            end
            c = matlibre_sym_croissants(arbre{2}, nom) / diviseur;
        case '^'
            exposant = matlibre_sym_croissants(arbre{3}, nom);
            if numel(exposant) > 1 || exposant ~= round(exposant) || exposant < 0
                error('symbolic:sym2poly:Exposant', ...
                      'L''exposant doit être un entier positif.');
            end
            base = matlibre_sym_croissants(arbre{2}, nom);
            c = 1;
            for k = 1:exposant
                c = conv(c, base);
            end
        otherwise
            error('symbolic:sym2poly:Fonction', ...
                  '''%s'' n''est pas polynomiale.', arbre{1});
    end
end

function s = matlibre_sym_somme(a, b)
    n = max(numel(a), numel(b));
    s = [a(:).', zeros(1, n - numel(a))] + [b(:).', zeros(1, n - numel(b))];
end
