function modele = armax(donnees, ordres, iterations)
%ARMAX Estimation ARMAX par la méthode pseudo-linéaire.
%   MODELE = ARMAX(DONNEES,[na nb nc nk]) alterne estimation des
%   paramètres et reconstruction du bruit.
    if nargin < 3
        iterations = 20;
    end
    na = ordres(1); nb = ordres(2); nc = ordres(3);
    if numel(ordres) > 3
        nk = ordres(4);
    else
        nk = 1;
    end
    y = donnees.y;
    u = donnees.u;
    N = numel(y);
    e = zeros(N, 1);
    debut = max([na, nb + nk - 1, nc]) + 1;
    theta = [];
    for tour = 1:iterations
        lignes = N - debut + 1;
        Phi = zeros(lignes, na + nb + nc);
        Y = zeros(lignes, 1);
        for t = debut:N
            i = t - debut + 1;
            for k = 1:na
                Phi(i, k) = -y(t - k);
            end
            for k = 1:nb
                Phi(i, na + k) = u(t - nk - k + 1);
            end
            for k = 1:nc
                Phi(i, na + nb + k) = e(t - k);
            end
            Y(i) = y(t);
        end
        theta = Phi \ Y;
        residus = Y - Phi * theta;
        e(debut:N) = residus;
    end
    modele = struct();
    modele.A = [1; theta(1:na)].';
    modele.B = [zeros(1, nk), theta(na+1:na+nb).'];
    modele.C = [1; theta(na+nb+1:end)].';
    modele.Ts = donnees.Ts;
end
