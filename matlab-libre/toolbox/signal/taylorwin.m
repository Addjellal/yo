function w = taylorwin(n, nbar, sll)
%TAYLORWIN Fenêtre de Taylor.
%   W = TAYLORWIN(N,NBAR,SLL) rend la fenêtre de N points dont les NBAR
%   premiers lobes secondaires sont proches de SLL décibels, les suivants
%   décroissant. NBAR vaut 4 et SLL -30 par défaut.
%
%   C'est la fenêtre des antennes et des radars : à la différence de
%   Dolph-Tchebychev, elle ne garde pas des lobes égaux jusqu'au bout, ce
%   qui évite les impulsions aux extrémités.
%
%   Exemple :
%      w = taylorwin(64, 5, -35);
    if nargin < 2 || isempty(nbar), nbar = 4; end
    if nargin < 3 || isempty(sll), sll = -30; end
    n = round(n);
    if n <= 1
        w = ones(max(n, 0), 1);
        return
    end
    if sll > 0, sll = -sll; end
    A = acosh(10 ^ (-sll / 20)) / pi;
    sigmaCarre = nbar ^ 2 / (A ^ 2 + (nbar - 0.5) ^ 2);
    coefficients = zeros(1, nbar - 1);
    for m = 1:nbar-1
        haut = 1;
        for i = 1:nbar-1
            haut = haut * (1 - m ^ 2 / (sigmaCarre * (A ^ 2 + (i - 0.5) ^ 2)));
        end
        bas = 1;
        for i = 1:nbar-1
            if i ~= m
                bas = bas * (1 - m ^ 2 / i ^ 2);
            end
        end
        coefficients(m) = (-1) ^ (m + 1) * haut / (2 * bas);
    end
    indices = (0:n-1)' - (n - 1) / 2;
    w = ones(n, 1);
    for m = 1:nbar-1
        w = w + 2 * coefficients(m) * cos(2 * pi * m * indices / n);
    end
end
