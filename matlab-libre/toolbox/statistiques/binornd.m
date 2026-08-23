function r = binornd(n, pr, varargin)
%BINORND Tirages d'une loi binomiale.
%   Somme de N indicatrices de Bernoulli quand N est petit, inversion de
%   la répartition sinon.
    forme = statForme(size(n + pr), varargin);
    n = statEtendre(n, forme);
    pr = statEtendre(pr, forme);
    r = zeros(forme);
    grand = max(n(:));
    if isempty(grand), grand = 0; end
    if grand <= 200
        % Somme de Bernoulli : N tirages vectorisés sur tout le tableau.
        for k = 1:grand
            r = r + (rand(forme) < pr & k <= n);
        end
    else
        r = binoinv(rand(forme), n, pr);
    end
    r(pr < 0 | pr > 1 | n < 0 | n ~= round(n)) = NaN;
end
