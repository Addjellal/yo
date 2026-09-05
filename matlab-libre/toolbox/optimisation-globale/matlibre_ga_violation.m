function total = matlibre_ga_violation(x, A, b, Aeq, beq, nonlineaires)
%MATLIBRE_GA_VIOLATION Somme des violations de contraintes en un point.
%   Rend zéro quand toutes les contraintes sont satisfaites, et la somme
%   de leurs dépassements sinon. Une inégalité A x <= b viole de
%   max(0, A x - b) ; une égalité viole de sa valeur absolue.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi GA, GAMULTIOBJ.
    x = x(:);
    total = 0;
    if ~isempty(A)
        total = total + sum(max(0, A * x - b(:)));
    end
    if ~isempty(Aeq)
        total = total + sum(abs(Aeq * x - beq(:)));
    end
    if ~isempty(nonlineaires)
        [c, ceq] = nonlineaires(x.');
        if ~isempty(c)
            total = total + sum(max(0, c(:)));
        end
        if ~isempty(ceq)
            total = total + sum(abs(ceq(:)));
        end
    end
end
