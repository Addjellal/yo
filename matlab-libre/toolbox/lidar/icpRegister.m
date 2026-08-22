function [R, t, erreur] = icpRegister(source, cible, iterations)
%ICPREGISTER Recalage rigide 2-D par ICP.
    if nargin < 3
        iterations = 30;
    end
    R = eye(2);
    t = [0 0];
    courant = source;
    erreur = inf;
    for k = 1:iterations
        indices = zeros(size(courant, 1), 1);
        for i = 1:size(courant, 1)
            d = sum((cible - repmat(courant(i, :), size(cible, 1), 1)) .^ 2, 2);
            [~, indices(i)] = min(d);
        end
        appariee = cible(indices, :);
        cs = mean(courant, 1);
        cc = mean(appariee, 1);
        H = (courant - repmat(cs, size(courant,1), 1)).' * ...
            (appariee - repmat(cc, size(appariee,1), 1));
        [U, ~, V] = svd(H);
        Rk = V * U.';
        tk = cc.' - Rk * cs.';
        courant = (Rk * courant.' + repmat(tk, 1, size(courant,1))).';
        R = Rk * R;
        t = (Rk * t.' + tk).';
        erreur = mean(sqrt(sum((courant - appariee) .^ 2, 2)));
    end
end
