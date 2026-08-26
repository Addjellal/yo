function [tensions, courants] = solveDC(c)
%SOLVEDC Point de fonctionnement continu par analyse nodale modifiée.
%   [V,I] = SOLVEDC(C) rend le potentiel de chaque nœud (le nœud 0 étant
%   la masse) et le courant de chaque source de tension.
%   En régime continu, un condensateur est un circuit ouvert et une
%   bobine un court-circuit.
    n = c.noeuds;
    sourcesTension = [];
    for k = 1:numel(c.composants)
        if any(strcmp(c.composants{k}.type, {'v', 'l'}))
            sourcesTension(end+1) = k;
        end
    end
    m = numel(sourcesTension);
    A = zeros(n + m, n + m);
    b = zeros(n + m, 1);
    for k = 1:numel(c.composants)
        comp = c.composants{k};
        a = comp.n1;
        d = comp.n2;
        switch comp.type
            case 'r'
                g = 1 / comp.valeur;
                if a > 0, A(a, a) = A(a, a) + g; end
                if d > 0, A(d, d) = A(d, d) + g; end
                if a > 0 && d > 0
                    A(a, d) = A(a, d) - g;
                    A(d, a) = A(d, a) - g;
                end
            case 'i'
                if a > 0, b(a) = b(a) - comp.valeur; end
                if d > 0, b(d) = b(d) + comp.valeur; end
            case {'v', 'l'}
                j = n + find(sourcesTension == k);
                if a > 0
                    A(a, j) = A(a, j) + 1;
                    A(j, a) = A(j, a) + 1;
                end
                if d > 0
                    A(d, j) = A(d, j) - 1;
                    A(j, d) = A(j, d) - 1;
                end
                if strcmp(comp.type, 'v')
                    b(j) = comp.valeur;
                else
                    b(j) = 0;   % une bobine est un court-circuit en continu
                end
        end
    end
    solution = A \ b;
    tensions = solution(1:n);
    courants = solution(n+1:end);
end
