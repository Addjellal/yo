function phat = gamfit(x)
%GAMFIT Estimation des paramètres d'une loi gamma.
%   Le maximum de vraisemblance vérifie log(a) - psi(a) = log(moyenne) -
%   moyenne des logarithmes ; on résout par Newton, en partant de
%   l'approximation de Thom, puis l'échelle suit.
%
%   PHAT vaut [A B] : forme et échelle.
    x = double(x(:));
    if any(x <= 0)
        error('stats:gamfit:BadData', 'Les données doivent être strictement positives.');
    end
    n = numel(x);
    s = log(sum(x) / n) - sum(log(x)) / n;
    a = (3 - s + sqrt((3 - s) ^ 2 + 24 * s)) / (12 * s);
    for iteration = 1:100
        f = log(a) - psi(a) - s;
        df = 1 / a - psi(1, a);
        pas = f / df;
        nouveau = a - pas;
        if nouveau <= 0, nouveau = a / 2; end
        if abs(nouveau - a) <= 1e-14 * a
            a = nouveau;
            break
        end
        a = nouveau;
    end
    phat = [a, sum(x) / (n * a)];
end
