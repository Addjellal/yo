function modele = arx(donnees, ordres)
%ARX Estimation d'un modèle ARX par moindres carrés.
%   MODELE = ARX(DONNEES,[na nb nk]) ajuste
%      y(t) + a1 y(t-1) + ... = b1 u(t-nk) + ...
    na = ordres(1);
    nb = ordres(2);
    if numel(ordres) > 2
        nk = ordres(3);
    else
        nk = 1;
    end
    y = donnees.y;
    u = donnees.u;
    N = numel(y);
    debut = max(na, nb + nk - 1) + 1;
    lignes = N - debut + 1;
    Phi = zeros(lignes, na + nb);
    Y = zeros(lignes, 1);
    for t = debut:N
        i = t - debut + 1;
        for k = 1:na
            Phi(i, k) = -y(t - k);
        end
        for k = 1:nb
            Phi(i, na + k) = u(t - nk - k + 1);
        end
        Y(i) = y(t);
    end
    theta = Phi \ Y;
    modele = struct();
    modele.A = [1; theta(1:na)].';
    modele.B = [zeros(1, nk), theta(na+1:end).'];
    modele.Ts = donnees.Ts;
    modele.residus = Y - Phi * theta;
    modele.variance = var(modele.residus);
end
