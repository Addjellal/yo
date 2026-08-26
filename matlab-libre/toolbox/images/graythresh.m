function seuil = graythresh(x)
%GRAYTHRESH Seuil global par la méthode d'Otsu.
%   SEUIL = GRAYTHRESH(X) maximise la variance interclasse.
    x = im2double(x);
    v = x(:);
    n = 256;
    compte = zeros(1, n);
    for k = 1:numel(v)
        indice = min(n, max(1, round(v(k) * (n - 1)) + 1));
        compte(indice) = compte(indice) + 1;
    end
    p = compte / sum(compte);
    niveaux = (0:n-1) / (n - 1);
    variances = zeros(1, n-1);
    for k = 1:n-1
        w0 = sum(p(1:k));
        w1 = 1 - w0;
        if w0 == 0 || w1 == 0
            variances(k) = -1;
            continue;
        end
        m0 = sum(p(1:k) .* niveaux(1:k)) / w0;
        m1 = sum(p(k+1:end) .* niveaux(k+1:end)) / w1;
        variances(k) = w0 * w1 * (m0 - m1) ^ 2;
    end
    meilleure = max(variances);
    if meilleure <= 0
        seuil = 0.5;
        return;
    end
    % Comme la fonction de référence, on prend le milieu des seuils qui
    % atteignent le maximum : sur une image à deux niveaux, cela tombe
    % à mi-chemin entre les deux modes.
    gagnants = find(variances >= meilleure - 1e-12);
    seuil = mean(niveaux(gagnants));
end
