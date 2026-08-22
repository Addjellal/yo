function yhat = predictArx(modele, donnees)
%PREDICTARX Prédiction à un pas d'un modèle ARX.
    y = donnees.y;
    u = donnees.u;
    N = numel(y);
    A = modele.A;
    B = modele.B;
    yhat = zeros(N, 1);
    for t = 1:N
        acc = 0;
        for k = 2:numel(A)
            if t - k + 1 >= 1
                acc = acc - A(k) * y(t - k + 1);
            end
        end
        for k = 1:numel(B)
            if t - k + 1 >= 1
                acc = acc + B(k) * u(t - k + 1);
            end
        end
        yhat(t) = acc;
    end
end
