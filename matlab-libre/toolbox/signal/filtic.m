function z = filtic(b, a, y, x)
%FILTIC Conditions initiales d'un filtre, d'après son passé.
%   Z = FILTIC(B,A,Y,X) rend le vecteur d'état que FILTER attend pour
%   reprendre un filtrage déjà commencé : Y porte les sorties passées,
%   Y(1) valant y(-1), Y(2) valant y(-2), et X les entrées passées de la
%   même façon. Les vecteurs trop courts sont complétés par des zéros.
%
%   Z = FILTIC(B,A,Y) suppose les entrées passées nulles.
%
%   L'état est celui de la forme directe II transposée, celle qu'emploie
%   FILTER :
%
%      Z(m) = somme_{i>m} [ B(i) X(i-m) - A(i) Y(i-m) ].
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      x = randn(1, 100);
%      [y, zf] = filter(b, a, x);
%      z = filtic(b, a, y(end:-1:end-2), x(end:-1:end-2));
%      % z reproduit zf
%
%   Voir aussi FILTER, FILTFILT, IMPZ.
    if nargin < 4
        x = [];
    end
    b = double(b(:)).';
    a = double(a(:)).';
    if isempty(a), a = 1; end
    if a(1) == 0
        error('signal:filtic:NullLeading', 'A(1) ne peut pas être nul.');
    end
    b = b / a(1);
    a = a / a(1);
    n = max(numel(a), numel(b)) - 1;
    b = [b, zeros(1, n + 1 - numel(b))];
    a = [a, zeros(1, n + 1 - numel(a))];
    y = [double(y(:)).', zeros(1, n)];
    x = [double(x(:)).', zeros(1, n)];
    z = zeros(n, 1);
    for m = 1:n
        somme = 0;
        for i = (m + 1):(n + 1)
            somme = somme + b(i) * x(i - m) - a(i) * y(i - m);
        end
        z(m) = somme;
    end
end
