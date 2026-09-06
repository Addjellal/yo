function H = matlibre_hadamard_noyau(n)
%MATLIBRE_HADAMARD_NOYAU Noyaux de la construction de Hadamard.
%   Les ordres 1 et 2 sont immédiats ; 12 et 20 viennent des
%   constructions de Paley, qui bordent une matrice circulante bâtie sur
%   les résidus quadratiques modulo un nombre premier.
%
%   Fonction interne : elle n'existe pas dans MATLAB.
    switch n
        case 1
            H = 1;
        case 2
            H = [1 1; 1 -1];
        otherwise
            % Paley I : p premier, p = n - 1, la matrice est bordée d'une
            % ligne et d'une colonne de uns, et son coeur porte le
            % caractère quadratique modulo p.
            p = n - 1;
            residus = false(1, p);
            for k = 1:p-1
                residus(mod(k * k, p) + 1) = true;
            end
            Q = zeros(p, p);
            for i = 1:p
                for j = 1:p
                    d = mod(i - j, p);
                    if d == 0
                        Q(i, j) = 0;
                    elseif residus(d + 1)
                        Q(i, j) = 1;
                    else
                        Q(i, j) = -1;
                    end
                end
            end
            H = [1, ones(1, p); ones(p, 1), Q - eye(p)];
    end
end
