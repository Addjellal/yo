function b = de2bi(d, n, varargin)
%DE2BI Entiers vers vecteurs de chiffres.
%   B = DE2BI(D) rend, une ligne par élément de D, les chiffres binaires
%   avec le poids faible en tête. B = DE2BI(D,N) fixe le nombre de
%   colonnes, B = DE2BI(D,N,BASE) change de base.
%
%   B = DE2BI(D,N,BASE,'left-msb') met le poids fort en tête ;
%   'right-msb' est le comportement par défaut. Les deux conventions
%   coexistent parce que les codes correcteurs écrivent les polynômes par
%   puissances croissantes, et les modulateurs les symboles par poids
%   décroissants.
%
%   Exemple :
%      de2bi(5, 4)                 % [1 0 1 0]
%      de2bi(5, 4, 2, 'left-msb')  % [0 1 0 1]
%
%   Voir aussi BI2DE, DEC2BIN.
    [base, sens] = optionsChiffres(varargin);
    d = double(d(:));
    if nargin < 2 || isempty(n)
        n = 1;
        m = max([d; 0]);
        while base ^ n <= m
            n = n + 1;
        end
    end
    b = zeros(numel(d), n);
    for k = 1:numel(d)
        v = d(k);
        for j = 1:n
            b(k, j) = mod(v, base);
            v = floor(v / base);
        end
    end
    if strcmp(sens, 'left-msb')
        b = b(:, end:-1:1);
    end
end
