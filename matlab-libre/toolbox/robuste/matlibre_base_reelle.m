function Vr = matlibre_base_reelle(V, valeurs)
%MATLIBRE_BASE_REELLE Une base réelle à partir de vecteurs propres complexes.
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%   Une paire de pôles conjugués donne deux vecteurs propres conjugués ;
%   leur partie réelle et leur partie imaginaire engendrent le même plan
%   et sont réelles, ce qui évite de porter des complexes dans un modèle
%   qui n'en a pas.
    n = size(V, 1);
    Vr = zeros(n, size(V, 2));
    k = 1;
    while k <= numel(valeurs)
        if abs(imag(valeurs(k))) < 1e-12 * max(1, abs(valeurs(k))) || k == numel(valeurs)
            Vr(:, k) = real(V(:, k));
            k = k + 1;
        else
            Vr(:, k) = real(V(:, k));
            Vr(:, k + 1) = imag(V(:, k));
            k = k + 2;
        end
    end
end
