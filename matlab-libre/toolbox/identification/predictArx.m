function yhat = predictArx(modele, donnees)
%PREDICTARX Prédiction à un pas d'un modèle ARX.
%   YHAT = PREDICTARX(MODELE,DONNEES) rend la prédiction à un pas d'un
%   modèle ARX : A(q)y(t) = B(q)u(t), la sortie prédite au temps t étant
%   calculée à partir des sorties et des entrées mesurées jusqu'à t-1.
%
%   Prédire à un pas n'est pas simuler. Ici les sorties passées employées
%   sont les vraies, mesurées ; une simulation réinjecterait ses propres
%   prédictions et laisserait l'erreur s'accumuler. C'est pourquoi un
%   modèle peut prédire excellemment à un pas et diverger en simulation :
%   le premier exercice est presque toujours facile dès que la sortie est
%   régulière, et ne prouve pas grand-chose.
%
%   Les termes antérieurs au début de l'enregistrement sont pris nuls, ce
%   qui fausse les premiers points ; ils sont à écarter avant tout calcul
%   d'erreur d'ajustement.
%
%   Exemple :
%      rng(1);
%      u = randn(200, 1);
%      z = iddata(filter([0 0.5], [1 -0.8], u), u);
%      m = arx(z, [1 1 1]);
%      yhat = predictArx(m, z);
%
%   Voir aussi ARX, IMPULSEEST, COMPARE, IDDATA.
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
