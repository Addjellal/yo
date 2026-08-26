function [ca, ch, cv, cd] = dwt2(x, ondelette)
%DWT2 Transformée en ondelettes discrète bidimensionnelle, un niveau.
%   [CA,CH,CV,CD] = DWT2(X,ONDELETTE) rend l'approximation et les détails
%   horizontal, vertical et diagonal. La transformée est séparable : on
%   applique DWT aux lignes puis aux colonnes.
%
%   Exemple :
%      [a, h, v, d] = dwt2(ones(4), 'db1');   % a = 2*ones(2), h = v = d = 0
    x = double(x);
    [m, n] = size(x);
    % Lignes.
    for i = 1:m
        [a, d] = dwt(x(i, :), ondelette);
        if i == 1
            ligneA = zeros(m, numel(a));
            ligneD = zeros(m, numel(d));
        end
        ligneA(i, :) = a;
        ligneD(i, :) = d;
    end
    % Colonnes.
    for j = 1:size(ligneA, 2)
        [a, d] = dwt(ligneA(:, j)', ondelette);
        if j == 1
            ca = zeros(numel(a), size(ligneA, 2));
            ch = zeros(numel(d), size(ligneA, 2));
        end
        ca(:, j) = a(:);
        ch(:, j) = d(:);
    end
    for j = 1:size(ligneD, 2)
        [a, d] = dwt(ligneD(:, j)', ondelette);
        if j == 1
            cv = zeros(numel(a), size(ligneD, 2));
            cd = zeros(numel(d), size(ligneD, 2));
        end
        cv(:, j) = a(:);
        cd(:, j) = d(:);
    end
end
